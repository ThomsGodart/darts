import 'package:flutter/material.dart';

import '../session/session.dart';
import '../theme/darts_space.dart';
import '../ui/game_labels.dart';
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
                  selected: {x01.startScore},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setup.config = x01.copyWith(startScore: s.single),
                ),
                SwitchListTile(
                  title: const Text('Double-out'),
                  value: x01.outRule == OutRule.double,
                  onChanged: (value) => setup.config = x01.copyWith(
                    outRule: value ? OutRule.double : OutRule.straight,
                  ),
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
              HalveItConfig() => [
                Text(
                  'Cibles : ${halveItTargets.map((t) => t.label).join(' · ')}. '
                  'Une volée sans touche divise le score par 2 ; '
                  'le plus de points gagne.',
                  style: textTheme.bodyMedium,
                ),
              ],
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
                const SizedBox(height: DartsSpace.sm),
                Text(
                  'Le trou n est le numéro n. Jusqu’à 3 fléchettes, la '
                  'dernière compte : double 1, triple 2, simple 3, raté '
                  '$golfMissStrokes. Le moins de coups gagne.',
                  style: textTheme.bodyMedium,
                ),
              ],
              AroundTheClockConfig(:final finishOnBull) => [
                Text(
                  'De 1 à 20 dans l’ordre, n’importe quel anneau compte. '
                  'Le premier arrivé gagne.',
                  style: textTheme.bodyMedium,
                ),
                SwitchListTile(
                  title: const Text('Finir par le bull'),
                  value: finishOnBull,
                  onChanged: (value) =>
                      setup.config = AroundTheClockConfig(finishOnBull: value),
                ),
              ],
              Bobs27Config() => [
                Text(
                  'Départ à $bobs27StartScore. Trois fléchettes sur chaque '
                  'double, de D1 à D20 puis le bull : chaque touche ajoute sa '
                  'valeur, une volée sans touche la retire. À zéro ou moins, '
                  'on est éliminé.',
                  style: textTheme.bodyMedium,
                ),
              ],
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
                const SizedBox(height: DartsSpace.sm),
                Text(
                  'Chaque fléchette compte sa valeur ; le plus gros total '
                  'gagne.',
                  style: textTheme.bodyMedium,
                ),
              ],
              BaseballConfig() => [
                Text(
                  '$baseballInnings manches : la manche n se joue sur le '
                  'numéro n. Simple 1 run, double 2, triple 3. En cas '
                  'd’égalité en tête, on joue des prolongations.',
                  style: textTheme.bodyMedium,
                ),
              ],
            },
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
