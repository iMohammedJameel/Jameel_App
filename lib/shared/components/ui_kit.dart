// lib/shared/components/ui_kit.dart
//
// Barrel export + lightweight helpers for the Jameel design system.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:jameel/shared/styles/app_design.dart';

export 'app_badges.dart';
export 'app_dialogs.dart';
export 'app_inputs.dart';
export 'app_surfaces.dart';
export 'shimmer_placeholder.dart';

class AppHaptics {
  AppHaptics._();

  static void light() => HapticFeedback.lightImpact();
  static void medium() => HapticFeedback.mediumImpact();
  static void error() => HapticFeedback.heavyImpact();
}

/// Chevron that points the right way in both LTR and RTL.
IconData directionalChevron(BuildContext context) =>
    Directionality.of(context) == ui.TextDirection.rtl
        ? Icons.chevron_left_rounded
        : Icons.chevron_right_rounded;

Color statusColor(String status) {
  switch (status) {
    case 'approved':
      return AppColors.success;
    case 'rejected':
      return AppColors.primary;
    case 'pending':
      return AppColors.warning;
    default:
      return AppColors.muted;
  }
}
