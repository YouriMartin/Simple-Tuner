import '../../domain/entities/tuning_result.dart';
import 'note_model.dart';

/// Data model for TuningResult entity
class TuningResultModel {
  final NoteModel? detectedNote;
  final double detectedFrequency;
  final double centsOffset;
  final double amplitude;
  final bool isInTune;
  final DateTime timestamp;

  const TuningResultModel({
    this.detectedNote,
    required this.detectedFrequency,
    required this.centsOffset,
    required this.amplitude,
    required this.isInTune,
    required this.timestamp,
  });

  /// Creates TuningResultModel from domain entity
  factory TuningResultModel.fromEntity(TuningResult result) {
    return TuningResultModel(
      detectedNote: result.detectedNote != null 
          ? NoteModel.fromEntity(result.detectedNote!)
          : null,
      detectedFrequency: result.detectedFrequency,
      centsOffset: result.centsOffset,
      amplitude: result.amplitude,
      isInTune: result.isInTune,
      timestamp: result.timestamp,
    );
  }

  /// Converts to domain entity
  TuningResult toEntity() {
    return TuningResult(
      detectedNote: detectedNote?.toEntity(),
      detectedFrequency: detectedFrequency,
      centsOffset: centsOffset,
      amplitude: amplitude,
      isInTune: isInTune,
      timestamp: timestamp,
    );
  }

  /// Creates a TuningResultModel indicating no sound detected
  const TuningResultModel.noSound()
      : detectedNote = null,
        detectedFrequency = 0.0,
        centsOffset = 0.0,
        amplitude = 0.0,
        isInTune = false,
        timestamp = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuningResultModel &&
          runtimeType == other.runtimeType &&
          detectedNote == other.detectedNote &&
          detectedFrequency == other.detectedFrequency &&
          centsOffset == other.centsOffset &&
          amplitude == other.amplitude &&
          isInTune == other.isInTune &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      detectedNote.hashCode ^
      detectedFrequency.hashCode ^
      centsOffset.hashCode ^
      amplitude.hashCode ^
      isInTune.hashCode ^
      timestamp.hashCode;
}
