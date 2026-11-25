import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/security/pin_lock_screen.dart';
import 'package:jameel/shared/cubits/app_preferences_cubit.dart';

void main() {
  setUpAll(() {
    EasyLocalization.logger.enableBuildModes = [];
  });

  testWidgets('PinLockScreen rejects invalid PIN and unlocks with valid PIN', (
    tester,
  ) async {
    final prefsCubit = AppPreferencesCubit(
      initialState: AppPreferencesState(
        currentUser: const JameelUserModel(uId: 'u1'),
        pinHash: AppPreferencesCubit.hashPin('1234'),
        isLocked: true,
      ),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: prefsCubit,
        child: const MaterialApp(home: PinLockScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (final d in ['9', '9', '9', '9']) {
      await tester.ensureVisible(find.text(d));
      await tester.tap(find.text(d));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('unlock'));
    await tester.tap(find.text('unlock'));
    await tester.pump();
    expect(prefsCubit.state.isLocked, isTrue);
    expect(find.text('pin_incorrect'), findsOneWidget);

    for (final d in ['1', '2', '3', '4']) {
      await tester.ensureVisible(find.text(d));
      await tester.tap(find.text(d));
      await tester.pump();
    }
    expect(prefsCubit.state.isLocked, isFalse);

    await prefsCubit.close();
  });
}
