// lib/widgets/chat/chat_room/chatRoomAppBar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/call_service_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../screens/chat/ChatRoom/remote_profile_screen.dart';
import '../../../themes/theme.dart';

class ChatRoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String phoneNumber;
  final String conversationId;
  final String? avatarUrl;
  final DateTime? createdAt;
  final String recipientID;

  const ChatRoomAppBar({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.conversationId,
    this.avatarUrl,
    this.createdAt,
    required this.recipientID,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final callController = Get.find<CallServiceController>();
    final userController = Get.find<UserController>();
    final userID = userController.currentUser.value?.id ?? '';
    final userName = userController.currentUser.value?.name ?? '';

    return AppBar(
      flexibleSpace: isDarkMode
          ? null
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kLightOrange7, kLightOrange4],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left, color: Colors.white),
        onPressed: () => Get.back(),
      ),
      title: GestureDetector(
        onTap: () {
          Get.to(() => RemoteProfileScreen(
            username: name,
            profileImageUrl: avatarUrl ??
                "https://avatar.iran.liara.run/username?username=$name&uppercase=false",
            phoneNumber: phoneNumber,
            email: 'test@gmail.com',
            createdAt: createdAt,
            status: "",
            conversationId: conversationId,
          ));
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Text(
                name.substring(0, 1).toUpperCase(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      actions: [
        callController.getCallInvitationButton(
          targetUserID: recipientID,
          targetUserName: name,
          currentUserID: userID,
          currentUserName: userName,
          isVideoCall: false,
          conversationId: conversationId,
        ),
        const SizedBox(width: 8),
        callController.getCallInvitationButton(
          targetUserID: recipientID,
          targetUserName: name,
          currentUserID: userID,
          currentUserName: userName,
          isVideoCall: true,
          conversationId: conversationId,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}