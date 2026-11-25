abstract class RequestsStates {}

class RequestsInitialState extends RequestsStates {}

class RequestsLoadingState extends RequestsStates {}

class RequestsSuccessState extends RequestsStates {}

class RequestCancelledState extends RequestsStates {}

class RequestReviewedState extends RequestsStates {}

class RequestsErrorState extends RequestsStates {
  /// Translation key describing what went wrong.
  final String messageKey;

  RequestsErrorState(this.messageKey);
}
