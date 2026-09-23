import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/screens/profile/help_support_screen.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: HelpSupportScreen()));
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

    testWidgets('the other three answers are a placeholder, never fabricated FAQ copy', (tester) async {
      await _pump(tester);

      // Open each of the other three questions in turn (the accordion is
      // exclusive, so only one is open at a time) -- each shows the SAME
      // placeholder, never three different made-up answers.
      for (final q in [
        'What happens when my monthly allowance runs out?',
        'Can I bring guests to the café?',
        "What's the difference between full service and self-service hours?",
      ]) {
        await tester.tap(find.text(q));
        await tester.pumpAndSettle();
        expect(find.text('Answer not available yet.'), findsOneWidget, reason: q);
      }

      // None of the strings a plausible-sounding fabricated answer would use
      // for these specific questions appear anywhere on the page.
      final pageText = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? (t.textSpan?.toPlainText() ?? ''))
          .join(' ')
          .toLowerCase();
      for (final phrase in [
        'renews', 'resets on', 'billing cycle', // a plausible allowance answer
        'guests are welcome', 'up to 2 guests', 'additional guests', // a plausible guest-policy answer
        'full service includes', 'self-service allows', // a plausible hours answer
      ]) {
        expect(pageText, isNot(contains(phrase)), reason: 'looks like a fabricated answer: "$phrase"');
      }
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
      expect(find.text(answer), findsOneWidget);
      expect(find.text('Answer not available yet.'), findsNothing);

      await tester.tap(find.text('Can I bring guests to the café?'));
      await tester.pumpAndSettle();

      expect(find.text(answer), findsNothing); // the first one closed
      expect(find.text('Answer not available yet.'), findsOneWidget); // only the tapped one is open
    });

    testWidgets('every question can be expanded, and only one body shows at a time', (tester) async {
      await _pump(tester);
      const realAnswer =
          'Simply open the QR Code section from your dashboard, show it to the '
          'scanner at the entrance, and specify how many guests are with you.';

      final questions = [
        'How do I use my QR code to enter the café?',
        'What happens when my monthly allowance runs out?',
        'Can I bring guests to the café?',
        "What's the difference between full service and self-service hours?",
      ];
      // Item 0 starts open; tapping it again would toggle it CLOSED, so only
      // tap when a question isn't already the open one.
      var openIndex = 0;
      for (var i = 0; i < questions.length; i++) {
        if (i != openIndex) {
          await tester.tap(find.text(questions[i]));
          await tester.pumpAndSettle();
          openIndex = i;
        }

        final placeholders = find.text('Answer not available yet.').evaluate().length;
        final realAnswers = find.text(realAnswer).evaluate().length;
        expect(placeholders + realAnswers, 1, reason: 'after opening "${questions[i]}"');
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
