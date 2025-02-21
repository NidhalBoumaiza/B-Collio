import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../controllers/user_controller.dart';
import '../../themes/theme.dart';
import '../../utils/misc.dart';
import '../../widgets/base_widget/input_field.dart';
import '../../widgets/base_widget/otp_loading_indicator.dart';
import '../../widgets/base_widget/primary_button.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final UserController userController = Get.find<UserController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  RxBool isPasswordVisible = false.obs;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Obx(() {
      final isLoading = userController.isLoading.value;

      return Stack(
        children: [
          Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
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
              elevation: 0,
              title: Text(
                'Create Profile'.tr, // Translated text
                style:
                    theme.textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Instruction Text
                      Center(
                        child: Text(
                          "Fill in the details below to create your profile."
                              .tr, // Translated text
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Name Input
                      StyledInputField(
                        controller: nameController,
                        label: 'Name'.tr, // Translated text
                        hint: 'Enter your name'.tr, // Translated text
                        imagePath: "assets/3d_icons/user_icon.png",
                      ),
                      const SizedBox(height: 20),

                      // Email Input
                      StyledInputField(
                        controller: emailController,
                        label: 'Email'.tr, // Translated text
                        hint: 'Enter your email'.tr, // Translated text
                        imagePath: "assets/3d_icons/email_icon.png",
                        inputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),

                      // Password Input
                      StyledInputField(
                        controller: passwordController,
                        label: 'Password'.tr, // Translated text
                        hint: 'Enter your password'.tr, // Translated text
                        imagePath: "assets/3d_icons/password_icon.png",
                        inputType: TextInputType.visiblePassword,
                        trailing: Obx(
                          () => IconButton(
                            icon: Icon(isPasswordVisible.value
                                ? Iconsax.eye
                                : Iconsax.eye_slash),
                            onPressed: () {
                              isPasswordVisible.value =
                                  !isPasswordVisible.value;
                            },
                          ),
                        ),
                        obscureText: !isPasswordVisible.value,
                      ),
                      const SizedBox(height: 40),

                      // Submit Button
                      PrimaryButton(
                        title: 'Create Profile'.tr, // Translated text
                        onPressed: _finishProfileCreation,
                      ),

                      const SizedBox(height: 20),

                      // Additional Note
                      Center(
                        child: Text(
                          "By creating a profile, you agree to our Terms & Conditions."
                              .tr, // Translated text
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isLoading) const OtpLoadingIndicator(),
        ],
      );
    });
  }

  void _finishProfileCreation() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phoneNumber = Get.arguments['phoneNumber'];

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showSnackbar("Please fill all fields".tr); // Translated text
      return;
    }

    // Initiate registration
    await userController.registerWithAvatar(
      email: email,
      password: password,
      name: name,
      phoneNumber: phoneNumber,
    );

    if (userController.currentUser.value != null) {
      Get.offAllNamed('/login');
    }
  }
}
