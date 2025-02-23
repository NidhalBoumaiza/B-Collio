import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/chatbot_controller.dart';
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
  final ChatbotController chatbotController = Get.put(ChatbotController());
  final RxBool isSearching = false.obs;

  @override
  void initState() {
    super.initState();
    fetchConversations();

    userController.getToken().then((token) {
      if (token != null) {
        conversationController.startPolling(token);
      }
    });
    chatbotController.initializeChat();
  }

  void _showChatbotModal() {

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus(); // Dismiss keyboard when tapping outside
          },
          behavior: HitTestBehavior.opaque, // Ensures taps are captured everywhere
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.3,
            maxChildSize: 1.0,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return _buildChatbotModal(context, scrollController);
            },
          ),
        );
      },
    );
  }
  final textController = TextEditingController();
  Widget _buildChatbotModal(BuildContext context, ScrollController scrollController) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final modalHeight = screenHeight * 0.7;
    final focusNode = FocusNode();


    // Scroll to the bottom when the modal opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return Container(
      height: modalHeight,
      decoration: BoxDecoration(
        color: isDarkMode ? kDarkBgColor : kLightBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? kDarkPrimaryColor.withOpacity(0.8)
                        : kLightOrange7,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: Text("chat_bot_close".tr),
                ),
                ElevatedButton(
                  onPressed: chatbotController.clearConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode
                        ? kDarkPrimaryColor.withOpacity(0.8)
                        : kLightOrange7,
                    foregroundColor: isDarkMode ? Colors.black : Colors.white,
                  ),
                  child: Text("chat_bot_clear".tr),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              height: 2.0,
              width: double.infinity,
              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            Expanded(
              child: Obx(() {
                // Scroll to the bottom when messages update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.jumpTo(scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: scrollController, // Assign the controller here
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: chatbotController.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatbotController.messages[index];
                    final isUserMessage = message.startsWith("You: ");
                    final messageText = message.replaceFirst(RegExp(r'You: |AI: '), '');

                    return Align(
                      alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: isUserMessage
                              ? (isDarkMode ? kDarkPrimaryColor.withOpacity(0.8) : kLightOrange7)
                              : (isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          messageText,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isUserMessage
                                ? (isDarkMode ? Colors.black : Colors.white)
                                : (isDarkMode ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkBgColor.withOpacity(0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: textController,
                        focusNode: focusNode,
                        onChanged: (value) => chatbotController.userInput.value = value,
                        decoration: InputDecoration(
                          hintText: 'Tapez un message...'.tr,
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: BorderSide(
                              color: Colors.grey.withOpacity(0.5),
                              width: 1.0,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Obx(() {
                      return chatbotController.isLoading.value
                          ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: isDarkMode ? kDarkPrimaryColor : kLightOrange7,
                            strokeWidth: 4.0,
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(Icons.send, color: isDarkMode ? kDarkPrimaryColor : kLightOrange7),
                        onPressed: () async {
                          focusNode.unfocus();
                          textController.clear();
                          await chatbotController.sendMessage(chatbotController.userInput.value);

                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void fetchConversations() async {
    final token = await userController.getToken();
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
              return Row(
                children: [
                  IconButton(
                    splashRadius: 24,
                    onPressed: () => isSearching.value = true,
                    icon: const Icon(Icons.search, color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: _showChatbotModal,
                    child:
                    Lottie.asset(
                      'assets/json/robot.json',
                      width: 50,
                    ),
                  ),
                ],
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
        child:
        Lottie.asset(
          'assets/json/add.json',
          repeat: true,
        ),
      ),
    );
  }
}