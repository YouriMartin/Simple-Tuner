import 'dart:async';

import 'package:permission_handler/permission_handler.dart';

import '../models/tuning_result_model.dart';
import '../../core/error/exceptions.dart';
import 'audio_datasource.dart';

/// Factory exposed to the facade via conditional import
AudioDataSource createAudioDataSource() => WebAudioDataSource();

/// Web implementation (stub) that avoids dart:ffi and native code.
/// It provides a basic stream to keep the app responsive in web builds.
class WebAudioDataSource implements AudioDataSource {
  StreamController<TuningResultModel>? _controller;
  Timer? _timer;
  bool _running = false;

  @override
  Future<void> startAudioCapture() async {
    if (_running) {
      throw AudioException('Audio capture is already running');
    }

    final hasPermission = await checkMicrophonePermission();
    if (!hasPermission) {
      final granted = await requestMicrophonePermission();
      if (!granted) {
        throw PermissionException('Microphone permission not granted');
      }
    }

    _controller = StreamController<TuningResultModel>.broadcast();
    _running = true;

    // Emit a periodic placeholder result to keep the UI updating.
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_running) return;
      _controller?.add(TuningResultModel(
        detectedNote: null,
        detectedFrequency: 0.0,
        centsOffset: 0.0,
        amplitude: 0.0,
        isInTune: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Future<void> stopAudioCapture() async {
    if (!_running) return;
    _timer?.cancel();
    _timer = null;
    await _controller?.close();
    _controller = null;
    _running = false;
  }

  @override
  Stream<TuningResultModel> get tuningResultStream {
    if (_controller == null) {
      throw AudioException('Audio capture not started');
    }
    return _controller!.stream;
  }

  @override
  Future<bool> checkMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted;
    } catch (e) {
      throw PermissionException('Failed to check microphone permission: ${e.toString()}');
    }
  }

  @override
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      throw PermissionException('Failed to request microphone permission: ${e.toString()}');
    }
  }
}
