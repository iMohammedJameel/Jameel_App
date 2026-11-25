import 'package:flutter_test/flutter_test.dart';
import 'package:jameel/data/repositories/requests_repository.dart';
import 'package:jameel/models/request_model.dart';
import 'package:jameel/models/user_model.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_cubit.dart';
import 'package:jameel/modules/requests_screen/requests_cubit/requests_states.dart';

class _FakeRequestsRepository extends RequestsRepository {
  _FakeRequestsRepository({this.overlappingLeave = false});

  bool overlappingLeave;
  bool submitted = false;
  String? lastCancelledId;
  String? lastReviewedId;
  String? lastReviewStatus;
  String? lastStatusFilter;

  @override
  Future<bool> hasOverlappingLeave({
    required String employeeId,
    required DateTime start,
    required DateTime end,
  }) async =>
      overlappingLeave;

  @override
  Future<void> submitRequest({
    required String type,
    required String description,
    required String employeeId,
    String? employeeName,
    String? leaveCategory,
    DateTime? startDate,
    DateTime? endDate,
    double? amount,
  }) async {
    submitted = true;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    lastCancelledId = requestId;
  }

  @override
  Future<void> reviewRequest({
    required String requestId,
    required String status,
    required String reviewerId,
    String? note,
  }) async {
    lastReviewedId = requestId;
    lastReviewStatus = status;
  }

  @override
  Stream<List<EmployeeRequestModel>> getRequestsStream(
    String employeeId, {
    String? statusFilter,
    int limit = RequestsRepository.recentLimit,
  }) {
    lastStatusFilter = statusFilter;
    return const Stream<List<EmployeeRequestModel>>.empty();
  }

  @override
  Stream<List<EmployeeRequestModel>> getPendingApprovalsStream({int limit = 50}) {
    return Stream.value([
      EmployeeRequestModel(
        id: 'r1',
        employeeId: 'e1',
        type: 'leave',
        description: 'Family trip leave request',
        status: 'pending',
        timestamp: DateTime(2026, 5, 1),
      ),
    ]);
  }
}

void main() {
  group('RequestsCubit', () {
    test('rejects overlapping leave dates before submitting', () async {
      final repo = _FakeRequestsRepository(overlappingLeave: true);
      final cubit = RequestsCubit(
        repository: repo,
        currentUserGetter: () => const JameelUserModel(uId: 'emp1'),
      );

      await cubit.submitRequest(
        type: 'leave',
        description: 'Annual vacation dates',
        leaveCategory: 'annual',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 4),
      );

      expect(repo.submitted, isFalse);
      expect(cubit.state, isA<RequestsErrorState>());
      expect(
        (cubit.state as RequestsErrorState).messageKey,
        'leave_dates_overlap',
      );
      await cubit.close();
    });

    test('submits valid request and forwards server status filter', () async {
      final repo = _FakeRequestsRepository();
      final cubit = RequestsCubit(
        repository: repo,
        currentUserGetter: () =>
            const JameelUserModel(uId: 'emp1', userName: 'Sara'),
      );

      await cubit.submitRequest(
        type: 'loan',
        description: 'Medical emergency advance',
        amount: 2500,
      );
      expect(repo.submitted, isTrue);
      expect(cubit.state, isA<RequestsSuccessState>());

      cubit.getRequestsStream(statusFilter: 'approved');
      expect(repo.lastStatusFilter, 'approved');

      await cubit.cancelRequest('req-9');
      expect(repo.lastCancelledId, 'req-9');
      expect(cubit.state, isA<RequestCancelledState>());

      await cubit.close();
    });

    test('restricts pending team approvals stream to manager or HR role', () async {
      final repo = _FakeRequestsRepository();
      final employeeCubit = RequestsCubit(
        repository: repo,
        currentUserGetter: () =>
            const JameelUserModel(uId: 'e1', role: 'employee'),
      );
      expect(await employeeCubit.getPendingApprovalsStream().isEmpty, isTrue);
      await employeeCubit.close();

      final managerCubit = RequestsCubit(
        repository: repo,
        currentUserGetter: () =>
            const JameelUserModel(uId: 'm1', role: 'manager'),
      );
      final pending = await managerCubit.getPendingApprovalsStream().first;
      expect(pending.length, 1);

      await managerCubit.reviewRequest(requestId: 'r1', status: 'approved');
      expect(repo.lastReviewedId, 'r1');
      expect(repo.lastReviewStatus, 'approved');
      expect(managerCubit.state, isA<RequestReviewedState>());
      await managerCubit.close();
    });
  });
}
