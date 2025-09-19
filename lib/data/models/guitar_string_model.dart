import '../../domain/entities/guitar_string.dart';
import 'note_model.dart';

/// Data model for GuitarString entity
class GuitarStringModel {
  final int stringNumber;
  final NoteModel targetNote;
  final String name;

  const GuitarStringModel({
    required this.stringNumber,
    required this.targetNote,
    required this.name,
  });

  /// Creates GuitarStringModel from domain entity
  factory GuitarStringModel.fromEntity(GuitarString guitarString) {
    return GuitarStringModel(
      stringNumber: guitarString.stringNumber,
      targetNote: NoteModel.fromEntity(guitarString.targetNote),
      name: guitarString.name,
    );
  }

  /// Converts to domain entity
  GuitarString toEntity() {
    return GuitarString(
      stringNumber: stringNumber,
      targetNote: targetNote.toEntity(),
      name: name,
    );
  }

  /// Creates GuitarStringModel from JSON
  factory GuitarStringModel.fromJson(Map<String, dynamic> json) {
    return GuitarStringModel(
      stringNumber: json['stringNumber'] as int,
      targetNote: NoteModel.fromJson(json['targetNote'] as Map<String, dynamic>),
      name: json['name'] as String,
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'stringNumber': stringNumber,
      'targetNote': targetNote.toJson(),
      'name': name,
    };
  }

  @override
  String toString() => 'String $stringNumber: $name (${targetNote.frequency.toStringAsFixed(2)}Hz)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuitarStringModel &&
          runtimeType == other.runtimeType &&
          stringNumber == other.stringNumber &&
          targetNote == other.targetNote &&
          name == other.name;

  @override
  int get hashCode => stringNumber.hashCode ^ targetNote.hashCode ^ name.hashCode;
}
