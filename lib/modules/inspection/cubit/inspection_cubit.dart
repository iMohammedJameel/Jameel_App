import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/modules/inspection/cubit/inspection_states.dart';
import 'package:jameel/modules/inspection/watermark_helper.dart';
import 'package:jameel/shared/helpers/location_helper.dart';
import 'package:jameel/shared/session.dart';

class InspectionCubit extends Cubit<InspectionStates> {
  InspectionCubit({
    InspectionsRepository? repository,
    Connectivity? connectivity,
    this.employeeId,
  })  : _repository = repository ?? InspectionsRepository(),
        _connectivity = connectivity ?? Connectivity(),
        super(InspectionInitialState());

  final InspectionsRepository _repository;
  final Connectivity _connectivity;
  final String? employeeId;

  InspectionPreviewReadyState? _pendingPreview;
  InspectionPreviewReadyState? get pendingPreview => _pendingPreview;

  String? get _uid => employeeId ?? userModel?.uId;

  /// Reads GPS location (rejecting mock GPS), stamps the watermark onto the
  /// photo, and exposes a preview before saving/uploading.
  Future<void> preparePreview({
    required Uint8List rawJpegBytes,
    String? employeeName,
  }) async {
    emit(InspectionProcessingState());
    try {
      final position = await LocationHelper.getCurrentPosition();
      final capturedAt = DateTime.now();
      final stamped = await WatermarkHelper.stamp(
        imageBytes: rawJpegBytes,
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: capturedAt,
        employeeName: employeeName,
      );
      final preview = InspectionPreviewReadyState(
        watermarkedBytes: stamped,
        latitude: position.latitude,
        longitude: position.longitude,
        capturedAt: capturedAt,
      );
      _pendingPreview = preview;
      emit(preview);
    } on LocationException catch (e) {
      emit(InspectionLocationErrorState(e));
    } catch (e, st) {
      addError(e, st);
      emit(InspectionErrorState('error_unknown'));
    }
  }

  /// Saves the watermarked inspection locally on disk and uploads it when
  /// online; otherwise keeps it queued for automatic background sync.
  Future<void> saveAndUpload() async {
    final preview = _pendingPreview;
    if (preview == null) return;

    emit(InspectionSavingState());
    final uid = _uid;
    try {
      final key = await _repository.saveLocally(
        bytes: preview.watermarkedBytes,
        latitude: preview.latitude,
        longitude: preview.longitude,
        capturedAt: preview.capturedAt,
        employeeId: uid,
        synced: false,
      );

      final connectivity = await _connectivity.checkConnectivity();
      final hasNetwork = !connectivity.contains(ConnectivityResult.none);
      if (hasNetwork && uid != null && uid.isNotEmpty) {
        try {
          final result = await _repository.uploadInspection(
            employeeId: uid,
            latitude: preview.latitude,
            longitude: preview.longitude,
            capturedAt: preview.capturedAt,
            bytes: preview.watermarkedBytes,
          );
          await _repository.markSynced(
            key,
            employeeId: uid,
            storagePath: result.storagePath,
            downloadUrl: result.downloadUrl,
          );
          _pendingPreview = null;
          emit(InspectionUploadedState());
          return;
        } catch (e, st) {
          addError(e, st);
        }
      }

      _pendingPreview = null;
      emit(InspectionSavedLocallyState());
    } catch (e, st) {
      addError(e, st);
      emit(InspectionErrorState('error_unknown'));
    }
  }
}
