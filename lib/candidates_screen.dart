import 'package:flutter/material.dart';

import 'election.dart';
import 'election_repository.dart';
import 'models.dart';

/// The Candidates tab: add a candidate, remove one who has no votes yet, or
/// reset every vote after an "Are you sure?" dialog.
class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({
    super.key,
    required this.election,
    required this.repository,
    required this.showMessage,
  });

  final Election election;
  final ElectionRepository repository;
  final void Function(String) showMessage;

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  final nameController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    final name = widget.election.cleanName(nameController.text);
    setState(() => _busy = true);
    final error = await widget.repository.addCandidate(
      widget.election,
      nameController.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    nameController.clear();
    widget.showMessage('$name added');
  }

  Future<void> _remove(Candidate candidate) async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await widget.repository.removeCandidate(
      widget.election,
      candidate,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${candidate.name} removed'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            final undoError = await widget.repository.undoRemove(candidate);
            if (undoError != null && mounted) {
              widget.showMessage(undoError);
            }
          },
        ),
      ),
    );
  }

  Future<void> _rename(Candidate candidate) async {
    if (_busy) return;
    var draft = candidate.name;
    final rawName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename candidate'),
          content: TextFormField(
            initialValue: candidate.name,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => draft = value,
            onFieldSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, draft),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (rawName == null || !mounted) return;
    final name = widget.election.cleanName(rawName);
    if (name == candidate.name) return;

    setState(() => _busy = true);
    final error = await widget.repository.renameCandidate(
      widget.election,
      candidate,
      rawName,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      widget.showMessage(error);
      return;
    }
    widget.showMessage('${candidate.name} renamed to $name');
  }

  Future<void> _reset() async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await widget.repository.resetVotes(widget.election);
    if (!mounted) return;
    setState(() => _busy = false);
    widget.showMessage(error ?? 'All votes reset');
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
                Navigator.pop(context);
                _reset();
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
    return Column(
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
              FilledButton(
                onPressed: _busy ? null : _add,
                child: const Text('Add'),
              ),
              IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Reset all votes',
                onPressed: _busy ? null : _confirmReset,
              ),
            ],
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
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
                      onTap: _busy ? null : () => _rename(candidate),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Rename ${candidate.name}',
                            onPressed: _busy ? null : () => _rename(candidate),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Remove ${candidate.name}',
                            onPressed: _busy ? null : () => _remove(candidate),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
