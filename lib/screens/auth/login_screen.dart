import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/wayv_logo.dart';

/// Login screen — email + password form.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
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
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      // Navigation is handled by the router redirect — no manual push needed.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    } catch (_) {
      setState(() => _error = 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendlyError(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password. Please try again.',
        'invalid-email' => 'The email address is not valid.',
        'user-disabled' => 'This account has been disabled.',
        'invalid-credential' => 'Invalid email or password.',
        'too-many-requests' => 'Too many attempts. Please wait a moment.',
        _ => 'Login failed. Please try again.',
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
                    'Welcome back',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue exploring',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Form ───────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
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
                    label: 'Sign In',
                    isLoading: _loading,
                    onPressed: _submit,
                    icon: Icons.login_rounded,
                  ),

                  const SizedBox(height: 20),

                  // ── Go to sign-up ──────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: theme.textTheme.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.goNamed('signup'),
                        child: Text(
                          'Sign Up',
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
        SizedBox(height: size.height * 0.06),
        const WayvLogo(width: 140, height: 100),
        const SizedBox(height: 20),
      ],
    );
  }
}
