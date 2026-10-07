/// Form-field validators used across the app.
///
/// Each validator returns `null` when valid, or an error message string.
class Validators {
  Validators._();

  /// Field must not be empty.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  /// Valid email address format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex = RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Password must be at least 6 characters.
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  /// Passwords must match.
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password.';
      }
      if (value != password) {
        return 'Passwords do not match.';
      }
      return null;
    };
  }

  /// Must be a minimum length.
  static String? Function(String?) minLength(int min, {String? fieldName}) {
    final name = fieldName ?? 'This field';
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '$name is required.';
      }
      if (value.trim().length < min) {
        return '$name must be at least $min characters.';
      }
      return null;
    };
  }

  /// Valid phone number (optional field — empty is OK).
  static String? phoneOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 8 || cleaned.length > 15) {
      return 'Enter a valid phone number.';
    }
    if (!RegExp(r'^[\+\d]+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits and +.';
    }
    return null;
  }

  /// Valid URL (optional field — empty is OK).
  static String? urlOptional(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Enter a valid URL (e.g. https://example.com).';
    }
    return null;
  }

  /// Non-empty description with minimum length.
  static String? description(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required.';
    }
    if (value.trim().length < 10) {
      return 'Description must be at least 10 characters.';
    }
    return null;
  }

  /// Business name: required + min 2 chars.
  static String? businessName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Business name is required.';
    }
    if (value.trim().length < 2) {
      return 'Business name must be at least 2 characters.';
    }
    return null;
  }

  /// Post title: required + min 3 chars.
  static String? postTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required.';
    }
    if (value.trim().length < 3) {
      return 'Title must be at least 3 characters.';
    }
    return null;
  }
}
