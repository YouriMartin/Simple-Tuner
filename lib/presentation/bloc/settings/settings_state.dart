import 'package:equatable/equatable.dart';
import '../../../domain/entities/tuning_settings.dart';

/// Base class for settings states
abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object> get props => [];
}

/// Initial state when settings are not loaded
class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

/// Loading state when loading or saving settings
class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

/// Loaded state with current settings
class SettingsLoaded extends SettingsState {
  final TuningSettings settings;

  const SettingsLoaded(this.settings);

  @override
  List<Object> get props => [settings];

  /// Creates a copy with updated settings
  SettingsLoaded copyWith({TuningSettings? settings}) {
    return SettingsLoaded(settings ?? this.settings);
  }
}

/// Error state for settings-related errors
class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object> get props => [message];
}

/// State when settings are successfully saved
class SettingsSaved extends SettingsState {
  final TuningSettings settings;

  const SettingsSaved(this.settings);

  @override
  List<Object> get props => [settings];
}
