import '../session/session.dart';

const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "sam. 03/10/2026 · 21:05", in the device's local time.
String sessionDate(DateTime when) {
  final local = when.toLocal();
  return '${_days[local.weekday - 1]} ${_two(local.day)}/${_two(local.month)}/'
      '${local.year} · ${_two(local.hour)}:${_two(local.minute)}';
}

/// Whether a team played in [game].
bool hasTeam(Game game) => game.players.any((side) => side.isTeam);

/// "1 partie", "3 parties".
String gamesCount(int count) => count == 1 ? '1 partie' : '$count parties';
