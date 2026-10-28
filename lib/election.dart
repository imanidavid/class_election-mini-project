import 'models.dart';

/// Holds the election's data and every rule that changes it.
///
/// This class imports nothing from Flutter on purpose. Each rule returns a
/// message when it refuses bad input, or `null` when it succeeded and the
/// screen should show its own success message. That keeps the rules testable
/// on their own, far away from any widget.
class Election {
  Election({required List<Candidate> candidates})
    : candidates = List.of(candidates);

  final List<Candidate> candidates;

  /// The cleaned name of every person who has already voted, in the order
  /// they voted. A list, not a set, so `contains` and `indexOf` both work.
  final List<String> voters = [];

  /// The total number of votes across all candidates.
  int get totalVotes => candidates.fold(0, (sum, c) => sum + c.votes);

  /// Cleans a name: trims the ends, squeezes extra spaces between words down
  /// to one, and writes every word in Title Case.
  ///
  ///     '  keza   uwase '  ->  'Keza Uwase'
  ///     'aLINE'             ->  'Aline'
  String cleanName(String raw) {
    final words = raw.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Records one vote for [candidate] from the person named [rawVoterName].
  ///
  /// Returns a message when the vote is refused (empty name, or the person has
  /// already voted). Returns `null` when the vote is accepted.
  String? castVote(Candidate candidate, String rawVoterName) {
    final name = cleanName(rawVoterName);
    if (name.isEmpty) {
      return 'Type your name first';
    }
    if (voters.contains(name)) {
      return '$name has already voted';
    }
    candidate.votes++;
    voters.add(name);
    return null;
  }

  /// Adds a new candidate after cleaning the name.
  ///
  /// Returns a message when the name is empty or already taken, `null` on
  /// success.
  String? addCandidate(String rawName) {
    final name = cleanName(rawName);
    if (name.isEmpty) {
      return 'Type a name first';
    }
    final duplicate = candidates.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      return '$name is already a candidate';
    }
    candidates.add(Candidate(name));
    return null;
  }

  /// Removes [candidate], but only while they have no votes.
  ///
  /// Returns a message when the removal is refused, `null` on success.
  String? removeCandidate(Candidate candidate) {
    if (candidate.votes > 0) {
      return '${candidate.name} has votes and cannot be removed';
    }
    candidates.remove(candidate);
    return null;
  }

  /// Puts a removed candidate back where they were, for the Undo action.
  void undoRemove(Candidate candidate, int position) {
    candidates.insert(position.clamp(0, candidates.length), candidate);
  }

  /// Returns every candidate sorted highest votes first.
  ///
  /// The sort is not guaranteed to be stable in Dart, so when two candidates
  /// have the same number of votes the order between them is decided by name.
  /// That makes the ranking predictable: equal scores always sit together,
  /// alphabetically.
  List<Candidate> ranked() {
    final sorted = List.of(candidates);
    sorted.sort((a, b) {
      final byVotes = b.votes.compareTo(a.votes);
      if (byVotes != 0) return byVotes;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  /// The percentage of all votes that went to [candidate], to one decimal.
  ///
  /// Guarded so that with no votes at all it returns `0`, never `NaN`.
  double percentage(Candidate candidate) {
    if (totalVotes == 0) return 0;
    return candidate.votes / totalVotes * 100;
  }

  /// True when the top score is shared by more than one candidate.
  bool isTied() {
    if (totalVotes == 0) return false;
    final top = ranked().first;
    return ranked().where((c) => c.votes == top.votes).length > 1;
  }

  /// The banner text: the winner, the tie, or a plain "No votes yet".
  String winnerText() {
    if (totalVotes == 0) return 'No votes yet';
    final top = ranked().first;
    final tied = ranked().where((c) => c.votes == top.votes).toList();
    if (tied.length == 1) {
      return 'Winner: ${top.name}';
    }
    final names = tied.map((c) => c.name).join(' and ');
    return 'Tie between $names (${top.votes} votes each)';
  }

  /// Clears every vote and every voter, but keeps the candidates.
  void resetVotes() {
    for (final c in candidates) {
      c.votes = 0;
    }
    voters.clear();
  }
}
