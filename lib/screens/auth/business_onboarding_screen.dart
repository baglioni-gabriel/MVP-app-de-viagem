import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/constants.dart';
import '../../models/business_page_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/wayv_logo.dart';

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

/// Step-by-step business onboarding wizard.
///
/// Designed to be simple and didactic, guiding business owners
/// through 4 clear steps:
///   1. Business name & category
///   2. Description
///   3. Location & contact
///   4. Gallery photos (optional)
///
/// Each step has helper text explaining what to fill in.
class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final _pageCtrl = PageController();
  int _currentStep = 0;
  static const _totalSteps = 4;

  // Form keys per step
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  String _category = _categories.first;

  // Photos
  final List<File> _photos = [];

  bool _loading = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  // ─── Navigation ─────────────────────────────────────────────────────

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _step1Key.currentState?.validate() ?? false;
      case 1:
        return _step2Key.currentState?.validate() ?? false;
      case 2:
        return _step3Key.currentState?.validate() ?? false;
      case 3:
        return true; // photos are optional
      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── Photo picking ──────────────────────────────────────────────────

  Future<void> _addPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(
      maxWidth: StorageService.maxWidth,
      maxHeight: StorageService.maxHeight,
      imageQuality: StorageService.quality,
    );
    if (images.isNotEmpty) {
      setState(() {
        _photos.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  // ─── Submit ─────────────────────────────────────────────────────────

  Future<void> _submit() async {
    setState(() => _loading = true);

    try {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user == null) throw Exception('Not authenticated.');

      final storage = ref.read(storageServiceProvider);
      final firestore = ref.read(firestoreServiceProvider);

      final page = BusinessPage(
        id: '',
        ownerUid: user.uid,
        businessName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        address: _addressCtrl.text.trim(),
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
      if (_photos.isNotEmpty) {
        final urls = await storage.uploadBusinessGalleryPhotos(
          pageId: pageId,
          files: _photos,
        );
        await firestore.updateBusinessPage(pageId, {'photoUrls': urls});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Business page created! Welcome to Wayv.'),
          ),
        );
        // Navigation will be handled by the router redirect
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
        title: const WayvLogo(height: 28),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // ── Progress indicator ───────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _stepTitle(_currentStep),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.primary
                        .withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(
                        theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),

          // ── Page content ────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(theme),
                _buildStep2(theme),
                _buildStep3(theme),
                _buildStep4(theme),
              ],
            ),
          ),

          // ── Bottom button ───────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: CustomButton(
              label: _currentStep < _totalSteps - 1
                  ? 'Continue'
                  : 'Create My Business Page',
              isLoading: _loading,
              onPressed: _nextStep,
              icon: _currentStep < _totalSteps - 1
                  ? Icons.arrow_forward_rounded
                  : Icons.check_rounded,
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) => switch (step) {
        0 => 'Basic Info',
        1 => 'Description',
        2 => 'Location & Contact',
        3 => 'Gallery',
        _ => '',
      };

  // ─── Step 1: Name & Category ────────────────────────────────────────

  Widget _buildStep1(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.storefront_rounded,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              "What's your business called?",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a name that travelers will easily recognize. '
              'This is the first thing they\'ll see.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameCtrl,
              label: 'Business Name',
              hint: 'e.g. Sunset Beach Hotel',
              prefixIcon: const Icon(Icons.badge_outlined),
              validator: Validators.businessName,
            ),
            const SizedBox(height: 20),
            Text(
              'What category fits best?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _category == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _category = cat),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Description ────────────────────────────────────────────

  Widget _buildStep2(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Tell travelers about your business',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Describe your services, what makes you special, '
              'and why travelers should visit you. The more detail, '
              'the better!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _descCtrl,
              label: 'Description',
              hint: 'We are a family-run hotel with ocean views...',
              maxLines: 8,
              validator: Validators.description,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3: Location & Contact ─────────────────────────────────────

  Widget _buildStep3(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Where can travelers find you?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your address so travelers can calculate '
              'how long it takes to reach you.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _addressCtrl,
              label: 'Address',
              hint: 'Rua das Flores, 123 — São Paulo',
              prefixIcon: const Icon(Icons.location_on_outlined),
              validator: Validators.required,
            ),
            const SizedBox(height: 20),

            // Optional contact info
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Phone and website are optional, but help travelers '
                      'contact you directly.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneCtrl,
              label: 'Phone (optional)',
              hint: '+55 11 98765-4321',
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
              validator: Validators.phoneOptional,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              controller: _websiteCtrl,
              label: 'Website (optional)',
              hint: 'https://mybusiness.com',
              prefixIcon: const Icon(Icons.language_rounded),
              keyboardType: TextInputType.url,
              validator: Validators.urlOptional,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 4: Gallery ────────────────────────────────────────────────

  Widget _buildStep4(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Show off your space',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Photos are the best way to attract travelers! '
            'Add your best shots. You can always add more later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tip: Photos of the entrance, interior, and '
                    'popular spots work great!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Photo grid
          if (_photos.isNotEmpty) ...[
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _photos[i],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(i),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Add photos button
          OutlinedButton.icon(
            onPressed: _addPhotos,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(_photos.isEmpty ? 'Add Photos' : 'Add More Photos'),
          ),

          if (_photos.isEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'You can skip this step and add photos later.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
