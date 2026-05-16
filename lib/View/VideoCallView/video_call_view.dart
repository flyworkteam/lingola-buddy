import 'package:flutter/material.dart';

class VideoCallView extends StatelessWidget {
  const VideoCallView({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(child: Icon(Icons.videocam, color: Colors.white54, size: 48)),
            ),
          ),
          Positioned(
            right: 14,
            top: MediaQuery.paddingOf(context).top + 8,
            width: 110,
            height: 145,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.photo_camera_front_outlined,
                  color: Colors.white54),
            ),
          ),
          Positioned(
            left: 14,
            top: MediaQuery.paddingOf(context).top + 8,
            child: Text(
              'Video - $tutorId',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.mic_off_outlined)),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.call_end_rounded),
                ),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.videocam_off_outlined)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
