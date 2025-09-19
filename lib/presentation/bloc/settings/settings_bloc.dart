import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/tuning_settings.dart';
import '../../../domain/repositories/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// BLoC for managing tuning settings
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _repository;

  SettingsBloc({
    required SettingsRepository repository,
  })  : _repository = repository,
        super(const SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<SaveSettingsEvent>(_onSaveSettings);
    on<UpdateA4FrequencyEvent>(_onUpdateA4Frequency);
    on<UpdateStringFrequencyEvent>(_onUpdateStringFrequency);
    on<ResetToStandardTuningEvent>(_onResetToStandardTuning);
    on<UpdateToleranceEvent>(_onUpdateTolerance);
  }

  Future<void> _onLoadSettings(
    LoadSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());

    final result = await _repository.loadSettings();

    result.fold(
      (failure) {
        // If loading fails, use default settings
        final defaultSettings = TuningSettings.standard();
        emit(SettingsLoaded(defaultSettings));
      },
      (settings) => emit(SettingsLoaded(settings)),
    );
  }

  Future<void> _onSaveSettings(
    SaveSettingsEvent event,
    Emitter<SettingsState> emit,
  ) async {
    final currentState = state;
    emit(const SettingsLoading());

    final result = await _repository.saveSettings(event.settings);

    result.fold(
      (failure) {
        emit(SettingsError(failure.message));
        // Restore previous state
        if (currentState is SettingsLoaded) {
          emit(currentState);
        }
      },
      (_) => emit(SettingsSaved(event.settings)),
    );
  }

  void _onUpdateA4Frequency(
    UpdateA4FrequencyEvent event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWithA4Frequency(event.frequency);
      emit(SettingsLoaded(updatedSettings));

      // Auto-save the settings
      add(SaveSettingsEvent(updatedSettings));
    }
  }

  void _onUpdateStringFrequency(
    UpdateStringFrequencyEvent event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = currentState.settings.copyWithStringFrequency(
        event.stringNumber,
        event.frequency,
      );
      emit(SettingsLoaded(updatedSettings));

      // Auto-save the settings
      add(SaveSettingsEvent(updatedSettings));
    }
  }

  void _onResetToStandardTuning(
    ResetToStandardTuningEvent event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final standardSettings = TuningSettings.standard(
        a4Frequency: currentState.settings.a4Frequency,
      );
      emit(SettingsLoaded(standardSettings));

      // Auto-save the settings
      add(SaveSettingsEvent(standardSettings));
    }
  }

  void _onUpdateTolerance(
    UpdateToleranceEvent event,
    Emitter<SettingsState> emit,
  ) {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      final updatedSettings = TuningSettings(
        a4Frequency: currentState.settings.a4Frequency,
        strings: currentState.settings.strings,
        toleranceCents: event.toleranceCents,
        minAmplitude: currentState.settings.minAmplitude,
      );
      emit(SettingsLoaded(updatedSettings));

      // Auto-save the settings
      add(SaveSettingsEvent(updatedSettings));
    }
  }
}
