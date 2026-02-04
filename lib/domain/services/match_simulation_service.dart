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

    // 치즈 확률: 공격력에 비례 (공격력 800 이상이면 25%, 700이면 20%, 600이면 15%)
    final cheeseProb = ((stats.attack - 400) / 2000).clamp(0.05, 0.30);
    if (cheeseScore > 1400 && _random.nextDouble() < cheeseProb) {
      return BuildStyle.cheese;
    }

    final ratio = attackScore / (defenseScore + 1);
    if (ratio > 1.15) {
      return BuildStyle.aggressive;
    } else if (ratio < 0.85) {
      return BuildStyle.defensive;
    } else {
      return BuildStyle.balanced;
    }
  }

  /// 두 선수 간 승률 계산 (homePlayer 기준)
  double calculateWinRate({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
  }) {
    // 1. 종족 상성 (맵 기반)
    final raceMatchupBonus = map.matchup.getWinRate(
      homePlayer.race,
      awayPlayer.race,
    );

    // 2. 능력치 비교
    final homeStats = homePlayer.effectiveStats;
    final awayStats = awayPlayer.effectiveStats;

    final homeTotal = homeStats.total + homeCheerfulBonus;
    final awayTotal = awayStats.total + awayCheerfulBonus;

    // 능력치 차이에 따른 승률 보정 (35당 1%, 최대 ±50%)
    // SS(6400) vs B(2800) = 3600 / 35 = 102% → 50%로 클램프 → SS 95% 승률
    final statDiff = homeTotal - awayTotal;
    final statBonus = (statDiff / 35).clamp(-50, 50);

    // 3. 빌드 스타일 상성 (동일 종족 매치업에서만)
    double buildBonus = 0;
    if (homePlayer.race == awayPlayer.race) {
      final homeStyle = _determineBuildStyle(homeStats);
      final awayStyle = _determineBuildStyle(awayStats);

      // 빌드 상성 기본값: aggressive > defensive > balanced > aggressive (가위바위보)
      // ZvZ: 선풀(aggressive) vs 해처리(defensive) → 선풀 유리 +32%
      if (homeStyle == BuildStyle.aggressive && awayStyle == BuildStyle.defensive) {
        buildBonus = 32;
      } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.aggressive) {
        buildBonus = -32;
      }

      // 등급 차이가 크면 빌드 상성 효과 감소
      // 등급 차이 7000당 빌드 상성 효과 50% 감소 (매우 완만하게)
      // SS vs B (차이 3500) → 32% × 0.75 = 약 24% → 저급이 5~7% 이변 가능
      final gradeDiff = (homeTotal - awayTotal).abs();
      final buildEffectMultiplier = (1.0 - gradeDiff / 14000).clamp(0.5, 1.0);
      buildBonus *= buildEffectMultiplier;

      // 수비력이 높으면 빌드 불리 일부 상쇄 (ZvZ 선링 방어)
      if (buildBonus < 0) {
        // 빌드 불리한 쪽의 수비력이 높으면 상쇄
        final defenseAdvantage = (homeStats.defense - awayStats.defense) / 150;
        buildBonus += defenseAdvantage.clamp(0, 3); // 최대 3% 상쇄
      }
    }

    // 4. 맵 특성 보너스
    double mapBonus = 0;

    // 러시거리가 짧으면 공격력 유리
    if (map.favorsAggressive) {
      final homeAttack = homeStats.attack + homeStats.harass;
      final awayAttack = awayStats.attack + awayStats.harass;
      mapBonus += (homeAttack - awayAttack) / 200;
    }

    // 자원이 많으면 물량 유리
    if (map.favorsMacro) {
      final homeMacro = homeStats.macro + homeStats.defense;
      final awayMacro = awayStats.macro + awayStats.defense;
      mapBonus += (homeMacro - awayMacro) / 200;
    }

    // 복잡도가 높으면 전략 유리
    if (map.favorsStrategic) {
      final homeStrategy = homeStats.strategy + homeStats.sense;
      final awayStrategy = awayStats.strategy + awayStats.sense;
      mapBonus += (homeStrategy - awayStrategy) / 200;
    }

    mapBonus = mapBonus.clamp(-10, 10); // 최대 ±10%

    // 최종 승률 계산
    final baseWinRate = raceMatchupBonus.toDouble();
    final finalWinRate = (baseWinRate + statBonus + buildBonus + mapBonus).clamp(3, 97);

    return finalWinRate / 100;
  }

  /// 경기 시뮬레이션 (텍스트 없이 결과만)
  SetResult simulateMatch({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
  }) {
    final winRate = calculateWinRate(
      homePlayer: homePlayer,
      awayPlayer: awayPlayer,
      map: map,
      homeCheerfulBonus: homeCheerfulBonus,
      awayCheerfulBonus: awayCheerfulBonus,
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
  Stream<SimulationState> simulateMatchWithLog({
    required Player homePlayer,
    required Player awayPlayer,
    required GameMap map,
    required int intervalMs,
    int homeCheerfulBonus = 0,
    int awayCheerfulBonus = 0,
  }) async* {
    final winRate = calculateWinRate(
      homePlayer: homePlayer,
      awayPlayer: awayPlayer,
      map: map,
      homeCheerfulBonus: homeCheerfulBonus,
      awayCheerfulBonus: awayCheerfulBonus,
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

    // 빌드가 없으면 기본 시뮬레이션
    if (homeBuild == null || awayBuild == null) {
      yield* _fallbackSimulation(
        homePlayer: homePlayer,
        awayPlayer: awayPlayer,
        map: map,
        intervalMs: intervalMs,
        winRate: winRate,
      );
      return;
    }

    // 경기 시작 메시지
    state = state.copyWith(
      battleLogEntries: [
        const BattleLogEntry(text: '마이프로리그, 경기 시작했습니다!', owner: LogOwner.system),
        BattleLogEntry(text: '${map.name}에서 ${homePlayer.name} 선수와 ${awayPlayer.name} 선수가 맞붙습니다.', owner: LogOwner.system),
        BattleLogEntry(text: '${homePlayer.name} 선수는 ${_getBuildStyleName(homeStyle)} 빌드를 선택했습니다.', owner: LogOwner.home),
        BattleLogEntry(text: '${awayPlayer.name} 선수는 ${_getBuildStyleName(awayStyle)} 빌드를 선택했습니다.', owner: LogOwner.away),
      ],
    );
    yield state;
    await Future.delayed(Duration(milliseconds: intervalMs));

    // 빌드 진행 인덱스
    int homeIndex = 0;
    int awayIndex = 0;
    int lineCount = 0;
    const maxLines = 200;

    // 충돌 발생 여부
    bool clashOccurred = false;
    int clashStartLine = -1;

    while (!state.isFinished && lineCount < maxLines) {
      lineCount++;

      // 현재 라인에 해당하는 이벤트 결정
      final homeStep = _getNextStep(homeBuild, homeIndex, lineCount);
      final awayStep = _getNextStep(awayBuild, awayIndex, lineCount);

      // 충돌 체크 (둘 다 isClash이거나 병력 격차 일정 이상)
      // ZvZ: 한쪽이 공격형일 때 초반 충돌 발생 가능
      final isZvZ = homePlayer.race == Race.zerg && awayPlayer.race == Race.zerg;
      final isZvZAggressiveVsNonAggressive = isZvZ && (
        (homeStyle == BuildStyle.aggressive && awayStyle != BuildStyle.aggressive) ||
        (awayStyle == BuildStyle.aggressive && homeStyle != BuildStyle.aggressive)
      );

      if (!clashOccurred && (
          (homeStep?.isClash == true) ||
          (awayStep?.isClash == true) ||
          (isZvZAggressiveVsNonAggressive && lineCount >= 8) || // ZvZ 선풀vs비선풀은 8줄부터 충돌
          (lineCount >= 50 && _random.nextDouble() < 0.1) // 50줄 이후 10% 확률
      )) {
        clashOccurred = true;
        clashStartLine = lineCount;
      }

      String text = '';
      int homeArmyChange = 0;
      int awayArmyChange = 0;
      int homeResourceChange = 0;
      int awayResourceChange = 0;
      bool decisive = false;
      bool? homeWinOverride; // 이변 시 승자 강제 지정

      // ========== ZvZ 빌드 상성 이변 (우선 체크) ==========
      // _simulateClash의 다른 decisive 체크보다 먼저 실행
      if (isZvZAggressiveVsNonAggressive && lineCount >= 8 && lineCount <= 18) {
        final homeIsAggressive = homeStyle == BuildStyle.aggressive;
        final aggressorStats = homeIsAggressive ? homeStats : awayStats;
        final defenderStats = homeIsAggressive ? awayStats : homeStats;
        final aggressor = homeIsAggressive ? homePlayer : awayPlayer;
        // ignore: unused_local_variable
        final _ = homeIsAggressive ? awayPlayer : homePlayer; // defender (향후 텍스트에 사용 가능)
        final defenderStyle = homeIsAggressive ? awayStyle : homeStyle;
        final isAggressorHome = homeIsAggressive;

        // 등급 차이 (defender가 높으면 양수)
        final gradeDiff = defenderStats.total - aggressorStats.total;

        // 저급 선풀이 고급 상대를 빌드 유리로 이기는 이변
        if (gradeDiff > 1000) {
          // 이변 확률: defensive 상대면 더 높은 확률
          // defensive: 라인당 0.9% (11라인 × 0.9% ≈ 9.5% 총)
          // balanced: 라인당 0.5% (11라인 × 0.5% ≈ 5.4% 총)
          // 목표: 5~7%
          final baseChance = defenderStyle == BuildStyle.defensive ? 0.009 : 0.005;

          if (_random.nextDouble() < baseChance) {
            decisive = true;
            homeWinOverride = isAggressorHome;
            text = '${aggressor.name} 선수, 선제 저글링 공격 성공! 빌드 승리!';
          }
        }
      }

      if (!decisive && clashOccurred && lineCount >= clashStartLine) {
        // 충돌 시뮬레이션
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
        );

        text = clashResult.text;
        homeArmyChange = clashResult.homeArmyChange;
        awayArmyChange = clashResult.awayArmyChange;
        homeResourceChange = clashResult.homeResourceChange;
        awayResourceChange = clashResult.awayResourceChange;
        // decisive와 homeWinOverride는 이미 우선 체크에서 설정됐을 수 있으므로
        // clashResult 값으로 덮어쓰지 않음 (upset 우선)
        if (!decisive) {
          decisive = clashResult.decisive;
          homeWinOverride = clashResult.homeWinOverride;
        }
      } else {
        // 일반 빌드 진행 (홈과 어웨이 번갈아)
        final isHomeTurn = lineCount % 2 == 1;
        final step = isHomeTurn ? homeStep : awayStep;
        final player = isHomeTurn ? homePlayer : awayPlayer;

        if (step != null) {
          text = step.text.replaceAll('{player}', player.name);

          if (isHomeTurn) {
            homeArmyChange = step.myArmy;
            homeResourceChange = step.myResource;
            awayArmyChange = step.enemyArmy;
            awayResourceChange = step.enemyResource;
            homeIndex++;
          } else {
            awayArmyChange = step.myArmy;
            awayResourceChange = step.myResource;
            homeArmyChange = step.enemyArmy;
            homeResourceChange = step.enemyResource;
            awayIndex++;
          }
        } else {
          // 빌드 스텝이 없으면 중후반 이벤트 풀에서 선택
          final currentArmy = isHomeTurn ? state.homeArmy : state.awayArmy;
          final currentResource = isHomeTurn ? state.homeResources : state.awayResources;
          final raceStr = isHomeTurn ? homeRace : awayRace;

          final midLateStep = BuildOrderData.getMidLateEvent(
            lineCount: lineCount,
            currentArmy: currentArmy,
            currentResource: currentResource,
            race: raceStr,
          );

          text = midLateStep.text.replaceAll('{player}', player.name);

          if (isHomeTurn) {
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
        }
      }

      // 이벤트 소유자 결정
      LogOwner eventOwner = LogOwner.system;
      if (clashOccurred && lineCount >= clashStartLine) {
        eventOwner = LogOwner.clash;
      } else {
        final isHomeTurn = lineCount % 2 == 1;
        eventOwner = isHomeTurn ? LogOwner.home : LogOwner.away;
      }

      // 상태 업데이트
      state = state.copyWith(
        homeArmy: (state.homeArmy + homeArmyChange).clamp(0, 200),
        awayArmy: (state.awayArmy + awayArmyChange).clamp(0, 200),
        homeResources: (state.homeResources + homeResourceChange).clamp(0, 10000),
        awayResources: (state.awayResources + awayResourceChange).clamp(0, 10000),
        battleLogEntries: text.isNotEmpty
            ? [...state.battleLogEntries, BattleLogEntry(text: text, owner: eventOwner)]
            : state.battleLogEntries,
      );

      yield state;
      await Future.delayed(Duration(milliseconds: intervalMs));

      // 결정적 이벤트 체크
      if (decisive) {
        // homeWinOverride가 있으면 강제 지정, 없으면 winRate 사용
        final isHomeWinner = homeWinOverride ?? (_random.nextDouble() < winRate);
        final winner = isHomeWinner ? homePlayer : awayPlayer;
        final loser = isHomeWinner ? awayPlayer : homePlayer;

        state = state.copyWith(
          isFinished: true,
          homeWin: isHomeWinner,
          battleLogEntries: [
            ...state.battleLogEntries,
            BattleLogEntry(text: '${loser.name} 선수, GG를 선언합니다.', owner: isHomeWinner ? LogOwner.away : LogOwner.home),
            BattleLogEntry(text: '${winner.name} 선수 승리!', owner: LogOwner.system),
          ],
        );
        yield state;
        return;
      }

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

    // 200줄 강제 판정
    if (!state.isFinished) {
      final homeScore = state.homeArmy + (state.homeResources / 50);
      final awayScore = state.awayArmy + (state.awayResources / 50);
      final homeWin = homeScore >= awayScore;

      final winner = homeWin ? homePlayer : awayPlayer;
      final loser = homeWin ? awayPlayer : homePlayer;

      state = state.copyWith(
        isFinished: true,
        homeWin: homeWin,
        battleLogEntries: [
          ...state.battleLogEntries,
          BattleLogEntry(text: '접전 끝에 ${loser.name} 선수가 GG를 선언합니다.', owner: homeWin ? LogOwner.away : LogOwner.home),
          BattleLogEntry(text: '${winner.name} 선수가 승리를 거머쥡니다!', owner: LogOwner.system),
        ],
      );
      yield state;
    }
  }

  /// 빌드 스타일 이름
  String _getBuildStyleName(BuildStyle style) {
    switch (style) {
      case BuildStyle.aggressive:
        return '공격형';
      case BuildStyle.defensive:
        return '수비형';
      case BuildStyle.balanced:
        return '밸런스';
      case BuildStyle.cheese:
        return '기습형';
    }
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
  }) {
    final clashDuration = lineCount - clashStartLine;
    final isZvZ = homePlayer.race == Race.zerg && awayPlayer.race == Race.zerg;

    // 우세한 쪽 결정 (공격력 높은 쪽이 공격자) - 이벤트 풀 선택 전에 먼저 결정
    final homeAttackPower = homeStats.attack + homeStats.harass;
    final awayAttackPower = awayStats.attack + awayStats.harass;
    final isHomeAttacker = homeAttackPower >= awayAttackPower ||
                           homeStyle == BuildStyle.aggressive ||
                           homeStyle == BuildStyle.cheese;

    // 충돌 이벤트 풀 (매치업별 종족 정보 전달)
    final homeRaceStr = _getRaceString(homePlayer.race);
    final awayRaceStr = _getRaceString(awayPlayer.race);
    final events = BuildOrderData.getClashEvents(
      homeStyle,
      awayStyle,
      attackerRace: isHomeAttacker ? homeRaceStr : awayRaceStr,
      defenderRace: isHomeAttacker ? awayRaceStr : homeRaceStr,
    );

    // 랜덤 이벤트 선택
    final event = events[_random.nextInt(events.length)];

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

    // 능력치에 따른 보정 (차이가 클수록 더 큰 보정)
    if (event.favorsStat != null) {
      final homeStat = _getStatValue(homeStats, event.favorsStat);
      final awayStat = _getStatValue(awayStats, event.favorsStat);
      final statDiff = (homeStat - awayStat).abs();
      final modifier = 1.0 + (statDiff / 500).clamp(0.0, 0.5); // 최대 1.5배

      if (homeStat > awayStat) {
        homeArmyChange = (homeArmyChange * (2 - modifier)).round();
        awayArmyChange = (awayArmyChange * modifier).round();
      } else if (awayStat > homeStat) {
        homeArmyChange = (homeArmyChange * modifier).round();
        awayArmyChange = (awayArmyChange * (2 - modifier)).round();
      }
    }

    // ========== 저그전 특별 규칙 (ZvZ) ==========
    if (isZvZ) {
      final homeControl = homeStats.control;
      final awayControl = awayStats.control;
      final homeTotal = homeStats.total;
      final awayTotal = awayStats.total;

      // 초반 저글링 싸움 (20줄 이내)
      // 단, 이변 체크 라인(8~25)에서는 데미지를 줄여서 이변 가능성 유지
      if (lineCount <= 20) {
        // 컨트롤 + 전체 등급을 종합적으로 고려
        // 등급 차이 1000당 컨트롤 100 차이와 동등 (빌드 상성 살리기 위해 완화)
        final effectiveControlDiff = (homeControl - awayControl) +
                                     (homeTotal - awayTotal) / 10;

        // 수비력이 높으면 저글링 방어 성공 (선링 막기)
        final homeDefenseBonus = homeStats.defense / 250; // 수비력 750이면 +3
        final awayDefenseBonus = awayStats.defense / 250;

        // 빌드 스타일에 따른 초반 우위 (선풀이 해처리 상대로 초반 유리)
        double buildAdvantage = 0;
        if (homeStyle == BuildStyle.aggressive && awayStyle == BuildStyle.defensive) {
          buildAdvantage = 200; // 선풀이 해처리 상대로 컨트롤 200 이점 (강화)
        } else if (homeStyle == BuildStyle.defensive && awayStyle == BuildStyle.aggressive) {
          buildAdvantage = -200;
        }

        final totalDiff = effectiveControlDiff + buildAdvantage;

        // 데미지 감소: 기본 3, 등급 차이로 ±2 (최대 5)
        if (totalDiff > 150) {
          text = '${homePlayer.name} 선수, 저글링 컨트롤 압도!';
          final damage = (3 + (homeTotal - awayTotal) / 2000).clamp(2, 5).round();
          awayArmyChange -= damage;
        } else if (totalDiff < -150) {
          text = '${awayPlayer.name} 선수, 저글링 컨트롤 압도!';
          final damage = (3 + (awayTotal - homeTotal) / 2000).clamp(2, 5).round();
          homeArmyChange -= damage;
        } else {
          // 비슷한 경우 - 수비력 높은 쪽이 덜 손해
          text = '치열한 저글링 싸움! 서로 물고 물립니다!';
          homeArmyChange -= (3 - homeDefenseBonus).clamp(1, 4).round();
          awayArmyChange -= (3 - awayDefenseBonus).clamp(1, 4).round();
        }
      }

      // 뮤탈전 (30줄 이후)
      if (lineCount >= 30 && lineCount <= 60) {
        // 뮤탈전도 등급 차이 반영 (좀 더 완화)
        final effectiveControlDiff = (homeControl - awayControl) +
                                     (homeTotal - awayTotal) / 7;
        if (_random.nextDouble() < 0.3) { // 30% 확률로 뮤탈 매직
          if (effectiveControlDiff > 100) {
            text = '${homePlayer.name} 선수, 뮤탈 매직 작렬!';
            final damage = (8 + (homeTotal - awayTotal) / 1000).clamp(5, 15).round();
            awayArmyChange -= damage;
          } else if (effectiveControlDiff < -100) {
            text = '${awayPlayer.name} 선수, 뮤탈 매직 작렬!';
            final damage = (8 + (awayTotal - homeTotal) / 1000).clamp(5, 15).round();
            homeArmyChange -= damage;
          }
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
        text = '${cheesePlayer.name} 선수, 기습 성공! 상대 본진 초토화!';
      }
    }

    // 공격형 빌드 + 공격력 높음 + 초반 (35줄 이내)
    if (!decisive && lineCount <= 35) {
      final homeIsAggressive = homeStyle == BuildStyle.aggressive && homeStats.attack >= 700;
      final awayIsAggressive = awayStyle == BuildStyle.aggressive && awayStats.attack >= 700;

      if (homeIsAggressive || awayIsAggressive) {
        final aggressor = homeIsAggressive ? homePlayer : awayPlayer;
        final aggressorStats = homeIsAggressive ? homeStats : awayStats;
        final defenderStats = homeIsAggressive ? awayStats : homeStats;

        // 공격력이 수비력보다 200 이상 높으면 빠른 GG
        if (aggressorStats.attack > defenderStats.defense + 200) {
          final rushSuccessRate = 0.12 + (aggressorStats.attack - defenderStats.defense) / 3000;
          if (_random.nextDouble() < rushSuccessRate.clamp(0.05, 0.25)) {
            decisive = true;
            text = '${aggressor.name} 선수, 압도적인 공격! 상대 무너집니다!';
          }
        }
      }
    }

    // ========== 역전 이벤트 (열세에서 한방) ==========
    final armyRatio = currentState.homeArmy / (currentState.awayArmy + 1);
    final isHomeUnderdog = armyRatio < 0.6;
    final isAwayUnderdog = armyRatio > 1.67;

    if (!decisive && (isHomeUnderdog || isAwayUnderdog)) {
      final underdog = isHomeUnderdog ? homePlayer : awayPlayer;
      final underdogStats = isHomeUnderdog ? homeStats : awayStats;
      final favoredStats = isHomeUnderdog ? awayStats : homeStats;

      // 역전 확률: 전략/센스가 높으면 증가, 컨트롤이 높으면 증가
      final comebackChance = (
        (underdogStats.strategy - favoredStats.strategy) / 1000 +
        (underdogStats.sense - favoredStats.sense) / 1000 +
        (underdogStats.control - favoredStats.control) / 1500 +
        0.08  // 기본 8%
      ).clamp(0.03, 0.20);

      if (_random.nextDouble() < comebackChance) {
        decisive = true;
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
    if (!decisive) {
      if (clashDuration > 30 && _random.nextDouble() < 0.06) {
        decisive = true;
      }
      if (clashDuration > 50 && _random.nextDouble() < 0.12) {
        decisive = true;
      }
      if (clashDuration > 80 && _random.nextDouble() < 0.20) {
        decisive = true;
      }
    }

    // 병력 격차가 매우 크면 결정적 이벤트 (역전 기회 지나면)
    if (!decisive && (armyRatio > 2.5 || armyRatio < 0.4)) {
      decisive = true;
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
    required int intervalMs,
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
    await Future.delayed(Duration(milliseconds: intervalMs));

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
      await Future.delayed(Duration(milliseconds: intervalMs));

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
