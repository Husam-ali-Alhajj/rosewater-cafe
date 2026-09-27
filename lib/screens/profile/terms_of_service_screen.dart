import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/legal_document_screen.dart';

/// Sprint 9 Task 5. **Draft placeholder text, not company-approved copy** --
/// see docs/decisions.md's Task 5 entry and [LegalDocumentScreen]'s doc
/// comment. The billing section states this app's actual upgrade-only rule
/// (decision #75: `upgrade_subscription` rejects anything that isn't a
/// strictly-higher-priced plan) rather than a generic "you may change your
/// plan" line that wouldn't be true here.
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

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(title: AppLocalizations.of(context).termsOfService, sections: _sections);
  }
}
