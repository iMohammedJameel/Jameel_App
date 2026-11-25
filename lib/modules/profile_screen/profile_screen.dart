// lib/modules/profile_screen/profile_screen.dart
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/modules/login/login_screen.dart';
import 'package:jameel/modules/profile_screen/profile_sheets.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/helpers/locale_helper.dart';
import 'package:jameel/shared/styles/app_design.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferencesCubit>().state;
    final user = prefs.currentUser;

    return BlocConsumer<JameelCubit, JameelStates>(
      listenWhen: (_, state) =>
          state is SignOutLoadingState ||
          state is SignOutSuccessState ||
          state is SignOutErrorState,
      listener: (context, state) {
        if (state is SignOutLoadingState) {
          if (_isLoadingDialogOpen) return;
          _isLoadingDialogOpen = true;
          showLoadingDialog(context)
              .whenComplete(() => _isLoadingDialogOpen = false);
          return;
        }
        if (_isLoadingDialogOpen) {
          _isLoadingDialogOpen = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (state is SignOutSuccessState) {
          final prefsCubit = context.read<AppPreferencesCubit>();
          prefsCubit.removeSecurityPin();
          prefsCubit.setSessionUser(null);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
          );
        } else if (state is SignOutErrorState) {
          showStatusDialog(
            context,
            success: false,
            message: state.messageKey.tr(),
          );
        }
      },
      builder: (context, state) {
        final cubit = JameelCubit.get(context);

        if (user == null) {
          return Scaffold(
            backgroundColor: context.bgColor,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final rawName = user.userName?.trim() ?? '';
        final name = rawName.isEmpty ? 'unknown_user'.tr() : rawName;
        final dept = (user.userDepartment ?? '').trim();
        final themeLabel = switch (prefs.themeMode) {
          ThemeMode.light => 'theme_light'.tr(),
          ThemeMode.dark => 'theme_dark'.tr(),
          ThemeMode.system => 'theme_system'.tr(),
        };

        return Scaffold(
          backgroundColor: context.bgColor,
          body: PageOrnamentBackground(
            child: SingleChildScrollView(
            child: Column(
              children: [
                HeroBackground(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          InitialsAvatar(
                            name: name,
                            size: 92,
                            photoUrl: user.photoUrl,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.userEmail ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14.5,
                            ),
                          ),
                          if (dept.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            HeroChip(
                              icon: Icons.apartment_rounded,
                              label: dept,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SettingsGroup(
                        title: 'account_and_profile'.tr(),
                        tiles: [
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: 'edit_personal_info'.tr(),
                            onTap: () => showEditProfileSheet(context, user),
                          ),
                          _SettingsTile(
                            icon: Icons.manage_accounts_outlined,
                            title: 'manage_account'.tr(),
                            onTap: () => showManageAccountSheet(context, user),
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'app_preferences'.tr(),
                        tiles: [
                          _SettingsTile(
                            icon: Icons.language_rounded,
                            title: 'language'.tr(),
                            trailingText: 'language_name'.tr(),
                            onTap: context.toggleLocale,
                          ),
                          _SettingsTile(
                            icon: Icons.brightness_6_outlined,
                            title: 'theme'.tr(),
                            trailingText: themeLabel,
                            onTap: () => showThemeSheet(context),
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_none_rounded,
                            title: 'notifications'.tr(),
                            onTap: () => showNotificationPrefsSheet(context),
                          ),
                        ],
                      ),
                      _SettingsGroup(
                        title: 'privacy_and_security'.tr(),
                        tiles: [
                          _SettingsTile(
                            icon: Icons.privacy_tip_outlined,
                            title: 'manage_privacy'.tr(),
                            onTap: () => showPrivacySheet(context),
                          ),
                          _SettingsTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'change_password'.tr(),
                            onTap: () => showChangePasswordSheet(context, user),
                          ),
                          _SettingsTile(
                            icon: Icons.shield_outlined,
                            title: 'two_factor_auth'.tr(),
                            trailingText: prefs.hasSecurityPin
                                ? 'enabled'.tr()
                                : 'disabled'.tr(),
                            onTap: () => showSecurityPinSheet(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context, cubit),
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(
                            'logout'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            backgroundColor: context.surfaceColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
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

  void _showLogoutDialog(BuildContext context, JameelCubit cubit) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: dialogContext.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'confirm_logout'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: dialogContext.inkColor,
          ),
        ),
        content: Text(
          'logout_confirmation'.tr(),
          style: TextStyle(color: dialogContext.mutedColor, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'cancel'.tr(),
              style: TextStyle(color: dialogContext.mutedColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.signOut();
            },
            child: Text(
              'logout'.tr(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.tiles});

  final String title;
  final List<_SettingsTile> tiles;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == ui.TextDirection.rtl;
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      children.add(tiles[i]);
      if (i < tiles.length - 1) {
        children.add(
          Divider(height: 1, indent: 70, color: context.borderColor),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: context.mutedColor,
                letterSpacing: isRtl ? 0 : 0.3,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailingText,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppHaptics.light();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            IconBubble(icon: icon, color: AppColors.primary, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: context.inkColor,
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  color: context.mutedColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(
              directionalChevron(context),
              color: context.mutedColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
