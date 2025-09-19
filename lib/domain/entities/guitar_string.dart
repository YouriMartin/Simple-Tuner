import 'package:equatable/equatable.dart';
import 'note.dart';

/// Represents a guitar string with its tuning configuration
class GuitarString extends Equatable {
  final int stringNumber; // 1-6 (1 = high E, 6 = low E)
  final Note targetNote;
  final String name;

  const GuitarString({
    required this.stringNumber,
    required this.targetNote,
    required this.name,
  });

  @override
  List<Object> get props => [stringNumber, targetNote, name];

  @override
  String toString() => 'String $stringNumber: $name (${targetNote.frequency.toStringAsFixed(2)}Hz)';
}
