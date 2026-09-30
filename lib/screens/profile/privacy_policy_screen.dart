import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/legal_document_screen.dart';

/// Privacy Policy, in English and Arabic. DRAFT placeholder text, not reviewed by a lawyer or
/// approved by the company. It describes the data this app actually stores.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _sections = [
    LegalSection(
      '1. Introduction',
      'This Privacy Policy describes how Rosewater Café ("we," "us," or "our") collects, uses, '
          'and protects information when you use the Rosewater Café membership app (the "App"). By '
          'creating an account, you agree to the practices described in this Policy.',
    ),
    LegalSection(
      '2. Information We Collect',
      'Account & Profile Information: your full name, email address, phone number, and profile '
          'photo.\n\n'
          'Identity Verification Documents: a government-issued ID (image or PDF) you upload to '
          'verify eligibility for in-person membership benefits. These files are stored separately '
          'from your other data and carry a review status (pending, approved, or rejected).\n\n'
          'Payment Method Details: for a card you choose to save, we store only its brand, last 4 '
          'digits, and expiration month/year. We do not store full card numbers, CVV codes, or other '
          'sensitive card data.\n\n'
          'Membership & Usage Data: your subscription plan and its history (including upgrades), '
          'your monthly hookah and drink allowance usage, event reservations you make, and facility '
          'check-ins (door access) logged against your account.\n\n'
          'Notification Preferences: which notification channels (such as email) and types (such as '
          'event reminders) you have turned on or off. Your language and theme choices stay on your '
          'device and are not sent to us.\n\n'
          'Notifications: the content of the account, reservation, and membership alerts we send you '
          'inside the App and, if you have email notifications turned on, by email.',
    ),
    LegalSection(
      '3. How We Use Your Information',
      'We use the information above to: verify your identity and membership eligibility; process '
          'and manage your subscription, including plan upgrades; track your monthly usage '
          'allowances so limits are enforced fairly; manage your event reservations and facility '
          'check-ins; send you account-related and service notifications; keep your account secure '
          '(for example, requiring your current password again before a password, email, or account '
          'change takes effect); and maintain and improve the App.',
    ),
    LegalSection(
      '4. How We Share Your Information',
      'We do not sell your personal information, and we do not share it with third parties for '
          'their own marketing purposes. Your information may be processed by the infrastructure '
          'providers that host the App\'s data and file storage on our behalf, solely to provide the '
          'App\'s functionality. If you have email notifications turned on, notification emails are '
          'delivered through an email service provider, which receives your email address and the '
          'content of those emails solely to deliver them.',
    ),
    LegalSection(
      '5. Data Retention & Account Deletion',
      'We retain your account data for as long as your account stays active. You can permanently '
          'delete your account at any time from Privacy & Security > Delete Account, after '
          're-entering your current password. Deletion is immediate, self-service, and irreversible: '
          'it removes your profile, subscription and billing history, saved payment method details, '
          'usage records, reservations, uploaded ID documents, and notifications. There is no '
          'recovery period and no staff-processed request queue -- once confirmed, the data is gone.',
    ),
    LegalSection(
      '6. Data Security',
      'Access to your data is restricted so that, aside from the limited server-side processes '
          'described above, only you can read your own records. Your uploaded ID documents are kept '
          'in a private, access-controlled file store. Certain sensitive changes -- changing your '
          'password, changing your email, or deleting your account -- require you to re-enter your '
          'current password first, so a device left unlocked can\'t be used to make them silently.',
    ),
    LegalSection(
      '7. Your Choices & Rights',
      'You can review and edit your profile information at any time from Edit Profile, update your '
          'notification preferences -- including turning email notifications off -- from '
          'Notifications settings, and request deletion of your '
          'account and its data at any time as described in Section 5.',
    ),
    LegalSection(
      '8. Children\'s Privacy',
      'The App is not directed at children under 16, and we do not knowingly collect information '
          'from them.',
    ),
    LegalSection(
      '9. Changes to This Policy',
      'We may update this Privacy Policy as the App changes. Continuing to use the App after an '
          'update means you accept the revised Policy.',
    ),
    LegalSection(
      '10. Contact Us',
      'Questions about this Policy can be directed to the Rosewater Café support team through Help '
          '& Support in the App, or to support@example.com (placeholder -- to be replaced with a '
          'real contact address before this Policy is finalized).',
    ),
  ];

  /// The same draft in Arabic (also a placeholder).
  static const _sectionsAr = [
    LegalSection(
      '1. مقدمة',
      'توضح سياسة الخصوصية هذه كيف يجمع Rosewater Café ("نحن") المعلومات ويستخدمها ويحميها عند استخدامك لتطبيق عضوية Rosewater Café ("التطبيق"). بإنشائك حسابًا، فإنك توافق على الممارسات الموضحة في هذه السياسة.',
    ),
    LegalSection(
      '2. المعلومات التي نجمعها',
      'معلومات الحساب والملف الشخصي: اسمك الكامل، وعنوان بريدك الإلكتروني، ورقم هاتفك، وصورة ملفك الشخصي.\n\n'
          'مستندات التحقق من الهوية: هوية حكومية (صورة أو ملف PDF) ترفعها للتحقق من أهليتك للاستفادة من مزايا العضوية الحضورية. تُخزَّن هذه الملفات بشكل منفصل عن بياناتك الأخرى، ولكل منها حالة مراجعة (قيد المراجعة أو مقبول أو مرفوض).\n\n'
          'بيانات وسائل الدفع: بالنسبة للبطاقة التي تختار حفظها، نخزّن فقط نوعها وآخر 4 أرقام منها وشهر وسنة انتهاء صلاحيتها. لا نخزّن أرقام البطاقات الكاملة ولا رموز CVV ولا أي بيانات حساسة أخرى للبطاقة.\n\n'
          'بيانات العضوية والاستخدام: خطة اشتراكك وسجلها (بما في ذلك الترقيات)، واستخدامك الشهري لرصيد الشيشة والمشروبات، وحجوزات الفعاليات التي تجريها، وتسجيلات دخولك إلى المنشأة المسجّلة على حسابك.\n\n'
          'تفضيلات الإشعارات: قنوات الإشعارات (مثل البريد الإلكتروني) وأنواعها (مثل تذكيرات الفعاليات) التي فعّلتها أو أوقفتها. أما اختياراتك للغة والمظهر فتبقى على جهازك ولا تُرسَل إلينا.\n\n'
          'الإشعارات: محتوى تنبيهات الحساب والحجوزات والعضوية التي نرسلها إليك داخل التطبيق، وعبر البريد الإلكتروني إذا كانت إشعارات البريد الإلكتروني مفعّلة لديك.',
    ),
    LegalSection(
      '3. كيف نستخدم معلوماتك',
      'نستخدم المعلومات المذكورة أعلاه من أجل: التحقق من هويتك وأهليتك للعضوية؛ ومعالجة اشتراكك وإدارته، بما في ذلك ترقيات الخطة؛ وتتبّع رصيد استخدامك الشهري لضمان تطبيق الحدود بإنصاف؛ وإدارة حجوزات الفعاليات وتسجيلات الدخول إلى المنشأة؛ وإرسال إشعارات الحساب والخدمة إليك؛ والحفاظ على أمان حسابك (مثل طلب إدخال كلمة المرور الحالية مجددًا قبل تنفيذ أي تغيير على كلمة المرور أو البريد الإلكتروني أو الحساب)؛ وصيانة التطبيق وتحسينه.',
    ),
    LegalSection(
      '4. كيف نشارك معلوماتك',
      'لا نبيع معلوماتك الشخصية، ولا نشاركها مع أطراف ثالثة لأغراضها التسويقية الخاصة. قد تتم معالجة معلوماتك من قِبل مزوّدي البنية التحتية الذين يستضيفون بيانات التطبيق وملفاته نيابةً عنا، وذلك فقط لتوفير وظائف التطبيق. وإذا كانت إشعارات البريد الإلكتروني مفعّلة لديك، فإن رسائل الإشعارات تُرسَل عبر مزوّد خدمة بريد إلكتروني يتلقى عنوان بريدك الإلكتروني ومحتوى تلك الرسائل لغرض إيصالها فقط.',
    ),
    LegalSection(
      '5. الاحتفاظ بالبيانات وحذف الحساب',
      'نحتفظ ببيانات حسابك طالما ظل حسابك نشطًا. يمكنك حذف حسابك نهائيًا في أي وقت من الخصوصية والأمان ← حذف الحساب، بعد إعادة إدخال كلمة المرور الحالية. يتم الحذف فورًا وذاتيًا ولا يمكن التراجع عنه: إذ يزيل ملفك الشخصي، وسجل اشتراكاتك وفواتيرك، وبيانات وسائل الدفع المحفوظة، وسجلات الاستخدام، والحجوزات، ومستندات الهوية المرفوعة، والإشعارات. لا توجد فترة استرداد ولا قائمة طلبات يعالجها الموظفون -- بمجرد التأكيد تُحذف البيانات.',
    ),
    LegalSection(
      '6. أمان البيانات',
      'يقتصر الوصول إلى بياناتك بحيث لا يستطيع أحد غيرك قراءة سجلاتك، باستثناء العمليات المحدودة على الخادم الموضحة أعلاه. تُحفظ مستندات الهوية التي ترفعها في مخزن ملفات خاص يخضع للتحكم في الوصول. وتتطلب بعض التغييرات الحساسة -- تغيير كلمة المرور أو البريد الإلكتروني أو حذف الحساب -- إعادة إدخال كلمة المرور الحالية أولًا، حتى لا يمكن استخدام جهاز غير مقفل لإجرائها دون علمك.',
    ),
    LegalSection(
      '7. خياراتك وحقوقك',
      'يمكنك مراجعة معلومات ملفك الشخصي وتعديلها في أي وقت من تعديل الملف الشخصي، وتحديث تفضيلات الإشعارات -- بما في ذلك إيقاف إشعارات البريد الإلكتروني -- من إعدادات الإشعارات، وطلب حذف حسابك وبياناته في أي وقت كما هو موضح في القسم 5.',
    ),
    LegalSection('8. خصوصية الأطفال', 'التطبيق غير موجّه للأطفال دون سن 16 عامًا، ولا نجمع معلومات منهم عن علم.'),
    LegalSection(
      '9. التغييرات على هذه السياسة',
      'قد نحدّث سياسة الخصوصية هذه مع تطوّر التطبيق. ويعني استمرارك في استخدام التطبيق بعد أي تحديث قبولك للسياسة المعدّلة.',
    ),
    LegalSection(
      '10. تواصل معنا',
      'يمكن توجيه الأسئلة المتعلقة بهذه السياسة إلى فريق دعم Rosewater Café عبر المساعدة والدعم في التطبيق، أو إلى support@example.com (عنوان مؤقت -- سيُستبدل بعنوان تواصل حقيقي قبل اعتماد هذه السياسة).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return LegalDocumentScreen(
      title: AppLocalizations.of(context).privacyPolicy,
      sections: isArabic ? _sectionsAr : _sections,
    );
  }
}
