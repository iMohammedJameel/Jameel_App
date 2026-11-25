import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/requests_repository.dart';
import 'package:jameel/models/request_model.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_states.dart';
import 'package:jameel/shared/session.dart';

class RequestsCubit extends Cubit<RequestsStates> {
  RequestsCubit({
    RequestsRepository? repository,
    JameelUserModel? Function()? currentUserGetter,
  })  : _repository = repository ?? RequestsRepository(),
        _currentUserGetter = currentUserGetter ?? (() => userModel),
        super(RequestsInitialState());

  final RequestsRepository _repository;
  final JameelUserModel? Function() _currentUserGetter;

  static RequestsCubit get(BuildContext context) =>
      BlocProvider.of<RequestsCubit>(context);

  Stream<List<EmployeeRequestModel>> getRequestsStream({
    String? statusFilter,
    int limit = RequestsRepository.recentLimit,
  }) {
    final uid = _currentUserGetter()?.uId;
    if (uid == null || uid.isEmpty) {
      return const Stream<List<EmployeeRequestModel>>.empty();
    }
    return _repository.getRequestsStream(
      uid,
      statusFilter: statusFilter,
      limit: limit,
    );
  }

  Stream<List<EmployeeRequestModel>> getPendingApprovalsStream() {
    final user = _currentUserGetter();
    if (user == null || !user.isManagerOrHr) {
      return const Stream<List<EmployeeRequestModel>>.empty();
    }
    return _repository.getPendingApprovalsStream();
  }

  Future<void> submitRequest({
    required String type,
    required String description,
    String? leaveCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
  }) async {
    if (state is RequestsLoadingState) return; // ignore double taps

    emit(RequestsLoadingState());
    final user = _currentUserGetter();
    final uid = user?.uId;
    if (uid == null || uid.isEmpty) {
      emit(RequestsErrorState('no_user_found'));
      return;
    }

    try {
      if (type == 'leave' && startDate != null && endDate != null) {
        final overlaps = await _repository.hasOverlappingLeave(
          employeeId: uid,
          start: startDate,
          end: endDate,
        );
        if (overlaps) {
          emit(RequestsErrorState('leave_dates_overlap'));
          return;
        }
      }

      await _repository.submitRequest(
        type: type,
        description: description,
        employeeId: uid,
        employeeName: user?.userName,
        leaveCategory: leaveCategory,
        startDate: startDate,
        endDate: endDate,
        amount: amount,
      );
      emit(RequestsSuccessState());
    } catch (e, st) {
      addError(e, st);
      emit(RequestsErrorState('error_unknown'));
    }
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _repository.cancelRequest(requestId);
      emit(RequestCancelledState());
    } catch (e, st) {
      addError(e, st);
      emit(RequestsErrorState('error_unknown'));
    }
  }

  Future<void> reviewRequest({
    required String requestId,
    required String status,
    String? note,
  }) async {
    final uid = _currentUserGetter()?.uId;
    if (uid == null || uid.isEmpty) {
      emit(RequestsErrorState('no_user_found'));
      return;
    }
    try {
      await _repository.reviewRequest(
        requestId: requestId,
        status: status,
        reviewerId: uid,
        note: note,
      );
      emit(RequestReviewedState());
    } catch (e, st) {
      addError(e, st);
      emit(RequestsErrorState('error_unknown'));
    }
  }
}
