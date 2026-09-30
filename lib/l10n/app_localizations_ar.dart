// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navQrCode => 'رمز QR';

  @override
  String get navEvents => 'الفعاليات';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get welcomeBack => 'مرحبًا بعودتك';

  @override
  String get signInSubtitle => 'سجّل الدخول إلى حسابك';

  @override
  String get emailAddressLabel => 'البريد الإلكتروني';

  @override
  String get emailAddressHint => 'your@email.com';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordHint => '••••••••';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get rememberMe => 'تذكرني';

  @override
  String get forgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get signInButton => 'تسجيل الدخول';

  @override
  String get signingIn => 'جارٍ تسجيل الدخول…';

  @override
  String get noAccountPrompt => 'ليس لديك حساب؟';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get signInGenericError => 'حدث خطأ ما. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get welcomeGeneric => 'أهلاً بك!';

  @override
  String welcomeNamed(String name) {
    return 'أهلاً بك يا $name!';
  }

  @override
  String memberIdLabel(String id) {
    return 'رقم العضوية: $id';
  }

  @override
  String get notifications => 'الإشعارات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get membershipStatus => 'حالة العضوية';

  @override
  String memberSuffix(String plan) {
    return 'عضو $plan';
  }

  @override
  String get activeStatus => 'نشط';

  @override
  String validUntil(String date) {
    return 'صالح حتى: $date';
  }

  @override
  String get accessCafe => 'الدخول إلى المقهى';

  @override
  String get reserveEvent => 'حجز فعالية';

  @override
  String get hookahSessions => 'جلسات الشيشة';

  @override
  String get drinks => 'المشروبات';

  @override
  String get unlimited => 'غير محدود';

  @override
  String usedThisMonth(int used) {
    return 'استُخدم $used هذا الشهر';
  }

  @override
  String get serviceHours => 'ساعات الخدمة';

  @override
  String get fullServiceHours => 'ساعات الخدمة الكاملة';

  @override
  String get fullServiceHoursValue => '٩:٠٠ ص - ١١:٠٠ م';

  @override
  String get selfServiceHours => 'ساعات الخدمة الذاتية';

  @override
  String get selfServiceHoursValue => '١١:٠٠ م - ٩:٠٠ ص';

  @override
  String get currentStatusLabel => 'الحالة الحالية: ';

  @override
  String get fullServiceAvailable => 'الخدمة الكاملة متاحة';

  @override
  String get selfServiceHoursStatus => 'ساعات الخدمة الذاتية';

  @override
  String get membershipBenefits => 'مزايا العضوية';

  @override
  String comingSoonSuffix(String label) {
    return '$label — سيتوفر في مهمة لاحقة';
  }

  @override
  String get genericConnectionError =>
      'حدث خطأ ما. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordHelperText =>
      '٨ أحرف أو أكثر، تتضمن حرفًا كبيرًا وصغيرًا ورقمًا';

  @override
  String get authLandingTagline => 'عضوية VIP وصالة استرخاء';

  @override
  String get featurePremiumLounge => 'صالة مميزة';

  @override
  String get featureExclusiveServices => 'خدمات حصرية';

  @override
  String get featureBringGuests => 'إحضار ضيوف';

  @override
  String get authLandingFooter => 'تجربة مقهى شيشة فاخرة';

  @override
  String get createAccountHeading => 'إنشاء حساب';

  @override
  String get joinToday => 'انضم إلى Rosewater Café اليوم';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get fullNameHint => 'أحمد محمد';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get phoneNumberHint => '+1 (555) 000-0000';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get agreeToTermsPrefix => 'أوافق على ';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get agreeToTermsAnd => ' و ';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get mustAgreeToContinue => 'يجب الموافقة للمتابعة';

  @override
  String get creatingAccount => 'جارٍ إنشاء الحساب…';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get forgotPasswordSubtitle =>
      'لا داعي للقلق! أدخل بريدك الإلكتروني وسنرسل لك رابطًا لإعادة تعيين كلمة المرور.';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get sendingEllipsis => 'جارٍ الإرسال…';

  @override
  String get checkYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String resetLinkSentBody(String email) {
    return 'إذا كان هناك حساب مرتبط بـ $email، فقد أرسلنا رابطًا لإعادة تعيين كلمة المرور. تحقق من بريدك الوارد (ومجلد الرسائل غير المرغوب فيها).';
  }

  @override
  String get backToSignIn => 'العودة لتسجيل الدخول';

  @override
  String get setNewPasswordHeading => 'تعيين كلمة مرور جديدة';

  @override
  String get chooseNewPasswordSubtitle => 'اختر كلمة مرور جديدة لحسابك.';

  @override
  String get newPasswordLabel => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordLabel => 'تأكيد كلمة المرور الجديدة';

  @override
  String get updatingEllipsis => 'جارٍ التحديث…';

  @override
  String get updatePassword => 'تحديث كلمة المرور';

  @override
  String get passwordUpdatedHeading => 'تم تحديث كلمة المرور';

  @override
  String get passwordUpdatedBody =>
      'تم تغيير كلمة المرور الخاصة بك. يرجى تسجيل الدخول بكلمة المرور الجديدة.';

  @override
  String get continueToSignIn => 'المتابعة لتسجيل الدخول';

  @override
  String get couldNotUpdatePasswordError =>
      'تعذر تحديث كلمة المرور. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get confirmYourEmailHeading => 'تأكيد بريدك الإلكتروني';

  @override
  String confirmEmailBody(String email) {
    return 'حسابك على وشك الجاهزية. أرسلنا رابط تأكيد إلى $email — اضغط عليه لتفعيل حسابك، ثم سجّل الدخول.';
  }

  @override
  String get chooseYourMembership => 'اختر عضويتك';

  @override
  String get selectPlanSubtitle => 'اختر الخطة التي تناسب أسلوب حياتك';

  @override
  String get couldNotLoadPlansError =>
      'تعذر تحميل خطط العضوية. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get allPlansFooter =>
      'تشمل جميع الخطط خصومات الأعضاء. طلبات الضيوف غير مشمولة في المخصصات.';

  @override
  String get mostPopularBadge => 'الأكثر شيوعًا';

  @override
  String get perMonthSuffix => '/شهريًا';

  @override
  String get selectingEllipsis => 'جارٍ الاختيار…';

  @override
  String selectPlanButton(String plan) {
    return 'اختيار $plan';
  }

  @override
  String get unlimitedHookahFeature => 'شيشة غير محدودة';

  @override
  String hookahSessionsPerMonth(int count) {
    return '$count جلسة شيشة شهريًا';
  }

  @override
  String get unlimitedDrinksFeature => 'مشروبات غير محدودة';

  @override
  String drinksIncludedCount(int count) {
    return '$count مشروب ضمن الاشتراك';
  }

  @override
  String get bringGuestBulletSingular => 'إحضار ضيف واحد';

  @override
  String bringGuestBulletPlural(int max) {
    return 'إحضار حتى $max ضيوف';
  }

  @override
  String get planFeatureStandardSeating => 'مقاعد عادية';

  @override
  String get planFeatureMemberDiscounts => 'خصومات للأعضاء';

  @override
  String get planFeaturePrioritySeating => 'أولوية في الجلوس';

  @override
  String get planFeatureWeekendAccess => 'دخول في عطلة نهاية الأسبوع';

  @override
  String get planFeaturePrivateBooth => 'مقصورة خاصة';

  @override
  String get planFeature247Access => 'دخول على مدار الساعة';

  @override
  String get planFeatureEventPriority => 'أولوية حضور الفعاليات';

  @override
  String get planFeatureExclusiveMenu => 'قائمة حصرية';

  @override
  String get couldNotLoadDetailsError =>
      'تعذر تحميل بياناتك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'الاختيار من المعرض';

  @override
  String get chooseFileHint => 'اختيار ملف (PNG، JPG، PDF)';

  @override
  String get cameraGalleryAccessError =>
      'تعذر الوصول إلى الكاميرا/المعرض. تحقق من أذونات التطبيق وحاول مرة أخرى.';

  @override
  String get filePickerError => 'تعذر فتح منتقي الملفات. حاول مرة أخرى.';

  @override
  String get invalidIdFileType => 'يرجى اختيار ملف PNG أو JPG أو PDF.';

  @override
  String idFileTooLarge(int mb) {
    return 'هذا الملف كبير جدًا — الحد الأقصى $mb ميغابايت.';
  }

  @override
  String get uploadFailedError => 'فشل الرفع. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get cancellingEllipsis => 'جارٍ الإلغاء…';

  @override
  String get backToPlans => 'العودة إلى الخطط';

  @override
  String get verifyYourMembership => 'تحقق من عضويتك';

  @override
  String get subscriptionPlanLabel => 'خطة الاشتراك';

  @override
  String get uploadIdDocumentLabel => 'رفع وثيقة الهوية';

  @override
  String get requiredForVerification => 'مطلوب للتحقق من العضوية والأمان';

  @override
  String get uploadingEllipsis => 'جارٍ الرفع…';

  @override
  String get continueToPayment => 'المتابعة إلى الدفع';

  @override
  String get clickToUploadId => 'اضغط لرفع الهوية';

  @override
  String get idFileTypesHint => 'PNG، JPG، PDF (بحد أقصى 10 ميغابايت)';

  @override
  String get couldNotGoBackToPlansError =>
      'تعذرت العودة إلى الخطط. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get completePayment => 'إتمام الدفع';

  @override
  String planSuffix(String plan) {
    return 'خطة $plan';
  }

  @override
  String get monthlySubscription => 'الاشتراك الشهري';

  @override
  String get totalLabel => 'الإجمالي';

  @override
  String get cardNumberLabel => 'رقم البطاقة';

  @override
  String get expiryDateLabel => 'تاريخ الانتهاء';

  @override
  String get cvvLabel => 'رمز التحقق (CVV)';

  @override
  String get paymentFailedError => 'فشل الدفع. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get backButton => 'رجوع';

  @override
  String get payingEllipsis => 'جارٍ الدفع…';

  @override
  String payAmountButton(String amount) {
    return 'ادفع $amount';
  }

  @override
  String get youAreMember => 'أنت الآن عضو!';

  @override
  String welcomeMembershipActive(String plan) {
    return 'مرحبًا بك في Rosewater Café. عضويتك في خطة $plan أصبحت نشطة الآن.';
  }

  @override
  String get continueButton => 'متابعة';

  @override
  String get eventTypeBirthday => 'عيد ميلاد';

  @override
  String get eventTypeCorporate => 'فعالية شركات';

  @override
  String get eventTypePrivateParty => 'حفلة خاصة';

  @override
  String get eventTypeOther => 'أخرى';

  @override
  String get durationRequired => 'المدة مطلوبة';

  @override
  String get enterValidNumberDecimal =>
      'أدخل رقمًا صحيحًا (حتى منزلتين عشريتين)';

  @override
  String get durationMustBeGreaterThanZero => 'يجب أن تكون المدة أكبر من 0';

  @override
  String get guestCountRequired => 'عدد الضيوف مطلوب';

  @override
  String get enterValidNumber => 'أدخل رقمًا صحيحًا';

  @override
  String get guestCountRange => 'الحد الأدنى 5 ضيوف، والحد الأقصى 100 ضيف';

  @override
  String get genericTryAgainError => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get backToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String get reserveAnEvent => 'حجز فعالية';

  @override
  String get reserveEventSubtitle =>
      'احجز المقهى لفعاليتك الخاصة. مثالي للحفلات والاجتماعات والمناسبات الخاصة.';

  @override
  String get eventTypeLabel => 'نوع الفعالية';

  @override
  String get pleaseSelectEventType => 'يرجى اختيار نوع الفعالية';

  @override
  String get selectEventTypeHint => 'اختر نوع الفعالية';

  @override
  String get eventDateLabel => 'تاريخ الفعالية';

  @override
  String get selectDateHint => 'اختر تاريخًا';

  @override
  String get eventDateRequired => 'تاريخ الفعالية مطلوب';

  @override
  String get datePassedError =>
      'لقد مضى هذا التاريخ بالفعل — يرجى اختيار تاريخ آخر.';

  @override
  String get startTimeLabel => 'وقت البدء';

  @override
  String get selectTimeHint => 'اختر وقتًا';

  @override
  String get startTimeRequired => 'وقت البدء مطلوب';

  @override
  String get durationHoursLabel => 'المدة (بالساعات)';

  @override
  String get durationExampleHint => 'مثال: 2';

  @override
  String get numberOfGuestsLabel => 'عدد الضيوف';

  @override
  String get confirmingEllipsis => 'جارٍ التأكيد…';

  @override
  String get confirmReservation => 'تأكيد الحجز';

  @override
  String get eventPackageIncludes => 'تشمل باقة الفعالية:';

  @override
  String get packageBulletCafe => 'استخدام حصري للمقهى';

  @override
  String get packageBulletHookah => 'شيشة مجانية لجميع الضيوف';

  @override
  String get packageBulletMenu => 'قائمة طعام خاصة بالفعاليات متاحة';

  @override
  String get packageBulletStaff => 'خدمة موظفين مخصصة';

  @override
  String get packageBulletSound => 'نظام صوتي والتحكم بالموسيقى';

  @override
  String get baseRatePerHour => 'السعر الأساسي (لكل ساعة)';

  @override
  String get durationRowLabel => 'المدة';

  @override
  String durationHoursValue(String hours) {
    return '$hours ساعات';
  }

  @override
  String get estimatedTotal => 'الإجمالي التقديري';

  @override
  String get eventReservationConfirmedBanner => 'تم تأكيد حجز الفعالية!';

  @override
  String get reservationConfirmedHeading => 'تم تأكيد الحجز!';

  @override
  String get reservationConfirmedSubtitle => 'تم حجز فعاليتك بنجاح';

  @override
  String get dateColonLabel => 'التاريخ:';

  @override
  String get timeColonLabel => 'الوقت:';

  @override
  String get durationColonLabel => 'المدة:';

  @override
  String get guestsColonLabel => 'الضيوف:';

  @override
  String get hourSingular => 'ساعة';

  @override
  String get hourPlural => 'ساعات';

  @override
  String get peopleLabel => 'أشخاص';

  @override
  String get doorAccessHeading => 'الدخول عبر الباب';

  @override
  String get doorUnlockedMessage => 'تم فتح الباب! استمتع بزيارتك.';

  @override
  String get unableToLoadMemberId => 'تعذر تحميل رقم عضويتك';

  @override
  String get scanQrInstruction =>
      'امسح رمز الاستجابة السريعة هذا عند المدخل لفتح الباب';

  @override
  String get howManyPeopleQuestion => 'كم عدد الأشخاص المرافقين لك؟';

  @override
  String guestAllowanceSingular(int max, String plan) {
    return 'يمكنك إحضار ضيف واحد كحد أقصى مع عضوية $plan';
  }

  @override
  String guestAllowancePlural(int max, String plan) {
    return 'يمكنك إحضار حتى $max ضيوف مع عضوية $plan';
  }

  @override
  String get openingEllipsis => 'جارٍ الفتح…';

  @override
  String get openDoorButton => 'فتح الباب';

  @override
  String get guestsCounterLabel => 'الضيوف';

  @override
  String get noteLabel => 'ملاحظة: ';

  @override
  String get guestOrdersNote =>
      'يغطي رصيدك الشهري طلباتك فقط. ستحصل طلبات الضيوف على خصومات الأعضاء لكن تُدفع بشكل منفصل.';

  @override
  String get skipButton => 'تخطي';

  @override
  String get nextButton => 'التالي';

  @override
  String get previousButton => 'السابق';

  @override
  String get getStartedButton => 'ابدأ الآن';

  @override
  String get onboardingWelcomeHeading => 'مرحبًا بك في Rosewater Café';

  @override
  String get onboardingWelcomeBody =>
      'استمتع بأرقى صالة شيشة مع عضويات VIP حصرية، وخدمات مميزة، وأجواء فاخرة.';

  @override
  String get onboardingQrHeading => 'الدخول عبر رمز الاستجابة السريعة';

  @override
  String get onboardingQrBody =>
      'افتح باب المقهى برمز الاستجابة السريعة الخاص بك. أحضر ضيوفك وتابع زياراتك بسهولة.';

  @override
  String get onboardingAllowancesHeading => 'الرصيد الشهري';

  @override
  String get onboardingAllowancesBody =>
      'استمتع بجلسات شيشة ومشروبات مشمولة كل شهر. تابع استخدامك واستفد إلى أقصى حد من مزايا عضويتك.';

  @override
  String get onboardingEventsHeading => 'فعاليات حصرية';

  @override
  String get onboardingEventsBody =>
      'احجز المقهى بالكامل لفعالياتك الخاصة. احصل على أولوية الحجز وخصومات VIP في المناسبات الخاصة.';

  @override
  String get profileHeading => 'الملف الشخصي';

  @override
  String get editProfileButton => 'تعديل الملف الشخصي';

  @override
  String planBadgeSuffix(String plan) {
    return 'عضو $plan';
  }

  @override
  String get couldntLoadProfile => 'تعذر تحميل ملفك الشخصي.';

  @override
  String get tryAgainButton => 'حاول مرة أخرى';

  @override
  String get membershipDetailsTitle => 'تفاصيل العضوية';

  @override
  String get planLabel => 'الخطة';

  @override
  String get validUntilLabel => 'صالحة حتى';

  @override
  String get maxGuestsLabel => 'الحد الأقصى للضيوف';

  @override
  String get upgradeMembershipButton => 'ترقية العضوية';

  @override
  String get upgradeMembershipSubtitle =>
      'اختر خطة أعلى فئة لفتح المزيد من المزايا';

  @override
  String get upgradingEllipsis => 'جارٍ الترقية…';

  @override
  String upgradeToPlanButton(String plan) {
    return 'الترقية إلى $plan';
  }

  @override
  String get noUpgradeAvailable => 'لا توجد خطة أعلى فئة متاحة حاليًا.';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get paymentMethodsLabel => 'طرق الدفع';

  @override
  String get notificationsLabel => 'الإشعارات';

  @override
  String get privacySecurityLabel => 'الخصوصية والأمان';

  @override
  String get helpSupportLabel => 'المساعدة والدعم';

  @override
  String get appSettingsLabel => 'إعدادات التطبيق';

  @override
  String get signOutButton => 'تسجيل الخروج';

  @override
  String versionFooter(String version) {
    return 'الإصدار $version • Rosewater Café';
  }

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get savingEllipsis => 'جارٍ الحفظ…';

  @override
  String get takePhotoOption => 'التقاط صورة';

  @override
  String get chooseFromGalleryOption => 'اختيار من المعرض';

  @override
  String get photoTypeError => 'يرجى اختيار صورة بصيغة PNG أو JPG أو WebP.';

  @override
  String photoTooLargeError(int mb) {
    return 'هذه الصورة كبيرة جدًا (الحد الأقصى $mb ميجابايت).';
  }

  @override
  String get saveChangesButton => 'حفظ التغييرات';

  @override
  String get personalInformationTitle => 'المعلومات الشخصية';

  @override
  String get emailCantBeChangedNote =>
      'لا يمكن تغيير بريدك الإلكتروني داخل التطبيق.';

  @override
  String get membershipInformationTitle => 'معلومات العضوية';

  @override
  String get memberIdFieldLabel => 'رقم العضوية';

  @override
  String get subscriptionTypeLabel => 'نوع الاشتراك';

  @override
  String get contactSupportNote => 'تواصل مع الدعم لتغيير نوع العضوية';

  @override
  String get changePhotoTooltip => 'تغيير الصورة';

  @override
  String get tapCameraIconHint => 'اضغط على أيقونة الكاميرا لتغيير الصورة';

  @override
  String get couldntSaveChangesError =>
      'تعذر حفظ تغييراتك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get addNewPaymentMethodButton => 'إضافة طريقة دفع جديدة';

  @override
  String get couldntLoadPaymentMethods => 'تعذر تحميل طرق الدفع الخاصة بك.';

  @override
  String get noPaymentMethodsYet => 'لم تقم بإضافة طريقة دفع بعد.';

  @override
  String get removeCardTitle => 'إزالة هذه البطاقة؟';

  @override
  String removeCardBody(String brand, String last4) {
    return 'سيتم إزالة بطاقة $brand المنتهية بـ $last4 من حسابك.';
  }

  @override
  String get removeButton => 'إزالة';

  @override
  String get setAsDefaultTooltip => 'تعيين كافتراضي';

  @override
  String get deleteTooltip => 'حذف';

  @override
  String get defaultBadge => 'افتراضي';

  @override
  String get addPaymentMethodHeading => 'إضافة طريقة دفع';

  @override
  String get setAsDefaultPaymentCheckbox => 'تعيين كطريقة الدفع الافتراضية';

  @override
  String get cardSecurityNote =>
      'لأمانك، يتم حفظ نوع البطاقة وآخر 4 أرقام وتاريخ الانتهاء فقط — لا يُحفظ رقم بطاقتك الكامل أو رمز التحقق (CVV) أبدًا.';

  @override
  String get couldntSaveCardError =>
      'تعذر حفظ بطاقتك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get saveCardButton => 'حفظ البطاقة';

  @override
  String get doneButton => 'تم';

  @override
  String get couldntSaveSettingError =>
      'تعذر حفظ هذا الإعداد. يرجى المحاولة مرة أخرى.';

  @override
  String get communicationPreferencesTitle => 'تفضيلات التواصل';

  @override
  String get communicationPreferencesSubtitle => 'اختر كيف تريد أن يتم إشعارك';

  @override
  String get notificationTypesTitle => 'أنواع الإشعارات';

  @override
  String get pushNotificationsLabel => 'الإشعارات الفورية';

  @override
  String get pushNotificationsDescription => 'استلام الإشعارات على جهازك';

  @override
  String get emailNotificationsLabel => 'إشعارات البريد الإلكتروني';

  @override
  String get emailNotificationsDescription =>
      'احصل على التحديثات عبر البريد الإلكتروني';

  @override
  String get smsNotificationsLabel => 'الرسائل النصية القصيرة';

  @override
  String get smsNotificationsDescription =>
      'استلام رسائل نصية للتحديثات المهمة';

  @override
  String get soundVibrationLabel => 'الصوت والاهتزاز';

  @override
  String get soundVibrationDescription => 'تشغيل صوت عند وصول الإشعارات';

  @override
  String get eventRemindersLabel => 'تذكيرات الفعاليات';

  @override
  String get eventRemindersDescription => 'احصل على تذكير بحجوزاتك القادمة';

  @override
  String get allowanceAlertsLabel => 'تنبيهات الرصيد';

  @override
  String get allowanceAlertsDescription => 'التنبيه عند اقتراب نفاد رصيدك';

  @override
  String get promotionsOffersLabel => 'العروض والترويجات';

  @override
  String get promotionsOffersDescription => 'احصل على عروض خاصة ومزايا الأعضاء';

  @override
  String get cacheClearedMessage => 'تم مسح ذاكرة التخزين المؤقت.';

  @override
  String get clearAllAppDataTitle => 'مسح جميع بيانات التطبيق؟';

  @override
  String get clearAllAppDataBody =>
      'سيؤدي هذا إلى إزالة كل تفضيل محفوظ على هذا الجهاز وتسجيل خروجك. حسابك وبياناته لن يتأثرا — يمكنك تسجيل الدخول مرة أخرى بشكل طبيعي.';

  @override
  String get clearAndSignOutButton => 'مسح وتسجيل الخروج';

  @override
  String get appearanceCardTitle => 'المظهر';

  @override
  String get darkModeLabel => 'الوضع الداكن';

  @override
  String get darkModeDescription => 'التبديل إلى المظهر الداكن';

  @override
  String get animationsLabel => 'الحركات';

  @override
  String get animationsDescription =>
      'تفعيل الحركات السلسة في جميع أنحاء التطبيق';

  @override
  String get languageSectionLabel => 'اللغة';

  @override
  String get interactionsCardTitle => 'التفاعلات';

  @override
  String get soundEffectsLabel => 'المؤثرات الصوتية';

  @override
  String get soundEffectsDescription =>
      'تشغيل الأصوات عند الإجراءات والإشعارات';

  @override
  String get hapticFeedbackLabel => 'الاستجابة اللمسية';

  @override
  String get hapticFeedbackDescription =>
      'الاهتزاز عند الضغط على الأزرار والتفاعلات';

  @override
  String get dataStorageCardTitle => 'البيانات والتخزين';

  @override
  String get cacheSizeLabel => 'حجم ذاكرة التخزين المؤقت';

  @override
  String get clearCacheButton => 'مسح ذاكرة التخزين المؤقت';

  @override
  String get clearAllAppDataButton => 'مسح جميع بيانات التطبيق';

  @override
  String versionLine(String version) {
    return 'الإصدار $version';
  }

  @override
  String buildLine(String build) {
    return 'الإصدار البرمجي $build';
  }

  @override
  String get passwordSectionTitle => 'كلمة المرور';

  @override
  String get emailSectionTitle => 'البريد الإلكتروني';

  @override
  String get privacySectionTitle => 'الخصوصية';

  @override
  String get securityOptionsTitle => 'خيارات الأمان';

  @override
  String get biometricAuthLabel => 'المصادقة البيومترية';

  @override
  String get biometricAuthDescription =>
      'استخدام بصمة الإصبع أو التعرف على الوجه لتسجيل الدخول';

  @override
  String get twoFactorAuthLabel => 'المصادقة الثنائية';

  @override
  String get twoFactorAuthDescription => 'إضافة طبقة إضافية من الأمان';

  @override
  String get comingSoonNote => '(قريبًا)';

  @override
  String get autoLockLabel => 'القفل التلقائي';

  @override
  String get autoLockDescription => 'قفل التطبيق تلقائيًا عند عدم النشاط';

  @override
  String get noBiometricsAvailableError =>
      'لا تتوفر ميزة القياسات الحيوية على هذا الجهاز. يرجى إعداد بصمة الإصبع أو ميزة التعرف على الوجه أولاً.';

  @override
  String get strongPasswordPrompt =>
      'حافظ على أمان حسابك باستخدام كلمة مرور قوية';

  @override
  String get changePasswordButton => 'تغيير كلمة المرور';

  @override
  String get currentPasswordLabel => 'كلمة المرور الحالية';

  @override
  String get enterCurrentPasswordHint => 'أدخل كلمة المرور الحالية';

  @override
  String get enterNewPasswordHint => 'أدخل كلمة المرور الجديدة';

  @override
  String get confirmNewPasswordHint => 'أكّد كلمة المرور الجديدة';

  @override
  String get updatePasswordButton => 'تحديث كلمة المرور';

  @override
  String get enterCurrentPasswordError => 'أدخل كلمة المرور الحالية';

  @override
  String get passwordMustDifferError =>
      'اختر كلمة مرور مختلفة عن كلمة مرورك الحالية.';

  @override
  String get couldntUpdatePasswordError =>
      'تعذر تحديث كلمة مرورك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get passwordUpdatedMessage => 'تم تحديث كلمة المرور.';

  @override
  String get deleteAccountLabel => 'حذف الحساب';

  @override
  String get deleteAccountWarning =>
      'سيؤدي هذا إلى حذف حسابك وكل ما فيه فورًا وبشكل دائم — ملفك الشخصي وعضويتك وطرق الدفع وسجل الحجوزات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deletePermanentlyButton => 'حذف نهائيًا';

  @override
  String get deletingEllipsis => 'جارٍ الحذف…';

  @override
  String get couldntDeleteAccountError =>
      'تعذر حذف حسابك. يرجى المحاولة مرة أخرى.';

  @override
  String get changeEmailButton => 'تغيير البريد الإلكتروني';

  @override
  String confirmationSentToEmail(String email) {
    return 'تم إرسال رابط التأكيد إلى $email — اضغط على الرابط هناك لإتمام العملية. سيستمر عمل بريدك الإلكتروني الحالي حتى ذلك الحين.';
  }

  @override
  String get newEmailFormInstructions =>
      'أدخل عنوان بريدك الإلكتروني الجديد وكلمة مرورك الحالية. سنرسل رابط تأكيد إلى العنوان الجديد — سيستمر عمل بريدك الحالي حتى تضغط عليه.';

  @override
  String get newEmailAddressLabel => 'عنوان البريد الإلكتروني الجديد';

  @override
  String get sendConfirmationButton => 'إرسال التأكيد';

  @override
  String get couldntUpdateEmailError =>
      'تعذر تحديث بريدك الإلكتروني. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get viewPrivacyPolicyLabel => 'عرض سياسة الخصوصية';

  @override
  String get legalDraftDisclaimer =>
      'نص مسودة مؤقت -- لم تتم كتابته أو مراجعته من قبل محامٍ. هذا ليس نصاً قانونياً نهائياً وسيتم استبداله بنص معتمد من الشركة قبل الإطلاق.';

  @override
  String get showPasswordTooltip => 'إظهار كلمة المرور';

  @override
  String get hidePasswordTooltip => 'إخفاء كلمة المرور';

  @override
  String get liveChatTitle => 'الدردشة المباشرة';

  @override
  String get liveChatDescription => 'تحدث مع فريقنا';

  @override
  String get emailUsTitle => 'راسلنا';

  @override
  String get emailUsDescription => 'احصل على المساعدة عبر البريد الإلكتروني';

  @override
  String get callUsTitle => 'اتصل بنا';

  @override
  String get callUsDescription => 'تحدث مع الدعم';

  @override
  String get faqCardTitle => 'الأسئلة الشائعة';

  @override
  String get faqQuestion1 =>
      'كيف أستخدم رمز الاستجابة السريعة الخاص بي للدخول إلى المقهى؟';

  @override
  String get faqAnswer1 =>
      'ببساطة افتح قسم رمز الاستجابة السريعة من لوحة التحكم الخاصة بك، وأظهره للماسح الضوئي عند المدخل، وحدد عدد الأشخاص المرافقين لك.';

  @override
  String get faqQuestion2 => 'ماذا يحدث عند نفاد رصيدي الشهري؟';

  @override
  String get faqAnswer2 =>
      'إذا كانت تنبيهات الرصيد مفعّلة لديك، فسنرسل لك تنبيهًا بانخفاض الرصيد بمجرد أن يتبقى لديك 3 جلسات شيشة أو مشروبات أو أقل هذا الشهر، حتى لا تُفاجأ. يبدأ رصيدك من جديد مع كل فترة عضوية جديدة — أو فورًا إذا قمت بالترقية إلى باقة أعلى من الملف الشخصي للحصول على رصيد شهري أكبر.';

  @override
  String get faqQuestion3 => 'هل يمكنني إحضار ضيوف إلى المقهى؟';

  @override
  String get faqAnswer3 =>
      'نعم — تتضمن كل باقة حدًا أقصى للضيوف، يظهر كـ«الحد الأقصى للضيوف» في تفاصيل العضوية. عند فتح الباب برمز الاستجابة السريعة، اختر عدد الضيوف المرافقين لك بما لا يتجاوز هذا الحد. يغطي رصيدك الشهري طلباتك أنت فقط؛ أما طلبات الضيوف فتحصل على خصومات الأعضاء لكنها تُدفع بشكل منفصل.';

  @override
  String get faqQuestion4 =>
      'ما الفرق بين ساعات الخدمة الكاملة والخدمة الذاتية؟';

  @override
  String get faqAnswer4 =>
      'ساعات الخدمة الكاملة (٩:٠٠ ص – ١١:٠٠ م) مزوّدة بطاقم عمل يتولى الطلبات وتجهيز الشيشة نيابة عنك. أما ساعات الخدمة الذاتية (١١:٠٠ م – ٩:٠٠ ص) فتتيح للأعضاء الدخول إلى المكان بعضويتهم، لكن دون طاقم عمل حاضر، فتكون تجربة أكثر محدودية وتعتمد على خدمة النفس.';

  @override
  String get faqDraftAnswerNote =>
      'إجابة مسودة — بانتظار التأكيد من الشركة، وليست نصاً نهائياً.';

  @override
  String get resourcesCardTitle => 'الموارد';

  @override
  String get userGuideLabel => 'دليل المستخدم';

  @override
  String get membershipBenefitsLabel => 'مزايا العضوية';

  @override
  String get communityGuidelinesLabel => 'إرشادات المجتمع';

  @override
  String get appLockedTitle => 'التطبيق مقفل';

  @override
  String get unlockWithBiometricPrompt =>
      'افتح القفل ببصمة إصبعك أو وجهك للمتابعة.';

  @override
  String get unlockWithPasswordPrompt => 'أدخل كلمة مرورك للمتابعة.';

  @override
  String get checkingEllipsis => 'جارٍ التحقق…';

  @override
  String get tryAgainBiometricButton => 'أعد المحاولة';

  @override
  String get usePasswordInsteadButton => 'استخدم كلمة المرور بدلاً من ذلك';

  @override
  String get passwordFieldLabel => 'كلمة المرور';

  @override
  String get verifyingEllipsis => 'جارٍ التحقق…';

  @override
  String get unlockButton => 'فتح القفل';

  @override
  String get useBiometricInsteadButton =>
      'استخدم المصادقة البيومترية بدلاً من ذلك';

  @override
  String get enterYourPasswordError => 'أدخل كلمة مرورك';

  @override
  String get couldntVerifyPasswordError =>
      'تعذر التحقق من كلمة مرورك. تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get unlockReasonPrompt => 'افتح قفل Rosewater Café';

  @override
  String get couldntSignOutError =>
      'تعذر تسجيل الخروج. يرجى المحاولة مرة أخرى.';

  @override
  String get notifSubscriptionActivatedTitle => 'تم تفعيل العضوية';

  @override
  String notifSubscriptionActivatedBody(String plan, String date) {
    return 'عضويتك $plan مفعّلة الآن حتى $date.';
  }

  @override
  String get notifEventReservationConfirmedTitle => 'تم تأكيد حجز الفعالية';

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
      other: '$guestCount ضيف',
      many: '$guestCount ضيفًا',
      few: '$guestCount ضيوف',
      two: 'ضيفين',
      one: 'ضيف واحد',
    );
    return 'تم تأكيد حجزك ($eventType) يوم $date الساعة $time لـ $_temp0.';
  }

  @override
  String unreadNotificationsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار غير مقروء',
      many: '$count إشعارًا غير مقروء',
      few: '$count إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
      zero: 'لا توجد إشعارات غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String unreadBadgeSemantics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count إشعار غير مقروء',
      many: '$count إشعارًا غير مقروء',
      few: '$count إشعارات غير مقروءة',
      two: 'إشعاران غير مقروءين',
      one: 'إشعار واحد غير مقروء',
    );
    return '$_temp0';
  }

  @override
  String get markAsReadButton => 'تعليم كمقروء';

  @override
  String get viewDetailsButton => 'عرض التفاصيل';

  @override
  String get noNotificationsTitle => 'لا توجد إشعارات بعد';

  @override
  String get noNotificationsBody =>
      'ستظهر هنا تحديثات الدفع وحجوزات الفعاليات.';

  @override
  String get couldntLoadNotificationsError => 'تعذر تحميل إشعاراتك.';

  @override
  String get couldntUpdateNotificationError =>
      'تعذر تحديث هذا الإشعار. يرجى المحاولة مرة أخرى.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'منذ $n دقيقة',
      few: 'منذ $n دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'منذ $n ساعة',
      few: 'منذ $n ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String timeDaysAgo(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'منذ $n يومًا',
      few: 'منذ $n أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String get notifEventReminderTitle => 'تذكير بالفعالية';

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
      other: '$guestCount ضيف',
      many: '$guestCount ضيفًا',
      few: '$guestCount ضيوف',
      two: 'ضيفين',
      one: 'ضيف واحد',
    );
    return 'موعد حجزك ($eventType) يقترب: يوم $date الساعة $time لـ $_temp0.';
  }

  @override
  String get notifLowAllowanceTitle => 'تنبيه انخفاض الرصيد';

  @override
  String notifLowHookahBody(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'تبقّى لك $remaining جلسة شيشة فقط هذا الشهر.',
      few: 'تبقّت لك $remaining جلسات شيشة فقط هذا الشهر.',
      two: 'تبقّت لك جلستا شيشة فقط هذا الشهر.',
      one: 'تبقّت لك جلسة شيشة واحدة فقط هذا الشهر.',
      zero: 'لقد استخدمت جميع جلسات الشيشة لهذا الشهر.',
    );
    return '$_temp0';
  }

  @override
  String notifLowDrinksBody(int remaining) {
    String _temp0 = intl.Intl.pluralLogic(
      remaining,
      locale: localeName,
      other: 'تبقّى لك $remaining مشروبًا فقط هذا الشهر.',
      few: 'تبقّت لك $remaining مشروبات فقط هذا الشهر.',
      two: 'تبقّى لك مشروبان فقط هذا الشهر.',
      one: 'تبقّى لك مشروب واحد فقط هذا الشهر.',
      zero: 'لقد استخدمت جميع مشروباتك لهذا الشهر.',
    );
    return '$_temp0';
  }

  @override
  String get reservationDetailsTitle => 'تفاصيل الحجز';

  @override
  String get reservationStatusConfirmed => 'مؤكد';

  @override
  String get reservationStatusPending => 'قيد الانتظار';

  @override
  String get reservationStatusCancelled => 'ملغى';

  @override
  String get totalColonLabel => 'الإجمالي:';

  @override
  String get reservationNotFound => 'هذا الحجز لم يعد متاحًا.';

  @override
  String get couldntLoadReservationError => 'تعذر تحميل هذا الحجز.';

  @override
  String get payWithLabel => 'الدفع باستخدام';

  @override
  String get useNewCardOption => 'استخدام بطاقة جديدة';

  @override
  String get saveCardForNextTime => 'حفظ هذه البطاقة للمرة القادمة';

  @override
  String cardExpiryShort(String date) {
    return 'تنتهي $date';
  }

  @override
  String get cardExpiredLabel => 'منتهية الصلاحية';

  @override
  String get notifSubscriptionUpgradedTitle => 'تمت ترقية العضوية';

  @override
  String notifSubscriptionUpgradedBody(
    String oldPlan,
    String newPlan,
    String date,
  ) {
    return 'تمت ترقيتك من $oldPlan إلى $newPlan. عضويتك الجديدة مفعّلة حتى $date.';
  }
}
