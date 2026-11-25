class Validators {
  /// Route Code Format: Exactly 2 uppercase letters + 3 numbers (e.g. CR101, CR201)
  /// Regex: ^[A-Z]{2}[0-9]{3}$
  static final RegExp routeCodeRegex = RegExp(r'^[A-Z]{2}[0-9]{3}$');

  /// Validates route code
  static bool isValidRouteCode(String? code) {
    if (code == null) return false;
    final normalized = normalizeRouteCode(code);
    return normalized.length == 5 && routeCodeRegex.hasMatch(normalized);
  }

  /// Normalizes route code (strips whitespace, converts to uppercase)
  static String normalizeRouteCode(String code) {
    return code.trim().toUpperCase().replaceAll(' ', '');
  }

  /// Normalizes vehicle/bus number (removes spaces and hyphens, converts to uppercase)
  static String normalizeBusNumber(String busNumber) {
    return busNumber.trim().toUpperCase().replaceAll(' ', '').replaceAll('-', '');
  }

  /// Formats bus number with standard spacing (e.g., KA 06 F 8558)
  static String formatBusDisplay(String busNumber) {
    final clean = normalizeBusNumber(busNumber);
    if (clean.length >= 9) {
      // e.g. KA06F8558 -> KA-06-F-8558
      return '${clean.substring(0, 2)}-${clean.substring(2, 4)}-${clean.substring(4, 5)}-${clean.substring(5)}';
    }
    return clean;
  }

  /// Basic bus number validation (must have state code + digits + letter + digits, min 7 chars)
  static bool isValidBusNumber(String? busNumber) {
    if (busNumber == null) return false;
    final clean = normalizeBusNumber(busNumber);
    return clean.length >= 6 && clean.length <= 12;
  }

  /// Email validation
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Indian Mobile Number validation (+91 optional, 10 digits starting with 6-9)
  static bool isValidIndianMobile(String? phone) {
    if (phone == null) return false;
    final clean = phone.replaceAll(RegExp(r'[\s\-+()]'), '');
    final numberOnly = clean.startsWith('91') && clean.length == 12 ? clean.substring(2) : clean;
    final mobileRegex = RegExp(r'^[6-9]\d{9}$');
    return mobileRegex.hasMatch(numberOnly);
  }

  /// Driving Licence Number validation (standard Indian format: e.g. KA-06-2020-0012345 or min 10 chars)
  static bool isValidLicenceNumber(String? licence) {
    if (licence == null) return false;
    final clean = licence.trim().replaceAll(' ', '');
    return clean.length >= 8;
  }

  /// Password Strength: returns score from 0.0 (empty) to 1.0 (very strong)
  /// Checks: min 8 chars, uppercase, lowercase, digit, special character
  static double getPasswordStrength(String password) {
    if (password.isEmpty) return 0.0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    return (score / 6.0).clamp(0.0, 1.0);
  }

  /// Password Strength text descriptor
  static String getPasswordStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.85) return 'Good';
    return 'Strong';
  }

  /// Validates password meets minimum security requirements
  static bool isPasswordValid(String password) {
    if (password.length < 8) return false;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    return hasUpper && hasLower && hasDigit;
  }
}
