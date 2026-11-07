import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() =>
      _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  bool _isSigningOut = false;
  bool? _messageIsSuccess;
  String? _message;

  bool get _isBusy => _isChecking || _isResending || _isSigningOut;

  void _showMessage(String message, {required bool success}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsSuccess = success;
    });
  }

  void _navigateAccordingToAccountStatus(AppUser user) {
    if (user.role == 'pending_staff' &&
        user.accountStatus == 'pending') {
      context.go('/pending-staff');
      return;
    }

    if ((user.role == 'student' || user.role == 'staff') &&
        user.accountStatus == 'active') {
      context.go('/home');
      return;
    }

    _showMessage(
      'Your verified account has an unsupported role or status. '
      'Please contact support.',
      success: false,
    );
  }

  Future<void> _checkVerification() async {
    if (_isBusy) return;

    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .completeEmailVerification();
      if (mounted) _navigateAccordingToAccountStatus(user);
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_isBusy) return;

    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendVerificationEmail();
      _showMessage(
        'A new verification link has been sent. Check your inbox.',
        success: true,
      );
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _signOut() async {
    if (_isBusy) return;

    setState(() {
      _isSigningOut = true;
      _message = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (error) {
      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email =
        ref.watch(authRemoteDataSourceProvider).currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 96,
                    width: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Verify your email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification link to:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Open the link in that email before accessing CampusCare. '
                    'Once verified, return here and confirm your email.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (_messageIsSuccess == true
                                ? AppColors.success
                                : AppColors.error)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _messageIsSuccess == true
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isBusy ? null : _checkVerification,
                      icon: _isChecking
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: const Text('I Have Verified'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isBusy ? null : _resendVerification,
                    child: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Resend Verification Email'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isBusy ? null : _signOut,
                    icon: _isSigningOut
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout_rounded),
                    label: const Text('Sign Out / Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}