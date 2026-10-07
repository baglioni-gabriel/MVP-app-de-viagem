import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../models/business_page_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Categories available for business pages.
const _categories = [
  'Hotel',
  'Restaurant',
  'Tour',
  'Bar & Nightlife',
  'Adventure',
  'Transport',
  'Shopping',
  'Other',
];

/// Create / edit business page form.
///
/// If [existingPage] is provided (via GoRouter `extra`), the form
/// opens in **edit** mode. Otherwise it creates a new page.
class EditBusinessPageScreen extends ConsumerStatefulWidget {
  final BusinessPage? existingPage;
  const EditBusinessPageScreen({super.key, this.existingPage});

  @override
  ConsumerState<EditBusinessPageScreen> createState() =>
      _EditBusinessPageScreenState();
}

class _EditBusinessPageScreenState
    extends ConsumerState<EditBusinessPageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _category = _categories.first;

  /// Existing gallery URLs (from Firestore).
  List<String> _existingPhotoUrls = [];

  /// Newly picked local files to upload.
  final List<File> _newPhotos = [];

  bool _loading = false;
  bool get _isEditing => widget.existingPage != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPage;
    if (p != null) {
      _nameCtrl.text = p.businessName;
      _descCtrl.text = p.description;
      _addressCtrl.text = p.address;
      _phoneCtrl.text = p.phoneNumber ?? '';
      _websiteCtrl.text = p.website ?? '';
      _category = p.category;
      _existingPhotoUrls = List.of(p.photoUrls);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  // ─── Gallery helpers ────────────────────────────────────────────────

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: StorageService.maxWidth,
      maxHeight: StorageService.maxHeight,
      imageQuality: StorageService.quality,
    );
    if (images.isNotEmpty) {
      setState(() {
        _newPhotos.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _removeExisting(int index) {
    setState(() => _existingPhotoUrls.removeAt(index));
  }

  void _removeNew(int index) {
    setState(() => _newPhotos.removeAt(index));
  }

  // ─── Save ───────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user == null) throw Exception('Not authenticated.');

      final storage = ref.read(storageServiceProvider);
      final firestore = ref.read(firestoreServiceProvider);

      if (_isEditing) {
        // Upload new photos
        final pageId = widget.existingPage!.id;
        final newUrls = await storage.uploadBusinessGalleryPhotos(
          pageId: pageId,
          files: _newPhotos,
        );

        final allUrls = [..._existingPhotoUrls, ...newUrls];

        await firestore.updateBusinessPage(pageId, {
          'businessName': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'category': _category,
          'address': _addressCtrl.text.trim(),
          'phoneNumber': _phoneCtrl.text.trim(),
          'website': _websiteCtrl.text.trim(),
          'photoUrls': allUrls,
        });
      } else {
        // Create new page
        final page = BusinessPage(
          id: '', // will be overridden by Firestore auto-ID
          ownerUid: user.uid,
          businessName: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          address: _addressCtrl.text.trim(),
          // TODO Phase 3: Use location picker for precise coordinates
          location: const GeoPoint(
            AppConstants.defaultLat,
            AppConstants.defaultLng,
          ),
          phoneNumber: _phoneCtrl.text.trim(),
          website: _websiteCtrl.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final pageId = await firestore.createBusinessPage(page);

        // Upload gallery photos
        if (_newPhotos.isNotEmpty) {
          final urls = await storage.uploadBusinessGalleryPhotos(
            pageId: pageId,
            files: _newPhotos,
          );
          await firestore.updateBusinessPage(pageId, {'photoUrls': urls});
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEditing
                  ? 'Business page updated!'
                  : 'Business page created!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Business Page' : 'Create Business Page'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Business name ──────────────────────────────
              CustomTextField(
                controller: _nameCtrl,
                label: 'Business Name',
                prefixIcon: const Icon(Icons.storefront_outlined),
                validator: Validators.businessName,
              ),
              const SizedBox(height: 14),

              // ── Category dropdown ──────────────────────────
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 14),

              // ── Description ────────────────────────────────
              CustomTextField(
                controller: _descCtrl,
                label: 'Description',
                hint: 'Tell travelers about your business...',
                maxLines: 4,
                validator: Validators.description,
              ),
              const SizedBox(height: 14),

              // ── Address ────────────────────────────────────
              CustomTextField(
                controller: _addressCtrl,
                label: 'Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: Validators.required,
              ),
              const SizedBox(height: 14),

              // ── Phone ──────────────────────────────────────
              CustomTextField(
                controller: _phoneCtrl,
                label: 'Phone (optional)',
                prefixIcon: const Icon(Icons.phone_outlined),
                keyboardType: TextInputType.phone,
                validator: Validators.phoneOptional,
              ),
              const SizedBox(height: 14),

              // ── Website ────────────────────────────────────
              CustomTextField(
                controller: _websiteCtrl,
                label: 'Website (optional)',
                prefixIcon: const Icon(Icons.language_rounded),
                keyboardType: TextInputType.url,
                validator: Validators.urlOptional,
              ),

              const SizedBox(height: 24),

              // ── Gallery ────────────────────────────────────
              Text('Gallery Photos',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),

              // Existing photos
              if (_existingPhotoUrls.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingPhotoUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _GalleryThumb(
                      child: Image.network(_existingPhotoUrls[i],
                          fit: BoxFit.cover, width: 100, height: 100),
                      onRemove: () => _removeExisting(i),
                    ),
                  ),
                ),
              if (_existingPhotoUrls.isNotEmpty && _newPhotos.isNotEmpty)
                const SizedBox(height: 8),

              // New picked photos
              if (_newPhotos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _newPhotos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _GalleryThumb(
                      child: Image.file(_newPhotos[i],
                          fit: BoxFit.cover, width: 100, height: 100),
                      onRemove: () => _removeNew(i),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _addPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Photos'),
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────
              CustomButton(
                label: _isEditing ? 'Save Changes' : 'Create Page',
                isLoading: _loading,
                onPressed: _save,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thumbnail with a remove button overlay.
class _GalleryThumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _GalleryThumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 100, height: 100, child: child),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
