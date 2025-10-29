import 'dart:io';

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/features/home/viewmodel/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marquee/marquee.dart';

class MusicPlayer extends ConsumerWidget {
  const MusicPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final userFavorites = ref.watch(currentUserNotifierProvider.select((data) => data!.favorites));


    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            hexToRgb(currentSong!.hex_code),
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
                            ? FileImage(File(currentSong.localThumbnailPath!))
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
                                    blankSpace: 40,
                                    velocity: 30,
                                    pauseAfterRound: const Duration(seconds: 2),
                                    startAfter: const Duration(seconds: 2),
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
                          // IconButton(
                          //   onPressed: () async {
                          //     await ref.watch(homeViewmodelProvider.notifier).favSong(songId: currentSong.id);
                          //   },
                          //   icon: Icon(
                          //     userFavorites.where((fav) => fav.song_id== currentSong.id).toList().isNotEmpty
                          //         ? Icons.favorite
                          //         : Icons.favorite_border_rounded,
                          //     color: Pallete.whiteColor,
                          //   )
                          // ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20,),
                  StreamBuilder(
                    stream: songNotifier.audioPlayer!.positionStream,
                    builder: (context, asyncSnapshot) {
                      if(asyncSnapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox();
                      }

                      final position = asyncSnapshot.data;
                      final duration = songNotifier.audioPlayer!.duration;
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
                                '${position?.inMinutes ?? 0 }:${(position?.inSeconds ?? 0) % 60}'.padLeft(2, '0'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: Pallete.subtitleText,
                                ),
                              ),
                              Text(
                                '${duration?.inMinutes ?? 0 }:${(duration?.inSeconds ?? 0) % 60}'.padLeft(2, '0') ,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.shuffle_rounded),
                        iconSize: 23,
                        color: Pallete.whiteColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.skip_previous_rounded),
                        iconSize: 52,
                        color: Pallete.whiteColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: songNotifier.playPause,
                        icon: Icon(
                          songNotifier.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill,
                          ),
                        iconSize: 80,
                        color: Pallete.whiteColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 52,
                        color: Pallete.whiteColor,
                        // constraints: BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        onPressed: songNotifier.loop,
                        icon: Icon(
                          songNotifier.loopT
                              ? Icons.replay
                          : Icons.replay_circle_filled_rounded,
                        ),
                        iconSize: 23,
                        color: Pallete.whiteColor,
                        visualDensity: VisualDensity.compact,
                      ),
                      // Padding(
                      //   padding: EdgeInsets.all(10),
                      //   child: Image.asset(
                      //     'assets/images/repeat.png',
                      //     color: Pallete.whiteColor,
                      //   ),
                      // ),
                    ],
                  ),
                  // const SizedBox(height: 20),
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.all(10),
                  //       child: Image.asset(
                  //         'assets/images/connect-device.png',
                  //         color: Pallete.whiteColor,
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.all(10),
                  //       child: Image.asset(
                  //         'assets/images/playlist.png',
                  //         color: Pallete.whiteColor,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}