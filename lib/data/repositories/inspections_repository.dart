import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:path_provider/path_provider.dart';

class LocalInspection {
  const LocalInspection({
    required this.key,
    required this.bytes,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
    required this.synced,
    this.employeeId,
    this.filePath,
    this.storagePath,
    this.downloadUrl,
  });

  final dynamic key;
  final Uint8List bytes;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
  final bool synced;
  final String? employeeId;
  final String? filePath;
  final String? storagePath;
  final String? downloadUrl;
}

class InspectionsRepository {
  InspectionsRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    Connectivity? connectivity,
  })  : _firestoreOverride = firestore,
        _storageOverride = storage,
        _connectivityOverride = connectivity;

  final FirebaseFirestore? _firestoreOverride;
  final FirebaseStorage? _storageOverride;
  final Connectivity? _connectivityOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  Connectivity get _connectivity => _connectivityOverride ?? Connectivity();

  static const String boxName = 'inspections';

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(boxName)) return Hive.box(boxName);
    final cipher = await CacheHelper.resolveCipher();
    try {
      return await Hive.openBox(boxName, encryptionCipher: cipher);
    } catch (_) {
      // Migrate entries from a previously unencrypted box into an AES box.
      final migrated = <Map<String, dynamic>>[];
      try {
        final legacy = await Hive.openBox(boxName);
        for (final k in legacy.keys) {
          final v = legacy.get(k);
          if (v is Map) migrated.add(Map<String, dynamic>.from(v));
        }
        await legacy.close();
      } catch (_) {}
      await Hive.deleteBoxFromDisk(boxName);
      final encrypted = await Hive.openBox(boxName, encryptionCipher: cipher);
      for (final item in migrated) {
        await encrypted.add(item);
      }
      return encrypted;
    }
  }

  /// Writes watermarked photo bytes to a file on disk instead of storing heavy
  /// blobs inside Hive, keeping local DB memory usage small.
  Future<String?> _persistImageFile(Uint8List bytes, DateTime capturedAt) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}${Platform.pathSeparator}inspections');
      if (!folder.existsSync()) {
        folder.createSync(recursive: true);
      }
      final name = 'insp_${capturedAt.microsecondsSinceEpoch}.png';
      final file = File('${folder.path}${Platform.pathSeparator}$name');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Uploads the watermarked image to Firebase Storage and writes the verified
  /// inspection record to Firestore. Failures propagate so offline sync keeps
  /// unsent photos queued until both Storage and Firestore succeed.
  Future<({String storagePath, String downloadUrl})> uploadInspection({
    required String employeeId,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    required Uint8List bytes,
  }) async {
    final fileName = 'insp_${capturedAt.millisecondsSinceEpoch}.png';
    final storagePath = 'inspections/$employeeId/$fileName';
    final ref = _storage.ref().child(storagePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
    final downloadUrl = await ref.getDownloadURL();

    await _firestore.collection('inspections').add({
      'employeeId': employeeId,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'uploadedAt': FieldValue.serverTimestamp(),
      'size': bytes.length,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
    });

    return (storagePath: storagePath, downloadUrl: downloadUrl);
  }

  Future<dynamic> saveLocally({
    required Uint8List bytes,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    String? employeeId,
    bool synced = false,
  }) async {
    final filePath = await _persistImageFile(bytes, capturedAt);
    final box = await _box();
    return box.add({
      if (filePath != null) 'filePath': filePath else 'bytes': bytes,
      'latitude': latitude,
      'longitude': longitude,
      'capturedAt': capturedAt.toUtc().toIso8601String(),
      'employeeId': employeeId,
      'synced': synced,
    });
  }

  Future<void> markSynced(
    dynamic key, {
    String? employeeId,
    String? storagePath,
    String? downloadUrl,
  }) async {
    final box = await _box();
    final existing = box.get(key);
    if (existing is Map) {
      final updated = Map<String, dynamic>.from(existing);
      updated['synced'] = true;
      if (employeeId != null) updated['employeeId'] = employeeId;
      if (storagePath != null) updated['storagePath'] = storagePath;
      if (downloadUrl != null) updated['downloadUrl'] = downloadUrl;
      await box.put(key, updated);
    }
  }

  Future<List<LocalInspection>> getLocalInspections({String? employeeId}) async {
    final box = await _box();
    final items = <LocalInspection>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      final recordOwner = map['employeeId'] as String?;
      if (employeeId != null &&
          recordOwner != null &&
          recordOwner.isNotEmpty &&
          recordOwner != employeeId) {
        continue;
      }

      Uint8List? bytes;
      final filePath = map['filePath'] as String?;
      if (filePath != null && filePath.isNotEmpty) {
        final file = File(filePath);
        if (file.existsSync()) {
          bytes = await file.readAsBytes();
        }
      }
      if (bytes == null) {
        final rawBytes = map['bytes'];
        if (rawBytes is Uint8List) {
          bytes = rawBytes;
        } else if (rawBytes is List) {
          bytes = Uint8List.fromList(rawBytes.cast<int>());
        }
      }
      if (bytes == null) continue;

      final lat = (map['latitude'] as num?)?.toDouble() ?? 0.0;
      final lng = (map['longitude'] as num?)?.toDouble() ?? 0.0;
      final capturedRaw = map['capturedAt'] as String?;
      final capturedAt =
          (capturedRaw != null ? DateTime.tryParse(capturedRaw) : null) ??
              DateTime.now();
      final synced = map['synced'] as bool? ?? false;
      items.add(
        LocalInspection(
          key: key,
          bytes: bytes,
          latitude: lat,
          longitude: lng,
          capturedAt: capturedAt.toLocal(),
          synced: synced,
          employeeId: recordOwner,
          filePath: filePath,
          storagePath: map['storagePath'] as String?,
          downloadUrl: map['downloadUrl'] as String?,
        ),
      );
    }
    items.sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return items;
  }

  Future<int> getPendingCount({String? employeeId}) async {
    final all = await getLocalInspections(employeeId: employeeId);
    return all.where((item) => !item.synced).length;
  }

  /// Uploads all unsynced local inspections for [employeeId] when online.
  /// Returns the number of items successfully synced.
  Future<int> syncPending({required String employeeId}) async {
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return 0;

    final pending = (await getLocalInspections(employeeId: employeeId))
        .where((item) => !item.synced)
        .toList();
    if (pending.isEmpty) return 0;

    var syncedCount = 0;
    for (final item in pending) {
      try {
        final result = await uploadInspection(
          employeeId: employeeId,
          latitude: item.latitude,
          longitude: item.longitude,
          capturedAt: item.capturedAt,
          bytes: item.bytes,
        );
        await markSynced(
          item.key,
          employeeId: employeeId,
          storagePath: result.storagePath,
          downloadUrl: result.downloadUrl,
        );
        syncedCount++;
      } catch (_) {
        break;
      }
    }
    return syncedCount;
  }

  Future<void> clearLocalInspections() async {
    final box = await _box();
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final filePath = raw['filePath'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          final f = File(filePath);
          if (f.existsSync()) f.deleteSync();
        }
      }
    }
    await box.clear();
  }
}
