import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/profile_screen/sheets/profile_sheet_scaffold.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

void showChangePasswordSheet(BuildContext context, JameelUserModel user) {
  showProfileSheet<void>(
    context,
    title: 'change_password'.tr(),
    bodyBuilder: (_) => _ChangePasswordForm(user: user, hostContext: context),
  );
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm({
    required this.user,
    required this.hostContext,
  });

  final JameelUserModel user;
  final BuildContext hostContext;

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordSetupEmail(String email) async {
    final authRepo = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await authRepo.sendPasswordReset(email);
      if (mounted) Navigator.pop(context);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'reset_email_sent'.tr());
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'error_unknown'.tr(), error: true);
      }
    }
  }

  Future<void> _submitChange() async {
    if (!_formKey.currentState!.validate()) return;
    final authRepo = context.read<AuthRepository>();
    setState(() => _busy = true);
    try {
      await authRepo.changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) Navigator.pop(context);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'password_changed'.tr());
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _busy = false);
      final key = switch (e.code) {
        'wrong-password' || 'invalid-credential' => 'wrong_current_password',
        'weak-password' => 'password_too_short',
        'network-request-failed' => 'error_network',
        _ => 'error_unknown',
      };
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, key.tr(), error: true);
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      if (widget.hostContext.mounted) {
        showAppSnack(widget.hostContext, 'error_unknown'.tr(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = context.read<AuthRepository>().hasPasswordProvider;
    if (!hasPassword) {
      final email = widget.user.userEmail ?? '';
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'google_account_password_hint'.tr(),
            style: TextStyle(
              color: context.mutedColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (email.isNotEmpty)
            PrimaryButton(
              label: 'send_password_setup_email'.tr(),
              loading: _busy,
              onPressed: _busy ? null : () => _sendPasswordSetupEmail(email),
            )
          else
            PrimaryButton(
              label: 'close'.tr(),
              onPressed: () => Navigator.pop(context),
            ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _currentCtrl,
            label: 'current_password'.tr(),
            icon: Icons.lock_outline_rounded,
            obscureText: _obscure,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'enter_password'.tr() : null,
            suffix: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: context.mutedColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _newCtrl,
            label: 'new_password'.tr(),
            icon: Icons.lock_reset_rounded,
            obscureText: _obscure,
            validator: (v) {
              if (v == null || v.length < 6) {
                return 'password_too_short'.tr();
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _confirmCtrl,
            label: 'confirm_new_password'.tr(),
            icon: Icons.lock_reset_rounded,
            obscureText: _obscure,
            validator: (v) =>
                v != _newCtrl.text ? 'passwords_do_not_match'.tr() : null,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'change_password'.tr(),
            loading: _busy,
            onPressed: _busy ? null : _submitChange,
          ),
        ],
      ),
    );
  }
}

void showSecurityPinSheet(BuildContext context) {
  showProfileSheet<void>(
    context,
    title: 'two_factor_auth'.tr(),
    bodyBuilder: (_) => _SecurityPinForm(hostContext: context),
  );
}

class _SecurityPinForm extends StatefulWidget {
  const _SecurityPinForm({required this.hostContext});

  final BuildContext hostContext;

  @override
  State<_SecurityPinForm> createState() => _SecurityPinFormState();
}

class _SecurityPinFormState extends State<_SecurityPinForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
      builder: (ctx, prefs) {
        final hasPin = prefs.hasSecurityPin;
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'app_pin_lock'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: ctx.inkColor,
                      ),
                    ),
                  ),
                  StatusChip(
                    label: hasPin ? 'enabled'.tr() : 'disabled'.tr(),
                    color: hasPin ? AppColors.success : ctx.mutedColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'app_pin_lock_hint'.tr(),
                style: TextStyle(
                  fontSize: 13.5,
                  color: ctx.mutedColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (hasPin) ...[
                AppTextField(
                  controller: _currentPinCtrl,
                  label: 'current_pin'.tr(),
                  icon: Icons.pin_outlined,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final pin = v?.trim() ?? '';
                    if (pin.length < 4) return 'pin_invalid_length'.tr();
                    if (!ctx.read<AppPreferencesCubit>().verifyPin(pin)) {
                      return 'pin_incorrect'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await ctx.read<AppPreferencesCubit>().removeSecurityPin();
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (widget.hostContext.mounted) {
                      showAppSnack(
                        widget.hostContext,
                        'security_pin_disabled'.tr(),
                      );
                    }
                  },
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
                  child: Text(
                    'disable_pin'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ] else ...[
                AppTextField(
                  controller: _newPinCtrl,
                  label: 'new_pin'.tr(),
                  icon: Icons.pin_outlined,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final pin = v?.trim() ?? '';
                    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                      return 'pin_invalid_length'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'enable_pin'.tr(),
                  icon: Icons.shield_rounded,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    await ctx
                        .read<AppPreferencesCubit>()
                        .setSecurityPin(_newPinCtrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (widget.hostContext.mounted) {
                      showAppSnack(
                        widget.hostContext,
                        'security_pin_enabled'.tr(),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
