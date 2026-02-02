import 'package:hive/hive.dart';

class YieldRecord {
  final String id;
  final String cropName;
  final String fieldName;
  final double expectedYield;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> rawAiResponse;

  YieldRecord({
    required this.id,
    required this.cropName,
    required this.fieldName,
    required this.expectedYield,
    required this.confidence,
    required this.timestamp,
    required this.rawAiResponse,
  });
}

class YieldRecordAdapter extends TypeAdapter<YieldRecord> {
  @override
  final int typeId = 2; // Unique from DiagnosisRecord (0) and WeatherCache (1)

  /// Recursively converts a dynamic map (including LinkedMap) to Map<String, dynamic>
  Map<String, dynamic> _deepConvertMap(dynamic input) {
    if (input == null) return {};
    if (input is! Map) return {};
    
    final Map<String, dynamic> result = {};
    for (final entry in input.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      
      if (value is Map) {
        result[key] = _deepConvertMap(value);
      } else if (value is List) {
        result[key] = _deepConvertList(value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  /// Recursively converts a list, handling nested maps
  List<dynamic> _deepConvertList(List<dynamic> input) {
    return input.map((item) {
      if (item is Map) {
        return _deepConvertMap(item);
      } else if (item is List) {
        return _deepConvertList(item);
      }
      return item;
    }).toList();
  }

  @override
  YieldRecord read(BinaryReader reader) {
    final id = reader.readString();
    final cropName = reader.readString();
    final fieldName = reader.readString();
    final expectedYield = reader.readDouble();
    final confidence = reader.readDouble();
    final timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    
    // Backward compatibility for old records without rawAiResponse
    Map<String, dynamic> rawAiResponse = {};
    try {
      // Hive BinaryReader will throw an error if it hits the end of the entry's byte stream
      final map = reader.readMap();
      // Use deep conversion to handle nested LinkedMaps from Hive
      rawAiResponse = _deepConvertMap(map);
    } catch (e) {
      // If we reach here, it's likely an old record. We return an empty map.
      // The YieldDetailsScreen already handles empty maps gracefully.
    }

    return YieldRecord(
      id: id,
      cropName: cropName,
      fieldName: fieldName,
      expectedYield: expectedYield,
      confidence: confidence,
      timestamp: timestamp,
      rawAiResponse: rawAiResponse,
    );
  }

  @override
  void write(BinaryWriter writer, YieldRecord obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.cropName);
    writer.writeString(obj.fieldName);
    writer.writeDouble(obj.expectedYield);
    writer.writeDouble(obj.confidence);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeMap(obj.rawAiResponse);
  }
}
