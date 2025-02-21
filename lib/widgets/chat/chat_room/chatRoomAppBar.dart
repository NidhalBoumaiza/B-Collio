import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/call_service_controller.dart';
import '../../../controllers/user_controller.dart';
import '../../../screens/chat/ChatRoom/remote_profile_screen.dart';
import '../../../themes/theme.dart';
import '../../base_widget/custom_snack_bar.dart';

class ChatRoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name; // The name of the recipient
  final String phoneNumber; // The phone number of the recipient
  final String conversationId; // The ID of the current conversation
  final String? avatarUrl; // Optional avatar URL of the recipient
  final DateTime? createdAt;
  final String recipientID; // Recipient's user ID

  const ChatRoomAppBar({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.conversationId,
    this.avatarUrl,
    this.createdAt,
    required this.recipientID, // Add recipient's user ID
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Initialize controllers
    final callController = Get.find<CallServiceController>();
    final userController = Get.find<UserController>();

    // Fetch logged-in user's details
    final userID = userController.currentUser.value?.id; // Logged-in user ID
    final userName =
        userController.currentUser.value?.name; // Logged-in user name

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
          // Navigate to the recipient's profile screen
          Get.to(
            () => RemoteProfileScreen(
              username: name,
              profileImageUrl: avatarUrl ??
                  "https://avatar.iran.liara.run/username?username=$name&uppercase=false",
              phoneNumber: phoneNumber,
              email: 'test@gmail.com', // Replace with the actual email
              createdAt: createdAt,
              status: "",
              conversationId: conversationId,
            ),
          );
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
        // Voice Call Button
        callController.getCallInvitationButton(
          targetUserID: recipientID, // Use recipient's user ID
          targetUserName: name,
          isVideoCall: false, // Voice call
        ),
        const SizedBox(width: 8),
        // Video Call Button
        callController.getCallInvitationButton(
          targetUserID: recipientID, // Use recipient's user ID
          targetUserName: name,
          isVideoCall: true, // Video call
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
