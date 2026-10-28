import 'package:flutter/material.dart';

import 'election.dart';
import 'models.dart';

/// The Candidates tab: add a candidate, remove one who has no votes yet, or
/// reset every vote after an "Are you sure?" dialog.
class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({
    super.key,
    required this.election,
    required this.showMessage,
    required this.refresh,
  });

  final Election election;
  final void Function(String) showMessage;
  final void Function() refresh;

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _add() {
    final error = widget.election.addCandidate(nameController.text);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    final name = widget.election.cleanName(nameController.text);
    nameController.clear();
    widget.refresh();
    widget.showMessage('$name added');
  }

  void _remove(Candidate candidate) {
    final error = widget.election.removeCandidate(candidate);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    widget.refresh();
    widget.showMessage('${candidate.name} removed');
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset all votes?'),
          content: const Text(
            'Every candidate will go back to 0 votes. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                widget.election.resetVotes();
                widget.refresh();
                Navigator.pop(context);
                widget.showMessage('All votes reset');
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final election = widget.election;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidates'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset all votes',
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Add a candidate',
                      hintText: 'e.g.  keza  uwase',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _add(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _add, child: const Text('Add')),
              ],
            ),
          ),
          Expanded(
            child: election.candidates.isEmpty
                ? const Center(child: Text('No candidates yet'))
                : ListView.builder(
                    itemCount: election.candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = election.candidates[index];
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(candidate.name),
                        subtitle: Text('${candidate.votes} votes'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Remove ${candidate.name}',
                          onPressed: () => _remove(candidate),
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
