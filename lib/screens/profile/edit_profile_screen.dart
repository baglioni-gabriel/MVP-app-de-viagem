import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/image_picker_widget.dart';

/// Edit-profile screen — lets the user change their display name
/// and profile photo.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  File? _pickedPhoto;
  bool _loading = false;
  bool _initialised = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialised) return;
    final user = ref.read(appUserProvider).valueOrNull;
    if (user != null) {
      _nameCtrl.text = user.displayName;
      _initialised = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = ref.read(appUserProvider).valueOrNull;
      if (user == null) throw Exception('User not found.');

      final updates = <String, dynamic>{
        'displayName': _nameCtrl.text.trim(),
      };

      // Upload photo if changed
      if (_pickedPhoto != null) {
        final url = await ref.read(storageServiceProvider).uploadProfilePhoto(
              uid: user.uid,
              file: _pickedPhoto!,
            );
        updates['photoUrl'] = url;
      }

      updates['updatedAt'] = Timestamp.now();

      await ref.read(firestoreServiceProvider).updateUser(user.uid, updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
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

  @override
  Widget build(BuildContext context) {
    _initFields();
    final user = ref.watch(appUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ── Photo picker ─────────────────────────────────
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: ImagePickerWidget(
                    currentImageUrl: user?.photoUrl,
                    pickedFile: _pickedPhoto,
                    onPicked: (file) =>
                        setState(() => _pickedPhoto = file),
                    width: 120,
                    height: 120,
                    borderRadius: 60,
                    placeholderIcon: Icons.person_add_alt_1_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Name field ───────────────────────────────────
              CustomTextField(
                controller: _nameCtrl,
                label: 'Display Name',
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required.'
                    : null,
              ),
              const SizedBox(height: 12),

              // ── Email (read-only) ────────────────────────────
              CustomTextField(
                label: 'Email',
                hint: user?.email ?? '',
                prefixIcon: const Icon(Icons.email_outlined),
                readOnly: true,
              ),

              const SizedBox(height: 32),

              // ── Save button ──────────────────────────────────
              CustomButton(
                label: 'Save Changes',
                isLoading: _loading,
                onPressed: _save,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
