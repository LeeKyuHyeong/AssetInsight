import 'package:hive/hive.dart';

part 'team.g.dart';

/// 팀 전적
@HiveType(typeId: 3)
class TeamRecord {
  @HiveField(0)
  final int wins;

  @HiveField(1)
  final int losses;

  @HiveField(2)
  final int setWins;

  @HiveField(3)
  final int setLosses;

  @HiveField(4)
  final int proleagueChampionships; // 프로리그 우승

  @HiveField(5)
  final int proleagueRunnerUps; // 프로리그 준우승

  @HiveField(6)
  final int individualChampionships; // 개인리그 우승 (소속 선수)

  @HiveField(7)
  final int individualRunnerUps; // 개인리그 준우승 (소속 선수)

  const TeamRecord({
    this.wins = 0,
    this.losses = 0,
    this.setWins = 0,
    this.setLosses = 0,
    this.proleagueChampionships = 0,
    this.proleagueRunnerUps = 0,
    this.individualChampionships = 0,
    this.individualRunnerUps = 0,
  });

  double get winRate => wins + losses > 0 ? wins / (wins + losses) : 0.0;
  double get setWinRate =>
      setWins + setLosses > 0 ? setWins / (setWins + setLosses) : 0.0;

  TeamRecord addMatchResult({
    required bool isWin,
    required int ourSets,
    required int opponentSets,
  }) {
    return TeamRecord(
      wins: wins + (isWin ? 1 : 0),
      losses: losses + (isWin ? 0 : 1),
      setWins: setWins + ourSets,
      setLosses: setLosses + opponentSets,
      proleagueChampionships: proleagueChampionships,
      proleagueRunnerUps: proleagueRunnerUps,
      individualChampionships: individualChampionships,
      individualRunnerUps: individualRunnerUps,
    );
  }

  TeamRecord addProleagueChampionship() {
    return TeamRecord(
      wins: wins,
      losses: losses,
      setWins: setWins,
      setLosses: setLosses,
      proleagueChampionships: proleagueChampionships + 1,
      proleagueRunnerUps: proleagueRunnerUps,
      individualChampionships: individualChampionships,
      individualRunnerUps: individualRunnerUps,
    );
  }

  TeamRecord addProleagueRunnerUp() {
    return TeamRecord(
      wins: wins,
      losses: losses,
      setWins: setWins,
      setLosses: setLosses,
      proleagueChampionships: proleagueChampionships,
      proleagueRunnerUps: proleagueRunnerUps + 1,
      individualChampionships: individualChampionships,
      individualRunnerUps: individualRunnerUps,
    );
  }
}

/// 팀 모델
@HiveType(typeId: 4)
class Team {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String shortName; // 약칭

  @HiveField(3)
  final int colorValue; // 팀 색상 (Color.value)

  @HiveField(4)
  final List<String> playerIds; // 소속 선수 ID 목록

  @HiveField(5)
  final String? acePlayerId; // 에이스 선수 ID

  @HiveField(6)
  final int money; // 보유 자금 (만원)

  @HiveField(7)
  final int actionPoints; // 행동력

  @HiveField(8)
  final TeamRecord record;

  @HiveField(9)
  final TeamRecord seasonRecord; // 이번 시즌 전적

  @HiveField(10)
  final bool isPlayerTeam; // 플레이어가 운영하는 팀인지

  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.colorValue,
    this.playerIds = const [],
    this.acePlayerId,
    this.money = 0,
    this.actionPoints = 0,
    this.record = const TeamRecord(),
    this.seasonRecord = const TeamRecord(),
    this.isPlayerTeam = false,
  });

  int get playerCount => playerIds.length;
  bool get hasMinimumRoster => playerCount >= 10;

  /// 자금 추가
  Team addMoney(int amount) {
    return copyWith(money: money + amount);
  }

  /// 자금 감소
  Team spendMoney(int amount) {
    return copyWith(money: (money - amount).clamp(0, double.maxFinite.toInt()));
  }

  /// 행동력 추가
  Team addActionPoints(int amount) {
    return copyWith(actionPoints: actionPoints + amount);
  }

  /// 행동력 소모
  Team spendActionPoints(int amount) {
    return copyWith(actionPoints: (actionPoints - amount).clamp(0, double.maxFinite.toInt()));
  }

  /// 선수 추가
  Team addPlayer(String playerId) {
    if (playerIds.contains(playerId)) return this;
    return copyWith(playerIds: [...playerIds, playerId]);
  }

  /// 선수 제거
  Team removePlayer(String playerId) {
    return copyWith(
      playerIds: playerIds.where((id) => id != playerId).toList(),
      acePlayerId: acePlayerId == playerId ? null : acePlayerId,
    );
  }

  /// 에이스 지정
  Team setAcePlayer(String playerId) {
    if (!playerIds.contains(playerId)) return this;
    return copyWith(acePlayerId: playerId);
  }

  /// 매치 결과 적용
  Team applyMatchResult({
    required bool isWin,
    required int ourSets,
    required int opponentSets,
  }) {
    return copyWith(
      record: record.addMatchResult(
        isWin: isWin,
        ourSets: ourSets,
        opponentSets: opponentSets,
      ),
      seasonRecord: seasonRecord.addMatchResult(
        isWin: isWin,
        ourSets: ourSets,
        opponentSets: opponentSets,
      ),
    );
  }

  /// 시즌 시작 시 리셋
  Team resetForNewSeason() {
    return copyWith(
      seasonRecord: const TeamRecord(),
      actionPoints: 0,
    );
  }

  /// 2매치 완료 보너스 (컨디션 +5는 선수별 적용, 행동력 +100)
  Team applyTwoMatchBonus() {
    return copyWith(actionPoints: actionPoints + 100);
  }

  Team copyWith({
    String? id,
    String? name,
    String? shortName,
    int? colorValue,
    List<String>? playerIds,
    String? acePlayerId,
    int? money,
    int? actionPoints,
    TeamRecord? record,
    TeamRecord? seasonRecord,
    bool? isPlayerTeam,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      colorValue: colorValue ?? this.colorValue,
      playerIds: playerIds ?? this.playerIds,
      acePlayerId: acePlayerId ?? this.acePlayerId,
      money: money ?? this.money,
      actionPoints: actionPoints ?? this.actionPoints,
      record: record ?? this.record,
      seasonRecord: seasonRecord ?? this.seasonRecord,
      isPlayerTeam: isPlayerTeam ?? this.isPlayerTeam,
    );
  }
}
