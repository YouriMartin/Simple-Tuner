import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/start_tuning.dart';
import '../../../domain/usecases/stop_tuning.dart';
import '../../../domain/usecases/get_tuning_stream.dart';
import '../../../domain/entities/tuning_result.dart';
import '../../../core/constants/audio_constants.dart';
import 'tuner_event.dart';
import 'tuner_state.dart';

/// BLoC for managing tuner functionality
class TunerBloc extends Bloc<TunerEvent, TunerState> {
  final StartTuning _startTuning;
  final StopTuning _stopTuning;
  final GetTuningStream _getTuningStream;

  StreamSubscription<TuningResult>? _tuningSubscription;
  final List<double> _centsHistory = [];

  TunerBloc({
    required StartTuning startTuning,
    required StopTuning stopTuning,
    required GetTuningStream getTuningStream,
  })  : _startTuning = startTuning,
        _stopTuning = stopTuning,
        _getTuningStream = getTuningStream,
        super(const TunerInitial()) {
    on<StartTuningEvent>(_onStartTuning);
    on<StopTuningEvent>(_onStopTuning);
    on<TuningDataReceivedEvent>(_onTuningDataReceived);
    on<ResetTunerEvent>(_onResetTuner);
  }

  Future<void> _onStartTuning(
    StartTuningEvent event,
    Emitter<TunerState> emit,
  ) async {
    emit(const TunerLoading());

    final result = await _startTuning();

    result.fold(
      (failure) => emit(TunerError(failure.message)),
      (_) {
        // Subscribe to tuning stream
        _tuningSubscription = _getTuningStream().listen(
          (tuningResult) {
            add(TuningDataReceivedEvent(tuningResult));
          },
          onError: (error) {
            add(const StopTuningEvent());
            emit(TunerError(error.toString()));
          },
        );

        emit(const TunerRunning());
      },
    );
  }

  Future<void> _onStopTuning(
    StopTuningEvent event,
    Emitter<TunerState> emit,
  ) async {
    await _tuningSubscription?.cancel();
    _tuningSubscription = null;
    _centsHistory.clear();

    final result = await _stopTuning();

    result.fold(
      (failure) => emit(TunerError(failure.message)),
      (_) => emit(const TunerStopped()),
    );
  }

  void _onTuningDataReceived(
    TuningDataReceivedEvent event,
    Emitter<TunerState> emit,
  ) {
    if (state is TunerRunning) {
      // Update cents history for smoother LED display
      _updateCentsHistory(event.tuningResult.centsOffset);

      final currentState = state as TunerRunning;
      emit(currentState.copyWith(
        currentResult: event.tuningResult,
        recentCentsHistory: List.from(_centsHistory),
      ));
    }
  }

  void _onResetTuner(
    ResetTunerEvent event,
    Emitter<TunerState> emit,
  ) {
    _centsHistory.clear();
    emit(const TunerInitial());
  }

  void _updateCentsHistory(double cents) {
    _centsHistory.add(cents);

    // Keep only recent history for smoother display
    const maxHistorySize = 10;
    if (_centsHistory.length > maxHistorySize) {
      _centsHistory.removeAt(0);
    }
  }

  @override
  Future<void> close() {
    _tuningSubscription?.cancel();
    return super.close();
  }
}
