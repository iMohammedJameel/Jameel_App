import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/models/location_model.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/styles/app_design.dart';

class ShiftSummaryCard extends StatelessWidget {
  const ShiftSummaryCard({
    super.key,
    required this.todayItems,
    required this.isActive,
  });

  final List<LocationCheckInModel> todayItems;
  final bool isActive;

  String _formatWorkedDuration() {
    // todayItems is newest-first; oldest item is first check-in today.
    final first = todayItems.last.timestamp;
    final end = isActive ? DateTime.now() : todayItems.first.timestamp;
    final diff = end.difference(first);
    if (diff.isNegative) return '00h 00m';
    final hours = diff.inHours.toString().padLeft(2, '0');
    final mins = (diff.inMinutes % 60).toString().padLeft(2, '0');
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final firstTime = DateFormat('HH:mm').format(todayItems.last.timestamp);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconBubble(
            icon: isActive
                ? Icons.work_history_rounded
                : Icons.verified_rounded,
            color: isActive ? AppColors.success : AppColors.info,
            size: 46,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'today_shift_summary'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: context.inkColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'shift_started_at'.tr(namedArgs: {'time': firstTime}),
                  style: TextStyle(
                    color: context.mutedColor,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatWorkedDuration(),
                textDirection: ui.TextDirection.ltr,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isActive ? AppColors.success : context.inkColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'checkins_today_count'.tr(
                  namedArgs: {'count': '${todayItems.length}'},
                ),
                style: TextStyle(
                  color: context.mutedColor,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingSyncBanner extends StatelessWidget {
  const PendingSyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JameelCubit, JameelStates>(
      buildWhen: (_, state) => state is OfflineSyncStateChanged,
      builder: (context, _) {
        final cubit = JameelCubit.get(context);
        final count = cubit.totalPendingSyncCount;
        if (!cubit.isSyncing && count == 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            onTap: cubit.isSyncing
                ? null
                : () async {
                    final synced = await cubit.syncAllPending();
                    if (!context.mounted) return;
                    if (synced > 0) {
                      showAppSnack(context, 'sync_completed'.tr());
                    }
                  },
            child: Row(
              children: [
                IconBubble(
                  icon: cubit.isSyncing
                      ? Icons.cloud_sync_rounded
                      : Icons.cloud_upload_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cubit.isSyncing
                        ? 'syncing'.tr()
                        : 'pending_sync_count'.tr(namedArgs: {'count': '$count'}),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: context.inkColor,
                    ),
                  ),
                ),
                if (cubit.isSyncing)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AppColors.primary,
                    ),
                  )
                else
                  Text(
                    'sync_now'.tr(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomeActionTile extends StatelessWidget {
  const HomeActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : context.inkColor;
    final sub =
        filled ? Colors.white.withValues(alpha: 0.82) : context.mutedColor;

    return Container(
      decoration: BoxDecoration(
        gradient: filled ? AppColors.heroGradient : null,
        color: filled ? null : context.surfaceColor,
        borderRadius: BorderRadius.circular(22),
        border: filled ? null : Border.all(color: context.borderColor),
        boxShadow: filled
            ? AppShadows.brand
            : (context.isDark ? null : AppShadows.soft),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.white.withValues(alpha: 0.2)
                        : context.primarySoftColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: filled ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: sub, fontSize: 12.5, height: 1.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
