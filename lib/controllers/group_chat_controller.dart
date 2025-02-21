import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/contact_model.dart';
import '../controllers/contact_controller.dart';
import '../controllers/conversation_controller.dart';
import '../controllers/user_controller.dart';
import '../screens/chat/ChatRoom/chat_room_screen.dart';

class GroupChatController extends GetxController {
  final ConversationController conversationController =
      Get.find<ConversationController>();
  final ContactController contactController = Get.find<ContactController>();
  final UserController userController = Get.find<UserController>();

  // Loading flags
  RxBool isFetchingContacts = false.obs; // For contact fetching
  RxBool isLoading = false.obs; // For group creation

  RxList<Contact> contacts = <Contact>[].obs;
  RxList<Contact> filteredContacts = <Contact>[].obs;
  RxList<Contact> selectedContacts = <Contact>[].obs;

  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupLogoController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchContacts();
  }

  /// Fetch Contacts
  Future<void> fetchContacts() async {
    isFetchingContacts.value = true; // Start fetching contacts
    try {
      final token = await userController.getToken();
      if (token != null && token.isNotEmpty) {
        await contactController.fetchContacts(token);
        contacts.value = contactController.contacts; // Sync contacts
        filteredContacts.value = contacts;
      } else {
        Get.snackbar('Error', 'Token is missing.');
      }
    } catch (e) {
      debugPrint('Error fetching contacts: $e');
    } finally {
      isFetchingContacts.value = false; // End fetching contacts
    }
  }

  /// Search Contacts
  void searchContacts(String query) {
    if (query.isEmpty) {
      filteredContacts.value = contacts;
    } else {
      filteredContacts.value = contacts
          .where((contact) =>
              contact.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Upload logo to Cloudinary
  Future<String?> uploadLogoToCloudinary(File image) async {
    try {
      final imageUrl =
          await userController.userApiService.uploadImageToCloudinary(image);
      return imageUrl;
    } catch (e) {
      debugPrint("Failed to upload image: $e");
      return null;
    }
  }

  /// Toggle Contact Selection
  void toggleSelection(Contact contact) {
    if (selectedContacts.contains(contact)) {
      selectedContacts.remove(contact);
    } else {
      selectedContacts.add(contact);
    }
  }

  /// Create Group Chat
  Future<void> createGroupChat() async {
    final token = await userController.getToken();
    if (token == null || token.isEmpty) {
      Get.snackbar('Error', 'Failed to retrieve token. Please log in again.');
      return;
    }

    final memberIds = selectedContacts.map((contact) => contact.id).toList();
    final groupName = groupNameController.text.trim();
    final groupLogo = groupLogoController.text.trim();

    if (groupName.isEmpty) {
      Get.snackbar('Error', 'Please provide a group name.');
      return;
    }

    isLoading.value = true; // Start group creation loading
    try {
      await conversationController.createGroupConversation(
        token: token,
        name: groupName,
        logo: groupLogo.isEmpty ? null : groupLogo,
        memberIds: memberIds,
      );

      // Navigate to ChatRoomPage
      final newGroup = conversationController.conversations.last;
      Get.to(() => ChatRoomPage(
            name: newGroup.name ?? 'Group Chat',
            phoneNumber: '', // Not applicable for groups
            avatarUrl: newGroup.logo,
            conversationId: newGroup.id,
            createdAt: newGroup.createdAt,
          ));
    } catch (e) {
      debugPrint('Error creating group: $e');
      Get.snackbar('Error', 'Failed to create group.');
    } finally {
      isLoading.value = false; // End group creation loading
    }
  }
}
