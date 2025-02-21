import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/call_service_controller.dart';
import '../../../controllers/chat_room_controller.dart';
import '../../../controllers/conversation_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../models/true_message_model.dart';
import '../../../services/message_api_service.dart';
import '../../../widgets/chat/chat_room/chatRoomAppBar.dart';
import '../../../widgets/chat/chat_room/chat_input_area.dart';
import '../../../widgets/chat/chat_room/message_list.dart';
import '../../../widgets/chat/chat_room/shimmer_loading_messages.dart';

class ChatRoomPage extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? avatarUrl;
  final String conversationId;
  final DateTime? createdAt;

  ChatRoomPage({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.conversationId,
    this.avatarUrl,
    this.createdAt,
  });

  final ScrollController _scrollController = ScrollController();
  final RxBool isSending = false.obs;
  final CallServiceController callController = Get.put(CallServiceController());

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 150,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final conversationController = Get.find<ConversationController>();
    final ChatRoomController controller = Get.put(
      ChatRoomController(messageApiService: Get.find<MessageApiService>()),
      tag: conversationId,
    );

    // Fetch logged-in user's details
    final userController = Get.find<UserController>();
    final currentUserId = userController.currentUser.value?.id;

    Future.delayed(Duration.zero, () async {
      final token = await userController.getToken();
      if (token != null && token.isNotEmpty) {
        await controller.fetchMessages(token, conversationId);
        controller.startPolling(token, conversationId);
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
        await conversationController.markAsSeen(
          token: token,
          conversationId: conversationId,
        );
      } else {
        Get.snackbar(
            'Error'.tr, 'Failed to retrieve token. Please log in again.'.tr);
      }
    });

    // Extract recipient's user ID
    final recipientID = _getRecipientId(controller.messages, currentUserId);
    debugPrint("Recipient ID: $recipientID"); // Debug log

    return WillPopScope(
      onWillPop: () async {
        controller.stopPolling();
        return true;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize:
              const Size.fromHeight(56), // Set the height of the AppBar
          child: Obx(() {
            // React to changes in messages
            final recipientID =
                _getRecipientId(controller.messages, currentUserId);
            return ChatRoomAppBar(
              name: name,
              phoneNumber: phoneNumber,
              avatarUrl: avatarUrl,
              conversationId: conversationId,
              createdAt: createdAt,
              recipientID: recipientID,
            );
          }),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const ShimmerMessageList();
          }

          return Column(
            children: [
              Expanded(
                child: controller.messages.isEmpty
                    ? Center(
                        child: Text('no_messages_yet'.tr),
                      )
                    : MessageList(
                        messages: controller.messages,
                        scrollController: _scrollController,
                        onReply: (message) async {
                          final token =
                              await Get.find<UserController>().getToken();
                          if (token != null && token.isNotEmpty) {
                            await controller.sendMessage(
                              token: token,
                              conversationId: conversationId,
                              body: message,
                            );
                            _scrollToBottom();
                          } else {
                            Get.snackbar(
                                'Error'.tr, 'Failed to retrieve token.'.tr);
                          }
                        },
                      ),
              ),
              ChatInputArea(
                isRecording: controller.isRecording,
                isSending: isSending,
                onSend: (message) async {
                  isSending.value = true;
                  final token = await Get.find<UserController>().getToken();
                  if (token != null && token.isNotEmpty) {
                    if (message.startsWith('@aibot')) {
                      final userQuery =
                          message.replaceFirst('@aibot', '').trim();
                      if (userQuery.isNotEmpty) {
                        await controller.sendAIChatbotMessage(
                          token: token,
                          conversationId: conversationId,
                          userMessage: userQuery,
                        );
                      }
                    } else {
                      await controller.sendMessage(
                        token: token,
                        conversationId: conversationId,
                        body: message,
                      );
                    }
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottom();
                    });
                  } else {
                    Get.snackbar('Error'.tr, 'Failed to retrieve token.'.tr);
                  }
                  isSending.value = false;
                },
                onAttachImage: (imageFile) async {
                  isSending.value = true;
                  final token = await Get.find<UserController>().getToken();
                  if (token != null && token.isNotEmpty) {
                    await controller.sendImage(
                      token: token,
                      conversationId: conversationId,
                      imageFile: imageFile,
                    );
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottom();
                    });
                  } else {
                    Get.snackbar('Error'.tr, 'Failed to retrieve token.'.tr);
                  }
                  isSending.value = false;
                },
                onStartRecording: () => controller.startRecording(),
                onStopRecording: () async {
                  isSending.value = true;
                  final token = await Get.find<UserController>().getToken();
                  if (token != null && token.isNotEmpty) {
                    await controller.stopRecording(
                      token: token,
                      conversationId: conversationId,
                    );
                    Future.delayed(const Duration(milliseconds: 200), () {
                      _scrollToBottom();
                    });
                  } else {
                    Get.snackbar('Error'.tr, 'Failed to retrieve token.'.tr);
                  }
                  isSending.value = false;
                },
                onDiscardRecording: () => controller.discardRecording(),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Helper method to get the recipient's user ID
  String _getRecipientId(List<Message> messages, String? currentUserId) {
    if (messages.isNotEmpty) {
      // Collect all possible user IDs from messages (senders and seenBy)
      Set<String> allUserIds = {};
      for (final message in messages) {
        allUserIds.add(message.senderId);
        if (message.seenBy != null) {
          for (final user in message.seenBy!) {
            allUserIds.add(user.id);
          }
        }
      }
      // Remove current user's ID to find the recipient
      allUserIds.remove(currentUserId);
      // Return the first user ID which is not the current user (recipient)
      return allUserIds.isNotEmpty ? allUserIds.first : '';
    }
    return ''; // Fallback if no messages
  }
}
