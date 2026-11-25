import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/models/location_model.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

class _FakeAuthRepository extends AuthRepository {
  bool signedOut = false;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

class _FakeLocationsRepository extends LocationsRepository {
  int pendingCount = 2;
  bool syncedCalled = false;

  @override
  Future<List<LocationCheckInModel>> getPendingCheckIns(String userId) async {
    return List.generate(
      pendingCount,
      (i) => LocationCheckInModel(
        id: 'off_$i',
        latitude: 30.0,
        longitude: 31.0,
        timestamp: DateTime(2026, 6, 1),
        isSynced: false,
      ),
    );
  }

  @override
  Future<int> syncPendingCheckIns(String userId) async {
    syncedCalled = true;
    final count = pendingCount;
    pendingCount = 0;
    return count;
  }
}

class _FakeInspectionsRepository extends InspectionsRepository {
  int pendingCount = 1;
  bool syncedCalled = false;

  @override
  Future<int> getPendingCount({String? employeeId}) async => pendingCount;

  @override
  Future<int> syncPending({required String employeeId}) async {
    syncedCalled = true;
    final count = pendingCount;
    pendingCount = 0;
    return count;
  }
}

class _FakeConnectivity implements Connectivity {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async =>
      const [ConnectivityResult.wifi];

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      const Stream<List<ConnectivityResult>>.empty();
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('jameel_layout_cubit_test_');
    Hive.init(tempDir.path);
    await CacheHelper.init(enableEncryption: false);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('JameelCubit', () {
    test('syncAllPending uploads offline check-ins & inspections and resets counts', () async {
      final locRepo = _FakeLocationsRepository();
      final inspRepo = _FakeInspectionsRepository();
      final cubit = JameelCubit(
        locationsRepository: locRepo,
        authRepository: _FakeAuthRepository(),
        inspectionsRepository: inspRepo,
        connectivity: _FakeConnectivity(),
        currentUserGetter: () => const JameelUserModel(uId: 'emp-1'),
      );

      final synced = await cubit.syncAllPending();
      expect(synced, 3);
      expect(locRepo.syncedCalled, isTrue);
      expect(inspRepo.syncedCalled, isTrue);
      expect(cubit.totalPendingSyncCount, 0);

      await cubit.close();
    });

    test('signOut clears user, security PIN, and emits SignOutSuccessState', () async {
      await CacheHelper.cacheUser(const JameelUserModel(uId: 'emp-1'));
      await CacheHelper.setSecurityPinHash('abc');
      userModel = const JameelUserModel(uId: 'emp-1');

      final authRepo = _FakeAuthRepository();
      final cubit = JameelCubit(
        locationsRepository: _FakeLocationsRepository(),
        authRepository: authRepo,
        inspectionsRepository: _FakeInspectionsRepository(),
        connectivity: _FakeConnectivity(),
        currentUserGetter: () => userModel,
      );

      await cubit.signOut();

      expect(authRepo.signedOut, isTrue);
      expect(userModel, isNull);
      expect(await CacheHelper.getCachedUser(), isNull);
      expect(await CacheHelper.getSecurityPinHash(), isNull);
      expect(cubit.state, isA<SignOutSuccessState>());

      await cubit.close();
    });

    test('changeBottomNavBar updates index only when changed', () async {
      final cubit = JameelCubit(
        locationsRepository: _FakeLocationsRepository(),
        authRepository: _FakeAuthRepository(),
        inspectionsRepository: _FakeInspectionsRepository(),
        connectivity: _FakeConnectivity(),
      );

      cubit.changeBottomNavBar(2);
      expect(cubit.selectedIndex, 2);
      expect(cubit.state, isA<JameelChangeBottomNavState>());

      await cubit.close();
    });
  });
}
