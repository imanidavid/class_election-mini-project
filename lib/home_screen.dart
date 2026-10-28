import 'package:flutter/material.dart';

import 'candidates_screen.dart';
import 'election.dart';
import 'models.dart';
import 'results_screen.dart';
import 'vote_screen.dart';

/// The shell of the app: owns the [Election] and switches between the three
/// tabs. Every tab reads the same [Election], so a change made on one tab is
/// already on the others the moment they are shown again.
class ElectionHome extends StatefulWidget {
  const ElectionHome({super.key});

  @override
  State<ElectionHome> createState() => _ElectionHomeState();
}

class _ElectionHomeState extends State<ElectionHome> {
  final election = Election(
    candidates: [
      Candidate('Keza Uwase'),
      Candidate('Mutoni Aline'),
      Candidate('Patrick Niyonzima'),
    ],
  );

  int _index = 0;

  /// Shows a short message at the bottom of the screen.
  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Tells Flutter to redraw every tab from the current data.
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          VoteScreen(
            election: election,
            showMessage: showMessage,
            refresh: refresh,
          ),
          ResultsScreen(election: election),
          CandidatesScreen(
            election: election,
            showMessage: showMessage,
            refresh: refresh,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Results'),
          NavigationDestination(icon: Icon(Icons.groups), label: 'Candidates'),
        ],
      ),
    );
  }
}
