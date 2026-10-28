/// The data describing one candidate in the election.
///
/// [name] never changes once the candidate is created, so it is `final`.
/// [votes] changes every time this candidate receives a vote, so it is not.
class Candidate {
  Candidate(this.name);

  final String name;
  int votes = 0;
}
