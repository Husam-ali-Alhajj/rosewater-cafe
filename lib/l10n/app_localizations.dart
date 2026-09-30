import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get navQrCode;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// Bottom nav tab label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Sign In screen heading
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInSubtitle;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get emailAddressHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get passwordHint;

  /// Sign In password field validator message
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @noAccountPrompt.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountPrompt;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get signInGenericError;

  /// Home header greeting when no profile name is available
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeGeneric;

  /// Home header greeting with the member's first name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeNamed(String name);

  /// Home header member ID line
  ///
  /// In en, this message translates to:
  /// **'Member ID: {id}'**
  String memberIdLabel(String id);

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @membershipStatus.
  ///
  /// In en, this message translates to:
  /// **'Membership Status'**
  String get membershipStatus;

  /// Home status card title, e.g. "Premium Member" -- {plan} is the real plan name, not translated
  ///
  /// In en, this message translates to:
  /// **'{plan} Member'**
  String memberSuffix(String plan);

  /// Home status card badge
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// Home status card, e.g. "Valid until: 6/1/2026" -- {date} is a pre-formatted M/D/YYYY string, not re-formatted per locale
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String validUntil(String date);

  /// Home quick-action button
  ///
  /// In en, this message translates to:
  /// **'Access Café'**
  String get accessCafe;

  /// Home quick-action button
  ///
  /// In en, this message translates to:
  /// **'Reserve Event'**
  String get reserveEvent;

  /// No description provided for @hookahSessions.
  ///
  /// In en, this message translates to:
  /// **'Hookah Sessions'**
  String get hookahSessions;

  /// No description provided for @drinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get drinks;

  /// Usage card value when a plan has no limit for that allowance
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// Usage card caption
  ///
  /// In en, this message translates to:
  /// **'{used} used this month'**
  String usedThisMonth(int used);

  /// No description provided for @serviceHours.
  ///
  /// In en, this message translates to:
  /// **'Service Hours'**
  String get serviceHours;

  /// No description provided for @fullServiceHours.
  ///
  /// In en, this message translates to:
  /// **'Full Service Hours'**
  String get fullServiceHours;

  /// No description provided for @fullServiceHoursValue.
  ///
  /// In en, this message translates to:
  /// **'9:00 AM - 11:00 PM'**
  String get fullServiceHoursValue;

  /// No description provided for @selfServiceHours.
  ///
  /// In en, this message translates to:
  /// **'Self-Service Hours'**
  String get selfServiceHours;

  /// No description provided for @selfServiceHoursValue.
  ///
  /// In en, this message translates to:
  /// **'11:00 PM - 9:00 AM'**
  String get selfServiceHoursValue;

  /// No description provided for @currentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Status: '**
  String get currentStatusLabel;

  /// No description provided for @fullServiceAvailable.
  ///
  /// In en, this message translates to:
  /// **'Full service available'**
  String get fullServiceAvailable;

  /// Status banner text when outside full-service hours -- distinct string from selfServiceHours (a row label) even though the English happens to be similar
  ///
  /// In en, this message translates to:
  /// **'Self-service hours'**
  String get selfServiceHoursStatus;

  /// No description provided for @membershipBenefits.
  ///
  /// In en, this message translates to:
  /// **'Membership Benefits'**
  String get membershipBenefits;

  /// ComingSoonScreen's body text
  ///
  /// In en, this message translates to:
  /// **'{label} — coming in a future task'**
  String comingSoonSuffix(String label);

  /// Shared fallback for an unexpected (non-typed) network/server failure, several auth screens
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check your connection and try again.'**
  String get genericConnectionError;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordHelperText.
  ///
  /// In en, this message translates to:
  /// **'8+ characters, with uppercase, lowercase & a number'**
  String get passwordHelperText;

  /// No description provided for @authLandingTagline.
  ///
  /// In en, this message translates to:
  /// **'VIP Membership & Lounge'**
  String get authLandingTagline;

  /// No description provided for @featurePremiumLounge.
  ///
  /// In en, this message translates to:
  /// **'Premium Lounge'**
  String get featurePremiumLounge;

  /// No description provided for @featureExclusiveServices.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Services'**
  String get featureExclusiveServices;

  /// No description provided for @featureBringGuests.
  ///
  /// In en, this message translates to:
  /// **'Bring Guests'**
  String get featureBringGuests;

  /// No description provided for @authLandingFooter.
  ///
  /// In en, this message translates to:
  /// **'Premium hookah lounge & café experience'**
  String get authLandingFooter;

  /// Create Account screen heading -- same English text as the createAccount button/link label, kept as its own key since a heading and a button label can diverge later
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountHeading;

  /// No description provided for @joinToday.
  ///
  /// In en, this message translates to:
  /// **'Join Rosewater Café today'**
  String get joinToday;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fullNameHint;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In en, this message translates to:
  /// **'+1 (555) 000-0000'**
  String get phoneNumberHint;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @agreeToTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreeToTermsPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @agreeToTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get agreeToTermsAnd;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @mustAgreeToContinue.
  ///
  /// In en, this message translates to:
  /// **'You must agree to continue'**
  String get mustAgreeToContinue;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating account…'**
  String get creatingAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No worries! Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @sendingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sendingEllipsis;

  /// No description provided for @checkYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmail;

  /// Forgot Password success state -- deliberately worded to be true whether or not the account exists, never confirming/denying it
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we\'ve sent a link to reset your password. Check your inbox (and spam folder).'**
  String resetLinkSentBody(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @setNewPasswordHeading.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get setNewPasswordHeading;

  /// No description provided for @chooseNewPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get chooseNewPasswordSubtitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPasswordLabel;

  /// No description provided for @updatingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updatingEllipsis;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdatedHeading.
  ///
  /// In en, this message translates to:
  /// **'Password Updated'**
  String get passwordUpdatedHeading;

  /// No description provided for @passwordUpdatedBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed. Please sign in with your new password.'**
  String get passwordUpdatedBody;

  /// No description provided for @continueToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue to Sign In'**
  String get continueToSignIn;

  /// No description provided for @couldNotUpdatePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your password. Check your connection and try again.'**
  String get couldNotUpdatePasswordError;

  /// No description provided for @confirmYourEmailHeading.
  ///
  /// In en, this message translates to:
  /// **'Confirm Your Email'**
  String get confirmYourEmailHeading;

  /// Confirm Email Pending screen body
  ///
  /// In en, this message translates to:
  /// **'Your account is almost ready. We\'ve sent a confirmation link to {email} — click it to activate your account, then sign in.'**
  String confirmEmailBody(String email);

  /// No description provided for @chooseYourMembership.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Membership'**
  String get chooseYourMembership;

  /// No description provided for @selectPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the plan that fits your lifestyle'**
  String get selectPlanSubtitle;

  /// No description provided for @couldNotLoadPlansError.
  ///
  /// In en, this message translates to:
  /// **'Could not load membership plans. Check your connection and try again.'**
  String get couldNotLoadPlansError;

  /// No description provided for @allPlansFooter.
  ///
  /// In en, this message translates to:
  /// **'All plans include member discounts. Guest orders not included in allowance.'**
  String get allPlansFooter;

  /// No description provided for @mostPopularBadge.
  ///
  /// In en, this message translates to:
  /// **'Most Popular'**
  String get mostPopularBadge;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonthSuffix;

  /// No description provided for @selectingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Selecting…'**
  String get selectingEllipsis;

  /// Choose Membership card button -- {plan} is the real plan name, not translated
  ///
  /// In en, this message translates to:
  /// **'Select {plan}'**
  String selectPlanButton(String plan);

  /// Plan bullet (Choose Membership + Home Benefits) when hookah_limit is null
  ///
  /// In en, this message translates to:
  /// **'Unlimited Hookah'**
  String get unlimitedHookahFeature;

  /// Plan bullet (Choose Membership + Home Benefits) with a numeric hookah_limit
  ///
  /// In en, this message translates to:
  /// **'{count} Hookah sessions/month'**
  String hookahSessionsPerMonth(int count);

  /// Plan bullet (Choose Membership + Home Benefits) when drinks_limit is null
  ///
  /// In en, this message translates to:
  /// **'Unlimited Drinks'**
  String get unlimitedDrinksFeature;

  /// Plan bullet (Choose Membership + Home Benefits) with a numeric drinks_limit
  ///
  /// In en, this message translates to:
  /// **'{count} Drinks included'**
  String drinksIncludedCount(int count);

  /// Plan bullet (Choose Membership + Home Benefits), max_guests == 1
  ///
  /// In en, this message translates to:
  /// **'Bring 1 guest'**
  String get bringGuestBulletSingular;

  /// Plan bullet (Choose Membership + Home Benefits), max_guests > 1
  ///
  /// In en, this message translates to:
  /// **'Bring {max} guests'**
  String bringGuestBulletPlural(int max);

  /// A plan perk from the database, translated in utils/membership_localization.dart; unknown values are shown as stored
  ///
  /// In en, this message translates to:
  /// **'Standard seating'**
  String get planFeatureStandardSeating;

  /// No description provided for @planFeatureMemberDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Member discounts'**
  String get planFeatureMemberDiscounts;

  /// No description provided for @planFeaturePrioritySeating.
  ///
  /// In en, this message translates to:
  /// **'Priority seating'**
  String get planFeaturePrioritySeating;

  /// No description provided for @planFeatureWeekendAccess.
  ///
  /// In en, this message translates to:
  /// **'Weekend access'**
  String get planFeatureWeekendAccess;

  /// No description provided for @planFeaturePrivateBooth.
  ///
  /// In en, this message translates to:
  /// **'Private booth'**
  String get planFeaturePrivateBooth;

  /// No description provided for @planFeature247Access.
  ///
  /// In en, this message translates to:
  /// **'24/7 access'**
  String get planFeature247Access;

  /// No description provided for @planFeatureEventPriority.
  ///
  /// In en, this message translates to:
  /// **'Event priority'**
  String get planFeatureEventPriority;

  /// No description provided for @planFeatureExclusiveMenu.
  ///
  /// In en, this message translates to:
  /// **'Exclusive menu'**
  String get planFeatureExclusiveMenu;

  /// No description provided for @couldNotLoadDetailsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your details. Check your connection and try again.'**
  String get couldNotLoadDetailsError;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @chooseFileHint.
  ///
  /// In en, this message translates to:
  /// **'Choose File (PNG, JPG, PDF)'**
  String get chooseFileHint;

  /// No description provided for @cameraGalleryAccessError.
  ///
  /// In en, this message translates to:
  /// **'Could not access the camera/gallery. Check app permissions and try again.'**
  String get cameraGalleryAccessError;

  /// No description provided for @filePickerError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the file picker. Try again.'**
  String get filePickerError;

  /// No description provided for @invalidIdFileType.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PNG, JPG, or PDF file.'**
  String get invalidIdFileType;

  /// No description provided for @idFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That file is too large — max {mb}MB.'**
  String idFileTooLarge(int mb);

  /// No description provided for @uploadFailedError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get uploadFailedError;

  /// No description provided for @cancellingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Cancelling…'**
  String get cancellingEllipsis;

  /// No description provided for @backToPlans.
  ///
  /// In en, this message translates to:
  /// **'Back to Plans'**
  String get backToPlans;

  /// No description provided for @verifyYourMembership.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Membership'**
  String get verifyYourMembership;

  /// No description provided for @subscriptionPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription Plan'**
  String get subscriptionPlanLabel;

  /// No description provided for @uploadIdDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Upload ID Document'**
  String get uploadIdDocumentLabel;

  /// No description provided for @requiredForVerification.
  ///
  /// In en, this message translates to:
  /// **'Required for membership verification and security'**
  String get requiredForVerification;

  /// No description provided for @uploadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get uploadingEllipsis;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @clickToUploadId.
  ///
  /// In en, this message translates to:
  /// **'Click to upload ID'**
  String get clickToUploadId;

  /// No description provided for @idFileTypesHint.
  ///
  /// In en, this message translates to:
  /// **'PNG, JPG, PDF (max 10MB)'**
  String get idFileTypesHint;

  /// No description provided for @couldNotGoBackToPlansError.
  ///
  /// In en, this message translates to:
  /// **'Could not go back to plans. Check your connection and try again.'**
  String get couldNotGoBackToPlansError;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// Complete Payment screen subtitle -- {plan} is the real plan name, not translated
  ///
  /// In en, this message translates to:
  /// **'{plan} Plan'**
  String planSuffix(String plan);

  /// No description provided for @monthlySubscription.
  ///
  /// In en, this message translates to:
  /// **'Monthly Subscription'**
  String get monthlySubscription;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @cardNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumberLabel;

  /// No description provided for @expiryDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDateLabel;

  /// No description provided for @cvvLabel.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvvLabel;

  /// No description provided for @paymentFailedError.
  ///
  /// In en, this message translates to:
  /// **'Payment failed. Check your connection and try again.'**
  String get paymentFailedError;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @payingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Paying…'**
  String get payingEllipsis;

  /// e.g. "Pay $19.99" -- {amount} already includes the currency-formatted string
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String payAmountButton(String amount);

  /// No description provided for @youAreMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re a Member!'**
  String get youAreMember;

  /// No description provided for @welcomeMembershipActive.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rosewater Café. Your {plan} membership is now active.'**
  String welcomeMembershipActive(String plan);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @eventTypeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get eventTypeBirthday;

  /// No description provided for @eventTypeCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get eventTypeCorporate;

  /// No description provided for @eventTypePrivateParty.
  ///
  /// In en, this message translates to:
  /// **'Private Party'**
  String get eventTypePrivateParty;

  /// No description provided for @eventTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get eventTypeOther;

  /// No description provided for @durationRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration is required'**
  String get durationRequired;

  /// No description provided for @enterValidNumberDecimal.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number (up to 2 decimal places)'**
  String get enterValidNumberDecimal;

  /// No description provided for @durationMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Duration must be greater than 0'**
  String get durationMustBeGreaterThanZero;

  /// No description provided for @guestCountRequired.
  ///
  /// In en, this message translates to:
  /// **'Number of guests is required'**
  String get guestCountRequired;

  /// No description provided for @enterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get enterValidNumber;

  /// No description provided for @guestCountRange.
  ///
  /// In en, this message translates to:
  /// **'Minimum 5 guests, maximum 100 guests'**
  String get guestCountRange;

  /// Shared fallback for an unexpected failure, Reserve an Event / QR Access -- distinct wording from genericConnectionError (no "check your connection")
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericTryAgainError;

  /// No description provided for @backToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get backToDashboard;

  /// No description provided for @reserveAnEvent.
  ///
  /// In en, this message translates to:
  /// **'Reserve an Event'**
  String get reserveAnEvent;

  /// No description provided for @reserveEventSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book the café for your private event. Perfect for parties, meetings, and special occasions.'**
  String get reserveEventSubtitle;

  /// No description provided for @eventTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get eventTypeLabel;

  /// No description provided for @pleaseSelectEventType.
  ///
  /// In en, this message translates to:
  /// **'Please select an event type'**
  String get pleaseSelectEventType;

  /// No description provided for @selectEventTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Select event type'**
  String get selectEventTypeHint;

  /// No description provided for @eventDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Date'**
  String get eventDateLabel;

  /// No description provided for @selectDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDateHint;

  /// No description provided for @eventDateRequired.
  ///
  /// In en, this message translates to:
  /// **'Event date is required'**
  String get eventDateRequired;

  /// No description provided for @datePassedError.
  ///
  /// In en, this message translates to:
  /// **'That date has already passed -- please choose another.'**
  String get datePassedError;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTimeLabel;

  /// No description provided for @selectTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get selectTimeHint;

  /// No description provided for @startTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Start time is required'**
  String get startTimeRequired;

  /// No description provided for @durationHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (hours)'**
  String get durationHoursLabel;

  /// No description provided for @durationExampleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2'**
  String get durationExampleHint;

  /// No description provided for @numberOfGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Number of Guests'**
  String get numberOfGuestsLabel;

  /// No description provided for @confirmingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get confirmingEllipsis;

  /// No description provided for @confirmReservation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reservation'**
  String get confirmReservation;

  /// No description provided for @eventPackageIncludes.
  ///
  /// In en, this message translates to:
  /// **'Event Package Includes:'**
  String get eventPackageIncludes;

  /// No description provided for @packageBulletCafe.
  ///
  /// In en, this message translates to:
  /// **'Exclusive use of the café'**
  String get packageBulletCafe;

  /// No description provided for @packageBulletHookah.
  ///
  /// In en, this message translates to:
  /// **'Complimentary hookah for all guests'**
  String get packageBulletHookah;

  /// No description provided for @packageBulletMenu.
  ///
  /// In en, this message translates to:
  /// **'Special event menu available'**
  String get packageBulletMenu;

  /// No description provided for @packageBulletStaff.
  ///
  /// In en, this message translates to:
  /// **'Dedicated staff service'**
  String get packageBulletStaff;

  /// No description provided for @packageBulletSound.
  ///
  /// In en, this message translates to:
  /// **'Sound system and music control'**
  String get packageBulletSound;

  /// No description provided for @baseRatePerHour.
  ///
  /// In en, this message translates to:
  /// **'Base rate (per hour)'**
  String get baseRatePerHour;

  /// No description provided for @durationRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationRowLabel;

  /// Reserve an Event's price breakdown row -- always "hours" regardless of count, matching the original design copy exactly (not grammatically pluralized)
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String durationHoursValue(String hours);

  /// No description provided for @estimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'Estimated Total'**
  String get estimatedTotal;

  /// No description provided for @eventReservationConfirmedBanner.
  ///
  /// In en, this message translates to:
  /// **'Event reservation confirmed!'**
  String get eventReservationConfirmedBanner;

  /// No description provided for @reservationConfirmedHeading.
  ///
  /// In en, this message translates to:
  /// **'Reservation Confirmed!'**
  String get reservationConfirmedHeading;

  /// No description provided for @reservationConfirmedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your event has been successfully reserved'**
  String get reservationConfirmedSubtitle;

  /// No description provided for @dateColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get dateColonLabel;

  /// No description provided for @timeColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Time:'**
  String get timeColonLabel;

  /// No description provided for @durationColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get durationColonLabel;

  /// No description provided for @guestsColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests:'**
  String get guestsColonLabel;

  /// No description provided for @hourSingular.
  ///
  /// In en, this message translates to:
  /// **'hour'**
  String get hourSingular;

  /// No description provided for @hourPlural.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get hourPlural;

  /// No description provided for @peopleLabel.
  ///
  /// In en, this message translates to:
  /// **'people'**
  String get peopleLabel;

  /// No description provided for @doorAccessHeading.
  ///
  /// In en, this message translates to:
  /// **'Door Access'**
  String get doorAccessHeading;

  /// No description provided for @doorUnlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Door unlocked! Enjoy your visit.'**
  String get doorUnlockedMessage;

  /// No description provided for @unableToLoadMemberId.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your member ID'**
  String get unableToLoadMemberId;

  /// No description provided for @scanQrInstruction.
  ///
  /// In en, this message translates to:
  /// **'Scan this QR code at the entrance to unlock the door'**
  String get scanQrInstruction;

  /// No description provided for @howManyPeopleQuestion.
  ///
  /// In en, this message translates to:
  /// **'How many people are with you?'**
  String get howManyPeopleQuestion;

  /// No description provided for @guestAllowanceSingular.
  ///
  /// In en, this message translates to:
  /// **'You can bring up to {max} guest with your {plan} membership'**
  String guestAllowanceSingular(int max, String plan);

  /// No description provided for @guestAllowancePlural.
  ///
  /// In en, this message translates to:
  /// **'You can bring up to {max} guests with your {plan} membership'**
  String guestAllowancePlural(int max, String plan);

  /// No description provided for @openingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get openingEllipsis;

  /// No description provided for @openDoorButton.
  ///
  /// In en, this message translates to:
  /// **'Open Door'**
  String get openDoorButton;

  /// No description provided for @guestsCounterLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsCounterLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note: '**
  String get noteLabel;

  /// No description provided for @guestOrdersNote.
  ///
  /// In en, this message translates to:
  /// **'Your monthly allowance covers your orders only. Guest orders will receive member discounts but are paid separately.'**
  String get guestOrdersNote;

  /// No description provided for @skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousButton;

  /// No description provided for @getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStartedButton;

  /// No description provided for @onboardingWelcomeHeading.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rosewater Café'**
  String get onboardingWelcomeHeading;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Experience the finest hookah lounge with exclusive VIP memberships, premium services, and a luxurious atmosphere.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingQrHeading.
  ///
  /// In en, this message translates to:
  /// **'QR Code Door Access'**
  String get onboardingQrHeading;

  /// No description provided for @onboardingQrBody.
  ///
  /// In en, this message translates to:
  /// **'Unlock the café with your personal QR code. Bring guests and track your visits effortlessly.'**
  String get onboardingQrBody;

  /// No description provided for @onboardingAllowancesHeading.
  ///
  /// In en, this message translates to:
  /// **'Monthly Allowances'**
  String get onboardingAllowancesHeading;

  /// No description provided for @onboardingAllowancesBody.
  ///
  /// In en, this message translates to:
  /// **'Enjoy included hookah sessions and drinks every month. Track your usage and maximize your membership benefits.'**
  String get onboardingAllowancesBody;

  /// No description provided for @onboardingEventsHeading.
  ///
  /// In en, this message translates to:
  /// **'Exclusive Events'**
  String get onboardingEventsHeading;

  /// No description provided for @onboardingEventsBody.
  ///
  /// In en, this message translates to:
  /// **'Reserve the entire café for private events. Get priority booking and VIP discounts on special occasions.'**
  String get onboardingEventsBody;

  /// No description provided for @profileHeading.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileHeading;

  /// No description provided for @editProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileButton;

  /// Profile header badge -- plan is already upper-cased by the caller
  ///
  /// In en, this message translates to:
  /// **'{plan} Member'**
  String planBadgeSuffix(String plan);

  /// No description provided for @couldntLoadProfile.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile.'**
  String get couldntLoadProfile;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgainButton;

  /// No description provided for @membershipDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership Details'**
  String get membershipDetailsTitle;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @validUntilLabel.
  ///
  /// In en, this message translates to:
  /// **'Valid Until'**
  String get validUntilLabel;

  /// No description provided for @maxGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Max Guests'**
  String get maxGuestsLabel;

  /// No description provided for @upgradeMembershipButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Membership'**
  String get upgradeMembershipButton;

  /// No description provided for @upgradeMembershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a higher-tier plan to unlock more benefits'**
  String get upgradeMembershipSubtitle;

  /// No description provided for @upgradingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Upgrading…'**
  String get upgradingEllipsis;

  /// Upgrade Membership card button -- {plan} is the real plan name, not translated
  ///
  /// In en, this message translates to:
  /// **'Upgrade to {plan}'**
  String upgradeToPlanButton(String plan);

  /// Upgrade Membership screen's defensive empty state -- should be unreachable in practice since Profile hides the entry point when this is true, see hasUpgradeOption
  ///
  /// In en, this message translates to:
  /// **'No higher-tier plan is available right now.'**
  String get noUpgradeAvailable;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @paymentMethodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get paymentMethodsLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @privacySecurityLabel.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get privacySecurityLabel;

  /// No description provided for @helpSupportLabel.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportLabel;

  /// No description provided for @appSettingsLabel.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettingsLabel;

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutButton;

  /// No description provided for @versionFooter.
  ///
  /// In en, this message translates to:
  /// **'Version {version} • Rosewater Café'**
  String versionFooter(String version);

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @savingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get savingEllipsis;

  /// No description provided for @takePhotoOption.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhotoOption;

  /// No description provided for @chooseFromGalleryOption.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGalleryOption;

  /// No description provided for @photoTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please choose a PNG, JPG or WebP image.'**
  String get photoTypeError;

  /// No description provided for @photoTooLargeError.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large (max {mb}MB).'**
  String photoTooLargeError(int mb);

  /// No description provided for @saveChangesButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesButton;

  /// No description provided for @personalInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformationTitle;

  /// No description provided for @emailCantBeChangedNote.
  ///
  /// In en, this message translates to:
  /// **'Your email can\'t be changed in the app.'**
  String get emailCantBeChangedNote;

  /// No description provided for @membershipInformationTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership Information'**
  String get membershipInformationTitle;

  /// No description provided for @memberIdFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Member ID'**
  String get memberIdFieldLabel;

  /// No description provided for @subscriptionTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription Type'**
  String get subscriptionTypeLabel;

  /// No description provided for @contactSupportNote.
  ///
  /// In en, this message translates to:
  /// **'Contact support to change membership type'**
  String get contactSupportNote;

  /// No description provided for @changePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhotoTooltip;

  /// No description provided for @tapCameraIconHint.
  ///
  /// In en, this message translates to:
  /// **'Tap camera icon to change photo'**
  String get tapCameraIconHint;

  /// No description provided for @couldntSaveChangesError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your changes. Check your connection and try again.'**
  String get couldntSaveChangesError;

  /// No description provided for @addNewPaymentMethodButton.
  ///
  /// In en, this message translates to:
  /// **'Add New Payment Method'**
  String get addNewPaymentMethodButton;

  /// No description provided for @couldntLoadPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your payment methods.'**
  String get couldntLoadPaymentMethods;

  /// No description provided for @noPaymentMethodsYet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t added a payment method yet.'**
  String get noPaymentMethodsYet;

  /// No description provided for @removeCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this card?'**
  String get removeCardTitle;

  /// No description provided for @removeCardBody.
  ///
  /// In en, this message translates to:
  /// **'{brand} ending in {last4} will be removed from your account.'**
  String removeCardBody(String brand, String last4);

  /// No description provided for @removeButton.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeButton;

  /// No description provided for @setAsDefaultTooltip.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get setAsDefaultTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteTooltip;

  /// No description provided for @defaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultBadge;

  /// No description provided for @addPaymentMethodHeading.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get addPaymentMethodHeading;

  /// No description provided for @setAsDefaultPaymentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'Set as default payment method'**
  String get setAsDefaultPaymentCheckbox;

  /// No description provided for @cardSecurityNote.
  ///
  /// In en, this message translates to:
  /// **'For your security, only the card type, last 4 digits and expiry date are saved — never your full card number or CVV.'**
  String get cardSecurityNote;

  /// No description provided for @couldntSaveCardError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save your card. Check your connection and try again.'**
  String get couldntSaveCardError;

  /// No description provided for @saveCardButton.
  ///
  /// In en, this message translates to:
  /// **'Save Card'**
  String get saveCardButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @couldntSaveSettingError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save that setting. Please try again.'**
  String get couldntSaveSettingError;

  /// No description provided for @communicationPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication Preferences'**
  String get communicationPreferencesTitle;

  /// No description provided for @communicationPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to be notified'**
  String get communicationPreferencesSubtitle;

  /// No description provided for @notificationTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Types'**
  String get notificationTypesTitle;

  /// No description provided for @pushNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsLabel;

  /// No description provided for @pushNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on your device'**
  String get pushNotificationsDescription;

  /// No description provided for @emailNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotificationsLabel;

  /// No description provided for @emailNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get updates via email'**
  String get emailNotificationsDescription;

  /// No description provided for @smsNotificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get smsNotificationsLabel;

  /// No description provided for @smsNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive text messages for important updates'**
  String get smsNotificationsDescription;

  /// No description provided for @soundVibrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound & Vibration'**
  String get soundVibrationLabel;

  /// No description provided for @soundVibrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Play sound when notifications arrive'**
  String get soundVibrationDescription;

  /// No description provided for @eventRemindersLabel.
  ///
  /// In en, this message translates to:
  /// **'Event Reminders'**
  String get eventRemindersLabel;

  /// No description provided for @eventRemindersDescription.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about your upcoming reservations'**
  String get eventRemindersDescription;

  /// No description provided for @allowanceAlertsLabel.
  ///
  /// In en, this message translates to:
  /// **'Allowance Alerts'**
  String get allowanceAlertsLabel;

  /// No description provided for @allowanceAlertsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify when allowances are running low'**
  String get allowanceAlertsDescription;

  /// No description provided for @promotionsOffersLabel.
  ///
  /// In en, this message translates to:
  /// **'Promotions & Offers'**
  String get promotionsOffersLabel;

  /// No description provided for @promotionsOffersDescription.
  ///
  /// In en, this message translates to:
  /// **'Receive special deals and member benefits'**
  String get promotionsOffersDescription;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared.'**
  String get cacheClearedMessage;

  /// No description provided for @clearAllAppDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all app data?'**
  String get clearAllAppDataTitle;

  /// No description provided for @clearAllAppDataBody.
  ///
  /// In en, this message translates to:
  /// **'This removes every saved preference from this device and signs you out. Your account and its data aren\'t affected -- you can sign back in normally.'**
  String get clearAllAppDataBody;

  /// No description provided for @clearAndSignOutButton.
  ///
  /// In en, this message translates to:
  /// **'Clear & Sign Out'**
  String get clearAndSignOutButton;

  /// No description provided for @appearanceCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceCardTitle;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @darkModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get darkModeDescription;

  /// No description provided for @animationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Animations'**
  String get animationsLabel;

  /// No description provided for @animationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Enable smooth animations throughout the app'**
  String get animationsDescription;

  /// No description provided for @languageSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSectionLabel;

  /// No description provided for @interactionsCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get interactionsCardTitle;

  /// No description provided for @soundEffectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffectsLabel;

  /// No description provided for @soundEffectsDescription.
  ///
  /// In en, this message translates to:
  /// **'Play sounds for actions and notifications'**
  String get soundEffectsDescription;

  /// No description provided for @hapticFeedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedbackLabel;

  /// No description provided for @hapticFeedbackDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on button presses and interactions'**
  String get hapticFeedbackDescription;

  /// No description provided for @dataStorageCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorageCardTitle;

  /// No description provided for @cacheSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Cache Size'**
  String get cacheSizeLabel;

  /// No description provided for @clearCacheButton.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCacheButton;

  /// No description provided for @clearAllAppDataButton.
  ///
  /// In en, this message translates to:
  /// **'Clear All App Data'**
  String get clearAllAppDataButton;

  /// No description provided for @versionLine.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLine(String version);

  /// No description provided for @buildLine.
  ///
  /// In en, this message translates to:
  /// **'Build {build}'**
  String buildLine(String build);

  /// No description provided for @passwordSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordSectionTitle;

  /// No description provided for @emailSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailSectionTitle;

  /// No description provided for @privacySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacySectionTitle;

  /// No description provided for @securityOptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security Options'**
  String get securityOptionsTitle;

  /// No description provided for @biometricAuthLabel.
  ///
  /// In en, this message translates to:
  /// **'Biometric Authentication'**
  String get biometricAuthLabel;

  /// No description provided for @biometricAuthDescription.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint or face ID to sign in'**
  String get biometricAuthDescription;

  /// No description provided for @twoFactorAuthLabel.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthLabel;

  /// No description provided for @twoFactorAuthDescription.
  ///
  /// In en, this message translates to:
  /// **'Add an extra layer of security'**
  String get twoFactorAuthDescription;

  /// No description provided for @comingSoonNote.
  ///
  /// In en, this message translates to:
  /// **'(Coming Soon)'**
  String get comingSoonNote;

  /// No description provided for @autoLockLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-Lock'**
  String get autoLockLabel;

  /// No description provided for @autoLockDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatically lock app when inactive'**
  String get autoLockDescription;

  /// No description provided for @noBiometricsAvailableError.
  ///
  /// In en, this message translates to:
  /// **'No biometrics available on this device. Set up a fingerprint or face unlock first.'**
  String get noBiometricsAvailableError;

  /// No description provided for @strongPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure by using a strong password'**
  String get strongPasswordPrompt;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @enterCurrentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enterCurrentPasswordHint;

  /// No description provided for @enterNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enterNewPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @updatePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePasswordButton;

  /// No description provided for @enterCurrentPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get enterCurrentPasswordError;

  /// No description provided for @passwordMustDifferError.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from your current one.'**
  String get passwordMustDifferError;

  /// No description provided for @couldntUpdatePasswordError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your password. Check your connection and try again.'**
  String get couldntUpdatePasswordError;

  /// No description provided for @passwordUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Password updated.'**
  String get passwordUpdatedMessage;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountLabel;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This immediately and permanently deletes your account and everything in it -- your profile, membership, payment methods, and reservation history. This cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deletePermanentlyButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanentlyButton;

  /// No description provided for @deletingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Deleting…'**
  String get deletingEllipsis;

  /// No description provided for @couldntDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get couldntDeleteAccountError;

  /// No description provided for @changeEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmailButton;

  /// No description provided for @confirmationSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'Confirmation sent to {email} -- click the link there to finish. Your current email still works until then.'**
  String confirmationSentToEmail(String email);

  /// No description provided for @newEmailFormInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter your new email address and current password. We\'ll send a confirmation link to the new address -- your current email keeps working until you click it.'**
  String get newEmailFormInstructions;

  /// No description provided for @newEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'New Email Address'**
  String get newEmailAddressLabel;

  /// No description provided for @sendConfirmationButton.
  ///
  /// In en, this message translates to:
  /// **'Send Confirmation'**
  String get sendConfirmationButton;

  /// No description provided for @couldntUpdateEmailError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update your email. Check your connection and try again.'**
  String get couldntUpdateEmailError;

  /// No description provided for @viewPrivacyPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get viewPrivacyPolicyLabel;

  /// No description provided for @legalDraftDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Draft placeholder text -- not written or reviewed by a lawyer. This is not final legal coverage and will be replaced with company-approved copy before launch.'**
  String get legalDraftDisclaimer;

  /// No description provided for @showPasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPasswordTooltip;

  /// No description provided for @hidePasswordTooltip.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePasswordTooltip;

  /// No description provided for @liveChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChatTitle;

  /// No description provided for @liveChatDescription.
  ///
  /// In en, this message translates to:
  /// **'Chat with our team'**
  String get liveChatDescription;

  /// No description provided for @emailUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUsTitle;

  /// No description provided for @emailUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get help via email'**
  String get emailUsDescription;

  /// No description provided for @callUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUsTitle;

  /// No description provided for @callUsDescription.
  ///
  /// In en, this message translates to:
  /// **'Speak to support'**
  String get callUsDescription;

  /// No description provided for @faqCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get faqCardTitle;

  /// No description provided for @faqQuestion1.
  ///
  /// In en, this message translates to:
  /// **'How do I use my QR code to enter the café?'**
  String get faqQuestion1;

  /// No description provided for @faqAnswer1.
  ///
  /// In en, this message translates to:
  /// **'Simply open the QR Code section from your dashboard, show it to the scanner at the entrance, and specify how many guests are with you.'**
  String get faqAnswer1;

  /// No description provided for @faqQuestion2.
  ///
  /// In en, this message translates to:
  /// **'What happens when my monthly allowance runs out?'**
  String get faqQuestion2;

  /// No description provided for @faqAnswer2.
  ///
  /// In en, this message translates to:
  /// **'If you have Allowance Alerts turned on, we\'ll send you a low-allowance alert once you\'re down to 3 or fewer hookah sessions or drinks for the month, so you\'re not caught by surprise. Your allowance starts fresh with each new membership period — or right away if you upgrade to a higher plan from Profile for a bigger monthly allowance.'**
  String get faqAnswer2;

  /// No description provided for @faqQuestion3.
  ///
  /// In en, this message translates to:
  /// **'Can I bring guests to the café?'**
  String get faqQuestion3;

  /// No description provided for @faqAnswer3.
  ///
  /// In en, this message translates to:
  /// **'Yes — every plan includes a guest limit, shown as Max Guests in your Membership Details. When you open the door with your QR code, choose how many guests are with you, up to that limit. Your monthly allowance covers your own orders only; guest orders get member discounts but are paid separately.'**
  String get faqAnswer3;

  /// No description provided for @faqQuestion4.
  ///
  /// In en, this message translates to:
  /// **'What\'s the difference between full service and self-service hours?'**
  String get faqQuestion4;

  /// No description provided for @faqAnswer4.
  ///
  /// In en, this message translates to:
  /// **'Full Service Hours (9:00 AM – 11:00 PM) are staffed, with our team handling orders and hookah setup for you. Self-Service Hours (11:00 PM – 9:00 AM) let members access the space with their membership, but without staff on site, so it\'s a more limited, help-yourself experience.'**
  String get faqAnswer4;

  /// No description provided for @faqDraftAnswerNote.
  ///
  /// In en, this message translates to:
  /// **'Draft answer — pending confirmation from the company, not final copy.'**
  String get faqDraftAnswerNote;

  /// No description provided for @resourcesCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get resourcesCardTitle;

  /// No description provided for @userGuideLabel.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get userGuideLabel;

  /// No description provided for @membershipBenefitsLabel.
  ///
  /// In en, this message translates to:
  /// **'Membership Benefits'**
  String get membershipBenefitsLabel;

  /// No description provided for @communityGuidelinesLabel.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get communityGuidelinesLabel;

  /// No description provided for @appLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'App Locked'**
  String get appLockedTitle;

  /// No description provided for @unlockWithBiometricPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock with your fingerprint or face to continue.'**
  String get unlockWithBiometricPrompt;

  /// No description provided for @unlockWithPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to continue.'**
  String get unlockWithPasswordPrompt;

  /// No description provided for @checkingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checkingEllipsis;

  /// No description provided for @tryAgainBiometricButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainBiometricButton;

  /// No description provided for @usePasswordInsteadButton.
  ///
  /// In en, this message translates to:
  /// **'Use Password Instead'**
  String get usePasswordInsteadButton;

  /// No description provided for @passwordFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldLabel;

  /// No description provided for @verifyingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Verifying…'**
  String get verifyingEllipsis;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @useBiometricInsteadButton.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric Instead'**
  String get useBiometricInsteadButton;

  /// No description provided for @enterYourPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPasswordError;

  /// No description provided for @couldntVerifyPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify your password. Check your connection and try again.'**
  String get couldntVerifyPasswordError;

  /// No description provided for @unlockReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'Unlock Rosewater Café'**
  String get unlockReasonPrompt;

  /// No description provided for @couldntSignOutError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign out. Please try again.'**
  String get couldntSignOutError;

  /// No description provided for @notifSubscriptionActivatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership Activated'**
  String get notifSubscriptionActivatedTitle;

  /// Notification body after a membership payment. {plan} is the real plan name (not translated, same as everywhere else); {date} is valid_until, already formatted for the locale
  ///
  /// In en, this message translates to:
  /// **'Your {plan} membership is now active until {date}.'**
  String notifSubscriptionActivatedBody(String plan, String date);

  /// No description provided for @notifEventReservationConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Reservation Confirmed'**
  String get notifEventReservationConfirmedTitle;

  /// Notification body after an event reservation. {eventType} is the localized event type label; {date}/{time} are already formatted for the locale
  ///
  /// In en, this message translates to:
  /// **'Your {eventType} reservation on {date} at {time} for {guestCount, plural, =1{1 guest} other{{guestCount} guests}} is confirmed.'**
  String notifEventReservationConfirmedBody(String eventType, String date, String time, int guestCount);

  /// Notifications screen subtitle, e.g. "2 unread notifications"
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications} =1{1 unread notification} other{{count} unread notifications}}'**
  String unreadNotificationsCount(int count);

  /// Screen-reader label for the Home bell's red badge
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread notification} other{{count} unread notifications}}'**
  String unreadBadgeSemantics(int count);

  /// No description provided for @markAsReadButton.
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsReadButton;

  /// No description provided for @viewDetailsButton.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetailsButton;

  /// No description provided for @noNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsTitle;

  /// No description provided for @noNotificationsBody.
  ///
  /// In en, this message translates to:
  /// **'Payment and event reservation updates will show up here.'**
  String get noNotificationsBody;

  /// No description provided for @couldntLoadNotificationsError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your notifications.'**
  String get couldntLoadNotificationsError;

  /// No description provided for @couldntUpdateNotificationError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update that notification. Please try again.'**
  String get couldntUpdateNotificationError;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// e.g. "5m ago"
  ///
  /// In en, this message translates to:
  /// **'{n}m ago'**
  String timeMinutesAgo(int n);

  /// e.g. "2h ago"
  ///
  /// In en, this message translates to:
  /// **'{n}h ago'**
  String timeHoursAgo(int n);

  /// e.g. "1d ago" (under a week; older shows a date)
  ///
  /// In en, this message translates to:
  /// **'{n}d ago'**
  String timeDaysAgo(int n);

  /// No description provided for @notifEventReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Reminder'**
  String get notifEventReminderTitle;

  /// Sent about 24 hours before a reservation. {eventType} is translated; {date} and {time} are already formatted
  ///
  /// In en, this message translates to:
  /// **'Your {eventType} reservation is coming up on {date} at {time} for {guestCount, plural, =1{1 guest} other{{guestCount} guests}}.'**
  String notifEventReminderBody(String eventType, String date, String time, int guestCount);

  /// No description provided for @notifLowAllowanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Low Allowance Alert'**
  String get notifLowAllowanceTitle;

  /// Low allowance alert, hookah
  ///
  /// In en, this message translates to:
  /// **'{remaining, plural, =0{You have used all your hookah sessions this month.} =1{You have only 1 hookah session remaining this month.} other{You have only {remaining} hookah sessions remaining this month.}}'**
  String notifLowHookahBody(int remaining);

  /// Low Allowance Alert card, drinks
  ///
  /// In en, this message translates to:
  /// **'{remaining, plural, =0{You have used all your drinks this month.} =1{You have only 1 drink remaining this month.} other{You have only {remaining} drinks remaining this month.}}'**
  String notifLowDrinksBody(int remaining);

  /// No description provided for @reservationDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reservation Details'**
  String get reservationDetailsTitle;

  /// No description provided for @reservationStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get reservationStatusConfirmed;

  /// No description provided for @reservationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reservationStatusPending;

  /// No description provided for @reservationStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reservationStatusCancelled;

  /// No description provided for @totalColonLabel.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get totalColonLabel;

  /// No description provided for @reservationNotFound.
  ///
  /// In en, this message translates to:
  /// **'This reservation is no longer available.'**
  String get reservationNotFound;

  /// No description provided for @couldntLoadReservationError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load this reservation.'**
  String get couldntLoadReservationError;

  /// No description provided for @payWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay with'**
  String get payWithLabel;

  /// No description provided for @useNewCardOption.
  ///
  /// In en, this message translates to:
  /// **'Use a new card'**
  String get useNewCardOption;

  /// No description provided for @saveCardForNextTime.
  ///
  /// In en, this message translates to:
  /// **'Save this card for next time'**
  String get saveCardForNextTime;

  /// Saved card's expiry on the payment screen, e.g. "Exp 12/27"
  ///
  /// In en, this message translates to:
  /// **'Exp {date}'**
  String cardExpiryShort(String date);

  /// No description provided for @cardExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get cardExpiredLabel;

  /// No description provided for @notifSubscriptionUpgradedTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership Upgraded'**
  String get notifSubscriptionUpgradedTitle;

  /// Notification after upgrade_subscription. Plan names are real plan names (not translated, as everywhere); {date} is valid_until formatted for the locale
  ///
  /// In en, this message translates to:
  /// **'You\'ve upgraded from {oldPlan} to {newPlan}. Your new membership is active until {date}.'**
  String notifSubscriptionUpgradedBody(String oldPlan, String newPlan, String date);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
