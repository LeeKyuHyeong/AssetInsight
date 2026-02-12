import 'dart:async';
import 'dart:math';
import '../models/models.dart';
import '../../core/constants/build_orders.dart';

/// 전투 로그 소유자 타입
enum LogOwner {
  system,  // 시스템 메시지 (경기 시작, 종료 등)
  home,    // 홈 선수 이벤트
  away,    // 어웨이 선수 이벤트
  clash,   // 충돌/전투 이벤트
}

/// 전투 로그 엔트리
class BattleLogEntry {
  final String text;
  final LogOwner owner;

  const BattleLogEntry({
    required this.text,
    this.owner = LogOwner.system,
  });
}

/// 경기 시뮬레이션 상태
class SimulationState {
  final int homeArmy;
  final int awayArmy;
  final int homeResources;
  final int awayResources;
  final List<BattleLogEntry> battleLogEntries;
  final bool isFinished;
  final bool? homeWin;

  const SimulationState({
    this.homeArmy = 80,       // 초기 병력
    this.awayArmy = 80,       // 초기 병력
    this.homeResources = 150, // 초기 자원
    this.awayResources = 150, // 초기 자원
    this.battleLogEntries = const [],
    this.isFinished = false,
    this.homeWin,
  });

  // 하위 호환성을 위한 getter
  List<String> get battleLog => battleLogEntries.map((e) => e.text).toList();

  SimulationState copyWith({
    int? homeArmy,
    int? awayArmy,
    int? homeResources,
    int? awayResources,
    List<BattleLogEntry>? battleLogEntries,
    bool? isFinished,
    bool? homeWin,
  }) {
    return SimulationState(
      homeArmy: homeArmy ?? this.homeArmy,
      awayArmy: awayArmy ?? this.awayArmy,
      homeResources: homeResources ?? this.homeResources,
      awayResources: awayResources ?? this.awayResources,
      battleLogEntries: battleLogEntries ?? this.battleLogEntries,
      isFinished: isFinished ?? this.isFinished,
      homeWin: homeWin ?? this.homeWin,
    );
  }
}

/// 경기 시뮬레이션 서비스 (빌드오더 기반)
class MatchSimulationService {
  final Random _random = Random();

  /// 종족 문자열 변환
  String _getRaceString(Race race) {
    switch (race) {
      case Race.terran:
        return 'T';
      case Race.zerg:
        return 'Z';
      case Race.protoss:
        return 'P';
    }
  }

  /// 선수 능력치 기반 빌드 스타일 결정
  BuildStyle _determineBuildStyle(PlayerStats stats) {
    final attackScore = stats.attack + stats.harass + stats.control;
    final defenseScore = stats.defense + stats.macro + stats.strategy;
    final cheeseScore = stats.attack + stats.sense;

    // 치즈 확률: 공격+감각 기반 (B+ 선수도 ~8-12% 확률로 가능)
    final cheeseProb = ((cheeseScore - 600) / 3000).clamp(0.05, 0.20);
    if (cheeseScore > 900 && _random.nextDouble() < cheeseProb) {
      return BuildStyle.cheese;
    }

    final ratio = attackScore / (defenseScore + 1);
    // 랜덤 노이즈로 밸런스 독점 방지 (±0.15 범위)
    final noise = (_random.nextDouble() - 0.5) * 0.30;
    final adjustedRatio = ratio + noise;
    if (adjustedRatio > 1.08) {
      return BuildStyle.aggressive;
    } else if (adjustedRatio < 0.92) {
      return BuildStyle.defensive;
    } else {
      return BuildStyle.balanced;
    }
  }

  /// 세부 빌드 타입 결정 (매치업 + 능력치 기반)
  BuildType? _determineBuildType(PlayerStats stats, String matchup, BuildStyle preferredStyle, {int rushDistance = 5}) {
    final candidates = BuildType.getByMatchupAndStyle(matchup, preferredStyle);
    if (candidates.isEmpty) {
      // 해당 스타일 빌드가 없으면 매치업 전체에서 선택
      final allBuilds = BuildType.getByMatchup(matchup);
      if (allBuilds.isEmpty) return null;
      return allBuilds[_random.nextInt(allBuilds.length)];
    }

    // 핵심 능력치에 맞는 빌드 우선 선택
    final scoredBuilds = <MapEntry<BuildType, double>>[];

    for (final build in candidates) {
      double score = 0;
      for (final stat in build.keyStats) {
        score += _getStatValueByName(stats, stat);
      }
      // 맵 rushDistance 기반 빌드 점수 보정
      if (rushDistance <= 4 && (build.parentStyle == BuildStyle.cheese || build.parentStyle == BuildStyle.aggressive)) {
        score += 200;
      } else if (rushDistance >= 7 && (build.parentStyle == BuildStyle.defensive || build.parentStyle == BuildStyle.balanced)) {
        score += 200;
      }
      scoredBuilds.add(MapEntry(build, score));
    }

    // 점수순 정렬 후 상위 빌드 중 랜덤 선택 (약간의 변동성)
    scoredBuilds.sort((a, b) => b.value.compareTo(a.value));

    // 상위 50% 중 랜덤 선택
    final topCount = (scoredBuilds.length / 2).ceil().clamp(1, scoredBuilds.length);
    return scoredBuilds[_random.nextInt(topCount)].key;
  }

  /// 능력치 이름으로 값 가져오기
  int _getStatValueByName(PlayerStats stats, String statName) {
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

  /// 두 선수 간 승률 계산 (homePlayer 기준)
  double calculateWinRate({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
    double homeSnipingBonus = 0,
    double awaySnipingBonus = 0,
  }) {
    // 1. 종족 상성 (맵 기반)
    final raceMatchupBonus = map.matchup.getWinRate(
      homePlayer.race,
      awayPlayer.race,
    );

    // 2. 능력치 비교 (컨디션 적용)
    final homeStats = homePlayer.effectiveStats;
    final awayStats = awayPlayer.effectiveStats;

    // 매치업 문자열 생성
    final homeRace = _getRaceString(homePlayer.race);
    final awayRace = _getRaceString(awayPlayer.race);
    final matchup = '$homeRace' 'v$awayRace';

    // 3. 기본 능력치 비교 (경기 초반 기준으로 전체 평가)
    final homeTotal = homeStats.total + homeCheerfulBonus;
    final awayTotal = awayStats.total + awayCheerfulBonus;

    // 능력치 차이에 따른 승률 보정 (35당 1%, 최대 ±50%)
    final statDiff = homeTotal - awayTotal;
    final statBonus = (statDiff / 35).clamp(-50.0, 50.0);

    // 4. 빌드 스타일 및 세부 빌드 상성
    final homeStyle = _determineBuildStyle(homeStats);
    final awayStyle = _determineBuildStyle(awayStats);
    final homeBuildType = _determineBuildType(homeStats, matchup, homeStyle, rushDistance: map.rushDistance);
    final awayBuildType = _determineBuildType(awayStats, '${awayRace}v$homeRace', awayStyle, rushDistance: map.rushDistance);

    double buildBonus = 0;

    // 세부 빌드 타입 상성 (있는 경우)
    if (homeBuildType != null && awayBuildType != null) {
      buildBonus = BuildMatchup.getBuildAdvantage(homeBuildType, awayBuildType);

      // 정찰 성공 보너스 (상대 빌드 읽기)
      buildBonus += BuildMatchup.getScoutBonus(homeStats.scout, awayBuildType);
      buildBonus -= BuildMatchup.getScoutBonus(awayStats.scout, homeBuildType);
    } else {
      // 세부 빌드가 없으면 상위 스타일로 계산
      if (homeStyle == BuildStyle.aggressive && awayStyle == BuildStyle.defensive) {
        buildBonus = 15;
      } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.aggressive) {
        buildBonus = -15;
      } else if (homeStyle == BuildStyle.cheese && awayStyle == BuildStyle.defensive) {
        buildBonus = 25;
      } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.cheese) {
        buildBonus = -15;
      }
    }

    // 등급 차이가 크면 빌드 상성 효과 감소
    final gradeDiff = (homeTotal - awayTotal).abs();
    final buildEffectMultiplier = (1.0 - gradeDiff / 14000).clamp(0.5, 1.0);
    buildBonus *= buildEffectMultiplier;

    // 수비력이 높으면 빌드 불리 일부 상쇄
    if (buildBonus < 0) {
      final defenseAdvantage = (homeStats.defense - awayStats.defense) / 150;
      buildBonus += defenseAdvantage.clamp(0.0, 5.0);
    }

    buildBonus = buildBonus.clamp(-40.0, 40.0);

    // 5. 맵 특성 보너스 (세분화된 시스템)
    final mapBonusResult = map.calculateMapBonus(
      homeSense: homeStats.sense,
      homeControl: homeStats.control,
      homeAttack: homeStats.attack,
      homeHarass: homeStats.harass,
      homeStrategy: homeStats.strategy,
      homeMacro: homeStats.macro,
      homeDefense: homeStats.defense,
      homeScout: homeStats.scout,
      awaySense: awayStats.sense,
      awayControl: awayStats.control,
      awayAttack: awayStats.attack,
      awayHarass: awayStats.harass,
      awayStrategy: awayStats.strategy,
      awayMacro: awayStats.macro,
      awayDefense: awayStats.defense,
      awayScout: awayStats.scout,
    );

    final mapBonus = mapBonusResult.netHomeAdvantage;

    // 5-1. 넓은 맵 정찰 보너스 (rushDistance >= 7: 정찰 중요도 증가)
    double scoutMapBonus = 0;
    if (map.rushDistance >= 7) {
      final scoutDiff = homeStats.scout - awayStats.scout;
      scoutMapBonus = (scoutDiff / 100).clamp(-5.0, 5.0);
    }

    // 6. 레벨 차이에 따른 경험 보정 (레벨당 +2%, 최대 ±20%)
    final levelDiff = homePlayer.level.value - awayPlayer.level.value;
    final levelBonus = (levelDiff * 2).clamp(-20, 20);

    // 7. 스나이핑 보정 (성공 시 +20%)
    final snipingBonus = homeSnipingBonus - awaySnipingBonus;

    // 최종 승률 계산
    // 맵 종족상성 효과 (±15)
    final raceDeviation = raceMatchupBonus.toDouble() - 50.0;
    final baseWinRate = 50.0 + raceDeviation * 1.0;
    final finalWinRate = (baseWinRate + statBonus + buildBonus + mapBonus + scoutMapBonus + levelBonus + snipingBonus).clamp(3.0, 97.0);

    return finalWinRate / 100;
  }

  /// 경기 시뮬레이션 (텍스트 없이 결과만)
  SetResult simulateMatch({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
    double homeSnipingBonus = 0,
    double awaySnipingBonus = 0,
  }) {
    final winRate = calculateWinRate(
      homePlayer: homePlayer,
      awayPlayer: awayPlayer,
      map: map,
      homeCheerfulBonus: homeCheerfulBonus,
      awayCheerfulBonus: awayCheerfulBonus,
      homeSnipingBonus: homeSnipingBonus,
      awaySnipingBonus: awaySnipingBonus,
    );

    final homeWin = _random.nextDouble() < winRate;

    return SetResult(
      mapId: map.id,
      homePlayerId: homePlayer.id,
      awayPlayerId: awayPlayer.id,
      homeWin: homeWin,
    );
  }

  /// 경기 시뮬레이션 (텍스트 로그 포함, 스트림) - 빌드오더 기반
  /// [getIntervalMs] 콜백을 사용하여 배속 변경 시 스트림 재시작 없이 반영 가능
  Stream<SimulationState> simulateMatchWithLog({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    required int Function() getIntervalMs,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
    double homeSnipingBonus = 0,
    double awaySnipingBonus = 0,
    String? homeSnipingPlayerName,
    String? awaySnipingPlayerName,
  }) async* {
    final winRate = calculateWinRate(
      homePlayer: homePlayer,
      awayPlayer: awayPlayer,
      map: map,
      homeCheerfulBonus: homeCheerfulBonus,
      awayCheerfulBonus: awayCheerfulBonus,
      homeSnipingBonus: homeSnipingBonus,
      awaySnipingBonus: awaySnipingBonus,
    );

    var state = const SimulationState();
    final homeStats = homePlayer.effectiveStats;
    final awayStats = awayPlayer.effectiveStats;

    // 각 선수의 빌드 스타일 결정
    final homeStyle = _determineBuildStyle(homeStats);
    final awayStyle = _determineBuildStyle(awayStats);

    // 각 선수의 빌드오더 가져오기
    final homeRace = _getRaceString(homePlayer.race);
    final awayRace = _getRaceString(awayPlayer.race);

    final homeBuild = BuildOrderData.getBuildOrder(
      race: homeRace,
      vsRace: awayRace,
      preferredStyle: homeStyle,
    );
    final awayBuild = BuildOrderData.getBuildOrder(
      race: awayRace,
      vsRace: homeRace,
      preferredStyle: awayStyle,
    );

    // 빌드 스텝에서 유닛 키워드 추출 (이벤트 필터링용)
    final homeUnitTags = homeBuild != null ? BuildOrderData.extractUnitTags(homeBuild) : <String>{};
    final awayUnitTags = awayBuild != null ? BuildOrderData.extractUnitTags(awayBuild) : <String>{};
    final combinedUnitTags = homeUnitTags.union(awayUnitTags);

    // 세부 빌드 타입 결정
    final matchup = '${homeRace}v$awayRace';
    final homeBuildType = _determineBuildType(homeStats, matchup, homeStyle, rushDistance: map.rushDistance);
    final awayBuildType = _determineBuildType(awayStats, '${awayRace}v$homeRace', awayStyle, rushDistance: map.rushDistance);

    // 빌드가 없으면 기본 시뮬레이션
    if (homeBuild == null || awayBuild == null) {
      yield* _fallbackSimulation(
        homePlayer: homePlayer,
        awayPlayer: awayPlayer,
        map: map,
        getIntervalMs: getIntervalMs,
        winRate: winRate,
      );
      return;
    }

    // 경기 시작 메시지 (빌드 스타일 스포일 없음)
    final openingEntries = <BattleLogEntry>[
      const BattleLogEntry(text: '마이프로리그, 경기 시작했습니다!', owner: LogOwner.system),
      BattleLogEntry(text: '${map.name}에서 ${homePlayer.name} 선수와 ${awayPlayer.name} 선수가 맞붙습니다.', owner: LogOwner.system),
    ];

    // 스나이핑 성공 텍스트
    if (homeSnipingBonus > 0 && homeSnipingPlayerName != null) {
      openingEntries.add(BattleLogEntry(
        text: "'$homeSnipingPlayerName' 선수 상대를 예상하고 맞춤빌드를 짜온 것 같은데요!",
        owner: LogOwner.home,
      ));
    }
    if (awaySnipingBonus > 0 && awaySnipingPlayerName != null) {
      openingEntries.add(BattleLogEntry(
        text: "'$awaySnipingPlayerName' 선수 상대를 예상하고 맞춤빌드를 짜온 것 같은데요!",
        owner: LogOwner.away,
      ));
    }

    state = state.copyWith(battleLogEntries: openingEntries);
    yield state;
    await Future.delayed(Duration(milliseconds: getIntervalMs()));

    // 빌드 진행 인덱스 (독립 진행)
    int homeIndex = 0;
    int awayIndex = 0;
    int lineCount = 0;
    const maxLines = 200;
    int lastCommentaryLine = -10; // 코멘터리 연속 방지
    final usedTexts = <String, int>{}; // 텍스트 사용 횟수 추적 (같은 텍스트 2회 이상 방지)

    // 충돌 발생 여부
    bool clashOccurred = false;
    int clashStartLine = -1;
    LogOwner lastClashOwner = LogOwner.home; // 클래시 교차 표시용

    // ZvZ 상수 (루프 밖에서 한번만 계산)
    final isZvZ = homePlayer.race == Race.zerg && awayPlayer.race == Race.zerg;
    final isZvZAggressiveVsNonAggressive = isZvZ && (
      (homeStyle == BuildStyle.aggressive && awayStyle != BuildStyle.aggressive) ||
      (awayStyle == BuildStyle.aggressive && homeStyle != BuildStyle.aggressive)
    );

    while (!state.isFinished && lineCount < maxLines) {
      lineCount++;

      // 현재 라인에 해당하는 이벤트 결정 (양측 독립)
      final homeStep = _getNextStep(homeBuild, homeIndex, lineCount);
      final awayStep = _getNextStep(awayBuild, awayIndex, lineCount);

      // 충돌 체크
      if (!clashOccurred && (
          (homeStep?.isClash == true) ||
          (awayStep?.isClash == true) ||
          (isZvZAggressiveVsNonAggressive && lineCount >= 10 && _random.nextDouble() < 0.4) ||
          (isZvZ && lineCount >= 25 && _random.nextDouble() < 0.15) ||
          (lineCount >= 50 && _random.nextDouble() < 0.1)
      )) {
        clashOccurred = true;
        clashStartLine = lineCount;

        if (isZvZ) {
          final avgArmy = ((state.homeArmy + state.awayArmy) / 2).round();
          state = state.copyWith(homeArmy: avgArmy, awayArmy: avgArmy);
        }
      }

      // ========== 클래시 구간 ==========
      if (clashOccurred && lineCount >= clashStartLine) {
        String text = '';
        int homeArmyChange = 0;
        int awayArmyChange = 0;
        int homeResourceChange = 0;
        int awayResourceChange = 0;
        bool decisive = false;
        bool? homeWinOverride;

        // ZvZ 빌드 상성 이변 (우선 체크)
        if (isZvZAggressiveVsNonAggressive && lineCount >= 8 && lineCount <= 18) {
          final homeIsAggressive = homeStyle == BuildStyle.aggressive;
          final aggressorStats = homeIsAggressive ? homeStats : awayStats;
          final zvzDefenderStats = homeIsAggressive ? awayStats : homeStats;
          final aggressor = homeIsAggressive ? homePlayer : awayPlayer;
          final defenderStyle = homeIsAggressive ? awayStyle : homeStyle;
          final isAggressorHome = homeIsAggressive;

          final gradeDiff = zvzDefenderStats.total - aggressorStats.total;

          if (gradeDiff > 1000) {
            final baseChance = defenderStyle == BuildStyle.defensive ? 0.006 : 0.004;
            if (_random.nextDouble() < baseChance) {
              decisive = true;
              homeWinOverride = isAggressorHome;
              text = '${aggressor.name} 선수, 선제 저글링 공격 성공! 빌드 승리!';
            }
          }
        }

        if (!decisive) {
          // 클래시 텍스트 중복 방지: 최대 3회 재시도
          _ClashResult? bestResult;
          for (int retry = 0; retry < 3; retry++) {
            final clashResult = _simulateClash(
              homePlayer: homePlayer,
              awayPlayer: awayPlayer,
              homeStats: homeStats,
              awayStats: awayStats,
              homeStyle: homeStyle,
              awayStyle: awayStyle,
              winRate: winRate,
              lineCount: lineCount,
              clashStartLine: clashStartLine,
              currentState: state,
              map: map,
              homeBuildType: homeBuildType,
              awayBuildType: awayBuildType,
              combinedUnitTags: combinedUnitTags,
            );
            // 미사용 텍스트면 바로 채택
            if ((usedTexts[clashResult.text] ?? 0) == 0 || clashResult.decisive) {
              bestResult = clashResult;
              break;
            }
            // 더 적게 사용된 후보 기억
            if (bestResult == null || (usedTexts[clashResult.text] ?? 0) < (usedTexts[bestResult.text] ?? 0)) {
              bestResult = clashResult;
            }
          }
          final clashResult = bestResult!;

          text = clashResult.text;
          homeArmyChange = clashResult.homeArmyChange;
          awayArmyChange = clashResult.awayArmyChange;
          homeResourceChange = clashResult.homeResourceChange;
          awayResourceChange = clashResult.awayResourceChange;
          decisive = clashResult.decisive;
          homeWinOverride = clashResult.homeWinOverride;
          if (text.isNotEmpty) {
            usedTexts[text] = (usedTexts[text] ?? 0) + 1;
          }
        }

        // 클래시 텍스트의 주체 선수 결정 (선수 이름 기반 + 교차 표시)
        LogOwner clashOwner;
        if (text.isNotEmpty) {
          final transformedText = _transformEnding(text);
          final homeNameIdx = transformedText.indexOf(homePlayer.name);
          final awayNameIdx = transformedText.indexOf(awayPlayer.name);
          if (homeNameIdx >= 0 && (awayNameIdx < 0 || homeNameIdx < awayNameIdx)) {
            clashOwner = LogOwner.home;
          } else if (awayNameIdx >= 0 && (homeNameIdx < 0 || awayNameIdx < homeNameIdx)) {
            clashOwner = LogOwner.away;
          } else {
            // 선수 이름 없는 중립 텍스트 → 이전 owner 반대로 교차
            clashOwner = lastClashOwner == LogOwner.home ? LogOwner.away : LogOwner.home;
          }
          lastClashOwner = clashOwner;
        } else {
          clashOwner = LogOwner.clash;
        }

        // 상태 업데이트
        state = state.copyWith(
          homeArmy: (state.homeArmy + homeArmyChange).clamp(0, 200),
          awayArmy: (state.awayArmy + awayArmyChange).clamp(0, 200),
          homeResources: (state.homeResources + homeResourceChange).clamp(0, 10000),
          awayResources: (state.awayResources + awayResourceChange).clamp(0, 10000),
          battleLogEntries: text.isNotEmpty
              ? [...state.battleLogEntries, BattleLogEntry(text: _transformEnding(text), owner: clashOwner)]
              : state.battleLogEntries,
        );

        yield state;
        await Future.delayed(Duration(milliseconds: getIntervalMs()));

        // 결정적 이벤트 → 엔딩
        if (decisive) {
          yield* _emitEnding(
            state: state,
            homeWinOverride: homeWinOverride,
            winRate: winRate,
            homePlayer: homePlayer,
            awayPlayer: awayPlayer,
            lineCount: lineCount,
            getIntervalMs: getIntervalMs,
          );
          return;
        }

        // 승패 체크
        final result = _checkWinCondition(state, lineCount);
        if (result != null) {
          yield* _emitEnding(
            state: state,
            homeWinOverride: result,
            winRate: winRate,
            homePlayer: homePlayer,
            awayPlayer: awayPlayer,
            lineCount: lineCount,
            getIntervalMs: getIntervalMs,
          );
          return;
        }

        continue; // 클래시 구간에서는 빌드 스텝 건너뜀
      }

      // ========== 일반 빌드 진행 (병합 타임라인) ==========
      final newEntries = <BattleLogEntry>[];
      int homeArmyChange = 0;
      int awayArmyChange = 0;
      int homeResourceChange = 0;
      int awayResourceChange = 0;

      // 홈 빌드 스텝
      if (homeStep != null) {
        final text = _transformEnding(homeStep.text.replaceAll('{player}', homePlayer.name));
        newEntries.add(BattleLogEntry(text: text, owner: LogOwner.home));
        homeArmyChange += homeStep.myArmy;
        homeResourceChange += homeStep.myResource;
        awayArmyChange += homeStep.enemyArmy;
        awayResourceChange += homeStep.enemyResource;
        homeIndex++;

        // 인터랙션 이벤트 (상대 반응)
        final interaction = _getInteractionEvent(
          triggerText: homeStep.text,
          triggerRace: homeRace,
          reactorRace: awayRace,
          reactorName: awayPlayer.name,
        );
        if (interaction != null) {
          newEntries.add(BattleLogEntry(text: interaction, owner: LogOwner.away));
        }

        // 빌드 반응 해설 (주요 빌드 선택에 대한 해설자 코멘터리)
        if (lineCount - lastCommentaryLine >= 3) {
          final buildCommentary = _getBuildReactionCommentary(
            buildText: homeStep.text,
            builderName: homePlayer.name,
            opponentName: awayPlayer.name,
            builderRace: homeRace,
            opponentRace: awayRace,
            usedTexts: usedTexts,
          );
          if (buildCommentary != null) {
            newEntries.add(BattleLogEntry(text: buildCommentary, owner: LogOwner.system));
            lastCommentaryLine = lineCount;
            usedTexts[buildCommentary] = (usedTexts[buildCommentary] ?? 0) + 1;
          }
        }
      }

      // 어웨이 빌드 스텝
      if (awayStep != null) {
        final text = _transformEnding(awayStep.text.replaceAll('{player}', awayPlayer.name));
        newEntries.add(BattleLogEntry(text: text, owner: LogOwner.away));
        awayArmyChange += awayStep.myArmy;
        awayResourceChange += awayStep.myResource;
        homeArmyChange += awayStep.enemyArmy;
        homeResourceChange += awayStep.enemyResource;
        awayIndex++;

        // 인터랙션 이벤트 (상대 반응)
        final interaction = _getInteractionEvent(
          triggerText: awayStep.text,
          triggerRace: awayRace,
          reactorRace: homeRace,
          reactorName: homePlayer.name,
        );
        if (interaction != null) {
          newEntries.add(BattleLogEntry(text: interaction, owner: LogOwner.home));
        }

        // 빌드 반응 해설 (주요 빌드 선택에 대한 해설자 코멘터리)
        if (lineCount - lastCommentaryLine >= 3) {
          final buildCommentary = _getBuildReactionCommentary(
            buildText: awayStep.text,
            builderName: awayPlayer.name,
            opponentName: homePlayer.name,
            builderRace: awayRace,
            opponentRace: homeRace,
            usedTexts: usedTexts,
          );
          if (buildCommentary != null) {
            newEntries.add(BattleLogEntry(text: buildCommentary, owner: LogOwner.system));
            lastCommentaryLine = lineCount;
            usedTexts[buildCommentary] = (usedTexts[buildCommentary] ?? 0) + 1;
          }
        }
      }

      // 양측 빌드 스텝 없음 → 코멘터리 또는 중후반 이벤트
      if (homeStep == null && awayStep == null) {
        // 코멘터리 기회 (최소 5라인 간격)
        if (lineCount - lastCommentaryLine >= 5) {
          final commentary = _getCommentary(
            state: state,
            lineCount: lineCount,
            homePlayer: homePlayer,
            awayPlayer: awayPlayer,
            usedTexts: usedTexts,
          );
          if (commentary != null) {
            newEntries.add(BattleLogEntry(text: commentary, owner: LogOwner.system));
            lastCommentaryLine = lineCount;
            usedTexts[commentary] = (usedTexts[commentary] ?? 0) + 1;
          }
        }

        // 초반(15줄 이전)에서는 midLateEvent 사용 금지 - 아직 병력이 없으므로
        // 중반 이후에도 70% 확률로만 삽입 (빈 줄 허용)
        if (newEntries.isEmpty && lineCount >= 15 && _random.nextDouble() < 0.70) {
          final isHomeTurn = _random.nextBool();
          final player = isHomeTurn ? homePlayer : awayPlayer;
          final currentArmy = isHomeTurn ? state.homeArmy : state.awayArmy;
          final currentResource = isHomeTurn ? state.homeResources : state.awayResources;
          final raceStr = isHomeTurn ? homeRace : awayRace;

          BuildStep? bestStep;
          String bestText = '';
          for (int retry = 0; retry < 5; retry++) {
            final candidate = BuildOrderData.getMidLateEvent(
              lineCount: lineCount,
              currentArmy: currentArmy,
              currentResource: currentResource,
              race: raceStr,
              vsRace: isHomeTurn ? awayRace : homeRace,
              rushDistance: map.rushDistance,
              resources: map.resources,
              terrainComplexity: map.terrainComplexity,
              random: _random,
              availableUnits: isHomeTurn ? homeUnitTags : awayUnitTags,
            );
            final candidateText = _transformEnding(candidate.text.replaceAll('{player}', player.name));
            // 미사용 텍스트 우선
            if ((usedTexts[candidateText] ?? 0) == 0) {
              bestStep = candidate;
              bestText = candidateText;
              break;
            }
            // 가장 적게 사용된 후보 기억
            if (bestStep == null || (usedTexts[candidateText] ?? 0) < (usedTexts[bestText] ?? 0)) {
              bestStep = candidate;
              bestText = candidateText;
            }
          }

          final midLateStep = bestStep!;
          final text = bestText;
          usedTexts[text] = (usedTexts[text] ?? 0) + 1;
          newEntries.add(BattleLogEntry(text: text, owner: isHomeTurn ? LogOwner.home : LogOwner.away));

          if (isHomeTurn) {
            homeArmyChange += midLateStep.myArmy;
            homeResourceChange += midLateStep.myResource;
            awayArmyChange += midLateStep.enemyArmy;
            awayResourceChange += midLateStep.enemyResource;
          } else {
            awayArmyChange += midLateStep.myArmy;
            awayResourceChange += midLateStep.myResource;
            homeArmyChange += midLateStep.enemyArmy;
            homeResourceChange += midLateStep.enemyResource;
          }
        }
      }

      // 상태 업데이트
      state = state.copyWith(
        homeArmy: (state.homeArmy + homeArmyChange).clamp(0, 200),
        awayArmy: (state.awayArmy + awayArmyChange).clamp(0, 200),
        homeResources: (state.homeResources + homeResourceChange).clamp(0, 10000),
        awayResources: (state.awayResources + awayResourceChange).clamp(0, 10000),
        battleLogEntries: newEntries.isNotEmpty
            ? [...state.battleLogEntries, ...newEntries]
            : state.battleLogEntries,
      );

      yield state;
      await Future.delayed(Duration(milliseconds: getIntervalMs()));

      // 승패 체크
      final result = _checkWinCondition(state, lineCount);
      if (result != null) {
        yield* _emitEnding(
          state: state,
          homeWinOverride: result,
          winRate: winRate,
          homePlayer: homePlayer,
          awayPlayer: awayPlayer,
          lineCount: lineCount,
          getIntervalMs: getIntervalMs,
        );
        return;
      }
    }

    // 200줄 강제 판정
    if (!state.isFinished) {
      final homeScore = state.homeArmy + (state.homeResources / 50);
      final awayScore = state.awayArmy + (state.awayResources / 50);
      // 동점이면 winRate 기반 확률 판정 (홈 편향 방지)
      final homeWin = homeScore != awayScore
          ? homeScore > awayScore
          : _random.nextDouble() < winRate;

      yield* _emitEnding(
        state: state,
        homeWinOverride: homeWin,
        winRate: winRate,
        homePlayer: homePlayer,
        awayPlayer: awayPlayer,
        lineCount: lineCount,
        getIntervalMs: getIntervalMs,
        isLongGame: true,
      );
    }
  }

  // ==================== 엔딩 시스템 ====================

  /// 엔딩 emit (GG + 코멘터리 + 승리 선언)
  Stream<SimulationState> _emitEnding({
    required SimulationState state,
    required bool? homeWinOverride,
    required double winRate,
    required Player homePlayer,
    required Player awayPlayer,
    required int lineCount,
    required int Function() getIntervalMs,
    bool isLongGame = false,
  }) async* {
    final isHomeWinner = homeWinOverride ?? (_random.nextDouble() < winRate);
    final winner = isHomeWinner ? homePlayer : awayPlayer;
    final loser = isHomeWinner ? awayPlayer : homePlayer;

    final endingCommentary = _getEndingCommentary(
      winner: winner,
      state: state,
      lineCount: lineCount,
      isLongGame: isLongGame,
    );

    state = state.copyWith(
      isFinished: true,
      homeWin: isHomeWinner,
      battleLogEntries: [
        ...state.battleLogEntries,
        BattleLogEntry(
          text: isLongGame
              ? '접전 끝에 ${loser.name} 선수가 GG를 선언합니다.'
              : '${loser.name} 선수, GG를 선언합니다.',
          owner: isHomeWinner ? LogOwner.away : LogOwner.home,
        ),
        BattleLogEntry(text: endingCommentary, owner: LogOwner.system),
        BattleLogEntry(text: '${winner.name} 선수 승리!', owner: LogOwner.system),
      ],
    );
    yield state;
  }

  /// 엔딩 코멘터리 (게임 상황에 따라)
  String _getEndingCommentary({
    required Player winner,
    required SimulationState state,
    required int lineCount,
    bool isLongGame = false,
  }) {
    if (isLongGame) {
      final longGameTexts = [
        '정말 긴 접전이었습니다! ${winner.name} 선수가 끝까지 버텨냈네요.',
        '양측 모두 포기하지 않은 명경기였습니다!',
        '장기전에서 ${winner.name} 선수의 운영이 빛났습니다.',
      ];
      return longGameTexts[_random.nextInt(longGameTexts.length)];
    }

    // 빠른 승리 (40줄 이하)
    if (lineCount <= 40) {
      final quickTexts = [
        '${winner.name} 선수, 초반부터 압도적이었습니다!',
        '빠른 경기! ${winner.name} 선수가 일찍 승기를 잡았네요.',
        '${winner.name} 선수, 초반 운영이 완벽했습니다!',
      ];
      return quickTexts[_random.nextInt(quickTexts.length)];
    }

    // 접전 (병력 차 적음)
    final armyDiff = (state.homeArmy - state.awayArmy).abs();
    if (armyDiff < 20) {
      final closeTexts = [
        '정말 아슬아슬한 경기였습니다!',
        '어느 쪽이 이겨도 이상하지 않은 접전이었네요!',
        '한 끗 차이의 승부! ${winner.name} 선수가 가져갑니다!',
      ];
      return closeTexts[_random.nextInt(closeTexts.length)];
    }

    // 일반적 마무리
    final normalTexts = [
      '${winner.name} 선수는 역시 끝낼 수 있을 때 끝내버리죠.',
      '${winner.name} 선수, 깔끔한 마무리입니다!',
      '${winner.name} 선수의 경기 운영이 한 수 위였습니다.',
      '대단한 경기력! ${winner.name} 선수 승리 가져갑니다.',
    ];
    return normalTexts[_random.nextInt(normalTexts.length)];
  }

  // ==================== 인터랙션 이벤트 시스템 ====================

  /// 인터랙션 규칙 (트리거-반응 매칭)
  static final List<_InteractionRule> _interactionRules = [
    // 프로토스 → 테란 반응
    _InteractionRule(triggerPattern: RegExp(r'질럿'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor}, 마린으로 질럿 잡아내고.',
      '{reactor} 선수 벙커 뒤에서 질럿 상대합니다.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'다크템플러|다크'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor} 선수 컴샛 스테이션 올립니다!',
      '{reactor} 선수 스캔으로 다크 잡아내구요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'캐리어|모선'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor} 선수 골리앗도 나왔구요.',
      '{reactor} 선수 발키리 생산 서두릅니다.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'리버'), triggerRace: 'P', reactorRace: '*', reactions: [
      '{reactor} 선수 리버 주의하면서 운영합니다.',
      '{reactor} 선수 리버 견제에 대비하고.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'옵저버|정찰'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor} 선수 터렛으로 옵저버 대비하구요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'아비터'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor} 선수 사이언스 베슬 급히 뽑습니다!',
      '{reactor} 선수 EMP 준비하네요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'하이템플러|스톰|사이오닉'), triggerRace: 'P', reactorRace: 'T', reactions: [
      '{reactor} 선수 EMP 준비! 하이템플러 대비하구요.',
      '{reactor} 선수 병력 분산 시킵니다.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'질럿|드라군'), triggerRace: 'P', reactorRace: 'Z', reactions: [
      '{reactor} 선수 저글링으로 견제 나갑니다.',
      '{reactor} 선수 성큰 올려서 방어 준비!',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'캐리어|모선'), triggerRace: 'P', reactorRace: 'Z', reactions: [
      '{reactor} 선수 스커지 서둘러 모읍니다!',
      '{reactor} 선수 히드라리스크로 대공 준비!',
    ]),

    // 저그 → 테란 반응
    _InteractionRule(triggerPattern: RegExp(r'저글링.*러쉬|저글링.*공격|선풀'), triggerRace: 'Z', reactorRace: 'T', reactions: [
      '{reactor}, 벙커로 저글링 막아냅니다!',
      '{reactor} 선수 마린 모아서 방어!',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'스파이어|뮤탈'), triggerRace: 'Z', reactorRace: 'T', reactions: [
      '{reactor} 선수 터렛 올리구요.',
      '{reactor} 선수 발키리 생산합니다.',
      '{reactor} 선수 미사일 터렛 건설!',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'럴커'), triggerRace: 'Z', reactorRace: 'T', reactions: [
      '{reactor} 선수 사이언스 베슬 서두릅니다.',
      '{reactor} 선수 디텍터 확보에 주력하네요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'디파일러|플레이그'), triggerRace: 'Z', reactorRace: 'T', reactions: [
      '{reactor} 선수 이레디에이트 준비하구요.',
      '{reactor} 선수 사이언스 베슬 컨트롤이 중요하겠네요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'히드라'), triggerRace: 'Z', reactorRace: 'P', reactions: [
      '{reactor} 선수 하이템플러 사이오닉 스톰 준비!',
      '{reactor} 선수 리버 견제 나가구요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'뮤탈'), triggerRace: 'Z', reactorRace: 'P', reactions: [
      '{reactor} 선수 코르세어 생산!',
      '{reactor} 선수 드라군으로 방어 준비합니다.',
    ]),

    // 테란 → 프로토스 반응
    _InteractionRule(triggerPattern: RegExp(r'시즈탱크|탱크'), triggerRace: 'T', reactorRace: 'P', reactions: [
      '{reactor} 선수 드라군으로 탱크 상대하구요.',
      '{reactor} 선수 셔틀 리버로 탱크 처리 노립니다.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'벌처|벌쳐'), triggerRace: 'T', reactorRace: 'P', reactions: [
      '{reactor} 선수 드라군으로 벌처 대응합니다.',
      '{reactor} 선수 질럿으로 벌처 잡아내고.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'레이스'), triggerRace: 'T', reactorRace: 'P', reactions: [
      '{reactor} 선수 드라군 생산량 늘립니다.',
      '{reactor} 선수 옵저버로 클로킹 레이스 잡아내고.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'배틀크루저|전투순양함'), triggerRace: 'T', reactorRace: 'P', reactions: [
      '{reactor} 선수 아비터 리콜 준비합니다!',
      '{reactor} 선수 드라군 대량으로 모읍니다.',
    ]),

    // 테란 → 저그 반응
    _InteractionRule(triggerPattern: RegExp(r'시즈탱크|탱크'), triggerRace: 'T', reactorRace: 'Z', reactions: [
      '{reactor} 선수 저글링 런바이 노리구요.',
      '{reactor} 선수 가디언으로 탱크 처리 노립니다.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'벌처|벌쳐'), triggerRace: 'T', reactorRace: 'Z', reactions: [
      '{reactor} 선수 저글링으로 벌처 대응합니다.',
      '{reactor} 선수 성큰 세워서 방어하네요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'레이스'), triggerRace: 'T', reactorRace: 'Z', reactions: [
      '{reactor} 선수 스커지 생산합니다.',
      '{reactor} 선수 뮤탈리스크로 대응 나가구요.',
    ]),

    // 범용 반응
    _InteractionRule(triggerPattern: RegExp(r'드랍|수송'), triggerRace: '*', reactorRace: '*', reactions: [
      '{reactor}, 드랍 읽었습니다! 본진 수비!',
      '{reactor} 선수 드랍 대비하며 병력 배치!',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'확장|멀티|앞마당'), triggerRace: '*', reactorRace: '*', reactions: [
      '{reactor} 선수도 확장 서두르네요.',
      '{reactor} 선수 견제 나갈 타이밍인데요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'업그레이드|업그'), triggerRace: '*', reactorRace: '*', reactions: [
      '{reactor} 선수도 업그레이드 챙기구요.',
    ]),
    _InteractionRule(triggerPattern: RegExp(r'정찰|스카우트'), triggerRace: '*', reactorRace: '*', reactions: [
      '{reactor} 선수 정찰 들어옵니다.',
    ]),
  ];

  /// 인터랙션 이벤트 생성 (30-50% 확률)
  String? _getInteractionEvent({
    required String triggerText,
    required String triggerRace,
    required String reactorRace,
    required String reactorName,
  }) {
    if (_random.nextDouble() > 0.40) return null; // 60% 확률로 스킵

    for (final rule in _interactionRules) {
      if (!rule.triggerPattern.hasMatch(triggerText)) continue;
      if (rule.triggerRace != '*' && rule.triggerRace != triggerRace) continue;
      if (rule.reactorRace != '*' && rule.reactorRace != reactorRace) continue;

      final reaction = rule.reactions[_random.nextInt(rule.reactions.length)];
      return reaction.replaceAll('{reactor}', reactorName);
    }
    return null;
  }

  // ==================== 코멘터리 시스템 ====================

  /// 상황에 따른 코멘터리 (빈 라인에서만 삽입, 중복 필터링)
  String? _getCommentary({
    required SimulationState state,
    required int lineCount,
    required Player homePlayer,
    required Player awayPlayer,
    Map<String, int>? usedTexts,
  }) {
    // 50% 확률로 코멘터리 스킵 (너무 자주 나오지 않게)
    if (_random.nextDouble() > 0.50) return null;

    final armyDiff = (state.homeArmy - state.awayArmy).abs();
    final resourceDiff = (state.homeResources - state.awayResources).abs();
    final leading = state.homeArmy > state.awayArmy ? homePlayer : awayPlayer;
    final trailing = state.homeArmy > state.awayArmy ? awayPlayer : homePlayer;

    // 후보 텍스트 선택 헬퍼 (이미 사용된 텍스트 제외)
    String? pickUnused(List<String> texts) {
      if (usedTexts == null) return texts[_random.nextInt(texts.length)];
      final unused = texts.where((t) => (usedTexts[t] ?? 0) == 0).toList();
      if (unused.isNotEmpty) return unused[_random.nextInt(unused.length)];
      // 모두 사용됨 → 가장 적게 사용된 것 선택
      texts.sort((a, b) => (usedTexts[a] ?? 0).compareTo(usedTexts[b] ?? 0));
      return texts.first;
    }

    // 병력 차이 크면
    if (armyDiff > 40) {
      final texts = [
        '병력 차이가 벌어지고 있습니다... 이거 위험한데요?',
        '${leading.name} 선수 병력이 압도적이구요!',
        '${trailing.name} 선수 이대로면 힘들어집니다.',
        '병력 격차가 점점 커지고 있습니다!',
        '${trailing.name} 선수, 병력 보충이 시급해 보입니다.',
        '${leading.name} 선수의 병력이 눈에 띄게 많아졌네요.',
        '이 병력 차이를 어떻게 극복할 수 있을까요?',
      ];
      return pickUnused(texts);
    }

    // 자원 차이 크면
    if (resourceDiff > 200) {
      final rLeading = state.homeResources > state.awayResources ? homePlayer : awayPlayer;
      final rTrailing = state.homeResources > state.awayResources ? awayPlayer : homePlayer;
      final texts = [
        '자원 차이가 크구요, 이대로라면 후반이 어려워집니다.',
        '${rLeading.name} 선수가 경제적으로 크게 앞서고 있네요.',
        '경제력 차이가 나기 시작합니다.',
        '${rTrailing.name} 선수, 자원이 부족한 상황입니다.',
        '멀티 운영 차이가 경제력 격차로 이어지고 있네요.',
        '이 경제력 차이가 후반에 큰 영향을 미칠 겁니다.',
      ];
      return pickUnused(texts);
    }

    // 접전
    if (armyDiff < 10 && lineCount > 30) {
      final texts = [
        '병력들이 돌고 도는 눈치싸움이 치열합니다.',
        '양쪽 다 팽팽한 접전을 이어가고 있네요.',
        '어느 쪽도 쉽게 물러서지 않습니다!',
        '긴장감 넘치는 접전이 계속됩니다.',
        '양 선수 한치의 양보도 없는 접전입니다!',
        '미세한 차이가 승부를 가를 수 있는 상황이네요.',
        '막상막하의 대결! 한 끗 차이 싸움입니다.',
        '서로 빈틈을 노리고 있는 모습이에요.',
        '누가 먼저 움직이느냐... 이 눈치싸움이 관건입니다.',
        '정말 팽팽합니다. 양측 다 실수를 허용할 수 없어요.',
        '한 번의 실수가 경기를 결정지을 수 있는 상황!',
        '운영력 대결이 계속되고 있습니다.',
      ];
      return pickUnused(texts);
    }

    // 초반 (10줄 이하)
    if (lineCount <= 10) {
      final texts = [
        '양측 건물 올리면서 초반 운영 시작합니다.',
        '경기 초반, 양 선수 빌드 준비에 들어갑니다.',
        '아직 초반이라 탐색전이 이어지고 있네요.',
        '초반 빌드가 진행되고 있습니다.',
        '양 선수 각자의 전략을 준비하고 있네요.',
        '아직은 조용한 초반입니다.',
      ];
      return pickUnused(texts);
    }

    // 중반 (20~60줄)
    if (lineCount > 20 && lineCount <= 60) {
      final texts = [
        '경기가 점점 흥미로워지고 있습니다.',
        '중반 운영이 이번 경기의 관건이 되겠네요.',
        '테크 전환을 노리고 있는 것 같은데요!',
        '양측 모두 경제를 챙기면서 운영하고 있습니다.',
        '이 타이밍에 누가 먼저 움직이느냐가 관건입니다.',
        '중반 싸움이 본격적으로 시작됩니다!',
        '슬슬 본격적인 전투가 시작될 것 같은데요.',
        '양 선수 모두 테크업에 집중하고 있네요.',
        '앞마당 타이밍이 경기를 좌우할 수 있습니다.',
        '중반 운영에서 누가 앞서느냐가 관건이네요.',
      ];
      return pickUnused(texts);
    }

    // 후반 (60줄 이후)
    if (lineCount > 60) {
      final texts = [
        '후반이 길어지고 있습니다. 멘탈 싸움이죠.',
        '양쪽 다 최대 병력으로 한번 크게 붙어야 될 것 같은데요.',
        '후반 운영 능력이 시험받는 시간입니다.',
        '경기가 장기전으로 가고 있네요!',
        '이쯤에서 한번 큰 전투가 날 것 같습니다.',
        '자원이 고갈되기 전에 승부를 내야 합니다.',
        '후반 체력 싸움! 집중력이 관건이에요.',
        '길어지는 후반, 누가 더 버티느냐의 싸움입니다.',
      ];
      return pickUnused(texts);
    }

    return null;
  }

  // ==================== 빌드 반응 해설 시스템 ====================

  /// 빌드 반응 해설 규칙 (빌드 키워드 → 해설자 코멘터리)
  static final List<_BuildReactionRule> _buildReactionRules = [
    // 다크템플러 관련
    _BuildReactionRule(
      pattern: RegExp(r'다크템플러|다크|DT'),
      reactions: [
        '{opponent} 선수가 눈치채고 잘 막아 낼 수 있을까요!',
        '다크템플러입니다! {opponent} 선수 디텍터 준비는 됐을까요?',
        '은밀한 다크 투입! 이걸 읽었느냐가 관건입니다!',
        '다크가 나옵니다! {opponent} 선수 대비가 됐을지 궁금하네요.',
      ],
    ),
    // 럴커 관련
    _BuildReactionRule(
      pattern: RegExp(r'럴커'),
      reactions: [
        '럴커입니다! {opponent} 선수 디텍터가 있을까요?',
        '럴커 등장! 이걸로 전세가 뒤집힐 수 있습니다!',
        '럴커가 나왔는데요, {opponent} 선수 대응이 관건이겠네요!',
      ],
    ),
    // 러쉬/올인 관련
    _BuildReactionRule(
      pattern: RegExp(r'러쉬|공격|올인|돌격|질럿.*러쉬|저글링.*러쉬'),
      reactions: [
        '공격적인 선택입니다! {opponent} 선수가 버틸 수 있을까요!',
        '이 타이밍 러쉬를 막아낼 수 있을지가 관건입니다!',
        '과감한 선택! {opponent} 선수 수비 준비가 됐을까요?',
      ],
    ),
    // 드랍 관련
    _BuildReactionRule(
      pattern: RegExp(r'드랍|수송|셔틀'),
      reactions: [
        '드랍을 노리고 있습니다! {opponent} 선수가 읽을 수 있을까요?',
        '기습 드랍 준비! 이걸 읽느냐가 승부의 관건!',
        '드랍 타이밍인데요, {opponent} 선수 본진 수비가 관건입니다!',
      ],
    ),
    // 캐리어/모선 관련
    _BuildReactionRule(
      pattern: RegExp(r'캐리어|모선'),
      reactions: [
        '캐리어 전환! {opponent} 선수 대공 준비가 급해졌습니다!',
        '대함선 테크입니다! 이걸로 후반을 노리는 건가요?',
        '캐리어가 뜹니다! {opponent} 선수에겐 시간이 촉박해요!',
      ],
    ),
    // 아비터 관련
    _BuildReactionRule(
      pattern: RegExp(r'아비터'),
      reactions: [
        '아비터입니다! 리콜이 나오면 상황이 뒤집힐 수 있어요!',
        '아비터 테크! {opponent} 선수 EMP 준비가 급합니다!',
        '아비터가 나왔네요! 이 한방이 경기를 결정지을 수 있습니다!',
      ],
    ),
    // 하이템플러/스톰 관련
    _BuildReactionRule(
      pattern: RegExp(r'하이템플러|사이오닉|스톰'),
      reactions: [
        '하이템플러! 사이오닉 스톰 한 방이면 상황이 바뀝니다!',
        '스톰 테크입니다! {opponent} 선수 병력 분산이 관건이에요!',
        '하이템플러가 합류했습니다! 이 한 수가 클 수 있어요!',
      ],
    ),
    // 뮤탈리스크 관련
    _BuildReactionRule(
      pattern: RegExp(r'뮤탈리스크|뮤탈|스파이어'),
      reactions: [
        '뮤탈리스크! 공중 장악에 나섭니다!',
        '뮤탈이 뜹니다! {opponent} 선수 대공 준비가 됐을까요?',
        '스파이어 올렸습니다! 뮤탈 견제가 시작되겠네요!',
      ],
    ),
    // 배틀크루저 관련
    _BuildReactionRule(
      pattern: RegExp(r'배틀크루저|전투순양함'),
      reactions: [
        '배틀크루저입니다! 최종 병기가 나왔네요!',
        '배틀크루저 전환! {opponent} 선수가 막을 수 있을까요?',
      ],
    ),
    // 시즈탱크 관련
    _BuildReactionRule(
      pattern: RegExp(r'시즈.*모드|시즈탱크|탱크.*시즈'),
      reactions: [
        '시즈모드! 이 라인을 뚫을 수 있을까요!',
        '탱크가 자리 잡았습니다! 이 진지를 돌파해야 합니다!',
      ],
    ),
    // 핵/뉴클리어 관련
    _BuildReactionRule(
      pattern: RegExp(r'핵|뉴클리어|뉴크'),
      reactions: [
        '핵입니다!! 이걸 잡아내야 합니다!',
        '뉴클리어 준비! 이 한 방이면 끝날 수도 있어요!',
      ],
    ),
    // 리버 관련
    _BuildReactionRule(
      pattern: RegExp(r'리버'),
      reactions: [
        '리버가 나옵니다! 스캐럽 한 방이 무서운데요!',
        '리버 투입! {opponent} 선수 일꾼 관리가 관건이에요!',
      ],
    ),
    // 디파일러 관련
    _BuildReactionRule(
      pattern: RegExp(r'디파일러|플레이그|다크스웜'),
      reactions: [
        '디파일러! 이 마법 한 방이 전세를 뒤집을 수 있습니다!',
        '디파일러 합류! {opponent} 선수에게 큰 위협이 될 수 있어요!',
      ],
    ),
    // 가디언 관련
    _BuildReactionRule(
      pattern: RegExp(r'가디언'),
      reactions: [
        '가디언이 뜹니다! 지상 병력으로는 상대가 안 되는데요!',
        '가디언 전환! {opponent} 선수 대공 준비가 시급합니다!',
      ],
    ),
    // 레이스 관련
    _BuildReactionRule(
      pattern: RegExp(r'레이스'),
      reactions: [
        '레이스! 클로킹 견제가 시작되겠네요!',
        '레이스 투입! {opponent} 선수 디텍터가 준비됐을까요?',
      ],
    ),
    // 확장/멀티 관련
    _BuildReactionRule(
      pattern: RegExp(r'확장|멀티|앞마당|서드'),
      reactions: [
        '확장을 올립니다! 이 타이밍이 안전할까요?',
        '과감한 확장! {opponent} 선수가 이 틈을 노릴 수 있을텐데요!',
        '멀티 타이밍인데요, 견제가 들어오면 위험할 수 있습니다!',
      ],
    ),
  ];

  /// 빌드 반응 해설 생성 (25% 확률, 주요 빌드에만 반응)
  String? _getBuildReactionCommentary({
    required String buildText,
    required String builderName,
    required String opponentName,
    required String builderRace,
    required String opponentRace,
    Map<String, int>? usedTexts,
  }) {
    if (_random.nextDouble() > 0.25) return null; // 75% 스킵

    for (final rule in _buildReactionRules) {
      if (!rule.pattern.hasMatch(buildText)) continue;

      // 후보 텍스트 중 미사용 우선 선택
      final candidates = rule.reactions
          .map((r) => r.replaceAll('{builder}', builderName).replaceAll('{opponent}', opponentName))
          .toList();

      if (usedTexts != null) {
        final unused = candidates.where((t) => (usedTexts[t] ?? 0) == 0).toList();
        if (unused.isNotEmpty) return unused[_random.nextInt(unused.length)];
        // 모두 사용 → 가장 적게 사용된 것
        candidates.sort((a, b) => (usedTexts[a] ?? 0).compareTo(usedTexts[b] ?? 0));
        return candidates.first;
      }
      return candidates[_random.nextInt(candidates.length)];
    }
    return null;
  }

  // ==================== 어미 변환 시스템 ====================

  /// 빌드 스텝 텍스트 어미를 방송 해설 톤으로 변환 (30-40% 확률)
  String _transformEnding(String text) {
    if (_random.nextDouble() > 0.35) return text; // 65% 확률로 원본 유지

    // "~합니다." → 다양한 어미
    if (text.endsWith('합니다.')) {
      final endings = ['하구요.', '하죠.', '하네요.', '합니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    if (text.endsWith('합니다!')) {
      final endings = ['하죠!!', '하는데요!', '합니다!', '하네요!'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    // "~입니다." → 다양한 어미
    if (text.endsWith('입니다.')) {
      final endings = ['이구요.', '이죠.', '이네요.', '입니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    // "~했습니다." → 다양한 어미
    if (text.endsWith('했습니다.')) {
      final endings = ['했구요.', '했죠.', '했네요.', '했습니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 5)}$ending';
    }
    if (text.endsWith('했습니다!')) {
      final endings = ['했죠!!', '했는데요!', '했습니다!', '했네요!'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 5)}$ending';
    }
    // "~됩니다." → 다양한 어미
    if (text.endsWith('됩니다.')) {
      final endings = ['되구요.', '되죠.', '되네요.', '됩니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    // "~습니다." → 다양한 어미 (일반)
    if (text.endsWith('습니다.')) {
      final endings = ['구요.', '죠.', '네요.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    if (text.endsWith('습니다!')) {
      final endings = ['죠!!', '는데요!', '네요!'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 4)}$ending';
    }
    // "~건설!" → "~건설하구요."
    if (text.endsWith('건설!')) {
      final endings = ['건설하구요.', '건설!', '건설합니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 3)}$ending';
    }
    // "~생산!" → "~생산하구요."
    if (text.endsWith('생산!')) {
      final endings = ['생산하구요.', '생산!', '생산합니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 3)}$ending';
    }
    // "~시작!" → "~시작하구요."
    if (text.endsWith('시작!')) {
      final endings = ['시작하구요.', '시작!', '시작합니다.'];
      final ending = endings[_random.nextInt(endings.length)];
      return '${text.substring(0, text.length - 3)}$ending';
    }

    return text;
  }

  /// 현재 라인에 맞는 다음 스텝 가져오기
  BuildStep? _getNextStep(BuildOrder build, int currentIndex, int lineCount) {
    if (currentIndex >= build.steps.length) return null;

    final step = build.steps[currentIndex];
    // 현재 라인이 스텝의 라인과 같거나 지났으면 실행
    if (lineCount >= step.line) {
      return step;
    }
    return null;
  }

  /// 충돌 시뮬레이션
  _ClashResult _simulateClash({
    required Player homePlayer,
    required Player awayPlayer,
    required PlayerStats homeStats,
    required PlayerStats awayStats,
    required BuildStyle homeStyle,
    required BuildStyle awayStyle,
    required double winRate,
    required int lineCount,
    required int clashStartLine,
    required SimulationState currentState,
    GameMap? map,
    BuildType? homeBuildType,
    BuildType? awayBuildType,
    Set<String>? combinedUnitTags,
  }) {
    final clashDuration = lineCount - clashStartLine;
    final isZvZ = homePlayer.race == Race.zerg && awayPlayer.race == Race.zerg;

    // 현재 경기 단계 결정
    final gamePhase = GamePhase.fromLineCount(lineCount);
    final homeRaceStr = _getRaceString(homePlayer.race);
    final awayRaceStr = _getRaceString(awayPlayer.race);
    final matchup = '${homeRaceStr}v$awayRaceStr';

    // 단계별 가중치 적용된 능력치 계산
    final homeWeightedTotal = StatWeights.getWeightedTotal(
      sense: homeStats.sense,
      control: homeStats.control,
      attack: homeStats.attack,
      harass: homeStats.harass,
      strategy: homeStats.strategy,
      macro: homeStats.macro,
      defense: homeStats.defense,
      scout: homeStats.scout,
      phase: gamePhase,
      matchup: matchup,
    );

    final awayWeightedTotal = StatWeights.getWeightedTotal(
      sense: awayStats.sense,
      control: awayStats.control,
      attack: awayStats.attack,
      harass: awayStats.harass,
      strategy: awayStats.strategy,
      macro: awayStats.macro,
      defense: awayStats.defense,
      scout: awayStats.scout,
      phase: gamePhase,
      matchup: '${awayRaceStr}v$homeRaceStr',
    );

    // 우세한 쪽 결정 (가중치 적용된 능력치 + 공격성향)
    // 매 충돌마다 결정하여 홈/어웨이 편향 방지
    // 공격형 스타일이라도 매 이벤트마다 반드시 공격자가 되지는 않음
    // (수비형도 역습/반격/주도권 전환 가능)
    final homeAttackPower = homeStats.attack + homeStats.harass;
    final awayAttackPower = awayStats.attack + awayStats.harass;
    final homeIsAggressiveStyle = homeStyle == BuildStyle.aggressive || homeStyle == BuildStyle.cheese;
    final awayIsAggressiveStyle = awayStyle == BuildStyle.aggressive || awayStyle == BuildStyle.cheese;
    final bool isHomeAttacker;
    if (homeIsAggressiveStyle && !awayIsAggressiveStyle) {
      // 공격형 vs 비공격형: 70% 확률로 공격자 (30%는 역습/반격)
      isHomeAttacker = _random.nextDouble() < 0.70;
    } else if (awayIsAggressiveStyle && !homeIsAggressiveStyle) {
      isHomeAttacker = _random.nextDouble() >= 0.70; // away가 70% attacker
    } else {
      // 같은 스타일이면: 공격력 차이로 결정, 비슷하면 매번 랜덤
      final powerDiff = homeAttackPower - awayAttackPower;
      if (powerDiff > 50) {
        isHomeAttacker = _random.nextDouble() < 0.65; // 약간 유리
      } else if (powerDiff < -50) {
        isHomeAttacker = _random.nextDouble() >= 0.65;
      } else {
        isHomeAttacker = _random.nextBool(); // 매 충돌마다 랜덤
      }
    }

    // 충돌 이벤트 풀 (매치업별 종족 정보 + 맵 특성 + 능력치 전달)
    final attackerStats = isHomeAttacker ? homeStats : awayStats;
    final defenderStats = isHomeAttacker ? awayStats : homeStats;
    final events = BuildOrderData.getClashEvents(
      homeStyle,
      awayStyle,
      attackerRace: isHomeAttacker ? homeRaceStr : awayRaceStr,
      defenderRace: isHomeAttacker ? awayRaceStr : homeRaceStr,
      rushDistance: map?.rushDistance,
      resources: map?.resources,
      terrainComplexity: map?.terrainComplexity,
      airAccessibility: map?.airAccessibility,
      centerImportance: map?.centerImportance,
      hasIsland: map?.hasIsland,
      attackerAttack: attackerStats.attack,
      attackerHarass: attackerStats.harass,
      attackerControl: attackerStats.control,
      attackerStrategy: attackerStats.strategy,
      attackerMacro: attackerStats.macro,
      attackerSense: attackerStats.sense,
      defenderDefense: defenderStats.defense,
      defenderStrategy: defenderStats.strategy,
      defenderMacro: defenderStats.macro,
      defenderControl: defenderStats.control,
      defenderSense: defenderStats.sense,
      attackerBuildType: isHomeAttacker ? homeBuildType : awayBuildType,
      defenderBuildType: isHomeAttacker ? awayBuildType : homeBuildType,
      availableUnits: combinedUnitTags,
      gamePhase: gamePhase,
      attackerArmySize: isHomeAttacker ? currentState.homeArmy : currentState.awayArmy,
      defenderArmySize: isHomeAttacker ? currentState.awayArmy : currentState.homeArmy,
    );

    // 가중치 기반 이벤트 선택
    final event = _selectWeightedEvent(
      events: events,
      attackerStats: attackerStats,
      defenderStats: defenderStats,
      gamePhase: gamePhase,
      matchup: matchup,
    );

    // 텍스트 변환
    final attacker = isHomeAttacker ? homePlayer : awayPlayer;
    final defender = isHomeAttacker ? awayPlayer : homePlayer;
    var text = event.text
        .replaceAll('{attacker}', attacker.name)
        .replaceAll('{defender}', defender.name);

    // 병력/자원 변화 계산
    int homeArmyChange = isHomeAttacker ? event.attackerArmy : event.defenderArmy;
    int awayArmyChange = isHomeAttacker ? event.defenderArmy : event.attackerArmy;
    int homeResourceChange = isHomeAttacker ? event.attackerResource : event.defenderResource;
    int awayResourceChange = isHomeAttacker ? event.defenderResource : event.attackerResource;

    // 능력치에 따른 보정 (가중치 적용 + 차이가 클수록 더 큰 보정)
    if (event.favorsStat != null) {
      // 해당 능력치의 가중치 적용
      final statWeight = StatWeights.getCombinedWeight(event.favorsStat!, gamePhase, matchup);
      final homeStat = (_getStatValue(homeStats, event.favorsStat) * statWeight).round();
      final awayStat = (_getStatValue(awayStats, event.favorsStat) * statWeight).round();
      final statDiff = (homeStat - awayStat).abs();
      final modifier = 1.0 + (statDiff / 800).clamp(0.0, 0.3); // 최대 1.3배 (기존 500/0.5 → 800/0.3)

      if (homeStat > awayStat) {
        homeArmyChange = (homeArmyChange * (2 - modifier)).round();
        awayArmyChange = (awayArmyChange * modifier).round();
      } else if (awayStat > homeStat) {
        homeArmyChange = (homeArmyChange * modifier).round();
        awayArmyChange = (awayArmyChange * (2 - modifier)).round();
      }
    }

    // 경기 단계별 추가 보정 (병력 손실에 반영)
    final weightedDiff = homeWeightedTotal - awayWeightedTotal;
    final phaseBonus = (weightedDiff / 1500).clamp(-3.0, 3.0); // 단계별 ±3 보정 (기존 1000/5.0)

    // phaseBonus 적용: 우세한 쪽은 피해 감소, 열세 쪽은 피해 증가
    if (phaseBonus > 0) {
      homeArmyChange = (homeArmyChange * (1.0 - phaseBonus / 25)).round(); // 피해 최대 12% 감소 (기존 25%)
      awayArmyChange = (awayArmyChange * (1.0 + phaseBonus / 25)).round(); // 피해 최대 12% 증가
    } else if (phaseBonus < 0) {
      homeArmyChange = (homeArmyChange * (1.0 - phaseBonus / 25)).round();
      awayArmyChange = (awayArmyChange * (1.0 + phaseBonus / 25)).round();
    }

    // ========== 저그전 특별 규칙 (ZvZ) ==========
    // ZvZ에서는 이벤트 기반 데미지를 완전히 대체하여 ZvZ 전용 데미지만 적용
    if (isZvZ) {
      // 이벤트 기반 데미지 완전 리셋 (ZvZ 전용 로직으로 대체)
      homeArmyChange = 0;
      awayArmyChange = 0;
      homeResourceChange = 0;
      awayResourceChange = 0;

      final homeControl = homeStats.control;
      final awayControl = awayStats.control;
      final homeTotal = homeStats.total;
      final awayTotal = awayStats.total;

      // 초반 저글링 싸움 (clashDuration 0~20)
      if (clashDuration <= 20) {
        // 컨트롤 차이 (저글링 컨트롤)
        final controlDiff = (homeControl - awayControl).toDouble();

        // 수비력이 높으면 저글링 방어 성공 (선링 막기)
        final homeDefAdv = (homeStats.defense - awayStats.defense) / 300;
        final awayDefAdv = (awayStats.defense - homeStats.defense) / 300;

        // 빌드 스타일에 따른 초반 우위 (수비형 반격력 고려)
        double buildAdvantage = 0;
        if (homeStyle == BuildStyle.aggressive && awayStyle == BuildStyle.defensive) {
          buildAdvantage = 40; // 80→40: 수비형 성큰/스파인 방어 고려
        } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.aggressive) {
          buildAdvantage = -40;
        } else if (homeStyle == BuildStyle.cheese && awayStyle == BuildStyle.defensive) {
          buildAdvantage = 60; // 치즈는 여전히 높은 이점
        } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.cheese) {
          buildAdvantage = -60;
        }

        // 총합: 컨트롤 + 빌드상성 - 상대 수비력 보정
        // 수비력이 높으면 공격형의 저글링 러시를 효과적으로 방어
        // 양수 = 홈 유리, 음수 = 어웨이 유리
        final defenseCounter = (awayStats.defense - homeStats.defense) * 0.5; // 0.3→0.5: 수비력 보정 강화
        final totalDiff = controlDiff + buildAdvantage - defenseCounter;

        // 60% 확률로 전투, 40% 포지셔닝
        if (_random.nextDouble() < 0.6) {
          if (totalDiff > 150) {
            final winTexts = [
              '${homePlayer.name} 선수, 저글링 컨트롤 압도!',
              '${homePlayer.name}, 저글링 서라운드 성공! 상대 병력 녹습니다!',
              '${homePlayer.name} 선수 저글링 포지셔닝이 한 수 위!',
            ];
            text = winTexts[_random.nextInt(winTexts.length)];
            final damage = (2 + (homeTotal - awayTotal) / 3000).clamp(1, 3).round();
            awayArmyChange -= damage;
            homeArmyChange -= 1;
          } else if (totalDiff < -150) {
            final winTexts = [
              '${awayPlayer.name} 선수, 저글링 컨트롤 압도!',
              '${awayPlayer.name}, 저글링 서라운드 성공! 상대 병력 녹습니다!',
              '${awayPlayer.name} 선수 저글링 포지셔닝이 한 수 위!',
            ];
            text = winTexts[_random.nextInt(winTexts.length)];
            final damage = (2 + (awayTotal - homeTotal) / 3000).clamp(1, 3).round();
            homeArmyChange -= damage;
            awayArmyChange -= 1;
          } else {
            // 비슷한 경우 - 양쪽 소량 피해
            final evenTexts = [
              '치열한 저글링 싸움! 서로 물고 물립니다!',
              '저글링 컨트롤 대결! 양 선수 팽팽합니다!',
              '양측 저글링이 맞물리며 소모전!',
              '서로 저글링을 주고받는 치열한 접전!',
              '저글링 교전! 아슬아슬한 수 싸움!',
            ];
            text = evenTexts[_random.nextInt(evenTexts.length)];
            const baseDamage = 2;
            homeArmyChange -= (baseDamage - homeDefAdv * 0.5).clamp(1, 3).round();
            awayArmyChange -= (baseDamage - awayDefAdv * 0.5).clamp(1, 3).round();
          }
        } else {
          // 비전투 이벤트 - 소규모 교전으로 양쪽 동일 피해
          final zlingTexts = [
            '${homePlayer.name}, 상대 확장 견제!',
            '${awayPlayer.name}, 상대 확장 견제!',
            '${homePlayer.name} 선수 언덕에서 유리한 교전!',
            '${awayPlayer.name} 선수 언덕에서 유리한 교전!',
            '${homePlayer.name} 선수 국지전 승리!',
            '${awayPlayer.name} 선수 국지전 승리!',
            '${homePlayer.name}, 드론 견제로 상대 경제 흔들기!',
            '${awayPlayer.name}, 드론 견제로 상대 경제 흔들기!',
            '${homePlayer.name} 선수, 성큰 올리며 방어 태세!',
            '${awayPlayer.name} 선수, 성큰 올리며 방어 태세!',
            '${homePlayer.name}, 오버로드로 상대 빌드 정찰!',
            '${awayPlayer.name}, 오버로드로 상대 빌드 정찰!',
          ];
          text = zlingTexts[_random.nextInt(zlingTexts.length)];
          // 소규모 교전: 양쪽 동일 피해
          final minorDamage = _random.nextInt(2) + 1;
          homeArmyChange -= minorDamage;
          awayArmyChange -= minorDamage;
        }
      }

      // 중반 과도기 (clashDuration 21~29): 저글링전에서 뮤탈전으로 전환
      if (clashDuration >= 21 && clashDuration <= 29) {
        final transitionTexts = [
          '${homePlayer.name} 선수, 스파이어 건설 시작!',
          '${awayPlayer.name} 선수, 스파이어 건설 시작!',
          '양측 모두 뮤탈리스크 전환을 노리고 있습니다!',
          '${homePlayer.name} 선수, 가스 확보에 집중!',
          '${awayPlayer.name} 선수, 멀티 해처리 건설!',
          '뮤탈리스크 등장이 임박합니다!',
          '${homePlayer.name}, 레어 테크 올리며 뮤탈 준비!',
          '${awayPlayer.name}, 레어 테크 올리며 뮤탈 준비!',
          '저글링전이 소강상태... 이제 공중전 준비입니다.',
          '가스 싸움이 중요해지는 시점이네요!',
          '${homePlayer.name} 선수, 해처리 추가하며 물량 준비!',
          '${awayPlayer.name} 선수, 해처리 추가하며 물량 준비!',
        ];
        text = transitionTexts[_random.nextInt(transitionTexts.length)];
        // 전환기: 경제 성장, 소량 피해
        // 수비형은 멀티 운영으로 경제적 보상
        final homeIsDef = homeStyle == BuildStyle.defensive || homeStyle == BuildStyle.balanced;
        final awayIsDef = awayStyle == BuildStyle.defensive || awayStyle == BuildStyle.balanced;
        homeResourceChange += _random.nextInt(30) + 10 + (homeIsDef ? 15 : 0);
        awayResourceChange += _random.nextInt(30) + 10 + (awayIsDef ? 15 : 0);
        // 수비형은 병력 보충도 유리 (해처리 추가 효과)
        homeArmyChange -= _random.nextInt(2) - (homeIsDef ? 2 : 0);
        awayArmyChange -= _random.nextInt(2) - (awayIsDef ? 2 : 0);
      }

      // 뮤탈전 (clashDuration 30 이후)
      if (clashDuration >= 30) {
        // 매크로 능력치 차이 반영: 수비/운영형이 뮤탈 물량에서 유리
        final homeMacroAdv = homeStyle == BuildStyle.defensive || homeStyle == BuildStyle.balanced
            ? homeStats.macro * 0.15 : 0.0;
        final awayMacroAdv = awayStyle == BuildStyle.defensive || awayStyle == BuildStyle.balanced
            ? awayStats.macro * 0.15 : 0.0;
        final effectiveControlDiff = (homeControl - awayControl) +
                                     (homeTotal - awayTotal) / 7 +
                                     homeMacroAdv - awayMacroAdv;
        if (_random.nextDouble() < 0.35) { // 35% 확률로 뮤탈 매직
          if (effectiveControlDiff > 100) {
            final winTexts = [
              '${homePlayer.name} 선수, 뮤탈 매직 작렬!',
              '${homePlayer.name}, 뮤탈 스택으로 상대 편대 박살!',
              '${homePlayer.name} 선수 뮤탈 컨트롤이 압도적입니다!',
            ];
            text = winTexts[_random.nextInt(winTexts.length)];
            final damage = (6 + (homeTotal - awayTotal) / 1500).clamp(4, 12).round();
            awayArmyChange -= damage;
            homeArmyChange -= 2;
          } else if (effectiveControlDiff < -100) {
            final winTexts = [
              '${awayPlayer.name} 선수, 뮤탈 매직 작렬!',
              '${awayPlayer.name}, 뮤탈 스택으로 상대 편대 박살!',
              '${awayPlayer.name} 선수 뮤탈 컨트롤이 압도적입니다!',
            ];
            text = winTexts[_random.nextInt(winTexts.length)];
            final damage = (6 + (awayTotal - homeTotal) / 1500).clamp(4, 12).round();
            homeArmyChange -= damage;
            awayArmyChange -= 2;
          } else {
            final evenTexts = [
              '양측 뮤탈리스크 공중전! 팽팽한 접전!',
              '뮤탈 대 뮤탈! 치열한 공중 싸움!',
              '뮤탈리스크 편대가 엉키며 혼전!',
              '뮤탈 스택 대결! 컨트롤로 승부합니다!',
            ];
            text = evenTexts[_random.nextInt(evenTexts.length)];
            final mutalDamage = _random.nextInt(4) + 3;
            homeArmyChange -= mutalDamage;
            awayArmyChange -= mutalDamage;
          }
        } else {
          // 뮤탈 견제/일꾼 사냥
          final isHomeHarass = _random.nextBool();
          final harasser = isHomeHarass ? homePlayer : awayPlayer;
          final victim = isHomeHarass ? awayPlayer : homePlayer;
          final harassTexts = [
            '${harasser.name} 선수, 뮤탈리스크로 일꾼 사냥!',
            '${harasser.name} 선수, 오버로드 사냥 성공!',
            '${harasser.name} 선수, 뮤탈리스크 히트앤런!',
            '${harasser.name}, 뮤탈로 ${victim.name} 본진 견제!',
            '${harasser.name} 선수, 스커지로 상대 뮤탈 요격!',
            '${harasser.name}, 멀티 해처리 드론 사냥!',
          ];
          text = harassTexts[_random.nextInt(harassTexts.length)];
          // 견제: 자원 피해 위주
          if (isHomeHarass) {
            awayResourceChange -= _random.nextInt(40) + 10;
          } else {
            homeResourceChange -= _random.nextInt(40) + 10;
          }
          // 뮤탈 교전 소규모 피해
          homeArmyChange -= _random.nextInt(2) + 1;
          awayArmyChange -= _random.nextInt(2) + 1;
        }
      }
    }

    // ========== 빠른 승리 (치즈/러쉬) ==========
    bool decisive = false;
    bool? homeWinOverride; // 이변 시 승자 강제 지정

    // ZvZ 빌드 상성 이변은 메인 루프에서 우선 처리 (여기서는 생략)

    // 치즈 빌드 + 초반 (25줄 이내) = 빠른 결정 확률
    if (!decisive && (homeStyle == BuildStyle.cheese || awayStyle == BuildStyle.cheese) && lineCount <= 25) {
      final cheesePlayer = homeStyle == BuildStyle.cheese ? homePlayer : awayPlayer;
      final cheeseStats = homeStyle == BuildStyle.cheese ? homeStats : awayStats;
      final defenderStats = homeStyle == BuildStyle.cheese ? awayStats : homeStats;

      // 공격력 vs 수비력 비교
      final attackPower = cheeseStats.attack + cheeseStats.sense;
      final defensePower = defenderStats.defense + defenderStats.scout;

      // 공격력이 수비력보다 높으면 빠른 GG 확률 증가
      final cheeseSuccessRate = ((attackPower - defensePower) / 1000 + 0.15).clamp(0.05, 0.35);

      if (_random.nextDouble() < cheeseSuccessRate) {
        decisive = true;
        homeWinOverride = homeStyle == BuildStyle.cheese; // 치즈 성공한 쪽 승리
        text = '${cheesePlayer.name} 선수, 기습 성공! 상대 본진 초토화!';
      }
    }

    // 공격형 빌드 + 공격력 높음 + 초반 (35줄 이내)
    if (!decisive && lineCount <= 35) {
      final homeIsAggressive = homeStyle == BuildStyle.aggressive && homeStats.attack >= 700;
      final awayIsAggressive = awayStyle == BuildStyle.aggressive && awayStats.attack >= 700;

      if (homeIsAggressive || awayIsAggressive) {
        // 양쪽 모두 공격형이면 랜덤으로 aggressor 선택
        final bool isHomeAggressor;
        if (homeIsAggressive && awayIsAggressive) {
          isHomeAggressor = _random.nextBool();
        } else {
          isHomeAggressor = homeIsAggressive;
        }
        final aggressor = isHomeAggressor ? homePlayer : awayPlayer;
        final aggressorStats = isHomeAggressor ? homeStats : awayStats;
        final defenderStats = isHomeAggressor ? awayStats : homeStats;

        // 공격력이 수비력보다 200 이상 높으면 빠른 GG
        if (aggressorStats.attack > defenderStats.defense + 200) {
          final rushSuccessRate = 0.12 + (aggressorStats.attack - defenderStats.defense) / 3000;
          if (_random.nextDouble() < rushSuccessRate.clamp(0.05, 0.25)) {
            decisive = true;
            homeWinOverride = isHomeAggressor; // 러시 성공한 쪽 승리
            text = '${aggressor.name} 선수, 압도적인 공격! 상대 무너집니다!';
          }
        }
      }
    }

    // ========== 역전 이벤트 (열세에서 한방) ==========
    final armyRatio = currentState.homeArmy / (currentState.awayArmy + 1);
    final isHomeUnderdog = armyRatio < 0.5; // 기준 강화: 0.6 → 0.5
    final isAwayUnderdog = armyRatio > 2.0;  // 기준 강화: 1.67 → 2.0

    if (!decisive && (isHomeUnderdog || isAwayUnderdog)) {
      final underdog = isHomeUnderdog ? homePlayer : awayPlayer;
      final underdogStats = isHomeUnderdog ? homeStats : awayStats;
      final favoredStats = isHomeUnderdog ? awayStats : homeStats;

      // 역전 확률: 전략/센스가 높으면 증가, 컨트롤이 높으면 증가
      final comebackChance = (
        (underdogStats.strategy - favoredStats.strategy) / 1000 +
        (underdogStats.sense - favoredStats.sense) / 1000 +
        (underdogStats.control - favoredStats.control) / 1500 +
        0.03  // 기본 3%
      ).clamp(0.01, 0.12);

      if (_random.nextDouble() < comebackChance) {
        decisive = true;
        homeWinOverride = isHomeUnderdog; // underdog가 역전 승리
        // 역전 텍스트 선택
        final comebackTexts = [
          '${underdog.name} 선수, 불리한 상황에서 기적같은 역전!',
          '${underdog.name} 선수, 읽기 싸움 승리! 카운터 빌드 적중!',
          '대단합니다! ${underdog.name} 선수, 물량 열세를 뒤집습니다!',
          '${underdog.name} 선수, 환상적인 한방 드랍으로 역전!',
          '숨막히는 역전극! ${underdog.name} 선수 승리!',
        ];
        text = comebackTexts[_random.nextInt(comebackTexts.length)];

        // 역전 시 병력 변화 (열세였던 쪽 유리)
        if (isHomeUnderdog) {
          homeArmyChange = 0;
          awayArmyChange = -20;
        } else {
          homeArmyChange = -20;
          awayArmyChange = 0;
        }
      }
    }

    // 일반 결정적 이벤트 확률 (후반)
    // 3단계 독립 체크 → 턴당 복합 확률:
    //   clashDuration 31~50: 6% (단일 체크)
    //   clashDuration 51~80: 1-(0.94×0.88) ≈ 17.3% (2개 체크)
    //   clashDuration 81+:  1-(0.94×0.88×0.80) ≈ 33.8% (3개 체크)
    // 경기 길어질수록 결정적 이벤트 확률 급상승 → 무한 경기 방지
    if (!decisive) {
      bool armyBasedWinner() {
        if (currentState.homeArmy > currentState.awayArmy) return true;
        if (currentState.awayArmy > currentState.homeArmy) return false;
        return _random.nextBool(); // 동일하면 랜덤
      }
      if (clashDuration > 30 && _random.nextDouble() < 0.06) {
        decisive = true;
        homeWinOverride = armyBasedWinner();
      }
      if (!decisive && clashDuration > 50 && _random.nextDouble() < 0.12) {
        decisive = true;
        homeWinOverride = armyBasedWinner();
      }
      if (!decisive && clashDuration > 80 && _random.nextDouble() < 0.20) {
        decisive = true;
        homeWinOverride = armyBasedWinner();
      }
    }

    // 병력 격차가 매우 크면 결정적 이벤트 (역전 기회 지나면)
    if (!decisive && (armyRatio > 2.5 || armyRatio < 0.4)) {
      decisive = true;
      homeWinOverride = armyRatio > 2.5; // 병력 우세한 쪽이 승리
      text = armyRatio > 2.5
          ? '${homePlayer.name} 선수 상대 본진 초토화!'
          : '${awayPlayer.name} 선수 상대 본진 초토화!';
    }

    return _ClashResult(
      text: text,
      homeArmyChange: homeArmyChange,
      awayArmyChange: awayArmyChange,
      homeResourceChange: homeResourceChange,
      awayResourceChange: awayResourceChange,
      decisive: decisive,
      homeWinOverride: homeWinOverride,
    );
  }

  /// 능력치 값 가져오기
  int _getStatValue(PlayerStats stats, String? statName) {
    if (statName == null) return 500;
    switch (statName) {
      case 'sense':
        return stats.sense;
      case 'control':
        return stats.control;
      case 'attack':
        return stats.attack;
      case 'harass':
        return stats.harass;
      case 'strategy':
        return stats.strategy;
      case 'macro':
        return stats.macro;
      case 'defense':
        return stats.defense;
      case 'scout':
        return stats.scout;
      default:
        return 500;
    }
  }

  /// 승패 조건 체크
  bool? _checkWinCondition(SimulationState state, int lineCount) {
    // 병력 0 이하 = 패배
    if (state.homeArmy <= 0) return false;
    if (state.awayArmy <= 0) return true;

    // 병력 격차 승리 조건 (최소 50줄 이후에만 체크)
    if (lineCount >= 50) {
      // 병력 5:1 격차 + 상대 병력 20 이하
      if (state.homeArmy >= state.awayArmy * 5 && state.awayArmy <= 20) {
        return true;
      }
      if (state.awayArmy >= state.homeArmy * 5 && state.homeArmy <= 20) {
        return false;
      }
    }

    // 후반전 (100줄 이후) 압도적 격차
    if (lineCount >= 100) {
      // 병력 3:1 격차 + 자원 2:1 격차
      final homeScore = state.homeArmy + state.homeResources / 10;
      final awayScore = state.awayArmy + state.awayResources / 10;

      if (homeScore >= awayScore * 3) return true;
      if (awayScore >= homeScore * 3) return false;
    }

    return null;
  }

  /// 폴백 시뮬레이션 (빌드가 없을 때)
  Stream<SimulationState> _fallbackSimulation({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    required int Function() getIntervalMs,
    required double winRate,
  }) async* {
    var state = const SimulationState();

    // 경기 시작 메시지
    state = state.copyWith(
      battleLogEntries: [
        const BattleLogEntry(text: '마이프로리그, 경기 시작했습니다!', owner: LogOwner.system),
        BattleLogEntry(text: '${map.name}에서 ${homePlayer.name} 선수와 ${awayPlayer.name} 선수가 맞붙습니다.', owner: LogOwner.system),
      ],
    );
    yield state;
    await Future.delayed(Duration(milliseconds: getIntervalMs()));

    int lineCount = 0;
    const maxLines = 200;

    final homeRace = _getRaceString(homePlayer.race);
    final awayRace = _getRaceString(awayPlayer.race);

    while (!state.isFinished && lineCount < maxLines) {
      lineCount++;

      // 이벤트 생성 (중후반 이벤트 풀 사용)
      final isHomeEvent = _random.nextDouble() < (winRate > 0.5 ? 0.55 : 0.45);
      final player = isHomeEvent ? homePlayer : awayPlayer;
      final currentArmy = isHomeEvent ? state.homeArmy : state.awayArmy;
      final currentResource = isHomeEvent ? state.homeResources : state.awayResources;
      final raceStr = isHomeEvent ? homeRace : awayRace;

      String text;
      int homeArmyChange = 0;
      int awayArmyChange = 0;
      int homeResourceChange = 0;
      int awayResourceChange = 0;

      // 중후반 이벤트 풀에서 선택
      final midLateStep = BuildOrderData.getMidLateEvent(
        lineCount: lineCount,
        currentArmy: currentArmy,
        currentResource: currentResource,
        race: raceStr,
        vsRace: isHomeEvent ? awayRace : homeRace,
      );

      text = midLateStep.text.replaceAll('{player}', player.name);

      if (isHomeEvent) {
        homeArmyChange = midLateStep.myArmy;
        homeResourceChange = midLateStep.myResource;
        awayArmyChange = midLateStep.enemyArmy;
        awayResourceChange = midLateStep.enemyResource;
      } else {
        awayArmyChange = midLateStep.myArmy;
        awayResourceChange = midLateStep.myResource;
        homeArmyChange = midLateStep.enemyArmy;
        homeResourceChange = midLateStep.enemyResource;
      }

      state = state.copyWith(
        homeArmy: (state.homeArmy + homeArmyChange).clamp(0, 200),
        awayArmy: (state.awayArmy + awayArmyChange).clamp(0, 200),
        homeResources: (state.homeResources + homeResourceChange).clamp(0, 10000),
        awayResources: (state.awayResources + awayResourceChange).clamp(0, 10000),
        battleLogEntries: [...state.battleLogEntries, BattleLogEntry(text: text, owner: isHomeEvent ? LogOwner.home : LogOwner.away)],
      );

      yield state;
      await Future.delayed(Duration(milliseconds: getIntervalMs()));

      // 승패 체크
      final result = _checkWinCondition(state, lineCount);
      if (result != null) {
        final winner = result ? homePlayer : awayPlayer;
        final loser = result ? awayPlayer : homePlayer;

        state = state.copyWith(
          isFinished: true,
          homeWin: result,
          battleLogEntries: [
            ...state.battleLogEntries,
            BattleLogEntry(text: '${loser.name} 선수, GG를 선언합니다.', owner: result ? LogOwner.away : LogOwner.home),
            BattleLogEntry(text: '${winner.name} 선수 승리!', owner: LogOwner.system),
          ],
        );
        yield state;
        return;
      }
    }

    // 강제 판정
    if (!state.isFinished) {
      final homeWin = _random.nextDouble() < winRate;
      final winner = homeWin ? homePlayer : awayPlayer;
      final loser = homeWin ? awayPlayer : homePlayer;

      state = state.copyWith(
        isFinished: true,
        homeWin: homeWin,
        battleLogEntries: [
          ...state.battleLogEntries,
          BattleLogEntry(text: '${loser.name} 선수, GG를 선언합니다.', owner: homeWin ? LogOwner.away : LogOwner.home),
          BattleLogEntry(text: '${winner.name} 선수 승리!', owner: LogOwner.system),
        ],
      );
      yield state;
    }
  }

  /// 가중치 기반 이벤트 선택
  /// favorsStat이 있는 이벤트는 해당 능력치가 높을수록 발생 확률 증가
  ClashEvent _selectWeightedEvent({
    required List<ClashEvent> events,
    required PlayerStats attackerStats,
    required PlayerStats defenderStats,
    required GamePhase gamePhase,
    required String matchup,
  }) {
    if (events.isEmpty) {
      throw StateError('Events list cannot be empty');
    }

    final weightedEvents = <MapEntry<ClashEvent, double>>[];

    for (final event in events) {
      double weight = 1.0;

      // favorsStat 기반 가중치 (해당 능력치 높으면 발생 확률 증가)
      if (event.favorsStat != null) {
        // 이벤트가 수비자 유리인지 확인 (공격자 피해가 더 크면 수비자 유리)
        final isDefenderFavored = event.attackerArmy < event.defenderArmy;
        final relevantStats = isDefenderFavored ? defenderStats : attackerStats;
        final stat = _getStatValue(relevantStats, event.favorsStat);
        // 능력치 600 기준, 높을수록 가중치 증가 (최대 1.5배)
        if (stat > 600) {
          weight *= 1.0 + (stat - 600) / 800; // 800에서 1.5배
        } else if (stat < 500) {
          weight *= 0.7 + (stat / 1000); // 낮으면 감소
        }

        // 경기 단계별 가중치 추가 적용
        final phaseWeight = StatWeights.getCombinedWeight(event.favorsStat!, gamePhase, matchup);
        weight *= (0.5 + phaseWeight / 2); // 단계별 가중치 영향 (0.5 ~ 1.0)
      }

      weightedEvents.add(MapEntry(event, weight.clamp(0.3, 2.0)));
    }

    // 과다선택 방지: 개별 이벤트가 전체의 4.5%를 넘지 않도록 캡핑
    final totalWeight = weightedEvents.fold<double>(0, (sum, e) => sum + e.value);
    final maxWeight = totalWeight * 0.045;
    for (int i = 0; i < weightedEvents.length; i++) {
      if (weightedEvents[i].value > maxWeight) {
        weightedEvents[i] = MapEntry(weightedEvents[i].key, maxWeight);
      }
    }

    // 가중치 기반 랜덤 선택
    return _weightedRandomSelect(weightedEvents);
  }

  /// 가중치 기반 랜덤 선택
  ClashEvent _weightedRandomSelect(List<MapEntry<ClashEvent, double>> weightedEvents) {
    final totalWeight = weightedEvents.fold<double>(0, (sum, e) => sum + e.value);
    var randomValue = _random.nextDouble() * totalWeight;

    for (final entry in weightedEvents) {
      randomValue -= entry.value;
      if (randomValue <= 0) {
        return entry.key;
      }
    }

    // 폴백 (마지막 이벤트 반환)
    return weightedEvents.last.key;
  }
}

class _ClashResult {
  final String text;
  final int homeArmyChange;
  final int awayArmyChange;
  final int homeResourceChange;
  final int awayResourceChange;
  final bool decisive;
  final bool? homeWinOverride; // 이변 시 승자 강제 지정 (null이면 winRate 사용)

  const _ClashResult({
    required this.text,
    required this.homeArmyChange,
    required this.awayArmyChange,
    required this.homeResourceChange,
    required this.awayResourceChange,
    required this.decisive,
    this.homeWinOverride,
  });
}

/// 인터랙션 규칙 (트리거-반응 매칭)
class _InteractionRule {
  final RegExp triggerPattern;
  final String triggerRace; // T/Z/P/* (트리거 종족)
  final String reactorRace; // T/Z/P/* (반응 종족)
  final List<String> reactions; // {reactor} 플레이스홀더

  const _InteractionRule({
    required this.triggerPattern,
    required this.triggerRace,
    required this.reactorRace,
    required this.reactions,
  });
}

/// 빌드 반응 해설 규칙 (빌드 키워드 → 해설자 코멘터리)
class _BuildReactionRule {
  final RegExp pattern;
  final List<String> reactions; // {builder}, {opponent} 플레이스홀더

  const _BuildReactionRule({
    required this.pattern,
    required this.reactions,
  });
}
