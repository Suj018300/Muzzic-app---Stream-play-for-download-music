import 'dart:io';
import 'dart:ui';
import 'package:client/core/failure/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/fav_song_model.dart';
import '../models/song_model.dart';
import '../repositories/home_local_repository.dart';
import '../repositories/home_repository.dart';
import 'home_viewmodel.dart';
part 'home_viewmodel.g.dart';

/// This is ViewModel for registering models after initializing in HomeRepository

// @riverpod
// Future<List<SongModel>> getAllSongs(Ref ref) async {
//   final token = ref.watch(currentUserNotifierProvider.select((user) => user!.token));
//   final res = await ref.watch(homeRepositoryProvider).getAllSongs(token: token);
//
//   return switch(res) {
//     Left(value: final l) => throw l.message,
//     Right(value: final r) => r,
//   };
// }


@riverpod
Future<List<SongModel>> getFavSongs(Ref ref) async {
  final token =
  ref.watch(currentUserNotifierProvider.select((user) => user!.token));
  final res = await ref.watch(homeRepositoryProvider).getFavSongs(
    token: token,
  );

  return switch (res) {
    Left(value: final l) => throw l.message,
    Right(value: final r) => r,
  };
}

@riverpod
class HomeViewmodel extends _$HomeViewmodel {
  late HomeRepository _homeRepository;
  late HomeLocalRepository _homeLocalRepository;

  @override
  AsyncValue? build() {
    _homeRepository = ref.watch(homeRepositoryProvider);
    _homeLocalRepository = ref.watch(homeLocalRepositoryProvider);
    return null;
  }

  Future<void> uploadSong({
    required File selectedAudio,
    required File selectedImage,
    required String songName,
    required String artist,
    required Color selectedColor
  }) async {
    state = const AsyncLoading();
    final res = await _homeRepository.uploadSong(
      selectedAudio: selectedAudio, 
      selectedImage: selectedImage, 
      songName: songName, 
      artist: artist, 
      hexCode: rgbToHex(selectedColor), 
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    final val = switch(res) {
      Left(value: final l) => state = AsyncError(l, StackTrace.current),
      Right(value: final r) => state = AsyncData(r),
    };
    // print(val);
  }

  Future<void> favSong({
    String? songId,
    String? userSongId,
  }) async {
    state = const AsyncLoading();
    final res = await _homeRepository.favSong(
      songId: songId,
      userSongId: userSongId,
      token: ref.read(currentUserNotifierProvider)!.token,
    );

    final val = switch(res) {
      Left(value: final l) => state = AsyncError(l, StackTrace.current),
      Right(value: final r) => _favSongsSuccess(r, (songId ?? userSongId)!),
    };
  }

  AsyncValue _favSongsSuccess(bool isFavorited, String songId) {
    final userNotifier = ref.read(currentUserNotifierProvider.notifier);
    if(isFavorited) {
      userNotifier.addUser(
        ref.read(currentUserNotifierProvider)!.copyWith(
          favorites: [
            ...ref.read(currentUserNotifierProvider)!.favorites,
            FavSongModel(id: '', song_id: songId, user_id: ''),
          ]
        )
      );
    } else {
      userNotifier.addUser(
          ref.read(currentUserNotifierProvider)!.copyWith(
              favorites: ref.read(currentUserNotifierProvider)!.favorites.where((fav) => fav.song_id!=songId,).toList()
          )
      );
    }
    ref.invalidate(getFavSongsProvider);
    return state = AsyncData(isFavorited);
  }

  List<SongModel> getRecentlyPlayedSongs() {
    return _homeLocalRepository.getRecentlyPlayedSongs();
  }
  
  Future<List<SongModel>> getSongsList() async {
    final res = await _homeRepository.getSongsList(
        token: ref.read(currentUserNotifierProvider)!.token,
    );
    return res;
  }

  Future<List<SongModel>> getAllSongs() async {
    final res = await _homeRepository.getUserSongs(
        token: ref.watch(currentUserNotifierProvider)!.token,
    );
    return res;
  }

  Future<List<SongModel>> getGlobalSongs() async {
    final res = await _homeRepository.getGlobalSongs(
        token: ref.watch(currentUserNotifierProvider)!.token,
    );
    return res;
  }

  Future<Either<AppFailure, String>> editSong({
    File? selectedAudio,
    File? selectedImage,
    required String token,
    required String id,
    String? songName,
    String? artist,
    Color? selectedColor,
  }) async {
    print('viewmodel is here');
    state = const AsyncLoading();
    try {
      final res = await _homeRepository.editSong(
          token: token,
          id: id,
          songName: songName,
          artist: artist,
          hexCode: selectedColor != null ? rgbToHex(selectedColor) : null,
          selectedAudio: selectedAudio,
          selectedImage: selectedImage
      );
      print('editSong upload complete');
      return res;
    }  catch (e, str) {
      return Left(AppFailure(e.toString()));
    }
  }

  Future<String> deleteSong({
      required String id,
    required String token,
  }) async {
    final res = await _homeRepository.deleteSong(
        id: id,
        token: token
    );
    _homeLocalRepository.deleteSongLocally(id);
    return res;
  }

  Future<String> downloadAudioRepo({
    required String audioUrl,
  }) async {
    final res = await _homeRepository.downloadAudio(
        audioUrl: audioUrl
    );
    return res;
  }

  Future<void> saveToDownloads({
    required String id,
    required String token
  }) async {
    final res = _homeRepository.saveToDownloads(
        id: id,
        token: token
    );
    return res;
  }
}
