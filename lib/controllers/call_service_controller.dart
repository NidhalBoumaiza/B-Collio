// lib/controllers/call_service_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../screens/chat/ChatRoom/call_page.dart';
import '../controllers/user_controller.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'conversation_controller.dart';

class CallServiceController extends GetxController {
  final UserController userController = Get.find<UserController>();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  final RxBool hasIncomingCall = false.obs;
  Map<String, dynamic>? incomingCallData;

  @override
  void onInit() {
    super.onInit();
    startPollingForCalls();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel();
    super.onClose();
  }

  Future<void> initiateCall({
    required String targetUserID,
    required String targetUserName,
    required String currentUserID,
    required String currentUserName,
    required bool isVideoCall,
    required String conversationId,
  }) async {
    print('initiateCall-------------------call   page ------ $targetUserID ==$currentUserID---$conversationId -$currentUserName ==$isVideoCall  ==$targetUserName ');
    Get.to(() => CallPage(
          localUserID: currentUserID,
          localUserName: currentUserName,
          targetUserID: targetUserID,
          targetUserName: targetUserName,
          roomID: conversationId,
          isVideoCall: isVideoCall,
          
        ));
  }

  Widget getCallInvitationButton({
    required String targetUserID,
    required String targetUserName,
    required String currentUserID,
    required String currentUserName,
    required bool isVideoCall,
    required String conversationId,
  }) {
    return IconButton(
      icon: Icon(
        isVideoCall ? Iconsax.video : Iconsax.call,
        color: Colors.white,
      ),
      onPressed: () => initiateCall(
        targetUserID: targetUserID,
        targetUserName: targetUserName,
        currentUserID: currentUserID,
        currentUserName: currentUserName,
        isVideoCall: isVideoCall,
        conversationId: conversationId,
      ),
    );
  }

  void startPollingForCalls() async {
    final currentUserId = userController.currentUser.value?.id ?? '';
    if (currentUserId.isEmpty) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final conversations = Get.find<ConversationController>().conversations;
      for (var conv in conversations) {
        final roomId = conv.id;
        final user = ZegoUser(
            currentUserId, userController.currentUser.value?.name ?? '');
        ZegoRoomConfig roomConfig = ZegoRoomConfig.defaultConfig()
          ..isUserStatusNotify = true;

        await ZegoExpressEngine.instance
            .loginRoom(roomId, user, config: roomConfig);
        await Future.delayed(const Duration(milliseconds: 500));
        await ZegoExpressEngine.instance.logoutRoom(roomId);
      }
    });
  }

  void onRoomUserUpdate(
      String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
    final currentUserId = userController.currentUser.value?.id ?? '';
    if (updateType == ZegoUpdateType.Add && !hasIncomingCall.value) {
      final caller =
          userList.firstWhereOrNull((user) => user.userID != currentUserId);
      if (caller != null) {
        hasIncomingCall.value = true;
        incomingCallData = {
          'caller_id': caller.userID,
          'caller_name': caller.userName,
          'conversation_id': roomID,
          'is_video_call': false, // Updated in CallPage
        };
        showIncomingCallNotification();
      }
    }
  }

  void showIncomingCallNotification() async {
    if (incomingCallData == null) return;

    final callerName = incomingCallData!['caller_name'];
    final conversationId = incomingCallData!['conversation_id'];
    final callerId = incomingCallData!['caller_id'];
    final isVideoCall = incomingCallData!['is_video_call'];

    const androidDetails = AndroidNotificationDetails(
      'call_channel',
      'Call Notifications',
      channelDescription: 'Incoming call notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
          'ringtone'), // From assets/sounds/ringtone.mp3
      fullScreenIntent: true,
      timeoutAfter: 30000, // Auto-cancel after 30 seconds
    );
    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Incoming ${isVideoCall ? 'Video' : 'Voice'} Call',
      'Call from $callerName',
      notificationDetails,
      payload: 'call_$conversationId$callerId$isVideoCall',
    );
  }

  void handleIncomingCall(
      String conversationId, String callerId, bool isVideoCall) {
    incomingCallData = {
      'caller_id': callerId,
      'caller_name': callerId, // Replace with actual name if available
      'conversation_id': conversationId,
      'is_video_call': isVideoCall,
    };
    Get.dialog(
      AlertDialog(
        title: Text('Incoming ${isVideoCall ? 'Video' : 'Voice'} Call'),
        content: Text('Call from $callerId'),
        actions: [
          TextButton(
            onPressed: () {
              hasIncomingCall.value = false;
              incomingCallData = null;
              flutterLocalNotificationsPlugin.cancel(0);
              Get.back();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () {
              hasIncomingCall.value = false;
              incomingCallData = null;
              flutterLocalNotificationsPlugin.cancel(0);
              Get.back();
              Get.to(() => CallPage(
                    localUserID: userController.currentUser.value?.id ?? '',
                    localUserName: userController.currentUser.value?.name ?? '',
                    targetUserID: callerId,
                    targetUserName:
                        callerId, // Replace with actual name if available
                    roomID: conversationId,
                    isVideoCall: isVideoCall,
                  ));
            },
            child: const Text('Accept'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
