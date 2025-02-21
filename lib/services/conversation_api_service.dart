import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/conversation_model.dart';
import '../utils/misc.dart';

class ConversationApiService {
  /// Fetch Conversations
  Future<List<Conversation>> getConversations(String token) async {
    final url = Uri.parse('$baseUrl/mobile/conversations');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      //debugPrint('API Response: ${response.body}');
      final List<dynamic> conversationsJson = json.decode(response.body);
      final conversations = conversationsJson
          .map((json) => Conversation.fromJson(json as Map<String, dynamic>))
          .toList();
      //debugPrint('Parsed Conversations: $conversations');
      return conversations;
    } else {
      throw Exception('Failed to fetch conversations: ${response.body}');
    }
  }

  /// Create Conversation
  Future<Conversation> createConversation({
    required String token,
    required bool isGroup,
    required String userId, // Expecting userId for 1-on-1 conversations
  }) async {
    final url = Uri.parse('$baseUrl/mobile/conversations');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'isGroup': isGroup,
          'userId': userId, // Pass userId for the 1-on-1 conversation
        }),
      );

      //debugPrint('Create Conversation Response Status: ${response.statusCode}');
      //debugPrint('Create Conversation Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Conversation.fromJson(json.decode(response.body));
      } else {
        debugPrint('Error: ${response.body}');
        throw Exception(
            'Failed to create conversation. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception: $e');
      throw Exception('An error occurred while creating the conversation.');
    }
  }

  /// Create Group Conversation
  Future<Conversation> createGroupConversation({
    required String token,
    required String name,
    String? logo, // Optional group logo
    required List<String> memberIds, // List of user IDs
  }) async {
    final url = Uri.parse('$baseUrl/mobile/conversations');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'isGroup': true,
          'name': name,
          'logo': logo,
          'members': memberIds.map((id) => {'value': id}).toList(),
        }),
      );

     // debugPrint('Create Group Response Status: ${response.statusCode}');
      //debugPrint('Create Group Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Conversation.fromJson(json.decode(response.body));
      } else {
        debugPrint('Error: ${response.body}');
        throw Exception(
            'Failed to create group conversation. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception in createGroupConversation: $e');
      throw Exception(
          'An error occurred while creating the group conversation.');
    }
  }

  /// Mark Conversation as Seen
  Future<Conversation> markConversationAsSeen({
    required String token,
    required String conversationId,
  }) async {
    final url = Uri.parse('$baseUrl/mobile/conversations/$conversationId/seen');

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

     // debugPrint('Mark Conversation As Seen Status: ${response.statusCode}');
     // debugPrint('Mark Conversation As Seen Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['id'] != null) {
          return Conversation.fromJson(jsonResponse);
        } else {
          throw Exception('Invalid response: Missing conversation ID.');
        }
      } else {
        throw Exception(
            'Failed to mark conversation as seen. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception in markConversationAsSeen: $e');
      throw Exception(
          'An error occurred while marking the conversation as seen.');
    }
  }

  ///Delete conversation by id
  Future<void> deleteConversation({
    required String token,
    required String conversationId,
  }) async {
    final url = Uri.parse('$baseUrl/mobile/conversations/$conversationId');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-type': 'application/json',
        },
      );
     // debugPrint('Delete Conversation Status:${response.statusCode}');
     // debugPrint('Delete Conversation Body:${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Failed to delete conversation.Status: ${response.statusCode},Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception in deleteConversation:$e');
      throw Exception('An error occurred while deleting the conversation ');
    }
  }
}
