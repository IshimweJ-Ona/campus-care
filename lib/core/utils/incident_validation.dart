class IncidentValidation {
  IncidentValidation._();

  static const categories = [
    'Water Shortage',
    'Electricity Outage',
    'Broken Furniture',
    'Damaged Facilities',
    'Sanitation',
    'Safety Concern',
    'Other',
  ];

  static const statuses = [
    'pending',
    'reviewed',
    'in_progress',
    'resolved',
  ];

  static String? validateCategory(String? value) {
    if (value == null || !categories.contains(value)) {
      return 'Select an incident category.';
    }
    return null;
  }

  static String? validateLocation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the incident location';
    }
    if (value.trim().length > 200) {
      return 'Location cannot exceed 200 characters.';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe the incident';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters';
    }
    if (value.trim().length > 500) {
      return 'Description cannot exceed 500 characters.';
    }
    return null;
  }

  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please write a comment first.';
    }
    if (value.trim().length > 2000) {
      return 'Comment cannot exceed 2000 characters.';
    }
    return null;
  }

  static String? validateStatus(String? value) {
    if (value == null || !statuses.contains(value)) {
      return 'Invalid incident status.';
    }
    return null;
  }

  static bool canTransitionStatus(String current, String next) {
    return validateStatus(current) == null &&
        validateStatus(next) == null &&
        current != next;
  }
}
