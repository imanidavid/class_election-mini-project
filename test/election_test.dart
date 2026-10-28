import 'package:flutter_test/flutter_test.dart';
import 'package:class_election/election.dart';
import 'package:class_election/models.dart';

void main() {
  test('aLINE then Aline is refused', () {
    final e = Election(candidates: [Candidate('Keza Uwase')]);
    expect(e.castVote(e.candidates.first, 'aLINE'), isNull);
    expect(e.castVote(e.candidates.first, '  ALINE '), 'Aline has already voted');
  });

  test('4, 4, 1 -> 44.4%, 44.4%, 11.1% and a tie, highest first', () {
    final keza = Candidate('Keza Uwase');
    final mutoni = Candidate('Mutoni Aline');
    final patrick = Candidate('Patrick Niyonzima');
    final e = Election(candidates: [patrick, keza, mutoni]);
    for (var i = 0; i < 4; i++) {
      e.castVote(keza, 'voter$i');
    }
    for (var i = 0; i < 4; i++) {
      e.castVote(mutoni, 'mutoniVoter$i');
    }
    e.castVote(patrick, 'patrickVoter');
    final ranked = e.ranked();
    expect(ranked[0].name, 'Keza Uwase');
    expect(ranked[1].name, 'Mutoni Aline');
    expect(ranked[2].name, 'Patrick Niyonzima');
    expect(e.percentage(ranked[0]).toStringAsFixed(1), '44.4');
    expect(e.percentage(ranked[1]).toStringAsFixed(1), '44.4');
    expect(e.percentage(ranked[2]).toStringAsFixed(1), '11.1');
    expect(e.winnerText(), 'Tie between Keza Uwase and Mutoni Aline (4 votes each)');
  });

  test('cleanName collapses spaces and title-cases', () {
    final e = Election(candidates: [Candidate('X')]);
    expect(e.cleanName('  keza   uwase '), 'Keza Uwase');
    expect(e.cleanName('aLINE'), 'Aline');
  });

  test('adding duplicate keza is refused', () {
    final e = Election(candidates: [Candidate('Keza Uwase')]);
    expect(e.addCandidate(' keza  uwase '), 'Keza Uwase is already a candidate');
  });

  test('reset clears votes -> No votes yet, never NaN', () {
    final keza = Candidate('Keza Uwase');
    final e = Election(candidates: [keza]);
    e.castVote(keza, 'Aline');
    e.resetVotes();
    expect(keza.votes, 0);
    expect(e.totalVotes, 0);
    expect(e.winnerText(), 'No votes yet');
    expect(e.percentage(keza), 0);
  });

  test('candidate with votes cannot be removed', () {
    final keza = Candidate('Keza Uwase');
    final e = Election(candidates: [keza]);
    e.castVote(keza, 'Aline');
    expect(e.removeCandidate(keza), isNotNull);
    expect(e.candidates.length, 1);
  });
}
