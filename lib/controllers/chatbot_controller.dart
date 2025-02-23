import 'package:get/get.dart';

import '../services/ai_chabot_service.dart'; // Replace with your actual package name

class ChatbotController extends GetxController {
  final AIChatbotService _aiChatbotService = AIChatbotService();
  final RxList<String> messages = <String>[].obs;
  final RxBool isLoading = false.obs;
  final RxString userInput = ''.obs;

  // Add a system message to start the conversation
  void initializeChat() {
   messages.add("Hi! How can I assist you?");
  }

  // Send message to AI and handle response
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    isLoading.value = true;
    messages.add("You: $message");

    try {
      final aiResponse = await _aiChatbotService.sendMessageToAI(message);
      messages.add("AI: $aiResponse");
    } catch (e) {
      messages.add("AI: Sorry, there was an error processing your request.");
    } finally {
      isLoading.value = false;
      userInput.value = ''; // Clear the input field after sending
    }
  }

  // Clear the conversation
  void clearConversation() {
    messages.clear();
   initializeChat(); // Reinitialize with the default message
  }
}