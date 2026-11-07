
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/google_sign_in_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'student';

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  // Independent loading states.
  bool _isRegistering = false;
  bool _isGoogleSigningIn = false;

  bool get _isBusy => _isRegistering || _isGoogleSigningIn;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  // Navigate according to the saved Firestore role and status.
  void _navigateAccordingToAccountStatus(AppUser user) {
    if (!mounted) return;

    if (!user.emailVerified) {
      context.go('/verify-email');
      return;
    }

    if (user.role == 'pending_staff' &&
        user.accountStatus == 'pending') {
      context.go('/pending-staff');
      return;
    }

    if (user.role == 'student' &&
        user.accountStatus == 'active') {
      context.go('/home');
      return;
    }

    if (user.role == 'staff' && user.accountStatus == 'active') {
      context.go('/home');
      return;
    }

    _showMessage(
      'Your account could not be verified. Please contact support.',
    );
  }

  // Register using email and password.
  Future<void> _register() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isRegistering = true;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .registerWithEmail(
            name: _nameController.text.trim(),
            email: Validators.normalizeEmail(_emailController.text),
            password: _passwordController.text,
            selectedRole: _selectedRole,
          );

      if (!mounted) return;

      context.go('/verify-email');
    } catch (error) {
      final currentUser =
          ref.read(authRemoteDataSourceProvider).currentUser;
      if (currentUser != null &&
          Validators.normalizeEmail(currentUser.email ?? '') ==
              Validators.normalizeEmail(_emailController.text) &&
          !currentUser.emailVerified) {
        if (mounted) {
          context.go('/verify-email');
          _showMessage(
            error.toString().replaceFirst('Exception: ', ''),
          );
        }
        return;
      }

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  // Register or sign in using Google.
  Future<void> _signInWithGoogle() async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleSigningIn = true;
    });

    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .signInWithGoogle(
            selectedRole: _selectedRole,
          );

      if (!mounted || user == null) return;

      _navigateAccordingToAccountStatus(user);
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

  // Student and staff role selection cards.
  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: _isBusy
            ? null
            : () {
                setState(() {
                  _selectedRole = role;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      size: 58,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Join CampusCare to help make your campus safer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'I am registering as a:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildRoleCard(
                          role: 'student',
                          title: 'Student',
                          description: 'Report and track incidents',
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(width: 12),
                        _buildRoleCard(
                          role: 'staff',
                          title: 'Campus Staff',
                          description: 'Manage campus incidents',
                          icon: Icons.badge_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    AuthFormField(
                      controller: _nameController,
                      label: 'Full name',
                      validator: Validators.validateName,
                      keyboardType: TextInputType.name,
                    ),

                    const SizedBox(height: 16),

                    AuthFormField(
                      controller: _emailController,
                      label: 'Email address',
                      validator: (value) {
                        final emailError =
                            Validators.validateAluEmail(value);
                        if (emailError != null) return emailError;
                        if (Validators.roleForAluEmail(value) !=
                            _selectedRole) {
                          return _selectedRole == 'student'
                              ? 'Use an @alustudent.com email for a student account.'
                              : 'Use an @alustaff.com email for a staff account.';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    AuthFormField(
                      controller: _passwordController,
                      label: 'Password',
                      validator: Validators.validatePassword,
                      obscureText: !_passwordVisible,
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

                    const SizedBox(height: 16),

                    AuthFormField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      validator: (value) =>
                          Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                      obscureText: !_confirmPasswordVisible,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        tooltip: _confirmPasswordVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: () {
                          setState(() {
                            _confirmPasswordVisible =
                                !_confirmPasswordVisible;
                          });
                        },
                        icon: Icon(
                          _confirmPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isBusy ? null : _register,
                      child: _isRegistering
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Text('Create account'),
                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 20),

                    GoogleSignInButton(
                      isLoading: _isGoogleSigningIn,
                      onPressed: _isBusy
                          ? null
                          : _signInWithGoogle,
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _isBusy
                                ? null
                                : () => context.push('/login'),
                            child: const Text(
                              'Login',
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
