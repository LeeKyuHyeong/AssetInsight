// ZvZ 100경기 시뮬레이션 테스트
// 러시거리 짧고 복잡도 높은 맵에서 실행
//
// 실행: flutter test test/zvz_simulation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;

  // 러시거리 짧고(2) 복잡도 높은(9) 맵
  final testMap = GameMap(
    id: 'test_zvz_map',
    name: '테스트맵 (근거리+고복잡도)',
    rushDistance: 2,       // 매우 짧은 러시거리
    resources: 5,
    complexity: 9,         // 매우 높은 복잡도
    matchup: const RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 50,
    ),
    expansionCount: 3,
    terrainComplexity: 8,  // 높은 지형 복잡도
    airAccessibility: 5,
    centerImportance: 7,
    hasIsland: false,
  );

  // 선수 A: 공격형 저그 (Grade B+)
  final playerA = Player(
    id: 'zvz_attacker',
    name: '김공격',
    raceIndex: Race.zerg.index,
    stats: PlayerStats(
      sense: 650,
      control: 700,
      attack: 750,
      harass: 600,
      strategy: 550,
      macro: 500,
      defense: 450,
      scout: 500,
    ),
    levelValue: 8,
    condition: 100,
  );

  // 선수 B: 수비형 저그 (Grade B+, 비슷한 총합)
  final playerB = Player(
    id: 'zvz_defender',
    name: '이운영',
    raceIndex: Race.zerg.index,
    stats: PlayerStats(
      sense: 550,
      control: 600,
      attack: 500,
      harass: 500,
      strategy: 650,
      macro: 750,
      defense: 700,
      scout: 600,
    ),
    levelValue: 8,
    condition: 100,
  );

  // 선수 C: 저급 공격 저그 (Grade C+, 능력치 낮음)
  final playerC = Player(
    id: 'zvz_low_attacker',
    name: '박돌진',
    raceIndex: Race.zerg.index,
    stats: PlayerStats(
      sense: 450,
      control: 500,
      attack: 600,
      harass: 400,
      strategy: 350,
      macro: 350,
      defense: 300,
      scout: 350,
    ),
    levelValue: 4,
    condition: 100,
  );

  // 선수 D: 고급 운영 저그 (Grade A, 능력치 높음)
  final playerD = Player(
    id: 'zvz_high_defender',
    name: '최강자',
    raceIndex: Race.zerg.index,
    stats: PlayerStats(
      sense: 750,
      control: 800,
      attack: 700,
      harass: 700,
      strategy: 800,
      macro: 850,
      defense: 800,
      scout: 750,
    ),
    levelValue: 12,
    condition: 100,
  );

  setUp(() {
    service = MatchSimulationService();
  });

  group('ZvZ 100경기 시뮬레이션 (근거리+고복잡도 맵)', () {

    test('시나리오 1: 비슷한 등급 (공격형 vs 수비형) 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 1: 김공격(공격형 B+) vs 이운영(수비형 B+)');
      print('맵: 러시거리=2, 복잡도=9, 지형복잡도=8');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      final logSamples = <List<String>>[];
      int decisiveCount = 0;
      int armyZeroCount = 0;

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: playerA,
          awayPlayer: playerB,
          map: testMap,
          getIntervalMs: () => 0, // 딜레이 없음
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

          // 병력 0으로 끝난 경기 vs decisive로 끝난 경기 구분
          if (finalState.homeArmy <= 0 || finalState.awayArmy <= 0) {
            armyZeroCount++;
          } else {
            decisiveCount++;
          }

          // 처음 5경기 병력 상태 출력
          if (i < 5) {
            print('  [경기${i+1}] ${finalState.homeWin! ? "홈승" : "원정승"} | 홈병력=${finalState.homeArmy} 원정병력=${finalState.awayArmy} | 줄수=${finalState.battleLog.length}');
          }

          // 처음 3경기 로그 저장
          if (logSamples.length < 3) {
            logSamples.add(finalState.battleLog);
          }
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('김공격 승: $homeWins  |  이운영 승: $awayWins');
      print('김공격 승률: ${winRate.toStringAsFixed(1)}%');
      print('기대 승률: ~50% (비슷한 등급, 빌드 상성에 따라 변동)');
      print('decisive 종료: $decisiveCount | 병력0 종료: $armyZeroCount');

      // 샘플 로그 출력
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

    test('시나리오 2: 큰 등급차 (저급 공격 vs 고급 운영) 100경기', () async {
      print('');
      print('=' * 70);
      print('시나리오 2: 박돌진(공격형 C+) vs 최강자(수비형 A)');
      print('맵: 러시거리=2, 복잡도=9, 지형복잡도=8');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      int upsetCount = 0;
      final logSamples = <List<String>>[];

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: playerC,
          awayPlayer: playerD,
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
            // 이변 경기 로그 저장 (최대 3개)
            if (logSamples.length < 3) {
              logSamples.add(finalState.battleLog);
            }
          } else {
            awayWins++;
          }
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      print('');
      print('--- 결과 ---');
      print('박돌진 승: $homeWins  |  최강자 승: $awayWins');
      print('박돌진(저급) 승률: ${winRate.toStringAsFixed(1)}%');
      print('이변 횟수: $upsetCount / 100');
      print('기대: 저급 측 3~10% 승률');

      // 이변 경기 로그 출력
      if (logSamples.isNotEmpty) {
        print('');
        print('--- 이변 경기 로그 ---');
        for (int i = 0; i < logSamples.length; i++) {
          print('');
          print('[이변 ${i + 1}] (${logSamples[i].length}줄)');
          for (final line in logSamples[i]) {
            print('  $line');
          }
        }
      } else {
        print('');
        print('이변 없음 (100경기 모두 고급 선수 승리)');
      }

      print('');
      expect(homeWins + awayWins, 100);
    });

    test('시나리오 3: 동일 선수 미러 100경기 (순수 랜덤 확인)', () async {
      print('');
      print('=' * 70);
      print('시나리오 3: 김공격 vs 김공격 (미러매치)');
      print('맵: 러시거리=2, 복잡도=9, 지형복잡도=8');
      print('=' * 70);

      int homeWins = 0;
      int awayWins = 0;
      int totalLogLines = 0;
      int shortGames = 0; // 30줄 이하 (빠른 GG)
      int longGames = 0;  // 100줄 이상 (장기전)

      // 미러용 선수 (같은 스탯, 다른 이름)
      final playerA2 = Player(
        id: 'zvz_mirror',
        name: '김공격B',
        raceIndex: Race.zerg.index,
        stats: PlayerStats(
          sense: 650,
          control: 700,
          attack: 750,
          harass: 600,
          strategy: 550,
          macro: 500,
          defense: 450,
          scout: 500,
        ),
        levelValue: 8,
        condition: 100,
      );

      // winRate 디버그: 10번 계산해서 분포 확인
      final winRates = <double>[];
      for (int i = 0; i < 10; i++) {
        final wr = service.calculateWinRate(
          homePlayer: playerA,
          awayPlayer: playerA2,
          map: testMap,
        );
        winRates.add(wr);
      }
      print('winRate 샘플 (10회): ${winRates.map((w) => '${(w * 100).toStringAsFixed(1)}%').join(', ')}');

      final sampleLogs = <List<String>>[];

      for (int i = 0; i < 100; i++) {
        SimulationState? finalState;

        await for (final state in service.simulateMatchWithLog(
          homePlayer: playerA,
          awayPlayer: playerA2,
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
            // 원정 승리 로그 저장 (최대 2개)
            if (sampleLogs.length < 2) {
              sampleLogs.add(finalState.battleLog);
            }
          }
          final lines = finalState.battleLog.length;
          totalLogLines += lines;
          if (lines <= 30) shortGames++;
          if (lines >= 100) longGames++;
        }
      }

      final winRate = homeWins / (homeWins + awayWins) * 100;
      final avgLines = totalLogLines / 100;
      print('');
      print('--- 결과 ---');
      print('홈 승: $homeWins  |  원정 승: $awayWins');
      print('홈 승률: ${winRate.toStringAsFixed(1)}% (기대: ~50%)');
      print('평균 로그 줄 수: ${avgLines.toStringAsFixed(1)}');
      print('빠른 GG (≤30줄): $shortGames경기');
      print('장기전 (≥100줄): $longGames경기');

      if (sampleLogs.isNotEmpty) {
        for (int i = 0; i < sampleLogs.length; i++) {
          print('');
          print('--- 원정 승리 경기 ${i + 1} (${sampleLogs[i].length}줄) ---');
          for (final line in sampleLogs[i]) {
            print('  $line');
          }
        }
      }

      print('');
      expect(homeWins + awayWins, 100);
    });
  });
}
