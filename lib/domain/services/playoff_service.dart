import '../models/models.dart';

/// 플레이오프 서비스
class PlayoffService {
  /// 정규 시즌 순위 계산
  List<TeamStanding> calculateStandings(
    List<ScheduleItem> schedule,
    List<String> teamIds,
  ) {
    // 각 팀별 스탠딩 초기화
    final standings = <String, TeamStanding>{};
    for (final teamId in teamIds) {
      standings[teamId] = TeamStanding(teamId: teamId);
    }

    // 완료된 경기 결과 반영
    for (final item in schedule) {
      if (!item.isCompleted || item.result == null) continue;

      final result = item.result!;
      final homeTeamId = result.homeTeamId;
      final awayTeamId = result.awayTeamId;

      // 홈팀 결과
      standings[homeTeamId] = standings[homeTeamId]!.addResult(
        isWin: result.isHomeWin,
        ourSets: result.homeScore,
        opponentSets: result.awayScore,
      );

      // 어웨이팀 결과
      standings[awayTeamId] = standings[awayTeamId]!.addResult(
        isWin: result.isAwayWin,
        ourSets: result.awayScore,
        opponentSets: result.homeScore,
      );
    }

    // 상대 전적 맵 생성 (teamA -> teamB -> (teamA의 승, teamA의 패))
    final headToHead = _buildHeadToHeadRecord(schedule);

    // 순위 정렬 (승점 → 세트 득실 → 상대 전적)
    final sortedStandings = standings.values.toList()
      ..sort((a, b) => _compareStandings(a, b, headToHead));

    return sortedStandings;
  }

  /// 상대 전적 맵 생성
  /// 반환: {teamA: {teamB: (teamA 승수, teamA 패수)}}
  Map<String, Map<String, (int, int)>> _buildHeadToHeadRecord(
    List<ScheduleItem> schedule,
  ) {
    final record = <String, Map<String, (int, int)>>{};

    for (final item in schedule) {
      if (!item.isCompleted || item.result == null) continue;

      final result = item.result!;
      final home = result.homeTeamId;
      final away = result.awayTeamId;
      final homeWin = result.isHomeWin;

      // 홈팀 기록
      record.putIfAbsent(home, () => {});
      final (homeWins, homeLosses) = record[home]![away] ?? (0, 0);
      record[home]![away] = homeWin ? (homeWins + 1, homeLosses) : (homeWins, homeLosses + 1);

      // 어웨이팀 기록
      record.putIfAbsent(away, () => {});
      final (awayWins, awayLosses) = record[away]![home] ?? (0, 0);
      record[away]![home] = homeWin ? (awayWins, awayLosses + 1) : (awayWins + 1, awayLosses);
    }

    return record;
  }

  /// 순위 비교 (승점 → 세트 득실 → 상대 전적)
  int _compareStandings(
    TeamStanding a,
    TeamStanding b,
    Map<String, Map<String, (int, int)>> headToHead,
  ) {
    // 1. 승점 비교
    if (a.points != b.points) return b.points - a.points;

    // 2. 세트 득실 비교
    if (a.setDiff != b.setDiff) return b.setDiff - a.setDiff;

    // 3. 상대 전적 비교
    final aVsB = headToHead[a.teamId]?[b.teamId];
    if (aVsB != null) {
      final (aWins, aLosses) = aVsB;
      if (aWins != aLosses) {
        return aWins > aLosses ? -1 : 1; // A가 이기면 A가 상위
      }
    }

    // 4. 동률이면 그대로
    return 0;
  }

  /// 플레이오프 대진표 생성 (정규 시즌 완료 후)
  PlayoffBracket createPlayoffBracket(List<TeamStanding> standings) {
    if (standings.length < 4) {
      throw ArgumentError('플레이오프에는 최소 4개 팀이 필요합니다.');
    }

    return PlayoffBracket(
      firstPlaceTeamId: standings[0].teamId,
      secondPlaceTeamId: standings[1].teamId,
      thirdPlaceTeamId: standings[2].teamId,
      fourthPlaceTeamId: standings[3].teamId,
    );
  }

  /// 다음 시즌 단계 결정
  SeasonPhase getNextPhase(Season season) {
    final currentPhase = season.phase;
    final playoff = season.playoff;
    final individualLeague = season.individualLeague;

    switch (currentPhase) {
      case SeasonPhase.regularSeason:
        // 정규 시즌 완료 + 개인리그 8강 완료 시 플레이오프 시작
        if (season.isRegularSeasonCompleted) {
          return SeasonPhase.playoffReady;
        }
        return SeasonPhase.regularSeason;

      case SeasonPhase.playoffReady:
        return SeasonPhase.playoff34;

      case SeasonPhase.playoff34:
        // 3,4위전 완료 시
        if (playoff?.match34 != null) {
          return SeasonPhase.individualSemiFinal;
        }
        return SeasonPhase.playoff34;

      case SeasonPhase.individualSemiFinal:
        // 개인리그 4강 완료 체크
        final semiFinalCount = individualLeague?.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.semiFinal)
            .length ?? 0;
        if (semiFinalCount >= 2) {
          return SeasonPhase.playoff23;
        }
        return SeasonPhase.individualSemiFinal;

      case SeasonPhase.playoff23:
        // 2,3위전 완료 시
        if (playoff?.match23 != null) {
          return SeasonPhase.individualFinal;
        }
        return SeasonPhase.playoff23;

      case SeasonPhase.individualFinal:
        // 개인리그 결승 완료 체크
        if (individualLeague?.championId != null) {
          return SeasonPhase.playoffFinal;
        }
        return SeasonPhase.individualFinal;

      case SeasonPhase.playoffFinal:
        // 결승전 완료 시
        if (playoff?.matchFinal != null) {
          return SeasonPhase.seasonEnd;
        }
        return SeasonPhase.playoffFinal;

      case SeasonPhase.seasonEnd:
        return SeasonPhase.seasonEnd;
    }
  }

  /// 현재 단계에서 수행해야 할 이벤트 설명
  String getPhaseDescription(SeasonPhase phase) {
    switch (phase) {
      case SeasonPhase.regularSeason:
        return '정규 시즌 진행 중';
      case SeasonPhase.playoffReady:
        return '플레이오프 대기 중 - 순위 확정';
      case SeasonPhase.playoff34:
        return '플레이오프 3,4위전';
      case SeasonPhase.individualSemiFinal:
        return '개인리그 4강';
      case SeasonPhase.playoff23:
        return '플레이오프 2,3위전';
      case SeasonPhase.individualFinal:
        return '개인리그 결승';
      case SeasonPhase.playoffFinal:
        return '프로리그 결승전';
      case SeasonPhase.seasonEnd:
        return '시즌 종료';
    }
  }

  /// 플레이오프 매치 결과 업데이트
  PlayoffBracket updatePlayoffMatch(
    PlayoffBracket bracket,
    PlayoffMatchType matchType,
    MatchResult result,
  ) {
    switch (matchType) {
      case PlayoffMatchType.thirdFourth:
        return bracket.copyWith(match34: result);
      case PlayoffMatchType.secondThird:
        return bracket.copyWith(match23: result);
      case PlayoffMatchType.final_:
        return bracket.copyWith(matchFinal: result);
    }
  }

  /// 컨디션 회복이 필요한 단계인지 확인
  bool needsConditionRecovery(SeasonPhase phase) {
    return phase == SeasonPhase.individualSemiFinal ||
           phase == SeasonPhase.individualFinal;
  }

  /// 플레이오프 진행 상황 요약
  PlayoffProgress getPlayoffProgress(PlayoffBracket bracket) {
    return PlayoffProgress(
      match34Completed: bracket.match34 != null,
      match23Completed: bracket.match23 != null,
      matchFinalCompleted: bracket.matchFinal != null,
      winner34: bracket.winner34,
      winner23: bracket.winner23,
      champion: bracket.champion,
      runnerUp: bracket.runnerUp,
    );
  }
}

/// 플레이오프 진행 상황
class PlayoffProgress {
  final bool match34Completed;
  final bool match23Completed;
  final bool matchFinalCompleted;
  final String? winner34;
  final String? winner23;
  final String? champion;
  final String? runnerUp;

  const PlayoffProgress({
    required this.match34Completed,
    required this.match23Completed,
    required this.matchFinalCompleted,
    this.winner34,
    this.winner23,
    this.champion,
    this.runnerUp,
  });

  bool get isCompleted => matchFinalCompleted;

  int get completedMatchCount {
    int count = 0;
    if (match34Completed) count++;
    if (match23Completed) count++;
    if (matchFinalCompleted) count++;
    return count;
  }
}
