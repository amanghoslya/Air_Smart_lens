import 'package:flutter_test/flutter_test.dart';
import 'package:air_smart_lens/data/mock_ordering_api.dart';
import 'package:air_smart_lens/services/device_store.dart';
import 'package:air_smart_lens/services/sound_service.dart';
import 'package:air_smart_lens/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('starts at welcome when no token is saved', () async {
    final store = MemoryStore();
    final state = AppState(api: MockOrderingApi(), sound: SoundService(), store: store);
    await state.init();
    expect(state.screen, 'welcome');
  });

  test('auto-navigates to home screen on startup when token is saved', () async {
    final store = MemoryStore();
    store.setString('asl.token', 'test_auth_token_xyz_123');
    final state = AppState(api: MockOrderingApi(), sound: SoundService(), store: store);
    await state.init();
    expect(state.screen, 'home');
  });

  test('signOut clears token and navigates back to welcome screen', () async {
    final store = MemoryStore();
    store.setString('asl.token', 'test_auth_token_xyz_123');
    final state = AppState(api: MockOrderingApi(), sound: SoundService(), store: store);
    await state.init();
    expect(state.screen, 'home');

    state.signOut();
    expect(store.getString('asl.token'), '');
    expect(state.screen, 'welcome');
  });
}
