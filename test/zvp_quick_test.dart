// ZvP 5경기 시뮬레이션 - 텍스트 확인용
// 실행: flutter test test/zvp_quick_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;

  final testMap = GameMap(
    id: 'test_zvp_map',
    name: '파이팅스피릿',
    rushDistance: 5,
    resources: 6,
    complexity: 6,
    matchup: const RaceMatchup(
      tvzTerranWinRate: 52,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 48,
    ),
    expansionCount: 4,
    terrainComplexity: 6,
    airAccessibility: 5,
    centerImportance: 7,
    hasIsland: false,
  );

  final zergPlayer = Player(
    id: 'zvp_zerg',
    name: '박성준',
    raceIndex: Race.zerg.index,
    stats: PlayerStats(
      sense: 680, control: 750, attack: 650, harass: 700,
      strategy: 680, macro: 720, defense: 600, scout: 650,
    ),
    levelValue: 8,
    condition: 100,
  );

  final protossPlayer = Player(
    id: 'zvp_protoss',
    name: '김택용',
    raceIndex: Race.protoss.index,
    stats: PlayerStats(
      sense: 700, control: 720, attack: 680, harass: 650,
      strategy: 700, macro: 680, defense: 650, scout: 600,
    ),
    levelValue: 8,
    condition: 100,
  );

  setUp(() {
    service = MatchSimulationService();
  });

  test('ZvP 5경기 시뮬레이션 (텍스트 확인)', () async {
    print('');
    print('=' * 70);
    print('ZvP 5경기: 박성준(저그 B+) vs 김택용(프로토스 B+)');
    print('맵: 파이팅스피릿');
    print('=' * 70);

    int homeWins = 0;
    int awayWins = 0;

    for (int i = 0; i < 5; i++) {
      SimulationState? finalState;

      await for (final state in service.simulateMatchWithLog(
        homePlayer: zergPlayer,
        awayPlayer: protossPlayer,
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

        print('');
        print('--- 경기 ${i + 1} (${finalState.homeWin! ? "저그 승" : "토스 승"}) | ${finalState.battleLog.length}줄 ---');
        for (final entry in finalState.battleLogEntries) {
          final prefix = switch (entry.owner) {
            LogOwner.system => '[시스템]',
            LogOwner.home => '[홈-저그]',
            LogOwner.away => '[원정-토스]',
            LogOwner.clash => '[전투]',
          };
          print('  $prefix ${entry.text}');
        }
      }
    }

    print('');
    print('=' * 70);
    print('최종: 박성준(저그) $homeWins승 | 김택용(토스) $awayWins승');
    print('=' * 70);

    expect(homeWins + awayWins, 5);
  });
}
