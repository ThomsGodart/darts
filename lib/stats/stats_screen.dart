import 'package:flutter/material.dart';

import '../session/session.dart';
import '../session_launcher.dart';
import '../settings/app_settings.dart';
import '../theme/darts_space.dart';
import '../ui/game_labels.dart';
import 'stat_lines.dart';

/// How far back the stats look.
enum StatsPeriod {
  all('Global', null),
  day('24 h', Duration(hours: 24)),
  week('7 j', Duration(days: 7)),
  month('30 j', Duration(days: 30));

  const StatsPeriod(this.label, this.length);

  final String label;

  /// Null for everything ever played.
  final Duration? length;
}

/// Everyone's stats over one kind of game at a time, side by side: the
/// game, how far back, and who is shown are the players' choice.
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.launcher,
    required this.settings,
    this.now = DateTime.now,
  });

  final SessionLauncher launcher;

  /// Remembers who the players left out.
  final AppSettings settings;

  /// What time it is, for the periods.
  final DateTime Function() now;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Future<List<PlayedGame>> _games = widget.launcher.playedGames();

  /// The game shown; the first one played until the players pick.
  GameKind? _kind;
  StatsPeriod _period = StatsPeriod.all;
  Participation _participation = Participation.any;

  /// X01 only: null for every start score.
  int? _startScore;

  /// Cricket only: the first variant played until the players pick.
  CricketVariant? _variant;

  /// Everyone with a part in [games], in the order they first played,
  /// under their latest name.
  List<Player> _peopleOf(List<PlayedGame> games) {
    final byId = <String, Player>{
      for (final played in games)
        for (final person in peopleOf(played.game.players)) person.id: person,
    };
    return byId.values.toList();
  }

  Future<void> _choosePlayers(List<Player> people) async {
    final hidden = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _PlayersDialog(
        people: people,
        hidden: widget.settings.statsHiddenPlayers,
      ),
    );
    if (hidden == null) return;
    await widget.settings.setStatsHiddenPlayers(hidden);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _games,
      builder: (context, snapshot) {
        final games = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Statistiques'),
            actions: [
              if (games != null && games.isNotEmpty)
                IconButton(
                  key: const Key('stats-players'),
                  tooltip: 'Choisir les joueurs',
                  icon: const Icon(Icons.group_outlined),
                  onPressed: () => _choosePlayers(_peopleOf(games)),
                ),
            ],
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true) => const Center(
              child: Text(
                'Impossible de charger les statistiques.',
                key: Key('stats-load-error'),
                textAlign: TextAlign.center,
              ),
            ),
            _ when games == null => const Center(
              child: CircularProgressIndicator(),
            ),
            _ when games.isEmpty => const Center(
              child: Text('Aucune partie jouée pour l’instant'),
            ),
            _ => ListenableBuilder(
              listenable: widget.settings,
              builder: (context, _) => _body(context, games),
            ),
          },
        );
      },
    );
  }

  Widget _body(BuildContext context, List<PlayedGame> games) {
    final kinds = kindsPlayed(games);
    final kind = kinds.contains(_kind) ? _kind! : kinds.first;
    final ofKind = [
      for (final played in games)
        if (played.game.config.kind == kind) played,
    ];
    final startScores = {
      for (final played in ofKind)
        if (played.game.config case X01Config(:final startScore)) startScore,
    }.toList()..sort();
    final variants = [
      for (final variant in CricketVariant.values)
        if (ofKind.any(
          (p) =>
              p.game.config is CricketConfig &&
              (p.game.config as CricketConfig).variant == variant,
        ))
          variant,
    ];
    // Points do not mean the same in the two variants: never mixed.
    final variant = variants.contains(_variant)
        ? _variant
        : variants.firstOrNull;
    final hidden = widget.settings.statsHiddenPlayers;
    final stats = [
      for (final s in statsOf(
        games,
        StatsQuery(
          kind: kind,
          since: switch (_period.length) {
            null => null,
            final length => widget.now().subtract(length),
          },
          participation: _participation,
          startScore: startScores.contains(_startScore) ? _startScore : null,
          variant: variant,
        ),
      ))
        if (!hidden.contains(s.player.id)) s,
    ]..sort((a, b) => b.gamesPlayed.compareTo(a.gamesPlayed));

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: DartsSpace.sm),
      children: [
        _ChipRow(
          key: const Key('stats-kinds'),
          children: [
            for (final k in kinds)
              ChoiceChip(
                label: Text(kindLabel(k)),
                selected: k == kind,
                onSelected: (_) => setState(() => _kind = k),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DartsSpace.lg,
            vertical: DartsSpace.xs,
          ),
          child: SegmentedButton<StatsPeriod>(
            key: const Key('stats-period'),
            segments: [
              for (final period in StatsPeriod.values)
                ButtonSegment(value: period, label: Text(period.label)),
            ],
            selected: {_period},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _period = s.single),
          ),
        ),
        if (hasTeamGames(ofKind))
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DartsSpace.lg,
              vertical: DartsSpace.xs,
            ),
            child: SegmentedButton<Participation>(
              key: const Key('stats-participation'),
              segments: const [
                ButtonSegment(value: Participation.any, label: Text('Toutes')),
                ButtonSegment(value: Participation.solo, label: Text('Solo')),
                ButtonSegment(
                  value: Participation.team,
                  label: Text('En équipe'),
                ),
              ],
              selected: {_participation},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  setState(() => _participation = s.single),
            ),
          ),
        if (startScores.length > 1)
          _ChipRow(
            key: const Key('stats-start-scores'),
            children: [
              ChoiceChip(
                label: const Text('Tous'),
                selected: !startScores.contains(_startScore),
                onSelected: (_) => setState(() => _startScore = null),
              ),
              for (final score in startScores)
                ChoiceChip(
                  label: Text('$score'),
                  selected: score == _startScore,
                  onSelected: (_) => setState(() => _startScore = score),
                ),
            ],
          ),
        if (variants.length > 1)
          _ChipRow(
            key: const Key('stats-variants'),
            children: [
              for (final v in variants)
                ChoiceChip(
                  label: Text(variantLabel(v)),
                  selected: v == variant,
                  onSelected: (_) => setState(() => _variant = v),
                ),
            ],
          ),
        const SizedBox(height: DartsSpace.sm),
        if (stats.isEmpty)
          const Padding(
            padding: EdgeInsets.all(DartsSpace.xl),
            child: Text(
              'Aucune partie pour ce choix',
              key: Key('stats-empty'),
              textAlign: TextAlign.center,
            ),
          )
        else
          _StatsTable(stats: stats),
      ],
    );
  }
}

/// A row of chips that scrolls sideways rather than wrapping.
class _ChipRow extends StatelessWidget {
  const _ChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(
      horizontal: DartsSpace.lg,
      vertical: DartsSpace.xs,
    ),
    child: Row(
      children: [
        for (final child in children)
          Padding(
            padding: const EdgeInsets.only(right: DartsSpace.sm),
            child: child,
          ),
      ],
    ),
  );
}

/// The stats in rows, the players in columns. What each row counts stays
/// in place while the players scroll sideways when they do not all fit.
class _StatsTable extends StatelessWidget {
  const _StatsTable({required this.stats});

  final List<GameStats> stats;

  static const _rowHeight = 44.0;
  static const _labelWidth = 150.0;
  static const _playerWidth = 92.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final lines = statLines(stats);
    Widget cell(String text, {TextStyle? style, bool end = true}) => SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: end
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: style,
        ),
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: DartsSpace.lg),
          child: SizedBox(
            width: _labelWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: _rowHeight),
                for (final (label, _) in lines)
                  cell(
                    label,
                    end: false,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            key: const Key('stats-table'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(right: DartsSpace.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, s) in stats.indexed)
                  SizedBox(
                    width: _playerWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cell(s.player.name, style: textTheme.titleSmall),
                        for (final (_, values) in lines)
                          cell(values[i], style: textTheme.titleMedium),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Who the stats show, a box per player; pops the ids left out, or null
/// when dismissed.
class _PlayersDialog extends StatefulWidget {
  const _PlayersDialog({required this.people, required this.hidden});

  final List<Player> people;
  final Set<String> hidden;

  @override
  State<_PlayersDialog> createState() => _PlayersDialogState();
}

class _PlayersDialogState extends State<_PlayersDialog> {
  late final Set<String> _hidden = {...widget.hidden};

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const Key('stats-players-dialog'),
    title: const Text('Joueurs affichés'),
    contentPadding: const EdgeInsets.symmetric(vertical: DartsSpace.sm),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final person in widget.people)
            CheckboxListTile(
              title: Text(person.name),
              value: !_hidden.contains(person.id),
              onChanged: (shown) => setState(
                () => shown ?? false
                    ? _hidden.remove(person.id)
                    : _hidden.add(person.id),
              ),
            ),
        ],
      ),
    ),
    actions: [
      // Everyone shown already: the one tap left is to clear them all.
      if (_hidden.isEmpty)
        TextButton(
          onPressed: () => setState(
            () => _hidden.addAll([for (final p in widget.people) p.id]),
          ),
          child: const Text('Tout décocher'),
        )
      else
        TextButton(
          onPressed: () => setState(_hidden.clear),
          child: const Text('Tout cocher'),
        ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_hidden),
        child: const Text('Valider'),
      ),
    ],
  );
}
