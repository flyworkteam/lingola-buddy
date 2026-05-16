import 'package:flutter/material.dart';

class VoiceCallView extends StatelessWidget {
  const VoiceCallView({super.key, required this.tutorId});

  final String tutorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.withValues(alpha: 0.18),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Text('Tutor: $tutorId', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              const CircleAvatar(radius: 70, child: Icon(Icons.face, size: 70)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.mic_none_rounded),
                    onPressed: () {},
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.call_end_rounded),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.volume_up_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
