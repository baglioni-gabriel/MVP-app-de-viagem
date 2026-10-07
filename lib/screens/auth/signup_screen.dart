import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/wayv_logo.dart';

/// Sign-up screen — email, password, confirm password.
///
/// After successful sign-up the user is redirected to the
/// role-selection screen by the router redirect logic.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cred = await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );

      // Optionally set the display name on the Firebase Auth user
      // so it's available before the Firestore doc is written.
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());

      // The router redirect will detect "logged in but no Firestore doc"
      // and send the user to the role-selection screen automatically.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(
          () => _error = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) => switch (code) {
        'email-already-in-use' =>
          'An account with this email already exists.',
        'invalid-email' => 'The email address is not valid.',
        'weak-password' => 'Password is too weak. Use at least 6 characters.',
        'operation-not-allowed' =>
          'Email/password accounts are not enabled.',
        _ => 'Sign-up failed. Please try again.',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeIn,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo / Header ──────────────────────────────
                  _LogoHeader(size: size),
                  const SizedBox(height: 12),
                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your travel journey today',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Form ───────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _nameCtrl,
                          label: 'Full Name',
                          hint: 'Jane Doe',
                          prefixIcon: const Icon(Icons.person_outline),
                          validator: Validators.required,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _passwordCtrl,
                          label: 'Password',
                          obscureText: _obscure,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: _confirmCtrl,
                          label: 'Confirm Password',
                          obscureText: _obscureConfirm,
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                          ),
                          validator:
                              Validators.confirmPassword(_passwordCtrl.text),
                        ),
                      ],
                    ),
                  ),

                  // ── Error ──────────────────────────────────────
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              size: 20, color: theme.colorScheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Submit button ──────────────────────────────
                  CustomButton(
                    label: 'Create Account',
                    isLoading: _loading,
                    onPressed: _submit,
                    icon: Icons.person_add_alt_1_rounded,
                  ),

                  const SizedBox(height: 20),

                  // ── Go to login ────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed('login'),
                        child: Text(
                          'Sign In',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wayv logo header shown at the top of the auth screens.
class _LogoHeader extends StatelessWidget {
  final Size size;
  const _LogoHeader({required this.size});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: size.height * 0.04),
        const WayvLogo(width: 140, height: 100),
        const SizedBox(height: 20),
      ],
    );
  }
}
