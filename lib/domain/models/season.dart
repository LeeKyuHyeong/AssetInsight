import 'package:hive/hive.dart';
import 'match.dart';
import 'enums.dart';

part 'season.g.dart';

/// 시즌 정보
@HiveType(typeId: 17)
class Season {
  @HiveField(0)
  final int number; // 시즌 번호

  @HiveField(1)
  final List<String> seasonMapIds; // 시즌맵 ID 목록 (12개 중 랜덤 선정)

  @HiveField(2)
  final List<ScheduleItem> proleagueSchedule; // 프로리그 일정

  @HiveField(3)
  final int currentMatchIndex; // 현재 경기 인덱스

  @HiveField(4)
  final int matchesSinceLastBonus; // 마지막 보너스(행동력+100) 후 경기 수

  @HiveField(5)
  final IndividualLeagueBracket? individualLeague;

  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final String? proleagueChampionId; // 프로리그 우승팀 ID

  @HiveField(8)
  final String? proleagueRunnerUpId; // 프로리그 준우승팀 ID

  @HiveField(9)
  final int phaseIndex; // SeasonPhase enum index

  @HiveField(10)
  final PlayoffBracket? playoff; // 플레이오프 대진표

  const Season({
    required this.number,
    this.seasonMapIds = const [],
    this.proleagueSchedule = const [],
    this.currentMatchIndex = 0,
    this.matchesSinceLastBonus = 0,
    this.individualLeague,
    this.isCompleted = false,
    this.proleagueChampionId,
    this.proleagueRunnerUpId,
    this.phaseIndex = 0,
    this.playoff,
  });

  SeasonPhase get phase => SeasonPhase.values[phaseIndex];

  ScheduleItem? get currentMatch =>
      currentMatchIndex < proleagueSchedule.length
          ? proleagueSchedule[currentMatchIndex]
          : null;

  bool get hasNextMatch => currentMatchIndex < proleagueSchedule.length;

  /// 다음 경기로 이동
  Season advanceMatch() {
    final newMatchesSinceLastBonus = matchesSinceLastBonus + 1;
    final giveBonus = newMatchesSinceLastBonus >= 2;

    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: proleagueSchedule,
      currentMatchIndex: currentMatchIndex + 1,
      matchesSinceLastBonus: giveBonus ? 0 : newMatchesSinceLastBonus,
      individualLeague: individualLeague,
      isCompleted: isCompleted,
      proleagueChampionId: proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId,
      phaseIndex: phaseIndex,
      playoff: playoff,
    );
  }

  /// 2경기 완료 보너스 필요 여부
  bool get shouldGiveBonus => matchesSinceLastBonus >= 2;

  /// 경기 결과 업데이트
  Season updateMatchResult(int matchIndex, MatchResult result) {
    final newSchedule = List<ScheduleItem>.from(proleagueSchedule);
    newSchedule[matchIndex] = newSchedule[matchIndex].complete(result);

    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: newSchedule,
      currentMatchIndex: currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus,
      individualLeague: individualLeague,
      isCompleted: isCompleted,
      proleagueChampionId: proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId,
      phaseIndex: phaseIndex,
      playoff: playoff,
    );
  }

  /// 개인리그 업데이트
  Season updateIndividualLeague(IndividualLeagueBracket bracket) {
    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: proleagueSchedule,
      currentMatchIndex: currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus,
      individualLeague: bracket,
      isCompleted: isCompleted,
      proleagueChampionId: proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId,
      phaseIndex: phaseIndex,
      playoff: playoff,
    );
  }

  /// 시즌 완료
  Season complete({String? championId, String? runnerUpId}) {
    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: proleagueSchedule,
      currentMatchIndex: currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus,
      individualLeague: individualLeague,
      isCompleted: true,
      proleagueChampionId: championId,
      proleagueRunnerUpId: runnerUpId,
      phaseIndex: SeasonPhase.seasonEnd.index,
      playoff: playoff,
    );
  }

  /// 시즌 단계 변경
  Season updatePhase(SeasonPhase newPhase) {
    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: proleagueSchedule,
      currentMatchIndex: currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus,
      individualLeague: individualLeague,
      isCompleted: isCompleted,
      proleagueChampionId: proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId,
      phaseIndex: newPhase.index,
      playoff: playoff,
    );
  }

  /// 플레이오프 업데이트
  Season updatePlayoff(PlayoffBracket newPlayoff) {
    return Season(
      number: number,
      seasonMapIds: seasonMapIds,
      proleagueSchedule: proleagueSchedule,
      currentMatchIndex: currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus,
      individualLeague: individualLeague,
      isCompleted: isCompleted,
      proleagueChampionId: proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId,
      phaseIndex: phaseIndex,
      playoff: newPlayoff,
    );
  }

  /// 정규 시즌 완료 여부
  bool get isRegularSeasonCompleted => !hasNextMatch;

  /// copyWith
  Season copyWith({
    int? number,
    List<String>? seasonMapIds,
    List<ScheduleItem>? proleagueSchedule,
    int? currentMatchIndex,
    int? matchesSinceLastBonus,
    IndividualLeagueBracket? individualLeague,
    bool? isCompleted,
    String? proleagueChampionId,
    String? proleagueRunnerUpId,
    int? phaseIndex,
    PlayoffBracket? playoff,
  }) {
    return Season(
      number: number ?? this.number,
      seasonMapIds: seasonMapIds ?? this.seasonMapIds,
      proleagueSchedule: proleagueSchedule ?? this.proleagueSchedule,
      currentMatchIndex: currentMatchIndex ?? this.currentMatchIndex,
      matchesSinceLastBonus: matchesSinceLastBonus ?? this.matchesSinceLastBonus,
      individualLeague: individualLeague ?? this.individualLeague,
      isCompleted: isCompleted ?? this.isCompleted,
      proleagueChampionId: proleagueChampionId ?? this.proleagueChampionId,
      proleagueRunnerUpId: proleagueRunnerUpId ?? this.proleagueRunnerUpId,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      playoff: playoff ?? this.playoff,
    );
  }
}

/// 플레이오프 대진표
@HiveType(typeId: 20)
class PlayoffBracket {
  @HiveField(0)
  final String firstPlaceTeamId; // 1위 팀 (결승 직행)

  @HiveField(1)
  final String secondPlaceTeamId; // 2위 팀

  @HiveField(2)
  final String thirdPlaceTeamId; // 3위 팀

  @HiveField(3)
  final String fourthPlaceTeamId; // 4위 팀

  @HiveField(4)
  final MatchResult? match34; // 3,4위전 결과

  @HiveField(5)
  final MatchResult? match23; // 2,3위전 결과 (3위 = 3,4위전 승자)

  @HiveField(6)
  final MatchResult? matchFinal; // 결승전 결과

  const PlayoffBracket({
    required this.firstPlaceTeamId,
    required this.secondPlaceTeamId,
    required this.thirdPlaceTeamId,
    required this.fourthPlaceTeamId,
    this.match34,
    this.match23,
    this.matchFinal,
  });

  /// 3,4위전 승자 (新 3위)
  String? get winner34 => match34?.winnerTeamId;

  /// 2,3위전 승자 (결승 진출)
  String? get winner23 => match23?.winnerTeamId;

  /// 프로리그 우승팀
  String? get champion => matchFinal?.winnerTeamId;

  /// 프로리그 준우승팀
  String? get runnerUp {
    if (matchFinal == null) return null;
    return matchFinal!.winnerTeamId == firstPlaceTeamId
        ? winner23
        : firstPlaceTeamId;
  }

  /// 현재 진행해야 할 플레이오프 매치
  PlayoffMatchType? get currentMatch {
    if (match34 == null) return PlayoffMatchType.thirdFourth;
    if (match23 == null) return PlayoffMatchType.secondThird;
    if (matchFinal == null) return PlayoffMatchType.final_;
    return null; // 모든 경기 완료
  }

  /// 다음 매치의 홈/어웨이 팀
  (String homeTeamId, String awayTeamId)? get nextMatchTeams {
    switch (currentMatch) {
      case PlayoffMatchType.thirdFourth:
        return (thirdPlaceTeamId, fourthPlaceTeamId);
      case PlayoffMatchType.secondThird:
        return (secondPlaceTeamId, winner34!);
      case PlayoffMatchType.final_:
        return (firstPlaceTeamId, winner23!);
      case null:
        return null;
    }
  }

  PlayoffBracket copyWith({
    String? firstPlaceTeamId,
    String? secondPlaceTeamId,
    String? thirdPlaceTeamId,
    String? fourthPlaceTeamId,
    MatchResult? match34,
    MatchResult? match23,
    MatchResult? matchFinal,
  }) {
    return PlayoffBracket(
      firstPlaceTeamId: firstPlaceTeamId ?? this.firstPlaceTeamId,
      secondPlaceTeamId: secondPlaceTeamId ?? this.secondPlaceTeamId,
      thirdPlaceTeamId: thirdPlaceTeamId ?? this.thirdPlaceTeamId,
      fourthPlaceTeamId: fourthPlaceTeamId ?? this.fourthPlaceTeamId,
      match34: match34 ?? this.match34,
      match23: match23 ?? this.match23,
      matchFinal: matchFinal ?? this.matchFinal,
    );
  }
}

/// 팀 순위 정보
@HiveType(typeId: 18)
class TeamStanding {
  @HiveField(0)
  final String teamId;

  @HiveField(1)
  final int wins;

  @HiveField(2)
  final int losses;

  @HiveField(3)
  final int setWins;

  @HiveField(4)
  final int setLosses;

  @HiveField(5)
  final int points; // 승점 (승리 당 3점)

  const TeamStanding({
    required this.teamId,
    this.wins = 0,
    this.losses = 0,
    this.setWins = 0,
    this.setLosses = 0,
    this.points = 0,
  });

  double get winRate => wins + losses > 0 ? wins / (wins + losses) : 0.0;
  int get setDiff => setWins - setLosses;

  TeamStanding addResult({
    required bool isWin,
    required int ourSets,
    required int opponentSets,
  }) {
    return TeamStanding(
      teamId: teamId,
      wins: wins + (isWin ? 1 : 0),
      losses: losses + (isWin ? 0 : 1),
      setWins: setWins + ourSets,
      setLosses: setLosses + opponentSets,
      points: points + (isWin ? 3 : 0),
    );
  }

  /// 순위 비교 (내림차순)
  int compareTo(TeamStanding other) {
    // 1. 승점
    if (points != other.points) return other.points - points;
    // 2. 세트 득실
    if (setDiff != other.setDiff) return other.setDiff - setDiff;
    // 3. 승률
    if (winRate != other.winRate) {
      return other.winRate > winRate ? 1 : -1;
    }
    return 0;
  }
}

/// 시즌 히스토리 (통계용)
@HiveType(typeId: 19)
class SeasonHistory {
  @HiveField(0)
  final int seasonNumber;

  @HiveField(1)
  final String? proleagueChampionId;

  @HiveField(2)
  final String? proleagueRunnerUpId;

  @HiveField(3)
  final String? individualChampionId;

  @HiveField(4)
  final String? individualRunnerUpId;

  @HiveField(5)
  final List<TeamStanding> finalStandings;

  @HiveField(6)
  final String? mvpPlayerId; // 시즌 MVP

  const SeasonHistory({
    required this.seasonNumber,
    this.proleagueChampionId,
    this.proleagueRunnerUpId,
    this.individualChampionId,
    this.individualRunnerUpId,
    this.finalStandings = const [],
    this.mvpPlayerId,
  });
}
