import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class AttachmentOptions extends StatelessWidget {
  final void Function(File) onAttachImage;
  final void Function() onStartRecording;

  const AttachmentOptions({
    super.key,
    required this.onAttachImage,
    required this.onStartRecording,
  });

  void _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      onAttachImage(File(pickedFile.path));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Image.asset(
              "assets/3d_icons/image_icon.png",
              width: 30,
              height: 30,
            ),
            title: Text("attach_image".tr, style: theme.textTheme.bodyLarge),
            onTap: () => _pickImage(context),
          ),
          const Divider(),
          ListTile(
            leading: Image.asset(
              "assets/3d_icons/record_icon.png",
              width: 30,
              height: 30,
            ),
            title: Text("record_voice_message".tr,
                style: theme.textTheme.bodyLarge),
            onTap: () {
              onStartRecording(); // Delegate to controller
              Navigator.pop(context); // Close the modal
            },
          ),
        ],
      ),
    );
  }
}
