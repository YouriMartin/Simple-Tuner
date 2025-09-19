import 'package:equatable/equatable.dart';
import '../../../domain/entities/tuning_result.dart';

/// Base class for tuner states
abstract class TunerState extends Equatable {
  const TunerState();

  @override
  List<Object?> get props => [];
}

/// Initial state when tuner is not active
class TunerInitial extends TunerState {
  const TunerInitial();
}

/// Loading state when starting tuner
class TunerLoading extends TunerState {
  const TunerLoading();
}

/// Active state when tuner is running and receiving data
class TunerRunning extends TunerState {
  final TuningResult? currentResult;
  final List<double> recentCentsHistory;

  const TunerRunning({
    this.currentResult,
    this.recentCentsHistory = const [],
  });

  @override
  List<Object?> get props => [currentResult, recentCentsHistory];

  /// Creates a copy with updated values
  TunerRunning copyWith({
    TuningResult? currentResult,
    List<double>? recentCentsHistory,
  }) {
    return TunerRunning(
      currentResult: currentResult ?? this.currentResult,
      recentCentsHistory: recentCentsHistory ?? this.recentCentsHistory,
    );
  }
}

/// Error state when something goes wrong
class TunerError extends TunerState {
  final String message;

  const TunerError(this.message);

  @override
  List<Object> get props => [message];
}

/// State when tuner is stopped
class TunerStopped extends TunerState {
  const TunerStopped();
}
