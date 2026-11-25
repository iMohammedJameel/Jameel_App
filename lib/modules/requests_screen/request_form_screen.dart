import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jameel/modules/requests_screen/request_meta.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_states.dart';
import 'package:jameel/shared/components/ui_kit.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';
import 'package:jameel/shared/styles/app_design.dart';

class RequestFormScreen extends StatefulWidget {
  final String requestType;

  const RequestFormScreen({super.key, required this.requestType});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  static const int _minDescriptionLength = 10;
  static const List<String> _leaveCategories = [
    'annual',
    'sick',
    'emergency',
    'unpaid',
  ];
  static const List<int> _quickAmounts = [500, 1000, 2500, 5000];

  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _leaveCategory = 'annual';
  DateTime? _startDate;
  DateTime? _endDate;
  double? _amount;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = RequestMeta.of(widget.requestType);
    final user = context.watch<AppPreferencesCubit>().state.currentUser;
    final leaveBalance = user?.annualLeaveBalance ?? 21;

    return BlocConsumer<RequestsCubit, RequestsStates>(
      listenWhen: (_, state) =>
          state is RequestsSuccessState || state is RequestsErrorState,
      listener: (context, state) {
        if (state is RequestsSuccessState) {
          AppHaptics.medium();
          showAppSnack(context, 'request_submitted'.tr());
          Navigator.pop(context);
        } else if (state is RequestsErrorState) {
          AppHaptics.error();
          showAppSnack(context, state.messageKey.tr(), error: true);
        }
      },
      builder: (context, state) {
        final isSubmitting = state is RequestsLoadingState;
        final days = _leaveDays;
        final projectedBalance = days != null ? (leaveBalance - days) : null;

        return Scaffold(
          backgroundColor: context.bgColor,
          appBar: AppBar(title: Text(meta.titleKey.tr())),
          body: PageOrnamentBackground(
            child: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppCard(
                            child: Row(
                              children: [
                                IconBubble(
                                  icon: meta.icon,
                                  color: meta.color,
                                  size: 52,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        meta.titleKey.tr(),
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: context.inkColor,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        meta.hintKey.tr(),
                                        style: TextStyle(
                                          color: context.mutedColor,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (widget.requestType == 'leave') ...[
                            Text(
                              'leave_category'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: context.mutedColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final cat in _leaveCategories)
                                  ChoiceChip(
                                    label: Text('leave_cat_$cat'.tr()),
                                    selected: _leaveCategory == cat,
                                    selectedColor: context.primarySoftColor,
                                    labelStyle: TextStyle(
                                      color: _leaveCategory == cat
                                          ? AppColors.primary
                                          : context.mutedColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    side: BorderSide(
                                      color: _leaveCategory == cat
                                          ? AppColors.primary
                                              .withValues(alpha: 0.4)
                                          : context.borderColor,
                                    ),
                                    backgroundColor: context.surfaceColor,
                                    onSelected: (_) {
                                      AppHaptics.light();
                                      setState(() => _leaveCategory = cat);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              onTap: _pickDateRange,
                              child: Row(
                                children: [
                                  const IconBubble(
                                    icon: Icons.date_range_rounded,
                                    color: AppColors.primary,
                                    size: 42,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'select_leave_dates'.tr(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.mutedColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          _startDate != null && _endDate != null
                                              ? '${DateFormat('yyyy-MM-dd').format(_startDate!)}${Directionality.of(context) == ui.TextDirection.rtl ? '  ←  ' : '  →  '}${DateFormat('yyyy-MM-dd').format(_endDate!)}'
                                              : 'tap_to_select_range'.tr(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: _startDate != null
                                                ? context.inkColor
                                                : context.mutedColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    directionalChevron(context),
                                    color: context.mutedColor,
                                  ),
                                ],
                              ),
                            ),
                            if (days != null) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  StatusChip(
                                    label: 'days_count'
                                        .tr(namedArgs: {'count': '$days'}),
                                    color: AppColors.info,
                                  ),
                                  if (_leaveCategory == 'annual' &&
                                      projectedBalance != null)
                                    StatusChip(
                                      label: 'balance_after_leave'.tr(
                                        namedArgs: {
                                          'count': '$projectedBalance',
                                        },
                                      ),
                                      color: projectedBalance >= 0
                                          ? AppColors.success
                                          : AppColors.primary,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                          ],
                          if (widget.requestType == 'loan') ...[
                            AppTextField(
                              controller: _amountController,
                              label: 'amount'.tr(),
                              icon: Icons.attach_money_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'enter_amount'.tr();
                                }
                                final amount = _parseAmount(value);
                                if (amount == null || amount <= 0) {
                                  return 'invalid_number'.tr();
                                }
                                return null;
                              },
                              onSaved: (value) => _amount = _parseAmount(value),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final preset in _quickAmounts)
                                  ActionChip(
                                    label: Text('$preset'),
                                    backgroundColor: context.surfaceColor,
                                    side: BorderSide(color: context.borderColor),
                                    labelStyle: TextStyle(
                                      color: context.inkColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    onPressed: () {
                                      AppHaptics.light();
                                      _amountController.text = '$preset';
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          AppTextField(
                            controller: _descriptionController,
                            label: 'description'.tr(),
                            hint: 'description_hint'.tr(),
                            maxLines: 5,
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) return 'enter_description'.tr();
                              if (text.length < _minDescriptionLength) {
                                return 'description_too_short'.tr();
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border(
                        top: BorderSide(color: context.borderColor),
                      ),
                    ),
                    child: PrimaryButton(
                      label: 'submit_request'.tr(),
                      icon: Icons.send_rounded,
                      loading: isSubmitting,
                      onPressed: isSubmitting ? null : _submitRequest,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }

  int? get _leaveDays {
    if (_startDate == null || _endDate == null) return null;
    if (_endDate!.isBefore(_startDate!)) return null;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialRange = (_startDate != null &&
            _endDate != null &&
            !_startDate!.isBefore(today))
        ? DateTimeRange(start: _startDate!, end: _endDate!)
        : null;

    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );
    if (range == null) return;
    setState(() {
      _startDate = range.start;
      _endDate = range.end;
    });
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (widget.requestType == 'leave') {
      if (_startDate == null || _endDate == null) {
        showAppSnack(context, 'select_both_dates_error'.tr(), error: true);
        return;
      }
      if (_endDate!.isBefore(_startDate!)) {
        showAppSnack(context, 'end_date_before_start_error'.tr(), error: true);
        return;
      }
    }

    final isLeave = widget.requestType == 'leave';
    final isLoan = widget.requestType == 'loan';
    context.read<RequestsCubit>().submitRequest(
          type: widget.requestType,
          description: _descriptionController.text.trim(),
          leaveCategory: isLeave ? _leaveCategory : null,
          startDate: isLeave ? _startDate : null,
          endDate: isLeave ? _endDate : null,
          amount: isLoan ? _amount : null,
        );
  }

  double? _parseAmount(String? raw) {
    if (raw == null) return null;
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    var text = raw
        .trim()
        .replaceAll('٫', '.')
        .replaceAll(RegExp(r'[,،٬\s]'), '');
    for (var i = 0; i < arabicDigits.length; i++) {
      text = text.replaceAll(arabicDigits[i], '$i');
    }
    return double.tryParse(text);
  }
}
