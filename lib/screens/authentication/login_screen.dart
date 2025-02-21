import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/user_controller.dart';
import '../../utils/misc.dart';
import '../../widgets/base_widget/input_field.dart';
import '../../widgets/base_widget/otp_loading_indicator.dart';
import '../../widgets/base_widget/primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final UserController userController = Get.find<UserController>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isPasswordVisible = false;

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
            body: SafeArea(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Lottie.asset(
                              isDarkMode
                                  ? 'assets/json/user_dark.json'
                                  : 'assets/json/user.json',
                              width: 200,
                            ),
                            Text(
                              'Welcome Back!'.tr,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Login to your account'.tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      StyledInputField(
                        controller: emailController,
                        label: 'Email'.tr,
                        hint: 'Enter your email'.tr,
                        imagePath: "assets/3d_icons/email_icon.png",
                        inputType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      StyledInputField(
                        controller: passwordController,
                        label: 'Password'.tr,
                        hint: 'Enter your password'.tr,
                        imagePath: "assets/3d_icons/password_icon.png",
                        inputType: TextInputType.visiblePassword,
                        trailing: IconButton(
                          icon: Icon(
                            isPasswordVisible ? Iconsax.eye : Iconsax.eye_slash,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                        obscureText: !isPasswordVisible,
                      ),
                      /* const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Forgot Password Logic
                            debugPrint('Forgot Password');
                          },
                          child: Text(
                            'Forgot Password?'.tr,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),*/
                      const SizedBox(height: 40),
                      PrimaryButton(
                        title: 'Login'.tr,
                        onPressed: () async {
                          final email = emailController.text.trim();
                          final password = passwordController.text.trim();

                          if (email.isEmpty || password.isEmpty) {
                            showSnackbar("Error,Please fill in all fields.".tr);
                            return;
                          }

                          await userController.login(email, password);

                          // Save credentials after successful login
                          await userController.saveCredentials(email, password);
                        },
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?".tr,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Get.toNamed('/PhoneLogin');
                              },
                              child: Text(
                                'Sign Up'.tr,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
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
}
