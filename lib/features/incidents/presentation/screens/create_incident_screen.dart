import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/services/cloudinary_service.dart';
import '../../../../shared/services/image_picker_service.dart';
import '../providers/incident_providers.dart';

class CreateIncidentScreen extends ConsumerStatefulWidget {
  const CreateIncidentScreen({
    super.key,
    this.initialCategory,
  });

  final String? initialCategory;

  @override
  ConsumerState<CreateIncidentScreen> createState() =>
      _CreateIncidentScreenState();
}

class _CreateIncidentScreenState
    extends ConsumerState<CreateIncidentScreen> {
  final _formKey = GlobalKey<FormState>();

  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  File? _selectedImage;
  String? _selectedCategory;
  bool _isSubmitting = false;
  bool _isPickingImage = false;

  static const Color primaryColor = Color(0xFF1769AA);
  static const Color darkColor = Color(0xFF172B4D);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Water Shortage',
      'icon': Icons.water_drop_outlined,
    },
    {
      'name': 'Electricity Outage',
      'icon': Icons.electrical_services_outlined,
    },
    {
      'name': 'Broken Furniture',
      'icon': Icons.chair_outlined,
    },
    {
      'name': 'Damaged Facilities',
      'icon': Icons.domain_outlined,
    },
    {
      'name': 'Sanitation',
      'icon': Icons.cleaning_services_outlined,
    },
    {
      'name': 'Safety Concern',
      'icon': Icons.health_and_safety_outlined,
    },
    {
      'name': 'Other',
      'icon': Icons.more_horiz,
    },
  ];

  @override
  void initState() {
    super.initState();

    final requestedCategory = widget.initialCategory;

    if (requestedCategory != null &&
        _categories.any(
          (category) => category['name'] == requestedCategory,
        )) {
      _selectedCategory = requestedCategory;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerOptions() async {
    if (_isSubmitting || _isPickingImage) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Add incident photo',
                  style: TextStyle(
                    color: darkColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: primaryColor,
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(fromCamera: false);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: primaryColor,
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickImage(fromCamera: true);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    title: const Text('Remove selected photo'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _selectedImage = null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage({required bool fromCamera}) async {
    setState(() => _isPickingImage = true);

    try {
      final image = fromCamera
          ? await _imagePickerService.takePhoto()
          : await _imagePickerService.pickFromGallery();

      if (!mounted) return;

      if (image != null) {
        setState(() => _selectedImage = image);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select image: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;

      // Upload the image first, if the user selected one.
      if (_selectedImage != null) {
        photoUrl = await _cloudinaryService.uploadImage(
          _selectedImage!,
          imageType: CloudinaryImageType.incident,
        );
      }

      await ref.read(incidentRepositoryProvider).createIncident(
            category: _selectedCategory!,
            location: _locationController.text.trim(),
            description: _descriptionController.text.trim(),
            photoUrl: photoUrl,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident reported successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _formKey.currentState!.reset();
      _locationController.clear();
      _descriptionController.clear();

      setState(() {
        _selectedCategory = null;
        _selectedImage = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to submit report: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkColor,
        elevation: 0,
        title: const Text(
          'Create Incident',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(height: 28),

                _buildSectionTitle('Incident category'),
                const SizedBox(height: 12),

                _buildCategorySelector(),

                const SizedBox(height: 26),

                _buildSectionTitle('Where did it happen?'),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    hint: 'e.g. Main Library - Ground Floor',
                    icon: Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the incident location';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 26),

                _buildSectionTitle('Describe the problem'),
                const SizedBox(height: 10),

                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: _inputDecoration(
                    hint: 'Explain what happened and provide useful details...',
                    icon: Icons.description_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe the incident';
                    }

                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                _buildSectionTitle('Incident photo'),
                const SizedBox(height: 10),

                _buildImagePicker(),

                const SizedBox(height: 20),

                _buildInformationCard(),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _submitIncident,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 21,
                                width: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Submitting report...'),
                            ],
                          )
                        : const Text(
                            'Submit Incident',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    if (_selectedImage != null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _selectedImage!,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Photo selected',
                    style: TextStyle(
                      color: darkColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _selectedImage = null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : _showImagePickerOptions,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _isSubmitting || _isPickingImage
          ? null
          : _showImagePickerOptions,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD5DFEA),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (_isPickingImage)
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.add_a_photo_outlined,
                size: 38,
                color: primaryColor,
              ),
            const SizedBox(height: 12),
            Text(
              _isPickingImage
                  ? 'Opening image picker...'
                  : 'Add a photo of the issue',
              style: const TextStyle(
                color: darkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Optional · JPG, PNG or WEBP · Maximum 2 MB',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.campaign_outlined,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Report a campus issue',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Help us identify and resolve problems around campus. '
            'Your report makes a difference.',
            style: TextStyle(
              color: Colors.white,
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: darkColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildCategorySelector() {
    return FormField<String>(
      initialValue: _selectedCategory,
      validator: (_) {
        if (_selectedCategory == null) {
          return 'Please select an incident category';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final name = category['name'] as String;
                final icon = category['icon'] as IconData;
                final isSelected = _selectedCategory == name;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _isSubmitting
                      ? null
                      : () {
                          setState(() => _selectedCategory = name);
                          field.didChange(name);
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          icon,
                          color: primaryColor,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: darkColor,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: primaryColor,
                            size: 17,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primaryColor),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: primaryColor,
            size: 21,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your report will be visible to the campus community. '
              'Your personal information will only be accessible '
              'to authorized campus staff.',
              style: TextStyle(
                color: darkColor,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}