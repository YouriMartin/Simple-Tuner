import 'dart:async';

import '../models/tuning_result_model.dart';

// Conditional import that picks the proper implementation per platform.
import 'audio_datasource_web.dart' if (dart.library.io) 'audio_datasource_native.dart' as platform;

/// Data source for audio processing operations (platform-agnostic interface)
abstract class AudioDataSource {
  Future<void> startAudioCapture();
  Future<void> stopAudioCapture();
  Stream<TuningResultModel> get tuningResultStream;
  Future<bool> checkMicrophonePermission();
  Future<bool> requestMicrophonePermission();
}

/// Factory that returns the platform-specific implementation.
AudioDataSource createAudioDataSource() => platform.createAudioDataSource();
