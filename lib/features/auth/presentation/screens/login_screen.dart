
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/google_sign_in_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _passwordVisible = false;

  // Independent loading states.
  bool _isLoggingIn = false;
  bool _isGoogleSigningIn = false;

  bool get _isBusy => _isLoggingIn || _isGoogleSigningIn;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String? _validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password.';
    }

    return null;
  }

  Future<void> _handleSuccessfulLogin(dynamic user) async {
    if (!mounted) return;

    if (user.accountStatus == 'pending' ||
        user.role == 'pending_staff') {
      await ref
          .read(authControllerProvider.notifier)
          .signOut();

      if (!mounted) return;

      _showMessage(
        'Your staff account is awaiting approval. '
        'You will be able to access the staff portal once approved.',
      );
      return;
    }

    if (user.accountStatus != 'active') {
      await ref
          .read(authControllerProvider.notifier)
          .signOut();

      if (!mounted) return;

      _showMessage(
        'Your account is not currently active. Please contact support.',
      );
      return;
    }

    if (user.role == 'student') {
      context.go('/home');
      return;
    }

    if (user.role == 'staff') {
      context.go('/home');
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .signOut();

    if (!mounted) return;

    _showMessage(
      'Your account role could not be recognized. Please contact support.',
    );
  }

  Future<void> _login() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
    });

    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .loginWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      await _handleSuccessfulLogin(user);
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .loginWithGoogle();

      await _handleSuccessfulLogin(user);
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSigningIn = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.health_and_safety_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: 22),

                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Sign in to continue to CampusCare.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 36),

                    AuthFormField(
                      controller: _emailController,
                      label: 'Email address',
                      validator: Validators.validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 18),

                    AuthFormField(
                      controller: _passwordController,
                      label: 'Password',
                      validator: _validateLoginPassword,
                      obscureText: !_passwordVisible,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isBusy
                            ? null
                            : () => context.push('/forgot-password'),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton(
                      onPressed: _isBusy ? null : _login,
                      child: _isLoggingIn
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text('Login'),
                    ),

                    const SizedBox(height: 24),

                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 22),

                    GoogleSignInButton(
                      isLoading: _isGoogleSigningIn,
                      onPressed: _isBusy
                          ? null
                          : _signInWithGoogle,
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isBusy
                                ? null
                                : () => context.push('/register'),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
