
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/cloudinary_service.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  AppUser? _user;
  bool _isLoading = true;
  bool _isBusy = false;

  bool get _supportsPassword {
    final firebaseUser = ref.read(firebaseAuthProvider).currentUser;

    return firebaseUser?.providerData.any(
          (provider) => provider.providerId == 'password',
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ref
          .read(authControllerProvider.notifier)
          .getCurrentUser();

      if (!mounted) return;

      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _selectProfileImage() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              if (_user?.photoUrl != null &&
                  _user!.photoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Remove profile picture',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => Navigator.pop(context, 'remove'),
                ),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    if (choice == 'remove') {
      await _removeProfileImage();
      return;
    }

    try {
      setState(() => _isBusy = true);

      File? imageFile;

      if (choice == 'gallery') {
        imageFile = await _imagePickerService.pickFromGallery();
      } else {
        imageFile = await _imagePickerService.takePhoto();
      }

      if (!mounted) return;

      if (imageFile == null) {
        setState(() => _isBusy = false);
        return;
      }

      final imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        imageType: CloudinaryImageType.profile,
      );

      await ref.read(authControllerProvider.notifier).updatePhotoUrl(
            photoUrl: imageUrl,
          );

      if (!mounted) return;

      setState(() {
        _user = _user?.copyWith(photoUrl: imageUrl);
        _isBusy = false;
      });

      _showMessage('Profile picture updated successfully.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _removeProfileImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile picture?'),
        content: const Text(
          'Your profile picture will be removed from CampusCare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      setState(() => _isBusy = true);

      await ref.read(authControllerProvider.notifier).updatePhotoUrl(
            photoUrl: null,
          );

      if (!mounted) return;

      setState(() {
        _user = _user?.copyWith(clearPhotoUrl: true);
        _isBusy = false;
      });

      _showMessage('Profile picture removed.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _editName() async {
    _nameController.text = _user?.displayName ?? '';

    final formKey = GlobalKey<FormState>();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit full name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  _nameController.text.trim(),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || name == null || name.isEmpty) return;

    try {
      setState(() => _isBusy = true);

      await ref.read(authControllerProvider.notifier).updateName(
            name: name,
          );

      if (!mounted) return;

      setState(() {
        _user = _user?.copyWith(displayName: name);
        _isBusy = false;
      });

      _showMessage('Your name has been updated.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _changeEmail() async {
    if (!_supportsPassword) {
      _showMessage(
        'Email changes for Google accounts are not available here.',
        isError: true,
      );
      return;
    }

    _emailController.clear();
    _currentPasswordController.clear();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change email'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New email address',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                          .hasMatch(value.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your current password.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'email': _emailController.text.trim(),
                  'password': _currentPasswordController.text,
                });
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    try {
      setState(() => _isBusy = true);

      await ref.read(authControllerProvider.notifier).changeEmail(
            newEmail: result['email']!,
            currentPassword: result['password']!,
          );

      if (!mounted) return;

      setState(() => _isBusy = false);

      _showMessage(
        'Verification email sent. Verify your new address before using it.',
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _changePassword() async {
    if (!_supportsPassword) {
      _showMessage(
        'Password changes are not available for Google-only accounts.',
        isError: true,
      );
      return;
    }

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Use at least 6 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, {
                  'current': _currentPasswordController.text,
                  'new': _newPasswordController.text,
                });
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (!mounted || result == null) return;

    try {
      setState(() => _isBusy = true);

      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: result['current']!,
            newPassword: result['new']!,
          );

      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage('Your password has been changed.');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    try {
      setState(() => _isBusy = true);

      await ref.read(authControllerProvider.notifier).signOut();

      if (!mounted) return;

      context.go('/login');
    } catch (error) {
      if (!mounted) return;

      setState(() => _isBusy = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'student':
        return 'Student';
      case 'staff':
        return 'Approved Staff';
      case 'pending_staff':
        return 'Staff Application Pending';
      default:
        return role ?? 'Unknown';
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'pending':
        return 'Pending Approval';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('Profile'),
        ),
        body: const Center(
          child: Text('Unable to load your profile.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('My Profile'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isBusy ? null : _selectProfileImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 58,
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            backgroundImage: _user!.photoUrl != null &&
                                    _user!.photoUrl!.isNotEmpty
                                ? NetworkImage(_user!.photoUrl!)
                                : null,
                            child: _user!.photoUrl == null ||
                                    _user!.photoUrl!.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 58,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 19,
                              backgroundColor: theme.colorScheme.primary,
                              child: const Icon(
                                Icons.camera_alt,
                                size: 19,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _user!.displayName ?? 'CampusCare User',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Chip(
                      avatar: const Icon(Icons.verified_user, size: 17),
                      label: Text(_formatRole(_user!.role)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _sectionTitle('Account information'),
              _profileTile(
                icon: Icons.person_outline,
                title: 'Full name',
                subtitle: _user!.displayName ?? 'Not provided',
                onTap: _editName,
              ),
              _profileTile(
                icon: Icons.email_outlined,
                title: 'Email address',
                subtitle: _user!.email,
                onTap: _changeEmail,
              ),
              _profileTile(
                icon: Icons.lock_outline,
                title: 'Password',
                subtitle: _supportsPassword
                    ? 'Change your password'
                    : 'Managed by Google',
                onTap: _changePassword,
              ),
              const SizedBox(height: 20),
              _sectionTitle('Account status'),
              _profileTile(
                icon: Icons.badge_outlined,
                title: 'Account role',
                subtitle: _formatRole(_user!.role),
              ),
              _profileTile(
                icon: Icons.check_circle_outline,
                title: 'Account status',
                subtitle: _formatStatus(_user!.accountStatus),
              ),
              _profileTile(
                icon: Icons.mark_email_read_outlined,
                title: 'Email verification',
                subtitle: _user!.emailVerified ? 'Verified' : 'Not verified',
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                onPressed: _isBusy ? null : _signOut,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'CampusCare',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (_isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: _isBusy ? null : onTap,
      ),
    );
  }
}
