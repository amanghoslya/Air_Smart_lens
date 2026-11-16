// Checks the Dart business logic against the HTML prototype (v116, 6 Nov). No device or Flutter engine needed:
//
//   dart run tool/verify_logic.dart
import 'dart:io';

import '../test/reference_checks.dart';

void main() {
  final r = runReferenceChecks();
  for (final f in r.fails.take(25)) {
    stdout.writeln('FAIL $f');
  }
  stdout.writeln('${r.checks} checks, ${r.fails.length} failed (${r.matchLines} product matches compared)');
  exitCode = r.fails.isEmpty ? 0 : 1;
}
