// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusLogAdapter extends TypeAdapter<FocusLog> {
  @override
  final int typeId = 0;

  @override
  FocusLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusLog(
      taskNote: fields[0] as String,
      durationMinutes: fields[1] as int,
      timestamp: fields[2] as DateTime,
      isStarred: fields[3] == null ? false : fields[3] as bool,
      moodScore: fields[4] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, FocusLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.taskNote)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.isStarred)
      ..writeByte(4)
      ..write(obj.moodScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
