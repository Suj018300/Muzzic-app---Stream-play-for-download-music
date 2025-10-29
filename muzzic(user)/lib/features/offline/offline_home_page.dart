import 'package:client/features/offline/offline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/view/widgets/music_slab.dart';

class OfflineHomePage extends ConsumerStatefulWidget {
  const OfflineHomePage({super.key});

  @override
  ConsumerState<OfflineHomePage> createState() => _OfflineHomePageState();
}

class _OfflineHomePageState extends ConsumerState<OfflineHomePage> {
  int selectedIndex = 0;

  List<Widget> offlinePage = const [
    OfflinePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          offlinePage[selectedIndex],
          const Positioned(
            bottom: 0,
            child: MusicSlab(),
          )
        ],
      )
    );
  }
}
