import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/login/cubit/cubit.dart';
import 'package:jameel/modules/login/cubit/states.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.onGoogleSignIn});

  final Future<JameelUserModel?> Function()? onGoogleSignIn;

  @override
  Future<JameelUserModel?> signInWithGoogle() => onGoogleSignIn!();
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('jameel_login_test_');
    Hive.init(tempDir.path);
    await CacheHelper.init(enableEncryption: false);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() {
    userModel = null;
  });

  group('LoginCubit.signInWithGoogle', () {
    test('emits loading then success and sets session user', () async {
      final expectedUser = JameelUserModel(
        uId: 'g1',
        userName: 'Jameel User',
        userEmail: 'user@gmail.com',
      );
      final cubit = LoginCubit(
        authRepository: _FakeAuthRepository(
          onGoogleSignIn: () async => expectedUser,
        ),
      );

      final states = <LoginStates>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<LoginGoogleLoadingState>());
      expect(states[1], isA<LoginSuccessState>());
      expect(userModel?.uId, 'g1');

      await sub.cancel();
      await cubit.close();
    });

    test('returns silently to initial state when user cancels', () async {
      final cubit = LoginCubit(
        authRepository: _FakeAuthRepository(onGoogleSignIn: () async => null),
      );

      final states = <LoginStates>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.signInWithGoogle();
      await Future<void>.delayed(Duration.zero);

      expect(states.length, 2);
      expect(states[0], isA<LoginGoogleLoadingState>());
      expect(states[1], isA<LoginInitialState>());
      expect(userModel, isNull);

      await sub.cancel();
      await cubit.close();
    });

    test('maps GoogleSignInException and FirebaseAuthException to error keys', () async {
      final googleFailCubit = LoginCubit(
        authRepository: _FakeAuthRepository(
          onGoogleSignIn: () async => throw const GoogleSignInException(
            code: GoogleSignInExceptionCode.clientConfigurationError,
          ),
        ),
      );

      await googleFailCubit.signInWithGoogle();
      expect(googleFailCubit.state, isA<LoginErrorState>());
      expect(
        (googleFailCubit.state as LoginErrorState).errorKey,
        'google_sign_in_failed',
      );
      await googleFailCubit.close();

      final firebaseFailCubit = LoginCubit(
        authRepository: _FakeAuthRepository(
          onGoogleSignIn: () async => throw FirebaseAuthException(
            code: 'account-exists-with-different-credential',
          ),
        ),
      );

      await firebaseFailCubit.signInWithGoogle();
      expect(firebaseFailCubit.state, isA<LoginErrorState>());
      expect(
        (firebaseFailCubit.state as LoginErrorState).errorKey,
        'account_exists_different_credential',
      );
      await firebaseFailCubit.close();
    });
  });
}
