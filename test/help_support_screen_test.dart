import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/l10n/app_localizations.dart';
import 'package:rosewater_cafe/screens/profile/help_support_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      // Sprint 8 Task 6: the Resources rows push ComingSoonScreen, which
      // reads AppLocalizations now.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HelpSupportScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('static contact info -- no backend', () {
    testWidgets('shows all three contact cards with their real design copy', (tester) async {
      await _pump(tester);

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.text('Chat with our team'), findsOneWidget);
      expect(find.text('Email Us'), findsOneWidget);
      expect(find.text('Get help via email'), findsOneWidget);
      expect(find.text('Call Us'), findsOneWidget);
      expect(find.text('Speak to support'), findsOneWidget);
    });

    testWidgets('the contact cards are not tappable (no InkWell/GestureDetector wrapping them)', (tester) async {
      await _pump(tester);

      // Tapping where a card is shouldn't do anything observable -- no new
      // route, no ComingSoonScreen, no crash.
      await tester.tap(find.text('Live Chat'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('Live Chat'), findsOneWidget); // still on this screen
      expect(find.byType(HelpSupportScreen), findsOneWidget);
    });
  });

  group('FAQ accordion', () {
    testWidgets('all four real questions are shown', (tester) async {
      await _pump(tester);

      expect(find.text('Frequently Asked Questions'), findsOneWidget);
      expect(find.text('How do I use my QR code to enter the café?'), findsOneWidget);
      expect(find.text('What happens when my monthly allowance runs out?'), findsOneWidget);
      expect(find.text('Can I bring guests to the café?'), findsOneWidget);
      expect(find.text("What's the difference between full service and self-service hours?"), findsOneWidget);
    });

    testWidgets('the real answer is the one exported from the design, and starts expanded', (tester) async {
      await _pump(tester);

      expect(
        find.text(
          'Simply open the QR Code section from your dashboard, show it to the '
          'scanner at the entrance, and specify how many guests are with you.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'Sprint 9 Task 6: the other three answers are real (if draft) content, each flagged as unconfirmed',
      (tester) async {
        await _pump(tester);

        const draftAnswers = {
          'What happens when my monthly allowance runs out?':
              "Once you're down to 3 or fewer hookah sessions or drinks for the month, we'll send you a "
                  'low-allowance alert so you\'re not caught by surprise. Your allowance resets automatically '
                  'at the start of your next membership period, or you can upgrade to a higher plan at any '
                  'time from Profile for a bigger monthly allowance.',
          'Can I bring guests to the café?':
              'Yes — every plan includes a guest limit, shown as Max Guests on your Membership Details page. '
                  'When you check in with your QR code, just let the host know how many guests are joining '
                  'you, up to that limit.',
          "What's the difference between full service and self-service hours?":
              'Full Service Hours (9:00 AM – 11:00 PM) are staffed, with our team handling orders and hookah '
                  'setup for you. Self-Service Hours (11:00 PM – 9:00 AM) let members access the space with '
                  'their membership, but without staff on site, so it\'s a more limited, help-yourself '
                  'experience.',
        };

        // Open each of the other three questions in turn (the accordion is
        // exclusive, so only one is open at a time) -- each shows its own
        // real draft answer, never a blank/placeholder body, and each is
        // marked as not yet confirmed by the company (same disclosure as
        // Task 5's legal screens).
        for (final entry in draftAnswers.entries) {
          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();
          expect(find.text(entry.value), findsOneWidget, reason: entry.key);
          expect(
            find.text('Draft answer — pending confirmation from the company, not final copy.'),
            findsOneWidget,
            reason: entry.key,
          );
          expect(find.text('Answer not available yet.'), findsNothing, reason: entry.key);
        }
      },
    );

    testWidgets('the one real, design-exported answer carries no draft note', (tester) async {
      await _pump(tester);

      // Item 0 starts open -- the real answer is already on screen.
      expect(
        find.text('Draft answer — pending confirmation from the company, not final copy.'),
        findsNothing,
      );
    });

    testWidgets('tapping a question expands it; tapping it again collapses it', (tester) async {
      await _pump(tester);
      const answer =
          'Simply open the QR Code section from your dashboard, show it to the '
          'scanner at the entrance, and specify how many guests are with you.';
      expect(find.text(answer), findsOneWidget); // starts open

      await tester.tap(find.text('How do I use my QR code to enter the café?'));
      await tester.pumpAndSettle();
      expect(find.text(answer), findsNothing); // collapsed

      await tester.tap(find.text('How do I use my QR code to enter the café?'));
      await tester.pumpAndSettle();
      expect(find.text(answer), findsOneWidget); // expanded again
    });

    testWidgets('opening a different question closes the one that was open (exclusive accordion)', (tester) async {
      await _pump(tester);
      const answer =
          'Simply open the QR Code section from your dashboard, show it to the '
          'scanner at the entrance, and specify how many guests are with you.';
      const guestAnswer =
          'Yes — every plan includes a guest limit, shown as Max Guests on your Membership Details page. '
          'When you check in with your QR code, just let the host know how many guests are joining '
          'you, up to that limit.';
      expect(find.text(answer), findsOneWidget);
      expect(find.text(guestAnswer), findsNothing);

      await tester.tap(find.text('Can I bring guests to the café?'));
      await tester.pumpAndSettle();

      expect(find.text(answer), findsNothing); // the first one closed
      expect(find.text(guestAnswer), findsOneWidget); // only the tapped one is open
    });

    testWidgets('every question can be expanded, and only one body shows at a time', (tester) async {
      await _pump(tester);

      final questionsAndAnswers = {
        'How do I use my QR code to enter the café?':
            'Simply open the QR Code section from your dashboard, show it to the '
                'scanner at the entrance, and specify how many guests are with you.',
        'What happens when my monthly allowance runs out?':
            "Once you're down to 3 or fewer hookah sessions or drinks for the month, we'll send you a "
                'low-allowance alert so you\'re not caught by surprise. Your allowance resets automatically '
                'at the start of your next membership period, or you can upgrade to a higher plan at any '
                'time from Profile for a bigger monthly allowance.',
        'Can I bring guests to the café?':
            'Yes — every plan includes a guest limit, shown as Max Guests on your Membership Details page. '
                'When you check in with your QR code, just let the host know how many guests are joining '
                'you, up to that limit.',
        "What's the difference between full service and self-service hours?":
            'Full Service Hours (9:00 AM – 11:00 PM) are staffed, with our team handling orders and hookah '
                'setup for you. Self-Service Hours (11:00 PM – 9:00 AM) let members access the space with '
                'their membership, but without staff on site, so it\'s a more limited, help-yourself '
                'experience.',
      };
      final questions = questionsAndAnswers.keys.toList();
      // Item 0 starts open; tapping it again would toggle it CLOSED, so only
      // tap when a question isn't already the open one.
      var openIndex = 0;
      for (var i = 0; i < questions.length; i++) {
        if (i != openIndex) {
          await tester.tap(find.text(questions[i]));
          await tester.pumpAndSettle();
          openIndex = i;
        }

        for (final entry in questionsAndAnswers.entries) {
          final shouldShow = entry.key == questions[i];
          expect(
            find.text(entry.value),
            shouldShow ? findsOneWidget : findsNothing,
            reason: 'after opening "${questions[i]}", checking "${entry.key}"',
          );
        }
      }
    });
  });

  group('Resources', () {
    testWidgets('lists all three resources, each opening a coming-soon page', (tester) async {
      await _pump(tester);

      expect(find.text('Resources'), findsOneWidget);
      for (final label in ['User Guide', 'Membership Benefits', 'Community Guidelines']) {
        expect(find.text(label), findsOneWidget);
      }

      await tester.tap(find.text('User Guide'));
      await tester.pumpAndSettle();
      expect(find.textContaining('User Guide'), findsOneWidget);
      expect(find.textContaining('coming in a future task'), findsOneWidget);
    });
  });
}
