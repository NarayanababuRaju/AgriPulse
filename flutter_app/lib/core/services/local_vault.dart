import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../constants/hive_constants.dart';
import '../../features/crop_diagnosis/models/diagnosis_record.dart';
import '../../features/yield_prediction/models/yield_record.dart';
import '../../features/profile/domain/entities/field.dart';
import '../models/weather_cache.dart';
import '../api/path_enforcer.dart';

class LocalVault {
  static final LocalVault _instance = LocalVault._internal();
  factory LocalVault() => _instance;
  LocalVault._internal();

  late Box<DiagnosisRecord> _diagnosisBox;
  late Box<YieldRecord> _yieldBox;
  late Box<WeatherCache> _weatherBox;
  late Box _settingsBox;

  Future<void> init() async {
    try {
      debugPrint("📦 LocalVault: Opening Diagnosis Box...");
      _diagnosisBox = await Hive.openBox<DiagnosisRecord>(HiveConstants.diagnosisHistoryBox);
      
      debugPrint("📦 LocalVault: Opening Harvest Box...");
      _yieldBox = await Hive.openBox<YieldRecord>(HiveConstants.yieldHistoryBox);
      
      debugPrint("📦 LocalVault: Opening Weather Box...");
      _weatherBox = await Hive.openBox<WeatherCache>(HiveConstants.weatherCacheBox);
      
      debugPrint("📦 LocalVault: Opening Settings Box...");
      _settingsBox = await Hive.openBox(HiveConstants.settingsBox);
      
      debugPrint("✅ LocalVault initialized successfully.");
    } catch (e) {
      debugPrint("❌ Failed to initialize LocalVault: $e");
      // Fallback: Delete corrupted boxes and try again
      try {
          debugPrint("♻️ LocalVault: Attempting to clear corrupted boxes...");
          await Hive.deleteBoxFromDisk(HiveConstants.diagnosisHistoryBox);
          await Hive.deleteBoxFromDisk(HiveConstants.yieldHistoryBox);
          await Hive.deleteBoxFromDisk(HiveConstants.weatherCacheBox);
          await Hive.deleteBoxFromDisk(HiveConstants.settingsBox);
          
          _diagnosisBox = await Hive.openBox<DiagnosisRecord>(HiveConstants.diagnosisHistoryBox);
          _yieldBox = await Hive.openBox<YieldRecord>(HiveConstants.yieldHistoryBox);
          _weatherBox = await Hive.openBox<WeatherCache>(HiveConstants.weatherCacheBox);
          _settingsBox = await Hive.openBox(HiveConstants.settingsBox);
          debugPrint("✅ LocalVault: Recovery successful. Containers reset.");
      } catch (innerError) {
          debugPrint("💀 LocalVault: Recovery failed: $innerError");
          // Last resort: initialize empty boxes manually if possible, though openBox should handle it
      }
    }
  }

  // --- Diagnosis Operations (Hierarchical) ---
  
  Future<void> saveDiagnosis(DiagnosisRecord record, {required String userId, required String fieldId, required String cycleId}) async {
    final key = PathEnforcer.localCompositeKey(
      userId: userId,
      fieldId: fieldId, 
      cycleId: cycleId, 
      activityId: record.id
    );
    await _diagnosisBox.put(key, record);
    debugPrint("💾 (H) Saved Diagnosis with key: $key");
  }

  List<DiagnosisRecord> getHistory({required String userId, String? fieldId, String? cycleId}) {
    try {
      final allValues = _diagnosisBox.values.toList();
      debugPrint("📦 LocalVault: Reading diagnosis history for $userId. Total box entries: ${allValues.length}");
      
      // If no context provided, return all for this user
      if (fieldId == null || cycleId == null) {
        return _diagnosisBox.toMap().entries
            .where((e) => e.key.toString().startsWith('${userId}_'))
            .map((e) => e.value)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      debugPrint("🔍 LocalVault: Filtering for context: ${userId}_${fieldId}_$cycleId");
      
      // Prefix Filtering for specific Plot/Season and User
      final filtered = _diagnosisBox.toMap().entries
          .where((e) => PathEnforcer.matchesContext(e.key.toString(), userId, fieldId, cycleId))
          .map((e) => e.value)
          .toList();
      
      debugPrint("✅ LocalVault: Found ${filtered.length} matching records.");
      
      return filtered..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("❌ Error reading hierarchical diagnosis history: $e");
      return [];
    }
  }

  /// Re-home unassigned legacy data to a specific field/cycle
  Future<void> rehomeRecord(String oldKey, {required String userId, required String fieldId, required String cycleId}) async {
    final record = _diagnosisBox.get(oldKey);
    if (record != null) {
      await saveDiagnosis(record, userId: userId, fieldId: fieldId, cycleId: cycleId);
      await _diagnosisBox.delete(oldKey);
      debugPrint("🚚 Re-homed record $oldKey to $userId/$fieldId/$cycleId");
    }
  }

  /// Delete a specific diagnosis record
  Future<void> deleteDiagnosisRecord(String key) async {
    await _diagnosisBox.delete(key);
    debugPrint("🗑️ LocalVault: Deleted Diagnosis record with key: $key");
  }

  // --- Yield Operations (Hierarchical) ---

  Future<void> saveYield(YieldRecord record, {required String userId, required String fieldId, required String cycleId}) async {
    final key = PathEnforcer.localCompositeKey(
      userId: userId,
      fieldId: fieldId, 
      cycleId: cycleId, 
      activityId: record.id
    );
    await _yieldBox.put(key, record);
    debugPrint("💾 (H) Saved Yield Prediction with key: $key");
  }

  List<YieldRecord> getYieldHistory({required String userId, String? fieldId, String? cycleId}) {
    try {
      
      if (fieldId == null || cycleId == null) {
        return _yieldBox.toMap().entries
            .where((e) => e.key.toString().startsWith('${userId}_'))
            .map((e) => e.value)
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }

      return _yieldBox.toMap().entries
          .where((e) => PathEnforcer.matchesContext(e.key.toString(), userId, fieldId, cycleId))
          .map((e) => e.value)
          .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("❌ Error reading hierarchical yield history: $e");
      return [];
    }
  }

  /// Delete a specific yield record
  Future<void> deleteYieldRecord(String key) async {
    await _yieldBox.delete(key);
    debugPrint("🗑️ LocalVault: Deleted Yield record with key: $key");
  }

  // --- Settings & User Session ---

  Future<void> saveUser(Map<String, dynamic> userData) async {
    await _settingsBox.put('current_user', userData);
    debugPrint("💾 Application Saved User Session: ${userData['id']}");
  }

  Map<String, dynamic>? getUser() {
    final data = _settingsBox.get('current_user');
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }

  Future<void> clearUser() async {
    await _settingsBox.delete('current_user');
    debugPrint("🗑️ User Session Cleared.");
  }

  // --- Language Preference ---

  Future<void> saveLanguage(String languageCode) async {
    await _settingsBox.put('selected_language', languageCode);
    debugPrint("💾 Language preference saved: $languageCode");
  }

  String? getSavedLanguage() {
    return _settingsBox.get('selected_language');
  }

  // --- Field Operations (Scoped by User) ---

  Future<void> saveFields(String userId, List<Field> fields) async {
    await _settingsBox.put('fields_$userId', fields.map((f) => f.toJson()).toList());
    debugPrint("💾 LocalVault: Saved ${fields.length} fields for user $userId");
  }

  List<Field> getFields(String userId) {
    final data = _settingsBox.get('fields_$userId');
    if (data == null) {
      debugPrint("📦 LocalVault: No fields found for user $userId");
      return [];
    }
    final rawList = List<dynamic>.from(data);
    return rawList.map((f) => Field.fromJson(Map<String, dynamic>.from(f))).toList();
  }

  Future<void> saveSelectedFieldId(String userId, String fieldId) async {
    await _settingsBox.put('selected_id_$userId', fieldId);
  }

  String? getSelectedFieldId(String userId) {
    return _settingsBox.get('selected_id_$userId');
  }

  // --- Weather Operations ---

  Future<void> cacheWeather(String locationKey, String jsonData) async {
    final cache = WeatherCache(
      locationKey: locationKey, 
      jsonData: jsonData, 
      cachedAt: DateTime.now()
    );
    await _weatherBox.put(locationKey, cache);
    debugPrint("💾 Application Cached Weather for $locationKey");
  }

  WeatherCache? getCachedWeather(String locationKey) {
    return _weatherBox.get(locationKey);
  }

  Future<void> clearHistory({required String userId, required String fieldId, required String cycleId}) async {
    try {
      debugPrint("🗑️ LocalVault: Clearing history for context: ${userId}_${fieldId}_$cycleId");
      
      // Clear Diagnosis
      final diagnosisKeysToDelete = _diagnosisBox.keys
          .where((k) => PathEnforcer.matchesContext(k.toString(), userId, fieldId, cycleId))
          .toList();
      await _diagnosisBox.deleteAll(diagnosisKeysToDelete);
      debugPrint("Deleted ${diagnosisKeysToDelete.length} diagnosis records.");

      // Clear Yield
      final yieldKeysToDelete = _yieldBox.keys
          .where((k) => PathEnforcer.matchesContext(k.toString(), userId, fieldId, cycleId))
          .toList();
      await _yieldBox.deleteAll(yieldKeysToDelete);
      debugPrint("Deleted ${yieldKeysToDelete.length} yield records.");
      
    } catch (e) {
      debugPrint("❌ Error clearing history: $e");
    }
  }

}
