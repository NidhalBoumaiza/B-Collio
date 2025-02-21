import 'dart:convert';

import 'package:contacts_service/contacts_service.dart' as phone_contacts;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact_model.dart';
import '../services/contact_api_service.dart';
import '../widgets/base_widget/custom_snack_bar.dart';

class ContactController extends GetxController {
  final ContactApiService contactApiService;
  RxBool isPermissionGranted = false.obs;
  RxBool isLoading = false.obs;

  ContactController({required this.contactApiService});

  RxList<Contact> contacts = <Contact>[].obs;
  RxList<Contact> originalApiContacts = <Contact>[].obs; // Store API contacts
  RxList<Contact> originalPhoneContacts =
      <Contact>[].obs; // Store phone contacts

  @override
  void onInit() {
    super.onInit();
    _loadContactPermissionPreference();
    _checkContactsPermission();
    loadCachedContacts(); // Load cached contacts on initialization
  }

  // Load cached contacts from local storage
  Future<void> loadCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedContacts = prefs.getString('cachedContacts');

    if (cachedContacts != null) {
      debugPrint('Loading contacts from cache...');
      final List<dynamic> jsonList = jsonDecode(cachedContacts);
      final allContacts =
          jsonList.map((json) => Contact.fromJson(json)).toList();

      // Separate API and phone contacts
      originalApiContacts.assignAll(
          allContacts.where((contact) => !contact.isPhoneContact).toList());
      originalPhoneContacts.assignAll(
          allContacts.where((contact) => contact.isPhoneContact).toList());

      // Combine API and phone contacts, ensuring no duplicates
      contacts.assignAll([...originalApiContacts, ...originalPhoneContacts]);

      debugPrint('Cached API contacts loaded: ${originalApiContacts.length}');
      debugPrint(
          'Cached phone contacts loaded: ${originalPhoneContacts.length}');
    } else {
      debugPrint('No cached contacts found.');
    }
  }

  // Save both API and phone contacts to cache
  Future<void> _saveContactsToCache() async {
    final prefs = await SharedPreferences.getInstance();
    final allContacts = [...originalApiContacts, ...originalPhoneContacts];
    final jsonList = allContacts.map((contact) => contact.toJson()).toList();
    prefs.setString('cachedContacts', jsonEncode(jsonList));
    debugPrint('All contacts saved to cache: ${allContacts.length}');
  }

  Future<void> requestContactsPermission() async {
    isLoading.value = true;
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      isPermissionGranted.value = true;
      await _saveContactPermissionPreference(true);
    } else {
      isPermissionGranted.value = false;
      await _saveContactPermissionPreference(false);
    }
    isLoading.value = false;
  }

  Future<void> _checkContactsPermission() async {
    final status = await Permission.contacts.status;
    isPermissionGranted.value = status.isGranted;
    await _saveContactPermissionPreference(isPermissionGranted.value);
  }

  Future<void> _saveContactPermissionPreference(bool isGranted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isContactsPermissionGranted', isGranted);
  }

  Future<void> _loadContactPermissionPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isPermissionGranted.value =
        prefs.getBool('isContactsPermissionGranted') ?? false;
  }

  Future<void> fetchContacts(String token) async {
    isLoading.value = true;
    try {
      final fetchedContacts = await contactApiService.getContacts(token);
      originalApiContacts.assignAll(fetchedContacts);

      // Save fetched contacts to cache
      await _saveContactsToCache();
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Contact>> fetchPhoneContacts() async {
    if (!isPermissionGranted.value) {
      Get.snackbar('Permission Required', 'Contacts permission is not granted');
      return [];
    }
    try {
      final phoneContacts = await phone_contacts.ContactsService.getContacts();
      final mappedContacts = phoneContacts.map((phoneContact) {
        return Contact(
          id: phoneContact.identifier ?? '',
          name: phoneContact.displayName ?? '',
          email: '',
          image: phoneContact.avatar != null && phoneContact.avatar!.isNotEmpty
              ? 'data:image/jpeg;base64,${phoneContact.avatar}'
              : null,
          phoneNumber: phoneContact.phones?.isNotEmpty == true
              ? phoneContact.phones!.first.value ?? ''
              : '',
          isPhoneContact: true, // Mark as phone contact
        );
      }).toList();

      // Save phone contacts to cache
      originalPhoneContacts.assignAll(mappedContacts);
      await _saveContactsToCache();

      return mappedContacts;
    } catch (e) {
      debugPrint("Error fetching phone contacts: $e");
      return [];
    }
  }

  Future<void> addContact(String token, String contactId, String name,
      String phone, String? email) async {
    try {
      // Check if the contact already exists in the contacts list
      final existingContact = contacts.firstWhere(
        (contact) => contact.id == contactId,
        orElse: () => Contact(
          id: '',
          name: '',
          email: '',
          image: null,
          phoneNumber: null,
        ),
      );

      if (existingContact.id.isNotEmpty) {
        // If the contact already exists, show a snackbar
        showSuccessSnackbar("Contact already added");
        return;
      }

      // Add contact to API
      final newContact = await contactApiService.addContact(token, contactId);
      originalApiContacts.add(newContact);

      // Update the cache with the new contact
      await _saveContactsToCache();

      // Add contact to phone's native contact list
      await addContactToPhone(name, phone, email);

      showSuccessSnackbar("Contact added successfully!");
    } catch (e) {
      debugPrint('Error adding contact: $e');
      if (e.toString().contains('Contact already added')) {
        showSuccessSnackbar("Contact already added");
      } else {
        Get.snackbar('Error', e.toString());
      }
    }
  }

  Future<void> addContactToPhone(
      String name, String phone, String? email) async {
    try {
      // Request permission
      final status = await Permission.contacts.request();
      if (!status.isGranted) {
        throw Exception("Permission denied");
      }

      // Create the contact
      final contact = phone_contacts.Contact(
        givenName: name,
        phones: [phone_contacts.Item(label: "mobile", value: phone)],
        emails: email != null
            ? [phone_contacts.Item(label: "work", value: email)]
            : [],
      );

      // Add contact to phonebook
      await phone_contacts.ContactsService.addContact(contact);
    } catch (e) {
      throw Exception("Failed to add contact to phone: $e");
    }
  }
}
