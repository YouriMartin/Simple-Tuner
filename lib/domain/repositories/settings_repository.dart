import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/tuning_settings.dart';

/// Repository interface for settings persistence
abstract class SettingsRepository {
  /// Loads tuning settings from storage
  Future<Either<Failure, TuningSettings>> loadSettings();

  /// Saves tuning settings to storage
  Future<Either<Failure, void>> saveSettings(TuningSettings settings);
}
