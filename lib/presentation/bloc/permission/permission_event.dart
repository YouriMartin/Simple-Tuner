import 'package:equatable/equatable.dart';

/// Base class for permission events
abstract class PermissionEvent extends Equatable {
  const PermissionEvent();

  @override
  List<Object> get props => [];
}

/// Event to check current permission status
class CheckPermissionEvent extends PermissionEvent {
  const CheckPermissionEvent();
}

/// Event to request microphone permission
class RequestPermissionEvent extends PermissionEvent {
  const RequestPermissionEvent();
}

/// Event to handle permission result
class PermissionResultEvent extends PermissionEvent {
  final bool isGranted;

  const PermissionResultEvent(this.isGranted);

  @override
  List<Object> get props => [isGranted];
}

/// Event to reset permission state
class ResetPermissionEvent extends PermissionEvent {
  const ResetPermissionEvent();
}
