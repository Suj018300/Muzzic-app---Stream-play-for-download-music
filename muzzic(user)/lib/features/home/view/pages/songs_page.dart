import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:client/core/providers/current_song_notifier.dart';
import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/core/utils.dart';
import 'package:client/core/widgets/loader.dart';
import 'package:client/features/home/repositories/home_local_repository.dart';
import 'package:client/features/home/view/pages/upload_song_page.dart';
import 'package:client/features/home/view/pages/reupload_song_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/AppSnakBar.dart';
import '../../models/song_model.dart';
import '../../viewmodel/home_viewmodel.dart';


class SongsPage extends ConsumerStatefulWidget {
  const SongsPage({super.key});

  @override
  ConsumerState<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends ConsumerState<SongsPage> {

  final songsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
    final homeVM = ref.watch(homeViewmodelProvider.notifier);
    return await homeVM.getSongsList();
  });

  final allSongsProvider = FutureProvider<List<SongModel>>((ref) async {
    final homeVM = ref.watch(homeViewmodelProvider.notifier);
    return await homeVM.getAllSongs();
  });

@override
  Widget build(BuildContext context) {
    final homeVM = ref.watch(homeViewmodelProvider.notifier);
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    final playlistState = ref.watch(playlistControllerProvider);
    final recentlyPlayedSongs = homeVM.getRecentlyPlayedSongs();
    final currentSong = ref.watch(currentSongNotifierProvider);
    final allSongsAsync = ref.watch(allSongsProvider);
    final songAsync = ref.watch(songsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers:[

          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            sliver: SliverToBoxAdapter(
              child: AnimatedContainer(
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: double.infinity,
                          child: Text(
                            'Recently played',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: recentlyPlayedSongs.length,
                            itemBuilder: (context, index) {
                              final song = recentlyPlayedSongs[index];

                              return InkWell(
                                onTap: () {
                                  ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                                  ref.read(homeLocalRepositoryProvider).markAsRecentlyPlayed(song);
                                  // ref.read(playlistControllerProvider.notifier).playSongByIndex(index);
                                  setState(() {});
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      color: Pallete.cardColor,
                                      borderRadius: BorderRadius.circular(6)
                                  ),
                                  // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadiusGeometry.circular(6),
                                        child: Image.network(
                                          song.thumbnail_url,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 56,
                                              height: 56,
                                              color: Colors.grey.shade800,
                                              child: const Icon(Icons.music_note, color: Colors.white),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          song.song_name,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          maxLines: 1,
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
              ),
            )
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Recently Added songs',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: songAsync.when(
                loading: () {
                  return const Center(child: Loader(),);
                  },
                error: (err, _) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppBanner.show(
                      context,
                      title: "Error on Recently added songs",
                      message: "Error: $err",
                      contentType: ContentType.failure,
                    );
                  });
                  // print("Error: $err");
                  return const SizedBox();
                  },
                data: (songs) {
                  // print("UUUUUUUUFetched songs count: ${songs.length}");
                  return SizedBox(
                    height: 250,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: songs.length + 1 > 6 ? 6 : songs.length + 1,
                        itemBuilder: (context, index) {
                          if (index == songs.length) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const UploadSongPage()),);
                                        },
                                      style: ButtonStyle(
                                        shape: WidgetStatePropertyAll(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            )
                                        ),
                                        backgroundColor: const WidgetStatePropertyAll(Pallete.cardColor),
                                      ),
                                      child: const Icon(Icons.add, size: 70,),
                                    ),
                                  ),
                                  const SizedBox(height: 10,),
                                  const SizedBox(
                                    width: 180,
                                    child: Center(
                                      child: Text(
                                        "Upload Song",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final song = songs[index];
                          return GestureDetector(
                            onTap: () {
                              final index = songs.indexOf(song);

                              if (songs.isEmpty) return;
                              // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                              ref.read(playlistControllerProvider.notifier)
                                  .loadSongs(songs, source: SongSourceType.userSongs);

                              ref.read(playlistControllerProvider.notifier).playSongByIndex(index);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                children: [
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(song.thumbnail_url),
                                          fit: BoxFit.cover,
                                        ),
                                        borderRadius: BorderRadius.circular(10)
                                    ),
                                  ),
                                  const SizedBox(height: 10,),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      song.song_name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      song.artist,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          overflow: TextOverflow.ellipsis,
                                          color: Pallete.subtitleText
                                      ),
                                      maxLines: 1,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }
                    ),
                  );
                }
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All songs',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      IconButton(
                          iconSize: 40,
                          onPressed: () {
                            final song = allSongsAsync.valueOrNull ?? [];
                            if (song.isNotEmpty) {
                              playlistCtrl.toggleShuffle(
                                  song,
                                  SongSourceType.userSongs
                              );
                              playlistCtrl.loadSongs(song, source: SongSourceType.userSongs);
                            }
                          },
                          icon: Icon(
                            Icons.shuffle_rounded,
                            color:
                            playlistState.shuffleMode == ShuffleModeType.random
                                ? Pallete.gradient2
                                : Pallete.whiteColor,
                          )
                      ),
                      IconButton(
                          iconSize: 40,
                          onPressed: ref.read(currentSongNotifierProvider.notifier).playPause,
                          icon: Icon(
                             ref.watch(currentSongNotifierProvider)?.isPlaying ?? false
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded
                          )
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: allSongsAsync.when(
              loading: () {
                return const SliverToBoxAdapter (child: Center(child: Loader()));
                },
              error: (err, _) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  AppBanner.show(
                    context,
                    title: "Error in the your songs list",
                    message: "Error",
                    contentType: ContentType.failure,
                  );
                });
                return const SliverToBoxAdapter ( child: SizedBox());
                },
              data: (songs) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                      childCount: songs.length,
                          (context, index) {
                        final song = songs[index];
                        return Card(
                          // margin: EdgeInsets.all(8),
                          elevation: 0,
                          color: Pallete.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(leading: CircleAvatar(
                              radius: 35,
                              backgroundColor: Pallete.cardColor,
                              backgroundImage: NetworkImage(song.thumbnail_url),
                            ),
                              title: Text(
                                song.song_name,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700
                                ),
                              ),
                              onTap: () {
                              final index = songs.indexOf(song);
                              ref.read(playlistControllerProvider.notifier).loadSongs(songs, source: SongSourceType.userSongs);
                              ref.read(playlistControllerProvider.notifier).playSongByIndex(index);
                              // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                              },
                              trailing: PopupMenuButton(
                                  color: Pallete.cardColor,
                                  shadowColor: Pallete.gradient3,
                                  itemBuilder: (BuildContext context) =>
                                  [
                                    PopupMenuItem(
                                        onTap: () async {
                                          await Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => UploadSongPageDemo(
                                                  songGetter: song
                                              ),
                                            ),
                                          );
                                          },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.edit),
                                            Text('Edit'),
                                          ],
                                        )
                                    ),
                                    PopupMenuItem(
                                        onTap: () async {
                                          showDialog(
                                              context: context,
                                              builder: (builder) => AlertDialog(
                                                title: Text(
                                                  'Delete ${song.song_name} song?',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold
                                                  ),
                                                ),
                                                content: const Text(
                                                    "Press Delete to delete this song, deleted song can't be restored"
                                                ),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                        },
                                                      child: const Center(
                                                        child: Text('Cancel'),
                                                      )
                                                  ),
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        ref.read(homeViewmodelProvider.notifier).deleteSong(
                                                            id: song.id,
                                                            token: ref.read(currentUserNotifierProvider)!.token
                                                        );
                                                        },
                                                      style: const ButtonStyle(
                                                          elevation: WidgetStatePropertyAll(0),
                                                          backgroundColor: WidgetStatePropertyAll(Color.fromRGBO(207, 102, 121, 1))
                                                      ),
                                                      child: const Center(
                                                        child: Text('Delete'),
                                                      )
                                                  )
                                                ],
                                              )
                                          );
                                          },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.delete),
                                            Text('Delete song')
                                          ],
                                        )
                                    ),
                                    PopupMenuItem(
                                        onTap: () async {
                                          await ref.watch(homeViewmodelProvider.notifier).saveToDownloads(
                                              id: song.id,
                                              token: ref.watch(currentUserNotifierProvider)!.token
                                          );
                                          },
                                        child: const Row(
                                          children: [
                                            Icon(Icons.download_for_offline_rounded),
                                            Text('Save to downloads'),
                                          ],
                                        )
                                    ),
                                  ]
                              ),
                            ),
                          ),
                        );
                      }
                      ),
                );
                },
            ),
          )
        ]
      ),
    );
  }
}