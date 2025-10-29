import 'dart:io';

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';

import '../../../../core/AppSnakBar.dart';

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final playlistState = ref.watch(playlistControllerProvider);
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    final userFavorites = ref.watch(currentUserNotifierProvider.select((data) => data!.favorites));
    ref.watch(playlistControllerProvider);
    final allFavSongs = ref.watch(getFavSongsProvider);

    if (currentSong == null) {
      return const SizedBox.shrink();
    }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                hexToRgb(currentSong.hex_code),
                const Color(0xff121212),
              ],
            )
          ),
          child: Scaffold(
            backgroundColor: Pallete.transparentColor,
            appBar: AppBar(
              backgroundColor: Pallete.transparentColor,
              leading: Transform.translate(
                offset: const Offset(-15, 0),
                child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: IconButton(
                      focusColor: Pallete.transparentColor,
                      highlightColor: Pallete.transparentColor,
                      splashColor: Pallete.transparentColor,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Pallete.whiteColor,
                        size: 40,
                        )
                    ),
                  ),
                ),
                ),
            body: Column(
              children: [
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Hero(
                      tag: 'image-tag',
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: currentSong.localThumbnailPath != null
                                ? FileImage(File(currentSong.localThumbnailPath!)) as ImageProvider
                                : NetworkImage(currentSong.thumbnail_url),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 32,
                                      child: Marquee(
                                        text: currentSong.song_name,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Pallete.whiteColor,
                                        ),
                                        blankSpace: 150,
                                        velocity: 20,
                                        pauseAfterRound: const Duration(seconds: 3),
                                        startAfter: const Duration(seconds: 3),
                                        fadingEdgeStartFraction: 0.1,
                                        fadingEdgeEndFraction: 0.1,
                                      ),
                                    ),
                                    Text(
                                      currentSong.artist,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Pallete.whiteColor,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () async {
                                  final isGlobal = currentSong.isGlobal;
                                  await ref.read(homeViewmodelProvider.notifier).favSong(
                                    songId: isGlobal ? currentSong.id : null,
                                    userSongId: isGlobal ? null : currentSong.id,
                                  );
                                },
                                icon: Icon(
                                    (
                                        currentSong.isGlobal
                                      ? userFavorites.any((fav) => fav.song_id == currentSong.id)
                                      : userFavorites.any((fav) => fav.user_song_id == currentSong.id)
                                    )
                                      ? Icons.favorite
                                      : Icons.favorite_border_rounded,
                                  color: Pallete.whiteColor,
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20,),
                      StreamBuilder(
                        stream: songNotifier.audioPlayer.positionStream,
                        builder: (context, asyncSnapshot) {
                          if(asyncSnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox();
                          }

                          final position = asyncSnapshot.data;
                          final duration = songNotifier.audioPlayer.duration;
                          double sliderValue = 0.0;

                          if (position != null && duration != null && duration.inMilliseconds > 0) {
                            sliderValue = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
                          }
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Pallete.whiteColor,
                                  inactiveTrackColor: Pallete.whiteColor.withValues(alpha: 0.117),
                                  thumbColor: Pallete.whiteColor,
                                  trackHeight: 4,
                                  overlayShape: SliderComponentShape.noOverlay
                                ),
                                child: Slider(
                                  value: sliderValue,
                                  min: 0,
                                  max: 1,
                                  onChanged: (val) {
                                    sliderValue = val;
                                  },
                                  onChangeEnd: songNotifier.seek,
                                )
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${position?.inMinutes ?? 0}:${((position?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w300,
                                      color: Pallete.subtitleText,
                                    ),
                                  ),
                                  Text(
                                    '${duration?.inMinutes ?? 0}:${((duration?.inSeconds ?? 0) % 60).toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w300,
                                      color: Pallete.subtitleText,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          );
                        }
                      ),

                      const SizedBox(height: 30,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {
                              final song = allFavSongs.valueOrNull ?? [];
                              if (song.isNotEmpty) {
                                playlistCtrl.loadSongs(song, source: SongSourceType.favorites);
                                playlistCtrl.toggleShuffle(
                                    song,
                                    SongSourceType.favorites
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.shuffle_rounded,
                            ),
                            iconSize: 36,
                            color:
                            playlistState.shuffleMode == ShuffleModeType.random
                                  ? Pallete.gradient2
                                  : Pallete.whiteColor,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: playlistCtrl.playPrevious,
                            icon: const Icon(Icons.skip_previous_rounded),
                            iconSize: 52,
                            color: Pallete.whiteColor,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed:() {
                              /// Well Done, keep it up and clear all bugs
                              final current = ref.watch(currentSongNotifierProvider);
                              if (current != null) {
                                ref.read(currentSongNotifierProvider.notifier).playPause();
                              }
                            },
                            icon:AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Icon(
                                (currentSong.isPlaying ?? false)
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                key: ValueKey(currentSong.isPlaying ?? false),
                                size: 56,
                                color: Colors.white,
                              ),
                            ),
                            iconSize: 60,
                            color: Pallete.whiteColor,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: () async {
                              final song = allFavSongs.valueOrNull ?? [];
                              if (song.isNotEmpty) {
                                playlistCtrl.loadSongs(song, source: SongSourceType.favorites);;
                                playlistCtrl.playNext();
                              }
                            },
                            icon: const Icon(Icons.skip_next_rounded),
                            iconSize: 52,
                            color: Pallete.whiteColor,
                            // constraints: BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            onPressed: playlistCtrl.toggleRepeat,
                            icon: const Icon(
                              Icons.replay,
                            ),
                            iconSize: 36,
                            color: playlistState.repeatMode == RepeatModeType.on
                                 ? Pallete.gradient2
                                 : Pallete.whiteColor,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20,),
                      const Column(
                        children: [
                          Center(
                            child: Text(
                              "This music player page's shuffle button will play the songs from favorite songs list",
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}