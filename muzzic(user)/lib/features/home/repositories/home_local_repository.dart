import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/song_model.dart';

part 'home_local_repository.g.dart';


@riverpod
HomeLocalRepository homeLocalRepository(Ref ref) {
  return HomeLocalRepository();
}

class HomeLocalRepository {
  final Box box = Hive.box('songs');
  final Box recentlyPlayedBox = Hive.box('recentlyPlayed');

  void uploadLocalSong(SongModel song) {
    final data = song.toMap();
    if (!box.containsKey(song.id)) {
      data['lastPlayed'] = null;
    }
    box.put(song.id, jsonEncode(data));
  }

  List<SongModel> loadSongs() {
    List<SongModel> songs = [];
    for (final key in box.keys) {
      final raw = box.get(key) as String;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      songs.add(SongModel.fromMap(map));
    }
    return songs;
  }

  void deleteSongLocally(String id) {
    box.delete(id); // removes by key (id should be key)
    List<String> ids = recentlyPlayedBox.get('ids', defaultValue: []).cast<String>();
    ids.remove(id);
    recentlyPlayedBox.put('ids', ids);
  }

  void markAsRecentlyPlayed(SongModel song) {
    List<String> ids = recentlyPlayedBox.get('ids', defaultValue: []).cast<String>();
    ids.remove(song.id);
    ids.insert(0, song.id);
    if (ids.length > 20) ids = ids.sublist(0, 20);
    recentlyPlayedBox.put('ids', ids);

    final updatedMap = song.toMap();
    updatedMap['lastPlayed'] = DateTime.now().toIso8601String();
    box.put(song.id, jsonEncode(updatedMap));
  }

  List<SongModel> getRecentlyPlayedSongs() {
    final ids = recentlyPlayedBox.get('ids', defaultValue: []).cast<String>();
    final List<SongModel> songs = [];

    for (final id in ids) {
      final raw = box.get(id);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        songs.add(SongModel.fromMap(map));
      }
    }
    return songs;
  }
}