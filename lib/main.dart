import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/contact_controller.dart';
import 'controllers/conversation_controller.dart';
import 'controllers/language_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/user_controller.dart';
import 'i18n/app_translation.dart';
import 'routes.dart';
import 'screens/chat/ChatRoom/chat_room_screen.dart';
import 'services/contact_api_service.dart';
import 'services/conversation_api_service.dart';
import 'services/local_storage_service.dart';
import 'services/message_api_service.dart';
import 'services/user_api_service.dart';
import 'themes/theme.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize services and controllers
  final localStorageService = LocalStorageService();
  await localStorageService.init();
  Get.put(localStorageService);

  Get.put(UserController(userApiService: UserApiService()));
  Get.put(ContactController(contactApiService: ContactApiService()));
  Get.put(ThemeController());
  Get.put(LanguageController());
  Get.put(ConversationApiService());
  Get.put(MessageApiService());
  Get.put(NotificationController());

  // Initialize theme and language settings
  await Get.find<ThemeController>().initializeTheme();
  await Get.find<LanguageController>().initializeLanguage();

  // Initialize notification settings
  final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  final initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload != null) {
        final conversationController = Get.find<ConversationController>();
        final userController = Get.find<UserController>();
        final token = await userController.getToken();

        if (token != null && token.isNotEmpty) {
          await conversationController.refreshConversations(token);

          // Find the conversation by ID
          final conversation = conversationController.conversations.firstWhere(
            (c) => c.id == payload,
            orElse: () => throw Exception('Conversation not found'),
          );

          final currentUserId = userController.currentUser.value?.id;
          // Retrieve user details from the conversation
          final otherUser = conversation.users.firstWhere(
            (user) => user.id != currentUserId, // Correct comparison
            orElse: () => throw Exception('Other user not found'),
          );

          // Navigate to the ChatRoomPage
          Get.to(() => ChatRoomPage(
                conversationId: conversation.id,
                name: otherUser.name,
                phoneNumber: otherUser.phoneNumber ?? '',
                avatarUrl: otherUser.image,
                createdAt: otherUser.createdAt,
              ));
        }
      }
    },
  );

  // Request notification permission
  await Get.find<NotificationController>().requestNotificationPermission();
  // Request contacts permission
  await Get.find<ContactController>().requestContactsPermission();

  // Initialize ZegoUIKit and run the app
  ZegoUIKit().initLog().then((_) {
    // Set up ZegoUIKitPrebuiltCallInvitationService
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

    // Enable system calling UI
    ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
      [ZegoUIKitSignalingPlugin()],
    );

    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final ThemeController themeController = Get.find<ThemeController>();
  final LanguageController languageController = Get.find<LanguageController>();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        translations: AppTranslation(),
        locale: languageController.selectedLocale.value,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: themeController.themeMode.value,
        getPages: Routes.routes,
        builder: (BuildContext context, Widget? child) {
          return Stack(
            children: [
              child!,
              ZegoUIKitPrebuiltCallMiniOverlayPage(
                contextQuery: () {
                  return navigatorKey.currentState!.context;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
