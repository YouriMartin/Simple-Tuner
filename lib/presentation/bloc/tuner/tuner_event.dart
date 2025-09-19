import 'package:equatable/equatable.dart';
import '../../../domain/entities/tuning_result.dart';

/// Base class for tuner events
abstract class TunerEvent extends Equatable {
  const TunerEvent();

  @override
  List<Object> get props => [];
}

/// Event to start tuning process
class StartTuningEvent extends TunerEvent {
  const StartTuningEvent();
}

/// Event to stop tuning process
class StopTuningEvent extends TunerEvent {
  const StopTuningEvent();
}

/// Event when new tuning data is received
class TuningDataReceivedEvent extends TunerEvent {
  final TuningResult tuningResult;

  const TuningDataReceivedEvent(this.tuningResult);

  @override
  List<Object> get props => [tuningResult];
}

/// Event to reset tuner state
class ResetTunerEvent extends TunerEvent {
  const ResetTunerEvent();
}
