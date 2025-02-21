import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:typewritertext/typewritertext.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';
import '../../widgets/base_widget/primary_button.dart';
import '../../controllers/user_controller.dart';
import '../../services/local_storage_service.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final UserController userController = Get.find<UserController>();
  final LocalStorageService localStorageService =
      Get.find<LocalStorageService>();

  bool isLoading = true; // Flag to manage the loading state

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  // Attempt Auto-Login on App Start
  Future<void> _attemptAutoLogin() async {
    await userController.autoLogin(); // Try auto-login if credentials exist
    setState(() {
      isLoading =
          false; // Once the login process is complete, hide the loading state
    });

    if (userController.currentUser.value != null) {
      // If the user is logged in, navigate to the home page
      Get.offAllNamed('/home');
    } else {
      // Do nothing (no auto-redirect to login page)
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // App Logo with Animation
              WidgetAnimator(
                incomingEffect:
                    WidgetTransitionEffects.incomingSlideInFromTop(),
                atRestEffect: WidgetRestingEffects.swing(),
                child: Image.asset(
                  "assets/img/logo.png",
                  width: 200,
                  height: 200,
                ),
              ),

              const SizedBox(height: 20),

              // Animated Description
              TypeWriter.text(
                "welcome_message".tr, // Translated text
                duration: const Duration(milliseconds: 50),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Features Section
              Column(
                children: [
                  _buildFeatureItem(
                    theme: theme,
                    imagePath:
                        "assets/3d_icons/lock_icon.png", // Path to the image asset
                    title: "feature_secure_title".tr,
                    description: "feature_secure_description".tr,
                    incomingEffect:
                        WidgetTransitionEffects.incomingSlideInFromLeft(),
                    atRestEffect: WidgetRestingEffects.size(),
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    theme: theme,
                    imagePath:
                        "assets/3d_icons/phone_icon.png", // Path to the image asset
                    title: "feature_support_title".tr,
                    description: "feature_support_description".tr,
                    incomingEffect:
                        WidgetTransitionEffects.incomingSlideInFromLeft(),
                    atRestEffect: WidgetRestingEffects.wave(),
                  ),
                  const SizedBox(height: 20),
                  _buildFeatureItem(
                    theme: theme,
                    imagePath:
                        "assets/3d_icons/group_icon.png", // Path to the image asset
                    title: "feature_connected_title".tr,
                    description: "feature_connected_description".tr,
                    incomingEffect:
                        WidgetTransitionEffects.incomingSlideInFromLeft(),
                    atRestEffect: WidgetRestingEffects.slide(),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Agree and Continue Button (Only show if no user is logged in and not in loading state)
              if (!isLoading && userController.currentUser.value == null)
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    title: "agree_and_continue".tr,
                    onPressed: () {
                      Get.toNamed(
                          '/login'); // Navigate to the login page manually
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // Footer
              Text(
                "footer_powered_by".tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required ThemeData theme,
    required String imagePath, // Path to the image asset
    required String title,
    required String description,
    required WidgetTransitionEffects incomingEffect,
    required WidgetRestingEffects atRestEffect,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WidgetAnimator(
          incomingEffect: incomingEffect,
          atRestEffect: atRestEffect,
          child: Image.asset(
            imagePath, // Load image from assets
            width: 48, // Adjust the size as needed
            height: 48, // Adjust the size as needed
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
