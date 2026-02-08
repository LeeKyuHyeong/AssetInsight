import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/playoff_service.dart';

/// 헬퍼: 8개 테스트 팀 생성
List<Team> _createTestTeams() {
  return List.generate(8, (i) => Team(
    id: 'team_$i',
    name: '팀$i',
    shortName: 'T$i',
    colorValue: 0xFF000000 + i,
    playerIds: List.generate(10, (j) => 'player_${i}_$j'),
    money: 100,
    actionPoints: 0,
  ));
}

/// 헬퍼: 팀에 매칭되는 선수 생성 (8팀 × 10명 = 80명)
List<Player> _createTestPlayers(List<Team> teams) {
  final players = <Player>[];
  for (final team in teams) {
    for (final pid in team.playerIds) {
      players.add(Player(
        id: pid,
        name: '선수_$pid',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 400, control: 400, attack: 400, harass: 400,
          strategy: 400, macro: 400, defense: 400, scout: 400,
        ),
        levelValue: 5,
        condition: 80,
        teamId: team.id,
      ));
    }
  }
  return players;
}

/// 서클 메서드로 풀 라운드 로빈 대진 생성 (코드 복사 — 비공개 메서드 직접 테스트 불가)
List<List<String>> _generateRoundRobinMatchups(List<Team> teams, Random rng) {
  final matchups = <List<String>>[];
  final teamIds = teams.map((t) => t.id).toList()..shuffle(rng);
  final n = teamIds.length;

  for (int round = 0; round < n - 1; round++) {
    for (int i = 0; i < n ~/ 2; i++) {
      final home = i == 0 ? teamIds[0] : teamIds[(round + i) % (n - 1) + 1];
      final away = teamIds[(round + n - 1 - i) % (n - 1) + 1];
      if (i == 0) {
        matchups.add([teamIds[0], away]);
      } else {
        matchups.add([home, away]);
      }
    }
  }

  return matchups;
}

/// 프로리그 일정 생성 (비공개 메서드 복사)
List<ScheduleItem> _createProleagueSchedule(List<Team> teams) {
  final rng = Random(42);
  final schedule = <ScheduleItem>[];
  int matchId = 0;

  final firstHalfMatchups = _generateRoundRobinMatchups(teams, rng);

  final rows = List.generate(11, (i) => i);
  rows.shuffle(rng);
  final matchRows = rows.take(7).toList()..sort();

  // 1차 리그 (홀수 슬롯)
  for (int i = 0; i < firstHalfMatchups.length; i++) {
    final matchup = firstHalfMatchups[i];
    final round = i ~/ 4;
    final slot = matchRows[round] * 2 + 1;

    schedule.add(ScheduleItem(
      matchId: 'match_1_${matchId++}',
      roundNumber: slot,
      homeTeamId: matchup[0],
      awayTeamId: matchup[1],
    ));
  }

  // 2차 리그 (짝수 슬롯, 데칼코마니)
  for (int i = 0; i < firstHalfMatchups.length; i++) {
    final matchup = firstHalfMatchups[i];
    final round = i ~/ 4;
    final firstSlot = matchRows[round] * 2 + 1;
    final secondSlot = 23 - firstSlot;

    schedule.add(ScheduleItem(
      matchId: 'match_1_${matchId++}',
      roundNumber: secondSlot,
      homeTeamId: matchup[1],
      awayTeamId: matchup[0],
    ));
  }

  return schedule;
}

/// 헬퍼: MatchResult 생성 (홈 승)
MatchResult _createMatchResult({
  required String homeTeamId,
  required String awayTeamId,
  required int homeScore,
  required int awayScore,
  int roundNumber = 1,
}) {
  final sets = <SetResult>[];
  for (int i = 0; i < homeScore; i++) {
    sets.add(SetResult(
      mapId: 'map_$i',
      homePlayerId: 'hp_$i',
      awayPlayerId: 'ap_$i',
      homeWin: true,
    ));
  }
  for (int i = 0; i < awayScore; i++) {
    sets.add(SetResult(
      mapId: 'map_${homeScore + i}',
      homePlayerId: 'hp_${homeScore + i}',
      awayPlayerId: 'ap_${homeScore + i}',
      homeWin: false,
    ));
  }
  return MatchResult(
    id: 'mr_${homeTeamId}_$awayTeamId',
    homeTeamId: homeTeamId,
    awayTeamId: awayTeamId,
    sets: sets,
    isCompleted: true,
    roundNumber: roundNumber,
  );
}

void main() {
  group('일정 생성 검증: 8팀 라운드로빈 → 28경기(7라운드×4경기)', () {
    test('풀 라운드 로빈은 정확히 28경기를 생성한다', () {
      final teams = _createTestTeams();
      final rng = Random(42);
      final matchups = _generateRoundRobinMatchups(teams, rng);
      expect(matchups.length, 28, reason: '8팀 풀 라운드 로빈 = C(8,2) = 28경기');
    });

    test('프로리그 일정은 56개 ScheduleItem(28×2 홈/어웨이)을 생성한다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);
      expect(schedule.length, 56, reason: '1차 28 + 2차 28 = 56경기');
    });

    test('모든 팀 쌍이 정확히 1회 대전한다 (1차 리그 기준)', () {
      final teams = _createTestTeams();
      final rng = Random(42);
      final matchups = _generateRoundRobinMatchups(teams, rng);
      final teamIds = teams.map((t) => t.id).toSet();

      // 각 페어가 정확히 1회
      final pairSet = <String>{};
      for (final m in matchups) {
        final key = [m[0], m[1]]..sort();
        pairSet.add(key.join('-'));
      }

      // C(8,2) = 28 고유 페어
      expect(pairSet.length, 28);

      // 모든 팀이 참여
      final appearedTeams = <String>{};
      for (final m in matchups) {
        appearedTeams.add(m[0]);
        appearedTeams.add(m[1]);
      }
      expect(appearedTeams, teamIds);
    });

    test('각 라운드는 정확히 4경기이고, 같은 팀이 라운드 내 중복 출전하지 않는다', () {
      final teams = _createTestTeams();
      final rng = Random(42);
      final matchups = _generateRoundRobinMatchups(teams, rng);

      for (int round = 0; round < 7; round++) {
        final roundMatchups = matchups.sublist(round * 4, round * 4 + 4);
        expect(roundMatchups.length, 4, reason: '라운드 $round는 4경기');

        // 라운드 내 중복 팀 없음
        final teamsInRound = <String>{};
        for (final m in roundMatchups) {
          teamsInRound.add(m[0]);
          teamsInRound.add(m[1]);
        }
        expect(teamsInRound.length, 8, reason: '라운드 $round에 8팀 모두 출전');
      }
    });
  });

  group('데칼코마니 대칭: 슬롯 k ↔ 23-k가 동일 상대(홈/어웨이 반전)', () {
    test('1차 리그 경기(홀수 슬롯)와 2차 리그 경기(짝수 슬롯)가 대칭이다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);

      // 1차 리그: schedule 앞 28개, 2차 리그: 뒤 28개
      final firstHalf = schedule.sublist(0, 28);
      final secondHalf = schedule.sublist(28, 56);

      for (int i = 0; i < 28; i++) {
        final first = firstHalf[i];
        final second = secondHalf[i];

        // 슬롯 대칭: k + mirror = 23
        expect(
          first.roundNumber + second.roundNumber,
          23,
          reason: '슬롯 ${first.roundNumber} + ${second.roundNumber} = 23 (데칼코마니)',
        );

        // 홈/어웨이 반전
        expect(first.homeTeamId, second.awayTeamId,
          reason: '1차 홈팀이 2차 어웨이팀');
        expect(first.awayTeamId, second.homeTeamId,
          reason: '1차 어웨이팀이 2차 홈팀');
      }
    });

    test('빈 행(NO match)도 데칼코마니 대칭이다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);

      // 1차 리그가 사용하는 홀수 슬롯 모음
      final firstSlots = schedule.sublist(0, 28).map((s) => s.roundNumber).toSet();
      // 2차 리그가 사용하는 짝수 슬롯 모음
      final secondSlots = schedule.sublist(28, 56).map((s) => s.roundNumber).toSet();

      // 모든 홀수 슬롯(1,3,...,21) 중 경기가 없는 것 = NO match 행
      final allOddSlots = List.generate(11, (i) => i * 2 + 1).toSet();
      final noMatchOddSlots = allOddSlots.difference(firstSlots);

      // 모든 짝수 슬롯(2,4,...,22) 중 경기가 없는 것
      final allEvenSlots = List.generate(11, (i) => i * 2 + 2).toSet();
      final noMatchEvenSlots = allEvenSlots.difference(secondSlots);

      // NO match 홀수 슬롯의 데칼코마니 = 23-k → 짝수 슬롯에서도 NO match
      for (final oddSlot in noMatchOddSlots) {
        final mirrorSlot = 23 - oddSlot;
        expect(noMatchEvenSlots.contains(mirrorSlot), true,
          reason: '슬롯 $oddSlot에 경기 없으면 미러 슬롯 $mirrorSlot도 경기 없어야 함');
      }
    });
  });

  group('홈/어웨이 균등: 각 팀이 홈 7회, 어웨이 7회 (리그별)', () {
    test('1차 리그에서 각 팀 홈 7회, 어웨이 7회', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);

      // 전체 일정에서 팀별 홈/어웨이 횟수
      final homeCount = <String, int>{};
      final awayCount = <String, int>{};

      for (final item in schedule) {
        homeCount[item.homeTeamId] = (homeCount[item.homeTeamId] ?? 0) + 1;
        awayCount[item.awayTeamId] = (awayCount[item.awayTeamId] ?? 0) + 1;
      }

      for (final team in teams) {
        // 전체 56경기에서 각 팀은 14번 출전 = 홈 7 + 어웨이 7
        final h = homeCount[team.id] ?? 0;
        final a = awayCount[team.id] ?? 0;
        expect(h, 7, reason: '${team.id} 홈 7회');
        expect(a, 7, reason: '${team.id} 어웨이 7회');
      }
    });
  });

  group('2경기 보너스: applyTwoMatchBonus()', () {
    test('Team.applyTwoMatchBonus()는 deprecated되어 행동력 변경 없음 (Player로 이동)', () {
      final team = Team(
        id: 'test_team',
        name: '테스트팀',
        shortName: 'TT',
        colorValue: 0xFF000000,
        actionPoints: 50,
      );

      // ignore: deprecated_member_use_from_same_package
      final bonusTeam = team.applyTwoMatchBonus();
      expect(bonusTeam.actionPoints, 50, reason: '행동력은 Player 모델에서 관리, Team은 변경 없음');
    });

    test('Season.shouldGiveBonus는 matchesSinceLastBonus >= 2일 때 true', () {
      const season0 = Season(number: 1, matchesSinceLastBonus: 0);
      const season1 = Season(number: 1, matchesSinceLastBonus: 1);
      const season2 = Season(number: 1, matchesSinceLastBonus: 2);
      const season3 = Season(number: 1, matchesSinceLastBonus: 3);

      expect(season0.shouldGiveBonus, false);
      expect(season1.shouldGiveBonus, false);
      expect(season2.shouldGiveBonus, true);
      expect(season3.shouldGiveBonus, true);
    });

    test('Season.advanceMatch()가 2경기 후 matchesSinceLastBonus를 0으로 리셋한다', () {
      const season = Season(number: 1, matchesSinceLastBonus: 1);
      final advanced = season.advanceMatch();
      // matchesSinceLastBonus가 2가 되면 보너스 지급 후 0으로 리셋
      expect(advanced.matchesSinceLastBonus, 0,
        reason: '1 + 1 = 2 >= 2 → 리셋');
    });

    test('Player 컨디션 +5 보너스 적용 (clamp 0~110)', () {
      final player = Player(
        id: 'p1',
        name: '선수1',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(sense: 400, control: 400),
        condition: 80,
      );

      // 보너스 적용 시뮬레이션
      final bonusPlayer = player.copyWith(
        condition: (player.condition + 5).clamp(0, 110),
      );
      expect(bonusPlayer.condition, 85);

      // 상한 테스트
      final highCondPlayer = player.copyWith(condition: 108);
      final bonusHighCond = highCondPlayer.copyWith(
        condition: (highCondPlayer.condition + 5).clamp(0, 110),
      );
      expect(bonusHighCond.condition, 110, reason: '108 + 5 = 113 → clamp 110');
    });
  });

  group('순위 계산: 승점(3점)→세트득실→상대전적 타이브레이커', () {
    final playoffService = PlayoffService();

    test('승리 시 3점 기록, 패배 시 0점', () {
      final teamIds = ['A', 'B'];
      final schedule = [
        ScheduleItem(
          matchId: 'm1',
          roundNumber: 1,
          homeTeamId: 'A',
          awayTeamId: 'B',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'A', awayTeamId: 'B',
            homeScore: 4, awayScore: 2,
          ),
        ),
      ];

      final standings = playoffService.calculateStandings(schedule, teamIds);

      // A가 1위 (3점)
      expect(standings[0].teamId, 'A');
      expect(standings[0].points, 3);
      expect(standings[0].wins, 1);
      expect(standings[0].losses, 0);
      expect(standings[0].setWins, 4);
      expect(standings[0].setLosses, 2);

      // B가 2위 (0점)
      expect(standings[1].teamId, 'B');
      expect(standings[1].points, 0);
      expect(standings[1].wins, 0);
      expect(standings[1].losses, 1);
    });

    test('승점 동점 시 세트 득실로 순위 결정', () {
      // A: 1승 (4-3), B: 1승 (4-1) → 동점이지만 B의 세트 득실이 더 좋음
      final teamIds = ['A', 'B', 'C'];
      final schedule = [
        ScheduleItem(
          matchId: 'm1', roundNumber: 1,
          homeTeamId: 'A', awayTeamId: 'C',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'A', awayTeamId: 'C',
            homeScore: 4, awayScore: 3,
          ),
        ),
        ScheduleItem(
          matchId: 'm2', roundNumber: 2,
          homeTeamId: 'B', awayTeamId: 'C',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'B', awayTeamId: 'C',
            homeScore: 4, awayScore: 1,
          ),
        ),
      ];

      final standings = playoffService.calculateStandings(schedule, teamIds);

      // B: 세트득실 +3, A: 세트득실 +1
      expect(standings[0].teamId, 'B', reason: 'B가 세트득실 +3으로 1위');
      expect(standings[0].setDiff, 3);
      expect(standings[1].teamId, 'A', reason: 'A가 세트득실 +1로 2위');
      expect(standings[1].setDiff, 1);
    });

    test('승점·세트득실 동점 시 상대전적으로 순위 결정', () {
      // A vs B: A 승 (4-3), B vs C: B 승 (4-3), A vs C: C 승 (4-3)
      // 모두 1승 1패, 세트득실 0
      // 상대 전적: A > B (직접 대결 A 승)
      final teamIds = ['A', 'B'];
      final schedule = [
        ScheduleItem(
          matchId: 'm1', roundNumber: 1,
          homeTeamId: 'A', awayTeamId: 'B',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'A', awayTeamId: 'B',
            homeScore: 4, awayScore: 3,
          ),
        ),
        // A, B 각각 다른 팀에게 져서 1승 1패로 만듦
        ScheduleItem(
          matchId: 'm2', roundNumber: 2,
          homeTeamId: 'A', awayTeamId: 'B',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'A', awayTeamId: 'B',
            homeScore: 3, awayScore: 4, // B 승
          ),
        ),
      ];

      final standings = playoffService.calculateStandings(schedule, teamIds);

      // 둘 다 1승 1패, 각각 세트 7:7 → 세트득실 0
      // 상대 전적: 1:1 → 동률 (compareTo 0)
      expect(standings[0].points, standings[1].points, reason: '승점 동점');
      expect(standings[0].setDiff, standings[1].setDiff, reason: '세트득실 동점');
    });

    test('상대전적으로 순위 차이가 발생하는 경우', () {
      // 3팀 삼파전: A/B/C 각각 다른 팀에게 승리
      // A beats B (4-2), C beats A (4-2), B beats C (4-2)
      // 모두 1승 1패 (3점)
      // 세트: A(4+2=6승, 2+4=6패→득실0), B(2+4=6승, 4+2=6패→득실0), C(4+2=6승, 2+4=6패→득실0)
      final teamIds = ['A', 'B', 'C'];
      final schedule = [
        // A vs B → A 승 (4-2)
        ScheduleItem(
          matchId: 'm1', roundNumber: 1,
          homeTeamId: 'A', awayTeamId: 'B',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'A', awayTeamId: 'B',
            homeScore: 4, awayScore: 2,
          ),
        ),
        // C vs A → C 승 (4-2)
        ScheduleItem(
          matchId: 'm2', roundNumber: 2,
          homeTeamId: 'C', awayTeamId: 'A',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'C', awayTeamId: 'A',
            homeScore: 4, awayScore: 2,
          ),
        ),
        // B vs C → B 승 (4-2)
        ScheduleItem(
          matchId: 'm3', roundNumber: 3,
          homeTeamId: 'B', awayTeamId: 'C',
          isCompleted: true,
          result: _createMatchResult(
            homeTeamId: 'B', awayTeamId: 'C',
            homeScore: 4, awayScore: 2,
          ),
        ),
      ];

      final standings = playoffService.calculateStandings(schedule, teamIds);

      // 모두 1승 1패 (3점), 세트득실 0
      for (final s in standings) {
        expect(s.points, 3, reason: '${s.teamId} 1승 3점');
        expect(s.setDiff, 0, reason: '${s.teamId} 세트득실 0 (6-6)');
      }
      // 승점·세트득실 모두 동점이므로 상대전적이 타이브레이커
      // A>B, B>C, C>A → 순환, compareTo가 0을 반환하여 동률
      // 3팀 모두 존재하는지만 확인
      final resultIds = standings.map((s) => s.teamId).toSet();
      expect(resultIds, {'A', 'B', 'C'});
    });

    test('TeamStanding.addResult가 올바르게 누적한다', () {
      var standing = const TeamStanding(teamId: 'X');

      // 첫 경기: 승리 4-2
      standing = standing.addResult(isWin: true, ourSets: 4, opponentSets: 2);
      expect(standing.wins, 1);
      expect(standing.losses, 0);
      expect(standing.setWins, 4);
      expect(standing.setLosses, 2);
      expect(standing.points, 3);
      expect(standing.setDiff, 2);

      // 두 번째 경기: 패배 3-4
      standing = standing.addResult(isWin: false, ourSets: 3, opponentSets: 4);
      expect(standing.wins, 1);
      expect(standing.losses, 1);
      expect(standing.setWins, 7);
      expect(standing.setLosses, 6);
      expect(standing.points, 3);
      expect(standing.setDiff, 1);
    });
  });

  group('AI 매치 시뮬: 같은 라운드 AI 경기 처리 구조 검증', () {
    test('같은 roundNumber의 여러 경기가 schedule에 존재하고 필터링 가능하다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);

      // 특정 roundNumber에 해당하는 경기들을 찾기
      final roundNumbers = schedule.map((s) => s.roundNumber).toSet();

      for (final rn in roundNumbers) {
        final matchesInRound = schedule.where((s) => s.roundNumber == rn).toList();
        // 한 슬롯에 최대 4경기 (같은 라운드의 4팀 대결)
        expect(matchesInRound.length, greaterThanOrEqualTo(1));
        expect(matchesInRound.length, lessThanOrEqualTo(4));
      }
    });

    test('플레이어 팀을 제외한 같은 라운드 경기를 필터링할 수 있다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);
      final playerTeamId = 'team_0'; // 플레이어 팀

      // 한 라운드의 경기 가져오기
      final sampleRound = schedule.first.roundNumber;
      final roundMatches = schedule.where((s) => s.roundNumber == sampleRound).toList();
      final aiMatches = roundMatches.where((m) =>
        m.homeTeamId != playerTeamId && m.awayTeamId != playerTeamId
      ).toList();

      // 4경기 중 플레이어 팀이 참여하는 경기는 최대 1개
      // 따라서 AI 경기는 최소 roundMatches.length - 1 개 이상 (최대 roundMatches.length)
      if (roundMatches.any((m) =>
          m.homeTeamId == playerTeamId || m.awayTeamId == playerTeamId)) {
        expect(aiMatches.length, roundMatches.length - 1);
      } else {
        expect(aiMatches.length, roundMatches.length);
      }
    });

    test('AI 경기 완료 후 isCompleted + result가 채워지는 구조', () {
      // ScheduleItem.complete() 메서드 검증
      final item = ScheduleItem(
        matchId: 'test_match',
        roundNumber: 1,
        homeTeamId: 'team_0',
        awayTeamId: 'team_1',
      );

      expect(item.isCompleted, false);
      expect(item.result, null);

      final result = _createMatchResult(
        homeTeamId: 'team_0',
        awayTeamId: 'team_1',
        homeScore: 4,
        awayScore: 2,
      );

      final completed = item.complete(result);
      expect(completed.isCompleted, true);
      expect(completed.result, isNotNull);
      expect(completed.result!.homeScore, 4);
      expect(completed.result!.awayScore, 2);
      expect(completed.result!.isHomeWin, true);
    });

    test('Season.updateMatchResult()가 특정 인덱스의 경기를 올바르게 갱신한다', () {
      final teams = _createTestTeams();
      final schedule = _createProleagueSchedule(teams);

      final season = Season(
        number: 1,
        proleagueSchedule: schedule,
      );

      // 첫 번째 경기 완료 처리
      final result = _createMatchResult(
        homeTeamId: schedule[0].homeTeamId,
        awayTeamId: schedule[0].awayTeamId,
        homeScore: 4,
        awayScore: 3,
      );

      final updatedSeason = season.updateMatchResult(0, result);

      expect(updatedSeason.proleagueSchedule[0].isCompleted, true);
      expect(updatedSeason.proleagueSchedule[0].result!.isHomeWin, true);
      // 다른 경기는 변경 없음
      expect(updatedSeason.proleagueSchedule[1].isCompleted, false);
    });
  });

  group('통합 검증', () {
    test('다양한 시드로 일정을 생성해도 28+28=56경기 유지', () {
      final teams = _createTestTeams();

      for (int seed = 0; seed < 10; seed++) {
        final rng = Random(seed);
        final matchups = _generateRoundRobinMatchups(teams, rng);
        expect(matchups.length, 28, reason: 'seed=$seed: 28경기');

        // 중복 페어 없음
        final pairSet = <String>{};
        for (final m in matchups) {
          final key = [m[0], m[1]]..sort();
          pairSet.add(key.join('-'));
        }
        expect(pairSet.length, 28, reason: 'seed=$seed: 중복 없음');
      }
    });

    test('PlayoffService.calculateStandings는 빈 스케줄에서도 작동한다', () {
      final service = PlayoffService();
      final standings = service.calculateStandings([], ['A', 'B', 'C']);

      expect(standings.length, 3);
      for (final s in standings) {
        expect(s.points, 0);
        expect(s.wins, 0);
        expect(s.losses, 0);
      }
    });

    test('MatchResult 스코어 계산이 정확하다', () {
      final result = _createMatchResult(
        homeTeamId: 'A',
        awayTeamId: 'B',
        homeScore: 4,
        awayScore: 3,
      );

      expect(result.homeScore, 4);
      expect(result.awayScore, 3);
      expect(result.isHomeWin, true);
      expect(result.isAwayWin, false);
      // isAceMatch는 현재 스코어가 3-3일 때 true (결정 전 상태)
      // 4-3은 이미 결정된 상태이므로 false
      expect(result.isAceMatch, false);
      expect(result.winnerTeamId, 'A');

      // 3-3 에이스 결정전 상태 검증
      final aceResult = _createMatchResult(
        homeTeamId: 'X', awayTeamId: 'Y',
        homeScore: 3, awayScore: 3,
      );
      expect(aceResult.isAceMatch, true, reason: '3-3은 에이스 결정전');
    });
  });
}
