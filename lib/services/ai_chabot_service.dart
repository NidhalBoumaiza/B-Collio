import 'dart:convert';
import 'package:http/http.dart' as http;

class AIChatbotService {
  final String baseUrl = 'https://sd5.savooria.com/chat';

  /// Send a message to the AI chatbot
  Future<String> sendMessageToAI(String userMessage) async {
    final url = Uri.parse(baseUrl);

    final body = {
      "messages": [
        {"role": "system", "content": "Hi! How can I assist you?"},
        {"role": "user", "content": userMessage},
      ],
      "model": "llama2",
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        return responseData['message']['content'] as String;
      } else {
        throw Exception('Failed to get AI response: ${response.body}');
      }
    } catch (e) {
      throw Exception('AI Chatbot error: $e');
    }
  }
}
