import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloudinary/cloudinary.dart';
import '../models/true_message_model.dart';
import '../utils/misc.dart';

class MessageApiService {
  final cloudinary = Cloudinary.unsignedConfig(
    cloudName: cloudName,
  );

  /// Fetch Messages by Conversation
  Future<List<Message>> getMessages(String token, String conversationId) async {
    if (token.isEmpty || conversationId.isEmpty) {
      throw ArgumentError('Token and conversation ID cannot be empty');
    }

    final url =
        Uri.parse('$baseUrl/mobile/conversations/$conversationId/messages');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> messagesJson = json.decode(response.body);
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        print('Error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to fetch messages: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      rethrow;
    }
  }

  /// Send Message
  Future<Message> sendMessage({
    required String token,
    required String conversationId,
    String? body,
    String? image,
    String? audio,
  }) async {
    if (token.isEmpty || conversationId.isEmpty) {
      throw ArgumentError('Token and conversation ID cannot be empty');
    }

    final url = Uri.parse('$baseUrl/mobile/messages');
    final bodyPayload = {
      'conversationId': conversationId,
    };

    if (body != null && body.isNotEmpty) {
      bodyPayload['message'] = body;
    }
    if (image != null && image.isNotEmpty) {
      bodyPayload['image'] = image;
    }
    if (audio != null && audio.isNotEmpty) {
      bodyPayload['audio'] = audio;
    }

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode(bodyPayload),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Message.fromJson(json.decode(response.body));
      } else {
        print('Error: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Upload File to Cloudinary
  Future<String?> uploadFileToCloudinary(File file) async {
    try {
      // Identify resource type based on file extension
      final resourceType =
          file.path.endsWith('.m4a') || file.path.endsWith('.mp3')
              ? CloudinaryResourceType.auto
              : CloudinaryResourceType.image;

      final response = await cloudinary.unsignedUpload(
        file: file.path,
        uploadPreset: uploadPreset,
        resourceType: resourceType,
        progressCallback: (count, total) {
          print('Uploading file: $count/$total');
        },
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        throw Exception('Failed to upload file: ${response.error?.toString()}');
      }
    } catch (e) {
      print('Cloudinary upload error: $e');
      throw Exception('Cloudinary upload error: $e');
    }
  }
}
