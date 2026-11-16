# Builds a plain-Dart copy of the app state (no Flutter engine) and a runner for test/app_flow_test.dart's steps.
# usage: python3 make_runner.py <project dir> <work dir>
import os, re, shutil, sys
proj, work = os.path.abspath(sys.argv[1]), os.path.abspath(sys.argv[2])
here = os.path.dirname(os.path.abspath(__file__))
shutil.rmtree(work, ignore_errors=True)
os.makedirs(work)
app = os.path.join(work, 'app')
shutil.copytree(os.path.join(proj, 'lib'), os.path.join(app, 'lib'))
for d in ['assets', 'test']:
    shutil.copytree(os.path.join(proj, d), os.path.join(app, d))
# sounds: no audio on the VM
f = os.path.join(app, 'lib/services/sound_service.dart')
names = re.findall(r'^  void ([a-z][A-Za-z]*)\(([^)]*)\)', open(f).read(), re.M)
open(f, 'w').write('class SoundService {\n  bool enabled = true;\n  Future<void> init() async {}\n' + ''.join(f'  void {n}({a}) {{}}\n' for n, a in names) + '}\n')
# runner from the flow test
s = open(os.path.join(proj, 'test/app_flow_test.dart')).read().replace("import 'package:flutter_test/flutter_test.dart';\n", '')
s = s[: s.index('void main() {')] + '''
void main() async {
  final ref = jsonDecode(File('test/fixtures/js_flow_reference.json').readAsStringSync()) as List;
  var fails = 0;
  if (ref.length != steps.length) { print('reference has ${ref.length} steps, test has ${steps.length}'); exit(1); }
  final s = AppState(api: MockOrderingApi(), sound: SoundService());
  await s.init();
  for (var i = 0; i < steps.length; i++) {
    steps[i].run(s);
    await Future<void>.delayed(Duration(milliseconds: steps[i].wait));
    final want = normaliseReference((ref[i] as Map)['state'] as Map);
    final got = snapshot(s);
    for (final k in want.keys) {
      if (jsonEncode(got[k]) != jsonEncode(want[k])) {
        if (++fails <= 40) print('step $i "${steps[i].name}": $k\\n   got  ${jsonEncode(got[k])}\\n   want ${jsonEncode(want[k])}');
      }
    }
  }
  print('${steps.length} steps, $fails differences');
  exit(fails == 0 ? 0 : 1);
}
'''
open(os.path.join(app, 'flow.dart'), 'w').write(s)
qr = sys.argv[3] if len(sys.argv) > 3 else None
pk = [('air_smart_lens', app), ('flutter', os.path.join(here, 'fake_flutter')), ('shared_preferences', os.path.join(here, 'fake_shared_preferences'))]
if qr: pk.append(('qr', qr))
import json
json.dump({'configVersion': 2, 'packages': [{'name': n, 'rootUri': 'file://' + r.rstrip('/') + '/', 'packageUri': 'lib/', 'languageVersion': '3.8'} for n, r in pk]}, open(os.path.join(work, 'packages.json'), 'w'))
print(os.path.join(work, 'packages.json'))
