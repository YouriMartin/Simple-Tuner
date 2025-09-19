import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';
import 'package:simple_tuner/core/error/failures.dart';
import 'package:simple_tuner/domain/entities/tuning_result.dart';
import 'package:simple_tuner/domain/entities/note.dart';
import 'package:simple_tuner/domain/usecases/start_tuning.dart';
import 'package:simple_tuner/domain/usecases/stop_tuning.dart';
import 'package:simple_tuner/domain/usecases/get_tuning_stream.dart';
import 'package:simple_tuner/presentation/bloc/tuner/tuner_bloc.dart';
import 'package:simple_tuner/presentation/bloc/tuner/tuner_event.dart';
import 'package:simple_tuner/presentation/bloc/tuner/tuner_state.dart';

import 'tuner_bloc_test.mocks.dart';

@GenerateMocks([StartTuning, StopTuning, GetTuningStream])
void main() {
  late TunerBloc tunerBloc;
  late MockStartTuning mockStartTuning;
  late MockStopTuning mockStopTuning;
  late MockGetTuningStream mockGetTuningStream;

  setUp(() {
    mockStartTuning = MockStartTuning();
    mockStopTuning = MockStopTuning();
    mockGetTuningStream = MockGetTuningStream();

    tunerBloc = TunerBloc(
      startTuning: mockStartTuning,
      stopTuning: mockStopTuning,
      getTuningStream: mockGetTuningStream,
    );
  });

  tearDown(() {
    tunerBloc.close();
  });

  group('TunerBloc', () {
    test('initial state should be TunerInitial', () {
      expect(tunerBloc.state, const TunerInitial());
    });

    group('StartTuningEvent', () {
      blocTest<TunerBloc, TunerState>(
        'should emit [TunerLoading, TunerRunning] when starting tuning succeeds',
        build: () {
          when(mockStartTuning()).thenAnswer((_) async => const Right(null));
          when(mockGetTuningStream()).thenAnswer((_) => Stream.empty());
          return tunerBloc;
        },
        act: (bloc) => bloc.add(const StartTuningEvent()),
        expect: () => [
          const TunerLoading(),
          const TunerRunning(),
        ],
        verify: (_) {
          verify(mockStartTuning()).called(1);
          verify(mockGetTuningStream()).called(1);
        },
      );

      blocTest<TunerBloc, TunerState>(
        'should emit [TunerLoading, TunerError] when starting tuning fails',
        build: () {
          when(mockStartTuning()).thenAnswer(
            (_) async => const Left(AudioFailure('Failed to start')),
          );
          return tunerBloc;
        },
        act: (bloc) => bloc.add(const StartTuningEvent()),
        expect: () => [
          const TunerLoading(),
          const TunerError('Failed to start'),
        ],
        verify: (_) {
          verify(mockStartTuning()).called(1);
          verifyNever(mockGetTuningStream());
        },
      );
    });

    group('StopTuningEvent', () {
      blocTest<TunerBloc, TunerState>(
        'should emit [TunerStopped] when stopping tuning succeeds',
        build: () {
          when(mockStopTuning()).thenAnswer((_) async => const Right(null));
          return tunerBloc;
        },
        act: (bloc) => bloc.add(const StopTuningEvent()),
        expect: () => [const TunerStopped()],
        verify: (_) {
          verify(mockStopTuning()).called(1);
        },
      );
    });

    group('TuningDataReceivedEvent', () {
      const testResult = TuningResult(
        detectedNote: Note(name: 'A', frequency: 440.0, octave: 4),
        detectedFrequency: 440.0,
        centsOffset: 5.0,
        amplitude: 0.8,
        isInTune: false,
        timestamp: null,
      );

      blocTest<TunerBloc, TunerState>(
        'should update current result when tuner is running',
        build: () => tunerBloc,
        seed: () => const TunerRunning(),
        act: (bloc) => bloc.add(const TuningDataReceivedEvent(testResult)),
        expect: () => [
          const TunerRunning(
            currentResult: testResult,
            recentCentsHistory: [5.0],
          ),
        ],
      );

      blocTest<TunerBloc, TunerState>(
        'should not update when tuner is not running',
        build: () => tunerBloc,
        act: (bloc) => bloc.add(const TuningDataReceivedEvent(testResult)),
        expect: () => [],
      );
    });

    group('ResetTunerEvent', () {
      blocTest<TunerBloc, TunerState>(
        'should emit [TunerInitial] when reset',
        build: () => tunerBloc,
        act: (bloc) => bloc.add(const ResetTunerEvent()),
        expect: () => [const TunerInitial()],
      );
    });
  });
}
