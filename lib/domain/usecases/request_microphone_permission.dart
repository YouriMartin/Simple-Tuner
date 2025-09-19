import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

/// Use case to request microphone permission
class RequestMicrophonePermission implements UseCaseNoParams<bool> {
  final AudioRepository repository;

  RequestMicrophonePermission(this.repository);

  @override
  Future<Either<Failure, bool>> call() async {
    return await repository.requestMicrophonePermission();
  }
}
