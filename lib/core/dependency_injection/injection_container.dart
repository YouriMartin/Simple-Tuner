import 'package:get_it/get_it.dart';
import '../../data/data_exports.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/start_tuning.dart';
import '../../domain/usecases/stop_tuning.dart';
import '../../domain/usecases/get_tuning_stream.dart';
import '../../domain/usecases/request_microphone_permission.dart';
import '../../presentation/bloc/bloc_exports.dart';

/// Dependency injection container using GetIt
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  // ===== Features - Tuner =====

  // BLoC
  sl.registerFactory(
    () => TunerBloc(
      startTuning: sl(),
      stopTuning: sl(),
      getTuningStream: sl(),
    ),
  );

  sl.registerFactory(
    () => PermissionBloc(
      requestPermission: sl(),
      audioRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => SettingsBloc(
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => StartTuning(sl()));
  sl.registerLazySingleton(() => StopTuning(sl()));
  sl.registerLazySingleton(() => GetTuningStream(sl()));
  sl.registerLazySingleton(() => RequestMicrophonePermission(sl()));

  // Repository
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(audioDataSource: sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AudioDataSource>(
    () => createAudioDataSource(),
  );

  sl.registerLazySingleton<LocalStorageDataSource>(
    () => LocalStorageDataSourceImpl(),
  );

  // ===== External =====
  // No external dependencies for now (using built-in Flutter packages)
}
