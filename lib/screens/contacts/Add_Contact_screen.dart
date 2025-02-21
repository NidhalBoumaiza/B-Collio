import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:easy_stepper/easy_stepper.dart';
import '../../controllers/contact_controller.dart';
import '../../controllers/user_controller.dart';
import '../../models/contact_model.dart';
import '../../models/true_user_model.dart';
import '../../themes/theme.dart';
import '../../widgets/base_widget/custom_loading_indicator.dart';
import '../../widgets/base_widget/custom_snack_bar.dart';

class AddContactScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool isPhoneNumberValid = false.obs;
  final RxBool isNameFieldEnabled = true.obs;
  final RxString fetchedName = ''.obs;
  final RxInt currentStep = 0.obs; // Track the current step

  final UserController userController = Get.find<UserController>();
  final ContactController contactController = Get.find<ContactController>();

  AddContactScreen({super.key});

  Future<void> checkPhoneNumber(String phone) async {
    if (phone.isEmpty) {
      isPhoneNumberValid.value = false;
      isNameFieldEnabled.value = true;
      fetchedName.value = '';
      return;
    }

    final token = await userController.getToken();
    if (token == null || token.isEmpty) {
      showErrorSnackbar("token_error".tr);
      return;
    }

    isLoading.value = true;
    try {
      final users = await userController.fetchUsers(token);
      final user = users.firstWhere(
        (user) => user.phoneNumber == phone,
        orElse: () => User(
          id: '',
          email: '',
          name: '',
          image: '',
          phoneNumber: null,
        ),
      );

      if (user.id.isNotEmpty) {
        // If phone number exists, disable the name field and pre-fill the name
        isPhoneNumberValid.value = true;
        isNameFieldEnabled.value = false;
        fetchedName.value = user.name;
        nameController.text = user.name;
      } else {
        // If phone number does not exist, enable the name field
        isPhoneNumberValid.value = false;
        isNameFieldEnabled.value = true;
        fetchedName.value = '';
        nameController.clear();
      }
    } catch (e) {
      showErrorSnackbar("phone_check_error".tr + e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkAndAddContact() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      showErrorSnackbar("empty_phone_error".tr);
      return;
    }

    if (isNameFieldEnabled.value && name.isEmpty) {
      showErrorSnackbar("empty_name_error".tr);
      return;
    }

    isLoading.value = true;
    try {
      final token = await userController.getToken();
      if (token == null || token.isEmpty) {
        showErrorSnackbar("token_error".tr);
        return;
      }

      // Fetch users to check if the phone number exists
      final users = await userController.fetchUsers(token);
      final user = users.firstWhere(
        (user) => user.phoneNumber == phone,
        orElse: () => User(
          id: '',
          email: '',
          name: '',
          image: '',
          phoneNumber: null,
        ),
      );

      if (user.id.isNotEmpty) {
        // If user exists, check if the contact is already added
        final existingContact = contactController.contacts.firstWhere(
          (contact) => contact.id == user.id,
          orElse: () => Contact(
            id: '',
            name: '',
            email: '',
            image: null,
            phoneNumber: null,
          ),
        );

        if (existingContact.id.isNotEmpty) {
          // If the contact already exists, show a snackbar
          showSuccessSnackbar("contact_already_added".tr);
        } else {
          // If user exists, add them as a contact using their ID
          await contactController.addContact(
            token,
            user.id,
            user.name,
            user.phoneNumber ?? '',
            user.email,
          );
          showSuccessSnackbar("contact_added_success".tr);
        }
      } else {
        // If user does not exist, add the contact to the phone's native contact list
        await contactController.addContactToPhone(name, phone, '');
        showSuccessSnackbar("contact_added_to_phone".tr);
      }

      Get.offNamed('/allContactsScreen');
    } catch (e) {
      debugPrint('Error adding contact: $e');
      if (e.toString().contains('Contact already added')) {
        showSuccessSnackbar("contact_already_added".tr);
      } else {
        showErrorSnackbar("contact_add_error".tr + e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
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
        title: Text(
          "add_contact".tr,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          // Wrap the Column in a SingleChildScrollView
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Vertical Stepper
              Obx(() {
                return EasyStepper(
                  activeStep: currentStep.value,
                  direction: Axis.vertical,
                  stepRadius: 20, // Increased size
                  activeStepTextColor: theme.colorScheme.primary,
                  finishedStepTextColor: Colors.green,
                  activeStepIconColor: theme.colorScheme.primary,
                  finishedStepIconColor: Colors.green,
                  showLoadingAnimation: false,
                  steps: [
                    EasyStep(
                      icon:
                          const Icon(Iconsax.call, size: 24), // Iconsax call icon
                      title: 'step_1'.tr,
                      finishIcon:
                          const Icon(Iconsax.tick_circle), // Iconsax tick icon
                      customStep: CircleAvatar(
                        radius: 20, // Increased size
                        backgroundColor: currentStep.value >= 0
                            ? theme.appBarTheme.backgroundColor
                            : Colors.grey,
                        child: const Icon(Iconsax.call,
                            color: Colors.white), // Iconsax call icon
                      ),
                    ),
                    EasyStep(
                      icon:
                          const Icon(Iconsax.user, size: 24), // Iconsax user icon
                      title: 'step_2'.tr,
                      finishIcon:
                          const Icon(Iconsax.tick_circle), // Iconsax tick icon
                      customStep: CircleAvatar(
                        radius: 20, // Increased size
                        backgroundColor: currentStep.value >= 1
                            ? theme.appBarTheme.backgroundColor
                            : Colors.grey,
                        child: const Icon(Iconsax.user,
                            color: Colors.white), // Iconsax user icon
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Step Content
              Obx(() {
                if (currentStep.value == 0) {
                  return _buildPhoneNumberStep(theme);
                } else {
                  return _buildNameStep(theme);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneNumberStep(ThemeData theme) {
    return Column(
      children: [
        Text(
          "enter_phone_number".tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "phone_number_description".tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: "phone_number".tr,
            hintText: "enter_phone_hint".tr,
            prefixIcon: const Icon(Iconsax.call), // Iconsax call icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => checkPhoneNumber(value),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            if (phoneController.text.isNotEmpty) {
              currentStep.value = 1;
            } else {
              showErrorSnackbar("empty_phone_error".tr);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.appBarTheme.backgroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "next".tr,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep(ThemeData theme) {
    return Column(
      children: [
        Text(
          "enter_name".tr,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "name_description".tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Obx(() {
          return TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "name".tr,
              hintText: "enter_name_hint".tr,
              prefixIcon: const Icon(Iconsax.user), // Iconsax user icon
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              enabled: isNameFieldEnabled.value,
            ),
          );
        }),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                currentStep.value = 0;
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "back".tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: checkAndAddContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.appBarTheme.backgroundColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "save".tr,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
