import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/true_message_model.dart';
import '../services/ai_chabot_service.dart';
import '../services/message_api_service.dart';
import 'conversation_controller.dart';

class ChatRoomController extends GetxController {
  final MessageApiService messageApiService;
  final AIChatbotService aiChatbotService =
      AIChatbotService(); // Add AI chatbot service
  final ConversationController conversationController =
      Get.find<ConversationController>();

  ChatRoomController({required this.messageApiService});

  RxList<Message> messages = <Message>[].obs;
  RxBool isLoading = false.obs;
  RxBool isRecording = false.obs;
  RxString recordingFilePath = ''.obs;
  RxString sendingStatus = ''.obs;
  final AudioRecorder record = AudioRecorder();
  RxString lastFetchedMessageId = ''.obs; // To track the last message fetched
  Timer? _pollingTimer;
  Function? onMessagesUpdated;

  /// Fetch Messages
  Future<void> fetchMessages(String token, String conversationId) async {
    isLoading.value = true;
    try {
      final fetchedMessages =
          await messageApiService.getMessages(token, conversationId);
      messages.value = fetchedMessages;

      if (fetchedMessages.isNotEmpty) {
        lastFetchedMessageId.value = fetchedMessages.last.id;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Poll for new messages
  void startPolling(String token, String conversationId) {
    _pollingTimer?.cancel(); // Cancel any existing timer

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final fetchedMessages = await messageApiService.getMessages(
          token,
          conversationId,
        );

        // Filter and add only new messages
        final newMessages = fetchedMessages.where((message) => !messages
            .any((existingMessage) => existingMessage.id == message.id));

        if (newMessages.isNotEmpty) {
          messages.addAll(newMessages);
        }
      } catch (e) {
        debugPrint('Polling error: $e');
      }
    });
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
  }

  @override
  void onClose() {
    stopPolling(); // Ensure polling stops when the controller is disposed
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();

    // Listen to changes in the messages list
    messages.listen((_) {
      if (onMessagesUpdated != null) {
        onMessagesUpdated!(); // Call the callback when the list is updated
      }
    });
  }

  /// Send Text Message
  Future<void> sendMessage({
    required String token,
    required String conversationId,
    required String body,
  }) async {
    if (token.isEmpty || conversationId.isEmpty || body.isEmpty) {
      Get.snackbar(
          'Error', 'Token, Conversation ID, and Body cannot be empty.');
      return;
    }

    try {
      // Send the message to the server
      await messageApiService.sendMessage(
        token: token,
        conversationId: conversationId,
        body: body,
      );

      sendingStatus.value = ''; // Clear status when done
    } catch (e) {
      sendingStatus.value = ''; // Clear status on failure
      Get.snackbar('Error', 'Failed to send message: $e');
    }
  }

  /// Send Image Message
  Future<void> sendImage({
    required String token,
    required String conversationId,
    required File imageFile,
  }) async {
    if (token.isEmpty || conversationId.isEmpty) {
      Get.snackbar('Error', 'Token and Conversation ID cannot be empty.');
      return;
    }

    try {
      // Upload the image and get the URL
      final imageUrl =
          await messageApiService.uploadFileToCloudinary(imageFile);

      if (imageUrl == null || imageUrl.isEmpty) {
        sendingStatus.value = '';
        Get.snackbar('Error', 'Image upload failed.');
        return;
      }

      // Send the image message to the server
      await messageApiService.sendMessage(
        token: token,
        conversationId: conversationId,
        image: imageUrl,
      );

      sendingStatus.value = ''; // Clear status when done
    } catch (e) {
      sendingStatus.value = ''; // Clear status on failure
      Get.snackbar('Error', 'Failed to send image: $e');
    }
  }

  /// Send Voice Message
  Future<void> sendVoiceMessage({
    required String token,
    required String conversationId,
    required File voiceFile,
  }) async {
    if (token.isEmpty || conversationId.isEmpty) {
      Get.snackbar('Error', 'Token and Conversation ID cannot be empty.');
      return;
    }

    try {
      // Upload the voice file and get the URL
      final audioUrl =
          await messageApiService.uploadFileToCloudinary(voiceFile);

      if (audioUrl == null || audioUrl.isEmpty) {
        sendingStatus.value = '';
        Get.snackbar('Error', 'Audio upload failed.');
        return;
      }

      // Send the voice message to the server
      await messageApiService.sendMessage(
        token: token,
        conversationId: conversationId,
        audio: audioUrl,
      );

      sendingStatus.value = ''; // Clear status when done
    } catch (e) {
      sendingStatus.value = ''; // Clear status on failure
      Get.snackbar('Error', 'Failed to send voice message: $e');
    }
  }

  /// Start Recording
  Future<void> startRecording() async {
    if (await record.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          "${tempDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a";

      await record.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );
      recordingFilePath.value = filePath;
      isRecording.value = true;
    } else {
      Get.snackbar('Error', 'Microphone permission denied.');
    }
  }

  /// Stop Recording
  Future<void> stopRecording({
    required String token,
    required String conversationId,
  }) async {
    try {
      final recordedPath = await record.stop();
      if (recordedPath != null && recordedPath.isNotEmpty) {
        final voiceFile = File(recordedPath);
        if (voiceFile.existsSync()) {
          await sendVoiceMessage(
            token: token,
            conversationId: conversationId,
            voiceFile: voiceFile,
          );
        } else {
          throw Exception('Recorded file does not exist.');
        }
      }
      isRecording.value = false;
      recordingFilePath.value = '';
    } catch (e) {
      Get.snackbar('Error', 'Failed to stop recording: $e');
    } finally {
      isRecording.value = false;
      recordingFilePath.value = '';
    }
  }

  /// Discard Recording
  Future<void> discardRecording() async {
    try {
      if (await record.isRecording()) {
        await record.stop(); // Stop the recording to release the microphone
      }

      if (recordingFilePath.value.isNotEmpty) {
        final file = File(recordingFilePath.value);
        if (file.existsSync()) {
          file.deleteSync(); // Delete the recorded file
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to discard recording: $e');
    } finally {
      recordingFilePath.value = '';
      isRecording.value = false;
    }
  }

  /// Send AI Chatbot Message
  Future<void> sendAIChatbotMessage({
    required String token,
    required String conversationId,
    required String userMessage,
  }) async {
    try {
      // Step 1: Get AI response
      final aiResponse = await aiChatbotService.sendMessageToAI(userMessage);

      // Step 3: Add the AI message to the local messages list with isFromAI = true
      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'ai_chatbot', // Use a unique ID for the AI chatbot
        body: aiResponse,
        createdAt: DateTime.now(),
        isFromAI: true, conversationId: conversationId, // Mark as AI message
      );
      messages.add(aiMessage);
    } catch (e) {
      Get.snackbar('Error', 'Failed to get AI response: $e');
    }
  }
}
