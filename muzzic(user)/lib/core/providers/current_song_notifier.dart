import 'dart:async';

import 'package:client/core/providers/playlist_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/home/models/song_model.dart';
import '../../features/home/repositories/home_local_repository.dart';

part 'current_song_notifier.g.dart';
@riverpod
class CurrentSongNotifier extends _$CurrentSongNotifier {
  late HomeLocalRepository _homeLocalRepository;
  late AudioPlayer audioPlayer;
  late StreamSubscription<PlayerState> _playerStateSub;
  bool _initialized = false;

  @override
  SongModel? build() {
    if (!_initialized) {
      _initialized = true;

      _homeLocalRepository = ref.read(homeLocalRepositoryProvider);
      audioPlayer = AudioPlayer();

      // 👇 Watch for player state and song completion
      _playerStateSub = audioPlayer.playerStateStream.listen((playState) {
        if (playState.processingState == ProcessingState.completed) {
          ref.read(playlistControllerProvider.notifier).handleSongCompletion();
        }

        if (state != null) {
          // ✅ Always create a new state copy so Riverpod triggers rebuild
          state = state!.copyWith(isPlaying: audioPlayer.playing);
        }
      });

      ref.onDispose(() {
        _playerStateSub.cancel();
        audioPlayer.dispose();
      });
    }

    return null;
  }

  /// 🔊 Play or switch to a new song
  Future<void> updateSong(SongModel song) async {
    await audioPlayer.stop();

    final audioSource = song.isDownload
        ? AudioSource.uri(
      Uri.file(song.localAudioPath!),
      tag: MediaItem(
        id: song.id,
        title: song.song_name,
        artist: song.artist,
        artUri: Uri.file(song.localThumbnailPath!),
      ),
    )
        : AudioSource.uri(
      Uri.parse(song.song_url),
      tag: MediaItem(
        id: song.id,
        title: song.song_name,
        artist: song.artist,
        artUri: Uri.parse(song.thumbnail_url),
      ),
    );

    await audioPlayer.setAudioSource(audioSource);
    await audioPlayer.play();

    // ✅ Save to local repo
    _homeLocalRepository.markAsRecentlyPlayed(song);
    _homeLocalRepository.uploadLocalSong(song);

    // ✅ Force new instance (important!)
    state = song.copyWith(isPlaying: true);
  }

  /// ▶️ Pause / Resume
  void playPause() {
    if (state == null) return;

    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }

    // ✅ Update with new reference so widget rebuilds
    state = state!.copyWith(isPlaying: audioPlayer.playing);
  }

  /// ⏩ Seek bar handler
  void seek(double val) {
    final duration = audioPlayer.duration;
    if (duration == null) return;

    audioPlayer.seek(
      Duration(milliseconds: (val * duration.inMilliseconds).toInt()),
    );
  }

  /// 👇 Helper for PlaylistController
  void setCurrentSong(SongModel song, {bool isPlaying = true}) {
    state = song.copyWith(isPlaying: isPlaying);
  }
}
