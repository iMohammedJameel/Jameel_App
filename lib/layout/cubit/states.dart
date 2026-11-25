abstract class JameelStates {}

class JameelInitialState extends JameelStates {}

class JameelChangeBottomNavState extends JameelStates {}

class CheckInLoadingState extends JameelStates {}

class CheckInSuccessState extends JameelStates {
  CheckInSuccessState({this.type = 'check_in', this.offline = false});

  final String type;
  final bool offline;
}

class CheckInErrorState extends JameelStates {
  /// Translation key describing what went wrong.
  final String messageKey;

  CheckInErrorState(this.messageKey);
}

class OfflineSyncStateChanged extends JameelStates {}

class SignOutLoadingState extends JameelStates {}

class SignOutSuccessState extends JameelStates {}

class SignOutErrorState extends JameelStates {
  final String messageKey;

  SignOutErrorState(this.messageKey);
}
