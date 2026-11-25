import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:jameel/shared/components/app_inputs.dart';
import 'package:jameel/shared/styles/app_design.dart';

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: error ? AppColors.primary : AppColors.success,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
}

Future<void> showStatusDialog(
  BuildContext context, {
  required bool success,
  required String message,
  String? title,
}) {
  final color = success ? AppColors.success : AppColors.primary;
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: ctx.surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check_rounded : Icons.error_outline_rounded,
                color: color,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title ?? (success ? 'success'.tr() : 'error'.tr()),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ctx.inkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ctx.mutedColor,
                fontSize: 14.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(label: 'ok'.tr(), onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}

/// Non-dismissible loading overlay. Close it with `Navigator.pop(context)`.
Future<void> showLoadingDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Center(
      child: Container(
        width: 128,
        height: 128,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ctx.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: ctx.isDark ? null : AppShadows.soft,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      ),
    ),
  );
}
