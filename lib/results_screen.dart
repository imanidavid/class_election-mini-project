import 'package:flutter/material.dart';

import 'election.dart';

/// The Results tab: a banner with the winner, the tie, or "No votes yet",
/// then every candidate ranked with their votes, percentage and a bar.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.election});

  final Election election;

  @override
  Widget build(BuildContext context) {
    final ranked = election.ranked();
    final total = election.totalVotes;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: election.isTied() ? scheme.tertiary : scheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            election.winnerText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ranked.isEmpty
              ? const Center(child: Text('No candidates yet'))
              : ListView.builder(
                  itemCount: ranked.length,
                  itemBuilder: (context, index) {
                    final candidate = ranked[index];
                    final percent = election.percentage(candidate);
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ${candidate.name} — '
                              '${candidate.votes} votes — '
                              '${percent.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: total == 0 ? 0 : percent / 100,
                              minHeight: 12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
