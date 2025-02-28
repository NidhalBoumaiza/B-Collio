// lib/main.dart
import 'package:bcalio/screens/chat/ChatRoom/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'controllers/call_service_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/conversation_controller.dart';
import 'controllers/language_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/user_controller.dart';
import 'i18n/app_translation.dart';
import 'routes.dart';
import 'services/contact_api_service.dart';
import 'services/conversation_api_service.dart';
import 'services/local_storage_service.dart';
import 'services/message_api_service.dart';
import 'services/user_api_service.dart';
import 'themes/theme.dart';
import 'utils/zegocloud_constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initializeZegoEngine() async {
  await ZegoExpressEngine.createEngineWithProfile(
    ZegoEngineProfile(
      ZegoCloudConstants.appID,
      ZegoScenario.Default,
      appSign: ZegoCloudConstants.appSign,
    ),
  ).then((value) => debugPrint('ZegoEngine created-----------')).onError(
      (e, stackTrace) => debugPrint('Failed to create ZegoEngine: $e'));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeZegoEngine();

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
  Get.put(CallServiceController());

  await Get.find<ThemeController>().initializeTheme();
  await Get.find<LanguageController>().initializeLanguage();

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload != null) {
        if (payload.startsWith('call_')) {
          final callController = Get.find<CallServiceController>();
          final parts = payload.split('_');
          final conversationId = parts[1];
          final callerId = parts[2];
          final isVideoCall = parts[3] == 'true';
          callController.handleIncomingCall(
              conversationId, callerId, isVideoCall);
        } else {
          final conversationController = Get.find<ConversationController>();
          final userController = Get.find<UserController>();
          final token = await userController.getToken();
          if (token != null && token.isNotEmpty) {
            await conversationController.refreshConversations(token);
            final conversation =
                conversationController.conversations.firstWhere(
              (c) => c.id == payload,
              orElse: () => throw Exception('Conversation not found'),
            );
            final currentUserId = userController.currentUser.value?.id;
            final otherUser = conversation.users.firstWhere(
              (user) => user.id != currentUserId,
              orElse: () => throw Exception('Other user not found'),
            );
            Get.to(() => ChatRoomPage(
                  conversationId: conversation.id,
                  name: otherUser.name,
                  phoneNumber: otherUser.phoneNumber ?? '',
                  avatarUrl: otherUser.image,
                  createdAt: otherUser.createdAt,
                ));
          }
        }
      }
    },
  );

  await Get.find<NotificationController>().requestNotificationPermission();
  await Get.find<ContactController>().requestContactsPermission();
  await requestPermission();
  runApp(MyApp());
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
        builder: (context, child) => child!,
      ),
    );
  }
}

Future<void> requestPermission() async {
  await [Permission.camera, Permission.microphone].request();
}
