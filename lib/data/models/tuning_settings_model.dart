import '../../domain/entities/tuning_settings.dart';
import 'guitar_string_model.dart';

/// Data model for TuningSettings entity
class TuningSettingsModel {
  final double a4Frequency;
  final List<GuitarStringModel> strings;
  final double toleranceCents;
  final double minAmplitude;

  const TuningSettingsModel({
    required this.a4Frequency,
    required this.strings,
    required this.toleranceCents,
    required this.minAmplitude,
  });

  /// Creates TuningSettingsModel from domain entity
  factory TuningSettingsModel.fromEntity(TuningSettings settings) {
    return TuningSettingsModel(
      a4Frequency: settings.a4Frequency,
      strings: settings.strings.map((s) => GuitarStringModel.fromEntity(s)).toList(),
      toleranceCents: settings.toleranceCents,
      minAmplitude: settings.minAmplitude,
    );
  }

  /// Converts to domain entity
  TuningSettings toEntity() {
    return TuningSettings(
      a4Frequency: a4Frequency,
      strings: strings.map((s) => s.toEntity()).toList(),
      toleranceCents: toleranceCents,
      minAmplitude: minAmplitude,
    );
  }

  /// Creates TuningSettingsModel from JSON
  factory TuningSettingsModel.fromJson(Map<String, dynamic> json) {
    return TuningSettingsModel(
      a4Frequency: (json['a4Frequency'] as num).toDouble(),
      strings: (json['strings'] as List)
          .map((s) => GuitarStringModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      toleranceCents: (json['toleranceCents'] as num).toDouble(),
      minAmplitude: (json['minAmplitude'] as num).toDouble(),
    );
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() {
    return {
      'a4Frequency': a4Frequency,
      'strings': strings.map((s) => s.toJson()).toList(),
      'toleranceCents': toleranceCents,
      'minAmplitude': minAmplitude,
    };
  }

  /// Creates standard tuning model
  factory TuningSettingsModel.standard({double a4Frequency = 440.0}) {
    return TuningSettingsModel.fromEntity(
      TuningSettings.standard(a4Frequency: a4Frequency),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuningSettingsModel &&
          runtimeType == other.runtimeType &&
          a4Frequency == other.a4Frequency &&
          strings == other.strings &&
          toleranceCents == other.toleranceCents &&
          minAmplitude == other.minAmplitude;

  @override
  int get hashCode =>
      a4Frequency.hashCode ^
      strings.hashCode ^
      toleranceCents.hashCode ^
      minAmplitude.hashCode;
}
