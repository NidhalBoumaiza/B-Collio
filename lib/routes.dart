import 'package:get/get.dart';
import 'screens/authentication/create_profile.dart';
import 'screens/authentication/login_screen.dart';
import 'screens/authentication/phone_login_screen.dart';
import 'screens/authentication/otp_verification_screen.dart';
import 'screens/authentication/welcome_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/group_chat/create_group_chat_screen.dart';
import 'screens/contacts/Add_Contact_screen.dart';
import 'screens/contacts/all_contacts_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/settings/update_profile_screen.dart';

class Routes {
  // Route Names
  static const String start = '/';
  static const String phonelogin = '/PhoneLogin';
  static const String otpVerification = '/otpVerification';
  static const String createProfile = '/createProfile';
  static const String login = '/login';
  static const String home = '/home';
  static const String chat = "/chat";
  static const String createGroup = '/createGroup';
  static const String allContactsScreen = '/allContactsScreen';
  static const String addContactScreen = '/addContactScreen';
  static const String updateProfile = '/updateProfile';

  // Pages
  static final routes = [
    GetPage(name: start, page: () => WelcomePage()),
    GetPage(name: phonelogin, page: () => PhoneLoginPage()),
    GetPage(name: otpVerification, page: () => OTPVerificationPage()),
    GetPage(name: createProfile, page: () => CreateProfilePage()),
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: chat, page: () => ChatList()),
    GetPage(name: createGroup, page: () => CreateGroupChatScreen()),
    GetPage(name: allContactsScreen, page: () => AllContactsScreen()),
    GetPage(name: addContactScreen, page: () => AddContactScreen()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: updateProfile, page: () => UpdateProfileScreen()),
  ];
}
