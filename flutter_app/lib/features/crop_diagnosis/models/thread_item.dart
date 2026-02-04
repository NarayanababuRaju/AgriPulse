import 'package:hive/hive.dart';

part 'thread_item.g.dart';

@HiveType(typeId: 3) // Using typeId 3 to avoid conflict with YieldRecord(2)
class ThreadItem {
  @HiveField(0)
  final String role; // 'user' or 'ai'

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final Map<String, dynamic>? metadata;

  ThreadItem({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory ThreadItem.fromMap(Map<String, dynamic> map) {
    return ThreadItem(
      role: map['role'] ?? 'unknown',
      content: map['content'] ?? '',
      timestamp: DateTime.parse(map['timestamp']),
      metadata: map['metadata'],
    );
  }
}
