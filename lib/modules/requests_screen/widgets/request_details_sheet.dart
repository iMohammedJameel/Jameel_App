import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/models/request_model.dart';
import 'package:jameel/modules/requests_screen/request_meta.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/styles/app_design.dart';

String requestStatusText(String status) {
  switch (status) {
    case 'pending':
      return 'status_pending'.tr();
    case 'approved':
      return 'status_approved'.tr();
    case 'rejected':
      return 'status_rejected'.tr();
    case 'cancelled':
      return 'status_cancelled'.tr();
    default:
      return 'status_unknown'.tr();
  }
}

void showRequestDetailsSheet(BuildContext context, EmployeeRequestModel req) {
  final meta = RequestMeta.of(req.type);
  final requestDate = DateFormat('yyyy-MM-dd').format(req.timestamp);

  final rows = <MapEntry<String, String>>[
    MapEntry('description'.tr(), req.description),
    if (req.type == 'leave' && req.leaveCategory != null)
      MapEntry(
        'leave_category'.tr(),
        'leave_cat_${req.leaveCategory}'.tr(),
      ),
    if (req.type == 'leave') ...[
      MapEntry(
        'from_date'.tr(),
        req.startDate != null
            ? DateFormat('yyyy-MM-dd').format(req.startDate!)
            : '—',
      ),
      MapEntry(
        'to_date'.tr(),
        req.endDate != null
            ? DateFormat('yyyy-MM-dd').format(req.endDate!)
            : '—',
      ),
    ],
    if (req.type == 'loan')
      MapEntry('amount'.tr(), '${req.amount ?? '—'}'),
    if (req.reviewNote != null && req.reviewNote!.isNotEmpty)
      MapEntry('review_note'.tr(), req.reviewNote!),
    MapEntry('request_date'.tr(), requestDate),
  ];

  showModalBottomSheet(
    context: context,
    backgroundColor: context.surfaceColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: ctx.borderColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconBubble(icon: meta.icon, color: meta.color, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      meta.titleKey.tr(),
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: ctx.inkColor,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: requestStatusText(req.status),
                    color: statusColor(req.status),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _RequestStatusTimeline(status: req.status),
              const SizedBox(height: 18),
              Divider(height: 1, color: ctx.borderColor),
              for (final row in rows) ...[
                const SizedBox(height: 16),
                Text(
                  row.key,
                  style: TextStyle(
                    color: ctx.mutedColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.value,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.4,
                    color: ctx.inkColor,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (req.isPending) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<RequestsCubit>().cancelRequest(req.id);
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: Text('cancel_request'.tr()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                label: 'close'.tr(),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RequestStatusTimeline extends StatelessWidget {
  const _RequestStatusTimeline({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isFinal = status == 'approved' ||
        status == 'rejected' ||
        status == 'cancelled';
    final finalColor = statusColor(status);
    final finalLabel = switch (status) {
      'approved' => 'status_approved'.tr(),
      'rejected' => 'status_rejected'.tr(),
      'cancelled' => 'status_cancelled'.tr(),
      _ => 'step_decision'.tr(),
    };

    Widget node(IconData icon, String label, bool active, Color color) {
      return Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                  active ? color.withValues(alpha: 0.14) : context.borderColor,
              border: Border.all(
                color: active ? color : context.mutedColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: active ? color : context.mutedColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? context.inkColor : context.mutedColor,
            ),
          ),
        ],
      );
    }

    Widget connector(bool active, Color color) => Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 20, left: 6, right: 6),
            color: active ? color : context.borderColor,
          ),
        );

    return Row(
      children: [
        node(Icons.send_rounded, 'step_submitted'.tr(), true, AppColors.success),
        connector(true, AppColors.success),
        node(
          Icons.hourglass_top_rounded,
          'step_in_review'.tr(),
          true,
          isFinal ? AppColors.success : AppColors.warning,
        ),
        connector(isFinal, finalColor),
        node(
          status == 'approved'
              ? Icons.check_rounded
              : (status == 'rejected' || status == 'cancelled'
                  ? Icons.close_rounded
                  : Icons.circle_outlined),
          finalLabel,
          isFinal,
          finalColor,
        ),
      ],
    );
  }
}
