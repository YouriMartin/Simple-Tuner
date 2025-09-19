import 'package:equatable/equatable.dart';
import 'note.dart';

/// Represents the result of audio analysis for tuning
class TuningResult extends Equatable {
  final Note? detectedNote;
  final double detectedFrequency;
  final double centsOffset;
  final double amplitude;
  final bool isInTune;
  final DateTime timestamp;

  const TuningResult({
    this.detectedNote,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.amplitude,
    required this.isInTune,
    required this.timestamp,
  });

  /// Creates a TuningResult indicating no sound detected
  const TuningResult.noSound()
      : detectedNote = null,
        detectedFrequency = 0.0,
        centsOffset = 0.0,
        amplitude = 0.0,
        isInTune = false,
        timestamp = null;

  @override
  List<Object?> get props => [
        detectedNote,
        detectedFrequency,
        centsOffset,
        amplitude,
        isInTune,
        timestamp,
      ];
}
