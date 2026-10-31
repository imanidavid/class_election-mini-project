import 'package:cloud_firestore/cloud_firestore.dart';

/// The data describing one candidate in the election.
///
/// [name] never changes once the candidate is created, so it is `final`.
/// [votes] changes every time this candidate receives a vote, so it is not.
class Candidate {
  Candidate(this.name, {this.id = '', this.votes = 0});

  final String id;
  final String name;
  int votes;

  Map<String, dynamic> toMap() => {'name': name, 'votes': votes};

  factory Candidate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Candidate(
      (data['name'] as String?) ?? '',
      id: doc.id,
      votes: (data['votes'] as num?)?.toInt() ?? 0,
    );
  }
}
