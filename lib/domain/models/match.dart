import 'package:hive/hive.dart';
import 'enums.dart';

part 'match.g.dart';

/// 개별 세트 결과
@HiveType(typeId: 11)
class SetResult {
  @HiveField(0)
  final String mapId;

  @HiveField(1)
  final String homePlayerId;

  @HiveField(2)
  final String awayPlayerId;

  @HiveField(3)
  final bool homeWin;

  @HiveField(4)
  final List<String> battleLog; // 전투 텍스트 로그

  @HiveField(5)
  final int finalHomeArmy; // 최종 병력

  @HiveField(6)
  final int finalAwayArmy;

  @HiveField(7)
  final int finalHomeResources; // 최종 자원

  @HiveField(8)
  final int finalAwayResources;

  const SetResult({
    required this.mapId,
    required this.homePlayerId,
    required this.awayPlayerId,
    required this.homeWin,
    this.battleLog = const [],
    this.finalHomeArmy = 0,
    this.finalAwayArmy = 0,
    this.finalHomeResources = 0,
    this.finalAwayResources = 0,
  });

  String get winnerId => homeWin ? homePlayerId : awayPlayerId;
  String get loserId => homeWin ? awayPlayerId : homePlayerId;
}

/// 매치 결과 (7전 4선승)
@HiveType(typeId: 12)
class MatchResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String homeTeamId;

  @HiveField(2)
  final String awayTeamId;

  @HiveField(3)
  final List<SetResult> sets;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final int seasonNumber;

  @HiveField(6)
  final int roundNumber;

  const MatchResult({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    this.sets = const [],
    this.isCompleted = false,
    this.seasonNumber = 1,
    this.roundNumber = 1,
  });

  int get homeScore => sets.where((s) => s.homeWin).length;
  int get awayScore => sets.where((s) => !s.homeWin).length;

  bool get isHomeWin => homeScore >= 4;
  bool get isAwayWin => awayScore >= 4;
  String? get winnerTeamId => isHomeWin ? homeTeamId : (isAwayWin ? awayTeamId : null);

  bool get isAceMatch => homeScore == 3 && awayScore == 3;

  MatchResult addSet(SetResult setResult) {
    final newSets = [...sets, setResult];
    final newHomeScore = newSets.where((s) => s.homeWin).length;
    final newAwayScore = newSets.where((s) => !s.homeWin).length;

    return MatchResult(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      sets: newSets,
      isCompleted: newHomeScore >= 4 || newAwayScore >= 4,
      seasonNumber: seasonNumber,
      roundNumber: roundNumber,
    );
  }
}

/// 프로리그 일정 항목
@HiveType(typeId: 13)
class ScheduleItem {
  @HiveField(0)
  final String matchId;

  @HiveField(1)
  final String homeTeamId;

  @HiveField(2)
  final String awayTeamId;

  @HiveField(3)
  final int roundNumber;

  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final MatchResult? result;

  const ScheduleItem({
    required this.matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.roundNumber,
    this.isCompleted = false,
    this.result,
  });

  ScheduleItem complete(MatchResult result) {
    return ScheduleItem(
      matchId: matchId,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      roundNumber: roundNumber,
      isCompleted: true,
      result: result,
    );
  }
}

/// 개인리그 매치 결과 (단일 경기)
@HiveType(typeId: 14)
class IndividualMatchResult {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String player1Id;

  @HiveField(2)
  final String player2Id;

  @HiveField(3)
  final String winnerId;

  @HiveField(4)
  final String mapId;

  @HiveField(5)
  final int stageIndex; // IndividualLeagueStage enum index

  @HiveField(6)
  final List<String> battleLog;

  @HiveField(7)
  final bool showBattleLog; // 8강 이후만 true

  const IndividualMatchResult({
    required this.id,
    required this.player1Id,
    required this.player2Id,
    required this.winnerId,
    required this.mapId,
    required this.stageIndex,
    this.battleLog = const [],
    this.showBattleLog = false,
  });

  IndividualLeagueStage get stage => IndividualLeagueStage.values[stageIndex];
  String get loserId => winnerId == player1Id ? player2Id : player1Id;
}

/// 개인리그 대진표
@HiveType(typeId: 15)
class IndividualLeagueBracket {
  @HiveField(0)
  final int seasonNumber;

  @HiveField(1)
  final List<List<String>> pcBangGroups; // 24개 조, 각 조 4명

  @HiveField(2)
  final List<IndividualMatchResult> pcBangResults;

  @HiveField(3)
  final List<String> dualTournamentPlayers; // 듀얼토너먼트 진출자 (시드 순서대로)

  @HiveField(4)
  final List<IndividualMatchResult> dualTournamentResults;

  @HiveField(5)
  final List<String> mainTournamentPlayers; // 32강 진출자 (시드 순서대로)

  @HiveField(6)
  final List<IndividualMatchResult> mainTournamentResults;

  @HiveField(7)
  final String? championId;

  @HiveField(8)
  final String? runnerUpId;

  @HiveField(9)
  final List<String> dualTournamentSeeds; // 듀얼토너먼트 시드 선수 (이전 시즌 32강 진출자)

  @HiveField(10)
  final List<String> mainTournamentSeeds; // 본선 시드 선수 (이전 시즌 8강 진출자)

  @HiveField(11)
  final List<String> top8Players; // 8강 진출자 (다음 시즌 조지명식 직행)

  @HiveField(12)
  final List<List<String?>> dualTournamentGroups; // 듀얼토너먼트 12개 조 (각 조 4명)

  @HiveField(13)
  final List<List<String?>> mainTournamentGroups; // 본선 8개 조 (각 조 4명)

  const IndividualLeagueBracket({
    required this.seasonNumber,
    this.pcBangGroups = const [],
    this.pcBangResults = const [],
    this.dualTournamentPlayers = const [],
    this.dualTournamentResults = const [],
    this.mainTournamentPlayers = const [],
    this.mainTournamentResults = const [],
    this.championId,
    this.runnerUpId,
    this.dualTournamentSeeds = const [],
    this.mainTournamentSeeds = const [],
    this.top8Players = const [],
    this.dualTournamentGroups = const [],
    this.mainTournamentGroups = const [],
  });

  bool get isCompleted => championId != null;

  IndividualLeagueBracket copyWith({
    int? seasonNumber,
    List<List<String>>? pcBangGroups,
    List<IndividualMatchResult>? pcBangResults,
    List<String>? dualTournamentPlayers,
    List<IndividualMatchResult>? dualTournamentResults,
    List<String>? mainTournamentPlayers,
    List<IndividualMatchResult>? mainTournamentResults,
    String? championId,
    String? runnerUpId,
    List<String>? dualTournamentSeeds,
    List<String>? mainTournamentSeeds,
    List<String>? top8Players,
    List<List<String?>>? dualTournamentGroups,
    List<List<String?>>? mainTournamentGroups,
  }) {
    return IndividualLeagueBracket(
      seasonNumber: seasonNumber ?? this.seasonNumber,
      pcBangGroups: pcBangGroups ?? this.pcBangGroups,
      pcBangResults: pcBangResults ?? this.pcBangResults,
      dualTournamentPlayers: dualTournamentPlayers ?? this.dualTournamentPlayers,
      dualTournamentResults: dualTournamentResults ?? this.dualTournamentResults,
      mainTournamentPlayers: mainTournamentPlayers ?? this.mainTournamentPlayers,
      mainTournamentResults: mainTournamentResults ?? this.mainTournamentResults,
      championId: championId ?? this.championId,
      runnerUpId: runnerUpId ?? this.runnerUpId,
      dualTournamentSeeds: dualTournamentSeeds ?? this.dualTournamentSeeds,
      mainTournamentSeeds: mainTournamentSeeds ?? this.mainTournamentSeeds,
      top8Players: top8Players ?? this.top8Players,
      dualTournamentGroups: dualTournamentGroups ?? this.dualTournamentGroups,
      mainTournamentGroups: mainTournamentGroups ?? this.mainTournamentGroups,
    );
  }
}

/// 로스터 편성 (경기 출전 선수 배치)
@HiveType(typeId: 16)
class RosterSelection {
  @HiveField(0)
  final String teamId;

  @HiveField(1)
  final List<String?> mapPlayerIds; // 인덱스 = 세트 번호 (0-5), 값 = 선수 ID

  @HiveField(2)
  final String? acePlayerId; // 7세트 에이스 카드

  @HiveField(3)
  final Map<int, List<String>> mapItemIds; // 세트 번호 -> 사용할 아이템 ID 목록

  const RosterSelection({
    required this.teamId,
    this.mapPlayerIds = const [null, null, null, null, null, null],
    this.acePlayerId,
    this.mapItemIds = const {},
  });

  bool get isValid {
    // 중복 선수 체크
    final usedPlayers = mapPlayerIds.whereType<String>().toSet();
    if (usedPlayers.length != mapPlayerIds.whereType<String>().length) {
      return false;
    }

    // 에이스가 1~6세트에 이미 출전했는지 체크
    if (acePlayerId != null && mapPlayerIds.contains(acePlayerId)) {
      return false;
    }

    // 최소 4명 선택 체크
    if (mapPlayerIds.whereType<String>().length < 4) {
      return false;
    }

    return true;
  }

  RosterSelection setPlayer(int setIndex, String? playerId) {
    if (setIndex < 0 || setIndex > 5) return this;

    final newMapPlayerIds = List<String?>.from(mapPlayerIds);
    newMapPlayerIds[setIndex] = playerId;

    return RosterSelection(
      teamId: teamId,
      mapPlayerIds: newMapPlayerIds,
      acePlayerId: acePlayerId,
      mapItemIds: mapItemIds,
    );
  }

  RosterSelection setAcePlayer(String? playerId) {
    return RosterSelection(
      teamId: teamId,
      mapPlayerIds: mapPlayerIds,
      acePlayerId: playerId,
      mapItemIds: mapItemIds,
    );
  }

  RosterSelection setItems(int setIndex, List<String> itemIds) {
    final newMapItemIds = Map<int, List<String>>.from(mapItemIds);
    newMapItemIds[setIndex] = itemIds;

    return RosterSelection(
      teamId: teamId,
      mapPlayerIds: mapPlayerIds,
      acePlayerId: acePlayerId,
      mapItemIds: newMapItemIds,
    );
  }
}
