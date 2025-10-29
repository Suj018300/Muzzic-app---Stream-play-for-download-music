import 'package:client/core/providers/current_user_notifier.dart';
import 'package:client/core/providers/playlist_controller.dart';
import 'package:client/features/home/models/song_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../../../../core/AppSnakBar.dart';
import '../../../../core/providers/current_song_notifier.dart';
import '../../../../core/theme/app_pallet.dart';
import '../../../../core/utils.dart';
import '../../../../core/widgets/loader.dart';
import '../../viewmodel/home_viewmodel.dart';

class GlobalSongPage extends ConsumerStatefulWidget {
  const GlobalSongPage({super.key});

  @override
  ConsumerState<GlobalSongPage> createState() => _GlobalSongPageState();
}

class _GlobalSongPageState extends ConsumerState<GlobalSongPage> {

  final globalSongsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
    final response = ref.read(homeViewmodelProvider.notifier).getGlobalSongs();
    return response;
  });

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongNotifierProvider);
    final globalSongsAsync = ref.watch(globalSongsProvider);
    final userFavorite = ref.watch(currentUserNotifierProvider.select((data) => data!.favorites));
    final fav = ref.watch(getFavSongsProvider);
    final playlistCtrl = ref.read(playlistControllerProvider.notifier);
    final playlistState = ref.watch(playlistControllerProvider);

    return SafeArea(
        child: CustomScrollView(
          slivers: [

            const SliverAppBar(
              pinned: true,
              title: Text("Global Songs", textAlign: TextAlign.start,),
              backgroundColor: Color.fromRGBO(28, 28, 28, 1),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              sliver: globalSongsAsync.when(
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
                                playlistCtrl.playSongByIndex(index);
                                // ref.read(currentSongNotifierProvider.notifier).updateSong(song);
                                },
                                trailing: IconButton(
                                    onPressed: () async {
                                      // final isGlobal = currentSong.isGlobal;
                                      await ref.read(homeViewmodelProvider.notifier).favSong(
                                        songId: song.id,
                                      );
                                      final isNowFav = ref.read(currentUserNotifierProvider)!
                                          .favorites
                                          .any((fav) => fav.song_id == song.id);

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
                                      userFavorite.any((fav) => fav.song_id == song.id)
                                          ? Icons.favorite
                                          : Icons.favorite_border_rounded,
                                      color: Pallete.whiteColor,
                                    )
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
          ],
        )
    );
  }
}
