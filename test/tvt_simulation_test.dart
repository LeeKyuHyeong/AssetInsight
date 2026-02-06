// TvT 100경기 시뮬레이션 테스트
// 다양한 맵/선수 조합으로 실행
//
// 실행: flutter test test/tvt_simulation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;

  // 맵 1: 일반적인 TvT 맵 (중거리, 중간 복잡도)
  final testMap = GameMap(
    id: 'test_tvt_map',
    name: '파이팅스피릿 (중거리)',
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

  // 맵 2: 근거리 맵 (러쉬 유리)
  final rushMap = GameMap(
    id: 'test_tvt_rush',
    name: '블리츠 (근거리)',
    rushDistance: 2,
    resources: 4,
    complexity: 8,
    matchup: const RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 50,
    ),
    expansionCount: 2,
    terrainComplexity: 8,
    airAccessibility: 4,
    centerImportance: 8,
    hasIsland: false,
  );

  // 선수 A: 공격형 테란 (Grade B+) - 벌쳐/드랍 스타일
  final attackTerran = Player(
    id: 'tvt_attacker',
    name: '이공격',
    raceIndex: Race.terran.index,
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

  // 선수 B: 운영형 테란 (Grade B+) - 메카닉/시즈 스타일
  final defenseTerran = Player(
    id: 'tvt_defender',
    name: '박운영',
    raceIndex: Race.terran.index,
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

  // 선수 C: 저급 테란 (Grade C)
  final lowTerran = Player(
    id: 'tvt_low',
    name: '김신인',
    raceIndex: Race.terran.index,
    stats: PlayerStats(
      sense: 400,
      control: 450,
      attack: 500,
      harass: 400,
      strategy: 350,
      macro: 350,
      defense: 300,
      scout: 300,
    ),
    levelValue: 3,
    condition: 100,
  );

  // 선수 D: 고급 테란 (Grade A) - 올라운드
  final highTerran = Player(
    id: 'tvt_high',
    name: '최프로',
    raceIndex: Race.terran.index,
    stats: PlayerStats(
      sense: 800,
      control: 780,
      attack: 750,
      harass: 720,
      strategy: 800,
      macro: 830,
      defense: 780,
      scout: 750,
    ),
    levelValue: 12,
    condition: 100,
  );

  setUp(() {
    service = MatchSimulationService();
  });

  group('TvT 100경기 시뮬레이션', () {

    test('시나리오 1: 비슷한 등급 (공격형 vs 운영형) 중거리맵 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 1: 이공격(공격형 B+) vs 박운영(운영형 B+)');
      print('맵: 파이팅스피릿 (러시거리=5, 복잡도=6)');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      final logSamples = <List<String>>[];
      int totalLines = 0;
      int shortGames = 0;
      int longGames = 0;

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: attackTerran,
          awayPlayer: defenseTerran,
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
          if (lines <= 30) shortGames++;
          if (lines >= 100) longGames++;

          if (i < 5) {
            print('  [경기${i+1}] ${finalState.homeWin! ? "홈승" : "원정승"} | 홈병력=${finalState.homeArmy} 원정병력=${finalState.awayArmy} | ${lines}줄');
          }

          if (logSamples.length < 3) {
            logSamples.add(finalState.battleLog);
          }
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('이공격 승: $homeWins  |  박운영 승: $awayWins');
      print('이공격 승률: ${winRate.toStringAsFixed(1)}%');
      print('기대 승률: ~50% (비슷한 등급)');
      print('평균 로그 줄 수: ${(totalLines / 100).toStringAsFixed(1)}');
      print('빠른 GG (≤30줄): $shortGames경기 | 장기전 (≥100줄): $longGames경기');

      for (int i = 0; i < logSamples.length; i++) {
        print('');
        print('--- 경기 ${i + 1} 로그 (${logSamples[i].length}줄) ---');
        for (final line in logSamples[i]) {
          print('  $line');
        }
      }

      print('');
      expect(homeWins + awayWins, 100);
    });

    test('시나리오 2: 큰 등급차 (저급 vs 고급) 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 2: 김신인(C급) vs 최프로(A급)');
      print('맵: 파이팅스피릿 (러시거리=5, 복잡도=6)');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      int upsetCount = 0;
      final upsetLogs = <List<String>>[];

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: lowTerran,
          awayPlayer: highTerran,
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
            upsetCount++;
            if (upsetLogs.length < 3) {
              upsetLogs.add(finalState.battleLog);
            }
          } else {
            awayWins++;
          }
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('김신인 승: $homeWins  |  최프로 승: $awayWins');
      print('김신인(저급) 승률: ${winRate.toStringAsFixed(1)}%');
      print('이변 횟수: $upsetCount / 100');
      print('기대: 저급 측 3~15% 승률');

      if (upsetLogs.isNotEmpty) {
        print('');
        print('--- 이변 경기 로그 ---');
        for (int i = 0; i < upsetLogs.length; i++) {
          print('');
          print('[이변 ${i + 1}] (${upsetLogs[i].length}줄)');
          for (final line in upsetLogs[i]) {
            print('  $line');
          }
        }
      }

      print('');
      expect(homeWins + awayWins, 100);
    });

    test('시나리오 3: 동일 선수 미러 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 3: 이공격 vs 이공격 (미러매치)');
      print('맵: 파이팅스피릿 (러시거리=5, 복잡도=6)');
      print('=' * 70);

      // 동일 선수 미러 (이름만 다르게)
      final mirrorPlayer = Player(
        id: 'tvt_mirror_b',
        name: '이공격B',
        raceIndex: Race.terran.index,
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

      // winRate 확인
      final sampleRates = <double>[];
      for (int i = 0; i < 10; i++) {
        final wr = service.calculateWinRate(
          homePlayer: attackTerran,
          awayPlayer: mirrorPlayer,
          map: testMap,
        );
        sampleRates.add(wr);
      }
      print('winRate 샘플 (10회): ${sampleRates.map((r) => '${(r * 100).toStringAsFixed(1)}%').join(', ')}');

      int homeWins = 0;
      int awayWins = 0;
      int totalLines = 0;
      int shortGames = 0;
      int longGames = 0;
      final awayWinLogs = <List<String>>[];

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: attackTerran,
          awayPlayer: mirrorPlayer,
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
            if (awayWinLogs.length < 2) {
              awayWinLogs.add(finalState.battleLog);
            }
          }

          final lines = finalState.battleLog.length;
          totalLines += lines;
          if (lines <= 30) shortGames++;
          if (lines >= 100) longGames++;
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('홈 승: $homeWins  |  원정 승: $awayWins');
      print('홈 승률: ${winRate.toStringAsFixed(1)}% (기대: ~50%)');
      print('평균 로그 줄 수: ${(totalLines / 100).toStringAsFixed(1)}');
      print('빠른 GG (≤30줄): $shortGames경기 | 장기전 (≥100줄): $longGames경기');

      for (int i = 0; i < awayWinLogs.length; i++) {
        print('');
        print('--- 원정 승리 경기 ${i + 1} (${awayWinLogs[i].length}줄) ---');
        for (final line in awayWinLogs[i]) {
          print('  $line');
        }
      }

      print('');
      expect(homeWins + awayWins, 100);
    });

    test('시나리오 4: 공격형 vs 운영형 근거리맵 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 4: 이공격(공격형 B+) vs 박운영(운영형 B+)');
      print('맵: 블리츠 (러시거리=2, 복잡도=8) - 근거리 맵');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      int totalLines = 0;
      int shortGames = 0;
      int longGames = 0;

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: attackTerran,
          awayPlayer: defenseTerran,
          map: rushMap,
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
          if (lines <= 30) shortGames++;
          if (lines >= 100) longGames++;
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('이공격 승: $homeWins  |  박운영 승: $awayWins');
      print('이공격 승률: ${winRate.toStringAsFixed(1)}%');
      print('기대 승률: 공격형이 근거리맵에서 약간 유리 (~55-60%)');
      print('평균 로그 줄 수: ${(totalLines / 100).toStringAsFixed(1)}');
      print('빠른 GG (≤30줄): $shortGames경기 | 장기전 (≥100줄): $longGames경기');

      print('');
      expect(homeWins + awayWins, 100);
    });
  });
}
