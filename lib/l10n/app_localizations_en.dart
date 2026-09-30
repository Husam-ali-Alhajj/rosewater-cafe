// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navQrCode => 'QR Code';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInSubtitle => 'Sign in to your account';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String get emailAddressHint => 'your@email.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signInButton => 'Sign In';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInGenericError =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get welcomeGeneric => 'Welcome!';

  @override
  String welcomeNamed(String name) {
    return 'Welcome, $name!';
  }

  @override
  String memberIdLabel(String id) {
    return 'Member ID: $id';
  }

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get membershipStatus => 'Membership Status';

  @override
  String memberSuffix(String plan) {
    return '$plan Member';
  }

  @override
  String get activeStatus => 'Active';

  @override
  String validUntil(String date) {
    return 'Valid until: $date';
  }

  @override
  String get accessCafe => 'Access Café';

  @override
  String get reserveEvent => 'Reserve Event';

  @override
  String get hookahSessions => 'Hookah Sessions';

  @override
  String get drinks => 'Drinks';

  @override
  String get unlimited => 'Unlimited';

  @override
  String usedThisMonth(int used) {
    return '$used used this month';
  }

  @override
  String get serviceHours => 'Service Hours';

  @override
  String get fullServiceHours => 'Full Service Hours';

  @override
  String get fullServiceHoursValue => '9:00 AM - 11:00 PM';

  @override
  String get selfServiceHours => 'Self-Service Hours';

  @override
  String get selfServiceHoursValue => '11:00 PM - 9:00 AM';

  @override
  String get currentStatusLabel => 'Current Status: ';

  @override
  String get fullServiceAvailable => 'Full service available';

  @override
  String get selfServiceHoursStatus => 'Self-service hours';

  @override
  String get membershipBenefits => 'Membership Benefits';

  @override
  String comingSoonSuffix(String label) {
    return '$label — coming in a future task';
  }

  @override
  String get genericConnectionError =>
      'Something went wrong. Check your connection and try again.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get passwordHelperText =>
      '8+ characters, with uppercase, lowercase & a number';

  @override
  String get authLandingTagline => 'VIP Membership & Lounge';

  @override
  String get featurePremiumLounge => 'Premium Lounge';

  @override
  String get featureExclusiveServices => 'Exclusive Services';

  @override
  String get featureBringGuests => 'Bring Guests';

  @override
  String get authLandingFooter => 'Premium hookah lounge & café experience';

  @override
  String get createAccountHeading => 'Create Account';

  @override
  String get joinToday => 'Join Rosewater Café today';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get fullNameHint => 'John Doe';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get phoneNumberHint => '+1 (555) 000-0000';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get agreeToTermsPrefix => 'I agree to the ';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get agreeToTermsAnd => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get mustAgreeToContinue => 'You must agree to continue';

  @override
  String get creatingAccount => 'Creating account…';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get forgotPasswordSubtitle =>
      'No worries! Enter your email address and we\'ll send you a link to reset your password.';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get sendingEllipsis => 'Sending…';

  @override
  String get checkYourEmail => 'Check Your Email';

  @override
  String resetLinkSentBody(String email) {
    return 'If an account exists for $email, we\'ve sent a link to reset your password. Check your inbox (and spam folder).';
  }

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get setNewPasswordHeading => 'Set New Password';

  @override
  String get chooseNewPasswordSubtitle =>
      'Choose a new password for your account.';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmNewPasswordLabel => 'Confirm New Password';

  @override
  String get updatingEllipsis => 'Updating…';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdatedHeading => 'Password Updated';

  @override
  String get passwordUpdatedBody =>
      'Your password has been changed. Please sign in with your new password.';

  @override
  String get continueToSignIn => 'Continue to Sign In';

  @override
  String get couldNotUpdatePasswordError =>
      'Couldn\'t update your password. Check your connection and try again.';

  @override
  String get confirmYourEmailHeading => 'Confirm Your Email';

  @override
  String confirmEmailBody(String email) {
    return 'Your account is almost ready. We\'ve sent a confirmation link to $email — click it to activate your account, then sign in.';
  }

  @override
  String get chooseYourMembership => 'Choose Your Membership';

  @override
  String get selectPlanSubtitle => 'Select the plan that fits your lifestyle';

  @override
  String get couldNotLoadPlansError =>
      'Could not load membership plans. Check your connection and try again.';

  @override
  String get allPlansFooter =>
      'All plans include member discounts. Guest orders not included in allowance.';

  @override
  String get mostPopularBadge => 'Most Popular';

  @override
  String get perMonthSuffix => '/month';

  @override
  String get selectingEllipsis => 'Selecting…';

  @override
  String selectPlanButton(String plan) {
    return 'Select $plan';
  }

  @override
  String get unlimitedHookahFeature => 'Unlimited Hookah';

  @override
  String hookahSessionsPerMonth(int count) {
    return '$count Hookah sessions/month';
  }

  @override
  String get unlimitedDrinksFeature => 'Unlimited Drinks';

  @override
  String drinksIncludedCount(int count) {
    return '$count Drinks included';
  }

  @override
  String get bringGuestBulletSingular => 'Bring 1 guest';

  @override
  String bringGuestBulletPlural(int max) {
    return 'Bring $max guests';
  }

  @override
  String get planFeatureStandardSeating => 'Standard seating';

  @override
  String get planFeatureMemberDiscounts => 'Member discounts';

  @override
  String get planFeaturePrioritySeating => 'Priority seating';

  @override
  String get planFeatureWeekendAccess => 'Weekend access';

  @override
  String get planFeaturePrivateBooth => 'Private booth';

  @override
  String get planFeature247Access => '24/7 access';

  @override
  String get planFeatureEventPriority => 'Event priority';

  @override
  String get planFeatureExclusiveMenu => 'Exclusive menu';

  @override
  String get couldNotLoadDetailsError =>
      'Could not load your details. Check your connection and try again.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get chooseFileHint => 'Choose File (PNG, JPG, PDF)';

  @override
  String get cameraGalleryAccessError =>
      'Could not access the camera/gallery. Check app permissions and try again.';

  @override
  String get filePickerError => 'Could not open the file picker. Try again.';

  @override
  String get invalidIdFileType => 'Please choose a PNG, JPG, or PDF file.';

  @override
  String idFileTooLarge(int mb) {
    return 'That file is too large — max ${mb}MB.';
  }

  @override
  String get uploadFailedError =>
      'Upload failed. Check your connection and try again.';

  @override
  String get cancellingEllipsis => 'Cancelling…';

  @override
  String get backToPlans => 'Back to Plans';

  @override
  String get verifyYourMembership => 'Verify Your Membership';

  @override
  String get subscriptionPlanLabel => 'Subscription Plan';

  @override
  String get uploadIdDocumentLabel => 'Upload ID Document';

  @override
  String get requiredForVerification =>
      'Required for membership verification and security';

  @override
  String get uploadingEllipsis => 'Uploading…';

  @override
  String get continueToPayment => 'Continue to Payment';

  @override
  String get clickToUploadId => 'Click to upload ID';

  @override
  String get idFileTypesHint => 'PNG, JPG, PDF (max 10MB)';

  @override
  String get couldNotGoBackToPlansError =>
      'Could not go back to plans. Check your connection and try again.';

  @override
  String get completePayment => 'Complete Payment';

  @override
  String planSuffix(String plan) {
    return '$plan Plan';
  }

  @override
  String get monthlySubscription => 'Monthly Subscription';

  @override
  String get totalLabel => 'Total';

  @override
  String get cardNumberLabel => 'Card Number';

  @override
  String get expiryDateLabel => 'Expiry Date';

  @override
  String get cvvLabel => 'CVV';

  @override
  String get paymentFailedError =>
      'Payment failed. Check your connection and try again.';

  @override
  String get backButton => 'Back';

  @override
  String get payingEllipsis => 'Paying…';

  @override
  String payAmountButton(String amount) {
    return 'Pay $amount';
  }

  @override
  String get youAreMember => 'You\'re a Member!';

  @override
  String welcomeMembershipActive(String plan) {
    return 'Welcome to Rosewater Café. Your $plan membership is now active.';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get eventTypeBirthday => 'Birthday';

  @override
  String get eventTypeCorporate => 'Corporate';

  @override
  String get eventTypePrivateParty => 'Private Party';

  @override
  String get eventTypeOther => 'Other';

  @override
  String get durationRequired => 'Duration is required';

  @override
  String get enterValidNumberDecimal =>
      'Enter a valid number (up to 2 decimal places)';

  @override
  String get durationMustBeGreaterThanZero => 'Duration must be greater than 0';

  @override
  String get guestCountRequired => 'Number of guests is required';

  @override
  String get enterValidNumber => 'Enter a valid number';

  @override
  String get guestCountRange => 'Minimum 5 guests, maximum 100 guests';

  @override
  String get genericTryAgainError => 'Something went wrong. Please try again.';

  @override
  String get backToDashboard => 'Back to Dashboard';

  @override
  String get reserveAnEvent => 'Reserve an Event';

  @override
  String get reserveEventSubtitle =>
      'Book the café for your private event. Perfect for parties, meetings, and special occasions.';

  @override
  String get eventTypeLabel => 'Event Type';

  @override
  String get pleaseSelectEventType => 'Please select an event type';

  @override
  String get selectEventTypeHint => 'Select event type';

  @override
  String get eventDateLabel => 'Event Date';

  @override
  String get selectDateHint => 'Select a date';

  @override
  String get eventDateRequired => 'Event date is required';

  @override
  String get datePassedError =>
      'That date has already passed -- please choose another.';

  @override
  String get startTimeLabel => 'Start Time';

  @override
  String get selectTimeHint => 'Select a time';

  @override
  String get startTimeRequired => 'Start time is required';

  @override
  String get durationHoursLabel => 'Duration (hours)';

  @override
  String get durationExampleHint => 'e.g. 2';

  @override
  String get numberOfGuestsLabel => 'Number of Guests';

  @override
  String get confirmingEllipsis => 'Confirming…';

  @override
  String get confirmReservation => 'Confirm Reservation';

  @override
  String get eventPackageIncludes => 'Event Package Includes:';

  @override
  String get packageBulletCafe => 'Exclusive use of the café';

  @override
  String get packageBulletHookah => 'Complimentary hookah for all guests';

  @override
  String get packageBulletMenu => 'Special event menu available';

  @override
  String get packageBulletStaff => 'Dedicated staff service';

  @override
  String get packageBulletSound => 'Sound system and music control';

  @override
  String get baseRatePerHour => 'Base rate (per hour)';

  @override
  String get durationRowLabel => 'Duration';

  @override
  String durationHoursValue(String hours) {
    return '$hours hours';
  }

  @override
  String get estimatedTotal => 'Estimated Total';

  @override
  String get eventReservationConfirmedBanner => 'Event reservation confirmed!';

  @override
  String get reservationConfirmedHeading => 'Reservation Confirmed!';

  @override
  String get reservationConfirmedSubtitle =>
      'Your event has been successfully reserved';

  @override
  String get dateColonLabel => 'Date:';

  @override
  String get timeColonLabel => 'Time:';

  @override
  String get durationColonLabel => 'Duration:';

  @override
  String get guestsColonLabel => 'Guests:';

  @override
  String get hourSingular => 'hour';

  @override
  String get hourPlural => 'hours';

  @override
  String get peopleLabel => 'people';

  @override
  String get doorAccessHeading => 'Door Access';

  @override
  String get doorUnlockedMessage => 'Door unlocked! Enjoy your visit.';

  @override
  String get unableToLoadMemberId => 'Unable to load your member ID';

  @override
  String get scanQrInstruction =>
      'Scan this QR code at the entrance to unlock the door';

  @override
  String get howManyPeopleQuestion => 'How many people are with you?';

  @override
  String guestAllowanceSingular(int max, String plan) {
    return 'You can bring up to $max guest with your $plan membership';
  }

  @override
  String guestAllowancePlural(int max, String plan) {
    return 'You can bring up to $max guests with your $plan membership';
  }

  @override
  String get openingEllipsis => 'Opening…';

  @override
  String get openDoorButton => 'Open Door';

  @override
  String get guestsCounterLabel => 'Guests';

  @override
  String get noteLabel => 'Note: ';

  @override
  String get guestOrdersNote =>
      'Your monthly allowance covers your orders only. Guest orders will receive member discounts but are paid separately.';

  @override
  String get skipButton => 'Skip';

  @override
  String get nextButton => 'Next';

  @override
  String get previousButton => 'Previous';

  @override
  String get getStartedButton => 'Get Started';

  @override
  String get onboardingWelcomeHeading => 'Welcome to Rosewater Café';

  @override
  String get onboardingWelcomeBody =>
      'Experience the finest hookah lounge with exclusive VIP memberships, premium services, and a luxurious atmosphere.';

  @override
  String get onboardingQrHeading => 'QR Code Door Access';

  @override
  String get onboardingQrBody =>
      'Unlock the café with your personal QR code. Bring guests and track your visits effortlessly.';

  @override
  String get onboardingAllowancesHeading => 'Monthly Allowances';

  @override
  String get onboardingAllowancesBody =>
      'Enjoy included hookah sessions and drinks every month. Track your usage and maximize your membership benefits.';

  @override
  String get onboardingEventsHeading => 'Exclusive Events';

  @override
  String get onboardingEventsBody =>
      'Reserve the entire café for private events. Get priority booking and VIP discounts on special occasions.';

  @override
  String get profileHeading => 'Profile';

  @override
  String get editProfileButton => 'Edit Profile';

  @override
  String planBadgeSuffix(String plan) {
    return '$plan Member';
  }

  @override
  String get couldntLoadProfile => 'Couldn\'t load your profile.';

  @override
  String get tryAgainButton => 'Try again';

  @override
  String get membershipDetailsTitle => 'Membership Details';

  @override
  String get planLabel => 'Plan';

  @override
  String get validUntilLabel => 'Valid Until';

  @override
  String get maxGuestsLabel => 'Max Guests';

  @override
  String get upgradeMembershipButton => 'Upgrade Membership';

  @override
  String get upgradeMembershipSubtitle =>
      'Choose a higher-tier plan to unlock more benefits';

  @override
  String get upgradingEllipsis => 'Upgrading…';

  @override
  String upgradeToPlanButton(String plan) {
    return 'Upgrade to $plan';
  }

  @override
  String get noUpgradeAvailable =>
      'No higher-tier plan is available right now.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get paymentMethodsLabel => 'Payment Methods';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get privacySecurityLabel => 'Privacy & Security';

  @override
  String get helpSupportLabel => 'Help & Support';

  @override
  String get appSettingsLabel => 'App Settings';

  @override
  String get signOutButton => 'Sign Out';

  @override
  String versionFooter(String version) {
    return 'Version $version • Rosewater Café';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get savingEllipsis => 'Saving…';

  @override
  String get takePhotoOption => 'Take Photo';

  @override
  String get chooseFromGalleryOption => 'Choose from Gallery';

  @override
  String get photoTypeError => 'Please choose a PNG, JPG or WebP image.';

  @override
  String photoTooLargeError(int mb) {
    return 'That photo is too large (max ${mb}MB).';
  }

  @override
  String get saveChangesButton => 'Save Changes';

  @override
  String get personalInformationTitle => 'Personal Information';

  @override
  String get emailCantBeChangedNote =>
      'Your email can\'t be changed in the app.';

  @override
  String get membershipInformationTitle => 'Membership Information';

  @override
  String get memberIdFieldLabel => 'Member ID';

  @override
  String get subscriptionTypeLabel => 'Subscription Type';

  @override
  String get contactSupportNote => 'Contact support to change membership type';

  @override
  String get changePhotoTooltip => 'Change photo';

  @override
  String get tapCameraIconHint => 'Tap camera icon to change photo';

  @override
  String get couldntSaveChangesError =>
      'Couldn\'t save your changes. Check your connection and try again.';

  @override
  String get addNewPaymentMethodButton => 'Add New Payment Method';

  @override
  String get couldntLoadPaymentMethods =>
      'Couldn\'t load your payment methods.';

  @override
  String get noPaymentMethodsYet => 'You haven\'t added a payment method yet.';

  @override
  String get removeCardTitle => 'Remove this card?';

  @override
  String removeCardBody(String brand, String last4) {
    return '$brand ending in $last4 will be removed from your account.';
  }

  @override
  String get removeButton => 'Remove';

  @override
  String get setAsDefaultTooltip => 'Set as default';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get defaultBadge => 'Default';

  @override
  String get addPaymentMethodHeading => 'Add Payment Method';

  @override
  String get setAsDefaultPaymentCheckbox => 'Set as default payment method';

  @override
  String get cardSecurityNote =>
      'For your security, only the card type, last 4 digits and expiry date are saved — never your full card number or CVV.';

  @override
  String get couldntSaveCardError =>
      'Couldn\'t save your card. Check your connection and try again.';

  @override
  String get saveCardButton => 'Save Card';

  @override
  String get doneButton => 'Done';

  @override
  String get couldntSaveSettingError =>
      'Couldn\'t save that setting. Please try again.';

  @override
  String get communicationPreferencesTitle => 'Communication Preferences';

  @override
  String get communicationPreferencesSubtitle =>
      'Choose how you want to be notified';

  @override
  String get notificationTypesTitle => 'Notification Types';

  @override
  String get pushNotificationsLabel => 'Push Notifications';

  @override
  String get pushNotificationsDescription =>
      'Receive notifications on your device';

  @override
  String get emailNotificationsLabel => 'Email Notifications';

  @override
  String get emailNotificationsDescription => 'Get updates via email';

  @override
  String get smsNotificationsLabel => 'SMS Notifications';

  @override
  String get smsNotificationsDescription =>
      'Receive text messages for important updates';

  @override
  String get soundVibrationLabel => 'Sound & Vibration';

  @override
  String get soundVibrationDescription =>
      'Play sound when notifications arrive';

  @override
  String get eventRemindersLabel => 'Event Reminders';

  @override
  String get eventRemindersDescription =>
      'Get reminded about your upcoming reservations';

  @override
  String get allowanceAlertsLabel => 'Allowance Alerts';

  @override
  String get allowanceAlertsDescription =>
      'Notify when allowances are running low';

  @override
  String get promotionsOffersLabel => 'Promotions & Offers';

  @override
  String get promotionsOffersDescription =>
      'Receive special deals and member benefits';

  @override
  String get cacheClearedMessage => 'Cache cleared.';

  @override
  String get clearAllAppDataTitle => 'Clear all app data?';

  @override
  String get clearAllAppDataBody =>
      'This removes every saved preference from this device and signs you out. Your account and its data aren\'t affected -- you can sign back in normally.';

  @override
  String get clearAndSignOutButton => 'Clear & Sign Out';

  @override
  String get appearanceCardTitle => 'Appearance';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get darkModeDescription => 'Switch to dark theme';

  @override
  String get animationsLabel => 'Animations';

  @override
  String get animationsDescription =>
      'Enable smooth animations throughout the app';

  @override
  String get languageSectionLabel => 'Language';

  @override
  String get interactionsCardTitle => 'Interactions';

  @override
  String get soundEffectsLabel => 'Sound Effects';

  @override
  String get soundEffectsDescription =>
      'Play sounds for actions and notifications';

  @override
  String get hapticFeedbackLabel => 'Haptic Feedback';

  @override
  String get hapticFeedbackDescription =>
      'Vibrate on button presses and interactions';

  @override
  String get dataStorageCardTitle => 'Data & Storage';

  @override
  String get cacheSizeLabel => 'Cache Size';

  @override
  String get clearCacheButton => 'Clear Cache';

  @override
  String get clearAllAppDataButton => 'Clear All App Data';

  @override
  String versionLine(String version) {
    return 'Version $version';
  }

  @override
  String buildLine(String build) {
    return 'Build $build';
  }

  @override
  String get passwordSectionTitle => 'Password';

  @override
  String get emailSectionTitle => 'Email';

  @override
  String get privacySectionTitle => 'Privacy';

  @override
  String get securityOptionsTitle => 'Security Options';

  @override
  String get biometricAuthLabel => 'Biometric Authentication';

  @override
  String get biometricAuthDescription =>
      'Use fingerprint or face ID to sign in';

  @override
  String get twoFactorAuthLabel => 'Two-Factor Authentication';

  @override
  String get twoFactorAuthDescription => 'Add an extra layer of security';

  @override
  String get comingSoonNote => '(Coming Soon)';

  @override
  String get autoLockLabel => 'Auto-Lock';

  @override
  String get autoLockDescription => 'Automatically lock app when inactive';

  @override
  String get noBiometricsAvailableError =>
      'No biometrics available on this device. Set up a fingerprint or face unlock first.';

  @override
  String get strongPasswordPrompt =>
      'Keep your account secure by using a strong password';

  @override
  String get changePasswordButton => 'Change Password';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get enterCurrentPasswordHint => 'Enter current password';

  @override
  String get enterNewPasswordHint => 'Enter new password';

  @override
  String get confirmNewPasswordHint => 'Confirm new password';

  @override
  String get updatePasswordButton => 'Update Password';

  @override
  String get enterCurrentPasswordError => 'Enter your current password';

  @override
  String get passwordMustDifferError =>
      'Choose a password different from your current one.';

  @override
  String get couldntUpdatePasswordError =>
      'Couldn\'t update your password. Check your connection and try again.';

  @override
  String get passwordUpdatedMessage => 'Password updated.';

  @override
  String get deleteAccountLabel => 'Delete Account';

  @override
  String get deleteAccountWarning =>
      'This immediately and permanently deletes your account and everything in it -- your profile, membership, payment methods, and reservation history. This cannot be undone.';

  @override
  String get deletePermanentlyButton => 'Delete Permanently';

  @override
  String get deletingEllipsis => 'Deleting…';

  @override
  String get couldntDeleteAccountError =>
      'Couldn\'t delete your account. Please try again.';

  @override
  String get changeEmailButton => 'Change Email';

  @override
  String confirmationSentToEmail(String email) {
    return 'Confirmation sent to $email -- click the link there to finish. Your current email still works until then.';
  }

  @override
  String get newEmailFormInstructions =>
      'Enter your new email address and current password. We\'ll send a confirmation link to the new address -- your current email keeps working until you click it.';

  @override
  String get newEmailAddressLabel => 'New Email Address';

  @override
  String get sendConfirmationButton => 'Send Confirmation';

  @override
  String get couldntUpdateEmailError =>
      'Couldn\'t update your email. Check your connection and try again.';

  @override
  String get viewPrivacyPolicyLabel => 'View Privacy Policy';

  @override
  String get legalDraftDisclaimer =>
      'Draft placeholder text -- not written or reviewed by a lawyer. This is not final legal coverage and will be replaced with company-approved copy before launch.';

  @override
  String get showPasswordTooltip => 'Show password';

  @override
  String get hidePasswordTooltip => 'Hide password';

  @override
  String get liveChatTitle => 'Live Chat';

  @override
  String get liveChatDescription => 'Chat with our team';

  @override
  String get emailUsTitle => 'Email Us';

  @override
  String get emailUsDescription => 'Get help via email';

  @override
  String get callUsTitle => 'Call Us';

  @override
  String get callUsDescription => 'Speak to support';

  @override
  String get faqCardTitle => 'Frequently Asked Questions';

  @override
  String get faqQuestion1 => 'How do I use my QR code to enter the café?';

  @override
  String get faqAnswer1 =>
      'Simply open the QR Code section from your dashboard, show it to the scanner at the entrance, and specify how many guests are with you.';

  @override
  String get faqQuestion2 => 'What happens when my monthly allowance runs out?';

  @override
  String get faqAnswer2 =>
      'If you have Allowance Alerts turned on, we\'ll send you a low-allowance alert once you\'re down to 3 or fewer hookah sessions or drinks for the month, so you\'re not caught by surprise. Your allowance starts fresh with each new membership period — or right away if you upgrade to a higher plan from Profile for a bigger monthly allowance.';

  @override
  String get faqQuestion3 => 'Can I bring guests to the café?';

  @override
  String get faqAnswer3 =>
      'Yes — every plan includes a guest limit, shown as Max Guests in your Membership Details. When you open the door with your QR code, choose how many guests are with you, up to that limit. Your monthly allowance covers your own orders only; guest orders get member discounts but are paid separately.';

  @override
  String get faqQuestion4 =>
      'What\'s the difference between full service and self-service hours?';

  @override
  String get faqAnswer4 =>
      'Full Service Hours (9:00 AM – 11:00 PM) are staffed, with our team handling orders and hookah setup for you. Self-Service Hours (11:00 PM – 9:00 AM) let members access the space with their membership, but without staff on site, so it\'s a more limited, help-yourself experience.';

  @override
  String get faqDraftAnswerNote =>
      'Draft answer — pending confirmation from the company, not final copy.';

  @override
  String get resourcesCardTitle => 'Resources';

  @override
  String get userGuideLabel => 'User Guide';

  @override
  String get membershipBenefitsLabel => 'Membership Benefits';

  @override
  String get communityGuidelinesLabel => 'Community Guidelines';

  @override
  String get appLockedTitle => 'App Locked';

  @override
  String get unlockWithBiometricPrompt =>
      'Unlock with your fingerprint or face to continue.';

  @override
  String get unlockWithPasswordPrompt => 'Enter your password to continue.';

  @override
  String get checkingEllipsis => 'Checking…';

  @override
  String get tryAgainBiometricButton => 'Try Again';

  @override
  String get usePasswordInsteadButton => 'Use Password Instead';

  @override
  String get passwordFieldLabel => 'Password';

  @override
  String get verifyingEllipsis => 'Verifying…';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get useBiometricInsteadButton => 'Use Biometric Instead';

  @override
  String get enterYourPasswordError => 'Enter your password';

  @override
  String get couldntVerifyPasswordError =>
      'Couldn\'t verify your password. Check your connection and try again.';

  @override
  String get unlockReasonPrompt => 'Unlock Rosewater Café';

  @override
  String get couldntSignOutError => 'Couldn\'t sign out. Please try again.';

  @override
  String get notifSubscriptionActivatedTitle => 'Membership Activated';

  @override
  String notifSubscriptionActivatedBody(String plan, String date) {
    return 'Your $plan membership is now active until $date.';
  }

  @override
  String get notifEventReservationConfirmedTitle =>
      'Event Reservation Confirmed';

  @override
  String notifEventReservationConfirmedBody(
    String eventType,
    String date,
    String time,
    int guestCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      guestCount,
      locale: localeName,
      other: '$guestCount guests',
      one: '1 guest',
    );
    return 'Your $eventType reservation on $date at $time for $_temp0 is confirmed.';
  }

  @override
  String unreadNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
      zero: 'No unread notifications',
    );
    return '$_temp0';
  }

  @override
  String unreadBadgeSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
    );
    return '$_temp0';
  }

  @override
  String get markAsReadButton => 'Mark as Read';

  @override
  String get viewDetailsButton => 'View Details';

  @override
  String get noNotificationsTitle => 'No notifications yet';

  @override
  String get noNotificationsBody =>
      'Payment and event reservation updates will show up here.';

  @override
  String get couldntLoadNotificationsError =>
      'Couldn\'t load your notifications.';

  @override
  String get couldntUpdateNotificationError =>
      'Couldn\'t update that notification. Please try again.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int n) {
    return '${n}m ago';
  }

  @override
  String timeHoursAgo(int n) {
    return '${n}h ago';
  }

  @override
  String timeDaysAgo(int n) {
    return '${n}d ago';
  }

  @override
  String get notifEventReminderTitle => 'Event Reminder';

  @override
  String notifEventReminderBody(
    String eventType,
    String date,
    String time,
    int guestCount,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      guestCount,
      locale: localeName,
      other: '$guestCount guests',
      one: '1 guest',
    );
    return 'Your $eventType reservation is coming up on $date at $time for $_temp0.';
  }

  @override
  String get notifLowAllowanceTitle => 'Low Allowance Alert';

  @override
  String notifLowHookahBody(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'You have only $remaining hookah sessions remaining this month.',
      one: 'You have only 1 hookah session remaining this month.',
      zero: 'You have used all your hookah sessions this month.',
    );
    return '$_temp0';
  }

  @override
  String notifLowDrinksBody(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'You have only $remaining drinks remaining this month.',
      one: 'You have only 1 drink remaining this month.',
      zero: 'You have used all your drinks this month.',
    );
    return '$_temp0';
  }

  @override
  String get reservationDetailsTitle => 'Reservation Details';

  @override
  String get reservationStatusConfirmed => 'Confirmed';

  @override
  String get reservationStatusPending => 'Pending';

  @override
  String get reservationStatusCancelled => 'Cancelled';

  @override
  String get totalColonLabel => 'Total:';

  @override
  String get reservationNotFound => 'This reservation is no longer available.';

  @override
  String get couldntLoadReservationError => 'Couldn\'t load this reservation.';

  @override
  String get payWithLabel => 'Pay with';

  @override
  String get useNewCardOption => 'Use a new card';

  @override
  String get saveCardForNextTime => 'Save this card for next time';

  @override
  String cardExpiryShort(String date) {
    return 'Exp $date';
  }

  @override
  String get cardExpiredLabel => 'Expired';

  @override
  String get notifSubscriptionUpgradedTitle => 'Membership Upgraded';

  @override
  String notifSubscriptionUpgradedBody(
    String oldPlan,
    String newPlan,
    String date,
  ) {
    return 'You\'ve upgraded from $oldPlan to $newPlan. Your new membership is active until $date.';
  }
}
