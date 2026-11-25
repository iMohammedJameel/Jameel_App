import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/styles/app_design.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _errorText;
  Timer? _cooldownTimer;
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  @override
  void initState() {
    super.initState();
    _syncCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _syncCooldownTimer() {
    final prefsCubit = context.read<AppPreferencesCubit>();
    if (!prefsCubit.state.isPinCooldownActive) return;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      prefsCubit.clearCooldownIfExpired();
      if (!prefsCubit.state.isPinCooldownActive) {
        timer.cancel();
        setState(() => _errorText = null);
      } else {
        setState(() {});
      }
    });
  }

  void _appendDigit(String digit) {
    final prefsCubit = context.read<AppPreferencesCubit>();
    if (prefsCubit.state.isPinCooldownActive || _pin.length >= 6) return;
    AppHaptics.light();
    setState(() {
      _pin += digit;
      _errorText = null;
    });
    if (_pin.length >= 4 && prefsCubit.verifyAndUnlock(_pin)) {
      AppHaptics.medium();
    } else if (_pin.length == 6) {
      _unlock();
    }
  }

  void _backspace() {
    if (_pin.isEmpty) return;
    AppHaptics.light();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorText = null;
    });
  }

  void _clear() {
    if (_pin.isEmpty) return;
    AppHaptics.light();
    setState(() {
      _pin = '';
      _errorText = null;
    });
  }

  void _unlock() {
    final prefsCubit = context.read<AppPreferencesCubit>();
    if (prefsCubit.state.isPinCooldownActive) {
      _syncCooldownTimer();
      return;
    }
    if (_pin.length < 4) {
      AppHaptics.error();
      _shakeCtrl.forward(from: 0);
      setState(() => _errorText = 'pin_invalid_length'.tr());
      return;
    }
    final ok = prefsCubit.verifyAndUnlock(_pin);
    if (!ok) {
      AppHaptics.error();
      _shakeCtrl.forward(from: 0);
      if (prefsCubit.state.isPinCooldownActive) {
        _syncCooldownTimer();
      }
      setState(() {
        _errorText = 'pin_incorrect'.tr();
        _pin = '';
      });
    } else {
      AppHaptics.medium();
    }
  }

  Future<void> _signOut() async {
    final prefsCubit = context.read<AppPreferencesCubit>();
    await context.read<AuthRepository>().signOut();
    await CacheHelper.clearSessionSecurity();
    await prefsCubit.removeSecurityPin();
    if (!mounted) return;
    prefsCubit.setSessionUser(null);
  }

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferencesCubit>().state;
    final user = prefs.currentUser;
    final rawName = user?.userName?.trim() ?? '';
    final dotCount = math.max(4, _pin.length);
    final lockedCooldown = prefs.isPinCooldownActive;
    final statusMessage = lockedCooldown
        ? 'pin_locked_wait'.tr(
            namedArgs: {'seconds': '${prefs.pinCooldownRemainingSeconds}'},
          )
        : _errorText;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: PageOrnamentBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InitialsAvatar(
                    name: rawName.isEmpty ? 'J' : rawName,
                    size: 64,
                    photoUrl: user?.photoUrl,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'enter_security_pin'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: context.inkColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'security_pin_subtitle'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: context.mutedColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _shakeCtrl,
                    builder: (context, child) {
                      final offset =
                          math.sin(_shakeCtrl.value * math.pi * 4) * 10;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(dotCount, (i) {
                          final filled = i < _pin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: filled ? 18 : 15,
                            height: filled ? 18 : 15,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: statusMessage != null
                                    ? AppColors.primary
                                    : (filled
                                        ? AppColors.primary
                                        : context.borderColor),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 22,
                    child: statusMessage != null
                        ? Text(
                            statusMessage,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildNumpad(context, disabled: lockedCooldown),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'unlock'.tr(),
                    icon: Icons.lock_open_rounded,
                    onPressed: lockedCooldown ? null : _unlock,
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: _signOut,
                    child: Text(
                      'logout'.tr(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(BuildContext context, {bool disabled = false}) {
    Widget keyButton({
      String? digit,
      IconData? icon,
      VoidCallback? onTap,
    }) {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: context.surfaceColor,
          shape: CircleBorder(side: BorderSide(color: context.borderColor)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : onTap,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Center(
                child: digit != null
                    ? Text(
                        digit,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: disabled
                              ? context.mutedColor.withValues(alpha: 0.4)
                              : context.inkColor,
                        ),
                      )
                    : Icon(icon, size: 21, color: context.mutedColor),
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in ['1', '2', '3'])
                keyButton(digit: d, onTap: () => _appendDigit(d)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in ['4', '5', '6'])
                keyButton(digit: d, onTap: () => _appendDigit(d)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final d in ['7', '8', '9'])
                keyButton(digit: d, onTap: () => _appendDigit(d)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              keyButton(icon: Icons.clear_rounded, onTap: _clear),
              keyButton(digit: '0', onTap: () => _appendDigit('0')),
              keyButton(icon: Icons.backspace_outlined, onTap: _backspace),
            ],
          ),
        ],
      ),
    );
  }
}
