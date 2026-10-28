import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:class_election/main.dart';

void main() {
  testWidgets('App builds and shows the Vote screen', (tester) async {
    await tester.pumpWidget(const ClassElectionApp());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('e.g. aLINE'), findsOneWidget);
  });
}
