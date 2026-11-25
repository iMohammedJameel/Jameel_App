import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jameel/data/repositories/auth_repository.dart';
import 'package:jameel/modules/login/cubit/states.dart';
import 'package:jameel/shared/network/local/cache_helper.dart';
import 'package:jameel/shared/session.dart';

class LoginCubit extends Cubit<LoginStates> {
  LoginCubit({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository(),
        super(LoginInitialState());

  final AuthRepository _authRepository;

  bool visiblePassword = true;

  void changeVisiblePassword() {
    visiblePassword = !visiblePassword;
    emit(LoginPasswordVisibilityChangedState());
  }

  Future<void> userLogin({
    required String email,
    required String password,
  }) async {
    if (state is LoginLoadingState || state is LoginGoogleLoadingState) return;
    emit(LoginLoadingState());
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      userModel = user;
      await CacheHelper.cacheUser(user);
      emit(LoginSuccessState(user));
    } on FirebaseAuthException catch (e, st) {
      addError(e, st);
      emit(LoginErrorState(_errorKey(e)));
    } catch (e, st) {
      addError(e, st);
      emit(LoginErrorState('error_unknown'));
    }
  }

  Future<void> signInWithGoogle() async {
    if (state is LoginLoadingState || state is LoginGoogleLoadingState) return;
    emit(LoginGoogleLoadingState());
    try {
      final user = await _authRepository.signInWithGoogle();
      if (user == null) {
        emit(LoginInitialState());
        return;
      }
      userModel = user;
      await CacheHelper.cacheUser(user);
      emit(LoginSuccessState(user));
    } on GoogleSignInException catch (e, st) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        emit(LoginInitialState());
        return;
      }
      addError(e, st);
      emit(LoginErrorState('google_sign_in_failed'));
    } on FirebaseAuthException catch (e, st) {
      addError(e, st);
      emit(LoginErrorState(_errorKey(e)));
    } catch (e, st) {
      addError(e, st);
      emit(LoginErrorState('error_unknown'));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authRepository.sendPasswordReset(email);
      emit(LoginPasswordResetSentState());
    } on FirebaseAuthException catch (e, st) {
      addError(e, st);
      emit(LoginErrorState(_errorKey(e)));
    } catch (e, st) {
      addError(e, st);
      emit(LoginErrorState('error_unknown'));
    }
  }

  /// Maps Firebase error codes to translation keys so users never see raw
  /// (English-only, technical) exception messages.
  static String _errorKey(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'invalid_credentials';
      case 'invalid-email':
        return 'invalid_email';
      case 'account-exists-with-different-credential':
        return 'account_exists_different_credential';
      case 'user-disabled':
        return 'error_user_disabled';
      case 'too-many-requests':
        return 'error_too_many_requests';
      case 'network-request-failed':
        return 'error_network';
      default:
        return 'error_unknown';
    }
  }
}
