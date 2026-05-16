import 'package:flutter/material.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key, required this.tutorId});

  final String tutorId;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sohbet: ${widget.tutorId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                _Bubble(alignRight: false, text: 'Merhaba! Bugün üzerinde hangi konuyu çalışalım?'),
                SizedBox(height: 8),
                _Bubble(alignRight: true, text: 'Kafede sipariş verme pratik etmek istiyorum.'),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Mesaj...'),
                      onSubmitted: (_) => _controller.clear(),
                    ),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.send_rounded)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.alignRight, required this.text});

  final bool alignRight;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg =
        alignRight ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = alignRight ? scheme.onPrimary : scheme.onSurface;
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(text, style: TextStyle(color: fg)),
        ),
      ),
    );
  }
}
