import 'package:client/core/providers/playlist_controller.dart';

import '../../features/home/models/song_model.dart';

class PlaylistState {
  final List<SongModel> songs;
  final int currentIndex;
  final ShuffleModeType shuffleMode;
  final RepeatModeType repeatMode;
  final SongSourceType? currentSource;

  const PlaylistState({
    this.songs = const [],
    this.currentIndex = 0,
    this.shuffleMode = ShuffleModeType.sequential,
    this.repeatMode = RepeatModeType.off,
    this.currentSource,
  });

  PlaylistState copyWith({
    List<SongModel>? songs,
    int? currentIndex,
    ShuffleModeType? shuffleMode,
    RepeatModeType? repeatMode,
    SongSourceType? currentSource,
  }) {
    return PlaylistState(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      repeatMode: repeatMode ?? this.repeatMode,
      currentSource: currentSource ?? this.currentSource,
    );
  }
}
