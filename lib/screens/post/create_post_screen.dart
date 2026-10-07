import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/constants.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/image_picker_widget.dart';
import 'widgets/availability_picker.dart';
import 'widgets/location_picker.dart';

/// Create-post screen — brings together title, description, image,
/// location (Places autocomplete), and full availability configuration.
///
/// For **Business** users the post is automatically linked to their
/// business page via `businessPageId`.
class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  File? _imageFile;
  PickedLocation? _location;
  AvailabilityData? _availability;

  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Submit ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    // Validate form fields
    if (!_formKey.currentState!.validate()) return;

    // Validate non-form inputs
    if (_imageFile == null) {
      _showError('Please add an image for your post.');
      return;
    }
    if (_location == null) {
      _showError('Please select a location.');
      return;
    }
    if (_availability == null) {
      _showError('Please configure the availability settings.');
      return;
    }

    setState(() => _loading = true);

    try {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user == null) throw Exception('Not authenticated.');

      final storage = ref.read(storageServiceProvider);
      final firestore = ref.read(firestoreServiceProvider);

      // 1. Determine businessPageId for Business users
      String? businessPageId;
      if (user.role == UserRole.business) {
        final bizPage = ref.read(myBusinessPageProvider).valueOrNull;
        businessPageId = bizPage?.id;
      }

      // 2. Create a placeholder post to get the auto-ID, then upload image
      final tempPost = Post.create(
        id: '', // will be overwritten
        authorUid: user.uid,
        role: user.role,
        businessPageId: businessPageId,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: '', // placeholder
        address: _location!.address,
        location: _location!.geoPoint,
        startDateTime: _availability!.startDateTime,
        endDateTime: _availability!.endDateTime,
        operatingHours: _availability!.operatingHours,
        unavailableDays: _availability!.unavailableDays,
      );

      // 3. Write the post document (with empty imageUrl for now)
      final postId = await firestore.createPost(tempPost);

      // 4. Upload the image and patch the document
      final imageUrl = await storage.uploadPostImage(
        postId: postId,
        file: _imageFile!,
      );
      await firestore.updatePost(postId, {'imageUrl': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created!')),
        );
        context.pop();
      }
    } catch (e) {
      _showError('Failed to create post: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ─── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(appUserProvider).valueOrNull;
    final isBusiness = user?.role == UserRole.business;

    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Business link badge ───────────────────────────
              if (isBusiness) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_rounded,
                          size: 18, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This post will be linked to your Business Page.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Image ────────────────────────────────────────
              ImagePickerWidget(
                pickedFile: _imageFile,
                onPicked: (f) => setState(() => _imageFile = f),
                height: 200,
                borderRadius: 16,
                placeholderIcon: Icons.image_rounded,
              ),
              const SizedBox(height: 20),

              // ── Title ────────────────────────────────────────
              CustomTextField(
                controller: _titleCtrl,
                label: 'Title',
                hint: 'Give your post a catchy title',
                prefixIcon: const Icon(Icons.title_rounded),
                validator: Validators.postTitle,
              ),
              const SizedBox(height: 14),

              // ── Description ──────────────────────────────────
              CustomTextField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Describe the experience, event, or service...',
                maxLines: 5,
                validator: Validators.description,
              ),
              const SizedBox(height: 20),

              // ── Location ─────────────────────────────────────
              LocationPickerWidget(
                initial: _location,
                onPicked: (loc) => setState(() => _location = loc),
              ),
              const SizedBox(height: 24),

              // ── Divider ──────────────────────────────────────
              Divider(
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 16),

              // ── Availability ─────────────────────────────────
              AvailabilityPickerWidget(
                initial: _availability,
                onChanged: (data) => _availability = data,
              ),

              const SizedBox(height: 32),

              // ── Submit ───────────────────────────────────────
              CustomButton(
                label: 'Publish Post',
                isLoading: _loading,
                onPressed: _submit,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
