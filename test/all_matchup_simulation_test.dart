// 9개 종족전 각 10경기 시뮬레이션 테스트
// 동일 맵, 동일 등급(B+) 선수
//
// 실행: flutter test test/all_matchup_simulation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;

  final testMap = GameMap(
    id: 'test_map',
    name: '파이팅스피릿',
    rushDistance: 5,
    resources: 6,
    complexity: 6,
    matchup: const RaceMatchup(
      tvzTerranWinRate: 55,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 45,
    ),
    expansionCount: 4,
    terrainComplexity: 6,
    airAccessibility: 5,
    centerImportance: 7,
    hasIsland: false,
  );

  Player makePlayer(String id, String name, Race race) => Player(
    id: id,
    name: name,
    raceIndex: race.index,
    stats: PlayerStats(
      sense: 650,
      control: 650,
      attack: 650,
      harass: 650,
      strategy: 650,
      macro: 650,
      defense: 650,
      scout: 650,
    ),
    levelValue: 8,
    condition: 100,
  );

  Future<void> runMatchup({
    required String label,
    required Race homeRace,
    required Race awayRace,
    required int count,
  }) async {
    print('');
    print('=' * 60);
    print('$label ($count경기)');
    print('=' * 60);

    final home = makePlayer('home', '홈${homeRace.name}', homeRace);
    final away = makePlayer('away', '원정${awayRace.name}', awayRace);

    int homeWins = 0;
    int awayWins = 0;
    int errors = 0;
    int totalLines = 0;
    List<String>? sampleLog;

    for (int i = 0; i < count; i++) {
      try {
        SimulationState? finalState;
        await for (final state in service.simulateMatchWithLog(
          homePlayer: home,
          awayPlayer: away,
          map: testMap,
          getIntervalMs: () => 0,
        )) {
          if (state.isFinished) {
            finalState = state;
          }
        }

        if (finalState != null && finalState.homeWin != null) {
          if (finalState.homeWin!) {
            homeWins++;
          } else {
            awayWins++;
          }
          final lines = finalState.battleLog.length;
          totalLines += lines;
          print('  [경기${i + 1}] ${finalState.homeWin! ? "홈승" : "원정승"} | 홈병력=${finalState.homeArmy} 원정병력=${finalState.awayArmy} | ${lines}줄');

          if (sampleLog == null) {
            sampleLog = finalState.battleLog;
          }
        } else {
          errors++;
          print('  [경기${i + 1}] 결과 없음 (homeWin == null)');
        }
      } catch (e, st) {
        errors++;
        print('  [경기${i + 1}] ERROR: $e');
        print('  $st');
      }
    }

    final total = homeWins + awayWins;
    final winRate = total > 0 ? (homeWins / total * 100).toStringAsFixed(1) : 'N/A';
    final avgLines = total > 0 ? (totalLines / total).toStringAsFixed(1) : 'N/A';

    print('');
    print('--- $label 결과 ---');
    print('홈 $homeWins - $awayWins 원정 | 승률: $winRate% | 에러: $errors | 평균 로그: $avgLines줄');

    if (sampleLog != null) {
      print('');
      print('--- 샘플 로그 (경기 1, ${sampleLog.length}줄) ---');
      for (final line in sampleLog) {
        print('  $line');
      }
    }

    expect(errors, 0, reason: '$label에서 에러 발생');
    expect(total, count, reason: '$label 경기 수 불일치');
  }

  setUp(() {
    service = MatchSimulationService();
  });

  group('9개 종족전 시뮬레이션', () {
    test('TvZ 10경기', () async {
      await runMatchup(label: 'TvZ (테란 vs 저그)', homeRace: Race.terran, awayRace: Race.zerg, count: 10);
    });

    test('ZvT 10경기', () async {
      await runMatchup(label: 'ZvT (저그 vs 테란)', homeRace: Race.zerg, awayRace: Race.terran, count: 10);
    });

    test('TvP 10경기', () async {
      await runMatchup(label: 'TvP (테란 vs 프로토스)', homeRace: Race.terran, awayRace: Race.protoss, count: 10);
    });

    test('PvT 10경기', () async {
      await runMatchup(label: 'PvT (프로토스 vs 테란)', homeRace: Race.protoss, awayRace: Race.terran, count: 10);
    });

    test('ZvP 10경기', () async {
      await runMatchup(label: 'ZvP (저그 vs 프로토스)', homeRace: Race.zerg, awayRace: Race.protoss, count: 10);
    });

    test('PvZ 10경기', () async {
      await runMatchup(label: 'PvZ (프로토스 vs 저그)', homeRace: Race.protoss, awayRace: Race.zerg, count: 10);
    });

    test('TvT 10경기', () async {
      await runMatchup(label: 'TvT (테란 vs 테란)', homeRace: Race.terran, awayRace: Race.terran, count: 10);
    });

    test('ZvZ 10경기', () async {
      await runMatchup(label: 'ZvZ (저그 vs 저그)', homeRace: Race.zerg, awayRace: Race.zerg, count: 10);
    });

    test('PvP 10경기', () async {
      await runMatchup(label: 'PvP (프로토스 vs 프로토스)', homeRace: Race.protoss, awayRace: Race.protoss, count: 10);
    });
  });
}
