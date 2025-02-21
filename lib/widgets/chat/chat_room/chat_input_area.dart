import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'attachment_options.dart';

class ChatInputArea extends StatefulWidget {
  final void Function(String message) onSend;
  final void Function(File imageFile) onAttachImage;
  final void Function() onStartRecording;
  final void Function() onStopRecording;
  final void Function() onDiscardRecording;
  final RxBool isRecording;
  final RxBool isSending;

  ChatInputArea({
    super.key,
    required this.onSend,
    required this.onAttachImage,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onDiscardRecording,
    required this.isRecording,
    required this.isSending,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    super.dispose();
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 16,
            right: 16,
          ),
          child: AttachmentOptions(
            onAttachImage: widget.onAttachImage,
            onStartRecording: widget.onStartRecording,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if (widget.isRecording.value) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 1.0, end: 1.3)
                        .animate(_waveAnimationController),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const Icon(Icons.mic, color: Colors.red, size: 28),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "recording".tr,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  widget.isRecording.value = false;
                  widget.onStopRecording();
                },
                icon:
                    Icon(Iconsax.tick_circle, color: theme.colorScheme.primary),
              ),
              IconButton(
                onPressed: widget.onDiscardRecording,
                icon: const Icon(Iconsax.close_circle, color: Colors.red),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              onPressed: () => _showAttachmentOptions(context),
              icon: Icon(
                Iconsax.paperclip_2,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(width: 8),

            // Message Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    hintText: "type_a_message".tr,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send Button with loading state
            GestureDetector(
              onTap: () {
                final message = _messageController.text.trim();
                if (message.isNotEmpty) {
                  _messageController.clear();
                  widget.onSend(message);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.appBarTheme.backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: widget.isSending.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Iconsax.send_1,
                        color: theme.colorScheme.onPrimary,
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
