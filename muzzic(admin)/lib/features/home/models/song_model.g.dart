// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongModelAdapter extends TypeAdapter<SongModel> {
  @override
  final int typeId = 0;

  @override
  SongModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SongModel(
      id: fields[0] as String,
      song_name: fields[1] as String,
      artist: fields[2] as String,
      thumbnail_url: fields[3] as String,
      song_url: fields[4] as String,
      hex_code: fields[5] as String,
      create_at: fields[6] as DateTime?,
      localAudioPath: fields[7] as String?,
      localThumbnailPath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SongModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.song_name)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.thumbnail_url)
      ..writeByte(4)
      ..write(obj.song_url)
      ..writeByte(5)
      ..write(obj.hex_code)
      ..writeByte(6)
      ..write(obj.create_at)
      ..writeByte(7)
      ..write(obj.localAudioPath)
      ..writeByte(8)
      ..write(obj.localThumbnailPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
