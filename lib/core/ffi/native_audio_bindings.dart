import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'ffi_structures.dart';
import '../constants/audio_constants.dart';

/// Native audio bindings for FFI communication
class NativeAudioBindings {
  late final DynamicLibrary _dylib;
  late final Pointer<AudioConfigFFI> _audioConfig;
  late final Pointer<TuningSettingsFFI> _tuningSettings;
  late final Pointer<GuitarStringFFI> _guitarStrings;

  // Function bindings
  late final int Function(Pointer<AudioConfigFFI>) _audioInit;
  late final int Function() _audioStart;
  late final int Function() _audioStop;
  late final void Function() _audioCleanup;
  late final int Function(Pointer<TuningResultFFI>) _getLatestResult;
  late final int Function(Pointer<TuningSettingsFFI>, Pointer<GuitarStringFFI>) _setTuningSettings;
  late final int Function() _isAudioRunning;

  bool _isInitialized = false;

  /// Initialize the native library and bindings
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the dynamic library
      _dylib = _loadLibrary();

      // Bind the functions
      _bindFunctions();

      // Initialize audio configuration
      _initializeAudioConfig();

      // Initialize tuning settings
      _initializeTuningSettings();

      // Call native initialization
      final result = _audioInit(_audioConfig);
      if (result != 0) {
        throw Exception('Failed to initialize native audio: error code $result');
      }

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize native bindings: $e');
    }
  }

  /// Load the appropriate dynamic library for the platform
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libsimple_tuner_audio.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('simple_tuner_audio.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libsimple_tuner_audio.so');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libsimple_tuner_audio.dylib');
    }
    throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
  }

  /// Bind native functions to Dart functions
  void _bindFunctions() {
    _audioInit = _dylib
        .lookup<NativeFunction<Int32 Function(Pointer<AudioConfigFFI>)>>('audioInit')
        .asFunction();

    _audioStart = _dylib
        .lookup<NativeFunction<Int32 Function()>>('audioStart')
        .asFunction();

    _audioStop = _dylib
        .lookup<NativeFunction<Int32 Function()>>('audioStop')
        .asFunction();

    _audioCleanup = _dylib
        .lookup<NativeFunction<Void Function()>>('audioCleanup')
        .asFunction();

    _getLatestResult = _dylib
        .lookup<NativeFunction<Int32 Function(Pointer<TuningResultFFI>)>>('getLatestResult')
        .asFunction();

    _setTuningSettings = _dylib
        .lookup<NativeFunction<Int32 Function(Pointer<TuningSettingsFFI>, Pointer<GuitarStringFFI>)>>('setTuningSettings')
        .asFunction();

    _isAudioRunning = _dylib
        .lookup<NativeFunction<Int32 Function()>>('isAudioRunning')
        .asFunction();
  }

  /// Initialize audio configuration structure
  void _initializeAudioConfig() {
    _audioConfig = calloc<AudioConfigFFI>();
    _audioConfig.ref.sampleRate = AudioConstants.sampleRate;
    _audioConfig.ref.bufferSize = AudioConstants.bufferSize;
    _audioConfig.ref.minAmplitude = AudioConstants.minAmplitude;
  }

  /// Initialize tuning settings structure
  void _initializeTuningSettings() {
    _tuningSettings = calloc<TuningSettingsFFI>();
    _tuningSettings.ref.a4Frequency = 440.0;
    _tuningSettings.ref.toleranceCents = 5.0;
    _tuningSettings.ref.minAmplitude = AudioConstants.minAmplitude;
    _tuningSettings.ref.numberOfStrings = 6;

    // Initialize guitar strings (standard tuning)
    _guitarStrings = calloc<GuitarStringFFI>(6);
    _initializeStandardTuning();
  }

  /// Initialize standard guitar tuning
  void _initializeStandardTuning() {
    // Standard tuning frequencies (E-A-D-G-B-E)
    final standardFrequencies = [329.63, 246.94, 196.00, 146.83, 110.00, 82.41];
    final noteIndices = [4, 11, 7, 2, 9, 4]; // E, B, G, D, A, E
    final octaves = [4, 3, 3, 3, 2, 2];

    for (int i = 0; i < 6; i++) {
      _guitarStrings[i].stringNumber = i + 1;
      _guitarStrings[i].targetFrequency = standardFrequencies[i];
      _guitarStrings[i].noteIndex = noteIndices[i];
      _guitarStrings[i].octave = octaves[i];
    }
  }

  /// Start audio capture
  Future<void> startAudioCapture() async {
    _ensureInitialized();
    final result = _audioStart();
    if (result != 0) {
      throw Exception('Failed to start audio capture: error code $result');
    }
  }

  /// Stop audio capture
  Future<void> stopAudioCapture() async {
    _ensureInitialized();
    final result = _audioStop();
    if (result != 0) {
      throw Exception('Failed to stop audio capture: error code $result');
    }
  }

  /// Get the latest tuning result
  TuningResultFFI? getLatestTuningResult() {
    _ensureInitialized();
    final resultPtr = calloc<TuningResultFFI>();

    try {
      final result = _getLatestResult(resultPtr);
      if (result != 0) {
        return null; // No new data available
      }

      // Copy the result to return it
      final tuningResult = resultPtr.ref;
      return tuningResult;
    } finally {
      calloc.free(resultPtr);
    }
  }

  /// Update tuning settings
  Future<void> updateTuningSettings({
    required double a4Frequency,
    required List<double> stringFrequencies,
    double toleranceCents = 5.0,
  }) async {
    _ensureInitialized();

    // Update settings
    _tuningSettings.ref.a4Frequency = a4Frequency;
    _tuningSettings.ref.toleranceCents = toleranceCents;

    // Update string frequencies
    for (int i = 0; i < stringFrequencies.length && i < 6; i++) {
      _guitarStrings[i].targetFrequency = stringFrequencies[i];
    }

    final result = _setTuningSettings(_tuningSettings, _guitarStrings);
    if (result != 0) {
      throw Exception('Failed to update tuning settings: error code $result');
    }
  }

  /// Check if audio is currently running
  bool isAudioRunning() {
    _ensureInitialized();
    return _isAudioRunning() != 0;
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('Native bindings not initialized. Call initialize() first.');
    }
  }

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _audioCleanup();
      calloc.free(_audioConfig);
      calloc.free(_tuningSettings);
      calloc.free(_guitarStrings);
      _isInitialized = false;
    }
  }
}
