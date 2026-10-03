import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import 'setup_controller.dart';

/// Picks who plays, in which order, and the rules; pops a [GameSetup].
/// Whoever creates [controller] disposes it.
class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,
    required this.controller,
    this.title = 'Nouvelle session',
  });

  final SetupController controller;
  final String title;

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
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final problem = await setup.addPlayer(_newName.text);
    if (!mounted) return;
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

  Future<void> _remove(Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Supprimer ${player.name} ?'),
        content: const Text(
          'S’il a déjà joué, il est archivé : ses parties restent lisibles.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) await setup.removePlayer(player);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListenableBuilder(
        listenable: setup,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(DartsSpace.lg),
          children: [
            Text('Joueurs', style: textTheme.titleLarge),
            if (setup.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: DartsSpace.lg),
                child: Center(
                  child: SizedBox(
                    key: Key('setup-catalog-loading'),
                    width: DartsSpace.tap,
                    height: DartsSpace.tap,
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (setup.loadError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DartsSpace.md),
                child: Text(
                  setup.loadError!,
                  key: const Key('setup-catalog-error'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              )
            else if (setup.players.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DartsSpace.md),
                child: Text(
                  'Aucun joueur — ajoutez-en un ci-dessous',
                  key: const Key('setup-catalog-empty'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
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
                        value: () => _remove(player),
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
              const SizedBox(height: DartsSpace.xl),
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
            const SizedBox(height: DartsSpace.xl),
            Text('Partie', style: textTheme.titleLarge),
            const SizedBox(height: DartsSpace.sm),
            Wrap(
              spacing: DartsSpace.sm,
              runSpacing: DartsSpace.sm,
              children: [
                for (final kind in GameKind.values)
                  ChoiceChip(
                    label: Text(switch (kind) {
                      GameKind.x01 => 'X01',
                      GameKind.cricket => 'Cricket',
                      GameKind.shanghai => 'Shanghai',
                      GameKind.killer => 'Killer',
                    }),
                    selected: setup.kind == kind,
                    onSelected: (_) => setup.kind = kind,
                  ),
              ],
            ),
            const SizedBox(height: DartsSpace.sm),
            ...switch (setup.kind) {
              GameKind.x01 => [
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
              GameKind.cricket => [
                SegmentedButton<CricketVariant>(
                  segments: const [
                    ButtonSegment(
                      value: CricketVariant.standard,
                      label: Text('Standard'),
                    ),
                    ButtonSegment(
                      value: CricketVariant.cutThroat,
                      label: Text('Cut-Throat'),
                    ),
                  ],
                  selected: {setup.variant},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.variant = s.single,
                ),
                const SizedBox(height: DartsSpace.sm),
                SegmentedButton<CricketInput>(
                  key: const Key('cricket-input'),
                  segments: const [
                    ButtonSegment(
                      value: CricketInput.board,
                      label: Text('Saisie sur le tableau'),
                    ),
                    ButtonSegment(
                      value: CricketInput.keypad,
                      label: Text('Clavier fléchettes'),
                    ),
                  ],
                  selected: {setup.cricketInput},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.cricketInput = s.single,
                ),
              ],
              GameKind.shanghai => [
                SegmentedButton<ShanghaiLength>(
                  segments: const [
                    ButtonSegment(
                      value: ShanghaiLength.oneToSeven,
                      label: Text('1–7'),
                    ),
                    ButtonSegment(
                      value: ShanghaiLength.fourteenToTwenty,
                      label: Text('14–20'),
                    ),
                    ButtonSegment(
                      value: ShanghaiLength.oneToTwenty,
                      label: Text('1–20'),
                    ),
                  ],
                  selected: {setup.shanghaiLength},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.shanghaiLength = s.single,
                ),
                SwitchListTile(
                  title: const Text('Shanghai instantané'),
                  value: setup.instantShanghai,
                  onChanged: (value) => setup.instantShanghai = value,
                ),
              ],
              GameKind.killer => [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 3, label: Text('3 vies')),
                    ButtonSegment(value: 5, label: Text('5 vies')),
                  ],
                  selected: {setup.killerLives},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.killerLives = s.single,
                ),
                const SizedBox(height: DartsSpace.sm),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1 double')),
                    ButtonSegment(value: 3, label: Text('3 doubles')),
                  ],
                  selected: {setup.doublesToKiller},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.doublesToKiller = s.single,
                ),
                if (setup.picked.length < minKillerPlayers)
                  Padding(
                    padding: const EdgeInsets.only(top: DartsSpace.sm),
                    child: Text(
                      'Killer : au moins $minKillerPlayers joueurs',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
              ],
            },
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DartsSpace.lg),
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
