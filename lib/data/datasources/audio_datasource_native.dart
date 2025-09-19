import 'dart:async';
import 'dart:ffi';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/tuning_result_model.dart';
import '../models/note_model.dart';
import '../../core/error/exceptions.dart';
import '../../core/constants/audio_constants.dart';
import '../../core/ffi/native_audio_bindings.dart';
import '../../core/ffi/ffi_structures.dart';
import 'audio_datasource.dart';

/// Factory exposed to the facade via conditional import
AudioDataSource createAudioDataSource() => NativeAudioDataSource();

/// Native/IO implementation using FFI bindings
class NativeAudioDataSource implements AudioDataSource {
  StreamController<TuningResultModel>? _tuningController;
  Timer? _audioProcessingTimer;
  bool _isCapturing = false;
  late final NativeAudioBindings _nativeBindings;

  NativeAudioDataSource() {
    _nativeBindings = NativeAudioBindings();
  }

  Future<void> _ensureInitialized() async {
    await _nativeBindings.initialize();
  }

  @override
  Future<void> startAudioCapture() async {
    try {
      if (_isCapturing) {
        throw AudioException('Audio capture is already running');
      }

      // Check permission first
      final hasPermission = await checkMicrophonePermission();
      if (!hasPermission) {
        throw PermissionException('Microphone permission not granted');
      }

      // Ensure native bindings are initialized
      await _ensureInitialized();

      _tuningController = StreamController<TuningResultModel>.broadcast();

      // Start native audio capture
      await _nativeBindings.startAudioCapture();
      _isCapturing = true;

      // Start polling for results
      _startResultPolling();
    } catch (e) {
      throw AudioException('Failed to start audio capture: ${e.toString()}');
    }
  }

  @override
  Future<void> stopAudioCapture() async {
    try {
      if (!_isCapturing) {
        return;
      }

      _audioProcessingTimer?.cancel();
      _audioProcessingTimer = null;

      // Stop native audio capture
      await _nativeBindings.stopAudioCapture();

      await _tuningController?.close();
      _tuningController = null;

      _isCapturing = false;
    } catch (e) {
      throw AudioException('Failed to stop audio capture: ${e.toString()}');
    }
  }

  @override
  Stream<TuningResultModel> get tuningResultStream {
    if (_tuningController == null) {
      throw AudioException('Audio capture not started');
    }
    return _tuningController!.stream;
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

  // Start polling for results from native code
  void _startResultPolling() {
    _audioProcessingTimer = Timer.periodic(
      Duration(milliseconds: AudioConstants.ledUpdateFrequencyMs),
      (timer) {
        if (!_isCapturing) {
          timer.cancel();
          return;
        }

        // Get latest result from native code
        final nativeResult = _nativeBindings.getLatestTuningResult();
        if (nativeResult != null) {
          final tuningResult = _convertFromNative(nativeResult);
          _tuningController?.add(tuningResult);
        }
      },
    );
  }

  TuningResultModel _convertFromNative(TuningResultFFI nativeResult) {
    NoteModel? detectedNote;

    if (nativeResult.hasValidNote != 0) {
      // Convert frequency to note (simplified)
      final noteIndex = _frequencyToNoteIndex(nativeResult.detectedFrequency);
      final octave = _frequencyToOctave(nativeResult.detectedFrequency);
      final noteName = _getNoteNameFromIndex(noteIndex);

      detectedNote = NoteModel(
        name: noteName,
        frequency: nativeResult.detectedFrequency,
        octave: octave,
      );
    }

    return TuningResultModel(
      detectedNote: detectedNote,
      detectedFrequency: nativeResult.detectedFrequency,
      centsOffset: nativeResult.centsOffset,
      amplitude: nativeResult.amplitude,
      isInTune: nativeResult.isInTune != 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(nativeResult.timestampMs),
    );
  }

  int _frequencyToNoteIndex(double frequency) {
    // Calculate note index from frequency (A4 = 440Hz is index 9)
    final a4Frequency = 440.0;
    final semitonesFromA4 = 12.0 * (log(frequency / a4Frequency) / log(2));
    final noteIndex = (9 + semitonesFromA4.round()) % 12;
    return noteIndex < 0 ? noteIndex + 12 : noteIndex;
  }

  int _frequencyToOctave(double frequency) {
    // Calculate octave (A4 is octave 4)
    final a4Frequency = 440.0;
    final semitonesFromA4 = 12.0 * (log(frequency / a4Frequency) / log(2));
    return 4 + (semitonesFromA4 / 12).floor();
  }

  String _getNoteNameFromIndex(int index) {
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    return noteNames[index % 12];
  }

  /// Update tuning settings in native code
  Future<void> updateTuningSettings({
    required double a4Frequency,
    required List<double> stringFrequencies,
    double toleranceCents = 5.0,
  }) async {
    try {
      await _ensureInitialized();
      await _nativeBindings.updateTuningSettings(
        a4Frequency: a4Frequency,
        stringFrequencies: stringFrequencies,
        toleranceCents: toleranceCents,
      );
    } catch (e) {
      throw AudioException('Failed to update tuning settings: ${e.toString()}');
    }
  }

  void dispose() {
    _audioProcessingTimer?.cancel();
    _tuningController?.close();
    _nativeBindings.dispose();
  }
}
