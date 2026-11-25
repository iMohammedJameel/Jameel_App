import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/requests_repository.dart';
import 'package:jameel/models/request_model.dart';
import 'package:jameel/modules/requests_screen/request_form_screen.dart';
import 'package:jameel/modules/requests_screen/request_meta.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_states.dart';
import 'package:jameel/modules/requests_screen/widgets/request_details_sheet.dart';
import 'package:jameel/modules/requests_screen/widgets/team_approvals_sheet.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

class EmployeeRequestsScreen extends StatefulWidget {
  const EmployeeRequestsScreen({super.key});

  @override
  State<EmployeeRequestsScreen> createState() => _EmployeeRequestsScreenState();
}

class _EmployeeRequestsScreenState extends State<EmployeeRequestsScreen> {
  static const List<String> _filters = [
    'all',
    'pending',
    'approved',
    'rejected',
    'cancelled',
  ];

  int _limit = RequestsRepository.recentLimit;
  String _selectedFilter = 'all';
  late Stream<List<EmployeeRequestModel>> _requestsStream;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    _requestsStream = context.read<RequestsCubit>().getRequestsStream(
          statusFilter: _selectedFilter,
          limit: _limit,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppPreferencesCubit>().state.currentUser;
    final isManager = user?.isManagerOrHr ?? false;

    return BlocListener<RequestsCubit, RequestsStates>(
      listenWhen: (_, state) =>
          state is RequestCancelledState ||
          state is RequestReviewedState ||
          state is RequestsErrorState,
      listener: (context, state) {
        if (state is RequestCancelledState) {
          showAppSnack(context, 'request_cancelled'.tr());
        } else if (state is RequestReviewedState) {
          showAppSnack(context, 'request_reviewed'.tr());
        } else if (state is RequestsErrorState) {
          showAppSnack(context, state.messageKey.tr(), error: true);
        }
      },
      child: Scaffold(
        backgroundColor: context.bgColor,
        body: PageOrnamentBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'requests'.tr(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: context.inkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'requests_subtitle'.tr(),
                              style: TextStyle(
                                color: context.mutedColor,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isManager)
                        TextButton.icon(
                          onPressed: () => showTeamApprovalsSheet(context),
                          icon: const Icon(Icons.fact_check_rounded, size: 18),
                          label: Text('team_approvals'.tr()),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor: context.primarySoftColor,
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ],
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 12),
                    StatusChip(
                      label: 'leave_balance_chip'.tr(
                        namedArgs: {'count': '${user.annualLeaveBalance}'},
                      ),
                      color: AppColors.info,
                    ),
                  ],
                  const SizedBox(height: 18),
                  SectionTitle('new_request_section'.tr()),
                  const SizedBox(height: 12),
                  _buildQuickRequestGrid(context),
                  const SizedBox(height: 26),
                  SectionTitle('recent_requests'.tr()),
                  const SizedBox(height: 12),
                  _buildFilterChips(context),
                  const SizedBox(height: 14),
                  _buildRecentRequests(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRequestGrid(BuildContext context) {
    const types = RequestMeta.types;
    final rows = <Widget>[];
    for (var i = 0; i < types.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildQuickRequestCard(context, types[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < types.length
                    ? _buildQuickRequestCard(context, types[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildQuickRequestCard(BuildContext context, String type) {
    final meta = RequestMeta.of(type);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        AppHaptics.light();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestFormScreen(requestType: type),
          ),
        );
      },
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconBubble(icon: meta.icon, color: meta.color, size: 42),
            const SizedBox(height: 12),
            Text(
              meta.titleKey.tr(),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: context.inkColor,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              meta.hintKey.tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.mutedColor,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in _filters) ...[
            ChoiceChip(
              label: Text(
                filter == 'all'
                    ? 'filter_all'.tr()
                    : requestStatusText(filter),
              ),
              selected: _selectedFilter == filter,
              selectedColor: context.primarySoftColor,
              labelStyle: TextStyle(
                color: _selectedFilter == filter
                    ? AppColors.primary
                    : context.mutedColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
              side: BorderSide(
                color: _selectedFilter == filter
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : context.borderColor,
              ),
              backgroundColor: context.surfaceColor,
              onSelected: (_) {
                AppHaptics.light();
                setState(() {
                  _selectedFilter = filter;
                  _limit = RequestsRepository.recentLimit;
                  _subscribe();
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentRequests(BuildContext context) {
    return StreamBuilder<List<EmployeeRequestModel>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerListPlaceholder(itemCount: 3);
        }

        if (snapshot.hasError) {
          return AppCard(
            child: EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'error_loading_data'.tr(),
            ),
          );
        }

        final allItems = snapshot.data ?? const <EmployeeRequestModel>[];
        final items = _selectedFilter == 'all'
            ? allItems
            : allItems.where((r) => r.status == _selectedFilter).toList();

        if (items.isEmpty) {
          return AppCard(
            child: EmptyState(
              icon: Icons.inbox_rounded,
              title: 'no_requests'.tr(),
              subtitle: 'no_requests_hint'.tr(),
            ),
          );
        }

        return Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final req = items[index];
                final meta = RequestMeta.of(req.type);

                return AppCard(
                  padding: const EdgeInsets.all(14),
                  onTap: () => showRequestDetailsSheet(context, req),
                  child: Row(
                    children: [
                      IconBubble(icon: meta.icon, color: meta.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.titleKey.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: context.inkColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('yyyy-MM-dd').format(req.timestamp),
                              style: TextStyle(
                                color: context.mutedColor,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusChip(
                        label: requestStatusText(req.status),
                        color: statusColor(req.status),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (allItems.length >= _limit) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: () {
                  setState(() {
                    _limit += RequestsRepository.recentLimit;
                    _subscribe();
                  });
                },
                child: Text(
                  'load_more'.tr(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
