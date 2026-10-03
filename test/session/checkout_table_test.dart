import 'dart:io';

import 'package:darts_points_counter/session/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

const _tablePath = 'test/session/checkout_table.txt';

/// The double-out checkout table, one "remaining: route" line from 2 to 170.
String currentTable() {
  final lines = <String>[];
  for (var remaining = 2; remaining <= 170; remaining++) {
    final session = newSession()
      ..startGame([alice], config: X01Config(startScore: remaining));
    final route = session.state.game!.checkoutSuggestion;
    lines.add('$remaining: ${route?.map((d) => d.notation).join(' ') ?? '-'}');
  }
  return '${lines.join('\n')}\n';
}

void main() {
  // The table is reviewed like code: any change to the routing shows up as
  // a diff of checkout_table.txt. Regenerate with UPDATE_CHECKOUT_TABLE=1.
  test('double-out routes match the reviewed table', () {
    final file = File(_tablePath);
    if (Platform.environment['UPDATE_CHECKOUT_TABLE'] == '1') {
      file.writeAsStringSync(currentTable());
    }
    expect(currentTable(), file.readAsStringSync());
  });
}
