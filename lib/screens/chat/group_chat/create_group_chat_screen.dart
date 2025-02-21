import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../controllers/group_chat_controller.dart';
import '../../../themes/theme.dart';
import '../../../widgets/base_widget/custom_loading_indicator.dart';
import '../../../widgets/base_widget/custom_search_bar.dart';
import '../../../widgets/base_widget/no_search_found.dart';
import '../../../widgets/base_widget/otp_loading_indicator.dart';
import '../../../widgets/contacts/group/ContactTileGroup.dart';
import '../../../widgets/contacts/group/group_details_dialog.dart';
import '../../../widgets/base_widget/primary_button.dart';

class CreateGroupChatScreen extends StatelessWidget {
  final GroupChatController controller = Get.put(GroupChatController());

  CreateGroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    return Obx(() {
      return Stack(
        children: [
          Scaffold(
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
              title: Text("Create Group Chat".tr),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Iconsax.arrow_left),
                onPressed: () => Get.back(),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Obx(() {
                if (controller.isFetchingContacts.value) {
                  // Show contacts loading indicator
                  return Center(child: CustomLoadingIndicator());
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      "Select contacts to create a group chat.".tr,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search Bar
                    CustomSearchBar(
                      hintText: "Search Contacts".tr,
                      onChanged: (query) => controller.searchContacts(query),
                    ),
                    const SizedBox(height: 16),

                    // Contacts List
                    Expanded(
                      child: Obx(() {
                        if (controller.filteredContacts.isEmpty) {
                          return NoSearchFound(
                            message: "No contacts match your search.".tr,
                          );
                        }

                        return ListView.builder(
                          itemCount: controller.filteredContacts.length,
                          itemBuilder: (context, index) {
                            final contact = controller.filteredContacts[index];

                            return Obx(() {
                              final isSelected =
                                  controller.selectedContacts.contains(contact);

                              return ContactTileGroup(
                                name: contact.name,
                                phoneNumber: contact.phoneNumber ?? 'N/A',
                                avatarUrl: contact.image,
                                isSelected: isSelected,
                                onTap: () =>
                                    controller.toggleSelection(contact),
                              );
                            });
                          },
                        );
                      }),
                    ),

                    // Create Group Button
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Obx(() {
                          final hasSelectedContacts =
                              controller.selectedContacts.length >= 2;

                          return SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              title: "Create Group".tr,
                              onPressed: hasSelectedContacts
                                  ? () async => await showGroupDetailsDialog(
                                        context: context,
                                        controller: controller,
                                      )
                                  : null,
                              isDisabled: !hasSelectedContacts,
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          // Full-Screen Loader for Group Creation
          if (controller.isLoading.value)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: OtpLoadingIndicator(),
              ),
            ),
        ],
      );
    });
  }
}
