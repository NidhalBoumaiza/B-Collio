import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/user_controller.dart';
import '../../themes/theme.dart';
import '../../widgets/base_widget/custom_snack_bar.dart';
import '../../widgets/base_widget/input_field.dart';
import '../../widgets/base_widget/primary_button.dart';
import '../../widgets/base_widget/otp_loading_indicator.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final UserController userController = Get.find<UserController>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields with the current user's data
    final user = userController.currentUser.value;
    nameController.text = user?.name ?? '';
    aboutController.text = user?.about ?? '';
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    final name = nameController.text.trim();
    final about = aboutController.text.trim();

    // Handle optional image upload
    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await userController.userApiService
          .uploadImageToCloudinary(selectedImage!);
    } else {
      imageUrl =
          userController.currentUser.value?.image; // Keep the current image
    }

    // Call the update profile method
    final (success, statusCode) = await userController.updateProfile(
      name: name.isNotEmpty ? name : userController.currentUser.value?.name ??
          '',
      image: imageUrl ?? '',
      about: about.isNotEmpty ? about : userController.currentUser.value
          ?.about ?? '',
    );

    // Navigate back to the previous screen
    if (success && statusCode == 200) {
      Get.back(); // Only navigate back on success
      showSuccessSnackbar("Profile updated successfully.".tr);
    } else {
      showErrorSnackbar("Failed to update profile please try again later.".tr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Obx(() {
      final isLoading = userController.isLoading.value;

      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
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
                  'Update Profile'.tr,
                  style:
                      theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Profile Picture
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: selectedImage != null
                                    ? FileImage(selectedImage!)
                                    : userController.currentUser.value?.image !=
                                            null
                                        ? NetworkImage(userController
                                            .currentUser.value!.image!)
                                        : null,
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                child: selectedImage == null &&
                                        userController
                                                .currentUser.value?.image ==
                                            null
                                    ? Icon(
                                        Iconsax.user,
                                        size: 50,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                              ),
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    theme.appBarTheme.backgroundColor,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Instruction Text
                      Center(
                        child: Text(
                          "Update your profile details below.".tr,
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
                        label: 'Name'.tr,
                        hint: 'Enter your name'.tr,
                        imagePath: "assets/3d_icons/user_icon.png",
                      ),
                      const SizedBox(height: 20),

                   /*// About Input
                      StyledInputField(
                        controller: aboutController,
                        label: 'About'.tr,
                        hint: 'Tell us about yourself'.tr,
                        imagePath: "assets/3d_icons/about_icon.png",
                      ),*/
                      const SizedBox(height: 40),

                      // Update Button
                      PrimaryButton(
                        title: 'Update Profile'.tr,
                        onPressed: _updateProfile,
                      ),

                      const SizedBox(height: 20),

                      // Additional Note
                      Center(
                        child: Text(
                          "Changes will be reflected immediately.".tr,
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
            if (isLoading) const OtpLoadingIndicator(),
          ],
        ),
      );
    });
  }
}
