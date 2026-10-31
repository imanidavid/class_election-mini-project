import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:class_election/election.dart';
import 'package:class_election/election_repository.dart';
import 'package:class_election/home_screen.dart';
import 'package:class_election/login_screen.dart';
import 'package:class_election/models.dart';

class _FakeRepository implements ElectionRepository {
  _FakeRepository(this.election);

  final Election election;

  @override
  Stream<List<Candidate>> candidatesStream() =>
      Stream.value(election.candidates);

  @override
  Stream<List<String>> votersStream() => Stream.value(election.voters);

  @override
  Future<String?> addCandidate(Election election, String rawName) async => null;

  @override
  Future<String?> castVote(
    Election election,
    Candidate candidate,
    String rawVoterName,
  ) async => null;

  @override
  Future<String?> renameCandidate(
    Election election,
    Candidate candidate,
    String rawName,
  ) async => null;

  @override
  Future<String?> removeCandidate(
    Election election,
    Candidate candidate,
  ) async => null;

  @override
  Future<String?> resetVotes(Election election) async => null;

  @override
  Future<String?> undoRemove(Candidate candidate) async => null;
}

void main() {
  testWidgets('App builds and shows the Vote screen', (tester) async {
    final repository = _FakeRepository(
      Election(candidates: [Candidate('Keza Uwase')]),
    );
    await tester.pumpWidget(
      MaterialApp(home: ElectionHome(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('e.g. aLINE'), findsOneWidget);
  });

  testWidgets('Login screen validates an empty form', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('At least 6 characters'), findsOneWidget);
  });
}
