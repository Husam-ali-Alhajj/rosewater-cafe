import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rosewater_cafe/theme/app_theme.dart';
import 'package:rosewater_cafe/widgets/app_logo.dart';

String _assetShown(WidgetTester tester) =>
    ((tester.widget<Image>(find.byType(Image)).image) as AssetImage).assetName;

void main() {
  testWidgets('light mode uses the normal logo', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const AppLogo(height: 80)));
    expect(_assetShown(tester), 'assets/images/logo.png');
  });

  testWidgets('dark mode uses the version with the light hookah', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.dark(), home: const AppLogo(height: 80)));
    expect(_assetShown(tester), 'assets/images/logo_dark.png');
  });

  testWidgets('screen readers hear the cafe name', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: AppTheme.light(), home: const AppLogo(height: 80)));
    expect(find.bySemanticsLabel('Rosewater VIP Cafe'), findsOneWidget);
  });
}
