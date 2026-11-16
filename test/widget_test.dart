// Opens every screen of the app once and fails on any layout or build error.
//
//   flutter test test/widget_smoke_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:air_smart_lens/data/mock_ordering_api.dart';
import 'package:air_smart_lens/main.dart';
import 'package:air_smart_lens/services/reminder_service.dart';
import 'package:air_smart_lens/services/sound_service.dart';
import 'package:air_smart_lens/state/app_state.dart';
import 'package:air_smart_lens/ui/screens/registry.dart';

void main() {
  testWidgets('welcome, sign in and every screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final state = AppState(api: MockOrderingApi(), sound: SoundService());
    await tester.runAsync(state.init);
    await tester.pumpWidget(AirSmartLensApp(state: state, reminders: ReminderService()));
    await tester.pump();
    expect(state.screen, 'welcome');

    state.toLogin();
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);

    state.signIn();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(state.screen, 'home');

    for (final sc in screens.keys) {
      state.jump(sc);
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: sc);
    }

    // the three personas on checkout
    for (final p in ['owner', 'staff', 'sub']) {
      state.setPersona(p);
      state.jump('checkout');
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: 'checkout as $p');
    }

    // let the toasts and animations finish
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    state.dispose(); // stops the cart-nudge timer
  });
}
