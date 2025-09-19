import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/tuning_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/tuning_settings_model.dart';

/// Implementation of SettingsRepository
class SettingsRepositoryImpl implements SettingsRepository {
  final LocalStorageDataSource _localDataSource;

  SettingsRepositoryImpl({
    required LocalStorageDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Either<Failure, TuningSettings>> loadSettings() async {
    try {
      final settingsModel = await _localDataSource.loadSettings();
      return Right(settingsModel.toEntity());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(TuningSettings settings) async {
    try {
      final settingsModel = TuningSettingsModel.fromEntity(settings);
      await _localDataSource.saveSettings(settingsModel);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Unexpected error: ${e.toString()}'));
    }
  }
}
