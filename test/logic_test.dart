// The pure-Dart business logic against results produced by the HTML prototype's own JavaScript (v116, 6 Nov):
// hashes, money, range codes, all 479 order grids, 2,106 power searches with their codes, cart sentences, the
// repeat-order grids, simulated stock per power, N/A alternatives, QR codes and scanning, QR modules, Shop by range
// and prices. See test/reference_checks.dart and tool/reference_check/README.md.
import 'package:flutter_test/flutter_test.dart';
import 'package:air_smart_lens/core/models.dart';
import 'package:air_smart_lens/core/quantity.dart';

import 'reference_checks.dart';

void main() {
  test('logic matches the prototype', () {
    final r = runReferenceChecks();
    expect(r.checks, greaterThan(25000));
    expect(r.fails, isEmpty, reason: r.fails.take(10).join('\n'));
  });

  test('quantities and axis steps', () {
    expect(qWord('P', 1.5), '1½ pairs');
    expect(qWord('H', 0.5), 'half a pair');
    expect(qWord('R', 1), '1 right lens');
    expect(qStepN('H', 0.5, -1), 0.5);
    expect(qStepN('P', 1, 1), 2);
    expect(nearestAx(100, LensType.kt), 90);
    expect(nearestAx(0, LensType.prog), 180);
    expect(nearestAx(93, LensType.prog), 95);
  });
}
