import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/conversation_model.dart';
import '../models/true_message_model.dart';
import '../services/conversation_api_service.dart';
import '../widgets/base_widget/custom_snack_bar.dart';
import '../widgets/notifications/notification_card_widget.dart';
import 'user_controller.dart';

class ConversationController extends GetxController {
  final ConversationApiService conversationApiService;

  ConversationController({required this.conversationApiService});

  RxList<Conversation> conversations = <Conversation>[].obs;
  RxBool isLoading = false.obs;
  Timer? _pollingTimer;
  bool isPollingPaused = false; // Flag to track polling state

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  /// Fetch Conversations
  Future<void> fetchConversations(String token) async {
    isLoading.value = true;
    try {
      final fetchedConversations =
          await conversationApiService.getConversations(token);
      conversations.value = fetchedConversations;
      //debugPrint('Fetched Conversations: ${conversations.length}');
      /*debugPrint(
          'Conversations after fetch: ${conversations.map((c) => c.id)}');*/
    } catch (e) {
      //debugPrint('Error in fetchConversations: $e');
      Get.snackbar('Error', 'Failed to fetch conversations.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Refresh Conversations
  Future<void> refreshConversations(String token) async {
    try {
      final updatedConversations =
          await conversationApiService.getConversations(token);
      conversations.value = updatedConversations;
      //debugPrint('Conversations refreshed: ${conversations.map((c) => c.id)}');
    } catch (e) {
      //debugPrint('Error in refreshConversations: $e');
      Get.snackbar('Error', 'Failed to refresh conversations.');
    }
  }

  /// Start Polling for Updates
  void startPolling(String token) {
    // If polling is already running, do not start a new one
    if (_pollingTimer != null && _pollingTimer!.isActive) return;

    // Get the current user's ID
    final currentUserId = Get.find<UserController>().currentUser.value?.id;

    // Create a new timer for polling
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (isPollingPaused) return; // Skip polling if paused

      try {
        final oldConversations = List<Conversation>.from(conversations);

        // Fetch and refresh conversations
        await refreshConversations(token);

        // Compare with old conversations for new messages
        for (final conversation in conversations) {
          final oldConversation = oldConversations.firstWhere(
            (c) => c.id == conversation.id,
            orElse: () => Conversation(
              id: '',
              createdAt: DateTime.now(),
              messagesIds: [],
              userIds: [],
              users: [],
              messages: [],
            ),
          );

          // Check if there are new messages in the conversation
          if (conversation.messages.length > oldConversation.messages.length) {
            final newMessage = conversation.messages.last;

            // Show notification only if the message is sent by another user
            if (newMessage.sender?.id != currentUserId) {
              showSimpleNotification(
                senderName: newMessage.sender?.name ?? "Unknown Sender",
                messageContent: newMessage.body.isNotEmpty
                    ? newMessage.body
                    : "Sent an attachment",
                conversationId: conversation.id,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  /// Stop Polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null; // Clear the timer reference
  }

  /// Resume Polling
  Future<void> resumePolling() async {
    isPollingPaused = false;
    final token = await Get.find<UserController>().getToken();
    if (token != null) {
      startPolling(token); // Restart polling with the token
    } else {
      debugPrint("Token is null. Cannot resume polling.");
    }
  }

  /// Pause Polling (Explicit Method for Pausing)
  void pausePolling() {
    isPollingPaused = true;
  }

  /// Create Conversation
  Future<void> createConversation({
    required String token,
    required String userId,
  }) async {
    try {
      final newConversation = await conversationApiService.createConversation(
        token: token,
        isGroup: false, // Assuming 1-on-1 conversations
        userId: userId, // Pass the target user's ID
      );

      conversations.add(newConversation);
      showSuccessSnackbar("Success, Conversation created successfully.");
    } catch (e) {
      debugPrint('Error in createConversation: $e');
      Get.snackbar('Error', 'Failed to create conversation.');
    }
  }

  /// Update Last Message in a Conversation
  void updateLastMessage(String conversationId, Message message) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final updatedConversation = conversations[index].copyWith(
        messages: [...conversations[index].messages, message],
      );
      conversations[index] = updatedConversation;
    }
  }

  /// Create Group Conversation
  Future<void> createGroupConversation({
    required String token,
    required String name,
    String? logo,
    required List<String> memberIds,
  }) async {
    isLoading.value = true;
    try {
      final newGroup = await conversationApiService.createGroupConversation(
        token: token,
        name: name,
        logo: logo,
        memberIds: memberIds,
      );

      conversations.add(newGroup);
      showSuccessSnackbar("Success, Group created successfully.");
    } catch (e) {
      debugPrint('Error in createGroupConversation: $e');
      Get.snackbar('Error', 'Failed to create group.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark Conversation as Seen
  Future<void> markAsSeen({
    required String token,
    required String conversationId,
  }) async {
    try {
      final updatedConversation =
          await conversationApiService.markConversationAsSeen(
        token: token,
        conversationId: conversationId,
      );

      if (updatedConversation.id.isNotEmpty) {
        final index = conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          conversations[index] = updatedConversation;
          //debugPrint('Conversation marked as seen: $conversationId');
        } else {
          debugPrint('Conversation not found locally: $conversationId');
        }
      } else {
        throw Exception('Invalid response: Missing conversation ID.');
      }
    } catch (e) {
      debugPrint('Exception in markAsSeen: $e');
      //Get.snackbar('Error', 'Failed to mark conversation as seen.');(it works but has the bug)
    }
  }

  ///Delete conversation by id
  Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    isLoading.value = true;
    try {
      await conversationApiService.deleteConversation(
          token: token, conversationId: conversationId);
      // Remove the deleted conversation from the local list
      conversations.removeWhere((c) => c.id == conversationId);
      showSuccessSnackbar("Success, Conversation deleted successfully.");
    } catch (e) {
      debugPrint('Error in deleteConversation: $e');
      showErrorSnackbar('Error,Failed to delete conversation.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Find Conversation by ID (Optional Utility Method)
  /* Conversation? findConversationById(String conversationId) {
    try {
      return conversations.firstWhere(
            (c) => c.id == conversationId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Error in findConversationById: $e');
      return null;
    }
  }*/
}
