import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

/// Use case to start the tuning process
class StartTuning implements UseCaseNoParams<void> {
  final AudioRepository repository;

  StartTuning(this.repository);

  @override
  Future<Either<Failure, void>> call() async {
    // First check if we have permission
    final permissionResult = await repository.checkMicrophonePermission();

    return permissionResult.fold(
      (failure) => Left(failure),
      (hasPermission) async {
        if (!hasPermission) {
          return const Left(PermissionFailure('Microphone permission not granted'));
        }
        return await repository.startAudioCapture();
      },
    );
  }
}
