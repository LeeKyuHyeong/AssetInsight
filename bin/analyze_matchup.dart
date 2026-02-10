// 종족전별 빌드오더/이벤트 풀 중복도 분석 스크립트
// Usage: dart run bin/analyze_matchup.dart <matchup>
// e.g.: dart run bin/analyze_matchup.dart TvZ

import 'dart:math';
import 'package:mystar/core/constants/build_orders.dart';
import 'package:mystar/domain/models/enums.dart';

final _rng = Random(42);

/// _determineBuildStyle 재현 (MatchSimulationService)
BuildStyle determineBuildStyle(Map<String, int> stats) {
  final attackScore = stats['attack']! + stats['harass']! + stats['control']!;
  final defenseScore = stats['defense']! + stats['macro']! + stats['strategy']!;
  final cheeseScore = stats['attack']! + stats['sense']!;

  // 치즈 확률: 공격+감각 기반 (B+ 선수도 ~8-12% 확률로 가능)
  final cheeseProb = ((cheeseScore - 600) / 3000).clamp(0.05, 0.20);
  if (cheeseScore > 900 && _rng.nextDouble() < cheeseProb) {
    return BuildStyle.cheese;
  }

  final ratio = attackScore / (defenseScore + 1);
  // 랜덤 노이즈로 밸런스 독점 방지 (±0.15 범위)
  final noise = (_rng.nextDouble() - 0.5) * 0.30;
  final adjustedRatio = ratio + noise;
  if (adjustedRatio > 1.08) return BuildStyle.aggressive;
  if (adjustedRatio < 0.92) return BuildStyle.defensive;
  return BuildStyle.balanced;
}

/// _determineBuildType 재현
BuildType? determineBuildType(
    Map<String, int> stats, String matchup, BuildStyle preferredStyle) {
  final candidates = BuildType.getByMatchupAndStyle(matchup, preferredStyle);
  if (candidates.isEmpty) {
    final allBuilds = BuildType.getByMatchup(matchup);
    if (allBuilds.isEmpty) return null;
    return allBuilds[_rng.nextInt(allBuilds.length)];
  }

  final scoredBuilds = <MapEntry<BuildType, double>>[];
  for (final build in candidates) {
    double score = 0;
    for (final stat in build.keyStats) {
      score += stats[stat] ?? 500;
    }
    scoredBuilds.add(MapEntry(build, score));
  }

  scoredBuilds.sort((a, b) => b.value.compareTo(a.value));
  final topCount =
      (scoredBuilds.length / 2).ceil().clamp(1, scoredBuilds.length);
  return scoredBuilds[_rng.nextInt(topCount)].key;
}

/// B+ 등급 (총합 3200~3600) 랜덤 능력치 생성
Map<String, int> generateRandomStats() {
  final targetTotal = 3200 + _rng.nextInt(400);
  final statNames = [
    'sense', 'control', 'attack', 'harass', //
    'strategy', 'macro', 'defense', 'scout'
  ];
  final stats = <String, int>{};
  int remaining = targetTotal;

  for (int i = 0; i < 7; i++) {
    final avg = remaining ~/ (8 - i);
    final lo = (avg - 120).clamp(200, 700);
    final hi = (avg + 120).clamp(200, 700);
    final value = lo + _rng.nextInt((hi - lo).clamp(1, 400));
    stats[statNames[i]] = value;
    remaining -= value;
  }
  stats[statNames[7]] = remaining.clamp(200, 700);
  return stats;
}

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run bin/analyze_matchup.dart <matchup>');
    return;
  }

  final matchup = args[0]; // e.g. 'TvZ'
  final homeRace = matchup[0];
  final awayRace = matchup[2];
  final reverseMatchup = '${awayRace}v$homeRace';

  const numSims = 50;

  // ── 통계 컨테이너 ──
  final homeStyleCounts = <String, int>{};
  final awayStyleCounts = <String, int>{};
  final homeBuildCounts = <String, int>{}; // BuildOrder.name -> count
  final awayBuildCounts = <String, int>{};
  final homeBuildTypeCounts = <String, int>{}; // BuildType.koreanName -> count
  final awayBuildTypeCounts = <String, int>{};

  final allHomeBuildStepTexts = <String>{};
  final allAwayBuildStepTexts = <String>{};
  final perMatchBuildStepTexts = <int>[]; // 경기당 고유 빌드스텝 텍스트

  // 빌드간 텍스트 공유 분석
  final buildTextSets = <String, Set<String>>{}; // build name -> text set

  // 클래시 이벤트
  final allClashTexts = <String, Set<String>>{}; // phase -> unique texts
  final clashPoolSizes = <String, List<int>>{}; // phase -> sizes
  for (final phase in GamePhase.values) {
    allClashTexts[phase.name] = {};
    clashPoolSizes[phase.name] = [];
  }

  // 중후반 이벤트 분석
  final midLateTextCounts = <String, int>{}; // text -> count
  const midLateSamples = 200; // 경기당 대략적 이벤트 수

  // ── 50경기 시뮬레이션 ──
  for (int i = 0; i < numSims; i++) {
    final homeStats = generateRandomStats();
    final awayStats = generateRandomStats();

    final homeStyle = determineBuildStyle(homeStats);
    final awayStyle = determineBuildStyle(awayStats);

    homeStyleCounts[homeStyle.koreanName] =
        (homeStyleCounts[homeStyle.koreanName] ?? 0) + 1;
    awayStyleCounts[awayStyle.koreanName] =
        (awayStyleCounts[awayStyle.koreanName] ?? 0) + 1;

    // 빌드오더 선택
    final homeBuild = BuildOrderData.getBuildOrder(
        race: homeRace, vsRace: awayRace, preferredStyle: homeStyle);
    final awayBuild = BuildOrderData.getBuildOrder(
        race: awayRace, vsRace: homeRace, preferredStyle: awayStyle);

    if (homeBuild != null) {
      homeBuildCounts[homeBuild.name] =
          (homeBuildCounts[homeBuild.name] ?? 0) + 1;
      for (final step in homeBuild.steps) {
        allHomeBuildStepTexts.add(step.text);
      }
      buildTextSets.putIfAbsent(
          homeBuild.name, () => homeBuild.steps.map((s) => s.text).toSet());
    }
    if (awayBuild != null) {
      awayBuildCounts[awayBuild.name] =
          (awayBuildCounts[awayBuild.name] ?? 0) + 1;
      for (final step in awayBuild.steps) {
        allAwayBuildStepTexts.add(step.text);
      }
      buildTextSets.putIfAbsent(
          awayBuild.name, () => awayBuild.steps.map((s) => s.text).toSet());
    }

    // 경기당 고유 빌드스텝
    final matchTexts = <String>{};
    if (homeBuild != null) matchTexts.addAll(homeBuild.steps.map((s) => s.text));
    if (awayBuild != null) matchTexts.addAll(awayBuild.steps.map((s) => s.text));
    perMatchBuildStepTexts.add(matchTexts.length);

    // 빌드 타입 선택
    final homeBuildType = determineBuildType(homeStats, matchup, homeStyle);
    final awayBuildType =
        determineBuildType(awayStats, reverseMatchup, awayStyle);

    if (homeBuildType != null) {
      homeBuildTypeCounts[homeBuildType.koreanName] =
          (homeBuildTypeCounts[homeBuildType.koreanName] ?? 0) + 1;
    }
    if (awayBuildType != null) {
      awayBuildTypeCounts[awayBuildType.koreanName] =
          (awayBuildTypeCounts[awayBuildType.koreanName] ?? 0) + 1;
    }

    // 클래시 이벤트 풀 분석 (각 페이즈별)
    for (final phase in GamePhase.values) {
      final events = BuildOrderData.getClashEvents(
        homeStyle,
        awayStyle,
        attackerRace: homeRace,
        defenderRace: awayRace,
        attackerBuildType: homeBuildType,
        defenderBuildType: awayBuildType,
        attackerAttack: homeStats['attack'],
        attackerHarass: homeStats['harass'],
        attackerControl: homeStats['control'],
        attackerStrategy: homeStats['strategy'],
        attackerMacro: homeStats['macro'],
        attackerSense: homeStats['sense'],
        defenderDefense: awayStats['defense'],
        defenderStrategy: awayStats['strategy'],
        defenderMacro: awayStats['macro'],
        defenderControl: awayStats['control'],
        defenderSense: awayStats['sense'],
        gamePhase: phase,
      );

      for (final event in events) {
        allClashTexts[phase.name]!.add(event.text);
      }
      clashPoolSizes[phase.name]!.add(events.length);
    }

    // 중후반 이벤트 샘플링 (종족별)
    for (int j = 0; j < midLateSamples ~/ numSims; j++) {
      for (final race in [homeRace, awayRace]) {
        for (final lineCount in [30, 60, 100, 150]) {
          final event = BuildOrderData.getMidLateEvent(
            lineCount: lineCount,
            currentArmy: 80 + _rng.nextInt(60),
            currentResource: 80 + _rng.nextInt(200),
            race: race,
            random: _rng,
          );
          midLateTextCounts[event.text] =
              (midLateTextCounts[event.text] ?? 0) + 1;
        }
      }
    }
  }

  // ══════════════════════════════════════════
  //  출력
  // ══════════════════════════════════════════
  print('========================================');
  print('  $matchup 종족전 분석 (${numSims}경기)');
  print('========================================');

  // ── 빌드 타입 현황 ──
  final homeBuilds = BuildType.getByMatchup(matchup);
  final awayBuilds = BuildType.getByMatchup(reverseMatchup);
  print('');
  print('[빌드 타입 현황]');
  print('  $homeRace측 빌드 타입: ${homeBuilds.length}개');
  for (final b in homeBuilds) {
    print('    - ${b.koreanName} (${b.parentStyle.koreanName}) [${b.keyStats.join(",")}]');
  }
  if (matchup != reverseMatchup) {
    print('  $awayRace측 빌드 타입: ${awayBuilds.length}개');
    for (final b in awayBuilds) {
      print('    - ${b.koreanName} (${b.parentStyle.koreanName}) [${b.keyStats.join(",")}]');
    }
  }

  // ── 빌드 스타일 분포 ──
  print('');
  print('[빌드 스타일 분포]');
  print('  $homeRace측:');
  _printSorted(homeStyleCounts, numSims);
  print('  $awayRace측:');
  _printSorted(awayStyleCounts, numSims);

  // ── 빌드오더 선택 분포 ──
  print('');
  print('[빌드오더 선택 분포]');
  print('  $homeRace측 (사용된 빌드: ${homeBuildCounts.length}개):');
  _printSorted(homeBuildCounts, numSims);
  if (matchup != reverseMatchup) {
    print('  $awayRace측 (사용된 빌드: ${awayBuildCounts.length}개):');
    _printSorted(awayBuildCounts, numSims);
  }

  // ── 세부 빌드 타입 분포 ──
  print('');
  print('[세부 빌드 타입 분포]');
  print('  $homeRace측:');
  _printSorted(homeBuildTypeCounts, numSims);
  if (matchup != reverseMatchup) {
    print('  $awayRace측:');
    _printSorted(awayBuildTypeCounts, numSims);
  }

  // ── 빌드 스텝 텍스트 분석 ──
  print('');
  print('[빌드 스텝 텍스트 분석]');
  print('  $homeRace측 전체 고유 텍스트: ${allHomeBuildStepTexts.length}개');
  if (matchup != reverseMatchup) {
    print('  $awayRace측 전체 고유 텍스트: ${allAwayBuildStepTexts.length}개');
  }
  final combinedTexts = allHomeBuildStepTexts.union(allAwayBuildStepTexts);
  final overlapTexts = allHomeBuildStepTexts.intersection(allAwayBuildStepTexts);
  print('  양측 합산 고유 텍스트: ${combinedTexts.length}개');
  print('  양측 공유 텍스트: ${overlapTexts.length}개');
  if (perMatchBuildStepTexts.isNotEmpty) {
    final avg = perMatchBuildStepTexts.reduce((a, b) => a + b) /
        perMatchBuildStepTexts.length;
    final minV = perMatchBuildStepTexts.reduce((a, b) => a < b ? a : b);
    final maxV = perMatchBuildStepTexts.reduce((a, b) => a > b ? a : b);
    print('  경기당 고유 텍스트: 평균 ${avg.toStringAsFixed(1)} / 최소 $minV / 최대 $maxV');
  }

  // ── 빌드간 텍스트 겹침 ──
  print('');
  print('[빌드간 텍스트 겹침]');
  final buildNames = buildTextSets.keys.toList();
  if (buildNames.length > 1) {
    for (int a = 0; a < buildNames.length; a++) {
      for (int b = a + 1; b < buildNames.length; b++) {
        final setA = buildTextSets[buildNames[a]]!;
        final setB = buildTextSets[buildNames[b]]!;
        final overlap = setA.intersection(setB);
        final unionSize = setA.union(setB).length;
        final pct =
            unionSize > 0 ? (overlap.length / unionSize * 100).toStringAsFixed(1) : '0';
        if (overlap.isNotEmpty) {
          print(
              '  ${buildNames[a]} ∩ ${buildNames[b]}: ${overlap.length}개 겹침 ($pct%)');
        }
      }
    }
  }
  final allBuildTextsUnion = buildTextSets.values.fold<Set<String>>(
    {},
    (acc, s) => acc.union(s),
  );
  print('  전체 빌드오더 고유 텍스트 합계: ${allBuildTextsUnion.length}개');

  // ── 클래시 이벤트 분석 ──
  print('');
  print('[클래시 이벤트 풀 분석]');
  int totalClashUnique = 0;
  for (final phase in GamePhase.values) {
    final uniqueCount = allClashTexts[phase.name]!.length;
    totalClashUnique += uniqueCount;
    final poolSizes = clashPoolSizes[phase.name]!;
    final avgPool = poolSizes.isNotEmpty
        ? poolSizes.reduce((a, b) => a + b) / poolSizes.length
        : 0;
    final minPool =
        poolSizes.isNotEmpty ? poolSizes.reduce((a, b) => a < b ? a : b) : 0;
    final maxPool =
        poolSizes.isNotEmpty ? poolSizes.reduce((a, b) => a > b ? a : b) : 0;
    print('  ${phase.koreanName}:');
    print('    고유 이벤트 텍스트: ${uniqueCount}개');
    print('    풀 크기: 평균 ${avgPool.toStringAsFixed(1)} / 최소 $minPool / 최대 $maxPool');
  }
  final allPhasesClash = <String>{};
  for (final texts in allClashTexts.values) {
    allPhasesClash.addAll(texts);
  }
  print('  전 단계 합산 고유 이벤트: ${allPhasesClash.length}개');

  // ── 중후반 이벤트 분석 ──
  print('');
  print('[중후반(MidLate) 이벤트 분석]');
  print('  전체 고유 텍스트: ${midLateTextCounts.length}개');
  final sortedMidLate = midLateTextCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('  가장 빈번한 상위 5개:');
  for (int i = 0; i < 5 && i < sortedMidLate.length; i++) {
    final e = sortedMidLate[i];
    final truncated =
        e.key.length > 40 ? '${e.key.substring(0, 40)}...' : e.key;
    print('    ${e.value}회: $truncated');
  }

  // ── 종합 중복도 ──
  print('');
  print('[종합 중복도 요약]');
  final usedBuildCount = homeBuildCounts.length + awayBuildCounts.length;
  final maxBuildCount = homeBuilds.length + awayBuilds.length;
  print('  빌드오더 활용률: $usedBuildCount / $maxBuildCount'
      ' (${(usedBuildCount / maxBuildCount * 100).toStringAsFixed(0)}%)');
  print('  빌드오더 가능한 조합: ${homeBuildCounts.length} × ${awayBuildCounts.length}'
      ' = ${homeBuildCounts.length * awayBuildCounts.length}가지');

  // 텍스트 다양성 지수 (빌드스텝 + 클래시 + 중후반)
  final totalUniqueTexts =
      combinedTexts.length + allPhasesClash.length + midLateTextCounts.length;
  print('  전체 고유 텍스트 풀: $totalUniqueTexts개');
  print('    - 빌드 스텝: ${combinedTexts.length}개');
  print('    - 클래시 이벤트: ${allPhasesClash.length}개');
  print('    - 중후반 이벤트: ${midLateTextCounts.length}개');
}

void _printSorted(Map<String, int> counts, int total) {
  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in sorted) {
    final pct = (entry.value / total * 100).toStringAsFixed(1);
    print('    ${entry.key}: ${entry.value}회 ($pct%)');
  }
}
