// lib/main.dart
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/data/repositories/notifications_repository.dart';
import 'package:jameel/data/repositories/requests_repository.dart';
import 'package:jameel/firebase_options.dart';
import 'package:jameel/layout/jameel_layout.dart';
import 'package:jameel/modules/login/login_screen.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/modules/security/pin_lock_screen.dart';
import 'package:jameel/shared/app_theme.dart';
import 'package:jameel/shared/bloc_observer.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  Bloc.observer = const MyBlocObserver();

  final firebaseReady = await _initFirebase();
  if (firebaseReady) {
    _initCrashlytics();
  }

  await Hive.initFlutter();
  await CacheHelper.init();

  // Restore the cached user (if any). Sensitive fields (salary, address) are
  // intentionally not part of the cached model.
  userModel = await getUserDataLocally();
  final initialPrefs = await AppPreferencesCubit.loadInitialState();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      // No `startLocale`: it would override the language the user picked on
      // the previous run. First launch uses the device language, falling back
      // to English when it is unsupported.
      fallbackLocale: const Locale('en'),
      child: MyApp(initialPreferences: initialPrefs),
    ),
  );
}

Future<bool> _initFirebase() async {
  try {
    if (DefaultFirebaseOptions.isConfigured) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      // Uses native platform config (e.g. git-ignored google-services.json)
      // when Dart-level defines are not supplied.
      await Firebase.initializeApp();
    }
    return true;
  } catch (e, stackTrace) {
    debugPrint('Firebase initialisation failed: $e\n$stackTrace');
    return false;
  }
}

void _initCrashlytics() {
  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint('Crashlytics setup skipped: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialPreferences});

  final AppPreferencesState? initialPreferences;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppPreferencesCubit _prefsCubit =
      AppPreferencesCubit(initialState: widget.initialPreferences);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prefsCubit.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _prefsCubit.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      _prefsCubit.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => LocationsRepository()),
        RepositoryProvider(create: (_) => RequestsRepository()),
        RepositoryProvider(create: (_) => NotificationsRepository()),
        RepositoryProvider(create: (_) => InspectionsRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _prefsCubit),
          BlocProvider(
            create: (ctx) => RequestsCubit(
              repository: ctx.read<RequestsRepository>(),
              currentUserGetter: () => _prefsCubit.state.currentUser,
            ),
          ),
        ],
        child: BlocBuilder<AppPreferencesCubit, AppPreferencesState>(
          buildWhen: (prev, curr) =>
              prev.themeMode != curr.themeMode ||
              prev.isLocked != curr.isLocked ||
              prev.currentUser != curr.currentUser,
          builder: (context, prefs) {
            final Widget home;
            if (prefs.currentUser == null) {
              home = const LoginPage();
            } else if (prefs.isLocked) {
              home = const PinLockScreen();
            } else {
              home = const HomeLayout();
            }

            final lang = context.locale.languageCode;
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(Brightness.light, languageCode: lang),
              darkTheme: buildAppTheme(Brightness.dark, languageCode: lang),
              themeMode: prefs.themeMode,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: home,
            );
          },
        ),
      ),
    );
  }
}
