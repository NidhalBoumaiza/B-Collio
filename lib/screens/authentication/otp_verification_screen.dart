import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/theme.dart';
import '../../widgets/base_widget/otp_loading_indicator.dart';
import '../../widgets/base_widget/primary_button.dart';
import '../../widgets/base_widget/custom_snack_bar.dart';

class OTPVerificationPage extends StatefulWidget {
  const OTPVerificationPage({super.key});

  @override
  State<OTPVerificationPage> createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final ThemeController themeController = Get.find<ThemeController>();

  final TextEditingController _pinController = TextEditingController();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.onSurface),
        color: theme.scaffoldBackgroundColor,
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
      ),
    );

    return Scaffold(
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
        centerTitle: true,
        title: Text(
          "otp_verification".tr, // Translated text
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    "verify_phone".tr, // Translated text
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Text(
                    "enter_otp_message".tr, // Translated text
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Pinput for OTP
                  Pinput(
                    controller: _pinController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    validator: (pin) {
                      if (pin?.length == 6) return null;
                      return "Invalid OTP";
                    },
                    pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                    onCompleted: (pin) {
                      debugPrint("Completed: $pin");
                    },
                  ),
                  const SizedBox(height: 20),

                  // Clear Code Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _clearOTPFields,
                      child: Text(
                        "clear_code".tr, // Translated text
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Verify Button
                  PrimaryButton(
                    title: "verify".tr, // Translated text
                    onPressed: _verifyOTP,
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
          if (_loading) const OtpLoadingIndicator(),
        ],
      ),
    );
  }

  void _clearOTPFields() {
    _pinController.clear();
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  Future<void> _verifyOTP() async {
    final enteredOtp = _pinController.text.trim();
    final expectedOtp =
        Get.arguments['otp']; // Retrieve the OTP passed during navigation

    if (enteredOtp == expectedOtp) {
      showSuccessSnackbar("OTP Verified Successfully");
      Get.toNamed('/createProfile',
          arguments: {'phoneNumber': Get.arguments['phoneNumber']});
    } else {
      showErrorSnackbar("Invalid OTP. Please try again.");
    }
  }
}
