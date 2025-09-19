import 'package:equatable/equatable.dart';

/// Represents a musical note with its properties
class Note extends Equatable {
  final String name;
  final double frequency;
  final int octave;

  const Note({
    required this.name,
    required this.frequency,
    required this.octave,
  });

  @override
  List<Object> get props => [name, frequency, octave];

  @override
  String toString() => '$name$octave (${frequency.toStringAsFixed(2)}Hz)';
}
