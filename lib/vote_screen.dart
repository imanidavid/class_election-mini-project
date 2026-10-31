import 'package:flutter/material.dart';

import 'election.dart';
import 'election_repository.dart';
import 'models.dart';

/// The Vote tab: the voter types their name once, then taps Vote on one
/// candidate card. Each card shows how many votes that candidate has so far.
class VoteScreen extends StatefulWidget {
  const VoteScreen({
    super.key,
    required this.election,
    required this.repository,
    required this.showMessage,
  });

  final Election election;
  final ElectionRepository repository;
  final void Function(String) showMessage;

  @override
  State<VoteScreen> createState() => _VoteScreenState();
}

class _VoteScreenState extends State<VoteScreen> {
  final nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _voteFor(Candidate candidate) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await widget.repository.castVote(
      widget.election,
      candidate,
      nameController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    nameController.clear();
    widget.showMessage('Vote counted for ${candidate.name}');
  }

  @override
  Widget build(BuildContext context) {
    final election = widget.election;
    return Column(
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
        if (_busy) const LinearProgressIndicator(),
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
                          onPressed: _busy ? null : () => _voteFor(candidate),
                          child: const Text('Vote'),
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
