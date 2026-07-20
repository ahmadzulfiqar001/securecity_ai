/// All UI-facing strings for SecureCity AI.
/// English and Urdu variants included as static const fields.
/// Use [AppStrings.en] for English and [AppStrings.ur] for Urdu.
abstract final class AppStrings {
  // ─────────────────────────────────────────────────────────────────────────
  // App-level
  // ─────────────────────────────────────────────────────────────────────────
  static const String appName = 'SecureCity AI';
  static const String appNameUr = 'سیکیور سٹی اے آئی';
  static const String appTagline = 'Safety Powered by Intelligence';
  static const String appTaglineUr = 'ذہانت سے تقویت یافتہ سلامتی';

  // ─────────────────────────────────────────────────────────────────────────
  // Splash Screen
  // ─────────────────────────────────────────────────────────────────────────
  static const String splashInitializing = 'Initializing secure environment…';
  static const String splashInitializingUr = 'محفوظ ماحول شروع ہو رہا ہے…';
  static const String splashLoadingAI = 'Loading AI models…';
  static const String splashLoadingAIUr = 'AI ماڈلز لوڈ ہو رہے ہیں…';
  static const String splashConnecting = 'Connecting to safety network…';
  static const String splashConnectingUr = 'سیفٹی نیٹ ورک سے جڑ رہے ہیں…';

  // ─────────────────────────────────────────────────────────────────────────
  // Onboarding
  // ─────────────────────────────────────────────────────────────────────────
  static const String onboardingSkip = 'Skip';
  static const String onboardingSkipUr = 'چھوڑیں';
  static const String onboardingNext = 'Next';
  static const String onboardingNextUr = 'اگلا';
  static const String onboardingGetStarted = 'Get Started';
  static const String onboardingGetStartedUr = 'شروع کریں';

  static const String onboarding1Title = 'City Safety Monitoring';
  static const String onboarding1TitleUr = 'شہر کی سلامتی کی نگرانی';
  static const String onboarding1Body =
      'Real-time monitoring of crime hotspots, incidents, and safety alerts across your city.';
  static const String onboarding1BodyUr =
      'آپ کے شہر میں جرائم کے مراکز، واقعات اور حفاظتی انتباہات کی ریل ٹائم نگرانی۔';

  static const String onboarding2Title = 'Real-Time Emergency Response';
  static const String onboarding2TitleUr = 'ریل ٹائم ہنگامی ردعمل';
  static const String onboarding2Body =
      'One-tap SOS, automatic location sharing, and instant alerts to your emergency contacts.';
  static const String onboarding2BodyUr =
      'ایک ٹیپ SOS، خودکار مقام کا اشتراک، اور آپ کے ہنگامی رابطوں کو فوری انتباہ۔';

  static const String onboarding3Title = 'AI-Powered Safety Intelligence';
  static const String onboarding3TitleUr = 'AI سے چلنے والی حفاظتی ذہانت';
  static const String onboarding3Body =
      'Predictive safety scores, route recommendations, and an AI assistant available 24/7.';
  static const String onboarding3BodyUr =
      'پیشگوئی کرنے والے حفاظتی اسکور، راستے کی سفارشات، اور 24/7 دستیاب AI معاون۔';

  // ─────────────────────────────────────────────────────────────────────────
  // Authentication
  // ─────────────────────────────────────────────────────────────────────────
  static const String authWelcomeBack = 'Welcome Back';
  static const String authWelcomeBackUr = 'خوش آمدید';
  static const String authSignInSubtitle = 'Sign in to your SecureCity account';
  static const String authSignInSubtitleUr = 'اپنے سیکیور سٹی اکاؤنٹ میں سائن ان کریں';

  static const String authEmail = 'Email address';
  static const String authEmailUr = 'ای میل ایڈریس';
  static const String authPassword = 'Password';
  static const String authPasswordUr = 'پاس ورڈ';
  static const String authConfirmPassword = 'Confirm password';
  static const String authConfirmPasswordUr = 'پاس ورڈ کی تصدیق کریں';
  static const String authFullName = 'Full name';
  static const String authFullNameUr = 'پورا نام';
  static const String authPhone = 'Phone number';
  static const String authPhoneUr = 'فون نمبر';

  static const String authSignIn = 'Sign In';
  static const String authSignInUr = 'سائن ان';
  static const String authSignUp = 'Sign Up';
  static const String authSignUpUr = 'سائن اپ';
  static const String authSignOut = 'Sign Out';
  static const String authSignOutUr = 'سائن آؤٹ';

  static const String authSignInWithGoogle = 'Continue with Google';
  static const String authSignInWithGoogleUr = 'گوگل کے ساتھ جاری رکھیں';

  static const String authForgotPassword = 'Forgot password?';
  static const String authForgotPasswordUr = 'پاس ورڈ بھول گئے؟';
  static const String authResetPassword = 'Reset Password';
  static const String authResetPasswordUr = 'پاس ورڈ ری سیٹ کریں';
  static const String authResetPasswordSent =
      'Password reset email has been sent. Please check your inbox.';
  static const String authResetPasswordSentUr =
      'پاس ورڈ ری سیٹ ای میل بھیجی گئی ہے۔ براہ کرم اپنا ان باکس چیک کریں۔';

  static const String authNoAccount = "Don't have an account?";
  static const String authNoAccountUr = 'اکاؤنٹ نہیں ہے؟';
  static const String authHaveAccount = 'Already have an account?';
  static const String authHaveAccountUr = 'پہلے سے اکاؤنٹ ہے؟';

  static const String authCreateAccount = 'Create Account';
  static const String authCreateAccountUr = 'اکاؤنٹ بنائیں';
  static const String authCreateAccountSubtitle =
      'Join SecureCity and stay safe';
  static const String authCreateAccountSubtitleUr =
      'سیکیور سٹی سے جڑیں اور محفوظ رہیں';

  static const String authTermsAgreement =
      'By continuing, you agree to our Terms of Service and Privacy Policy.';
  static const String authTermsAgreementUr =
      'جاری رکھ کر آپ ہماری سروس کی شرائط اور رازداری کی پالیسی سے اتفاق کرتے ہیں۔';

  // ─────────────────────────────────────────────────────────────────────────
  // Validation Messages
  // ─────────────────────────────────────────────────────────────────────────
  static const String validationEmailRequired = 'Email is required';
  static const String validationEmailInvalid = 'Enter a valid email address';
  static const String validationPasswordRequired = 'Password is required';
  static const String validationPasswordTooShort =
      'Password must be at least 8 characters';
  static const String validationPasswordMismatch = 'Passwords do not match';
  static const String validationNameRequired = 'Full name is required';
  static const String validationPhoneInvalid = 'Enter a valid phone number';

  // ─────────────────────────────────────────────────────────────────────────
  // Home Screen
  // ─────────────────────────────────────────────────────────────────────────
  static const String homeGoodMorning = 'Good Morning';
  static const String homeGoodAfternoon = 'Good Afternoon';
  static const String homeGoodEvening = 'Good Evening';
  static const String homeGoodMorningUr = 'صبح بخیر';
  static const String homeGoodAfternoonUr = 'دوپہر بخیر';
  static const String homeGoodEveningUr = 'شام بخیر';

  static const String homeSafetyScore = 'Area Safety Score';
  static const String homeSafetyScoreUr = 'علاقے کا حفاظتی اسکور';
  static const String homeRecentAlerts = 'Recent Alerts';
  static const String homeRecentAlertsUr = 'حالیہ انتباہات';
  static const String homeQuickActions = 'Quick Actions';
  static const String homeQuickActionsUr = 'فوری اقدامات';
  static const String homeViewAll = 'View All';
  static const String homeViewAllUr = 'سب دیکھیں';
  static const String homeNewsFeed = 'Safety News';
  static const String homeNewsFeedUr = 'حفاظتی خبریں';

  static const String homeActionSOS = 'SOS';
  static const String homeActionSOSUr = 'ایس او ایس';
  static const String homeActionReport = 'Report';
  static const String homeActionReportUr = 'رپورٹ';
  static const String homeActionNavigate = 'Navigate';
  static const String homeActionNavigateUr = 'نیویگیٹ';
  static const String homeActionChatbot = 'AI Assistant';
  static const String homeActionChatbotUr = 'AI معاون';

  static const String homeIncidentsNearby = 'incidents nearby';
  static const String homeIncidentsNearbyUr = 'قریب کے واقعات';
  static const String homeActivePatrols = 'active patrols';
  static const String homeActivePatrolsUr = 'فعال گشت';
  static const String homeResponseTime = 'avg response time';
  static const String homeResponseTimeUr = 'اوسط ردعمل کا وقت';

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation Labels
  // ─────────────────────────────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navHomeUr = 'ہوم';
  static const String navMap = 'Map';
  static const String navMapUr = 'نقشہ';
  static const String navSOS = 'SOS';
  static const String navSOSUr = 'ایس او ایس';
  static const String navReports = 'Reports';
  static const String navReportsUr = 'رپورٹس';
  static const String navProfile = 'Profile';
  static const String navProfileUr = 'پروفائل';

  // ─────────────────────────────────────────────────────────────────────────
  // SOS Screen
  // ─────────────────────────────────────────────────────────────────────────
  static const String sosTitle = 'Emergency SOS';
  static const String sosTitleUr = 'ہنگامی SOS';
  static const String sosHoldToActivate = 'HOLD TO ACTIVATE';
  static const String sosHoldToActivateUr = 'چالو کرنے کے لیے دبائیں';
  static const String sosCountdownMessage = 'Sending SOS in';
  static const String sosCountdownMessageUr = 'SOS بھیجا جائے گا';
  static const String sosCancel = 'Cancel SOS';
  static const String sosCancelUr = 'SOS منسوخ کریں';
  static const String sosSending = 'Sending SOS…';
  static const String sosSendingUr = 'SOS بھیجا جا رہا ہے…';
  static const String sosSent = 'SOS Sent! Help is on the way.';
  static const String sosSentUr = 'SOS بھیج دیا گیا! مدد راستے میں ہے۔';
  static const String sosShakeEnabled = 'Shake to activate is ON';
  static const String sosShakeEnabledUr = 'ہلانے سے فعال ہونا چالو ہے';
  static const String sosVoiceEnabled = 'Voice activation is ON';
  static const String sosVoiceEnabledUr = 'آواز سے فعال کرنا چالو ہے';
  static const String sosEmergencyContacts = 'Emergency Contacts';
  static const String sosEmergencyContactsUr = 'ہنگامی رابطے';
  static const String sosAddContact = 'Add Contact';
  static const String sosAddContactUr = 'رابطہ شامل کریں';
  static const String sosLocationSharing = 'Sharing your live location';
  static const String sosLocationSharingUr = 'آپ کا لائیو مقام شیئر ہو رہا ہے';

  // ─────────────────────────────────────────────────────────────────────────
  // Incident Reporting
  // ─────────────────────────────────────────────────────────────────────────
  static const String incidentReportTitle = 'Report Incident';
  static const String incidentReportTitleUr = 'واقعہ رپورٹ کریں';
  static const String incidentType = 'Incident Type';
  static const String incidentTypeUr = 'واقعے کی قسم';
  static const String incidentDescription = 'Description';
  static const String incidentDescriptionUr = 'تفصیل';
  static const String incidentLocation = 'Location';
  static const String incidentLocationUr = 'مقام';
  static const String incidentAddMedia = 'Add Photos / Video';
  static const String incidentAddMediaUr = 'تصاویر / ویڈیو شامل کریں';
  static const String incidentSubmit = 'Submit Report';
  static const String incidentSubmitUr = 'رپورٹ جمع کریں';
  static const String incidentSubmitted = 'Incident reported successfully';
  static const String incidentSubmittedUr = 'واقعہ کامیابی سے رپورٹ ہو گیا';
  static const String incidentAnonymous = 'Report anonymously';
  static const String incidentAnonymousUr = 'گمنام رپورٹ کریں';

  static const String incidentTypeTheft = 'Theft';
  static const String incidentTypeAssault = 'Assault';
  static const String incidentTypeAccident = 'Accident';
  static const String incidentTypeHarassment = 'Harassment';
  static const String incidentTypeSuspicious = 'Suspicious Activity';
  static const String incidentTypeEmergency = 'Emergency';
  static const String incidentTypeOther = 'Other';

  // ─────────────────────────────────────────────────────────────────────────
  // Safety & Map
  // ─────────────────────────────────────────────────────────────────────────
  static const String mapTitle = 'Safety Map';
  static const String mapTitleUr = 'حفاظتی نقشہ';
  static const String mapSearchPlaceholder = 'Search location…';
  static const String mapSearchPlaceholderUr = 'مقام تلاش کریں…';
  static const String mapSafeZone = 'Safe Zone';
  static const String mapSafeZoneUr = 'محفوظ علاقہ';
  static const String mapDangerZone = 'Danger Zone';
  static const String mapDangerZoneUr = 'خطرناک علاقہ';
  static const String mapNearbyPolice = 'Nearby Police';
  static const String mapNearbyPoliceUr = 'قریبی پولیس';
  static const String mapNearbyHospital = 'Nearby Hospitals';
  static const String mapNearbyHospitalUr = 'قریبی ہسپتال';
  static const String mapNearbyFire = 'Fire Stations';
  static const String mapNearbyFireUr = 'فائر اسٹیشن';

  // ─────────────────────────────────────────────────────────────────────────
  // Safety Score Labels
  // ─────────────────────────────────────────────────────────────────────────
  static const String safetyExcellent = 'Excellent';
  static const String safetyGood = 'Good';
  static const String safetyCaution = 'Caution';
  static const String safetyDanger = 'Danger';
  static const String safetyCritical = 'Critical';
  static const String safetyExcellentUr = 'بہترین';
  static const String safetyGoodUr = 'اچھا';
  static const String safetyCautionUr = 'احتیاط';
  static const String safetyDangerUr = 'خطرہ';
  static const String safetyCriticalUr = 'تشویشناک';

  // ─────────────────────────────────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────────────────────────────────
  static const String profileTitle = 'My Profile';
  static const String profileTitleUr = 'میری پروفائل';
  static const String profileEditProfile = 'Edit Profile';
  static const String profileEditProfileUr = 'پروفائل تبدیل کریں';
  static const String profileSettings = 'Settings';
  static const String profileSettingsUr = 'ترتیبات';
  static const String profileJourneyHistory = 'Journey History';
  static const String profileJourneyHistoryUr = 'سفر کی تاریخ';
  static const String profileMyReports = 'My Reports';
  static const String profileMyReportsUr = 'میری رپورٹس';
  static const String profileNotifications = 'Notifications';
  static const String profileNotificationsUr = 'اطلاعات';
  static const String profileHelp = 'Help & Support';
  static const String profileHelpUr = 'مدد اور سپورٹ';
  static const String profileSignOut = 'Sign Out';
  static const String profileSignOutUr = 'سائن آؤٹ';

  // ─────────────────────────────────────────────────────────────────────────
  // Chatbot / AI Assistant
  // ─────────────────────────────────────────────────────────────────────────
  static const String chatbotTitle = 'AI Safety Assistant';
  static const String chatbotTitleUr = 'AI سیفٹی معاون';
  static const String chatbotPlaceholder = 'Ask me anything about safety…';
  static const String chatbotPlaceholderUr = 'سلامتی کے بارے میں کچھ بھی پوچھیں…';
  static const String chatbotSend = 'Send';
  static const String chatbotSendUr = 'بھیجیں';
  static const String chatbotTyping = 'SecureCity AI is typing…';
  static const String chatbotTypingUr = 'سیکیور سٹی AI ٹائپ کر رہا ہے…';
  static const String chatbotGreeting =
      'Hello! I\'m your SecureCity AI assistant. How can I help you stay safe today?';
  static const String chatbotGreetingUr =
      'ہیلو! میں آپ کا سیکیور سٹی AI معاون ہوں۔ آج میں آپ کو محفوظ رہنے میں کیسے مدد کر سکتا ہوں؟';

  // ─────────────────────────────────────────────────────────────────────────
  // Common / Shared
  // ─────────────────────────────────────────────────────────────────────────
  static const String commonOk = 'OK';
  static const String commonCancel = 'Cancel';
  static const String commonCancelUr = 'منسوخ';
  static const String commonConfirm = 'Confirm';
  static const String commonConfirmUr = 'تصدیق کریں';
  static const String commonSave = 'Save';
  static const String commonSaveUr = 'محفوظ کریں';
  static const String commonDelete = 'Delete';
  static const String commonDeleteUr = 'حذف کریں';
  static const String commonEdit = 'Edit';
  static const String commonEditUr = 'ترمیم';
  static const String commonShare = 'Share';
  static const String commonShareUr = 'شیئر کریں';
  static const String commonRetry = 'Retry';
  static const String commonRetryUr = 'دوبارہ کوشش';
  static const String commonLoading = 'Loading…';
  static const String commonLoadingUr = 'لوڈ ہو رہا ہے…';
  static const String commonError = 'Something went wrong';
  static const String commonErrorUr = 'کچھ غلط ہو گیا';
  static const String commonNoData = 'No data available';
  static const String commonNoDataUr = 'کوئی ڈیٹا دستیاب نہیں';
  static const String commonNoInternet = 'No internet connection';
  static const String commonNoInternetUr = 'انٹرنیٹ کنکشن نہیں ہے';
  static const String commonPermissionDenied = 'Permission denied';
  static const String commonPermissionDeniedUr = 'اجازت سے انکار';
  static const String commonLocationDisabled = 'Location services are disabled';
  static const String commonLocationDisabledUr = 'مقام کی خدمات غیر فعال ہیں';
  static const String commonTurnOnLocation = 'Please turn on location services to use this feature.';
  static const String commonTurnOnLocationUr = 'اس فیچر کو استعمال کرنے کے لیے مقام کی خدمات چالو کریں۔';
  static const String commonSeconds = 'seconds';
  static const String commonSecondsUr = 'سیکنڈ';
  static const String commonMinutes = 'minutes';
  static const String commonMinutesUr = 'منٹ';
  static const String commonAgo = 'ago';
  static const String commonAgoUr = 'پہلے';
  static const String commonJustNow = 'Just now';
  static const String commonJustNowUr = 'ابھی';

  // ─────────────────────────────────────────────────────────────────────────
  // Error Messages
  // ─────────────────────────────────────────────────────────────────────────
  static const String errorNetworkTimeout = 'Request timed out. Check your connection.';
  static const String errorNetworkTimeoutUr = 'درخواست کا وقت ختم ہو گیا۔ اپنا کنکشن چیک کریں۔';
  static const String errorUnauthorized = 'Session expired. Please sign in again.';
  static const String errorUnauthorizedUr = 'سیشن ختم ہو گیا۔ دوبارہ سائن ان کریں۔';
  static const String errorServerError = 'Server error. Please try again later.';
  static const String errorServerErrorUr = 'سرور کی خرابی۔ بعد میں دوبارہ کوشش کریں۔';
  static const String errorLocationFailed = 'Unable to fetch your location.';
  static const String errorLocationFailedUr = 'آپ کا مقام حاصل کرنے سے قاصر۔';
  static const String errorAuthFailed = 'Authentication failed. Check your credentials.';
  static const String errorAuthFailedUr = 'تصدیق ناکام ہوئی۔ اپنی اسناد چیک کریں۔';
  static const String errorUserNotFound = 'User not found.';
  static const String errorUserNotFoundUr = 'صارف نہیں ملا۔';
  static const String errorEmailAlreadyInUse = 'This email is already registered.';
  static const String errorEmailAlreadyInUseUr = 'یہ ای میل پہلے سے رجسٹرڈ ہے۔';
  static const String errorWrongPassword = 'Incorrect password.';
  static const String errorWrongPasswordUr = 'غلط پاس ورڈ۔';
}

/// Locale-aware string accessor.
class AppStringsLocale {
  final bool isUrdu;
  const AppStringsLocale({required this.isUrdu});

  String get appName => isUrdu ? AppStrings.appNameUr : AppStrings.appName;
  String get appTagline => isUrdu ? AppStrings.appTaglineUr : AppStrings.appTagline;
  String get authEmail => isUrdu ? AppStrings.authEmailUr : AppStrings.authEmail;
  String get authPassword => isUrdu ? AppStrings.authPasswordUr : AppStrings.authPassword;
  String get authSignIn => isUrdu ? AppStrings.authSignInUr : AppStrings.authSignIn;
  String get commonError => isUrdu ? AppStrings.commonErrorUr : AppStrings.commonError;
  String get commonLoading => isUrdu ? AppStrings.commonLoadingUr : AppStrings.commonLoading;
  String get sosTitle => isUrdu ? AppStrings.sosTitleUr : AppStrings.sosTitle;
}
