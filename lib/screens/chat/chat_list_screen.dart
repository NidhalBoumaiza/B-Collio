import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import '../../controllers/conversation_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/true_user_model.dart';
import '../../widgets/chat/chat_room/chatRoomAppBar.dart';
import '../../widgets/chat/chat_tile.dart';
import '../../widgets/chat/empty_chat.dart';
import '../../widgets/chat/list_tile_shimmer.dart';
import '../../widgets/home/delete_dialog_widget.dart';
import 'ChatRoom/chat_room_screen.dart';

class ChatList extends StatelessWidget {
  ChatList({super.key});

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  Future<void> _onRefresh(ConversationController conversationController,
      UserController userController) async {
    final token = await userController.getToken();
    if (token != null) {
      await conversationController.fetchConversations(token);
      _refreshController.refreshCompleted();
    } else {
      _refreshController.refreshFailed();
      debugPrint('Error: Token is null. Unable to refresh conversations.');
    }
  }

  Future<void> _confirmDeleteConversation(BuildContext context,
      ConversationController controller, String conversationId) async {
    final token = await Get.find<UserController>().getToken();
    if (token == null) {
      Get.snackbar('Error', 'Token is missing. Unable to delete conversation.');
      return;
    }

    final shouldDelete = await showDeleteConfirmationDialog(context);
    if (shouldDelete == true) {
      await controller.deleteConversation(
          token: token, conversationId: conversationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationController = Get.find<ConversationController>();
    final userController = Get.find<UserController>();
    final theme = Theme.of(context);
    final lightColor = theme.brightness == Brightness.light;

    return Obx(() {
      if (conversationController.isLoading.value) {
        return const ChatListTileShimmer(count: 6);
      }

      if (conversationController.conversations.isEmpty) {
        return const EmptyChatList();
      }

      return SmartRefresher(
        enablePullDown: true,
        header: WaterDropMaterialHeader(
          backgroundColor: lightColor
              ? theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}) ??
                  theme.colorScheme.primary // Fallback to primary color
              : theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        ),
        controller: _refreshController,
        onRefresh: () => _onRefresh(conversationController, userController),
        child: ListView.builder(
          itemCount: conversationController.conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversationController.conversations[index];
            final currentUserId = userController.currentUser.value?.id;

            // Check if it is a group conversation
            final isGroup = conversation.isGroup ?? false;

            String displayName;
            String displayImage;
            String displayPhoneNumber =
                'N/A'; // Default to 'N/A' if unavailable
            DateTime? otherUserCreatedAt;

            if (isGroup) {
              displayName = conversation.name ?? "Group Chat";
              displayImage = conversation.logo ?? "";
            } else {
              final otherUser = conversation.users.firstWhere(
                (user) => user.id != currentUserId,
                orElse: () => User(
                  id: '',
                  name: 'Unknown',
                  email: '',
                  image: '',
                  phoneNumber: 'N/A',
                ),
              );

              displayName = otherUser.name ?? 'Unknown';
              displayImage = otherUser.image ?? '';
              displayPhoneNumber = otherUser.phoneNumber ?? 'N/A';
              otherUserCreatedAt = otherUser.createdAt;
            }

            final lastMessage = conversation.messages.isNotEmpty
                ? conversation.messages.last
                : null;

            String lastMessageText = 'No messages yet';
            if (lastMessage != null) {
              if (lastMessage.image != null && lastMessage.image!.isNotEmpty) {
                lastMessageText = "Image was sent";
              } else if (lastMessage.audio != null &&
                  lastMessage.audio!.isNotEmpty) {
                lastMessageText = "Voice message was sent";
              } else {
                lastMessageText = lastMessage.body;
              }
            }

            return GestureDetector(
              onLongPress: () => _confirmDeleteConversation(
                context,
                conversationController,
                conversation.id,
              ),
              child: ChatListTile(
                senderName: displayName,
                avatarImage: displayImage,
                lastMessage: lastMessageText,
                isSeen: lastMessage?.seenBy
                        ?.any((user) => user.id == currentUserId) ??
                    false,
                lastMessageTime: lastMessage?.createdAt ?? DateTime.now(),
                onTap: () {
                  Get.to(
                    () => ChatRoomPage(
                      name: displayName,
                      phoneNumber: displayPhoneNumber,
                      conversationId: conversation.id,
                      avatarUrl: displayImage,
                      createdAt: otherUserCreatedAt,
                    ),
                    arguments: {
                      'currentUserId': currentUserId,
                    },
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }
}
