import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/legal_document_screen.dart';

/// Terms of Service, in English and Arabic. DRAFT placeholder text, not reviewed by a lawyer or
/// approved by the company.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const _sections = [
    LegalSection(
      '1. Acceptance of Terms',
      'By creating an account or using the Rosewater Café membership app (the "App"), you agree '
          'to these Terms of Service. If you do not agree, do not use the App.',
    ),
    LegalSection(
      '2. Membership Eligibility & Registration',
      'You must be able to accept these Terms to hold a membership. You are responsible for '
          'keeping your login credentials secure and for all activity under your account.',
    ),
    LegalSection(
      '3. Identity Verification',
      'Certain in-person membership benefits require identity verification. You may be asked to '
          'upload a government-issued ID document; benefits that depend on verification may be '
          'limited or unavailable until your document is reviewed and approved.',
    ),
    LegalSection(
      '4. Membership Plans, Billing & Upgrades',
      'Membership is offered in tiers (for example Basic, Premium, and VIP), each with its own '
          'price and its own monthly hookah, drink, and guest allowances. You may upgrade to any '
          'higher-priced plan at any time; the App does not currently support self-service '
          'downgrades to a lower-priced or equal-priced plan. Each membership period runs 30 days '
          'from the date it starts or is upgraded, after which your usage allowances reset for the '
          'new period.',
    ),
    LegalSection(
      '5. Reservations & Facility Use',
      'You may reserve a spot at eligible events, subject to availability. Checking in at our '
          'facility (door access) is logged against your account for allowance-tracking and '
          'security purposes.',
    ),
    LegalSection(
      '6. Acceptable Use',
      'You agree not to misuse the App, attempt to circumvent its security controls, or use '
          'another member\'s account. The guest limits and usage allowances attached to your plan may '
          'not be circumvented or shared beyond what your plan permits.',
    ),
    LegalSection(
      '7. Payment',
      'Saved payment methods are used to process your subscription charges. You are responsible '
          'for keeping your payment details current and valid.',
    ),
    LegalSection(
      '8. Termination & Account Deletion',
      'We may suspend or terminate an account that violates these Terms. You may delete your own '
          'account at any time from Privacy & Security > Delete Account, after re-entering your '
          'current password. This action is immediate and permanent: your profile, membership '
          'history, saved payment method details, usage records, reservations, uploaded ID '
          'documents, and notifications are all removed and cannot be recovered. There is no '
          'request queue or waiting period -- deletion happens as soon as you confirm it.',
    ),
    LegalSection(
      '9. Disclaimer of Warranties',
      'The App is provided "as is." We do not guarantee that it will be uninterrupted, error-free, '
          'or fit for any particular purpose.',
    ),
    LegalSection(
      '10. Limitation of Liability',
      'To the fullest extent permitted by law, Rosewater Café is not liable for indirect, '
          'incidental, or consequential damages arising from your use of the App.',
    ),
    LegalSection(
      '11. Governing Law',
      '[Placeholder -- the governing jurisdiction for these Terms is to be inserted during legal '
          'review.]',
    ),
    LegalSection(
      '12. Changes to These Terms',
      'We may update these Terms as the App changes. Continued use of the App after an update '
          'means you accept the revised Terms.',
    ),
    LegalSection(
      '13. Contact Us',
      'Questions about these Terms can be directed to the Rosewater Café support team through Help '
          '& Support in the App, or to support@example.com (placeholder -- to be replaced with a '
          'real contact address before these Terms are finalized).',
    ),
  ];

  /// The same draft in Arabic (also a placeholder).
  static const _sectionsAr = [
    LegalSection(
      '1. قبول الشروط',
      'بإنشائك حسابًا أو استخدامك لتطبيق عضوية Rosewater Café ("التطبيق")، فإنك توافق على شروط الخدمة هذه. إذا لم توافق عليها، فلا تستخدم التطبيق.',
    ),
    LegalSection(
      '2. أهلية العضوية والتسجيل',
      'يجب أن تكون قادرًا على قبول هذه الشروط لتحصل على عضوية. وأنت مسؤول عن الحفاظ على أمان بيانات تسجيل دخولك وعن جميع الأنشطة التي تتم عبر حسابك.',
    ),
    LegalSection(
      '3. التحقق من الهوية',
      'تتطلب بعض مزايا العضوية الحضورية التحقق من الهوية. وقد يُطلب منك رفع مستند هوية حكومي؛ وقد تكون المزايا المعتمدة على التحقق محدودة أو غير متاحة إلى أن تتم مراجعة مستندك والموافقة عليه.',
    ),
    LegalSection(
      '4. خطط العضوية والفوترة والترقيات',
      'تُقدَّم العضوية بمستويات (مثل Basic وPremium وVIP)، لكل منها سعره ورصيده الشهري الخاص من الشيشة والمشروبات والضيوف. يمكنك الترقية إلى أي خطة أعلى سعرًا في أي وقت؛ ولا يدعم التطبيق حاليًا الانتقال الذاتي إلى خطة أقل سعرًا أو مساوية في السعر. تمتد كل فترة عضوية 30 يومًا من تاريخ بدئها أو ترقيتها، وبعدها يُعاد تعيين رصيد استخدامك للفترة الجديدة.',
    ),
    LegalSection(
      '5. الحجوزات واستخدام المنشأة',
      'يمكنك حجز مكان في الفعاليات المتاحة، حسب التوفر. ويُسجَّل دخولك إلى منشأتنا على حسابك لأغراض تتبّع الرصيد والأمان.',
    ),
    LegalSection(
      '6. الاستخدام المقبول',
      'توافق على عدم إساءة استخدام التطبيق، أو محاولة التحايل على ضوابطه الأمنية، أو استخدام حساب عضو آخر. ولا يجوز التحايل على حدود الضيوف ورصيد الاستخدام المرتبطة بخطتك أو مشاركتها بما يتجاوز ما تسمح به خطتك.',
    ),
    LegalSection(
      '7. الدفع',
      'تُستخدم وسائل الدفع المحفوظة لمعالجة رسوم اشتراكك. وأنت مسؤول عن إبقاء بيانات الدفع الخاصة بك محدّثة وصالحة.',
    ),
    LegalSection(
      '8. الإنهاء وحذف الحساب',
      'يجوز لنا تعليق أو إنهاء أي حساب يخالف هذه الشروط. ويمكنك حذف حسابك في أي وقت من الخصوصية والأمان ← حذف الحساب، بعد إعادة إدخال كلمة المرور الحالية. هذا الإجراء فوري ونهائي: إذ تُزال بيانات ملفك الشخصي، وسجل عضويتك، وبيانات وسائل الدفع المحفوظة، وسجلات الاستخدام، والحجوزات، ومستندات الهوية المرفوعة، والإشعارات، ولا يمكن استردادها. لا توجد قائمة طلبات ولا فترة انتظار -- يتم الحذف بمجرد تأكيدك.',
    ),
    LegalSection(
      '9. إخلاء المسؤولية عن الضمانات',
      'يُقدَّم التطبيق "كما هو". ولا نضمن أن يعمل دون انقطاع أو أخطاء، أو أن يكون مناسبًا لأي غرض معيّن.',
    ),
    LegalSection(
      '10. تحديد المسؤولية',
      'إلى أقصى حد يسمح به القانون، لا يتحمل Rosewater Café المسؤولية عن أي أضرار غير مباشرة أو عرضية أو تبعية ناتجة عن استخدامك للتطبيق.',
    ),
    LegalSection(
      '11. القانون الحاكم',
      '[نص مؤقت -- سيتم تحديد الجهة القضائية التي تحكم هذه الشروط أثناء المراجعة القانونية.]',
    ),
    LegalSection(
      '12. التغييرات على هذه الشروط',
      'قد نحدّث هذه الشروط مع تطوّر التطبيق. ويعني استمرارك في استخدام التطبيق بعد أي تحديث قبولك للشروط المعدّلة.',
    ),
    LegalSection(
      '13. تواصل معنا',
      'يمكن توجيه الأسئلة المتعلقة بهذه الشروط إلى فريق دعم Rosewater Café عبر المساعدة والدعم في التطبيق، أو إلى support@example.com (عنوان مؤقت -- سيُستبدل بعنوان تواصل حقيقي قبل اعتماد هذه الشروط).',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return LegalDocumentScreen(
      title: AppLocalizations.of(context).termsOfService,
      sections: isArabic ? _sectionsAr : _sections,
    );
  }
}
