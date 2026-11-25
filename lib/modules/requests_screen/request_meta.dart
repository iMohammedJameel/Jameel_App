// lib/modules/requests_screen/request_meta.dart
//
// Visual metadata (icon / color / translation keys) for each request type,
// shared by the requests list and the request form.
import 'package:flutter/material.dart';
import 'package:jameel/shared/styles/app_design.dart';

class RequestMeta {
  const RequestMeta({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.hintKey,
  });

  final IconData icon;
  final Color color;
  final String titleKey;
  final String hintKey;

  static const List<String> types = ['leave', 'loan', 'complaint', 'suggestion'];

  static RequestMeta of(String type) {
    switch (type) {
      case 'leave':
        return const RequestMeta(
          icon: Icons.beach_access_rounded,
          color: AppColors.info,
          titleKey: 'request_leave',
          hintKey: 'hint_leave',
        );
      case 'loan':
        return const RequestMeta(
          icon: Icons.payments_rounded,
          color: AppColors.success,
          titleKey: 'request_loan',
          hintKey: 'hint_loan',
        );
      case 'complaint':
        return const RequestMeta(
          icon: Icons.report_problem_rounded,
          color: AppColors.primary,
          titleKey: 'request_complaint',
          hintKey: 'hint_complaint',
        );
      case 'suggestion':
        return const RequestMeta(
          icon: Icons.lightbulb_rounded,
          color: AppColors.warning,
          titleKey: 'request_suggestion',
          hintKey: 'hint_suggestion',
        );
      default:
        return const RequestMeta(
          icon: Icons.help_outline_rounded,
          color: AppColors.muted,
          titleKey: 'request_unknown',
          hintKey: 'request_unknown',
        );
    }
  }
}
