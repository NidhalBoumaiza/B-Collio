import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../models/true_user_model.dart';
import '../services/user_api_service.dart';
import '../utils/misc.dart';
import '../utils/zegocloud_constants.dart';

class UserController extends GetxController {
  final UserApiService userApiService;

  UserController({required this.userApiService});

  Rx<User?> currentUser = Rx<User?>(null);
  RxBool isLoading = false.obs;

  // Save token to SharedPreferences
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    debugPrint('Token saved: $token');
  }

  // Retrieve token from SharedPreferences
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Save email and password to SharedPreferences
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    await prefs.setString('password', password);
    debugPrint('Credentials saved: $email, $password');
  }

  // Retrieve email and password from SharedPreferences
  Future<Map<String, String?>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');
    return {'email': email, 'password': password};
  }

  // Login User
  Future<void> login(String email, String password) async {
    isLoading.value = true;
    try {
      final authResponse =
          await userApiService.login(email: email, password: password);
      currentUser.value = authResponse.user;

      // Save token for future requests
      await _saveToken(authResponse.token);
      debugPrint('Login successful.');

      // Initialize ZegoUIKitPrebuiltCallInvitationService after successful login
      await _initializeZegoCallKit(authResponse.user);

      // Navigate to Home Page
      Get.offAllNamed('/home');
    } catch (e) {
      debugPrint('Login error: $e');
      showSnackbar("Please check your credentials".tr);
    } finally {
      isLoading.value = false;
    }
  }

  // Initialize ZegoUIKitPrebuiltCallInvitationService
  Future<void> _initializeZegoCallKit(User user) async {
    try {
      // Initialize ZegoUIKitPrebuiltCallInvitationService
      debugPrint(
          "Initializing ZegoUIKitPrebuiltCallInvitationService for user: ${user.id}");
      ZegoUIKitPrebuiltCallInvitationService().init(
        appID: ZegoCloudConstants.appID,
        appSign: ZegoCloudConstants.appSign,
        userID: user.id, // Use the logged-in user's ID
        userName: user.name, // Use the logged-in user's name
        plugins: [ZegoUIKitSignalingPlugin()],
      );

      debugPrint('ZegoUIKitPrebuiltCallInvitationService initialized.');
    } catch (e) {
      debugPrint('Failed to initialize Zego Call Kit: $e');
    }
  }

  // Logout User
  Future<void> logout() async {
    try {
      // Clear token and user credentials, but retain language and theme preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('email');
      await prefs.remove('password');
      currentUser.value = null;

      // Deinitialize ZegoUIKitPrebuiltCallInvitationService
      ZegoUIKitPrebuiltCallInvitationService().uninit();
      debugPrint('ZegoUIKitPrebuiltCallInvitationService deinitialized.');

      debugPrint('Logout successful.');

      // Navigate to Login Page
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('Logout error: $e');
      Get.snackbar('Error', 'Failed to log out. Please try again.');
    }
  }

  Future<String?> getUserId() async {
    return currentUser.value?.id;
  }

  Future<void> registerWithAvatar({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    File? avatar,
  }) async {
    isLoading.value = true;

    try {
      String? imageUrl;

      // Upload avatar to Cloudinary if available
      if (avatar != null) {
        imageUrl = await userApiService.uploadImageToCloudinary(avatar);
      } else {
        debugPrint('No avatar selected, proceeding without an image.');
      }

      // Complete registration with the avatar URL
      final user = await userApiService.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
      );

      currentUser.value = user;
      debugPrint('Register successful. User details: $user');

      // Navigate to Login Page
      Get.offAllNamed('/login');
    } catch (e) {
      debugPrint('Register error: $e');
      showSnackbar("User already exist".tr);
    } finally {
      isLoading.value = false;
    }
  }

  // Method to retrieve and login automatically
  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (email != null && password != null) {
      await login(email, password); // Attempt auto-login
    }
  }

  Future<void> updateProfile({
    required String name,
    required String image,
    required String about,
  }) async {
    isLoading.value = true;

    try {
      final updatedUser = await userApiService.updateProfile(
        name: name,
        image: image,
        about: about,
      );

      currentUser.value = updatedUser;
      debugPrint('Profile updated successfully: $updatedUser');
    } catch (e) {
      debugPrint('Profile update error: $e');
      Get.snackbar('Error', 'Failed to update profile. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch Users
  Future<List<User>> fetchUsers(String token) async {
    try {
      return await userApiService.fetchUsers(token);
    } catch (e) {
      Get.snackbar('Error', e.toString());
      return [];
    }
  }

  // Debugging: Print Current User Info
  void debugUserInfo() {
    debugPrint('Current User:');
    debugPrint('Name: ${currentUser.value?.name}');
    debugPrint('Email: ${currentUser.value?.email}');
    debugPrint('Phone: ${currentUser.value?.phoneNumber}');
    debugPrint('Image: ${currentUser.value?.image}');
  }
}
