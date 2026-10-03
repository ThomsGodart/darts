import 'package:flutter/material.dart';

import '../soiree/soiree.dart';
import 'setup_controller.dart';

/// Picks who plays, in which order, and the rules; pops a [GameSetup].
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.controller});

  final SetupController controller;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  SetupController get setup => widget.controller;

  final _newName = TextEditingController();
  String? _newNameError;

  @override
  void initState() {
    super.initState();
    setup.load();
  }

  @override
  void dispose() {
    _newName.dispose();
    setup.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final problem = await setup.addPlayer(_newName.text);
    setState(() => _newNameError = _describe(problem));
    if (problem == null) _newName.clear();
  }

  Future<void> _rename(Player player) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(initial: player.name),
    );
    if (name == null || !mounted) return;
    final problem = await setup.renamePlayer(player, name);
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_describe(problem)!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle soirée')),
      body: ListenableBuilder(
        listenable: setup,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Joueurs', style: textTheme.titleLarge),
            for (final player in setup.players)
              CheckboxListTile(
                value: setup.isPicked(player),
                onChanged: setup.canPick(player)
                    ? (_) => setup.toggle(player)
                    : null,
                title: Text(player.name),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: PopupMenuButton<void Function()>(
                  tooltip: 'Options de ${player.name}',
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: () => _rename(player),
                      child: const Text('Renommer'),
                    ),
                    PopupMenuItem(
                      value: () => setup.removePlayer(player),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _newName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Ajouter un joueur',
                errorText: _newNameError,
                suffixIcon: IconButton(
                  tooltip: 'Ajouter',
                  icon: const Icon(Icons.person_add),
                  onPressed: _addPlayer,
                ),
              ),
              onSubmitted: (_) => _addPlayer(),
            ),
            if (setup.picked.length > 1) ...[
              const SizedBox(height: 24),
              Text('Ordre de jeu', style: textTheme.titleLarge),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorderItem: setup.reorder,
                children: [
                  for (final (i, player) in setup.picked.indexed)
                    ListTile(
                      key: ValueKey(player.id),
                      leading: Text('${i + 1}', style: textTheme.titleMedium),
                      title: Text(player.name),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Text('Partie', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 501, label: Text('501')),
                ButtonSegment(value: 301, label: Text('301')),
              ],
              selected: {setup.startScore},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setup.startScore = s.single,
            ),
            SwitchListTile(
              title: const Text('Double-out'),
              value: setup.doubleOut,
              onChanged: (value) => setup.doubleOut = value,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListenableBuilder(
            listenable: setup,
            builder: (context, _) => FilledButton(
              onPressed: setup.canStart
                  ? () => Navigator.of(context).pop(setup.result)
                  : null,
              child: const Text('Lancer la partie'),
            ),
          ),
        ),
      ),
    );
  }
}

String? _describe(PlayerNameProblem? problem) => switch (problem) {
  null => null,
  PlayerNameProblem.empty => 'Le nom est vide',
  PlayerNameProblem.taken => 'Ce nom est déjà pris',
};

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renommer'),
      content: TextField(
        controller: _name,
        autofocus: true,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_name.text),
          child: const Text('Renommer'),
        ),
      ],
    );
  }
}
