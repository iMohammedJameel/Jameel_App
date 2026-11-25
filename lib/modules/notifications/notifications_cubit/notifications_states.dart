abstract class NotificationsStates {}

class NotificationsInitialState extends NotificationsStates {}

class NotificationsLoadingState extends NotificationsStates {}

class NotificationsLoadedState extends NotificationsStates {}

class NotificationsErrorState extends NotificationsStates {
  /// Translation key describing what went wrong.
  final String messageKey;

  NotificationsErrorState(this.messageKey);
}
