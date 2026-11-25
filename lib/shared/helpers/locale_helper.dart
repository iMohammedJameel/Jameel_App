import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

extension LocaleToggle on BuildContext {
  /// Switches the app language between English and Arabic.
  Future<void> toggleLocale() => setLocale(
        locale.languageCode == 'en' ? const Locale('ar') : const Locale('en'),
      );
}
