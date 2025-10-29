// ignore_for_file: non_constant_identifier_names
import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';

part 'song_model.g.dart';

@HiveType(typeId: 0)
class SongModel {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  String song_name;
  
  @HiveField(2)
  String artist;
  
  @HiveField(3)
  String thumbnail_url;
  
  @HiveField(4)
  String song_url;
  
  @HiveField(5)
  String hex_code;

  @HiveField(6)
  bool isGlobal;

  @HiveField(7)
  final DateTime? create_at;
  
  final DateTime? lastPlayed;
  
  @HiveField(8)
  final String? localAudioPath;
  
  @HiveField(9)
  final String? localThumbnailPath;

  @HiveField(10)
  bool isPlaying;

  bool get isDownload =>
      localAudioPath != null &&
          localThumbnailPath != null &&
          File(localAudioPath!).existsSync() &&
          File(localThumbnailPath!).existsSync();


  SongModel({
    required this.id,
    required this.song_name,
    required this.artist,
    required this.thumbnail_url,
    required this.song_url,
    required this.hex_code,
    required this.isGlobal,
    required this.isPlaying,
    this.create_at,
    this.lastPlayed,
    this.localAudioPath,
    this.localThumbnailPath,
  });

  SongModel copyWith({
    String? id,
    String? song_name,
    String? artist,
    String? thumbnail_url,
    String? song_url,
    String? hex_code,
    DateTime? create_at,
    DateTime? lastPlayed,
    bool? isGlobal,
    bool? isPlaying,
    // String? localAudioPath,
    // String? localThumbnailPath
  }) {
    return SongModel(
      id: id ?? this.id,
      song_name: song_name ?? this.song_name,
      artist: artist ?? this.artist,
      thumbnail_url: thumbnail_url ?? this.thumbnail_url,
      song_url: song_url ?? this.song_url,
      hex_code: hex_code ?? this.hex_code,
      create_at: create_at ?? this.create_at,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      isGlobal: isGlobal ?? this.isGlobal,
      isPlaying: isPlaying ?? this.isPlaying
      // localAudioPath: localAudioPath ?? this.localAudioPath,
      // localThumbnailPath: localThumbnailPath ?? this.localThumbnailPath
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'song_name': song_name,
      'artist': artist,
      'thumbnail_url': thumbnail_url,
      'song_url': song_url,
      'hex_code': hex_code,
      'create_at': create_at?.toIso8601String(),
      'lastPlayed': lastPlayed?.toIso8601String(),
      'isGlobal': isGlobal
      // 'localAudioPath': localAudioPath,
      // 'localThumbnailPath': localThumbnailPath
    };
  }

  factory SongModel.fromMap(Map<String, dynamic> map, {bool isGlobal = false, bool isPlaying = false}) {
    return SongModel(
      id: map['id'] ?? '',
      song_name: map['song_name'] ?? '',
      artist: map['artist'] ?? "",
      thumbnail_url: map['thumbnail_url'] ?? '',
      song_url: map['song_url'] ?? '',
      hex_code: map['hex_code'] ?? '',
      create_at: map['create_at'] != null
          ? DateTime.parse(map['create_at'])
          : null,
      lastPlayed: map['lastPlayed'] != null
          ? DateTime.parse(map['lastPlayed'])
          : null,
      isGlobal: isGlobal,
      isPlaying: isPlaying,
      // localAudioPath: map['']
    );
  }

  String toJson() => json.encode(toMap());

  factory SongModel.fromJsonString(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return SongModel.fromMap(map);
  }

  @override
  String toString() {
    return 'SongModels('
        'id: $id, '
        'song_name: $song_name, '
        'artist: $artist, '
        'thumbnail_url: $thumbnail_url, '
        'song_url: $song_url, '
        'hex_code: $hex_code, '
        'create_at: $create_at, '
        'lastPlayed: $lastPlayed'
    'isGlobal: $isGlobal'
        ')';
  }

  @override
  bool operator ==(covariant SongModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.id == id &&
      other.song_name == song_name &&
      other.artist == artist &&
      other.thumbnail_url == thumbnail_url &&
      other.song_url == song_url &&
      other.hex_code == hex_code &&
      other.create_at == create_at &&
    other.lastPlayed == lastPlayed &&
    other.isGlobal == isGlobal;
  }

  @override
  int get hashCode {
    return id.hashCode ^
    song_name.hashCode ^
    artist.hashCode ^
    thumbnail_url.hashCode ^
    song_url.hashCode ^
    hex_code.hashCode ^
    create_at.hashCode ^
    lastPlayed.hashCode ^
    isGlobal.hashCode;
  }
}
