// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resources_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ResourceAdapter extends TypeAdapter<Resource> {
  @override
  final int typeId = 1;

  @override
  Resource read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Resource()
      ..secret = fields[0] as String
      ..resource = fields[1] as String;
  }

  @override
  void write(BinaryWriter writer, Resource obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.secret)
      ..writeByte(1)
      ..write(obj.resource);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResourceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
