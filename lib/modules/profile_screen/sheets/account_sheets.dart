import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/profile_screen/sheets/profile_sheet_scaffold.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

void showEditProfileSheet(BuildContext context, JameelUserModel user) {
  showProfileSheet<void>(
    context,
    title: 'edit_personal_info'.tr(),
    bodyBuilder: (_) => _EditProfileForm(user: user, hostContext: context),
  );
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm({
    required this.user,
    required this.hostContext,
  });

  final JameelUserModel user;
  final BuildContext hostContext;

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user.userName ?? '');
  late final TextEditingController _deptCtrl =
      TextEditingController(text: widget.user.userDepartment ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = widget.user.uId;
    if (uid == null || uid.isEmpty) return;

    final authRepo = context.read<AuthRepository>();
    final prefsCubit = context.read<AppPreferencesCubit>();
    setState(() => _saving = true);

    try {
      final updated = await authRepo.updateEmployeeProfile(
        uid: uid,
        name: _nameCtrl.text,
        department: _deptCtrl.text,
        email: widget.user.userEmail,
        existingJoinDate: widget.user.userJoinDate,
      );
      await prefsCubit.updateCachedUser(updated);
      if (mounted) Navigator.pop(context);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'profile_updated'.tr());
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'error_unknown'.tr(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _nameCtrl,
            label: 'full_name'.tr(),
            icon: Icons.person_outline_rounded,
            validator: (v) {
              final trimmed = v?.trim() ?? '';
              if (trimmed.isEmpty) return 'enter_name'.tr();
              if (trimmed.length > 120) return 'value_too_long'.tr();
              return null;
            },
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _deptCtrl,
            label: 'department'.tr(),
            icon: Icons.apartment_rounded,
            validator: (v) {
              if ((v?.trim().length ?? 0) > 100) return 'value_too_long'.tr();
              return null;
            },
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'save_changes'.tr(),
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _submit,
          ),
        ],
      ),
    );
  }
}

void showManageAccountSheet(BuildContext context, JameelUserModel user) {
  final authRepo = context.read<AuthRepository>();
  var busy = false;
  var verified = authRepo.isEmailVerified;
  final providers = authRepo.linkedProviders;

  showProfileSheet<void>(
    context,
    title: 'manage_account'.tr(),
    bodyBuilder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final joinText = user.userJoinDate != null
            ? DateFormat('yyyy-MM-dd').format(user.userJoinDate!)
            : '—';
        final providerLabel = providers.isEmpty
            ? '—'
            : providers
                .map((p) => p == 'google.com'
                    ? 'Google'
                    : (p == 'password' ? 'email'.tr() : p))
                .join(' • ');

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetInfoRow(label: 'email'.tr(), value: user.userEmail ?? '—'),
            SheetInfoRow(label: 'employee_id'.tr(), value: user.uId ?? '—'),
            SheetInfoRow(
                label: 'sign_in_methods'.tr(), value: providerLabel),
            SheetInfoRow(label: 'join_date'.tr(), value: joinText),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'email_verification'.tr(),
                    style: TextStyle(
                      color: ctx.mutedColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusChip(
                  label: verified ? 'verified'.tr() : 'unverified'.tr(),
                  color: verified ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            if (!verified && authRepo.currentFirebaseUser != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                await authRepo.reloadCurrentUser();
                                setState(() {
                                  verified = authRepo.isEmailVerified;
                                  busy = false;
                                });
                              } catch (_) {
                                setState(() => busy = false);
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ctx.inkColor,
                        side: BorderSide(color: ctx.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text('refresh_status'.tr()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'verify_email'.tr(),
                      loading: busy,
                      onPressed: busy
                          ? null
                          : () async {
                              setState(() => busy = true);
                              try {
                                await authRepo.sendEmailVerification();
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  showAppSnack(
                                    context,
                                    'verification_email_sent'.tr(),
                                  );
                                }
                              } catch (_) {
                                if (ctx.mounted) setState(() => busy = false);
                                if (context.mounted) {
                                  showAppSnack(
                                    context,
                                    'error_unknown'.tr(),
                                    error: true,
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'close'.tr(),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ],
        );
      },
    ),
  );
}
