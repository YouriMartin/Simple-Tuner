import 'package:equatable/equatable.dart';

/// Base class for permission states
abstract class PermissionState extends Equatable {
  const PermissionState();

  @override
  List<Object> get props => [];
}

/// Initial state when permission status is unknown
class PermissionInitial extends PermissionState {
  const PermissionInitial();
}

/// Loading state when checking/requesting permission
class PermissionLoading extends PermissionState {
  const PermissionLoading();
}

/// State when permission is granted
class PermissionGranted extends PermissionState {
  const PermissionGranted();
}

/// State when permission is denied
class PermissionDenied extends PermissionState {
  const PermissionDenied();
}

/// State when permission is permanently denied
class PermissionPermanentlyDenied extends PermissionState {
  const PermissionPermanentlyDenied();
}

/// Error state for permission-related errors
class PermissionError extends PermissionState {
  final String message;

  const PermissionError(this.message);

  @override
  List<Object> get props => [message];
}
