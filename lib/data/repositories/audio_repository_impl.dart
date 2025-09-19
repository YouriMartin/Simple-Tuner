import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/tuning_result.dart';
import '../../domain/repositories/audio_repository.dart';
import '../datasources/audio_datasource.dart';

/// Implementation of AudioRepository
class AudioRepositoryImpl implements AudioRepository {
  final AudioDataSource _audioDataSource;

  AudioRepositoryImpl({
    required AudioDataSource audioDataSource,
  }) : _audioDataSource = audioDataSource;

  @override
  Future<Either<Failure, void>> startAudioCapture() async {
    try {
      await _audioDataSource.startAudioCapture();
      return const Right(null);
    } on AudioException catch (e) {
      return Left(AudioFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(AudioFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> stopAudioCapture() async {
    try {
      await _audioDataSource.stopAudioCapture();
      return const Right(null);
    } on AudioException catch (e) {
      return Left(AudioFailure(e.message));
    } catch (e) {
      return Left(AudioFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Stream<TuningResult> get tuningResultStream {
    return _audioDataSource.tuningResultStream
        .map((model) => model.toEntity())
        .handleError((error) {
      if (error is AudioException) {
        throw AudioFailure(error.message);
      }
      throw AudioFailure('Stream error: ${error.toString()}');
    });
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    try {
      final hasPermission = await _audioDataSource.checkMicrophonePermission();
      return Right(hasPermission);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(PermissionFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    try {
      final isGranted = await _audioDataSource.requestMicrophonePermission();
      return Right(isGranted);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(PermissionFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
