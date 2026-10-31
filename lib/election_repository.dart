import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'election.dart';
import 'models.dart';

abstract class ElectionRepository {
  Stream<List<Candidate>> candidatesStream();

  Stream<List<String>> votersStream();

  Future<String?> addCandidate(Election election, String rawName);

  Future<String?> renameCandidate(
    Election election,
    Candidate candidate,
    String rawName,
  );

  Future<String?> removeCandidate(Election election, Candidate candidate);

  Future<String?> undoRemove(Candidate candidate);

  Future<String?> castVote(
    Election election,
    Candidate candidate,
    String rawVoterName,
  );

  Future<String?> resetVotes(Election election);
}

class FirestoreElectionRepository implements ElectionRepository {
  FirestoreElectionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _userCollection(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  CollectionReference<Map<String, dynamic>> get _candidates =>
      _userCollection('candidates');

  CollectionReference<Map<String, dynamic>> get _voters =>
      _userCollection('voters');

  @override
  Stream<List<Candidate>> candidatesStream() {
    return _candidates
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Candidate.fromDoc).toList());
  }

  @override
  Stream<List<String>> votersStream() {
    return _voters.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => doc.data()['name'])
          .whereType<String>()
          .toList(),
    );
  }

  @override
  Future<String?> addCandidate(Election election, String rawName) async {
    final name = election.cleanName(rawName);
    if (name.isEmpty) return 'Type a name first';
    if (election.candidates.any(
      (candidate) => candidate.name.toLowerCase() == name.toLowerCase(),
    )) {
      return '$name is already a candidate';
    }

    final id = nameKey(name);
    try {
      await _db.runTransaction((transaction) async {
        final ref = _candidates.doc(id);
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) throw const _DuplicateCandidate();
        transaction.set(ref, {'name': name, 'votes': 0});
      });
      return null;
    } on _DuplicateCandidate {
      return '$name is already a candidate';
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  @override
  Future<String?> renameCandidate(
    Election election,
    Candidate candidate,
    String rawName,
  ) async {
    final name = election.cleanName(rawName);
    if (name.isEmpty) return 'Type a name first';
    if (name.toLowerCase() == candidate.name.toLowerCase()) return null;
    final duplicate = election.candidates.any(
      (other) =>
          other.id != candidate.id &&
          other.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) return '$name is already a candidate';
    if (candidate.id.isEmpty) return 'That candidate no longer exists';

    final newId = nameKey(name);
    try {
      if (newId == candidate.id) {
        await _candidates.doc(candidate.id).update({'name': name});
        return null;
      }

      await _db.runTransaction((transaction) async {
        final oldRef = _candidates.doc(candidate.id);
        final newRef = _candidates.doc(newId);
        final oldSnapshot = await transaction.get(oldRef);
        final newSnapshot = await transaction.get(newRef);

        if (!oldSnapshot.exists) throw const _CandidateGone();
        if (newSnapshot.exists) throw const _DuplicateCandidate();

        final votes = (oldSnapshot.data()?['votes'] as num?)?.toInt() ?? 0;
        transaction.set(newRef, {'name': name, 'votes': votes});
        transaction.delete(oldRef);
      });
      return null;
    } on _CandidateGone {
      return 'That candidate no longer exists';
    } on _DuplicateCandidate {
      return '$name is already a candidate';
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  @override
  Future<String?> removeCandidate(
    Election election,
    Candidate candidate,
  ) async {
    if (candidate.votes > 0) {
      return '${candidate.name} has votes and cannot be removed';
    }
    if (candidate.id.isEmpty) return 'That candidate no longer exists';

    try {
      await _candidates.doc(candidate.id).delete();
      return null;
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  @override
  Future<String?> undoRemove(Candidate candidate) async {
    if (candidate.id.isEmpty) return 'Could not undo that removal';

    try {
      await _candidates.doc(candidate.id).set({
        'name': candidate.name,
        'votes': 0,
      });
      return null;
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  @override
  Future<String?> castVote(
    Election election,
    Candidate candidate,
    String rawVoterName,
  ) async {
    final name = election.cleanName(rawVoterName);
    if (name.isEmpty) return 'Type your name first';
    if (election.voters.contains(name)) return '$name has already voted';
    if (candidate.id.isEmpty) return 'That candidate no longer exists';

    final voterId = nameKey(name);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    try {
      await _db.runTransaction((transaction) async {
        final candidateRef = _candidates.doc(candidate.id);
        final voterRef = _voters.doc(voterId);
        final candidateSnapshot = await transaction.get(candidateRef);
        final voterSnapshot = await transaction.get(voterRef);

        if (!candidateSnapshot.exists) throw const _CandidateGone();
        if (voterSnapshot.exists) throw const _AlreadyVoted();

        transaction.update(candidateRef, {'votes': FieldValue.increment(1)});
        transaction.set(voterRef, {
          'name': name,
          'candidateId': candidate.id,
          'votedByUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      return null;
    } on _AlreadyVoted {
      return '$name has already voted';
    } on _CandidateGone {
      return '${candidate.name} is no longer a candidate';
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  @override
  Future<String?> resetVotes(Election election) async {
    try {
      final candidateSnapshot = await _candidates.get();
      final voterSnapshot = await _voters.get();
      final operations = <void Function(WriteBatch)>[];

      for (final doc in candidateSnapshot.docs) {
        final votes = (doc.data()['votes'] as num?)?.toInt() ?? 0;
        if (votes != 0) {
          operations.add((batch) => batch.update(doc.reference, {'votes': 0}));
        }
      }
      for (final doc in voterSnapshot.docs) {
        operations.add((batch) => batch.delete(doc.reference));
      }

      for (var start = 0; start < operations.length; start += 450) {
        final batch = _db.batch();
        for (final operation in operations.skip(start).take(450)) {
          operation(batch);
        }
        await batch.commit();
      }
      return null;
    } on FirebaseException catch (e) {
      return _message(e);
    }
  }

  String _message(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'The server refused that change. Check the Firestore rules.';
      case 'unavailable':
      case 'network-request-failed':
        return 'No internet connection. Try again.';
      case 'not-found':
        return 'That item no longer exists.';
      case 'failed-precondition':
        return 'Firestore is not set up for this project.';
      default:
        return 'Something went wrong (${e.code}).';
    }
  }
}

String nameKey(String cleanName) =>
    Uri.encodeComponent(cleanName.trim().toLowerCase());

class _AlreadyVoted implements Exception {
  const _AlreadyVoted();
}

class _CandidateGone implements Exception {
  const _CandidateGone();
}

class _DuplicateCandidate implements Exception {
  const _DuplicateCandidate();
}
