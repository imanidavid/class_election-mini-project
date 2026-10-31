import 'package:flutter_test/flutter_test.dart';

import 'package:class_election/election_repository.dart';

void main() {
  test('nameKey is case-insensitive and safe for Firestore ids', () {
    expect(nameKey('Keza Uwase'), nameKey('  keza uwase '));
    expect(nameKey('Keza Uwase'), isNot(contains('/')));
  });
}
