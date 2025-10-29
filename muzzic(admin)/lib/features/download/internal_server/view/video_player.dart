import 'package:flutter/material.dart';
// import 'package:media_kit/media_kit.dart';
// import 'package:media_kit_video/media_kit_video.dart';
import 'package:awesome_video_player/awesome_video_player.dart';

class VideoPlayer extends StatefulWidget {
  final String url;
  const VideoPlayer({
    super.key,
    required this.url
  });

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  // late final player = BetterPlayerConfiguration();
  late BetterPlayerController controller;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BetterPlayerConfiguration config = BetterPlayerConfiguration(
      autoPlay: true,
      looping: false,
      // other config options
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.url,
      // headers, subtitles, etc.
    );
    controller = BetterPlayerController(config);
    controller.setupDataSource(dataSource);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: BetterPlayer(
            controller: controller,
        )
      ),
    );
  }
}
