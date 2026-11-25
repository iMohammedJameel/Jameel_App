import 'dart:typed_data';

import 'package:jameel/shared/helpers/location_helper.dart';

abstract class InspectionStates {}

class InspectionInitialState extends InspectionStates {}

class InspectionProcessingState extends InspectionStates {}

class InspectionPreviewReadyState extends InspectionStates {
  InspectionPreviewReadyState({
    required this.watermarkedBytes,
    required this.latitude,
    required this.longitude,
    required this.capturedAt,
  });

  final Uint8List watermarkedBytes;
  final double latitude;
  final double longitude;
  final DateTime capturedAt;
}

class InspectionSavingState extends InspectionStates {}

class InspectionUploadedState extends InspectionStates {}

class InspectionSavedLocallyState extends InspectionStates {}

class InspectionLocationErrorState extends InspectionStates {
  final LocationException error;

  InspectionLocationErrorState(this.error);
}

class InspectionErrorState extends InspectionStates {
  /// Translation key describing what went wrong.
  final String messageKey;

  InspectionErrorState(this.messageKey);
}
