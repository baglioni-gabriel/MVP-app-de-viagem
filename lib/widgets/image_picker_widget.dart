import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/storage_service.dart';

/// Reusable image-picker widget.
///
/// Shows the current image (or a placeholder) and offers camera / gallery
/// options via a bottom sheet. Returns the picked [File] through [onPicked].
class ImagePickerWidget extends StatelessWidget {
  /// Current image URL (network) to display.
  final String? currentImageUrl;

  /// Currently picked local file (takes priority over [currentImageUrl]).
  final File? pickedFile;

  /// Called with the picked file when the user selects an image.
  final ValueChanged<File> onPicked;

  /// Widget dimensions.
  final double width;
  final double height;

  /// Border radius for the container.
  final double borderRadius;

  /// Icon shown when no image is present.
  final IconData placeholderIcon;

  const ImagePickerWidget({
    super.key,
    this.currentImageUrl,
    this.pickedFile,
    required this.onPicked,
    this.width = double.infinity,
    this.height = 180,
    this.borderRadius = 16,
    this.placeholderIcon = Icons.add_a_photo_rounded,
  });

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      maxWidth: StorageService.maxWidth,
      maxHeight: StorageService.maxHeight,
      imageQuality: StorageService.quality,
    );

    if (xFile != null) {
      onPicked(File(xFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine what to show: local file → network URL → placeholder
    Widget content;
    if (pickedFile != null) {
      content = Image.file(pickedFile!, fit: BoxFit.cover,
          width: width, height: height);
    } else if (currentImageUrl != null && currentImageUrl!.isNotEmpty) {
      content = Image.network(currentImageUrl!, fit: BoxFit.cover,
          width: width, height: height);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(placeholderIcon, size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('Tap to add photo',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              )),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            // Camera overlay icon (bottom-right)
            if (pickedFile != null || (currentImageUrl?.isNotEmpty ?? false))
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit_rounded, size: 18,
                      color: theme.colorScheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
