// lib/modules/inspection/capture_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/modules/inspection/cubit/inspection_cubit.dart';
import 'package:jameel/modules/inspection/cubit/inspection_states.dart';
import 'package:jameel/modules/inspection/widgets/capture_widgets.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

/// In-app camera capture flow.
///
/// Only opens the device camera directly — there is no gallery/album entry
/// point. Captures the photo, stamps a date/time/GPS watermark onto the image,
/// previews it with Retake / Save actions, and uploads online or queues offline
/// for automatic background sync.
class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AppPreferencesCubit>().state.currentUser;
    return BlocProvider(
      create: (_) => InspectionCubit(
        repository: context.read<InspectionsRepository>(),
        employeeId: user?.uId,
      ),
      child: const _CaptureView(),
    );
  }
}

class _CaptureView extends StatefulWidget {
  const _CaptureView();

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  List<LocalInspection> _localHistory = [];
  bool _tipsExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = context.read<AppPreferencesCubit>().state.currentUser?.uId;
    final items = await context
        .read<InspectionsRepository>()
        .getLocalInspections(employeeId: uid);
    if (mounted) {
      setState(() {
        _localHistory = items;
        if (items.isNotEmpty) _tipsExpanded = false;
      });
    }
  }

  Future<void> _openCamera() async {
    final cubit = context.read<InspectionCubit>();
    final prefsCubit = context.read<AppPreferencesCubit>();
    final includeName = prefsCubit.state.includeNameInWatermark;
    final employeeName = includeName ? prefsCubit.state.currentUser?.userName : null;
    prefsCubit.suppressNextAutoLock();

    try {
      // Camera source only — no gallery entry.
      final xfile = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 90,
        maxHeight: 1600,
        maxWidth: 1600,
      );
      if (xfile == null || !mounted) return; // cancelled, or screen closed

      await cubit.preparePreview(
        rawJpegBytes: await xfile.readAsBytes(),
        employeeName: employeeName,
      );
    } on PlatformException {
      if (!mounted) return;
      showStatusDialog(
        context,
        success: false,
        message: 'camera_permission_denied'.tr(),
      );
    } catch (_) {
      if (!mounted) return;
      showStatusDialog(context, success: false, message: 'error_unknown'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return BlocConsumer<InspectionCubit, InspectionStates>(
      listener: (context, state) {
        if (state is InspectionUploadedState) {
          showAppSnack(context, 'inspection_uploaded'.tr());
          Navigator.of(context).pop(true);
        } else if (state is InspectionSavedLocallyState) {
          showAppSnack(context, 'inspection_saved_locally'.tr());
          Navigator.of(context).pop(true);
        } else if (state is InspectionLocationErrorState) {
          showStatusDialog(context, success: false, message: state.error.key.tr());
        } else if (state is InspectionErrorState) {
          showStatusDialog(
            context,
            success: false,
            message: state.messageKey.tr(),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<InspectionCubit>();
        final preview = cubit.pendingPreview;
        final isProcessing = state is InspectionProcessingState;
        final isSaving = state is InspectionSavingState;
        final isBusy = isProcessing || isSaving;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(title: Text('capture_inspection'.tr())),
          body: PageOrnamentBackground(
            child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InspectionPreviewBox(
                          height: screenHeight * 0.4,
                          preview: preview,
                          isProcessing: isProcessing,
                        ),
                        const SizedBox(height: 18),
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onTap: () =>
                              setState(() => _tipsExpanded = !_tipsExpanded),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'capture_guidelines'.tr(),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: context.inkColor,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _tipsExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: context.mutedColor,
                                  ),
                                ],
                              ),
                              if (_tipsExpanded) ...[
                                const SizedBox(height: 14),
                                InspectionTipRow(
                                  icon: Icons.photo_camera_rounded,
                                  text: 'capture_tip_camera'.tr(),
                                ),
                                const SizedBox(height: 12),
                                InspectionTipRow(
                                  icon: Icons.pin_drop_rounded,
                                  text: 'capture_tip_gps'.tr(),
                                ),
                                const SizedBox(height: 12),
                                InspectionTipRow(
                                  icon: Icons.cloud_upload_rounded,
                                  text: 'capture_tip_offline'.tr(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_localHistory.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          SectionTitle('recent_inspections'.tr()),
                          const SizedBox(height: 12),
                          InspectionHistorySection(items: _localHistory),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border(top: BorderSide(color: context.borderColor)),
                  ),
                  child: preview != null
                      ? Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 54,
                                child: OutlinedButton.icon(
                                  onPressed: isBusy ? null : _openCamera,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'retake'.tr(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: context.inkColor,
                                    side: BorderSide(color: context.borderColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: PrimaryButton(
                                label: 'save_photo'.tr(),
                                icon: Icons.cloud_done_rounded,
                                loading: isSaving,
                                onPressed: isBusy
                                    ? null
                                    : () {
                                        AppHaptics.medium();
                                        cubit.saveAndUpload();
                                      },
                              ),
                            ),
                          ],
                        )
                      : PrimaryButton(
                          label: 'open_camera'.tr(),
                          icon: Icons.photo_camera_rounded,
                          loading: isBusy,
                          onPressed: isBusy ? null : _openCamera,
                        ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
