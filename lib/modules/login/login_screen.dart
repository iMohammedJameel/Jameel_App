import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/layout/jameel_layout.dart';
import 'package:jameel/modules/login/cubit/cubit.dart';
import 'package:jameel/modules/login/cubit/states.dart';
import 'package:jameel/modules/login/widgets/login_decorations.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/helpers/locale_helper.dart';
import 'package:jameel/shared/styles/app_design.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _resetPassword(BuildContext context) {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showAppSnack(context, 'enter_email_first'.tr(), error: true);
      return;
    }
    context.read<LoginCubit>().resetPassword(email);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => LoginCubit(authRepository: ctx.read<AuthRepository>()),
      child: BlocConsumer<LoginCubit, LoginStates>(
        listener: (context, state) {
          if (state is LoginErrorState) {
            showAppSnack(context, state.errorKey.tr(), error: true);
          } else if (state is LoginPasswordResetSentState) {
            showAppSnack(context, 'reset_email_sent'.tr());
          } else if (state is LoginSuccessState) {
            context.read<AppPreferencesCubit>().setSessionUser(state.user);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeLayout()),
            );
          }
        },
        builder: (context, state) {
          final cubit = context.read<LoginCubit>();
          final loading = state is LoginLoadingState;
          final googleLoading = state is LoginGoogleLoadingState;
          final isBusy = loading || googleLoading;

          return Scaffold(
            backgroundColor: context.bgColor,
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: LoginMarblePainter(isDark: context.isDark),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        _buildHero(context),
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: AppCard(
                              radius: 26,
                              padding: const EdgeInsets.all(22),
                              child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AppTextField(
                                    controller: _emailController,
                                    label: 'email'.tr(),
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) =>
                                        (value == null || value.trim().isEmpty)
                                        ? 'enter_email'.tr()
                                        : null,
                                  ),
                                  const SizedBox(height: 14),
                                  AppTextField(
                                    controller: _passwordController,
                                    label: 'password'.tr(),
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: cubit.visiblePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                        ? 'enter_password'.tr()
                                        : null,
                                    suffix: IconButton(
                                      onPressed: cubit.changeVisiblePassword,
                                      icon: Icon(
                                        cubit.visiblePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed: isBusy
                                          ? null
                                          : () => _resetPassword(context),
                                      child: Text(
                                        'forgot_password'.tr(),
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  PrimaryButton(
                                    label: 'login'.tr(),
                                    loading: loading,
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            if (_formKey.currentState!
                                                .validate()) {
                                              cubit.userLogin(
                                                email: _emailController.text
                                                    .trim(),
                                                password:
                                                    _passwordController.text,
                                              );
                                            }
                                          },
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          height: 1,
                                          color: context.borderColor,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'or_continue_with'.tr(),
                                          style: TextStyle(
                                            color: context.mutedColor,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          height: 1,
                                          color: context.borderColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  GoogleSignInButton(
                                    label: 'continue_with_google'.tr(),
                                    loading: googleLoading,
                                    onPressed: isBusy
                                        ? null
                                        : () {
                                            AppHaptics.light();
                                            context
                                                .read<AppPreferencesCubit>()
                                                .suppressNextAutoLock();
                                            cubit.signInWithGoogle();
                                          },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return HeroBackground(
      radius: 40,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 56),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton.icon(
                onPressed: context.toggleLocale,
                icon: const Icon(Icons.translate_rounded, size: 18),
                label: Text('switch_language'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 264,
              height: 92,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/jameel_logo.png',
                fit: BoxFit.contain,
                cacheWidth: 840, // the source PNG is ~1 MB; decode it smaller
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'welcome_back'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'login_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
