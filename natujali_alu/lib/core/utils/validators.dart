/// Form validators shared by the auth and report screens.
///
/// Each returns an error message, or null when the value is valid, which is
/// the contract `TextFormField.validator` expects.
class Validators {
  Validators._();

  static const studentDomain = 'alustudent.com';
  static const staffDomain = 'alueducation.com';

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _digitPattern = RegExp(r'\d');

  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  /// Students can only register with an @alustudent.com address.
  static String? studentEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter your university email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    if (!email.endsWith('@$studentDomain')) {
      return 'Use your @$studentDomain email address.';
    }
    return null;
  }

  /// Sign-in accepts both student and staff ALU addresses.
  static String? aluEmail(String? value) {
    final email = value?.trim().toLowerCase() ?? '';
    if (email.isEmpty) return 'Enter your university email.';
    if (!_emailPattern.hasMatch(email)) return 'Enter a valid email address.';
    if (!email.endsWith('@$studentDomain') &&
        !email.endsWith('@$staffDomain')) {
      return 'Use your ALU email address.';
    }
    return null;
  }

  static String? password(String? value) {
    final password = value ?? '';
    if (password.length < 8 || !_digitPattern.hasMatch(password)) {
      return 'Use at least 8 characters, including a number.';
    }
    return null;
  }

  static String? reportTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Add a short title.';
    if (title.length > 80) return 'Keep the title under 80 characters.';
    return null;
  }

  static String? reportDescription(String? value) {
    final description = value?.trim() ?? '';
    if (description.length < 20) {
      return 'Describe the issue in at least 20 characters.';
    }
    if (description.length > 1000) {
      return 'Keep the description under 1,000 characters.';
    }
    return null;
  }
}
