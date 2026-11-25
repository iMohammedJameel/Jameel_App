import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:jameel/models/user_model.dart';
import 'package:jameel/shared/components/ui_kit.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.user,
    required this.tenureYears,
  });

  final JameelUserModel? user;
  final int? tenureYears;

  @override
  Widget build(BuildContext context) {
    final rawName = user?.userName?.trim() ?? '';
    final name = rawName.isEmpty ? 'unknown_user'.tr() : rawName;
    final dept = (user?.userDepartment ?? '').trim();

    return HeroBackground(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                InitialsAvatar(
                  name: name,
                  size: 60,
                  photoUrl: user?.photoUrl,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome_back'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                HeroChip(
                  icon: Icons.apartment_rounded,
                  label: dept.isEmpty ? 'no_department'.tr() : dept,
                ),
                if (tenureYears != null)
                  HeroChip(
                    icon: Icons.workspace_premium_rounded,
                    label: 'years_of_service'.plural(tenureYears!),
                  ),
                if (user?.assignedSiteName != null &&
                    user!.assignedSiteName!.isNotEmpty)
                  HeroChip(
                    icon: Icons.location_city_rounded,
                    label: user!.assignedSiteName!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
