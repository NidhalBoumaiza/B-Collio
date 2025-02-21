import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatListTile extends StatelessWidget {
  final String senderName;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarImage;
  final bool isSeen; // New: Indicates whether the last message is seen
  final VoidCallback onTap;

  const ChatListTile({
    super.key,
    required this.senderName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.avatarImage,
    required this.isSeen, // New: Pass the seen status
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  avatarImage.isNotEmpty ? NetworkImage(avatarImage) : null,
              backgroundColor: Colors.grey.withOpacity(0.2),
              child: avatarImage.isEmpty
                  ? Text(
                      senderName.substring(0, 1).toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Name + Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender Name
                  Text(
                    senderName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Last Message Content
                  Row(
                    children: [
                      // Last message text
                      Expanded(
                        child: Text(
                          lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSeen
                                ? FontWeight.normal // Regular if seen
                                : FontWeight.bold, // Bold if not seen
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Seen Indicator
                      Icon(
                        isSeen
                            ? Icons.done_all // Double tick for seen
                            : Icons.check, // Single tick for delivered
                        size: 16,
                        color: isSeen
                            ? theme.colorScheme.primary // Blue for seen
                            : theme.colorScheme
                                .onSurfaceVariant, // Grey for delivered
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Time
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat.Hm().format(lastMessageTime),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
