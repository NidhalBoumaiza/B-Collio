import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../services/sms_verification_service.dart';
import '../../themes/theme.dart';
import '../../utils/misc.dart';
import '../../widgets/base_widget/custom_snack_bar.dart';
import '../../widgets/base_widget/primary_button.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({super.key});

  @override
  State<PhoneLoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<PhoneLoginPage> {
  final _userController = Get.find<UserController>();
  final _themeController = Get.find<ThemeController>();

  final _phoneController = TextEditingController();
  Country _selectedCountry = Country.worldWide;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = _themeController.isDarkMode;

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
        title: Text(
          "verify_phone".tr,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Lottie.asset('assets/json/phone_number.json'),
                  const SizedBox(height: 20),
                  Text(
                    "verification_message".tr,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  _buildPhoneNumberInput(theme, isDarkMode),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    title: "next".tr,
                    onPressed: _submitPhoneNumber,
                  ),
                ],
              ),
            ),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberInput(ThemeData theme, bool isDarkMode) {
    return Row(
      children: [
        GestureDetector(
          onTap: _pickCountry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor ??
                  (isDarkMode ? Colors.black12 : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: isDarkMode ? Colors.white30 : Colors.black26,
                  width: 1.5),
            ),
            child: Row(
              children: [
                Text(
                  _selectedCountry.flagEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  "+${_selectedCountry.phoneCode}",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(hintText: "phone_number_hint".tr),
          ),
        ),
      ],
    );
  }

  void _pickCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (country) => setState(() => _selectedCountry = country),
    );
  }

  void _submitPhoneNumber() async {
    final phoneNumber =
        "+${_selectedCountry.phoneCode}${_phoneController.text.trim()}";

    if (_phoneController.text.isEmpty || _phoneController.text.length < 6) {
      showSnackbar("Invalid phone number.");
      return;
    }

    final smsService = SmsVerificationService();
    final otp = smsService.generateOTP();
    final isOTPSent = await smsService.sendOTP(phoneNumber, otp);

    if (isOTPSent) {
      showSuccessSnackbar("OTP sent to $phoneNumber");
      Get.toNamed('/otpVerification',
          arguments: {'phoneNumber': phoneNumber, 'otp': otp});
    } else {
      showErrorSnackbar("Failed to send OTP. Please try again.");
    }
  }
}
