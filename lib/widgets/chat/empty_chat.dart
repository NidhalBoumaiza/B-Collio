import 'package:flutter/material.dart';
import 'package:get/get.dart';

class EmptyChatList extends StatelessWidget {
  const EmptyChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 84,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 25),
          Text(
            'no_chats_yet'.tr,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
