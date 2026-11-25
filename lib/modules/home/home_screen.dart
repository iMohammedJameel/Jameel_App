// lib/modules/home/home_screen.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/data/repositories/locations_repository.dart';
import 'package:jameel/layout/cubit/cubit.dart';
import 'package:jameel/layout/cubit/states.dart';
import 'package:jameel/models/location_model.dart';
import 'package:jameel/modules/home/widgets/home_header.dart';
import 'package:jameel/modules/home/widgets/location_history_section.dart';
import 'package:jameel/modules/home/widgets/shift_summary_card.dart';
import 'package:jameel/modules/inspection/capture_screen.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/helpers/tenure_helper.dart';
import 'package:jameel/shared/styles/app_design.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  bool _isLoadingDialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppPreferencesCubit>().state.currentUser;

    return BlocListener<JameelCubit, JameelStates>(
      listenWhen: (_, state) =>
          state is CheckInLoadingState ||
          state is CheckInSuccessState ||
          state is CheckInErrorState,
      listener: _onCheckInState,
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: PageOrnamentBackground(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => JameelCubit.get(context).syncAllPending(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHeader(
                    user: user,
                    tenureYears: yearsOfService(user?.userJoinDate),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: _HomeBody(userId: user?.uId),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCheckInState(BuildContext context, JameelStates state) {
    if (state is CheckInLoadingState) {
      if (_isLoadingDialogOpen) return;
      _isLoadingDialogOpen = true;
      showLoadingDialog(context).whenComplete(() => _isLoadingDialogOpen = false);
      return;
    }
    if (_isLoadingDialogOpen) {
      _isLoadingDialogOpen = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    if (state is CheckInSuccessState) {
      AppHaptics.medium();
      final msgKey = state.offline
          ? 'checkin_saved_offline'
          : (state.type == 'check_out'
              ? 'checkout_stored_successfully'
              : 'location_stored_successfully');
      final showDialogPref =
          context.read<AppPreferencesCubit>().state.notifyCheckIn;
      if (showDialogPref) {
        showStatusDialog(context, success: true, message: msgKey.tr());
      } else {
        showAppSnack(context, msgKey.tr());
      }
    } else if (state is CheckInErrorState) {
      AppHaptics.error();
      showStatusDialog(context, success: false, message: state.messageKey.tr());
    }
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({required this.userId});

  final String? userId;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  late Stream<List<LocationCheckInModel>> _stream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant _HomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _initStream();
    }
  }

  void _initStream() {
    final uid = widget.userId;
    _stream = uid == null || uid.isEmpty
        ? const Stream<List<LocationCheckInModel>>.empty()
        : context.read<LocationsRepository>().locationsStream(uid);
  }

  @override
  Widget build(BuildContext context) {
    final uid = widget.userId;
    if (uid == null || uid.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(context, nextType: 'check_in'),
          const SizedBox(height: 28),
          AppCard(
            child: EmptyState(
              icon: Icons.person_off_rounded,
              title: 'no_user_found'.tr(),
            ),
          ),
        ],
      );
    }

    return StreamBuilder<List<LocationCheckInModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <LocationCheckInModel>[];
        final todayItems = _todayItems(items);
        final nextType = _resolveNextShiftAction(todayItems);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todayItems.isNotEmpty) ...[
              ShiftSummaryCard(
                todayItems: todayItems,
                isActive: nextType == 'check_out',
              ),
              const SizedBox(height: 20),
            ],
            _buildQuickActions(
              context,
              nextType: nextType,
              checkedInToday: nextType == 'check_out',
              todayCount: todayItems.length,
            ),
            const PendingSyncBanner(),
            const SizedBox(height: 28),
            if (snapshot.hasError)
              AppCard(
                child: EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'error_loading_data'.tr(),
                ),
              )
            else if (!snapshot.hasData) ...[
              SectionTitle('location_history'.tr()),
              const SizedBox(height: 14),
              const ShimmerListPlaceholder(itemCount: 3),
            ] else if (items.isEmpty)
              AppCard(
                child: EmptyState(
                  icon: Icons.location_off_rounded,
                  title: 'no_locations_found'.tr(),
                  subtitle: 'no_locations_hint'.tr(),
                ),
              )
            else
              LocationHistorySection(items: items),
          ],
        );
      },
    );
  }

  List<LocationCheckInModel> _todayItems(List<LocationCheckInModel> items) {
    final now = DateTime.now();
    return items
        .where((i) =>
            i.timestamp.year == now.year &&
            i.timestamp.month == now.month &&
            i.timestamp.day == now.day)
        .toList();
  }

  String _resolveNextShiftAction(List<LocationCheckInModel> todayItems) {
    if (todayItems.isEmpty) return 'check_in';
    return todayItems.first.isCheckOut ? 'check_in' : 'check_out';
  }

  Widget _buildQuickActions(
    BuildContext context, {
    required String nextType,
    bool checkedInToday = false,
    int todayCount = 0,
  }) {
    final isCheckOut = nextType == 'check_out';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'quick_actions'.tr(),
          trailing: todayCount > 0
              ? StatusChip(
                  label:
                      checkedInToday ? 'shift_active'.tr() : 'shift_ended'.tr(),
                  color: checkedInToday ? AppColors.success : context.mutedColor,
                )
              : null,
        ),
        const SizedBox(height: 14),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: HomeActionTile(
                  icon: isCheckOut
                      ? Icons.logout_rounded
                      : Icons.my_location_rounded,
                  title: isCheckOut
                      ? 'check_out_action'.tr()
                      : 'store_location'.tr(),
                  subtitle: isCheckOut
                      ? 'check_out_hint'.tr()
                      : 'store_location_hint'.tr(),
                  filled: true,
                  onTap: () {
                    AppHaptics.medium();
                    JameelCubit.get(context).checkIn(type: nextType);
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: HomeActionTile(
                  icon: Icons.photo_camera_rounded,
                  title: 'capture_inspection'.tr(),
                  subtitle: 'capture_inspection_hint'.tr(),
                  onTap: () async {
                    AppHaptics.light();
                    final cubit = JameelCubit.get(context);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptureScreen(),
                      ),
                    );
                    await cubit.refreshPendingCounts();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
