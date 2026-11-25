// lib/layout/jameel_layout.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/data/repositories/notifications_repository.dart';
import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/modules/home/home_screen.dart';
import 'package:jameel/modules/notifications/notifications_screen.dart';
import 'package:jameel/modules/profile_screen/profile_screen.dart';
import 'package:jameel/modules/requests_screen/employee_requests_screen.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/services/push_notifications_service.dart';
import 'package:jameel/shared/styles/app_design.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  // Tab pages live in the layout (UI layer), not in the cubit (state layer).
  static const List<Widget> _pages = [
    HomePageScreen(),
    EmployeeRequestsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  PushNotificationsService? _pushService;
  Stream<List<String>>? _unreadTypesStream;
  String? _uid;

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository>();
    _uid = context.read<AppPreferencesCubit>().state.currentUser?.uId;
    if (_uid != null && _uid!.isNotEmpty) {
      _unreadTypesStream =
          context.read<NotificationsRepository>().unreadTypesStream(_uid!);
    }
    _pushService = PushNotificationsService(authRepository: authRepo)
      ..initForEmployee(
        _uid,
        onForegroundMessage: (title, body) {
          if (!mounted) return;
          final msg = [title, body].where((s) => s.trim().isNotEmpty).join(': ');
          if (msg.isNotEmpty) showAppSnack(context, msg);
        },
      );
  }

  @override
  void dispose() {
    _pushService?.dispose();
    super.dispose();
  }

  Widget _alertsIcon(bool selected, int unreadCount) {
    final icon = Icon(
      selected
          ? Icons.notifications_rounded
          : Icons.notifications_none_rounded,
    );
    if (unreadCount <= 0) return icon;
    return Badge(
      backgroundColor: AppColors.primary,
      textColor: Colors.white,
      label: Text(
        unreadCount > 99 ? '99+' : '$unreadCount',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
      ),
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => JameelCubit(
        locationsRepository: ctx.read<LocationsRepository>(),
        authRepository: ctx.read<AuthRepository>(),
        inspectionsRepository: ctx.read<InspectionsRepository>(),
        currentUserGetter: () =>
            ctx.read<AppPreferencesCubit>().state.currentUser,
      )..startAutoSync(),
      child: BlocBuilder<JameelCubit, JameelStates>(
        buildWhen: (_, state) => state is JameelChangeBottomNavState,
        builder: (context, state) {
          final cubit = JameelCubit.get(context);
          final langCode = context.locale.languageCode;
          return Scaffold(
            body: KeyedSubtree(
              key: ValueKey<String>(langCode),
              child: IndexedStack(
                index: cubit.selectedIndex,
                children: _pages,
              ),
            ),
            bottomNavigationBar: StreamBuilder<List<String>>(
              stream: _unreadTypesStream,
              builder: (context, snap) {
                final prefs = context.watch<AppPreferencesCubit>().state;
                final types = snap.data ?? const <String>[];
                final unread = types.where(prefs.isCategoryEnabled).length;
                return Container(
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border(
                      top: BorderSide(color: context.borderColor),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: NavigationBar(
                      selectedIndex: cubit.selectedIndex,
                      onDestinationSelected: (index) {
                        AppHaptics.light();
                        cubit.changeBottomNavBar(index);
                      },
                      labelBehavior:
                          NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                        NavigationDestination(
                          icon: const Icon(Icons.home_outlined),
                          selectedIcon: const Icon(Icons.home_rounded),
                          label: 'home'.tr(),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.assignment_outlined),
                          selectedIcon: const Icon(Icons.assignment_rounded),
                          label: 'requests'.tr(),
                        ),
                        NavigationDestination(
                          icon: _alertsIcon(false, unread),
                          selectedIcon: _alertsIcon(true, unread),
                          label: 'alerts'.tr(),
                        ),
                        NavigationDestination(
                          icon: const Icon(Icons.person_outline_rounded),
                          selectedIcon: const Icon(Icons.person_rounded),
                          label: 'profile'.tr(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
