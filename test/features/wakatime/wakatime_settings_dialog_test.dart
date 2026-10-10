import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:githabit/features/wakatime/presentation/wakatime_settings_dialog.dart';

void main() {
  testWidgets('WakaTimeSettingsDialog renders API key input and actions properly', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => WakaTimeSettingsDialog.show(context),
                child: const Text('Launch'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Launch'));
    await tester.pumpAndSettle();

    expect(find.text('WakaTime Integration'), findsOneWidget);
    expect(find.text('WakaTime Secret API Key'), findsOneWidget);
    expect(find.text('Save & Connect'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}

