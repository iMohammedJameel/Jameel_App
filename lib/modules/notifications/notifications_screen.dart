import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/notifications_repository.dart';
import 'package:jameel/models/notification_model.dart';
import 'package:jameel/modules/notifications/notifications_cubit/notifications_cubit.dart';
import 'package:jameel/modules/notifications/notifications_cubit/notifications_states.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _searchController = TextEditingController();
  bool _unreadOnly = false;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferencesCubit>().state;

    return BlocProvider(
      create: (ctx) => NotificationsCubit(
        repository: ctx.read<NotificationsRepository>(),
        userIdGetter: () =>
            ctx.read<AppPreferencesCubit>().state.currentUser?.uId,
      )..loadNotifications(),
      child: Scaffold(
        backgroundColor: context.bgColor,
        appBar: AppBar(
          title: Text('notifications'.tr()),
          actions: [
            IconButton(
              icon: Icon(
                _unreadOnly
                    ? Icons.mark_email_unread_rounded
                    : Icons.mark_email_unread_outlined,
              ),
              color: _unreadOnly ? AppColors.primary : context.mutedColor,
              onPressed: () {
                AppHaptics.light();
                setState(() => _unreadOnly = !_unreadOnly);
              },
              tooltip: 'unread_only'.tr(),
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.done_all_rounded),
                color: AppColors.primary,
                onPressed: () {
                  AppHaptics.light();
                  ctx.read<NotificationsCubit>().markAllAsRead();
                },
                tooltip: 'mark_all_read'.tr(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: PageOrnamentBackground(
          child: BlocConsumer<NotificationsCubit, NotificationsStates>(
          listener: (context, state) {
            if (state is NotificationsErrorState) {
              showAppSnack(context, state.messageKey.tr(), error: true);
            }
          },
          builder: (context, state) {
            final cubit = context.read<NotificationsCubit>();

            if (state is NotificationsLoadingState) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: ShimmerListPlaceholder(itemCount: 4),
              );
            }

            final q = _query.trim().toLowerCase();
            final visible = cubit.notifications.where((n) {
              if (!prefs.isCategoryEnabled(n.type)) return false;
              if (_unreadOnly && n.isRead) return false;
              if (q.isNotEmpty) {
                return n.title.toLowerCase().contains(q) ||
                    n.message.toLowerCase().contains(q);
              }
              return true;
            }).toList();

            final unread = visible.where((n) => !n.isRead).length;

            return Column(
              children: [
                if (cubit.notifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: TextStyle(color: context.inkColor, fontSize: 14.5),
                      decoration: InputDecoration(
                        hintText: 'search_notifications'.tr(),
                        hintStyle: TextStyle(color: context.mutedColor),
                        prefixIcon:
                            Icon(Icons.search_rounded, color: context.mutedColor),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: context.mutedColor,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.surfaceColor,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: visible.isEmpty
                      ? RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: cubit.loadNotifications,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.sizeOf(context).height * 0.16,
                              ),
                              EmptyState(
                                icon: cubit.notifications.isNotEmpty
                                    ? Icons.filter_alt_off_rounded
                                    : Icons.notifications_off_rounded,
                                title: cubit.notifications.isNotEmpty
                                    ? 'no_matching_notifications'.tr()
                                    : 'no_notifications_message'.tr(),
                              ),
                              if (_query.isNotEmpty || _unreadOnly)
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _query = '';
                                        _unreadOnly = false;
                                      });
                                    },
                                    icon: const Icon(Icons.clear_all_rounded),
                                    label: Text('clear_filters'.tr()),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: cubit.loadNotifications,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            children: [
                              if (unread > 0)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    'unread_count'
                                        .tr(namedArgs: {'count': '$unread'}),
                                    style: TextStyle(
                                      color: context.mutedColor,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ..._buildGroupedItems(context, visible),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedItems(
    BuildContext context,
    List<NotificationModel> items,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final widgets = <Widget>[];
    String? activeBucket;

    for (final item in items) {
      final d = DateTime(item.date.year, item.date.month, item.date.day);
      final bucket = d == today ? 'date_today' : 'date_earlier';
      if (bucket != activeBucket) {
        activeBucket = bucket;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: widgets.isEmpty ? 0 : 12,
              bottom: 8,
              left: 4,
              right: 4,
            ),
            child: Text(
              bucket.tr(),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: context.mutedColor,
              ),
            ),
          ),
        );
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildNotificationItem(context, item),
        ),
      );
    }
    return widgets;
  }

  String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'minutes_ago'.tr(namedArgs: {'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'hours_ago'.tr(namedArgs: {'count': '${diff.inHours}'});
    }
    return DateFormat('yyyy-MM-dd • HH:mm').format(date);
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
  ) {
    final color = _getNotificationColor(notification.type);
    final unread = !notification.isRead;

    final card = AppCard(
      padding: const EdgeInsets.all(14),
      color: unread ? context.unreadTintColor : context.surfaceColor,
      borderColor: unread
          ? AppColors.primary.withValues(alpha: 0.25)
          : context.borderColor,
      onTap: () {
        AppHaptics.light();
        context.read<NotificationsCubit>().markAsRead(notification.id);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: _getNotificationIcon(notification.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    color: context.inkColor,
                  ),
                ),
                if (notification.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: context.mutedColor,
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _relativeTime(notification.date),
                  textDirection: DateTime.now().difference(notification.date).inHours >= 24
                      ? ui.TextDirection.ltr
                      : null,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.mutedColor,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );

    if (!unread) return card;

    return Dismissible(
      key: ValueKey('notif_${notification.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (_) async {
        AppHaptics.light();
        await context.read<NotificationsCubit>().markAsRead(notification.id);
        return false;
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.done_rounded, color: AppColors.success),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.done_rounded, color: AppColors.success),
      ),
      child: card,
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'leave':
        return Icons.beach_access_rounded;
      case 'loan':
        return Icons.payments_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'leave':
        return AppColors.info;
      case 'loan':
        return AppColors.success;
      case 'announcement':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
}
