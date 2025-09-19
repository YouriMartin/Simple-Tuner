import '../../core/usecases/usecase.dart';
import '../entities/tuning_result.dart';
import '../repositories/audio_repository.dart';

/// Use case to get the stream of tuning results
class GetTuningStream implements StreamUseCaseNoParams<TuningResult> {
  final AudioRepository repository;

  GetTuningStream(this.repository);

  @override
  Stream<TuningResult> call() {
    return repository.tuningResultStream;
  }
}
