import '../../domain/entities/note.dart';

/// Data model for Note entity
class NoteModel {
  final String name;
  final double frequency;
  final int octave;

  const NoteModel({
    required this.name,
    required this.frequency,
    required this.octave,
  });

  /// Creates NoteModel from domain entity
  factory NoteModel.fromEntity(Note note) {
    return NoteModel(
      name: note.name,
      frequency: note.frequency,
      octave: note.octave,
    );
  }

  /// Converts to domain entity
  Note toEntity() {
    return Note(
      name: name,
      frequency: frequency,
      octave: octave,
    );
  }

  /// Creates NoteModel from JSON
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      name: json['name'] as String,
      frequency: (json['frequency'] as num).toDouble(),
      octave: json['octave'] as int,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'frequency': frequency,
      'octave': octave,
    };
  }

  @override
  String toString() => '$name$octave (${frequency.toStringAsFixed(2)}Hz)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          frequency == other.frequency &&
          octave == other.octave;

  @override
  int get hashCode => name.hashCode ^ frequency.hashCode ^ octave.hashCode;
}
