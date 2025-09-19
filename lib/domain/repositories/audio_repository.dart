import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/tuning_result.dart';

/// Repository interface for audio processing operations
abstract class AudioRepository {
  /// Starts audio capture and processing
  Future<Either<Failure, void>> startAudioCapture();

  /// Stops audio capture and processing
  Future<Either<Failure, void>> stopAudioCapture();

  /// Stream of tuning results from audio analysis
  Stream<TuningResult> get tuningResultStream;

  /// Checks if microphone permission is granted
  Future<Either<Failure, bool>> checkMicrophonePermission();

  /// Requests microphone permission
  Future<Either<Failure, bool>> requestMicrophonePermission();
}
