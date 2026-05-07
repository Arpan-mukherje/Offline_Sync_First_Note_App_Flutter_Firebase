// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_queue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 1;

  @override
  SyncQueueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncQueueItem(
      idempotencyKey: fields[0] as String,
      action: fields[1] as String,
      payload: (fields[2] as Map).cast<String, dynamic>(),
      retryCount: fields[3] as int,
      createdAt: fields[4] as DateTime,
      lastAttemptAt: fields[5] as DateTime?,
      isProcessing: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.idempotencyKey)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.payload)
      ..writeByte(3)
      ..write(obj.retryCount)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.lastAttemptAt)
      ..writeByte(6)
      ..write(obj.isProcessing);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncQueueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
