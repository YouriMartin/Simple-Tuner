import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Audio-related failures
class AudioFailure extends Failure {
  const AudioFailure(super.message);
}

/// Permission-related failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Settings-related failures
class SettingsFailure extends Failure {
  const SettingsFailure(super.message);
}

/// Network or external service failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Cache or local storage failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
