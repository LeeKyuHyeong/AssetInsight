// PvP 5경기 시뮬레이션 - 텍스트 확인용
// 실행: flutter test test/pvp_quick_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;

  final testMap = GameMap(
    id: 'test_pvp_map',
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

  // 공격형 프로토스 (B+)
  final attackProtoss = Player(
    id: 'pvp_attacker',
    name: '김공격',
    raceIndex: Race.protoss.index,
    stats: PlayerStats(
      sense: 650,
      control: 700,
      attack: 750,
      harass: 700,
      strategy: 550,
      macro: 450,
      defense: 400,
      scout: 500,
    ),
    levelValue: 8,
    condition: 100,
  );

  // 운영형 프로토스 (B+)
  final defenseProtoss = Player(
    id: 'pvp_defender',
    name: '박운영',
    raceIndex: Race.protoss.index,
    stats: PlayerStats(
      sense: 550,
      control: 600,
      attack: 450,
      harass: 500,
      strategy: 700,
      macro: 750,
      defense: 750,
      scout: 550,
    ),
    levelValue: 8,
    condition: 100,
  );

  setUp(() {
    service = MatchSimulationService();
  });

  test('PvP 5경기 시뮬레이션 (텍스트 확인)', () async {
    print('');
    print('=' * 70);
    print('PvP 5경기: 김공격(공격형 B+) vs 박운영(운영형 B+)');
    print('맵: 파이팅스피릿');
    print('=' * 70);

    int homeWins = 0;
    int awayWins = 0;

    for (int i = 0; i < 5; i++) {
      SimulationState? finalState;

      await for (final state in service.simulateMatchWithLog(
        homePlayer: attackProtoss,
        awayPlayer: defenseProtoss,
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
        print('--- 경기 ${i + 1} (${finalState.homeWin! ? "김공격 승" : "박운영 승"}) | ${finalState.battleLog.length}줄 ---');
        for (final entry in finalState.battleLogEntries) {
          final prefix = switch (entry.owner) {
            LogOwner.system => '[시스템]',
            LogOwner.home => '[홈-토스]',
            LogOwner.away => '[원정-토스]',
            LogOwner.clash => '[전투]',
          };
          print('  $prefix ${entry.text}');
        }
      }
    }

    print('');
    print('=' * 70);
    print('최종: 김공격 $homeWins승 | 박운영 $awayWins승');
    print('=' * 70);

    expect(homeWins + awayWins, 5);
  });
}
