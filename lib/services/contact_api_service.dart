import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/contact_model.dart';
import '../utils/misc.dart';

class ContactApiService {
  /// Fetch Contacts
  Future<List<Contact>> getContacts(String token) async {
    final url = Uri.parse('$baseUrl/mobile/contacts/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> contactsJson = json.decode(response.body);
      return contactsJson.map((json) => Contact.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch contacts: ${response.body}');
    }
  }

  /// Add Contact
  Future<Contact> addContact(String token, String contactId) async {
    final url = Uri.parse('$baseUrl/mobile/contacts');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'contactId': contactId}),
    );

    debugPrint('Add Contact Response Status: ${response.statusCode}');
    debugPrint('Add Contact Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody == null) {
        throw Exception('API response is null');
      }

      // Handle the case where the API returns a message
      if (responseBody.containsKey('message')) {
        debugPrint('API Message: ${responseBody['message']}');
        if (responseBody['message'] == 'Contact already added') {
          // Treat this as a success case
          return Contact(
            id: contactId,
            name: '',
            email: '',
            image: null,
            phoneNumber: null,
          );
        } else {
          throw Exception(responseBody['message']);
        }
      }

      // Handle the case where the API returns a contact object
      if (responseBody.containsKey('contact')) {
        final jsonData = responseBody['contact'];
        return Contact.fromJson(jsonData);
      } else {
        throw Exception('Invalid API response: Missing "contact" key');
      }
    } else {
      throw Exception('Failed to add contact: ${response.body}');
    }
  }
}
