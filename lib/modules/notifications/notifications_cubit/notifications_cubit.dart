import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jameel/data/repositories/notifications_repository.dart';
import 'package:jameel/models/notification_model.dart';
import 'package:jameel/modules/notifications/notifications_cubit/notifications_states.dart';
import 'package:jameel/shared/session.dart';

class NotificationsCubit extends Cubit<NotificationsStates> {
  NotificationsCubit({
    NotificationsRepository? repository,
    String? Function()? userIdGetter,
  })  : _repository = repository ?? NotificationsRepository(),
        _userIdGetter = userIdGetter ?? (() => userModel?.uId),
        super(NotificationsInitialState());

  final NotificationsRepository _repository;
  final String? Function() _userIdGetter;

  List<NotificationModel> notifications = [];

  Future<void> loadNotifications() async {
    emit(NotificationsLoadingState());
    try {
      final uid = _userIdGetter();
      notifications = (uid == null || uid.isEmpty)
          ? []
          : await _repository.fetchForEmployee(uid);
      emit(NotificationsLoadedState());
    } catch (e, st) {
      addError(e, st);
      emit(NotificationsErrorState('error_loading_data'));
    }
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;

    // Update the UI immediately, roll back if the write fails.
    final previous = notifications[index];
    notifications[index] = previous.copyWith(isRead: true);
    emit(NotificationsLoadedState());
    try {
      await _repository.markAsRead(id);
    } catch (e, st) {
      addError(e, st);
      notifications[index] = previous;
      emit(NotificationsErrorState('error_unknown'));
    }
  }

  Future<void> markAllAsRead() async {
    final unreadIds =
        notifications.where((n) => !n.isRead).map((n) => n.id).toList();
    if (unreadIds.isEmpty) return;

    final previous = List<NotificationModel>.of(notifications);
    notifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(NotificationsLoadedState());
    try {
      await _repository.markManyAsRead(unreadIds);
    } catch (e, st) {
      addError(e, st);
      notifications = previous;
      emit(NotificationsErrorState('error_unknown'));
    }
  }
}
