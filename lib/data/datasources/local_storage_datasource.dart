import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/tuning_settings_model.dart';
import '../../core/error/exceptions.dart';

/// Data source for local storage operations
abstract class LocalStorageDataSource {
  Future<TuningSettingsModel> loadSettings();
  Future<void> saveSettings(TuningSettingsModel settings);
}

class LocalStorageDataSourceImpl implements LocalStorageDataSource {
  static const String _settingsFileName = 'tuning_settings.json';

  @override
  Future<TuningSettingsModel> loadSettings() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_settingsFileName');

      if (!await file.exists()) {
        // Return default settings if file doesn't exist
        return TuningSettingsModel.standard();
      }

      final jsonString = await file.readAsString();
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      return TuningSettingsModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException('Failed to load settings: ${e.toString()}');
    }
  }

  @override
  Future<void> saveSettings(TuningSettingsModel settings) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_settingsFileName');

      final jsonString = json.encode(settings.toJson());
      await file.writeAsString(jsonString);
    } catch (e) {
      throw CacheException('Failed to save settings: ${e.toString()}');
    }
  }
}
