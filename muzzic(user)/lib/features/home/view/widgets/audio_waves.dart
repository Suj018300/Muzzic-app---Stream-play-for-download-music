import'package:audio_waveforms/audio_waveforms.dart';
import 'package:client/core/theme/app_pallet.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:waved_audio_player/waved_audio_player.dart';

import 'video_player.dart';

class AudioWaves extends StatefulWidget {
  String path;
  String songUrl;
  AudioWaves({
    super.key,
    required this.path,
    required this.songUrl,
    });

  @override
  State<AudioWaves> createState() => _AudioWavesState();
}

class _AudioWavesState extends State<AudioWaves> {
  final PlayerController playerController = PlayerController();
  final PlayerController onlinePlayerController = PlayerController();
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    if (widget.songUrl != 'null') {
      isOnline = true;
      initOnlinePLayer();
    } else if (widget.path != 'null') {
      isOnline = false;
      initAudioPlayer();
    }
  }

  void initAudioPlayer() async {
    await playerController.preparePlayer(path: widget.path);
  }

  Future<void> initOnlinePLayer() async {
    await onlinePlayerController.preparePlayer(
        path: widget.songUrl,
        shouldExtractWaveform: true
    );
  }

  Future<void> playAndPause() async {
    final controller = isOnline ? onlinePlayerController : playerController;

    if (!controller.playerState.isPlaying) {
      await controller.startPlayer(forceRefresh: false);
    } else if (!controller.playerState.isPaused) {
      await controller.pausePlayer();
    }
    setState(() {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    playerController.dispose();
    onlinePlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: playAndPause,
          icon: Icon(
            (isOnline ? onlinePlayerController : playerController).playerState.isPlaying ? Icons.pause :
            Icons.play_arrow_rounded
            )),
        Expanded(
          child: isOnline ?
    VideoPlayer(
        url: widget.songUrl,
    )
              :
          AudioFileWaveforms(
            size: const Size(double.infinity, 100),
            playerController: playerController,
            playerWaveStyle: const PlayerWaveStyle(
              fixedWaveColor: Pallete.borderColor,
              liveWaveColor: Pallete.gradient2,
              // showSeekLine: false
              spacing: 6,
            ),
          ),
          // VideoPlayer(
          //     url: widget.songUrl
          // ),
        ),
      ],
    );
  }
}

