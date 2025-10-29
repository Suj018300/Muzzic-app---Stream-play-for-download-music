import 'dart:io';

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/AppSnakBar.dart';
import '../../viewmodel/home_viewmodel.dart';
import 'music_player.dart';

class MusicSlab extends ConsumerWidget {
  const MusicSlab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final songNotifier = ref.read(currentSongNotifierProvider.notifier);
    final userFavorites = ref.watch(currentUserNotifierProvider.select((data) => data!.favorites));
    // bool fav = currentSong.isGlobal;

    if (currentSong == null) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap:() {
        Navigator.of(context).push(PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return const MusicPlayer();
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(begin: const Offset(0, 1),end: Offset.zero).chain(
              CurveTween(curve: Curves.easeIn),
            );

            final offSetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offSetAnimation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        ),
        );
      },
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 66,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: hexToRgb(currentSong.hex_code),
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'image-tag',
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          image: DecorationImage(
                            image: currentSong.localThumbnailPath != null
                                ? FileImage(File(currentSong.localThumbnailPath!)) as ImageProvider
                                : NetworkImage(
                              currentSong.thumbnail_url,
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8,),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(currentSong.song_name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500
                        ),
                        ),
                        Text(currentSong.artist,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Pallete.subtitleText,
                        ),
                        ),
                      ],
                    )
                  ],
                ),
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      currentSong.isDownload ? const SizedBox() : IconButton(
                        onPressed: () async {
                          final isGlobal = currentSong.isGlobal;
                          await ref.watch(homeViewmodelProvider.notifier).favSong(
                            songId: isGlobal ? currentSong.id : null,
                            userSongId: isGlobal ? null : currentSong.id,
                          );
                          final isNowFav = ref.read(currentUserNotifierProvider)!
                              .favorites
                              .any((fav) =>
                          fav.song_id == currentSong.id ||
                              fav.user_song_id == currentSong.id);

                          AppSnackBar.show(
                            context,
                            message: isNowFav
                                ? 'Added to Favorites ❤️'
                                : 'Removed from Favorites 💔',
                            backgroundColor: isNowFav
                                ? Colors.green.shade600
                                : Colors.red.shade700,
                            icon: Icons.favorite_rounded,
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
                      const SizedBox(width: 2,),
                      IconButton(
                        onPressed: () {
                          final current = ref.watch(currentSongNotifierProvider);
                          if (current != null) {
                            ref.read(currentSongNotifierProvider.notifier).playPause();
                          }
                        },
                        icon: Icon(
                          currentSong.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow_rounded,
                          color: Pallete.whiteColor,
                          )
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          StreamBuilder(
            stream: songNotifier.audioPlayer.positionStream,
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox();
              }

              final position = asyncSnapshot.data;
              final duration = songNotifier.audioPlayer!.duration;
              double sliderValue = 0.0;

              if (position != null && duration != null) {
                sliderValue = position.inMilliseconds / duration.inMilliseconds;
              }
              return Positioned(
                bottom: 0,
                left: 8,
                child: Container(
                  height: 2,
                  width: sliderValue * (MediaQuery.of(context).size.width - 16),
                  decoration: BoxDecoration(
                    color: Pallete.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              );
            }
          ),

          Positioned(
            bottom: 0,
            left: 8,
            child: Container(
              height: 2,
              width: MediaQuery.of(context).size.width - 16,
              decoration: BoxDecoration(
                color: Pallete.inactiveSeekColor,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          )
        ],
      ),
    );
  }
}