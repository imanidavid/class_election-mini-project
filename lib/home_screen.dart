import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'candidates_screen.dart';
import 'election.dart';
import 'election_repository.dart';
import 'models.dart';
import 'results_screen.dart';
import 'vote_screen.dart';

/// The shell of the app: listens to Firestore and switches between the three
/// tabs. Every tab reads the same live [Election].
class ElectionHome extends StatefulWidget {
  const ElectionHome({super.key, this.repository});

  final ElectionRepository? repository;

  @override
  State<ElectionHome> createState() => _ElectionHomeState();
}

class _ElectionHomeState extends State<ElectionHome> {
  late final ElectionRepository _repository =
      widget.repository ?? FirestoreElectionRepository();

  late Stream<List<Candidate>> _candidatesStream = _repository
      .candidatesStream();
  late Stream<List<String>> _votersStream = _repository.votersStream();

  int _index = 0;

  static const _titles = ['Vote', 'Results', 'Candidates'];

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _retry() {
    setState(() {
      _candidatesStream = _repository.candidatesStream();
      _votersStream = _repository.votersStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Candidate>>(
        stream: _candidatesStream,
        builder: (context, candidatesSnapshot) {
          if (candidatesSnapshot.hasError) {
            return _ErrorState(
              error: candidatesSnapshot.error,
              onRetry: _retry,
            );
          }
          if (!candidatesSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return StreamBuilder<List<String>>(
            stream: _votersStream,
            builder: (context, votersSnapshot) {
              if (votersSnapshot.hasError) {
                return _ErrorState(
                  error: votersSnapshot.error,
                  onRetry: _retry,
                );
              }
              if (!votersSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final election = Election(
                candidates: candidatesSnapshot.data!,
                voters: votersSnapshot.data!,
              );
              return IndexedStack(
                index: _index,
                children: [
                  VoteScreen(
                    election: election,
                    repository: _repository,
                    showMessage: _showMessage,
                  ),
                  ResultsScreen(election: election),
                  CandidatesScreen(
                    election: election,
                    repository: _repository,
                    showMessage: _showMessage,
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.how_to_vote), label: 'Vote'),
          NavigationDestination(
            icon: Icon(Icons.leaderboard),
            label: 'Results',
          ),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Candidates'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load the election.\n$error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
