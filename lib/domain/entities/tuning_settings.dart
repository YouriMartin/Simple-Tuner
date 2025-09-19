import 'package:equatable/equatable.dart';
import 'guitar_string.dart';
import 'note.dart';

/// Configuration settings for the tuner
class TuningSettings extends Equatable {
  final double a4Frequency;
  final List<GuitarString> strings;
  final double toleranceCents;
  final double minAmplitude;

  const TuningSettings({
    required this.a4Frequency,
    required this.strings,
    this.toleranceCents = 5.0, // ±5 cents tolerance
    this.minAmplitude = 0.01,
  });

  /// Standard guitar tuning (E-A-D-G-B-E)
  factory TuningSettings.standard({double a4Frequency = 440.0}) {
    return TuningSettings(
      a4Frequency: a4Frequency,
      strings: _createStandardTuning(a4Frequency),
    );
  }

  static List<GuitarString> _createStandardTuning(double a4Frequency) {
    // Calculate frequencies based on A4 = 440Hz (or custom)
    final double ratio = a4Frequency / 440.0;

    return [
      GuitarString(
        stringNumber: 1,
        name: 'High E',
        targetNote: Note(name: 'E', frequency: 329.63 * ratio, octave: 4),
      ),
      GuitarString(
        stringNumber: 2,
        name: 'B',
        targetNote: Note(name: 'B', frequency: 246.94 * ratio, octave: 3),
      ),
      GuitarString(
        stringNumber: 3,
        name: 'G',
        targetNote: Note(name: 'G', frequency: 196.00 * ratio, octave: 3),
      ),
      GuitarString(
        stringNumber: 4,
        name: 'D',
        targetNote: Note(name: 'D', frequency: 146.83 * ratio, octave: 3),
      ),
      GuitarString(
        stringNumber: 5,
        name: 'A',
        targetNote: Note(name: 'A', frequency: 110.00 * ratio, octave: 2),
      ),
      GuitarString(
        stringNumber: 6,
        name: 'Low E',
        targetNote: Note(name: 'E', frequency: 82.41 * ratio, octave: 2),
      ),
    ];
  }

  /// Creates a copy with modified string frequency
  TuningSettings copyWithStringFrequency(int stringNumber, double newFrequency) {
    final updatedStrings = strings.map((string) {
      if (string.stringNumber == stringNumber) {
        return GuitarString(
          stringNumber: string.stringNumber,
          name: string.name,
          targetNote: Note(
            name: string.targetNote.name,
            frequency: newFrequency,
            octave: string.targetNote.octave,
          ),
        );
      }
      return string;
    }).toList();

    return TuningSettings(
      a4Frequency: a4Frequency,
      strings: updatedStrings,
      toleranceCents: toleranceCents,
      minAmplitude: minAmplitude,
    );
  }

  /// Creates a copy with new A4 frequency
  TuningSettings copyWithA4Frequency(double newA4Frequency) {
    return TuningSettings.standard(a4Frequency: newA4Frequency);
  }

  @override
  List<Object> get props => [a4Frequency, strings, toleranceCents, minAmplitude];
}
