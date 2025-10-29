import 'dart:io';

import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/view/pages/upload_song_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/AppSnakBar.dart';
import '../../../../core/utils.dart';
import '../../viewmodel/home_viewmodel.dart';

class FavoritePage extends ConsumerWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final songNotifier = ref.watch(currentSongNotifierProvider.notifier);
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    final playlistState = ref.watch(playlistControllerProvider);
    final allFavSongs = ref.watch(getFavSongsProvider);
    final isPlaying = ref.watch(currentSongNotifierProvider.select((s) => s?.isPlaying ?? false));

    return SafeArea(
            minimum: EdgeInsets.zero,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                    child:currentSong != null ? Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          decoration: currentSong == null ? null : BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  hexToRgb(currentSong.hex_code),
                                  Pallete.transparentColor,
                                ],
                                stops: const [0.0, 0.45],
                              )
                          ),
                          child: Column(
                            children: [
                              /// Todo : Add currentSong image,
                              const SizedBox(height: 30,),
                              Center(
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    image: DecorationImage(
                                      image: currentSong.localThumbnailPath != null
                                          ? FileImage(File(currentSong.localThumbnailPath!))
                                          : NetworkImage(
                                        currentSong.thumbnail_url,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20,),

                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Favorite songs playlist",
                                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
                              ),
                              Row(
                                spacing: 6,
                                children: [
                                  IconButton(
                                      iconSize: 50,
                                      onPressed: () {
                                        final song = allFavSongs.valueOrNull ?? [];
                                        if (song.isNotEmpty) {
                                          playlistCtrl.toggleShuffle(
                                              song,
                                              SongSourceType.favorites
                                          );
                                          playlistCtrl.loadSongs(song, source: SongSourceType.favorites);
                                        }
                                      },
                                      icon: Icon(
                                        Icons.shuffle_rounded,
                                        color: (
                                            playlistState.shuffleMode == ShuffleModeType.random
                                                && playlistState.currentSource == SongSourceType.favorites
                                        )
                                            ? Pallete.gradient2
                                            : Pallete.whiteColor,
                                      )
                                  ),
                                  IconButton(
                                      iconSize: 50,
                                      onPressed:() {
                                        final song = allFavSongs.valueOrNull ?? [];
                                        final current = ref.watch(currentSongNotifierProvider);
                                        if (current != null) {
                                          ref.read(playlistControllerProvider.notifier).loadSongs(song, source: SongSourceType.favorites);
                                          ref.read(currentSongNotifierProvider.notifier).playPause();
                                        }
                                      },
                                      icon: Icon(
                                          currentSong.isPlaying
                                              ? Icons.pause_circle_filled_rounded
                                              : Icons.play_circle_fill_rounded
                                      )
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      ],
                    )
                        : const Center(child: Text("Add song to favorite to see magic..", style: TextStyle(fontSize: 16),),)
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: allFavSongs.when(
                    data: (data) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                            childCount: data.length + 1,
                                (context, index) {
                              if(index == data.length) {
                                return Card(
                                  key: const ValueKey("upload_card"),
                                  elevation: 0,
                                  color: Pallete.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(
                                      tileColor: Pallete.cardColor,
                                      onTap: () {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UploadSongPage()),);
                                      },
                                      leading: const CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Pallete.cardColor,
                                        child: Icon(Icons.add,),
                                      ),
                                      title: const Text(
                                        "Upload new song" ,
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final song = data[index];
                              return Card(
                                key: ValueKey(song.id),
                                elevation: 0,
                                color: Pallete.cardColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    onTap: () {
                                      final index = data.indexOf(song);
                                      if(data.isEmpty) return;
                                      ref.read(playlistControllerProvider.notifier).loadSongs(data, source: SongSourceType.favorites);
                                      ref.read(playlistControllerProvider.notifier).playSongByIndex(index);
                                      // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                                      },
                                    leading: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Pallete.backgroundColor,
                                      backgroundImage: NetworkImage(song.thumbnail_url),
                                    ),
                                    title: Text(
                                      song.song_name,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700
                                      ),
                                    ),
                                    subtitle: Text(
                                      song.artist,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                        ),
                      );
                    },
                    error: (error, st) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text(error.toString()),
                        ),
                      );},
                    loading: () => const SliverToBoxAdapter (child: Loader()),
                  ),
                )
              ],
            ),
          );
  }
}