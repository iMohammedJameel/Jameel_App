import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WatermarkHelper {
  WatermarkHelper._();

  static const int _maxOutputWidth = 1280;

  /// Resizes oversized images to keep file size compact, then stamps a
  /// translucent footer banner containing timestamp, GPS, and optional name.
  static Future<Uint8List> stamp({
    required Uint8List imageBytes,
    required double latitude,
    required double longitude,
    required DateTime capturedAt,
    String? employeeName,
  }) async {
    final probeCodec = await ui.instantiateImageCodec(imageBytes);
    final probeFrame = await probeCodec.getNextFrame();
    final sourceWidth = probeFrame.image.width;
    probeFrame.image.dispose();
    probeCodec.dispose();

    final codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: sourceWidth > _maxOutputWidth ? _maxOutputWidth : null,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawImage(image, Offset.zero, Paint());

    final pad = (width * 0.03).clamp(14.0, 36.0);
    final fontSize = (width * 0.026).clamp(13.0, 30.0);
    final formattedTime = DateFormat('yyyy-MM-dd  HH:mm:ss').format(capturedAt);
    final coords =
        'GPS: ${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    final cleanName = employeeName?.trim() ?? '';
    final headerLine =
        cleanName.isNotEmpty ? '$cleanName  •  $formattedTime' : formattedTime;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
      text: TextSpan(
        children: [
          TextSpan(
            text: '$headerLine\n',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          TextSpan(
            text: coords,
            style: TextStyle(
              color: const Color(0xFFE5E7EB),
              fontSize: fontSize * 0.9,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    )..layout(maxWidth: width - pad * 2);

    final bannerHeight = textPainter.height + pad * 1.4;
    final bannerRect = Rect.fromLTWH(
      0,
      height - bannerHeight,
      width,
      bannerHeight,
    );
    canvas.drawRect(
      bannerRect,
      Paint()..color = const Color(0xB8111827),
    );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        height - bannerHeight,
        width,
        (fontSize * 0.14).clamp(2.0, 5.0),
      ),
      Paint()..color = const Color(0xFFD92B2F),
    );

    textPainter.paint(
      canvas,
      Offset(pad, height - bannerHeight + pad * 0.7),
    );

    final picture = recorder.endRecording();
    final output = await picture.toImage(image.width, image.height);
    final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
    output.dispose();

    return byteData?.buffer.asUint8List() ?? imageBytes;
  }
}
