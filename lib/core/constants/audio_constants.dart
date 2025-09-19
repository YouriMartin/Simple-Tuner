/// Audio processing constants
class AudioConstants {
  // Sample rate for audio processing
  static const int sampleRate = 44100;

  // Buffer size for FFT analysis
  static const int bufferSize = 4096;

  // Minimum amplitude to consider a signal
  static const double minAmplitude = 0.001;

  // Cents precision (0.5 cents)
  static const double centsPrecision = 0.5;

  // Number of LEDs on each side
  static const int ledsPerSide = 10;

  // LED update frequency (60 FPS)
  static const int ledUpdateFrequencyMs = 16;

  // Frequency range for guitar strings (in Hz)
  static const double minFrequency = 70.0;  // Below low E
  static const double maxFrequency = 400.0; // Above high E
}
