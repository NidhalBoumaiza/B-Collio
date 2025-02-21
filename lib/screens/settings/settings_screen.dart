import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../themes/theme.dart';
import '../../widgets/settings/contacts_section.dart';
import '../../widgets/settings/notifications_section.dart';
import '../../widgets/settings/profile_section.dart';
import '../../widgets/settings/theme_section.dart';
import '../../widgets/settings/language_section.dart';
import '../../widgets/settings/logout_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          "settings".tr,
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProfileSection(),
            const SizedBox(height: 20),
            const NotificationSection(),
            const SizedBox(height: 20),
            const ContactsSectionSection(),
            const SizedBox(height: 20),
            const ThemeSection(),
            const SizedBox(height: 20),
            const LanguageSection(),
            const SizedBox(height: 20),
            const LogoutButton(),
          ],
        ),
      ),
    );
  }
}
