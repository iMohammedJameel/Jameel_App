import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/models/request_model.dart';
import 'package:jameel/modules/requests_screen/request_meta.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/styles/app_design.dart';

void showTeamApprovalsSheet(BuildContext context) {
  final cubit = context.read<RequestsCubit>();
  showModalBottomSheet(
    context: context,
    backgroundColor: context.surfaceColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.92,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
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
            const SizedBox(height: 16),
            Text(
              'team_approvals'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ctx.inkColor,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<EmployeeRequestModel>>(
                stream: cubit.getPendingApprovalsStream(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const ShimmerListPlaceholder(itemCount: 3);
                  }
                  final list = snap.data ?? const <EmployeeRequestModel>[];
                  if (list.isEmpty) {
                    return Center(
                      child: EmptyState(
                        icon: Icons.task_alt_rounded,
                        title: 'no_pending_approvals'.tr(),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final req = list[index];
                      final meta = RequestMeta.of(req.type);
                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconBubble(
                                  icon: meta.icon,
                                  color: meta.color,
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req.employeeName ?? 'unknown_user'.tr(),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: ctx.inkColor,
                                        ),
                                      ),
                                      Text(
                                        meta.titleKey.tr(),
                                        style: TextStyle(
                                          color: ctx.mutedColor,
                                          fontSize: 12.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              req.description,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: ctx.inkColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => cubit.reviewRequest(
                                      requestId: req.id,
                                      status: 'rejected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text('reject'.tr()),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => cubit.reviewRequest(
                                      requestId: req.id,
                                      status: 'approved',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text('approve'.tr()),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
