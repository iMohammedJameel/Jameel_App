import 'package:jameel/models/user_model.dart';

abstract class LoginStates {}

class LoginInitialState extends LoginStates {}

class LoginPasswordVisibilityChangedState extends LoginStates {}

class LoginLoadingState extends LoginStates {}

class LoginGoogleLoadingState extends LoginStates {}

class LoginSuccessState extends LoginStates {
  final JameelUserModel user;

  LoginSuccessState(this.user);
}

class LoginPasswordResetSentState extends LoginStates {}

class LoginErrorState extends LoginStates {
  /// A translation key (never raw exception text), resolved with `.tr()` in
  /// the UI.
  final String errorKey;

  LoginErrorState(this.errorKey);
}
