import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:simple_tuner/core/error/failures.dart';
import 'package:simple_tuner/domain/repositories/audio_repository.dart';
import 'package:simple_tuner/domain/usecases/start_tuning.dart';

import 'start_tuning_test.mocks.dart';

@GenerateMocks([AudioRepository])
void main() {
  late StartTuning usecase;
  late MockAudioRepository mockAudioRepository;

  setUp(() {
    mockAudioRepository = MockAudioRepository();
    usecase = StartTuning(mockAudioRepository);
  });

  group('StartTuning', () {
    test('should start audio capture when permission is granted', () async {
      // arrange
      when(mockAudioRepository.checkMicrophonePermission())
          .thenAnswer((_) async => const Right(true));
      when(mockAudioRepository.startAudioCapture())
          .thenAnswer((_) async => const Right(null));

      // act
      final result = await usecase();

      // assert
      expect(result, const Right(null));
      verify(mockAudioRepository.checkMicrophonePermission());
      verify(mockAudioRepository.startAudioCapture());
    });

    test('should return PermissionFailure when permission is not granted', () async {
      // arrange
      when(mockAudioRepository.checkMicrophonePermission())
          .thenAnswer((_) async => const Right(false));

      // act
      final result = await usecase();

      // assert
      expect(result, const Left(PermissionFailure('Microphone permission not granted')));
      verify(mockAudioRepository.checkMicrophonePermission());
      verifyNever(mockAudioRepository.startAudioCapture());
    });

    test('should return failure when checking permission fails', () async {
      // arrange
      when(mockAudioRepository.checkMicrophonePermission())
          .thenAnswer((_) async => const Left(PermissionFailure('Permission check failed')));

      // act
      final result = await usecase();

      // assert
      expect(result, const Left(PermissionFailure('Permission check failed')));
      verify(mockAudioRepository.checkMicrophonePermission());
      verifyNever(mockAudioRepository.startAudioCapture());
    });

    test('should return failure when starting audio capture fails', () async {
      // arrange
      when(mockAudioRepository.checkMicrophonePermission())
          .thenAnswer((_) async => const Right(true));
      when(mockAudioRepository.startAudioCapture())
          .thenAnswer((_) async => const Left(AudioFailure('Audio capture failed')));

      // act
      final result = await usecase();

      // assert
      expect(result, const Left(AudioFailure('Audio capture failed')));
      verify(mockAudioRepository.checkMicrophonePermission());
      verify(mockAudioRepository.startAudioCapture());
    });
  });
}
