
import 'dart:developer';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data/mock_ordering_api.dart';
import 'services/device_store.dart';
import 'services/reminder_service.dart';
import 'services/sound_service.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Hive.initFlutter();
  final box = await Hive.openBox('userdata');
  final token = box.get('token')?.toString();
  log('Token saved successfully in Hive: $token');
  final sound = SoundService();
  await sound.init();
  final store = await PrefsStore.open();
  final reminders = ReminderService();
  // Swap MockOrderingApi for the real API client (see lib/data/ordering_api.dart).
  final state = AppState(api: MockOrderingApi(), sound: sound, store: store);
  await state.init();
  reminders.onOpenCart = state.openCartFromReminder;
  await reminders.init();
  runApp(ProviderScope(child: AirSmartLensApp(state: state, reminders: reminders)));
}

class AirSmartLensApp extends StatefulWidget {
  final AppState state;
  final ReminderService reminders;
  const AirSmartLensApp({super.key, required this.state, required this.reminders});

  @override
  State<AirSmartLensApp> createState() => _AirSmartLensAppState();
}

class _AirSmartLensAppState extends State<AirSmartLensApp> {
  late final AppLifecycleListener _life;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(
      onHide: () {
        final r = widget.state.cartReminder;
        if (r != null) {
          widget.reminders.schedule(title: r.title, body: r.body, after: widget.state.remindAfter);
        }
      },
      onShow: () {
        widget.reminders.cancel();
        widget.state.activity();
      },
    );
    widget.state.activity();
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: AppScope(
        state: widget.state,
        child: ValueListenableBuilder<bool?>(
          valueListenable: widget.state.darkN,
          builder: (context, dark, _) => MaterialApp(
            title: 'Air Smart Lens',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(AppColors.light),
            darkTheme: buildTheme(AppColors.darkTheme),
            // side menu › Display › Dark mode; until it is used, the app follows the phone
            themeMode: dark == null
                ? ThemeMode.system
                : dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
            scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: PointerDeviceKind.values.toSet()),
            home: const AppShell(),
          ),
        ),
      ),
    );
  }
}
