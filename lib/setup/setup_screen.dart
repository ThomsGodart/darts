import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import '../ui/game_labels.dart';
import '../ui/game_rules.dart';
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

  /// Asks for a level, then picks a virtual opponent of that level.
  Future<void> _addBot() async {
    final average = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Niveau de l’adversaire'),
        children: [
          for (final average in botAverages)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(average),
              child: Text('Moyenne $average'),
            ),
        ],
      ),
    );
    if (average == null) return;
    final bot = Player.bot(average);
    if (!setup.isPicked(bot)) setup.toggle(bot);
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
            const SizedBox(height: DartsSpace.sm),
            Wrap(
              spacing: DartsSpace.sm,
              runSpacing: DartsSpace.sm,
              children: [
                for (final bot in setup.picked.where((p) => p.isBot))
                  InputChip(
                    avatar: const Icon(Icons.smart_toy_outlined),
                    label: Text(bot.name),
                    deleteButtonTooltipMessage: 'Retirer ${bot.name}',
                    onDeleted: () => setup.toggle(bot),
                  ),
                ActionChip(
                  key: const Key('add-bot'),
                  avatar: const Icon(Icons.add),
                  label: const Text('Adversaire virtuel'),
                  onPressed: _addBot,
                ),
              ],
            ),
            if (setup.picked.length > 1) ...[
              const SizedBox(height: DartsSpace.xl),
              Text('Ordre de jeu', style: textTheme.titleLarge),
              Text(
                'Faites glisser la poignée, ou maintenez une ligne appuyée, '
                'pour changer l’ordre',
                key: const Key('reorder-hint'),
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // The handle moves a row at once; the rest of the row moves
                // it after a hold, so that sliding over it still scrolls.
                buildDefaultDragHandles: false,
                onReorderItem: setup.reorder,
                children: [
                  for (final (i, player) in setup.picked.indexed)
                    ReorderableDelayedDragStartListener(
                      key: ValueKey(player.id),
                      index: i,
                      child: ListTile(
                        leading: Text('${i + 1}', style: textTheme.titleMedium),
                        title: Text(player.name),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: Tooltip(
                            message: 'Déplacer ${player.name}',
                            child: const SizedBox(
                              width: DartsSpace.tap,
                              height: DartsSpace.tap,
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (setup.picked.length > 1) ...[
              const SizedBox(height: DartsSpace.xl),
              Text('Équipes', style: textTheme.titleLarge),
              const SizedBox(height: DartsSpace.sm),
              SegmentedButton<int>(
                key: const Key('team-count'),
                segments: [
                  const ButtonSegment(value: 0, label: Text('Sans')),
                  for (final count in teamCounts)
                    // No more teams than there are players to fill them.
                    ButtonSegment(
                      value: count,
                      enabled: count <= setup.picked.length,
                      label: Text('$count équipes'),
                    ),
                ],
                selected: {setup.teamCount},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setup.teamCount = s.single,
              ),
              if (setup.teamCount > 0) ...[
                for (final player in setup.picked)
                  ListTile(
                    title: Text(player.name),
                    trailing: SegmentedButton<int>(
                      key: ValueKey('team-of-${player.id}'),
                      segments: [
                        for (var team = 0; team < setup.teamCount; team++)
                          ButtonSegment(
                            value: team,
                            label: Text('${team + 1}'),
                            tooltip: 'Équipe ${team + 1}',
                          ),
                      ],
                      selected: {setup.teamOf(player)},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) => setup.assign(player, s.single),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: DartsSpace.xs),
                  child: Text(
                    [
                      for (final (i, side) in setup.sides.indexed)
                        'Équipe ${i + 1} : ${side.name}',
                    ].join('\n'),
                    key: const Key('teams-summary'),
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
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
                    label: Text(kindLabel(kind)),
                    selected: setup.kind == kind,
                    onSelected: (_) => setup.kind = kind,
                  ),
              ],
            ),
            const SizedBox(height: DartsSpace.sm),
            ...switch (setup.config) {
              final X01Config x01 => [
                SegmentedButton<int>(
                  segments: [
                    for (final score in X01Config.offeredStartScores)
                      ButtonSegment(value: score, label: Text('$score')),
                  ],
                  // A score typed in is none of the offered ones.
                  emptySelectionAllowed: true,
                  selected: {
                    if (X01Config.offeredStartScores.contains(x01.startScore))
                      x01.startScore,
                  },
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    if (s.isEmpty) return;
                    setup.config = x01.copyWith(startScore: s.single);
                  },
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    key: const Key('custom-start-score'),
                    onPressed: () async {
                      final score = await _askStartScore(context);
                      if (score == null) return;
                      setup.config = x01.copyWith(startScore: score);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      X01Config.offeredStartScores.contains(x01.startScore)
                          ? 'Autre score…'
                          : 'Score de départ : ${x01.startScore}',
                    ),
                  ),
                ),
                SegmentedButton<OutRule>(
                  key: const Key('out-rule'),
                  segments: [
                    for (final rule in OutRule.values)
                      ButtonSegment(
                        value: rule,
                        label: Text(outRuleLabel(rule)),
                      ),
                  ],
                  selected: {x01.outRule},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setup.config = x01.copyWith(outRule: s.single),
                ),
                SwitchListTile(
                  title: const Text('Double-in'),
                  subtitle: const Text(
                    'Rien ne compte avant le premier double',
                  ),
                  value: x01.doubleIn,
                  onChanged: (value) =>
                      setup.config = x01.copyWith(doubleIn: value),
                ),
                SwitchListTile(
                  title: const Text('Pourcentage de checkout'),
                  subtitle: const Text(
                    'Demande les fléchettes tirées sur un double',
                  ),
                  value: x01.trackDoubles,
                  onChanged: (value) =>
                      setup.config = x01.copyWith(trackDoubles: value),
                ),
                SegmentedButton<int>(
                  key: const Key('legs-to-win'),
                  segments: [
                    for (final legs in X01Config.offeredLegsToWin)
                      ButtonSegment(
                        value: legs,
                        label: Text(legs == 1 ? '1 manche' : '1er à $legs'),
                      ),
                  ],
                  selected: {x01.legsToWin},
                  showSelectedIcon: false,
                  // A single leg is not played in sets.
                  onSelectionChanged: (s) => setup.config = x01.copyWith(
                    legsToWin: s.single,
                    setsToWin: s.single == 1 ? 1 : null,
                  ),
                ),
                if (x01.legsToWin > 1) ...[
                  const SizedBox(height: DartsSpace.sm),
                  SegmentedButton<int>(
                    key: const Key('sets-to-win'),
                    segments: [
                      for (final sets in X01Config.offeredSetsToWin)
                        ButtonSegment(
                          value: sets,
                          label: Text(sets == 1 ? 'Sans sets' : '$sets sets'),
                        ),
                    ],
                    selected: {x01.setsToWin},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) =>
                        setup.config = x01.copyWith(setsToWin: s.single),
                  ),
                ],
              ],
              CricketConfig(:final variant, :final input) => [
                SegmentedButton<CricketVariant>(
                  segments: [
                    for (final variant in CricketVariant.values)
                      ButtonSegment(
                        value: variant,
                        label: Text(switch (variant) {
                          CricketVariant.standard => 'Standard',
                          CricketVariant.cutThroat => 'Cut-Throat',
                        }),
                      ),
                  ],
                  selected: {variant},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.config = CricketConfig(
                    variant: s.single,
                    input: input,
                  ),
                ),
                const SizedBox(height: DartsSpace.sm),
                SegmentedButton<CricketInput>(
                  key: const Key('cricket-input'),
                  segments: [
                    for (final input in CricketInput.values)
                      ButtonSegment(
                        value: input,
                        label: Text(switch (input) {
                          CricketInput.board => 'Saisie sur le tableau',
                          CricketInput.keypad => 'Clavier fléchettes',
                        }),
                      ),
                  ],
                  selected: {input},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.config = CricketConfig(
                    variant: variant,
                    input: s.single,
                  ),
                ),
              ],
              ShanghaiConfig(:final length, :final instantShanghai) => [
                SegmentedButton<ShanghaiLength>(
                  segments: [
                    for (final length in ShanghaiLength.values)
                      ButtonSegment(
                        value: length,
                        label: Text(switch (length) {
                          ShanghaiLength.oneToSeven => '1–7',
                          ShanghaiLength.fourteenToTwenty => '14–20',
                          ShanghaiLength.oneToTwenty => '1–20',
                        }),
                      ),
                  ],
                  selected: {length},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.config = ShanghaiConfig(
                    length: s.single,
                    instantShanghai: instantShanghai,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Shanghai instantané'),
                  value: instantShanghai,
                  onChanged: (value) => setup.config = ShanghaiConfig(
                    length: length,
                    instantShanghai: value,
                  ),
                ),
              ],
              KillerConfig(:final lives, :final doublesToKiller) => [
                SegmentedButton<int>(
                  segments: [
                    for (final lives in KillerConfig.livesOptions)
                      ButtonSegment(value: lives, label: Text('$lives vies')),
                  ],
                  selected: {lives},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.config = KillerConfig(
                    lives: s.single,
                    doublesToKiller: doublesToKiller,
                  ),
                ),
                const SizedBox(height: DartsSpace.sm),
                SegmentedButton<int>(
                  segments: [
                    for (final doubles in KillerConfig.doublesToKillerOptions)
                      ButtonSegment(
                        value: doubles,
                        label: Text(
                          doubles == 1 ? '1 double' : '$doubles doubles',
                        ),
                      ),
                  ],
                  selected: {doublesToKiller},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setup.config = KillerConfig(
                    lives: lives,
                    doublesToKiller: s.single,
                  ),
                ),
              ],
              HalveItConfig() => [],
              GolfConfig(:final holes) => [
                SegmentedButton<int>(
                  segments: [
                    for (final holes in GolfConfig.holesOptions)
                      ButtonSegment(value: holes, label: Text('$holes trous')),
                  ],
                  selected: {holes},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setup.config = GolfConfig(holes: s.single),
                ),
              ],
              AroundTheClockConfig(:final finishOnBull) => [
                SwitchListTile(
                  title: const Text('Finir par le bull'),
                  value: finishOnBull,
                  onChanged: (value) =>
                      setup.config = AroundTheClockConfig(finishOnBull: value),
                ),
              ],
              Bobs27Config() => [],
              CountUpConfig(:final rounds) => [
                SegmentedButton<int>(
                  segments: [
                    for (final rounds in CountUpConfig.roundsOptions)
                      ButtonSegment(
                        value: rounds,
                        label: Text('$rounds manches'),
                      ),
                  ],
                  selected: {rounds},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setup.config = CountUpConfig(rounds: s.single),
                ),
              ],
              BaseballConfig() => [],
            },
            if (setup.problem case final problem?)
              Padding(
                padding: const EdgeInsets.only(top: DartsSpace.sm),
                child: Text(
                  switch (problem) {
                    SetupProblem.emptyTeam =>
                      'Chaque équipe doit avoir au moins un joueur',
                    SetupProblem.botInTeam =>
                      'L’adversaire virtuel joue seul, sans coéquipier',
                    SetupProblem.botCannotPlay =>
                      'L’adversaire virtuel ne joue qu’au X01 et au Count-Up',
                  },
                  key: const Key('setup-problem'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            if (setup.config.minPlayers > 1 &&
                setup.picked.length < setup.config.minPlayers)
              Padding(
                padding: const EdgeInsets.only(top: DartsSpace.sm),
                child: Text(
                  '${kindLabel(setup.kind)} : au moins '
                  '${setup.config.minPlayers} joueurs',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DartsSpace.lg),
          child: ListenableBuilder(
            listenable: setup,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  key: const Key('rules-button'),
                  onPressed: () => _showRules(context, setup.config),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Règles'),
                ),
                FilledButton(
                  onPressed: setup.canStart
                      ? () => Navigator.of(context).pop(setup.result)
                      : null,
                  child: const Text('Lancer la partie'),
                ),
              ],
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

/// Asks for an X01 start score; null if dismissed or not a score.
Future<int?> _askStartScore(BuildContext context) async {
  final typed = await showDialog<String>(
    context: context,
    builder: (context) {
      var text = '';
      return AlertDialog(
        title: const Text('Score de départ'),
        content: TextField(
          key: const Key('start-score-field'),
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Par exemple 1001'),
          onChanged: (value) => text = value,
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(text),
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
  final score = int.tryParse(typed?.trim() ?? '');
  if (score == null || !X01Config(startScore: score).isValid) return null;
  // Past this the scoreboard and the stats stop making sense.
  return score > 9999 ? null : score;
}

/// The levels a virtual opponent is offered at: three-dart averages.
const botAverages = [30, 40, 50, 60, 70, 80, 90];

/// How many teams a game can be asked to be played in.
const teamCounts = [2, 3, 4];

/// Spells out the rules of the game about to start, as set up.
Future<void> _showRules(BuildContext context, GameConfig config) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('rules-dialog'),
      title: Text('Règles · ${configLabel(config)}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final rule in gameRules(config))
              Padding(
                padding: const EdgeInsets.only(bottom: DartsSpace.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(rule)),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compris'),
        ),
      ],
    ),
  );
}
