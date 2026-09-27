import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/legal_document_screen.dart';

/// Sprint 9 Task 5. **Draft placeholder text, not company-approved copy** --
/// see docs/decisions.md's Task 5 entry and [LegalDocumentScreen]'s doc
/// comment. The account-deletion section describes decision #52's real,
/// immediate self-service deletion; every other data category names an
/// actual table this app has (`profiles`, `id_documents`, `payment_methods`,
/// `door_access_logs`, `event_reservations`, `subscriptions`,
/// `usage_allowances`, `notifications`) rather than invented, generic
/// filler -- "matching the structure real ones have" was the ask, not
/// "sounds like one."
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
          'App Preferences: the language, theme, and notification settings you choose.\n\n'
          'Notifications: the content of the account, reservation, and membership alerts we send you '
          'inside the App.',
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
          'App\'s functionality.',
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
          'notification preferences from Notifications settings, and request deletion of your '
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

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(title: AppLocalizations.of(context).privacyPolicy, sections: _sections);
  }
}
