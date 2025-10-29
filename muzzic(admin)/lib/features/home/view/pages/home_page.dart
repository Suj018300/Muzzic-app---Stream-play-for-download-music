import 'dart:async';
import 'package:client/core/theme/app_pallet.dart';
import 'package:client/features/home/view/pages/songs_page.dart';
import 'package:client/features/home/view/pages/upload_song_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../download/internal_server/view/internal_download_page.dart';
import '../widgets/music_slab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int selectedIndex = 0;
  bool isOnline = true;

  List<Widget> pages = const [
    SongsPage(),
    // LibraryPage(),
    UploadSongPage(),
    InternalDownloadPage(),
  ];


@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          pages[selectedIndex],
          const Positioned(
            bottom: 0,
            child: MusicSlab(),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        backgroundColor: const Color.fromRGBO(28, 28, 28, 1),
        selectedItemColor: Pallete.whiteColor,
        unselectedItemColor: Pallete.inactiveBottomBarItemColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Pallete.whiteColor),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, color: Pallete.inactiveBottomBarItemColor),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,),
              activeIcon: Icon(Icons.home_filled,),
              label: 'Home'
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.library_books_outlined,),
          //   activeIcon: Icon(Icons.library_books_rounded,),
          //   label: 'Library',
          // ),
          BottomNavigationBarItem(
              icon: Icon(Icons.upload_outlined,),
              activeIcon: Icon(Icons.upload_rounded,),
              label: 'Add'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.download_for_offline_outlined,),
              activeIcon: Icon(Icons.download_for_offline_rounded,),
              label: 'Download'
          ),
        ],
        // enableFeedback: true,
        iconSize: 30,
      ),
    );
  }
}