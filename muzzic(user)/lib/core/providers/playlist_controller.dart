import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/playlist_state_model.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:math';

part 'playlist_controller.g.dart';
enum ShuffleModeType { sequential, random }
enum RepeatModeType { off, on }
enum SongSourceType { userSongs, favorites, downloads }

@riverpod
class PlaylistController extends _$PlaylistController {
  late List<int> playHistory;

  @override
  PlaylistState build() {
    playHistory = [];
    return const PlaylistState();
  }

  void loadSongs(List<SongModel> list, {SongSourceType? source}) {
    state = state.copyWith(songs: list, currentSource: source);
  }

  void clearSongs() {
    state = state.copyWith(songs: [], currentSource: null);
  }


  void playSongByIndex(int index) {
    if (state.songs.isEmpty) return;

    playHistory.add(index);

    final song = state.songs[index];
    final currentSongNotifier = ref.read(currentSongNotifierProvider.notifier);

    // ✅ Ensure the song state updates before playback
    currentSongNotifier.updateSong(song);

    state = state.copyWith(currentIndex: index);
  }

  void playNext() {
    if (state.songs.isEmpty) return;
    int nextIndex;

    if (state.repeatMode == RepeatModeType.on) {
      playSongByIndex(state.currentIndex);
      return;
    }

    if (state.shuffleMode == ShuffleModeType.random) {
      do {
        nextIndex = Random().nextInt(state.songs.length);
      } while (nextIndex == state.currentIndex && state.songs.length > 1);
    } else {
      nextIndex = (state.currentIndex + 1) % state.songs.length;
    }

    playSongByIndex(nextIndex);
    final song = state.songs[nextIndex];
    ref.read(currentSongNotifierProvider.notifier)
        .setCurrentSong(song, isPlaying: true);
  }


  void playPrevious() {
    if (state.songs.isEmpty) return;

    int preIndex;
    if (playHistory.length > 1) {
      playHistory.removeLast();
      preIndex = playHistory.last;
    } else {
      preIndex = (state.currentIndex - 1 + state.songs.length) % state.songs.length;
    }

    playSongByIndex(preIndex);

    final song = state.songs[preIndex];
    ref.read(currentSongNotifierProvider.notifier)
        .setCurrentSong(song, isPlaying: true);
  }

  void handleSongCompletion() {
    if (state.songs.isEmpty) return;

    if (ref.read(currentSongNotifierProvider)?.isPlaying == true) {
      playNext();
    }

    if (state.repeatMode == RepeatModeType.on) {
      playSongByIndex(state.currentIndex);
    } else {
      playNext();
    }
  }

  bool isCurrentSource(SongSourceType source) =>
      state.currentSource == source;

  bool isRepeat(RepeatModeType repeatModeType) =>
      state.repeatMode == repeatModeType;

  void toggleShuffle(List<SongModel> songs, SongSourceType source) {
    final currentSong = ref.read(currentSongNotifierProvider);
    final currentSongIndex = currentSong != null
        ? songs.indexWhere((s) => s.id == currentSong.id)
        : 0;

    final newMode = (state.shuffleMode == ShuffleModeType.random &&
        state.currentSource == source)
        ? ShuffleModeType.sequential
        : ShuffleModeType.random;

    state = state.copyWith(
      shuffleMode: newMode,
      songs: songs,
      currentSource: source,
      currentIndex: currentSongIndex,
    );
  }

  void toggleRepeat() {
    final newMode = state.repeatMode == RepeatModeType.off
        ? RepeatModeType.on
        : RepeatModeType.off;
    state = state.copyWith(repeatMode: newMode);
  }
}
