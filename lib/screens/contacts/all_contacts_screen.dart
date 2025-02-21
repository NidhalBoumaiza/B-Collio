import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/contact_controller.dart';
import '../../controllers/conversation_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/contact_model.dart';
import '../../models/true_user_model.dart';
import '../../services/contact_api_service.dart';
import '../../services/sms_verification_service.dart';
import '../../themes/theme.dart';
import '../../widgets/base_widget/custom_loading_indicator.dart';
import '../../widgets/base_widget/custom_search_bar.dart';
import '../../widgets/base_widget/custom_snack_bar.dart';
import '../../widgets/base_widget/no_search_found.dart';
import '../../widgets/contacts/contact_list_tile.dart';
import '../chat/ChatRoom/chat_room_screen.dart';

//worked
class AllContactsScreen extends StatefulWidget {
  const AllContactsScreen({super.key});

  @override
  State<AllContactsScreen> createState() => _AllContactsScreenState();
}

class _AllContactsScreenState extends State<AllContactsScreen> {
  final ContactController contactController = Get.put(
    ContactController(contactApiService: ContactApiService()),
  );

  final ConversationController conversationController =
      Get.find<ConversationController>();

  final UserController userController = Get.find<UserController>();

  final RxBool isLoading = false.obs;

  // Store the original API and phone contacts separately
  final RxList<Contact> originalApiContacts = <Contact>[].obs;
  final RxList<Contact> originalPhoneContacts = <Contact>[].obs;

  // Initialize the SMS service
  final SmsVerificationService smsService = SmsVerificationService();

  RxList<Contact> mappedPhoneContacts = <Contact>[].obs;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    final token = await userController.getToken();
    if (token == null || token.isEmpty) {
      Get.snackbar("Error", "Failed to retrieve token. Please log in again.");
      return;
    }

    try {
      isLoading.value = true;

      // Load cached contacts first
      await contactController.loadCachedContacts();

      // Fetch API contacts if not already cached
      if (contactController.originalApiContacts.isEmpty) {
        await contactController.fetchContacts(token);
      }

      // Fetch phone contacts if not already cached
      if (contactController.originalPhoneContacts.isEmpty) {
        final phoneContacts = await contactController.fetchPhoneContacts();
        contactController.originalPhoneContacts.assignAll(phoneContacts);
      }

      // Combine API and phone contacts, ensuring no duplicates
      final uniquePhoneContacts =
          contactController.originalPhoneContacts.where((phoneContact) {
        final normalizedPhoneNumber =
            normalizePhoneNumber(phoneContact.phoneNumber ?? '');
        return !contactController.originalApiContacts.any((apiContact) =>
            normalizePhoneNumber(apiContact.phoneNumber ?? '') ==
            normalizedPhoneNumber);
      }).toList();

      contactController.contacts.assignAll(
          [...contactController.originalApiContacts, ...uniquePhoneContacts]);

      // Debug logs
      debugPrint(
          'Original API Contacts: ${contactController.originalApiContacts.length}');
      debugPrint(
          'Original Phone Contacts: ${contactController.originalPhoneContacts.length}');
      debugPrint('Unique Phone Contacts: ${uniquePhoneContacts.length}');
      debugPrint('Final Contacts: ${contactController.contacts.length}');
    } catch (e) {
      Get.snackbar('Error', 'Failed to retrieve contacts. Please try again.');
      debugPrint('Error fetching contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Normalizes a phone number by removing all non-numeric characters.
  String normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> navigateToChatRoom(
    String contactId,
    String name,
    String phoneNumber,
    String? avatarUrl,
  ) async {
    final token = await userController.getToken();
    if (token == null || token.isEmpty) {
      Get.snackbar("Error", "Failed to retrieve token. Please log in again.");
      return;
    }

    try {
      isLoading.value = true;

      final existingConversation =
          conversationController.conversations.isNotEmpty
              ? conversationController.conversations.firstWhereOrNull(
                  (conversation) =>
                      conversation.userIds.contains(contactId) &&
                      conversation.messages.isNotEmpty,
                )
              : null;

      if (existingConversation != null) {
        final otherUser = existingConversation.users.firstWhere(
          (user) => user.id == contactId,
          orElse: () => throw Exception("User not found in conversation."),
        );

        isLoading.value = false;
        Get.to(() => ChatRoomPage(
              name: name,
              phoneNumber: phoneNumber,
              avatarUrl: avatarUrl,
              conversationId: existingConversation.id,
              createdAt: otherUser.createdAt,
            ));
        return;
      }

      await conversationController.createConversation(
        token: token,
        userId: contactId,
      );

      await conversationController.refreshConversations(token);

      final newConversation = conversationController.conversations.firstWhere(
        (conversation) => conversation.userIds.contains(contactId),
        orElse: () => throw Exception("Conversation not found."),
      );

      final otherUser = newConversation.users.firstWhere(
        (user) => user.id == contactId,
        orElse: () => throw Exception("User not found in conversation."),
      );

      isLoading.value = false;
      Get.to(
        () => ChatRoomPage(
          name: name,
          phoneNumber: phoneNumber,
          avatarUrl: avatarUrl,
          conversationId: newConversation.id,
          createdAt: otherUser.createdAt,
        ),
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar("Error", "Failed to navigate to chat room: $e");
      debugPrint('Error navigating to ChatRoomPage: $e');
    }
  }

  Future<void> _handleAddContact(Contact contact) async {
    try {
      isLoading.value = true;

      final token = await userController.getToken();
      if (token == null || token.isEmpty) {
        showErrorSnackbar("Failed to retrieve token. Please log in again.");
        return;
      }

      // Fetch users to check if the phone number exists
      final users = await userController.fetchUsers(token);
      final user = users.firstWhere(
        (user) =>
            normalizePhoneNumber(user.phoneNumber ?? '') ==
            normalizePhoneNumber(contact.phoneNumber ?? ''),
        orElse: () => User(
          id: '',
          email: '',
          name: '',
          image: '',
          phoneNumber: null,
        ),
      );

      if (user.id.isNotEmpty) {
        // If user exists, add them as a contact
        await contactController.addContact(
          token,
          user.id,
          user.name,
          user.phoneNumber ?? '',
          user.email,
        );

        // Navigate to chat room after adding the contact
        await navigateToChatRoom(
          user.id,
          user.name,
          user.phoneNumber ?? '',
          user.image,
        );
      } else {
        // If user does not exist, send an SMS invitation
        final message = "We are inviting you to bcalio, check it out";
        final success = await smsService.sendMessage(
          contact.phoneNumber ?? '',
          message,
        );

        if (success) {
          showSuccessSnackbar("Success, Invitation sent to ${contact.name}");
        } else {
          showErrorSnackbar(
              "Error, Failed to send invitation to ${contact.name}");
        }
      }
    } catch (e) {
      debugPrint('Error handling add contact: $e');
      showErrorSnackbar("Failed to handle add contact: $e");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
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
        title: Text(
          "All Contacts".tr,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.user_add, color: Colors.white),
            onPressed: () {
              Get.offNamed('/addContactScreen');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    "Search for a contact or select one from the list below.".tr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomSearchBar(
                    hintText: "Search Contacts".tr,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        contactController.contacts.assignAll([
                          ...originalApiContacts,
                          ...originalPhoneContacts,
                        ]);
                      } else {
                        final filteredApiContacts =
                            originalApiContacts.where((contact) {
                          return contact.name
                                  .toLowerCase()
                                  .contains(query.toLowerCase()) ||
                              (contact.phoneNumber ?? '')
                                  .toLowerCase()
                                  .contains(query.toLowerCase());
                        }).toList();

                        final filteredPhoneContacts =
                            originalPhoneContacts.where((contact) {
                          return contact.name
                                  .toLowerCase()
                                  .contains(query.toLowerCase()) ||
                              (contact.phoneNumber ?? '')
                                  .toLowerCase()
                                  .contains(query.toLowerCase());
                        }).toList();

                        contactController.contacts.assignAll([
                          ...filteredApiContacts,
                          ...filteredPhoneContacts,
                        ]);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Obx(() {
                      if (isLoading.value) {
                        return Center(child: CustomLoadingIndicator());
                      }

                      if (contactController.contacts.isEmpty) {
                        return NoSearchFound(
                          message: "No contacts found.".tr,
                        );
                      }

                      return ListView.separated(
                        itemCount: contactController.contacts.length,
                        separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final contact = contactController.contacts[index];

                          final contactName = contact.name.isNotEmpty
                              ? contact.name
                              : "No Name Available";

                          final contactPhoneNumber =
                              contact.phoneNumber?.isNotEmpty == true
                                  ? contact.phoneNumber!
                                  : "No Phone Number";

                          final isPhoneContact =
                              contactController.originalPhoneContacts.any(
                            (phoneContact) => phoneContact.id == contact.id,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ContactListTile(
                              name: contactName,
                              phoneNumber: contactPhoneNumber,
                              avatarUrl: contact.image,
                              onTap: () => navigateToChatRoom(
                                contact.id,
                                contact.name,
                                contactPhoneNumber,
                                contact.image,
                              ),
                              trailing: isPhoneContact
                                  ? IconButton(
                                      icon: const Icon(Iconsax.user_add),
                                      onPressed: () async {
                                        await _handleAddContact(contact);
                                      },
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
