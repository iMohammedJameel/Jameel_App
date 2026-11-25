import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/modules/inspection/cubit/inspection_states.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/styles/app_design.dart';

class InspectionPreviewBox extends StatelessWidget {
  const InspectionPreviewBox({
    super.key,
    required this.height,
    required this.preview,
    required this.isProcessing,
  });

  final double height;
  final InspectionPreviewReadyState? preview;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'processing_watermark'.tr(),
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: context.mutedColor,
              ),
            ),
          ],
        ),
      );
    }

    if (preview != null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: context.isDark ? null : AppShadows.soft,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.memory(
          preview!.watermarkedBytes,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: context.primarySoftColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'capture_prompt'.tr(),
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: context.inkColor,
            ),
          ),
        ],
      ),
    );
  }
}

class InspectionHistorySection extends StatelessWidget {
  const InspectionHistorySection({super.key, required this.items});

  final List<LocalInspection> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length.clamp(0, 10),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return AppCard(
          padding: const EdgeInsets.all(12),
          onTap: () => _showPhotoDialog(context, item),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  item.bytes,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('yyyy-MM-dd  HH:mm').format(item.capturedAt),
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.inkColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                      textDirection: ui.TextDirection.ltr,
                      style: TextStyle(
                        color: context.mutedColor,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip(
                label: item.synced ? 'synced'.tr() : 'pending_upload'.tr(),
                color: item.synced ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPhotoDialog(BuildContext context, LocalInspection item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: ctx.surfaceColor,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                ),
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: Image.memory(item.bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: PrimaryButton(
                label: 'close'.tr(),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InspectionTipRow extends StatelessWidget {
  const InspectionTipRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBubble(icon: icon, color: AppColors.primary, size: 36),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: context.inkColor,
            ),
          ),
        ),
      ],
    );
  }
}
