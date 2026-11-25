import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/data/repositories/inspections_repository.dart';
import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/helpers/location_helper.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

class JameelCubit extends Cubit<JameelStates> {
  JameelCubit({
    LocationsRepository? locationsRepository,
    AuthRepository? authRepository,
    InspectionsRepository? inspectionsRepository,
    Connectivity? connectivity,
    JameelUserModel? Function()? currentUserGetter,
  })  : _locationsRepository = locationsRepository ?? LocationsRepository(),
        _authRepository = authRepository ?? AuthRepository(),
        _inspectionsRepository =
            inspectionsRepository ?? InspectionsRepository(),
        _connectivity = connectivity ?? Connectivity(),
        _currentUserGetter = currentUserGetter ?? (() => userModel),
        super(JameelInitialState());

  final LocationsRepository _locationsRepository;
  final AuthRepository _authRepository;
  final InspectionsRepository _inspectionsRepository;
  final Connectivity _connectivity;
  final JameelUserModel? Function() _currentUserGetter;

  int selectedIndex = 0;
  int pendingInspectionsCount = 0;
  int pendingCheckInsCount = 0;
  bool isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int get totalPendingSyncCount =>
      pendingInspectionsCount + pendingCheckInsCount;

  static JameelCubit get(BuildContext context) =>
      BlocProvider.of<JameelCubit>(context);

  void startAutoSync() {
    _connectivitySub ??= _connectivity.onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) {
        syncAllPending();
      }
    });
    syncAllPending();
  }

  Future<void> refreshPendingCounts() async {
    final uid = _currentUserGetter()?.uId;
    pendingInspectionsCount =
        await _inspectionsRepository.getPendingCount(employeeId: uid);
    pendingCheckInsCount = uid == null || uid.isEmpty
        ? 0
        : (await _locationsRepository.getPendingCheckIns(uid)).length;
    if (!isClosed) emit(OfflineSyncStateChanged());
  }

  Future<int> syncAllPending() async {
    final uid = _currentUserGetter()?.uId;
    if (uid == null || uid.isEmpty) {
      await refreshPendingCounts();
      return 0;
    }
    if (isSyncing) return 0;

    pendingInspectionsCount =
        await _inspectionsRepository.getPendingCount(employeeId: uid);
    pendingCheckInsCount =
        (await _locationsRepository.getPendingCheckIns(uid)).length;
    if (totalPendingSyncCount == 0) {
      if (!isClosed) emit(OfflineSyncStateChanged());
      return 0;
    }

    isSyncing = true;
    if (!isClosed) emit(OfflineSyncStateChanged());

    var syncedTotal = 0;
    try {
      final syncedCheckIns =
          await _locationsRepository.syncPendingCheckIns(uid);
      final syncedInspections =
          await _inspectionsRepository.syncPending(employeeId: uid);
      syncedTotal = syncedCheckIns + syncedInspections;
      await refreshPendingCounts();
    } catch (e, st) {
      addError(e, st);
    } finally {
      isSyncing = false;
      if (!isClosed) emit(OfflineSyncStateChanged());
    }
    return syncedTotal;
  }

  void changeBottomNavBar(int index) {
    if (index == selectedIndex) return;
    selectedIndex = index;
    emit(JameelChangeBottomNavState());
  }

  /// Stores a shift check-in or check-out with anti-spoofing, optional
  /// geofence check, best-effort reverse geocoding, and offline queueing.
  Future<void> checkIn({String type = 'check_in'}) async {
    emit(CheckInLoadingState());

    final user = _currentUserGetter();
    final uid = user?.uId;
    if (uid == null || uid.isEmpty) {
      emit(CheckInErrorState('no_user_found'));
      return;
    }

    try {
      final position = await LocationHelper.getCurrentPosition(
        timeLimit: const Duration(seconds: 7),
      );

      // Geofence enforcement when an assigned work site is configured.
      if (user != null && user.hasAssignedSite) {
        final dist = LocationHelper.distanceMeters(
          position.latitude,
          position.longitude,
          user.assignedSiteLat!,
          user.assignedSiteLng!,
        );
        if (dist > user.assignedSiteRadiusMeters!) {
          emit(CheckInErrorState('outside_work_site'));
          return;
        }
      }

      final connectivity = await _connectivity.checkConnectivity();
      final isOnline = !connectivity.contains(ConnectivityResult.none);
      final address = isOnline
          ? await LocationHelper.resolveAddress(
              position.latitude,
              position.longitude,
            )
          : null;

      if (isOnline) {
        try {
          await _locationsRepository.storeLocation(
            uid,
            position.latitude,
            position.longitude,
            type: type,
            address: address,
            siteName: user?.assignedSiteName,
          );
          emit(CheckInSuccessState(type: type, offline: false));
          return;
        } catch (e, st) {
          addError(e, st);
          // Fall through to offline queue on network failure.
        }
      }

      await _locationsRepository.queueOfflineCheckIn(
        userId: uid,
        lat: position.latitude,
        lng: position.longitude,
        type: type,
        address: address,
        siteName: user?.assignedSiteName,
      );
      await refreshPendingCounts();
      emit(CheckInSuccessState(type: type, offline: true));
    } on LocationException catch (e) {
      emit(CheckInErrorState(e.key));
    } catch (e, st) {
      addError(e, st);
      emit(CheckInErrorState('error_unknown'));
    }
  }

  Future<void> signOut() async {
    emit(SignOutLoadingState());
    try {
      await _authRepository.signOut();
      await CacheHelper.clearSessionSecurity();
      userModel = null;
      emit(SignOutSuccessState());
    } catch (e, st) {
      addError(e, st);
      emit(SignOutErrorState('error_unknown'));
    }
  }

  @override
  Future<void> close() async {
    await _connectivitySub?.cancel();
    return super.close();
  }
}
