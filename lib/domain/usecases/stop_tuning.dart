import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/usecases/usecase.dart';
import '../repositories/audio_repository.dart';

/// Use case to stop the tuning process
class StopTuning implements UseCaseNoParams<void> {
  final AudioRepository repository;

  StopTuning(this.repository);

  @override
  Future<Either<Failure, void>> call() async {
    return await repository.stopAudioCapture();
  }
}
