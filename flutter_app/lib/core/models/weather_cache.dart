import 'package:hive/hive.dart';

class WeatherCache {
  final String locationKey; // e.g., "lat_lon"
  final String jsonData;
  final DateTime cachedAt;

  WeatherCache({
    required this.locationKey,
    required this.jsonData,
    required this.cachedAt,
  });

  bool get isStale {
    return DateTime.now().difference(cachedAt).inHours > 4;
  }
}

class WeatherCacheAdapter extends TypeAdapter<WeatherCache> {
  @override
  final int typeId = 1;

  @override
  WeatherCache read(BinaryReader reader) {
    return WeatherCache(
      locationKey: reader.readString(),
      jsonData: reader.readString(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, WeatherCache obj) {
    writer.writeString(obj.locationKey);
    writer.writeString(obj.jsonData);
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
  }
}
