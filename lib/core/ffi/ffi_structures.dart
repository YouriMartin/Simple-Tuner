import 'dart:ffi';

/// FFI structure for audio configuration
final class AudioConfigFFI extends Struct {
  @Int32()
  external int sampleRate;

  @Int32()
  external int bufferSize;

  @Double()
  external double minAmplitude;
}

/// FFI structure for tuning result
final class TuningResultFFI extends Struct {
  @Double()
  external double detectedFrequency;

  @Double()
  external double centsOffset;

  @Double()
  external double amplitude;

  @Int32()
  external int isInTune; // 0 = false, 1 = true

  @Int64()
  external int timestampMs;

  @Int32()
  external int hasValidNote; // 0 = false, 1 = true
}

/// FFI structure for note information
final class NoteInfoFFI extends Struct {
  @Int32()
  external int noteIndex; // 0-11 (C, C#, D, D#, E, F, F#, G, G#, A, A#, B)

  @Int32()
  external int octave;

  @Double()
  external double targetFrequency;
}

/// FFI structure for guitar string configuration
final class GuitarStringFFI extends Struct {
  @Int32()
  external int stringNumber; // 1-6

  @Double()
  external double targetFrequency;

  @Int32()
  external int noteIndex;

  @Int32()
  external int octave;
}

/// FFI structure for tuning settings
final class TuningSettingsFFI extends Struct {
  @Double()
  external double a4Frequency;

  @Double()
  external double toleranceCents;

  @Double()
  external double minAmplitude;

  @Int32()
  external int numberOfStrings; // Should be 6 for guitar
}

/// Helper class for FFI type definitions
class FFITypes {
  // Function signatures for native calls
  static const audioInitSignature = 'int audioInit(void* config)';
  static const audioStartSignature = 'int audioStart()';
  static const audioStopSignature = 'int audioStop()';
  static const audioCleanupSignature = 'void audioCleanup()';
  static const getLatestResultSignature = 'int getLatestResult(void* result)';
  static const setTuningSettingsSignature = 'int setTuningSettings(void* settings, void* strings)';
  static const isAudioRunningSignature = 'int isAudioRunning()';
}
