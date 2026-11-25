import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:jameel/models/location_model.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';

class LocationsRepository {
  LocationsRepository({FirebaseFirestore? firestore, Connectivity? connectivity})
      : _firestoreOverride = firestore,
        _connectivityOverride = connectivity;

  final FirebaseFirestore? _firestoreOverride;
  final Connectivity? _connectivityOverride;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  Connectivity get _connectivity => _connectivityOverride ?? Connectivity();

  /// Most recent check-ins first. Capped so the list/map stay fast and the
  /// Firestore read cost stays bounded as history grows.
  static const int historyLimit = 50;

  Stream<List<LocationCheckInModel>> locationsStream(
    String userId, {
    int limit = historyLimit,
  }) {
    return _firestore
        .collection('employees')
        .doc(userId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => LocationCheckInModel.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> storeLocation(
    String userId,
    double lat,
    double lng, {
    String type = 'check_in',
    String? address,
    String? siteName,
    String? capturedAt,
  }) async {
    await _firestore
        .collection('employees')
        .doc(userId)
        .collection('locations')
        .add({
      'latitude': lat,
      'longitude': lng,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      if (capturedAt != null && capturedAt.isNotEmpty) 'capturedAt': capturedAt,
      if (address != null && address.isNotEmpty) 'address': address,
      if (siteName != null && siteName.isNotEmpty) 'siteName': siteName,
    });
  }

  Future<void> queueOfflineCheckIn({
    required String userId,
    required double lat,
    required double lng,
    required String type,
    String? address,
    String? siteName,
  }) async {
    final existing = await CacheHelper.getPendingCheckIns();
    existing.add({
      'id': 'offline_${DateTime.now().microsecondsSinceEpoch}',
      'userId': userId,
      'latitude': lat,
      'longitude': lng,
      'type': type,
      'capturedAt': DateTime.now().toUtc().toIso8601String(),
      if (address != null && address.isNotEmpty) 'address': address,
      if (siteName != null && siteName.isNotEmpty) 'siteName': siteName,
    });
    await CacheHelper.setPendingCheckIns(existing);
  }

  Future<List<LocationCheckInModel>> getPendingCheckIns(String userId) async {
    final all = await CacheHelper.getPendingCheckIns();
    return all
        .where((m) => m['userId'] == userId)
        .map(
          (m) => LocationCheckInModel.fromLocalMap(
            m['id'] as String? ?? 'offline',
            m,
          ),
        )
        .toList();
  }

  Future<int> syncPendingCheckIns(String userId) async {
    final connectivity = await _connectivity.checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return 0;

    final all = await CacheHelper.getPendingCheckIns();
    final mine = all.where((m) => m['userId'] == userId).toList();
    if (mine.isEmpty) return 0;

    final remaining = all.where((m) => m['userId'] != userId).toList();
    var synced = 0;

    for (var i = 0; i < mine.length; i++) {
      final item = mine[i];
      try {
        await storeLocation(
          userId,
          (item['latitude'] as num).toDouble(),
          (item['longitude'] as num).toDouble(),
          type: item['type'] as String? ?? 'check_in',
          address: item['address'] as String?,
          siteName: item['siteName'] as String?,
          capturedAt: item['capturedAt'] as String?,
        );
        synced++;
      } catch (_) {
        remaining.addAll(mine.sublist(i));
        break;
      }
    }

    await CacheHelper.setPendingCheckIns(remaining);
    return synced;
  }
}
