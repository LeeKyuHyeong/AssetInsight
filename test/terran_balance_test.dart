// Terran matchup balance test - 200 simulations per matchup
// Tests: TvT (attacker vs defender), TvZ, TvP
// Run: flutter test test/terran_balance_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/domain/models/models.dart';
import 'package:mystar/domain/services/match_simulation_service.dart';

void main() {
  late MatchSimulationService service;
  const numSimulations = 200;

  final testMap = GameMap(
    id: 'test_balance_map',
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

  setUp(() {
    service = MatchSimulationService();
  });

  // ========== TvT: Attacker vs Defender ==========
  test('TvT Balance: Attacker(B+) vs Defender(B+) - $numSimulations games', () async {
    // Attacker-style Terran (B+ grade, high attack/harass/control)
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

    // Defender-style Terran (B+ grade, high strategy/macro/defense)
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

    // Verify same total stats
    final attackTotal = attackTerran.stats.total;
    final defenseTotal = defenseTerran.stats.total;
    print('');
    print('=' * 70);
    print('TvT BALANCE TEST: Attacker vs Defender ($numSimulations games)');
    print('Attacker total stats: $attackTotal');
    print('Defender total stats: $defenseTotal');
    print('Stat difference: ${attackTotal - defenseTotal}');
    print('=' * 70);

    int attackerWins = 0;
    int defenderWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: attackTerran,
        awayPlayer: defenseTerran,
        map: testMap,
      );
      if (result.homeWin) {
        attackerWins++;
      } else {
        defenderWins++;
      }
    }

    final attackerRate = (attackerWins / numSimulations * 100).toStringAsFixed(1);
    final defenderRate = (defenderWins / numSimulations * 100).toStringAsFixed(1);

    print('Results:');
    print('  Attacker wins: $attackerWins ($attackerRate%)');
    print('  Defender wins: $defenderWins ($defenderRate%)');
    print('');

    // Also test reversed (defender as home)
    int defHomeWins = 0;
    int atkAwayWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: defenseTerran,
        awayPlayer: attackTerran,
        map: testMap,
      );
      if (result.homeWin) {
        defHomeWins++;
      } else {
        atkAwayWins++;
      }
    }

    final defHomeRate = (defHomeWins / numSimulations * 100).toStringAsFixed(1);
    final atkAwayRate = (atkAwayWins / numSimulations * 100).toStringAsFixed(1);

    print('Reversed (Defender home):');
    print('  Defender wins: $defHomeWins ($defHomeRate%)');
    print('  Attacker wins: $atkAwayWins ($atkAwayRate%)');
    print('');

    // Combined
    final totalAttackerWins = attackerWins + atkAwayWins;
    final totalDefenderWins = defenderWins + defHomeWins;
    final totalGames = numSimulations * 2;
    final combinedAttackerRate = (totalAttackerWins / totalGames * 100).toStringAsFixed(1);
    final combinedDefenderRate = (totalDefenderWins / totalGames * 100).toStringAsFixed(1);

    print('Combined ($totalGames total games):');
    print('  Attacker total wins: $totalAttackerWins ($combinedAttackerRate%)');
    print('  Defender total wins: $totalDefenderWins ($combinedDefenderRate%)');
    print('=' * 70);

    // Balance check: neither side should dominate > 75%
    expect(attackerWins + defenderWins, numSimulations);
  });

  // ========== TvT: Same style (balanced vs balanced) ==========
  test('TvT Balance: Balanced(B+) vs Balanced(B+) - $numSimulations games', () async {
    final balancedTerran1 = Player(
      id: 'tvt_bal1',
      name: '김균형',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 620,
        control: 650,
        attack: 620,
        harass: 600,
        strategy: 640,
        macro: 630,
        defense: 620,
        scout: 600,
      ),
      levelValue: 8,
      condition: 100,
    );

    final balancedTerran2 = Player(
      id: 'tvt_bal2',
      name: '최균형',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 620,
        control: 650,
        attack: 620,
        harass: 600,
        strategy: 640,
        macro: 630,
        defense: 620,
        scout: 600,
      ),
      levelValue: 8,
      condition: 100,
    );

    print('');
    print('=' * 70);
    print('TvT MIRROR TEST: Balanced vs Balanced ($numSimulations games)');
    print('=' * 70);

    int homeWins = 0;
    int awayWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: balancedTerran1,
        awayPlayer: balancedTerran2,
        map: testMap,
      );
      if (result.homeWin) {
        homeWins++;
      } else {
        awayWins++;
      }
    }

    final homeRate = (homeWins / numSimulations * 100).toStringAsFixed(1);
    final awayRate = (awayWins / numSimulations * 100).toStringAsFixed(1);

    print('Results:');
    print('  Home wins: $homeWins ($homeRate%)');
    print('  Away wins: $awayWins ($awayRate%)');
    print('=' * 70);

    expect(homeWins + awayWins, numSimulations);
  });

  // ========== TvZ ==========
  test('TvZ Balance: Terran(B+) vs Zerg(B+) - $numSimulations games', () async {
    final terranPlayer = Player(
      id: 'tvz_terran',
      name: '이영호',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 700,
        control: 720,
        attack: 680,
        harass: 650,
        strategy: 700,
        macro: 680,
        defense: 650,
        scout: 600,
      ),
      levelValue: 8,
      condition: 100,
    );

    final zergPlayer = Player(
      id: 'tvz_zerg',
      name: '박성준',
      raceIndex: Race.zerg.index,
      stats: PlayerStats(
        sense: 680,
        control: 750,
        attack: 650,
        harass: 700,
        strategy: 680,
        macro: 720,
        defense: 600,
        scout: 650,
      ),
      levelValue: 8,
      condition: 100,
    );

    final terranTotal = terranPlayer.stats.total;
    final zergTotal = zergPlayer.stats.total;

    print('');
    print('=' * 70);
    print('TvZ BALANCE TEST ($numSimulations games)');
    print('Terran total stats: $terranTotal');
    print('Zerg total stats: $zergTotal');
    print('Map TvZ Terran WR: ${testMap.matchup.tvzTerranWinRate}%');
    print('=' * 70);

    int terranWins = 0;
    int zergWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: terranPlayer,
        awayPlayer: zergPlayer,
        map: testMap,
      );
      if (result.homeWin) {
        terranWins++;
      } else {
        zergWins++;
      }
    }

    final terranRate = (terranWins / numSimulations * 100).toStringAsFixed(1);
    final zergRate = (zergWins / numSimulations * 100).toStringAsFixed(1);

    print('Results (Terran home):');
    print('  Terran wins: $terranWins ($terranRate%)');
    print('  Zerg wins: $zergWins ($zergRate%)');

    // Also test reversed
    int zergHomeWins = 0;
    int terranAwayWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: zergPlayer,
        awayPlayer: terranPlayer,
        map: testMap,
      );
      if (result.homeWin) {
        zergHomeWins++;
      } else {
        terranAwayWins++;
      }
    }

    final zergHomeRate = (zergHomeWins / numSimulations * 100).toStringAsFixed(1);
    final terranAwayRate = (terranAwayWins / numSimulations * 100).toStringAsFixed(1);

    print('');
    print('Reversed (Zerg home):');
    print('  Zerg wins: $zergHomeWins ($zergHomeRate%)');
    print('  Terran wins: $terranAwayWins ($terranAwayRate%)');

    // Combined
    final totalTerranWins = terranWins + terranAwayWins;
    final totalZergWins = zergWins + zergHomeWins;
    final totalGames = numSimulations * 2;
    final combinedTerranRate = (totalTerranWins / totalGames * 100).toStringAsFixed(1);
    final combinedZergRate = (totalZergWins / totalGames * 100).toStringAsFixed(1);

    print('');
    print('Combined ($totalGames total games):');
    print('  Terran total wins: $totalTerranWins ($combinedTerranRate%)');
    print('  Zerg total wins: $totalZergWins ($combinedZergRate%)');
    print('=' * 70);

    expect(terranWins + zergWins, numSimulations);
  });

  // ========== TvP ==========
  test('TvP Balance: Terran(B+) vs Protoss(B+) - $numSimulations games', () async {
    final terranPlayer = Player(
      id: 'tvp_terran',
      name: '이영호',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 700,
        control: 720,
        attack: 680,
        harass: 650,
        strategy: 700,
        macro: 680,
        defense: 650,
        scout: 600,
      ),
      levelValue: 8,
      condition: 100,
    );

    final protossPlayer = Player(
      id: 'tvp_protoss',
      name: '김택용',
      raceIndex: Race.protoss.index,
      stats: PlayerStats(
        sense: 680,
        control: 750,
        attack: 650,
        harass: 700,
        strategy: 680,
        macro: 720,
        defense: 600,
        scout: 650,
      ),
      levelValue: 8,
      condition: 100,
    );

    final terranTotal = terranPlayer.stats.total;
    final protossTotal = protossPlayer.stats.total;

    print('');
    print('=' * 70);
    print('TvP BALANCE TEST ($numSimulations games)');
    print('Terran total stats: $terranTotal');
    print('Protoss total stats: $protossTotal');
    print('Map PvT Protoss WR: ${testMap.matchup.pvtProtossWinRate}%');
    print('=' * 70);

    int terranWins = 0;
    int protossWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: terranPlayer,
        awayPlayer: protossPlayer,
        map: testMap,
      );
      if (result.homeWin) {
        terranWins++;
      } else {
        protossWins++;
      }
    }

    final terranRate = (terranWins / numSimulations * 100).toStringAsFixed(1);
    final protossRate = (protossWins / numSimulations * 100).toStringAsFixed(1);

    print('Results (Terran home):');
    print('  Terran wins: $terranWins ($terranRate%)');
    print('  Protoss wins: $protossWins ($protossRate%)');

    // Also test reversed
    int protossHomeWins = 0;
    int terranAwayWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: protossPlayer,
        awayPlayer: terranPlayer,
        map: testMap,
      );
      if (result.homeWin) {
        protossHomeWins++;
      } else {
        terranAwayWins++;
      }
    }

    final protossHomeRate = (protossHomeWins / numSimulations * 100).toStringAsFixed(1);
    final terranAwayRate = (terranAwayWins / numSimulations * 100).toStringAsFixed(1);

    print('');
    print('Reversed (Protoss home):');
    print('  Protoss wins: $protossHomeWins ($protossHomeRate%)');
    print('  Terran wins: $terranAwayWins ($terranAwayRate%)');

    // Combined
    final totalTerranWins = terranWins + terranAwayWins;
    final totalProtossWins = protossWins + protossHomeWins;
    final totalGames = numSimulations * 2;
    final combinedTerranRate = (totalTerranWins / totalGames * 100).toStringAsFixed(1);
    final combinedProtossRate = (totalProtossWins / totalGames * 100).toStringAsFixed(1);

    print('');
    print('Combined ($totalGames total games):');
    print('  Terran total wins: $totalTerranWins ($combinedTerranRate%)');
    print('  Protoss total wins: $totalProtossWins ($combinedProtossRate%)');
    print('=' * 70);

    expect(terranWins + protossWins, numSimulations);
  });

  // ========== TvT: Grade mismatch (A vs C+) ==========
  test('TvT Grade mismatch: A-grade vs C+ grade - $numSimulations games', () async {
    // A-grade Terran
    final aGradeTerran = Player(
      id: 'tvt_a_grade',
      name: '에이급',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 800,
        control: 820,
        attack: 790,
        harass: 780,
        strategy: 810,
        macro: 800,
        defense: 780,
        scout: 750,
      ),
      levelValue: 12,
      condition: 100,
    );

    // C+ grade Terran
    final cGradeTerran = Player(
      id: 'tvt_c_grade',
      name: '하위급',
      raceIndex: Race.terran.index,
      stats: PlayerStats(
        sense: 450,
        control: 480,
        attack: 460,
        harass: 440,
        strategy: 470,
        macro: 450,
        defense: 460,
        scout: 430,
      ),
      levelValue: 4,
      condition: 100,
    );

    final aTotal = aGradeTerran.stats.total;
    final cTotal = cGradeTerran.stats.total;

    print('');
    print('=' * 70);
    print('TvT GRADE MISMATCH: A($aTotal) vs C+($cTotal) ($numSimulations games)');
    print('Level diff: ${aGradeTerran.levelValue} vs ${cGradeTerran.levelValue}');
    print('=' * 70);

    int aWins = 0;
    int cWins = 0;

    for (int i = 0; i < numSimulations; i++) {
      final result = service.simulateMatch(
        homePlayer: aGradeTerran,
        awayPlayer: cGradeTerran,
        map: testMap,
      );
      if (result.homeWin) {
        aWins++;
      } else {
        cWins++;
      }
    }

    final aRate = (aWins / numSimulations * 100).toStringAsFixed(1);
    final cRate = (cWins / numSimulations * 100).toStringAsFixed(1);

    print('Results:');
    print('  A-grade wins: $aWins ($aRate%)');
    print('  C+-grade wins: $cWins ($cRate%)');
    print('=' * 70);

    expect(aWins + cWins, numSimulations);
  });
}
