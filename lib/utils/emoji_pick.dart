import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class EmojiPickerWidget extends StatelessWidget {
  final Function(String) onEmojiSelected;

  const EmojiPickerWidget({super.key, required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          Expanded(
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) => onEmojiSelected(emoji.emoji),
              config: const Config(
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(emojiSizeMax: 28),
              ),
            ),
          ),
          const Divider(height: 1),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
