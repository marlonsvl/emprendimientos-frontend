class Validators {
  // Email validation
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegExp = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$",
    );
    
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Username validation
  static String? username(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    
    final trimmedValue = value.trim();
    
    // Check minimum length
    if (trimmedValue.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    
    // Check maximum length
    if (trimmedValue.length > 20) {
      return 'Username cannot exceed 20 characters';
    }
    
    // Check if username starts with a letter
    if (!RegExp(r'^[a-zA-Z]').hasMatch(trimmedValue)) {
      return 'Username must start with a letter';
    }
    
    // Check allowed characters (letters, numbers, underscore, hyphen)
    if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_-]*$').hasMatch(trimmedValue)) {
      return 'Username can only contain letters, numbers, underscore, and hyphen';
    }
    
    // Check if username doesn't end with underscore or hyphen
    if (RegExp(r'[_-]$').hasMatch(trimmedValue)) {
      return 'Username cannot end with underscore or hyphen';
    }
    
    // Check for consecutive special characters
    if (RegExp(r'[_-]{2,}').hasMatch(trimmedValue)) {
      return 'Username cannot have consecutive underscores or hyphens';
    }
    
    // Reserved usernames (you can expand this list)
    final reservedUsernames = [
      'admin', 'administrator', 'root', 'user', 'guest', 'null', 'undefined',
      'api', 'www', 'mail', 'ftp', 'blog', 'news', 'support', 'help',
      'about', 'contact', 'terms', 'privacy', 'login', 'register', 'signup'
    ];
    
    if (reservedUsernames.contains(trimmedValue.toLowerCase())) {
      return 'This username is not available';
    }
    
    return null;
  }

  // Password validation
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!RegExp(r'(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Simple password validation (less strict)
  static String? simplePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  // Confirm password validation
  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? name(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // First name validation
  static String? firstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    
    if (value.trim().length < 2) {
      return 'First name must be at least 2 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'First name can only contain letters';
    }
    
    return null;
  }

  // Last name validation
  static String? lastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Last name must be at least 2 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
      return 'Last name can only contain letters';
    }
    
    return null;
  }

  // Phone number validation
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    
    return null;
  }

  // Required field validation
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  // Minimum length validation
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    
    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters long';
    }
    
    return null;
  }

  // Maximum length validation
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} cannot exceed $maxLength characters';
    }
    
    return null;
  }

  // Numeric validation
  static String? numeric(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return '${fieldName ?? 'This field'} must contain only numbers';
    }
    
    return null;
  }

  // URL validation
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    
    final urlRegExp = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
      caseSensitive: false,
    );
    
    if (!urlRegExp.hasMatch(value.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Age validation
  static String? age(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid age';
    }
    
    return null;
  }

  // Date validation (DD/MM/YYYY format)
  static String? date(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    final dateRegExp = RegExp(r'^\d{2}\/\d{2}\/\d{4}$');
    if (!dateRegExp.hasMatch(value)) {
      return 'Please enter date in DD/MM/YYYY format';
    }
    
    try {
      final parts = value.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      
      // Check if the date is valid
      if (date.day != day || date.month != month || date.year != year) {
        return 'Please enter a valid date';
      }
      
      // Check if date is not in the future
      if (date.isAfter(DateTime.now())) {
        return 'Date cannot be in the future';
      }
      
    } catch (e) {
      return 'Please enter a valid date';
    }
    
    return null;
  }

  // Combine multiple validators
  static String? combine(List<String? Function()> validators) {
    for (final validator in validators) {
      final result = validator();
      if (result != null) {
        return result;
      }
    }
    return null;
  }

  // Custom validation helper
  static String? custom(String? value, bool Function(String?) test, String errorMessage) {
    if (test(value)) {
      return null;
    }
    return errorMessage;
  }
}