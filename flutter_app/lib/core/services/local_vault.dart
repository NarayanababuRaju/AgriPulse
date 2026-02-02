import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../constants/hive_constants.dart';
import '../../features/crop_diagnosis/models/diagnosis_record.dart';
import '../../features/yield_prediction/models/yield_record.dart';
import '../models/weather_cache.dart';

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
      
      // Inject Demo Data (One-time check logic inside)
      debugPrint("🚀 LocalVault: Checking Demo Data...");
      await populateDemoData();
      
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

  // --- Diagnosis Operations ---
  
  Future<void> saveDiagnosis(DiagnosisRecord record) async {
    await _diagnosisBox.put(record.id, record);
    debugPrint("💾 Application Saved Diagnosis: ${record.id}");
  }

  List<DiagnosisRecord> getHistory() {
    try {
      return _diagnosisBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("❌ Error reading diagnosis history: $e");
      return [];
    }
  }

  // --- Yield Operations ---

  Future<void> saveYield(YieldRecord record) async {
    await _yieldBox.put(record.id, record);
    debugPrint("💾 Application Saved Yield Prediction: ${record.id}");
  }

  List<YieldRecord> getYieldHistory() {
    try {
      return _yieldBox.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      debugPrint("❌ Error reading yield history: $e");
      return [];
    }
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

  // --- Demo Data Injection ---

  Future<void> populateDemoData() async {
    if (_diagnosisBox.isNotEmpty) return; // Only populate if empty

    debugPrint("🚀 Injecting Demo Data for Hackathon...");

    final demoRecords = [
      DiagnosisRecord(
        id: "demo_1",
        imagePath: "assets/images/onion_datasets/Healthy leaves/100_jpg.rf.3074e710a4f19cc2252c0c83ec3bd651.jpg", 
        diseaseName: "Healthy Onion",
        confidence: 0.98,
        treatmentSummary: "Crop is in excellent condition. Continue current irrigation schedule.",
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        farmerInput: "Checking daily health. No visible spots.",
        refinementReasoning: "Visual assessment confirms healthy green tissue with no discoloration or lesions.",
        treatmentAdjustment: null, 
      ),
      DiagnosisRecord(
        id: "demo_2",
        imagePath: "assets/images/onion_datasets/Purple blotch/dr_0_1204.jpg",
        diseaseName: "Purple Blotch",
        confidence: 0.92,
        treatmentSummary: "Apply Mancozeb 75% WP @ 2g/liter. Avoid overhead irrigation.",
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        farmerInput: "Spots appeared after heavy rain last week. Worried about spread.",
        refinementReasoning: "High humidity reported by farmer correlates with purple blotch fungal sporulation.",
        treatmentAdjustment: "Added emphasis on avoiding overhead irrigation due to farmer's report of recent rain.",
      ),
    ];

    for (var record in demoRecords) {
      await _diagnosisBox.put(record.id, record);
    }
    
    debugPrint("✅ Demo Data Injected: ${demoRecords.length} records.");
  }
}
