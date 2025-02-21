import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/conversation_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/user_controller.dart';
import '../../themes/theme.dart';
import '../../widgets/base_widget/custom_search_bar.dart';
import '../../widgets/home/more_button.dart';
import '../chat/chat_list_screen.dart';
import '../contacts/all_contacts_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ThemeController themeController = Get.find<ThemeController>();
  final ConversationController conversationController =
      Get.put(ConversationController(conversationApiService: Get.find()));
  final UserController userController = Get.find<UserController>();

  final RxBool isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    fetchConversations();

    // Start polling for updates
    userController.getToken().then((token) {
      if (token != null) {
        conversationController.startPolling(token);
      }
    });
  }

/*
  @override
  void dispose() {
    conversationController.stopPolling();
    super.dispose();
  }
*/
  void fetchConversations() async {
    final token = await userController.getToken(); // Retrieve saved token
    if (token != null) {
      await conversationController.fetchConversations(token);
    } else {
      debugPrint('Error: Token is null. Unable to fetch conversations.');
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
        title: Obx(() {
          return isSearching.value
              ? CustomSearchBar(
                  hintText: "search_chats".tr,
                  onChanged: (query) async {
                    if (query.isEmpty) {
                      // Reset to the original list when the search query is cleared
                      final token = await userController.getToken();
                      if (token != null) {
                        await conversationController.fetchConversations(token);
                      }
                      conversationController.resumePolling();
                    } else {
                      final filtered = conversationController.conversations
                          .where((conversation) {
                        if (conversation.isGroup == true) {
                          return (conversation.name ?? '')
                              .toLowerCase()
                              .contains(query.toLowerCase());
                        } else {
                          final otherUser = conversation.users.firstWhereOrNull(
                            (user) =>
                                user.id != userController.currentUser.value?.id,
                          );
                          return (otherUser?.name ?? '')
                              .toLowerCase()
                              .contains(query.toLowerCase());
                        }
                      }).toList();

                      conversationController.conversations.value = filtered;
                      conversationController.stopPolling();
                    }
                  },
                  onBack: () async {
                    isSearching.value = false;
                    final token = await userController.getToken();
                    if (token != null) {
                      await conversationController.fetchConversations(token);
                    }
                    conversationController.resumePolling();
                  },
                )
              : Text(
                  "Chats".tr,
                  style:
                      theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                );
        }),
        actions: [
          Obx(() {
            if (!isSearching.value) {
              return IconButton(
                splashRadius: 24,
                onPressed: () => isSearching.value = true,
                icon: const Icon(Icons.search, color: Colors.white),
              );
            }
            return const SizedBox.shrink();
          }),
          if (!isSearching.value) const MoreButton(),
        ],
      ),
      body: ChatList(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor,
        onPressed: () {
          Get.to(() => AllContactsScreen());
        },
        child: Lottie.asset(
          'assets/json/add.json',
          repeat: true,
        ),
      ),
    );
  }
}
