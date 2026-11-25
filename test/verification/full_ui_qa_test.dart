import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/data/repositories/notifications_repository.dart';
import 'package:jameel/data/repositories/requests_repository.dart';
import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/jameel_layout.dart';
import 'package:jameel/models/location_model.dart';
import 'package:jameel/models/notification_model.dart';
import 'package:jameel/models/request_model.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/home/home_screen.dart';
import 'package:jameel/modules/inspection/capture_screen.dart';
import 'package:jameel/modules/login/login_screen.dart';
import 'package:jameel/modules/notifications/notifications_screen.dart';
import 'package:jameel/modules/profile_screen/profile_screen.dart';
import 'package:jameel/modules/requests_screen/employee_requests_screen.dart';
import 'package:jameel/modules/requests_screen/request_form_screen.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/modules/security/pin_lock_screen.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/styles/app_design.dart';

const String _shotDir = String.fromEnvironment('QA_SHOT_DIR');
const String _bilingualDir = String.fromEnvironment('QA_BILINGUAL_DIR');

// 1x1 transparent PNG so Image.memory decodes cleanly in widget tests.
final Uint8List _samplePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

JameelUserModel _managerFor(bool isAr) => JameelUserModel(
      uId: 'emp-mgr-1',
      userName: isAr ? 'أحمد جميل' : 'Ahmed Jameel',
      userEmail: 'ahmed@jameel.sa',
      userDepartment: isAr ? 'العمليات الميدانية' : 'Field Operations',
      role: 'manager',
      annualLeaveBalance: 18,
      assignedSiteName: isAr ? 'مقر الرياض الرئيسي' : 'Riyadh HQ',
      assignedSiteLat: 24.7136,
      assignedSiteLng: 46.6753,
      assignedSiteRadiusMeters: 500,
    );

class _MemoryAssetLoader extends AssetLoader {
  const _MemoryAssetLoader(this.translations);
  final Map<String, Map<String, dynamic>> translations;

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      translations[locale.languageCode] ?? translations['en']!;
}

class _QaAuthRepo extends AuthRepository {
  _QaAuthRepo({this.isAr = true});
  final bool isAr;

  @override
  User? get currentFirebaseUser => null;

  @override
  bool get isEmailVerified => false;

  @override
  bool get hasPasswordProvider => true;

  @override
  List<String> get linkedProviders => const ['password', 'google.com'];

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<JameelUserModel> updateEmployeeProfile({
    required String uid,
    required String name,
    required String department,
    String? email,
    DateTime? existingJoinDate,
  }) async {
    return _managerFor(isAr).copyWith(
      userName: name.trim(),
      userDepartment: department.trim(),
    );
  }
}

class _QaLocationsRepo extends LocationsRepository {
  _QaLocationsRepo({this.isAr = true});
  final bool isAr;

  @override
  Stream<List<LocationCheckInModel>> locationsStream(
    String userId, {
    int limit = LocationsRepository.historyLimit,
  }) {
    final now = DateTime.now();
    return Stream.value([
      LocationCheckInModel(
        id: 'l1',
        latitude: 24.71361,
        longitude: 46.67531,
        timestamp: now.subtract(const Duration(hours: 2)),
        type: 'check_in',
        address: isAr
            ? 'طريق الملك فهد، العليا، الرياض'
            : 'King Fahd Rd, Olaya, Riyadh',
      ),
      LocationCheckInModel(
        id: 'l2',
        latitude: 24.71210,
        longitude: 46.67400,
        timestamp: now.subtract(const Duration(days: 1, hours: 1)),
        type: 'check_out',
        address: isAr ? 'شارع التحلية، الرياض' : 'Tahlia St, Riyadh',
      ),
    ]);
  }

  @override
  Future<List<LocationCheckInModel>> getPendingCheckIns(String userId) async =>
      const [];

  @override
  Future<int> syncPendingCheckIns(String userId) async => 0;
}

class _QaRequestsRepo extends RequestsRepository {
  _QaRequestsRepo({this.isAr = true});
  final bool isAr;

  @override
  Stream<List<EmployeeRequestModel>> getRequestsStream(
    String employeeId, {
    String? statusFilter,
    int limit = RequestsRepository.recentLimit,
  }) {
    final now = DateTime.now();
    final all = [
      EmployeeRequestModel(
        id: 'r1',
        employeeId: employeeId,
        employeeName: isAr ? 'أحمد جميل' : 'Ahmed Jameel',
        type: 'leave',
        leaveCategory: 'annual',
        startDate: now.add(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 7)),
        description: isAr
            ? 'إجازة عائلية سنوية لمدة ثلاثة أيام'
            : 'Annual family vacation for three days',
        status: 'pending',
        timestamp: now,
      ),
      EmployeeRequestModel(
        id: 'r2',
        employeeId: employeeId,
        employeeName: isAr ? 'أحمد جميل' : 'Ahmed Jameel',
        type: 'loan',
        amount: 2500,
        description: isAr
            ? 'سلفة طارئة لشهر نوفمبر'
            : 'Emergency salary advance for November',
        status: 'approved',
        reviewNote:
            isAr ? 'تمت الموافقة من الموارد البشرية' : 'Approved by HR',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
    ];
    if (statusFilter != null && statusFilter != 'all') {
      return Stream.value(all.where((r) => r.status == statusFilter).toList());
    }
    return Stream.value(all);
  }

  @override
  Stream<List<EmployeeRequestModel>> getPendingApprovalsStream({
    int limit = 50,
  }) {
    return Stream.value([
      EmployeeRequestModel(
        id: 'p1',
        employeeId: 'emp-2',
        employeeName: isAr ? 'سارة محمد' : 'Sara Mohammed',
        type: 'leave',
        leaveCategory: 'emergency',
        description: isAr
            ? 'ظرف عائلي طارئ غداً'
            : 'Urgent family matter tomorrow',
        status: 'pending',
        timestamp: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<bool> hasOverlappingLeave({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      false;

  @override
  Future<void> submitRequest({
    required String type,
    required String description,
    required String employeeId,
    String? employeeName,
    String? leaveCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
  }) async {}

  @override
  Future<void> cancelRequest(String requestId) async {}

  @override
  Future<void> reviewRequest({
    required String requestId,
    required String status,
    required String reviewerId,
    String? note,
  }) async {}
}

class _QaNotificationsRepo extends NotificationsRepository {
  _QaNotificationsRepo({this.isAr = true});
  final bool isAr;

  @override
  Stream<List<String>> unreadTypesStream(String employeeId) =>
      Stream.value(const ['leave', 'announcement']);

  @override
  Future<List<NotificationModel>> fetchForEmployee(String employeeId) async {
    final now = DateTime.now();
    return [
      NotificationModel(
        id: 'n1',
        title: isAr ? 'تحديث طلب الإجازة' : 'Leave Request Update',
        message: isAr
            ? 'طلبك السنوي قيد المراجعة لدى المدير المباشر.'
            : 'Your annual leave request is under direct manager review.',
        type: 'leave',
        date: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n2',
        title: isAr ? 'إعلان إداري' : 'Company Announcement',
        message: isAr
            ? 'تحديث مواعيد الدوام الرسمية للأسبوع القادم.'
            : 'Updated official working hours schedule for next week.',
        type: 'announcement',
        date: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markManyAsRead(Iterable<String> ids) async {}
}

class _QaInspectionsRepo extends InspectionsRepository {
  @override
  Future<List<LocalInspection>> getLocalInspections({
    String? employeeId,
  }) async {
    return [
      LocalInspection(
        key: 0,
        bytes: _samplePng,
        latitude: 24.7136,
        longitude: 46.6753,
        capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
        synced: true,
        employeeId: employeeId,
      ),
    ];
  }

  @override
  Future<int> getPendingCount({String? employeeId}) async => 0;

  @override
  Future<int> syncPending({required String employeeId}) async => 0;

  @override
  Future<void> clearLocalInspections() async {}
}

class _QaConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream<List<ConnectivityResult>>.empty();
}

void main() {
  late Directory tempDir;
  late Map<String, Map<String, dynamic>> translations;
  var fontLoaded = false;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Load Tahoma TTF (Windows) + MaterialIcons (from FLUTTER_ROOT / SDK cache)
    // so both Arabic/English text and Icons render with real glyph metrics.
    final fontFile = File(r'C:\Windows\Fonts\tahoma.ttf');
    if (fontFile.existsSync()) {
      final bytes = fontFile.readAsBytesSync();
      final loader = FontLoader('TestTahoma')
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      fontLoaded = true;
    }
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final iconCandidates = <String>[
      if (flutterRoot != null && flutterRoot.isNotEmpty)
        '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts${Platform.pathSeparator}MaterialIcons-Regular.otf',
      r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    ];
    for (final path in iconCandidates) {
      final iconsFile = File(path);
      if (iconsFile.existsSync()) {
        final iconBytes = iconsFile.readAsBytesSync();
        final iconLoader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(iconBytes)));
        await iconLoader.load();
        break;
      }
    }

    // Mock shared_preferences & geolocator channels cleanly for headless tests.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/shared_preferences'),
      (call) async {
        if (call.method == 'getAll') return <String, Object>{};
        return true;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (call) async {
        if (call.method == 'checkPermission') return 3; // whileInUse
        return true;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (call) async => null,
    );

    EasyLocalization.logger.enableBuildModes = [];
    await EasyLocalization.ensureInitialized();

    final enJson = jsonDecode(
      File('assets/translations/en.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final arJson = jsonDecode(
      File('assets/translations/ar.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    translations = {'en': enJson, 'ar': arJson};

    tempDir = Directory.systemTemp.createTempSync('jameel_qa_test_');
    Hive.init(tempDir.path);
    await CacheHelper.init(enableEncryption: false);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  ThemeData qaTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: fontLoaded ? 'TestTahoma' : null,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
      ).copyWith(
        primary: AppColors.primary,
        surface: isDark ? AppColors.darkSurface : AppColors.surface,
        onSurface: isDark ? AppColors.darkInk : AppColors.ink,
      ),
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.background,
    );
  }

  Future<void> captureShot(
    WidgetTester tester,
    GlobalKey boundaryKey,
    String fileName, {
    String dirOverride = _shotDir,
  }) async {
    if (dirOverride.isEmpty) return;
    await tester.runAsync(() async {
      final ctx = boundaryKey.currentContext;
      if (ctx == null) return;
      final boundary = ctx.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return;
      final outDir = Directory(dirOverride)..createSync(recursive: true);
      File('${outDir.path}${Platform.pathSeparator}$fileName')
          .writeAsBytesSync(byteData.buffer.asUint8List());
    });
  }

  Future<void> mountScreen(
    WidgetTester tester, {
    required Size size,
    required Locale locale,
    required Widget child,
    Brightness brightness = Brightness.light,
    double textScale = 1.0,
    GlobalKey? shotKey,
    AppPreferencesCubit? prefsCubit,
  }) async {
    final isAr = locale.languageCode == 'ar';
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = prefsCubit ??
        AppPreferencesCubit(
          initialState: AppPreferencesState(
            currentUser: _managerFor(isAr),
            themeMode:
                brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
            pinHash: AppPreferencesCubit.hashPin('1234'),
          ),
        );
    if (prefsCubit == null) addTearDown(prefs.close);

    final authRepo = _QaAuthRepo(isAr: isAr);
    final locRepo = _QaLocationsRepo(isAr: isAr);
    final reqRepo = _QaRequestsRepo(isAr: isAr);
    final notifRepo = _QaNotificationsRepo(isAr: isAr);
    final inspRepo = _QaInspectionsRepo();

    Widget app = EasyLocalization(
      key: UniqueKey(),
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      assetLoader: _MemoryAssetLoader(translations),
      startLocale: locale,
      fallbackLocale: const Locale('en'),
      saveLocale: false,
      child: Builder(
        builder: (context) => MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>.value(value: authRepo),
            RepositoryProvider<LocationsRepository>.value(value: locRepo),
            RepositoryProvider<RequestsRepository>.value(value: reqRepo),
            RepositoryProvider<NotificationsRepository>.value(value: notifRepo),
            RepositoryProvider<InspectionsRepository>.value(value: inspRepo),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AppPreferencesCubit>.value(value: prefs),
              BlocProvider<RequestsCubit>(
                create: (_) => RequestsCubit(
                  repository: reqRepo,
                  currentUserGetter: () => prefs.state.currentUser,
                ),
              ),
              BlocProvider<JameelCubit>(
                create: (_) => JameelCubit(
                  locationsRepository: locRepo,
                  authRepository: authRepo,
                  inspectionsRepository: inspRepo,
                  connectivity: _QaConnectivity(),
                  currentUserGetter: () => prefs.state.currentUser,
                ),
              ),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: qaTheme(brightness),
              builder: (ctx, w) => MediaQuery(
                data: MediaQuery.of(ctx).copyWith(
                  textScaler: TextScaler.linear(textScale),
                ),
                child: w!,
              ),
              home: child,
            ),
          ),
        ),
      ),
    );

    if (shotKey != null) {
      app = RepaintBoundary(key: shotKey, child: app);
    }

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  final sizes = <String, Size>{
    'small_320': const Size(320, 568),
    'phone_390': const Size(390, 844),
    'tablet_800': const Size(800, 1280),
  };

  group('Multi-Size Visual & Interactive QA', () {
    testWidgets('LoginPage across sizes, locales, buttons, and #FDFDFD logo card', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        for (final locale in const [Locale('ar'), Locale('en')]) {
          final key = GlobalKey();
          await mountScreen(
            tester,
            size: entry.value,
            locale: locale,
            textScale: entry.key == 'small_320' ? 1.2 : 1.0,
            shotKey: entry.key != 'small_320' && locale.languageCode == 'ar'
                ? key
                : null,
            child: const LoginPage(),
          );

          // Verify logo image and #FDFDFD container background color.
          expect(find.byType(Image), findsOneWidget);
          final logoContainers = find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color == const Color(0xFFFDFDFD),
          );
          expect(logoContainers, findsOneWidget);

          // Toggle password visibility icon button & trigger forgot-password snack.
          await tester.tap(find.byIcon(Icons.visibility_off_outlined));
          await tester.pump();
          expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

          await tester.tap(find.byIcon(Icons.translate_rounded));
          await tester.pumpAndSettle();

          if (entry.key == 'phone_390' && locale.languageCode == 'ar') {
            // Restore Arabic before snapshot after testing language toggle.
            await tester.tap(find.byIcon(Icons.translate_rounded));
            await tester.pumpAndSettle();
            await captureShot(tester, key, 'qa_login_${entry.key}.png');
          }
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('PinLockScreen renders keypad cleanly across all 3 sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          shotKey: entry.key == 'phone_390' ? key : null,
          child: const PinLockScreen(),
        );

        for (final d in ['0', '1', '5', '9']) {
          expect(find.text(d), findsOneWidget);
        }
        await tester.tap(find.text('1'));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.backspace_outlined));
        await tester.pump();

        if (entry.key == 'phone_390') {
          await captureShot(tester, key, 'qa_pin_phone.png');
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('HomePageScreen renders header, shift summary, quick actions & list across all sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          textScale: entry.key == 'small_320' ? 1.25 : 1.0,
          shotKey: entry.key == 'phone_390' || entry.key == 'small_320'
              ? key
              : null,
          child: const HomePageScreen(),
        );

        expect(find.text('أحمد جميل'), findsOneWidget);
        expect(find.text('مقر الرياض الرئيسي'), findsOneWidget);
        expect(find.byIcon(Icons.logout_rounded), findsWidgets);
        expect(find.byIcon(Icons.photo_camera_rounded), findsOneWidget);
        expect(find.byIcon(Icons.view_list_rounded), findsOneWidget);
        expect(find.byIcon(Icons.map_rounded), findsOneWidget);

        if (entry.key == 'phone_390' || entry.key == 'small_320') {
          await captureShot(tester, key, 'qa_home_${entry.key}.png');
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('EmployeeRequestsScreen 2x2 centered grid, filters, details sheet & approvals sheet across sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          textScale: entry.key == 'small_320' ? 1.2 : 1.0,
          shotKey: entry.key != 'small_320' ? key : null,
          child: const EmployeeRequestsScreen(),
        );

        // Verify all 4 new request cards are present (2 rows of 2 cards) and centered.
        for (final icon in [
          Icons.beach_access_rounded,
          Icons.payments_rounded,
          Icons.report_problem_rounded,
          Icons.lightbulb_rounded,
        ]) {
          expect(find.byIcon(icon), findsWidgets);
        }

        // Verify card texts use TextAlign.center.
        final leaveTitle = tester.widget<Text>(find.text('طلب إجازة').first);
        expect(leaveTitle.textAlign, TextAlign.center);

        if (entry.key != 'small_320') {
          await captureShot(tester, key, 'qa_requests_${entry.key}.png');
        }

        // Test filter chip switch & Team Approvals sheet.
        final approvedChip = find.text('تمت الموافقة').first;
        await tester.ensureVisible(approvedChip);
        await tester.tap(approvedChip);
        await tester.pumpAndSettle();
        final allChip = find.text('الكل').first;
        await tester.ensureVisible(allChip);
        await tester.tap(allChip);
        await tester.pumpAndSettle();

        final approvalsBtn = find.text('اعتمادات الفريق');
        await tester.ensureVisible(approvalsBtn);
        await tester.tap(approvalsBtn);
        await tester.pumpAndSettle();
        expect(find.text('سارة محمد'), findsOneWidget);
        Navigator.of(tester.element(find.text('سارة محمد'))).pop();
        await tester.pumpAndSettle();

        // Tap pending request to open RequestDetailsSheet + status timeline.
        final pendingReq = find.text('قيد المراجعة').last;
        await tester.ensureVisible(pendingReq);
        await tester.tap(pendingReq);
        await tester.pumpAndSettle();
        expect(find.text('إلغاء الطلب'), findsOneWidget);
        await tester.ensureVisible(find.text('إغلاق'));
        await tester.tap(find.text('إغلاق'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('RequestFormScreen works for leave & loan with quick presets across sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          shotKey: entry.key == 'phone_390' ? key : null,
          child: const RequestFormScreen(requestType: 'leave'),
        );

        expect(find.byType(PrimaryButton), findsOneWidget);
        await tester.ensureVisible(find.text('مرضية'));
        await tester.tap(find.text('مرضية'));
        await tester.pumpAndSettle();
        if (entry.key == 'phone_390') {
          await captureShot(tester, key, 'qa_request_form_leave.png');
        }
        expect(tester.takeException(), isNull);

        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('en'),
          child: const RequestFormScreen(requestType: 'loan'),
        );
        await tester.ensureVisible(find.text('1000'));
        await tester.tap(find.text('1000'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('NotificationsScreen search, unread toggle, mark all & clear filters across sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          shotKey: entry.key == 'phone_390' ? key : null,
          child: const NotificationsScreen(),
        );

        expect(find.text('تحديث طلب الإجازة'), findsOneWidget);
        expect(find.text('إعلان إداري'), findsOneWidget);
        if (entry.key == 'phone_390') {
          await captureShot(tester, key, 'qa_notifications_phone.png');
        }

        // Filter to unmatched query -> shows Clear Filters button, then clears.
        await tester.enterText(find.byType(TextField), 'xyz_none');
        await tester.pumpAndSettle();
        expect(find.text('مسح الفلاتر'), findsOneWidget);
        await tester.tap(find.text('مسح الفلاتر'));
        await tester.pumpAndSettle();
        expect(find.text('تحديث طلب الإجازة'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.done_all_rounded));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('CaptureScreen guidelines, preview, and zoomable history dialog across sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          shotKey: entry.key == 'phone_390' ? key : null,
          child: const CaptureScreen(),
        );

        expect(find.text('فتح الكاميرا'), findsOneWidget);
        expect(find.text('صور التفتيش الأخيرة'), findsOneWidget);
        if (entry.key == 'phone_390') {
          await captureShot(tester, key, 'qa_capture_phone.png');
        }

        // Expand guidelines card & open local inspection zoom dialog.
        await tester.ensureVisible(find.text('إرشادات التصوير'));
        await tester.tap(find.text('إرشادات التصوير'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.pin_drop_rounded), findsOneWidget);

        await tester.ensureVisible(find.text('تمت المزامنة'));
        await tester.tap(find.text('تمت المزامنة'));
        await tester.pumpAndSettle();
        expect(find.byType(InteractiveViewer), findsOneWidget);
        await tester.tap(find.text('إغلاق'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('ProfileScreen & all 7 bottom sheets + logout dialog work cleanly across sizes', (
      tester,
    ) async {
      for (final entry in sizes.entries) {
        final key = GlobalKey();
        await mountScreen(
          tester,
          size: entry.value,
          locale: const Locale('ar'),
          brightness: Brightness.light,
          shotKey: entry.key == 'phone_390' ? key : null,
          child: const ProfileScreen(),
        );

        if (entry.key == 'phone_390') {
          await captureShot(tester, key, 'qa_profile_phone.png');
        }

        // Open and dismiss key sheets cleanly without overflow.
        for (final title in [
          'تعديل المعلومات الشخصية',
          'إدارة معلومات حسابك',
          'المظهر',
          'الإشعارات',
          'إدارة خيارات الخصوصية',
          'تغيير كلمة المرور',
          'المصادقة الثنائية',
        ]) {
          final finder = find.text(title);
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
          Navigator.of(tester.element(find.byType(BottomSheet))).pop();
          await tester.pumpAndSettle();
        }

        // Open Logout dialog & cancel cleanly.
        final logoutFinder = find.text('تسجيل الخروج');
        await tester.ensureVisible(logoutFinder);
        await tester.tap(logoutFinder);
        await tester.pumpAndSettle();
        expect(find.text('تأكيد تسجيل الخروج'), findsOneWidget);
        await tester.tap(find.text('إلغاء'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('HomeLayout bottom navigation switches across all 4 tabs with live unread badge', (
      tester,
    ) async {
      await mountScreen(
        tester,
        size: sizes['phone_390']!,
        locale: const Locale('ar'),
        child: const HomeLayout(),
      );

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // unread badge from stream

      for (final tab in ['الطلبات', 'التنبيهات', 'الملف الشخصي', 'الرئيسية']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Bilingual portfolio screenshots export (when QA_BILINGUAL_DIR is set)', (
      tester,
    ) async {
      if (_bilingualDir.isEmpty) return;

      for (final lang in ['en', 'ar']) {
        final locale = Locale(lang);
        final isAr = lang == 'ar';

        // 1. Login Screen (with precached logo PNG)
        final loginKey = GlobalKey();
        await mountScreen(
          tester,
          size: sizes['phone_390']!,
          locale: locale,
          shotKey: loginKey,
          child: const LoginPage(),
        );
        await tester.runAsync(() async {
          await precacheImage(
            const AssetImage('assets/images/jameel_logo.png'),
            tester.element(find.byType(LoginPage)),
          );
        });
        await tester.pumpAndSettle();
        await captureShot(
          tester,
          loginKey,
          'login_$lang.png',
          dirOverride: _bilingualDir,
        );

        // 2. PIN Lock Screen
        final pinKey = GlobalKey();
        await mountScreen(
          tester,
          size: sizes['phone_390']!,
          locale: locale,
          shotKey: pinKey,
          child: const PinLockScreen(),
        );
        await captureShot(
          tester,
          pinKey,
          'pin_lock_$lang.png',
          dirOverride: _bilingualDir,
        );

        // 3–6. Main HomeLayout Tabs (Home, Requests, Notifications, Profile)
        final layoutKey = GlobalKey();
        await mountScreen(
          tester,
          size: sizes['phone_390']!,
          locale: locale,
          shotKey: layoutKey,
          child: const HomeLayout(),
        );
        await captureShot(
          tester,
          layoutKey,
          'home_$lang.png',
          dirOverride: _bilingualDir,
        );

        final tabs = <String, String>{
          'requests': isAr ? 'الطلبات' : 'Requests',
          'notifications': isAr ? 'التنبيهات' : 'Alerts',
          'profile': isAr ? 'الملف الشخصي' : 'Profile',
        };
        for (final entry in tabs.entries) {
          await tester.tap(find.text(entry.value).last);
          await tester.pumpAndSettle();
          await captureShot(
            tester,
            layoutKey,
            '${entry.key}_$lang.png',
            dirOverride: _bilingualDir,
          );
        }

        // 7. Site Inspection Capture Screen
        final captureKey = GlobalKey();
        await mountScreen(
          tester,
          size: sizes['phone_390']!,
          locale: locale,
          shotKey: captureKey,
          child: const CaptureScreen(),
        );
        await captureShot(
          tester,
          captureKey,
          'capture_$lang.png',
          dirOverride: _bilingualDir,
        );

        // 8. Leave Request Form Screen
        final formKey = GlobalKey();
        await mountScreen(
          tester,
          size: sizes['phone_390']!,
          locale: locale,
          shotKey: formKey,
          child: const RequestFormScreen(requestType: 'leave'),
        );
        await captureShot(
          tester,
          formKey,
          'request_form_$lang.png',
          dirOverride: _bilingualDir,
        );
      }
    });
  });
}
