class ProfileFormValidators {
  static String? validateName(String? value) {
    final candidate = (value ?? '').trim();
    if (candidate.isEmpty) {
      return 'Name is required.';
    }
    if (candidate.length < 2) {
      return 'Name must be at least 2 characters.';
    }
    if (candidate.length > 60) {
      return 'Name must be 60 characters or fewer.';
    }
    return null;
  }

  static String? validateAvatarUrl(String? value) {
    final candidate = (value ?? '').trim();
    if (candidate.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasAuthority) {
      return 'Enter a valid image URL.';
    }

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return 'Avatar URL must start with http:// or https://';
    }

    return null;
  }
}
