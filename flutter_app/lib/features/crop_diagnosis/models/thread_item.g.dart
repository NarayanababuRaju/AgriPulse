// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ThreadItemAdapter extends TypeAdapter<ThreadItem> {
  @override
  final int typeId = 3;

  @override
  ThreadItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ThreadItem(
      role: fields[0] as String,
      content: fields[1] as String,
      timestamp: fields[2] as DateTime,
      metadata: (fields[3] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ThreadItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.role)
      ..writeByte(1)
      ..write(obj.content)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThreadItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
