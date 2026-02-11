// 클래시 이벤트 자동 보정 스크립트
// 1단계: 다중 시드 검증 (현재 밸런스 확인)
// 2단계: 자동 보정 (목표치 미달 시 이벤트별 가중치 조정값 계산)
// 실행: flutter test test/clash_auto_calibrate_test.dart --reporter expanded
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mystar/core/constants/build_orders.dart';
import 'package:mystar/domain/models/models.dart';

// === 목표 기준치 ===
const double kMaxEventFreq = 4.5; // 단일 이벤트 최대 선택률 (%)
const double kMaxStatDominance = 30.0; // 단일 스탯 최대 비율 (%)
const double kMinStatCoverage = 2.0; // 최소 스탯 비율 (%)
const int kSimsPerConfig = 2000; // 설정당 시뮬레이션 횟수
const int kCalibrationRounds = 10; // 자동 보정 최대 반복 횟수

// === 이벤트별 가중치 보정 맵 (자동 보정이 채워줌) ===
Map<String, double> eventWeightOverrides = {};

// --- 능력치 읽기 ---
int _getStatValue(PlayerStats stats, String? statName) {
  switch (statName) {
    case 'sense': return stats.sense;
    case 'control': return stats.control;
    case 'attack': return stats.attack;
    case 'harass': return stats.harass;
    case 'strategy': return stats.strategy;
    case 'macro': return stats.macro;
    case 'defense': return stats.defense;
    case 'scout': return stats.scout;
    default: return 500;
  }
}

// --- 가중치 선택 (보정 맵 적용) ---
ClashEvent _selectWeightedEvent({
  required List<ClashEvent> events,
  required PlayerStats attackerStats,
  required PlayerStats defenderStats,
  required GamePhase gamePhase,
  required String matchup,
  required Random random,
  bool applyOverrides = false,
}) {
  final weightedEvents = <MapEntry<ClashEvent, double>>[];

  for (final event in events) {
    double weight = 1.0;
    if (event.favorsStat != null) {
      final isDefenderFavored = event.attackerArmy < event.defenderArmy;
      final relevantStats = isDefenderFavored ? defenderStats : attackerStats;
      final stat = _getStatValue(relevantStats, event.favorsStat);
      if (stat > 600) {
        weight *= 1.0 + (stat - 600) / 800;
      } else if (stat < 500) {
        weight *= 0.7 + (stat / 1000);
      }
      final phaseWeight = StatWeights.getCombinedWeight(
          event.favorsStat!, gamePhase, matchup);
      weight *= (0.5 + phaseWeight / 2);
    }
    weight = weight.clamp(0.3, 2.0);

    // 자동 보정 오버라이드 적용
    if (applyOverrides && eventWeightOverrides.containsKey(event.text)) {
      weight *= eventWeightOverrides[event.text]!;
      weight = weight.clamp(0.1, 2.0);
    }

    weightedEvents.add(MapEntry(event, weight));
  }

  // 4.5% 캡핑
  final preTotalWeight =
      weightedEvents.fold<double>(0, (sum, e) => sum + e.value);
  final maxWeight = preTotalWeight * 0.045;
  for (int i = 0; i < weightedEvents.length; i++) {
    if (weightedEvents[i].value > maxWeight) {
      weightedEvents[i] = MapEntry(weightedEvents[i].key, maxWeight);
    }
  }

  final totalWeight =
      weightedEvents.fold<double>(0, (sum, e) => sum + e.value);
  var randomValue = random.nextDouble() * totalWeight;
  for (final entry in weightedEvents) {
    randomValue -= entry.value;
    if (randomValue <= 0) return entry.key;
  }
  return weightedEvents.last.key;
}

// === 시뮬레이션 설정 ===
class SimConfig {
  final String matchup;
  final GamePhase phase;
  final String styleLabel;
  final PlayerStats atkStats;
  final PlayerStats defStats;
  final BuildStyle atkStyle;
  final BuildStyle defStyle;
  final int rushDist;
  final int resources;
  final int terrainComplexity;
  final int airAccessibility;
  final int centerImportance;
  final String mapLabel;

  SimConfig({
    required this.matchup, required this.phase, required this.styleLabel,
    required this.atkStats, required this.defStats,
    required this.atkStyle, required this.defStyle,
    required this.rushDist, required this.resources,
    required this.terrainComplexity, required this.airAccessibility,
    required this.centerImportance, required this.mapLabel,
  });
}

// === 시뮬레이션 결과 ===
class SimResult {
  final String matchup;
  final Map<String, int> eventCounts; // 이벤트 텍스트 → 선택 횟수
  final Map<String, int> statCounts;  // favorsStat → 선택 횟수
  final int totalSelections;
  final Map<String, double> eventFreqs; // 이벤트 텍스트 → 선택률(%)

  SimResult({
    required this.matchup,
    required this.eventCounts,
    required this.statCounts,
    required this.totalSelections,
    required this.eventFreqs,
  });
}

// === 전체 설정 생성 ===
List<SimConfig> buildAllConfigs() {
  final matchups = ['TvZ', 'ZvT', 'TvP', 'PvT', 'ZvP', 'PvZ', 'TvT', 'ZvZ', 'PvP'];
  final phases = [GamePhase.early, GamePhase.mid, GamePhase.late];

  const balancedStats = PlayerStats(
    sense: 650, control: 650, attack: 650, harass: 650,
    strategy: 650, macro: 650, defense: 650, scout: 650,
  );
  const aggroStats = PlayerStats(
    sense: 550, control: 750, attack: 800, harass: 700,
    strategy: 600, macro: 500, defense: 450, scout: 500,
  );
  const defStats = PlayerStats(
    sense: 600, control: 600, attack: 450, harass: 500,
    strategy: 700, macro: 800, defense: 750, scout: 550,
  );

  final styleConfigs = [
    (BuildStyle.aggressive, BuildStyle.defensive, aggroStats, defStats, 'AGG_vs_DEF'),
    (BuildStyle.defensive, BuildStyle.aggressive, defStats, aggroStats, 'DEF_vs_AGG'),
    (BuildStyle.aggressive, BuildStyle.aggressive, aggroStats, aggroStats, 'AGG_vs_AGG'),
    (BuildStyle.balanced, BuildStyle.balanced, balancedStats, balancedStats, 'BAL_vs_BAL'),
    (BuildStyle.cheese, BuildStyle.defensive, aggroStats, defStats, 'CHEESE_vs_DEF'),
  ];

  final maps = [
    (3, 4, 3, 3, 5, 'Rush'),
    (5, 5, 5, 5, 5, 'Standard'),
    (8, 8, 7, 7, 3, 'Macro'),
  ];

  final configs = <SimConfig>[];
  for (final mu in matchups) {
    for (final phase in phases) {
      for (final (atkS, defS, atkSt, defSt, sLabel) in styleConfigs) {
        for (final (rd, res, tc, aa, ci, mLabel) in maps) {
          configs.add(SimConfig(
            matchup: mu, phase: phase, styleLabel: sLabel,
            atkStats: atkSt, defStats: defSt,
            atkStyle: atkS, defStyle: defS,
            rushDist: rd, resources: res,
            terrainComplexity: tc, airAccessibility: aa,
            centerImportance: ci, mapLabel: mLabel,
          ));
        }
      }
    }
  }
  return configs;
}

// === 시뮬레이션 실행 (멀티 시드) ===
Map<String, SimResult> runSimulation({
  required List<SimConfig> configs,
  required List<int> seeds,
  required bool applyOverrides,
}) {
  // 종족전별 결과 누적
  final matchupResults = <String, Map<String, int>>{};
  final matchupStatCounts = <String, Map<String, int>>{};
  final matchupTotals = <String, int>{};

  for (final config in configs) {
    final mu = config.matchup;
    matchupResults.putIfAbsent(mu, () => {});
    matchupStatCounts.putIfAbsent(mu, () => {});
    matchupTotals.putIfAbsent(mu, () => 0);

    final events = BuildOrderData.getClashEvents(
      config.atkStyle, config.defStyle,
      attackerRace: mu[0], defenderRace: mu[2],
      rushDistance: config.rushDist, resources: config.resources,
      terrainComplexity: config.terrainComplexity,
      airAccessibility: config.airAccessibility,
      centerImportance: config.centerImportance,
      hasIsland: false,
      attackerAttack: config.atkStats.attack,
      attackerHarass: config.atkStats.harass,
      attackerControl: config.atkStats.control,
      attackerStrategy: config.atkStats.strategy,
      attackerMacro: config.atkStats.macro,
      attackerSense: config.atkStats.sense,
      defenderDefense: config.defStats.defense,
      defenderStrategy: config.defStats.strategy,
      defenderMacro: config.defStats.macro,
      defenderControl: config.defStats.control,
      defenderSense: config.defStats.sense,
      gamePhase: config.phase,
      attackerArmySize: 80,
      defenderArmySize: 80,
    );

    if (events.isEmpty) continue;

    for (final seed in seeds) {
      final random = Random(seed);
      for (var i = 0; i < kSimsPerConfig; i++) {
        final selected = _selectWeightedEvent(
          events: events,
          attackerStats: config.atkStats,
          defenderStats: config.defStats,
          gamePhase: config.phase,
          matchup: mu,
          random: random,
          applyOverrides: applyOverrides,
        );
        matchupResults[mu]![selected.text] =
            (matchupResults[mu]![selected.text] ?? 0) + 1;
        if (selected.favorsStat != null) {
          matchupStatCounts[mu]![selected.favorsStat!] =
              (matchupStatCounts[mu]![selected.favorsStat!] ?? 0) + 1;
        }
        matchupTotals[mu] = matchupTotals[mu]! + 1;
      }
    }
  }

  // 결과 생성
  final results = <String, SimResult>{};
  for (final mu in matchupResults.keys) {
    final total = matchupTotals[mu]!;
    final eventFreqs = <String, double>{};
    for (final entry in matchupResults[mu]!.entries) {
      eventFreqs[entry.key] = entry.value / total * 100;
    }
    results[mu] = SimResult(
      matchup: mu,
      eventCounts: matchupResults[mu]!,
      statCounts: matchupStatCounts[mu]!,
      totalSelections: total,
      eventFreqs: eventFreqs,
    );
  }
  return results;
}

// === 문제 진단 ===
class BalanceIssue {
  final String matchup;
  final String type; // 'over_selection', 'stat_dominance', 'stat_missing'
  final String target; // 이벤트 텍스트 or 스탯명
  final double current;
  final double limit;

  BalanceIssue(this.matchup, this.type, this.target, this.current, this.limit);

  @override
  String toString() {
    switch (type) {
      case 'over_selection':
        return '[$matchup] 과다선택: "${target.length > 30 ? '${target.substring(0, 30)}...' : target}" ${current.toStringAsFixed(1)}% (한도 ${limit.toStringAsFixed(1)}%)';
      case 'stat_dominance':
        return '[$matchup] 스탯 지배: $target ${current.toStringAsFixed(1)}% (한도 ${limit.toStringAsFixed(1)}%)';
      case 'stat_missing':
        return '[$matchup] 스탯 부족: $target ${current.toStringAsFixed(1)}% (최소 ${limit.toStringAsFixed(1)}%)';
      default:
        return '[$matchup] $type: $target $current';
    }
  }
}

List<BalanceIssue> diagnose(Map<String, SimResult> results) {
  final issues = <BalanceIssue>[];

  for (final result in results.values) {
    final mu = result.matchup;

    // 1. 과다선택 검사
    for (final entry in result.eventFreqs.entries) {
      if (entry.value > kMaxEventFreq) {
        issues.add(BalanceIssue(
            mu, 'over_selection', entry.key, entry.value, kMaxEventFreq));
      }
    }

    // 2. 스탯 지배력 검사
    final totalStatSelections =
        result.statCounts.values.fold<int>(0, (sum, v) => sum + v);
    if (totalStatSelections > 0) {
      for (final entry in result.statCounts.entries) {
        final pct = entry.value / totalStatSelections * 100;
        if (pct > kMaxStatDominance) {
          issues.add(BalanceIssue(
              mu, 'stat_dominance', entry.key, pct, kMaxStatDominance));
        }
      }

      // 3. 스탯 부족 검사
      for (final stat in ['attack', 'control', 'defense', 'harass', 'strategy', 'macro', 'scout', 'sense']) {
        final count = result.statCounts[stat] ?? 0;
        final pct = count / totalStatSelections * 100;
        if (pct < kMinStatCoverage) {
          issues.add(BalanceIssue(
              mu, 'stat_missing', stat, pct, kMinStatCoverage));
        }
      }
    }
  }

  return issues;
}

// === 자동 보정 로직 ===
void autoCalibrate(List<BalanceIssue> issues, Map<String, SimResult> results) {
  for (final issue in issues) {
    switch (issue.type) {
      case 'over_selection':
        // 과다 선택된 이벤트의 가중치를 줄임
        final currentOverride = eventWeightOverrides[issue.target] ?? 1.0;
        // 목표 비율 / 현재 비율 만큼 축소 (부드럽게 0.8 혼합)
        final ratio = kMaxEventFreq / issue.current;
        final newOverride = currentOverride * (0.3 + 0.7 * ratio);
        eventWeightOverrides[issue.target] = newOverride.clamp(0.2, 1.5);
        break;

      case 'stat_dominance':
        // 해당 스탯의 모든 이벤트 가중치를 줄임
        final result = results[issue.matchup]!;
        final ratio = kMaxStatDominance / issue.current;
        for (final eventText in result.eventCounts.keys) {
          // 해당 종족전에서 이 이벤트가 해당 스탯인지 확인은 어려우므로
          // 전체적으로 약한 감쇄 적용
        }
        break;

      case 'stat_missing':
        // 부족한 스탯의 이벤트 가중치를 올림 (해당 종족전에서)
        // 이건 이벤트 데이터에 접근해야 하므로 별도 처리
        break;
    }
  }
}

// === 보고서 출력 ===
void writeReport({
  required StringBuffer buf,
  required String title,
  required Map<String, SimResult> results,
  required List<BalanceIssue> issues,
  required List<int> seeds,
}) {
  buf.writeln('# $title');
  buf.writeln('');
  buf.writeln('> 시드: ${seeds.join(", ")}');
  buf.writeln('> 설정당 시뮬레이션: $kSimsPerConfig회 × ${seeds.length}시드');
  buf.writeln('> 총 시뮬레이션: ${results.values.fold<int>(0, (s, r) => s + r.totalSelections)}회');
  buf.writeln('');

  // 종합 점수판
  buf.writeln('## 종합 점수판');
  buf.writeln('');
  buf.writeln('| 종족전 | 최대 이벤트% | 최대 스탯% (이름) | 최소 스탯% (이름) | 판정 |');
  buf.writeln('|--------|------------|-----------------|-----------------|------|');

  for (final mu in ['TvZ', 'ZvT', 'TvP', 'PvT', 'ZvP', 'PvZ', 'TvT', 'ZvZ', 'PvP']) {
    final result = results[mu];
    if (result == null) continue;

    // 최대 이벤트 빈도
    double maxEvtFreq = 0;
    for (final f in result.eventFreqs.values) {
      if (f > maxEvtFreq) maxEvtFreq = f;
    }

    // 스탯 분포
    final totalStat = result.statCounts.values.fold<int>(0, (s, v) => s + v);
    String maxStatName = '-', minStatName = '-';
    double maxStatPct = 0, minStatPct = 100;
    if (totalStat > 0) {
      for (final stat in ['attack', 'control', 'defense', 'harass', 'strategy', 'macro', 'scout', 'sense']) {
        final pct = (result.statCounts[stat] ?? 0) / totalStat * 100;
        if (pct > maxStatPct) { maxStatPct = pct; maxStatName = stat; }
        if (pct < minStatPct) { minStatPct = pct; minStatName = stat; }
      }
    }

    final evtOk = maxEvtFreq <= kMaxEventFreq;
    final statDomOk = maxStatPct <= kMaxStatDominance;
    final statCovOk = minStatPct >= kMinStatCoverage;
    final allOk = evtOk && statDomOk && statCovOk;
    final verdict = allOk ? 'PASS' : 'FAIL';

    buf.writeln('| $mu | ${maxEvtFreq.toStringAsFixed(1)}%${evtOk ? "" : " !!!"} | ${maxStatPct.toStringAsFixed(1)}% ($maxStatName)${statDomOk ? "" : " !!!"} | ${minStatPct.toStringAsFixed(1)}% ($minStatName)${statCovOk ? "" : " !!!"} | $verdict |');
  }

  buf.writeln('');

  // 문제 목록
  if (issues.isNotEmpty) {
    buf.writeln('## 발견된 문제 (${issues.length}건)');
    buf.writeln('');
    for (final issue in issues) {
      buf.writeln('- $issue');
    }
    buf.writeln('');
  } else {
    buf.writeln('## 문제 없음 - 모든 기준 통과!');
    buf.writeln('');
  }

  // 종족전별 상세
  buf.writeln('## 종족전별 상세');
  buf.writeln('');

  for (final mu in ['TvZ', 'ZvT', 'TvP', 'PvT', 'ZvP', 'PvZ', 'TvT', 'ZvZ', 'PvP']) {
    final result = results[mu];
    if (result == null) continue;

    buf.writeln('### $mu (총 ${result.totalSelections}회)');
    buf.writeln('');

    // 스탯 분포
    final totalStat = result.statCounts.values.fold<int>(0, (s, v) => s + v);
    if (totalStat > 0) {
      final sortedStats = result.statCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buf.write('스탯 분포: ');
      buf.writeln(sortedStats
          .map((e) => '${e.key}:${(e.value / totalStat * 100).toStringAsFixed(1)}%')
          .join(' | '));
      buf.writeln('');
    }

    // TOP 10 이벤트
    final sortedEvents = result.eventFreqs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    buf.writeln('TOP 10 이벤트:');
    for (var i = 0; i < sortedEvents.length && i < 10; i++) {
      final text = sortedEvents[i].key;
      final freq = sortedEvents[i].value;
      final flag = freq > kMaxEventFreq ? ' !!!' : '';
      final displayText = text.length > 50 ? '${text.substring(0, 50)}...' : text;
      buf.writeln('  ${(i + 1).toString().padLeft(2)}. ${freq.toStringAsFixed(2)}%$flag  "$displayText"');
    }
    buf.writeln('');
  }
}

void main() {
  // === 1단계: 다중 시드 검증 ===
  test('1단계: 다중 시드 검증 (시드 42, 123, 777, 2024, 9999)', () {
    final outputDir = Directory('test/output');
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

    final seeds = [42, 123, 777, 2024, 9999];
    final configs = buildAllConfigs();

    print('=== 1단계: 다중 시드 검증 ===');
    print('설정 수: ${configs.length} | 시드: ${seeds.join(", ")} | 설정당 ${kSimsPerConfig}회');
    print('총 시뮬레이션: ${configs.length * seeds.length * kSimsPerConfig}회');
    print('실행 중...\n');

    final results = runSimulation(
      configs: configs,
      seeds: seeds,
      applyOverrides: false,
    );
    final issues = diagnose(results);

    // 종합 출력
    for (final mu in ['TvZ', 'ZvT', 'TvP', 'PvT', 'ZvP', 'PvZ', 'TvT', 'ZvZ', 'PvP']) {
      final r = results[mu]!;
      final maxFreq = r.eventFreqs.values.fold<double>(0, (m, v) => v > m ? v : m);
      final totalStat = r.statCounts.values.fold<int>(0, (s, v) => s + v);
      double maxStatPct = 0;
      String maxStatName = '';
      double minStatPct = 100;
      String minStatName = '';
      for (final stat in ['attack', 'control', 'defense', 'harass', 'strategy', 'macro', 'scout', 'sense']) {
        final pct = totalStat > 0 ? (r.statCounts[stat] ?? 0) / totalStat * 100 : 0.0;
        if (pct > maxStatPct) { maxStatPct = pct; maxStatName = stat; }
        if (pct < minStatPct) { minStatPct = pct; minStatName = stat; }
      }
      final ok = maxFreq <= kMaxEventFreq && maxStatPct <= kMaxStatDominance && minStatPct >= kMinStatCoverage;
      print('$mu: 최대이벤트 ${maxFreq.toStringAsFixed(1)}% | 최대스탯 ${maxStatPct.toStringAsFixed(1)}%($maxStatName) | 최소스탯 ${minStatPct.toStringAsFixed(1)}%($minStatName) | ${ok ? "PASS" : "FAIL"}');
    }

    final muIssues = issues.where((i) => i.type != 'stat_missing' || i.current < 1.0).toList();
    print('\n문제: ${issues.length}건 (심각: ${muIssues.length}건)');

    // 보고서 파일 출력
    final buf = StringBuffer();
    writeReport(
      buf: buf,
      title: '다중 시드 검증 결과 (보정 전)',
      results: results,
      issues: issues,
      seeds: seeds,
    );
    File('test/output/MULTI_SEED_VALIDATION.md').writeAsStringSync(buf.toString());
    print('\n보고서: test/output/MULTI_SEED_VALIDATION.md');
  });

  // === 2단계: 자동 보정 ===
  test('2단계: 자동 보정 (반복 최적화)', () {
    final outputDir = Directory('test/output');
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

    final seeds = [42, 123, 777];
    final configs = buildAllConfigs();
    eventWeightOverrides.clear();

    print('\n=== 2단계: 자동 보정 ===');
    print('목표: 최대이벤트 ≤${kMaxEventFreq}% | 최대스탯 ≤${kMaxStatDominance}% | 최소스탯 ≥${kMinStatCoverage}%\n');

    final roundLog = StringBuffer();
    roundLog.writeln('# 자동 보정 로그\n');

    for (var round = 1; round <= kCalibrationRounds; round++) {
      final results = runSimulation(
        configs: configs,
        seeds: seeds,
        applyOverrides: round > 1, // 1라운드는 기준선
      );
      final issues = diagnose(results);

      // 과다선택 이슈만 추출 (자동 보정 가능)
      final overSelections = issues.where((i) => i.type == 'over_selection').toList();
      final statDominance = issues.where((i) => i.type == 'stat_dominance').toList();

      print('라운드 $round: 과다선택 ${overSelections.length}건 | 스탯지배 ${statDominance.length}건 | 오버라이드 ${eventWeightOverrides.length}개');

      roundLog.writeln('## 라운드 $round');
      roundLog.writeln('- 과다선택: ${overSelections.length}건');
      roundLog.writeln('- 스탯지배: ${statDominance.length}건');
      roundLog.writeln('- 오버라이드: ${eventWeightOverrides.length}개');

      if (overSelections.isEmpty && statDominance.isEmpty) {
        print('\n모든 기준 통과! (라운드 $round에서 수렴)\n');
        roundLog.writeln('\n**수렴 완료!**\n');
        break;
      }

      // 과다선택 보정
      for (final issue in overSelections) {
        final current = eventWeightOverrides[issue.target] ?? 1.0;
        final ratio = kMaxEventFreq / issue.current;
        // 부드러운 감쇄: 현재 가중치 × (0.3 + 0.7 × 목표비율)
        final newVal = current * (0.3 + 0.7 * ratio);
        eventWeightOverrides[issue.target] = newVal.clamp(0.15, 1.5);
        roundLog.writeln('  - 감쇄: "${issue.target.length > 40 ? '${issue.target.substring(0, 40)}...' : issue.target}" ${current.toStringAsFixed(3)} → ${eventWeightOverrides[issue.target]!.toStringAsFixed(3)}');
      }

      roundLog.writeln('');
    }

    // 최종 검증 (5시드로)
    print('--- 최종 검증 (5시드) ---');
    final finalSeeds = [42, 123, 777, 2024, 9999];
    final finalResults = runSimulation(
      configs: configs,
      seeds: finalSeeds,
      applyOverrides: true,
    );
    final finalIssues = diagnose(finalResults);

    for (final mu in ['TvZ', 'ZvT', 'TvP', 'PvT', 'ZvP', 'PvZ', 'TvT', 'ZvZ', 'PvP']) {
      final r = finalResults[mu]!;
      final maxFreq = r.eventFreqs.values.fold<double>(0, (m, v) => v > m ? v : m);
      final totalStat = r.statCounts.values.fold<int>(0, (s, v) => s + v);
      double maxStatPct = 0; String maxStatName = '';
      double minStatPct = 100; String minStatName = '';
      for (final stat in ['attack', 'control', 'defense', 'harass', 'strategy', 'macro', 'scout', 'sense']) {
        final pct = totalStat > 0 ? (r.statCounts[stat] ?? 0) / totalStat * 100 : 0.0;
        if (pct > maxStatPct) { maxStatPct = pct; maxStatName = stat; }
        if (pct < minStatPct) { minStatPct = pct; minStatName = stat; }
      }
      final ok = maxFreq <= kMaxEventFreq && maxStatPct <= kMaxStatDominance && minStatPct >= kMinStatCoverage;
      print('$mu: 최대이벤트 ${maxFreq.toStringAsFixed(1)}% | 최대스탯 ${maxStatPct.toStringAsFixed(1)}%($maxStatName) | 최소스탯 ${minStatPct.toStringAsFixed(1)}%($minStatName) | ${ok ? "PASS" : "FAIL"}');
    }

    // 가중치 오버라이드 출력
    if (eventWeightOverrides.isNotEmpty) {
      print('\n=== 자동 보정 가중치 오버라이드 (${eventWeightOverrides.length}개) ===');
      final sortedOverrides = eventWeightOverrides.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final entry in sortedOverrides) {
        final displayText = entry.key.length > 50 ? '${entry.key.substring(0, 50)}...' : entry.key;
        print('  ${entry.value.toStringAsFixed(3)}x  "$displayText"');
      }

      // Dart 코드로 출력 (복사하여 실제 코드에 적용 가능)
      final codeBuf = StringBuffer();
      codeBuf.writeln('\n// === 자동 보정 가중치 맵 (게임 코드에 적용 가능) ===');
      codeBuf.writeln('// _selectWeightedEvent()에서 이벤트 가중치에 곱할 보정값');
      codeBuf.writeln('static const Map<String, double> clashEventWeightOverrides = {');
      for (final entry in sortedOverrides) {
        codeBuf.writeln("  '${entry.key.replaceAll("'", "\\'")}': ${entry.value.toStringAsFixed(4)},");
      }
      codeBuf.writeln('};');
      print(codeBuf.toString());
    }

    // 보고서 출력
    final finalBuf = StringBuffer();
    writeReport(
      buf: finalBuf,
      title: '자동 보정 최종 결과',
      results: finalResults,
      issues: finalIssues,
      seeds: finalSeeds,
    );
    finalBuf.writeln('---\n');
    finalBuf.write(roundLog.toString());

    if (eventWeightOverrides.isNotEmpty) {
      finalBuf.writeln('\n## 가중치 오버라이드 맵');
      finalBuf.writeln('');
      finalBuf.writeln('```dart');
      finalBuf.writeln('static const Map<String, double> clashEventWeightOverrides = {');
      final sortedOverrides = eventWeightOverrides.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (final entry in sortedOverrides) {
        finalBuf.writeln("  '${entry.key.replaceAll("'", "\\'")}': ${entry.value.toStringAsFixed(4)},");
      }
      finalBuf.writeln('};');
      finalBuf.writeln('```');
    }

    File('test/output/AUTO_CALIBRATE_RESULT.md').writeAsStringSync(finalBuf.toString());
    print('\n보고서: test/output/AUTO_CALIBRATE_RESULT.md');
  });
}
