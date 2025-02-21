import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/user_controller.dart';
import '../../../models/true_message_model.dart';
import 'full_screen_image_viewer.dart';

class MessageList extends StatefulWidget {
  final RxList<Message> messages;
  final void Function(String message) onReply;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.onReply,
    required this.scrollController,
  });

  @override
  _MessageListState createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final RxInt _playingIndex = RxInt(-1);

  // Map to track which message is tapped for timestamp display
  final Map<int, bool> _showTimestamp = {};

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  String formatTimestamp(DateTime timestamp) {
    return "${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} ${timestamp.day}/${timestamp.month}/${timestamp.year}";
  }

  void _togglePlayPause(int index, String audioUrl) async {
    if (_playingIndex.value == index) {
      await _audioPlayer.pause();
      _playingIndex.value = -1;
    } else {
      await _audioPlayer.stop();

      try {
        await _audioPlayer.setSourceUrl(audioUrl);
        _audioPlayer.play(UrlSource(audioUrl));
        _playingIndex.value = index;

        _audioPlayer.onPlayerComplete.listen((_) {
          _playingIndex.value = -1;
        });
      } catch (e) {
        Get.snackbar(
          "Error",
          "Failed to play audio: $e",
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      return ListView.builder(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          final currentUserId = Get.arguments?['currentUserId'] ??
              Get.find<UserController>().currentUser.value?.id;
          final isMe = message.senderId == currentUserId &&
              !message.isFromAI; // Check if it's a user message
          final isAI = message.isFromAI; // Check if it's an AI message

          final type = message.type;
          final body = message.body;
          final image = message.image;
          final audio = message.audio;

          // Toggle the timestamp visibility on tap
          void _onMessageTap() {
            if (message.type == 'text') {
              setState(() {
                _showTimestamp[index] = !(_showTimestamp[index] ?? false);
              });
            }
          }

          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: (image != null && image.isNotEmpty)
                ? GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageViewer(
                            imageUrl: image,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FadeInImage(
                          placeholder:
                              const AssetImage('assets/placeholder.png'),
                          image: NetworkImage(image),
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                          placeholderErrorBuilder:
                              (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              width: 150,
                              height: 150,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              width: 150,
                              height: 150,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    ),
                  )
                : (audio != null && audio.isNotEmpty)
                    ? Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        width: 250,
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.appBarTheme.backgroundColor
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12).copyWith(
                            bottomRight:
                                isMe ? Radius.zero : const Radius.circular(12),
                            bottomLeft:
                                isMe ? const Radius.circular(12) : Radius.zero,
                          ),
                        ),
                        child: Row(
                          children: [
                            Obx(() => IconButton(
                                  icon: Icon(
                                    _playingIndex.value == index
                                        ? Iconsax.pause
                                        : Iconsax.play,
                                    color: isMe
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                  ),
                                  onPressed: () =>
                                      _togglePlayPause(index, audio),
                                )),
                            Obx(() {
                              return _playingIndex.value == index
                                  ? const SizedBox.shrink()
                                  : Flexible(
                                      child: Text(
                                        "Voice message",
                                        overflow: TextOverflow.ellipsis,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: isMe
                                              ? Colors.white
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    );
                            }),
                            const Spacer(),
                            Obx(() {
                              return _playingIndex.value == index
                                  ? Icon(
                                      Iconsax.sound,
                                      color: isMe
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                    )
                                  : const SizedBox.shrink();
                            }),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _onMessageTap, // Trigger timestamp display
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            if (isAI) // Display app icon for AI messages
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: theme.colorScheme.surface,
                                    child: Icon(
                                      Icons
                                          .android, // Use an appropriate icon for the AI chatbot
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? theme.appBarTheme.backgroundColor
                                    : theme.colorScheme.surface,
                                borderRadius:
                                    BorderRadius.circular(12).copyWith(
                                  bottomRight: isMe
                                      ? Radius.zero
                                      : const Radius.circular(12),
                                  bottomLeft: isMe
                                      ? const Radius.circular(12)
                                      : Radius.zero,
                                ),
                              ),
                              child: Text(
                                body.isNotEmpty ? body : '[No content]',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isMe
                                      ? Colors.white
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (_showTimestamp[index] ==
                                true) // Show timestamp below the container
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Sent at: ${formatTimestamp(message.createdAt)}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
          );
        },
      );
    });
  }
}
