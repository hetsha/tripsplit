class ApiEndpoints {
  static const String defaultLocalBaseUrl = 'http://192.168.1.11/tripsplit/api/';
  
  // Auth
  static const String me = 'auth.php?action=me';
  static const String switchTrip = 'auth.php?action=switch_trip';
  static const String register = 'auth.php?action=register';
  static const String logout = 'otp.php?action=logout';
  
  // OTP
  static const String sendOtp = 'otp.php?action=send_otp';
  static const String verifyOtp = 'otp.php?action=verify_otp';
  static const String linkPhoneSend = 'otp.php?action=send_link_otp';
  static const String linkPhoneVerify = 'otp.php?action=link_phone';
  
  // Email OTP
  static const String sendEmailOtp = 'email-otp.php?action=send_email_otp';
  static const String verifyEmailOtp = 'email-otp.php?action=verify_email_otp';
  
  // Google Auth
  static const String googleLogin = 'google-auth.php?action=google_login';
  
  // Dashboard & Sync
  static const String dashboard = 'dashboard.php';
  static const String sync = 'sync.php';
  
  // Trips
  static const String tripsList = 'trips.php?action=list';
  static const String createTrip = 'trips.php?action=create';
  static const String joinTrip = 'trips.php?action=join';
  
  // Transactions & Expenses
  static const String transactions = 'transactions.php';
  static const String expenses = 'expenses.php';
  static const String addMoney = 'transactions.php?action=add_money';
  
  // Settlements
  static const String settlements = 'settlements.php';
  static const String settleUp = 'settlements.php?action=create';
  static const String markSettlePaid = 'settlements.php?action=mark_paid';
  
  // Members & Categories & Wallets
  static const String members = 'members.php';
  static const String categories = 'categories.php';
}
