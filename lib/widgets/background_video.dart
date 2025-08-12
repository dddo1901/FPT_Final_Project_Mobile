import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class BackgroundVideo extends StatefulWidget {
  const BackgroundVideo({super.key});
  @override
  _BackgroundVideoState createState() => _BackgroundVideoState();
}

class _BackgroundVideoState extends State<BackgroundVideo> {
  late VideoPlayerController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/bg.mp4')
      ..initialize().then((_) {
        _ctrl.setLooping(true);
        _ctrl.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ctrl.value.isInitialized
        ? SizedBox.expand(child: VideoPlayer(_ctrl))
        : Container(color: Colors.black);
  }
}
