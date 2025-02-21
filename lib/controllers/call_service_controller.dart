import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../utils/zegocloud_constants.dart';

class CallServiceController extends GetxController {
  void initializeCallService(String userID, String userName) {
    ZegoUIKitPrebuiltCallInvitationService().init(
      appID: ZegoCloudConstants.appID,
      appSign: ZegoCloudConstants.appSign,
      userID: userID,
      userName: userName,
      plugins: [ZegoUIKitSignalingPlugin()],
    );
  }

  void deinitializeCallService() {
    ZegoUIKitPrebuiltCallInvitationService().uninit();
  }

  Widget getCallInvitationButton({
    required String targetUserID,
    required String targetUserName,
    required bool isVideoCall,
  }) {
    print ('/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/*/**/*/*/*/*/*/*/*/*/*/*/*');
    return ZegoSendCallInvitationButton(
      isVideoCall: isVideoCall,
      resourceID: "zegouikit_call",
      invitees: [ZegoUIKitUser(id: targetUserID, name: targetUserName)],
      buttonSize: const Size(40, 40),
      icon: ButtonIcon(
        icon: isVideoCall
            ? Image.asset('assets/3d_icons/video_icon.png',
                width: 30, height: 30)
            : Image.asset('assets/3d_icons/number_icon.png',
                width: 30, height: 30),
      ),
      iconSize: const Size(30, 30),
      text: '',
      clickableBackgroundColor: Colors.transparent,
      unclickableBackgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      borderRadius: 0,
      onPressed: (code, message, errorInvitees) async {
        print(
            'Call invitation result - Code: $code, Message: $message, Error Invitees: $errorInvitees');

        // Handle null or invalid code
        final parsedCode = int.tryParse(code ?? '');
        if (parsedCode == null) {
          return;
        }

        // Handle specific error codes
        switch (parsedCode) {
          case 0: // Success
            print('Call invitation sent successfully!');
            return;
          case -1: // Invitees list is empty
            _showErrorPopup(
              title: 'Call Failed',
              message: 'The user hasn\'t installed the app.',
            );
            return;
          case 107026: // User not registered
            _showErrorPopup(
              title: 'Call Failed',
              message: 'The user hasn\'t installed the app.',
            );
            return;
          default: // Other errors
            _showErrorPopup(
              title: 'Call Failed',
              message: 'The user hasn\'t installed the app.',
              //message ?? 'Failed to initiate the call. Error code: $parsedCode',
            );
        }
      },
    );
  }

  void _showErrorPopup({
    required String title,
    required String message,
    IconData icon = Iconsax.close_circle,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}
