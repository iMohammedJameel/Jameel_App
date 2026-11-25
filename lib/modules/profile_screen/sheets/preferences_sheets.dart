import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/modules/profile_screen/sheets/profile_sheet_scaffold.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

void showPrivacySheet(BuildContext context) {
  final jameelCubit = JameelCubit.get(context);
  final inspectionsRepo = context.read<InspectionsRepository>();

  showProfileSheet<void>(
    context,
    title: 'privacy_settings'.tr(),
    bodyBuilder: (ctx) => FutureBuilder<LocationPermission>(
      future: Geolocator.checkPermission(),
      builder: (ctx, snap) {
        final perm = snap.data;
        final permGranted = perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse;

        return BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
          builder: (ctx, prefs) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'location_permission_status'.tr(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: ctx.inkColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          perm == null
                              ? '—'
                              : (permGranted
                                  ? 'permission_granted'.tr()
                                  : 'permission_not_granted'.tr()),
                          style: TextStyle(
                            fontSize: 13,
                            color: permGranted
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: Geolocator.openAppSettings,
                    child: Text(
                      'open_settings'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.primary,
                title: Text(
                  'watermark_include_name'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: ctx.inkColor,
                  ),
                ),
                subtitle: Text(
                  'watermark_include_name_hint'.tr(),
                  style: TextStyle(fontSize: 13, color: ctx.mutedColor),
                ),
                value: prefs.includeNameInWatermark,
                onChanged: (val) => ctx
                    .read<AppPreferencesCubit>()
                    .setIncludeNameInWatermark(val),
              ),
              const Divider(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await inspectionsRepo.clearLocalInspections();
                  await jameelCubit.refreshPendingCounts();
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    showAppSnack(context, 'local_cache_cleared'.tr());
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text('clear_local_inspections'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

void showNotificationPrefsSheet(BuildContext context) {
  showProfileSheet<void>(
    context,
    title: 'notifications'.tr(),
    bodyBuilder: (ctx) => BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
      builder: (ctx, prefs) {
        final cubit = ctx.read<AppPreferencesCubit>();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PrefSwitch(
              title: 'notif_pref_leave'.tr(),
              value: prefs.notifyLeave,
              onChanged: (v) => cubit.setNotificationPref('leave', v),
            ),
            _PrefSwitch(
              title: 'notif_pref_loan'.tr(),
              value: prefs.notifyLoan,
              onChanged: (v) => cubit.setNotificationPref('loan', v),
            ),
            _PrefSwitch(
              title: 'notif_pref_announcement'.tr(),
              value: prefs.notifyAnnouncement,
              onChanged: (v) => cubit.setNotificationPref('announcement', v),
            ),
            _PrefSwitch(
              title: 'notif_pref_checkin'.tr(),
              value: prefs.notifyCheckIn,
              onChanged: (v) => cubit.setNotificationPref('check_in', v),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'ok'.tr(),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    ),
  );
}

class _PrefSwitch extends StatelessWidget {
  const _PrefSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      activeTrackColor: AppColors.primary,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: context.inkColor,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

void showThemeSheet(BuildContext context) {
  showProfileSheet<void>(
    context,
    title: 'theme'.tr(),
    bodyBuilder: (ctx) => BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
      builder: (ctx, prefs) {
        final cubit = ctx.read<AppPreferencesCubit>();
        Widget option(ThemeMode mode, IconData icon, String label) {
          final selected = prefs.themeMode == mode;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: IconBubble(
              icon: icon,
              color: selected ? AppColors.primary : ctx.mutedColor,
              size: 40,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: ctx.inkColor,
              ),
            ),
            trailing: Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : ctx.mutedColor,
            ),
            onTap: () {
              cubit.setThemeMode(mode);
              Navigator.pop(ctx);
            },
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(
              ThemeMode.light,
              Icons.light_mode_rounded,
              'theme_light'.tr(),
            ),
            option(ThemeMode.dark, Icons.dark_mode_rounded, 'theme_dark'.tr()),
            option(
              ThemeMode.system,
              Icons.brightness_auto_rounded,
              'theme_system'.tr(),
            ),
          ],
        );
      },
    ),
  );
}
