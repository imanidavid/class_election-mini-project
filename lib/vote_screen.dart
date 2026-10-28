import 'package:flutter/material.dart';

import 'election.dart';
import 'models.dart';

/// The Vote tab: the voter types their name once, then taps Vote on one
/// candidate card. Each card shows how many votes that candidate has so far.
class VoteScreen extends StatefulWidget {
  const VoteScreen({
    super.key,
    required this.election,
    required this.showMessage,
    required this.refresh,
  });

  final Election election;
  final void Function(String) showMessage;
  final void Function() refresh;

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _voteFor(Candidate candidate) {
    final error = widget.election.castVote(candidate, nameController.text);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    nameController.clear();
    widget.refresh();
    widget.showMessage('Vote counted for ${candidate.name}');
  }

  @override
  Widget build(BuildContext context) {
    final election = widget.election;
    return Scaffold(
      appBar: AppBar(title: const Text('Vote')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your name',
                hintText: 'e.g. aLINE',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                if (election.candidates.isNotEmpty) {
                  _voteFor(election.candidates.first);
                }
              },
            ),
          ),
          Expanded(
            child: election.candidates.isEmpty
                ? const Center(
                    child: Text('No candidates yet. Add them on the last tab.'),
                  )
                : ListView.builder(
                    itemCount: election.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = election.candidates[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(candidate.name),
                          subtitle: Text('${candidate.votes} votes so far'),
                          trailing: FilledButton(
                            onPressed: () => _voteFor(candidate),
                            child: const Text('Vote'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
