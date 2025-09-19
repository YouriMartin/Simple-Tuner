import 'package:equatable/equatable.dart';
import '../../../domain/entities/tuning_settings.dart';

/// Base class for settings events
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

/// Event to load settings from storage
class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

/// Event to save current settings
class SaveSettingsEvent extends SettingsEvent {
  final TuningSettings settings;

  const SaveSettingsEvent(this.settings);

  @override
  List<Object> get props => [settings];
}

/// Event to update A4 frequency
class UpdateA4FrequencyEvent extends SettingsEvent {
  final double frequency;

  const UpdateA4FrequencyEvent(this.frequency);

  @override
  List<Object> get props => [frequency];
}

/// Event to update individual string frequency
class UpdateStringFrequencyEvent extends SettingsEvent {
  final int stringNumber;
  final double frequency;

  const UpdateStringFrequencyEvent(this.stringNumber, this.frequency);

  @override
  List<Object> get props => [stringNumber, frequency];
}

/// Event to reset to standard tuning
class ResetToStandardTuningEvent extends SettingsEvent {
  const ResetToStandardTuningEvent();
}

/// Event to update tolerance
class UpdateToleranceEvent extends SettingsEvent {
  final double toleranceCents;

  const UpdateToleranceEvent(this.toleranceCents);

  @override
  List<Object> get props => [toleranceCents];
}
