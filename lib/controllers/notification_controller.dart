import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationController extends GetxController {
  RxBool isPermissionGranted = false.obs;
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadNotificationPreference(); // Load the notification preference
    _checkNotificationPermission(); // Check permission at initialization
  }

  // Request notification permission
  Future<void> requestNotificationPermission() async {
    isLoading.value = true;
    final status = await Permission.notification.request();
    if (status.isGranted) {
      isPermissionGranted.value = true;
      await _saveNotificationPreference(true);
    } else {
      isPermissionGranted.value = false;
      await _saveNotificationPreference(false);
    }
    isLoading.value = false; // Update loading state
  }

  // Check if notification permission is already granted
  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    isPermissionGranted.value = status.isGranted;
    await _saveNotificationPreference(isPermissionGranted.value);
    isLoading.value = false;
  }

  // Save notification preference to SharedPreferences
  Future<void> _saveNotificationPreference(bool isGranted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationPermissionGranted', isGranted);
  }

  // Load notification preference from SharedPreferences
  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    isPermissionGranted.value =
        prefs.getBool('isNotificationPermissionGranted') ?? false;
  }
}
