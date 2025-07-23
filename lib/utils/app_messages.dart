class AppMessages {
  // General Messages
  static const String somethingWentWrong = 'Something went wrong. Please try again.';
  static const String operationSuccess = 'Operation successful!';

  // Authentication Messages
  static const String loginSuccess = 'Logged in successfully!';
  static const String registrationSuccess = 'Registration successful! Please log in.';
  static const String logoutSuccess = 'Logged out successfully!';
  static const String userNotFound = 'No user found for that email.';
  static const String wrongPassword = 'Wrong password provided for that user.';
  static const String emailAlreadyInUse = 'The email address is already in use by another account.';
  static const String weakPassword = 'The password provided is too weak.';
  static const String invalidEmail = 'The email address is not valid.';
  static const String userDisabled = 'The user account has been disabled.';
  static const String tooManyRequests = 'Too many requests. Please try again later.';
  static const String networkRequestFailed = 'Network error. Please check your internet connection.';

  // Validation Messages
  static const String emailRequired = 'Email is required.';
  static const String passwordRequired = 'Password is required.';
  static const String confirmPasswordRequired = 'Confirm password is required.';
  static const String emailIncorrect = 'Email is incorrect. Please use a valid format (e.g., user@example.com).';
  static const String passwordTooShort = 'Password must be at least 8 characters long.';
  static const String passwordNoUppercase = 'Password must contain at least one uppercase letter.';
  static const String passwordNoLowercase = 'Password must contain at least one lowercase letter.';
  static const String passwordNoDigit = 'Password must contain at least one number.';
  static const String passwordNoSymbol = 'Password must contain at least one symbol (e.g., !@#\$%^&*).';
  static const String passwordsDoNotMatch = 'Passwords do not match.';
}
