import 'package:equatable/equatable.dart';

class NotificationUnreadCount extends Equatable {
  final int unreadCount;

  const NotificationUnreadCount({
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [unreadCount];
}
