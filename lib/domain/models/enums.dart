/// MyStar 게임 열거형 정의
library;

/// 종족
enum Race {
  terran('T', '테란'),
  zerg('Z', '저그'),
  protoss('P', '프로토스');

  final String code;
  final String koreanName;
  const Race(this.code, this.koreanName);
}

/// 등급 (F- ~ SSS, 25단계)
enum Grade {
  fMinus('F-', 0, 39),
  f('F', 40, 79),
  fPlus('F+', 80, 129),
  eMinus('E-', 130, 199),
  e('E', 200, 319),
  ePlus('E+', 320, 449),
  dMinus('D-', 450, 649),
  d('D', 650, 899),
  dPlus('D+', 900, 1199),
  cMinus('C-', 1200, 1599),
  c('C', 1600, 1999),
  cPlus('C+', 2000, 2399),
  bMinus('B-', 2400, 2799),
  b('B', 2800, 3199),
  bPlus('B+', 3200, 3599),
  aMinus('A-', 3600, 3999),
  a('A', 4000, 4399),
  aPlus('A+', 4400, 4799),
  sMinus('S-', 4800, 5199),
  s('S', 5200, 5599),
  sPlus('S+', 5600, 5999),
  ssMinus('SS-', 6000, 6399),
  ss('SS', 6400, 6799),
  ssPlus('SS+', 6800, 7199),
  sss('SSS', 7200, 7992);

  final String display;
  final int minStat;
  final int maxStat;
  const Grade(this.display, this.minStat, this.maxStat);

  /// 능력치 합계로 등급 계산
  static Grade fromTotalStats(int total) {
    for (final grade in Grade.values.reversed) {
      if (total >= grade.minStat) {
        return grade;
      }
    }
    return Grade.fMinus;
  }

  /// 등급별 기본 몸값 (만원)
  int get basePrice {
    switch (this) {
      case Grade.sss:
        return 1000;
      case Grade.ssPlus:
        return 800;
      case Grade.ss:
        return 600;
      case Grade.ssMinus:
        return 500;
      case Grade.sPlus:
        return 400;
      case Grade.s:
        return 300;
      case Grade.sMinus:
        return 250;
      case Grade.aPlus:
        return 200;
      case Grade.a:
        return 150;
      case Grade.aMinus:
        return 100;
      case Grade.bPlus:
        return 70;
      case Grade.b:
        return 50;
      case Grade.bMinus:
        return 35;
      default:
        return 20;
    }
  }

  /// 등급 간 차이 계산 (-값: 상대가 높음, +값: 내가 높음)
  int compareTo(Grade other) {
    return index - other.index;
  }
}

/// 선수 레벨 (1~20, 경험치 기반)
/// - 경기 출전으로 경험치 누적 → 레벨업
/// - 레벨당 전투 보정 +2% (최대 +38%)
/// - 레벨업 시 8개 능력치 각각 상승 (레벨 낮을수록 상승폭 큼)
/// - 레벨 20은 레전드급만 도달 가능
enum PlayerLevel {
  level1(1, 0, 0, 0),           // 시작 레벨 (상승 없음)
  level2(2, 200, 10, 45),       // 신인 폭풍 성장
  level3(3, 500, 10, 40),
  level4(4, 1000, 8, 35),
  level5(5, 1800, 8, 30),
  level6(6, 3000, 6, 25),       // 성장기
  level7(7, 4500, 6, 22),
  level8(8, 6500, 5, 20),
  level9(9, 9000, 5, 18),
  level10(10, 12000, 4, 16),    // 중견 진입
  level11(11, 16000, 4, 14),
  level12(12, 21000, 3, 12),
  level13(13, 27000, 3, 11),
  level14(14, 35000, 2, 10),    // 베테랑
  level15(15, 45000, 2, 9),
  level16(16, 58000, 2, 8),
  level17(17, 75000, 1, 7),     // 노장
  level18(18, 100000, 1, 6),
  level19(19, 135000, 1, 5),
  level20(20, 180000, 0, 10);   // 레전드 보너스

  final int value;
  final int requiredExp;      // 해당 레벨에 필요한 누적 경험치
  final int levelUpGrowthMin; // 레벨업 시 능력치 상승 최소 (각 스탯별)
  final int levelUpGrowthMax; // 레벨업 시 능력치 상승 최대 (각 스탯별)

  const PlayerLevel(this.value, this.requiredExp, this.levelUpGrowthMin, this.levelUpGrowthMax);

  /// 전투 보정 (레벨당 +2%)
  double get battleBonus => (value - 1) * 0.02;

  /// 전투 보정 퍼센트 표시용
  String get battleBonusDisplay => '+${((value - 1) * 2)}%';

  /// 이적료 계수 (레벨 높을수록 비쌈)
  double get priceMultiplier => 0.5 + (value * 0.1); // 0.6 ~ 2.5

  /// 다음 레벨
  PlayerLevel? get next {
    if (value >= 20) return null;
    return PlayerLevel.values[value]; // value가 1부터 시작하므로 index = value
  }

  /// 다음 레벨까지 필요한 경험치
  int get expToNextLevel {
    final nextLv = next;
    if (nextLv == null) return 0;
    return nextLv.requiredExp - requiredExp;
  }

  /// 경험치로 레벨 계산
  static PlayerLevel fromExperience(int exp) {
    for (final level in PlayerLevel.values.reversed) {
      if (exp >= level.requiredExp) {
        return level;
      }
    }
    return PlayerLevel.level1;
  }

  static PlayerLevel fromValue(int value) {
    return PlayerLevel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => PlayerLevel.level1,
    );
  }
}

/// 커리어 단계 (시간 기반, 성장/하락 담당)
/// - 시즌 경과에 따라 진행
/// - 성장폭과 하락 위험도 결정
enum Career {
  rookie('신인', 1.8, 20, 40, 5, 25, 50, 0.0),      // 성장 최고
  rising('상승세', 1.5, 15, 35, 0, 20, 45, 0.0),    // 성장 높음
  prime('전성기', 1.0, 5, 15, -10, 5, 35, 0.05),    // 안정
  veteran('베테랑', 0.6, -5, 5, -20, -5, 20, 0.15), // 하락 시작
  twilight('노장', 0.3, -15, 0, -35, -15, 10, 0.30); // 하락 높음

  final String koreanName;
  final double priceMultiplier; // 이적료 계수
  final int winGrowthMin;       // 승리 시 성장 최소
  final int winGrowthMax;       // 승리 시 성장 최대
  final int loseGrowthMin;      // 패배 시 성장 최소
  final int loseGrowthMax;      // 패배 시 성장 최대
  final int trainingMax;        // 특훈 시 능력치 상승 최대값
  final double declineChance;   // 시즌당 은퇴/하락 이벤트 확률

  const Career(
    this.koreanName,
    this.priceMultiplier,
    this.winGrowthMin,
    this.winGrowthMax,
    this.loseGrowthMin,
    this.loseGrowthMax,
    this.trainingMax,
    this.declineChance,
  );

  /// 다음 커리어 단계
  Career? get next {
    if (this == Career.twilight) return null;
    return Career.values[index + 1];
  }

  /// 커리어 단계별 필요 시즌 (누적)
  int get requiredSeasons {
    switch (this) {
      case Career.rookie:
        return 0;  // 시작
      case Career.rising:
        return 3;  // 3시즌 후
      case Career.prime:
        return 7;  // 7시즌 후
      case Career.veteran:
        return 14; // 14시즌 후
      case Career.twilight:
        return 20; // 20시즌 후
    }
  }

  /// 시즌 수로 커리어 단계 계산
  static Career fromSeasons(int seasons) {
    for (final career in Career.values.reversed) {
      if (seasons >= career.requiredSeasons) {
        return career;
      }
    }
    return Career.rookie;
  }

  static Career fromIndex(int index) {
    if (index < 0 || index >= Career.values.length) {
      return Career.rookie;
    }
    return Career.values[index];
  }
}

/// 아이템 종류
enum ItemType {
  consumable('소모품'),
  mouse('마우스'),
  keyboard('키보드'),
  monitor('모니터'),
  accessory('기타');

  final String koreanName;
  const ItemType(this.koreanName);
}

/// 경기 배속
enum MatchSpeed {
  x1(1, 1000),
  x2(2, 500),
  x4(4, 250),
  x8(8, 125);

  final int multiplier;
  final int intervalMs;
  const MatchSpeed(this.multiplier, this.intervalMs);
}

/// 빌드 스타일 (상위 분류)
enum BuildStyle {
  aggressive('공격형'),
  defensive('수비형'),
  balanced('밸런스'),
  cheese('치즈');

  final String koreanName;
  const BuildStyle(this.koreanName);
}

/// 세부 빌드 타입 (매치업별 구체적 빌드)
enum BuildType {
  // ==================== TvZ 빌드 ====================
  tvzBunkerDefense('tvz_bunker', 'TvZ', '벙커링', BuildStyle.defensive, ['defense', 'macro']),
  tvz2FactoryVulture('tvz_2fac_vulture', 'TvZ', '2팩 벌처', BuildStyle.aggressive, ['harass', 'control']),
  tvzSKTerran('tvz_sk', 'TvZ', 'SK테란', BuildStyle.balanced, ['harass', 'macro']),
  tvz3FactoryGoliath('tvz_3fac_goliath', 'TvZ', '3팩 골리앗', BuildStyle.defensive, ['defense', 'macro']),
  tvzWraithHarass('tvz_wraith', 'TvZ', '레이스 견제', BuildStyle.aggressive, ['harass', 'strategy']),
  tvzMechDrop('tvz_mech_drop', 'TvZ', '메카닉 드랍', BuildStyle.balanced, ['harass', 'control']),

  // ==================== TvP 빌드 ====================
  tvpDouble('tvp_double', 'TvP', '더블 커맨드', BuildStyle.defensive, ['macro', 'defense']),
  tvpFakeDouble('tvp_fake_double', 'TvP', '페이크 더블', BuildStyle.aggressive, ['attack', 'strategy']),
  tvp1FactDrop('tvp_1fac_drop', 'TvP', '원팩 드랍', BuildStyle.balanced, ['harass', 'control']),
  tvp1FactGosu('tvp_1fac_gosu', 'TvP', '원팩 고수', BuildStyle.defensive, ['defense', 'strategy']),
  tvpWraithRush('tvp_wraith_rush', 'TvP', '레이스 난사', BuildStyle.cheese, ['attack', 'harass']),

  // ==================== TvT 빌드 ====================
  tvt1FactPush('tvt_1fac_push', 'TvT', '원팩 선공', BuildStyle.aggressive, ['attack', 'control']),
  tvtProxy('tvt_proxy', 'TvT', '프록시 배럭', BuildStyle.cheese, ['attack', 'sense']),
  tvt2Barracks('tvt_2rax', 'TvT', '투배럭', BuildStyle.defensive, ['defense', 'macro']),
  tvt2Factory('tvt_2fac', 'TvT', '투팩', BuildStyle.balanced, ['macro', 'strategy']),
  tvtWraithCloak('tvt_wraith_cloak', 'TvT', '클로킹 레이스', BuildStyle.aggressive, ['harass', 'strategy']),

  // ==================== ZvT 빌드 ====================
  zvt3HatchMutal('zvt_3hatch_mutal', 'ZvT', '3해처리 뮤탈', BuildStyle.aggressive, ['harass', 'control']),
  zvt2HatchMutal('zvt_2hatch_mutal', 'ZvT', '투해처리 뮤탈', BuildStyle.balanced, ['harass', 'macro']),
  zvt2HatchLurker('zvt_2hatch_lurker', 'ZvT', '투해처리 럴커', BuildStyle.defensive, ['defense', 'strategy']),
  zvtHatchSpore('zvt_hatch_spore', 'ZvT', '해처리 스포', BuildStyle.defensive, ['defense', 'macro']),
  zvt1HatchAllIn('zvt_1hatch_allin', 'ZvT', '원해처리 올인', BuildStyle.cheese, ['attack', 'control']),

  // ==================== ZvP 빌드 ====================
  zvp3HatchHydra('zvp_3hatch_hydra', 'ZvP', '3해처리 히드라', BuildStyle.balanced, ['macro', 'defense']),
  zvp2HatchMutal('zvp_2hatch_mutal', 'ZvP', '투해처리 뮤탈', BuildStyle.aggressive, ['harass', 'control']),
  zvpScourgeDefiler('zvp_scourge_defiler', 'ZvP', '스커지 디파일러', BuildStyle.defensive, ['strategy', 'defense']),
  zvp5DroneZergling('zvp_5drone', 'ZvP', '5드론 저글링', BuildStyle.cheese, ['attack', 'sense']),

  // ==================== ZvZ 빌드 ====================
  zvzPoolFirst('zvz_pool_first', 'ZvZ', '선풀', BuildStyle.aggressive, ['attack', 'control']),
  zvz9Pool('zvz_9pool', 'ZvZ', '9풀', BuildStyle.aggressive, ['attack', 'control']),
  zvz12Hatch('zvz_12hatch', 'ZvZ', '12해처리', BuildStyle.defensive, ['macro', 'defense']),
  zvzOverPool('zvz_overpool', 'ZvZ', '오버풀', BuildStyle.balanced, ['macro', 'control']),
  zvzExtractor('zvz_extractor', 'ZvZ', '익스트랙터 트릭', BuildStyle.cheese, ['sense', 'attack']),

  // ==================== PvT 빌드 ====================
  pvt2GateZealot('pvt_2gate_zealot', 'PvT', '투게이트 질럿', BuildStyle.aggressive, ['attack', 'control']),
  pvtDarkSwing('pvt_dark_swing', 'PvT', '다크 스윙', BuildStyle.cheese, ['strategy', 'harass']),
  pvt1GateObserver('pvt_1gate_obs', 'PvT', '원게이트 옵저버', BuildStyle.defensive, ['defense', 'strategy']),
  pvtProxyDark('pvt_proxy_dark', 'PvT', '프록시 다크', BuildStyle.cheese, ['attack', 'sense']),

  // ==================== PvZ 빌드 ====================
  pvz2GateZealot('pvz_2gate_zealot', 'PvZ', '투게이트 질럿', BuildStyle.aggressive, ['attack', 'control']),
  pvzForgeCannon('pvz_forge_cannon', 'PvZ', '포지 캐논', BuildStyle.defensive, ['defense', 'macro']),
  pvzNexusFirst('pvz_nexus_first', 'PvZ', '넥서스 퍼스트', BuildStyle.defensive, ['macro', 'sense']),
  pvzCorsairReaver('pvz_corsair_reaver', 'PvZ', '커세어 리버', BuildStyle.aggressive, ['harass', 'control']),

  // ==================== PvP 빌드 ====================
  pvp2GateDragoon('pvp_2gate_dragoon', 'PvP', '투게이트 드라군', BuildStyle.balanced, ['control', 'attack']),
  pvpDarkAllIn('pvp_dark_allin', 'PvP', '다크 올인', BuildStyle.cheese, ['attack', 'strategy']),
  pvp1GateRobo('pvp_1gate_robo', 'PvP', '원게이트 로보', BuildStyle.defensive, ['defense', 'strategy']),
  pvpCannonRush('pvp_cannon_rush', 'PvP', '캐논 러시', BuildStyle.cheese, ['attack', 'sense']);

  final String id;
  final String matchup;
  final String koreanName;
  final BuildStyle parentStyle;
  final List<String> keyStats; // 핵심 능력치 2개

  const BuildType(this.id, this.matchup, this.koreanName, this.parentStyle, this.keyStats);

  /// 매치업에 맞는 빌드 목록 반환
  static List<BuildType> getByMatchup(String matchup) {
    return BuildType.values.where((b) => b.matchup == matchup).toList();
  }

  /// 매치업 + 스타일에 맞는 빌드 목록 반환
  static List<BuildType> getByMatchupAndStyle(String matchup, BuildStyle style) {
    return BuildType.values
        .where((b) => b.matchup == matchup && b.parentStyle == style)
        .toList();
  }
}

/// 빌드 상성 시스템
class BuildMatchup {
  /// 빌드 타입 간 상성 계산 (공격자 관점 보너스 %, -값은 불리)
  /// 기본 원칙: 올인 > 그리디, 그리디 > 안정형, 안정형 > 올인
  static double getBuildAdvantage(BuildType attacker, BuildType defender) {
    // 같은 빌드면 상성 없음
    if (attacker == defender) return 0;

    // 상위 스타일 기반 기본 상성
    double baseAdvantage = _getStyleAdvantage(attacker.parentStyle, defender.parentStyle);

    // 세부 빌드별 특수 상성
    baseAdvantage += _getSpecificAdvantage(attacker, defender);

    return baseAdvantage.clamp(-40, 40); // 최대 ±40%
  }

  /// 상위 스타일 간 기본 상성
  static double _getStyleAdvantage(BuildStyle attacker, BuildStyle defender) {
    // cheese > defensive (수비 빌드가 준비 전에 터뜨림)
    if (attacker == BuildStyle.cheese && defender == BuildStyle.defensive) return 25;
    // defensive > cheese (준비 완료 시 역전)
    if (attacker == BuildStyle.defensive && defender == BuildStyle.cheese) return -15;

    // aggressive > balanced (템포 선점)
    if (attacker == BuildStyle.aggressive && defender == BuildStyle.balanced) return 10;
    // balanced > aggressive (카운터)
    if (attacker == BuildStyle.balanced && defender == BuildStyle.aggressive) return 5;

    // defensive > aggressive (수비 성공 시 경제 유리)
    if (attacker == BuildStyle.defensive && defender == BuildStyle.aggressive) return 8;
    // aggressive > defensive (수비 뚫으면 끝)
    if (attacker == BuildStyle.aggressive && defender == BuildStyle.defensive) return 15;

    // cheese는 리스크 높음
    if (attacker == BuildStyle.cheese && defender == BuildStyle.aggressive) return -5;
    if (attacker == BuildStyle.cheese && defender == BuildStyle.balanced) return 10;

    return 0;
  }

  /// 세부 빌드 특수 상성
  static double _getSpecificAdvantage(BuildType attacker, BuildType defender) {
    // ZvZ 특수 상성
    if (attacker == BuildType.zvzPoolFirst && defender == BuildType.zvz12Hatch) return 20;
    if (attacker == BuildType.zvz12Hatch && defender == BuildType.zvzPoolFirst) return -25;
    if (attacker == BuildType.zvz9Pool && defender == BuildType.zvz12Hatch) return 15;
    if (attacker == BuildType.zvzOverPool && defender == BuildType.zvzPoolFirst) return 10;

    // TvZ 특수 상성
    if (attacker == BuildType.tvzBunkerDefense && defender == BuildType.zvt1HatchAllIn) return 25;
    if (attacker == BuildType.zvt3HatchMutal && defender == BuildType.tvz2FactoryVulture) return -10;

    // TvP 특수 상성
    if (attacker == BuildType.tvpFakeDouble && defender == BuildType.pvt1GateObserver) return -15;
    if (attacker == BuildType.pvtDarkSwing && defender == BuildType.tvpDouble) return 20;

    // PvZ 특수 상성
    if (attacker == BuildType.pvzForgeCannon && defender == BuildType.zvp5DroneZergling) return 30;
    if (attacker == BuildType.zvp5DroneZergling && defender == BuildType.pvzNexusFirst) return 25;

    return 0;
  }

  /// 정찰 성공 시 상성 역전 보너스
  static double getScoutBonus(int scoutStat, BuildType opponentBuild) {
    // 정찰력 700 이상이면 상대 빌드 읽기 가능
    if (scoutStat < 600) return 0;

    // cheese 빌드는 읽히면 치명적
    if (opponentBuild.parentStyle == BuildStyle.cheese) {
      return (scoutStat - 600) / 20; // 최대 +20%
    }

    // 일반 빌드도 읽으면 유리
    return (scoutStat - 600) / 40; // 최대 +10%
  }
}

/// 개인리그 단계
enum IndividualLeagueStage {
  pcBangQualifier('PC방 예선'),
  dualTournament('듀얼토너먼트'),
  groupDraw('조지명식'),
  round32('32강'),
  round16('16강'),
  quarterFinal('8강'),
  semiFinal('4강'),
  final_('결승');

  final String koreanName;
  const IndividualLeagueStage(this.koreanName);
}

/// 시즌 단계
enum SeasonPhase {
  regularSeason('정규 시즌'),
  playoffReady('플레이오프 대기'),
  playoff34('플레이오프 3,4위전'),
  individualSemiFinal('개인리그 4강'),
  playoff23('플레이오프 2,3위전'),
  individualFinal('개인리그 결승'),
  playoffFinal('플레이오프 결승'),
  seasonEnd('시즌 종료');

  final String koreanName;
  const SeasonPhase(this.koreanName);
}

/// 플레이오프 매치 타입
enum PlayoffMatchType {
  thirdFourth('3,4위전'),
  secondThird('2,3위전'),
  final_('결승전');

  final String koreanName;
  const PlayoffMatchType(this.koreanName);
}


/// 경기 단계
enum GamePhase {
  early('초반', 1, 30),
  mid('중반', 31, 80),
  late('후반', 81, 200);

  final String koreanName;
  final int startLine;
  final int endLine;

  const GamePhase(this.koreanName, this.startLine, this.endLine);

  static GamePhase fromLineCount(int lineCount) {
    if (lineCount <= 30) return GamePhase.early;
    if (lineCount <= 80) return GamePhase.mid;
    return GamePhase.late;
  }
}

/// 능력치 가중치 시스템
class StatWeights {
  /// 경기 단계별 능력치 가중치 (1.0 = 기본, 1.5 = 50% 보너스)
  static Map<String, double> getPhaseWeights(GamePhase phase) {
    switch (phase) {
      case GamePhase.early:
        return {
          'sense': 1.2,     // 빌드 선택
          'control': 1.0,
          'attack': 1.5,    // 초반 공격
          'harass': 1.0,
          'strategy': 1.3,  // 빌드 전략
          'macro': 0.8,
          'defense': 1.4,   // 초반 수비
          'scout': 1.5,     // 정찰 중요
        };
      case GamePhase.mid:
        return {
          'sense': 1.0,
          'control': 1.3,   // 교전 컨트롤
          'attack': 1.0,
          'harass': 1.5,    // 견제 전성기
          'strategy': 1.3,  // 테크 선택
          'macro': 1.2,     // 확장
          'defense': 1.0,
          'scout': 1.0,
        };
      case GamePhase.late:
        return {
          'sense': 1.0,
          'control': 1.5,   // 대규모 전투
          'attack': 1.0,
          'harass': 0.8,
          'strategy': 1.2,  // 역전 전략
          'macro': 1.5,     // 물량 싸움
          'defense': 1.0,
          'scout': 0.8,
        };
    }
  }

  /// 매치업별 핵심 능력치 가중치
  static Map<String, double> getMatchupWeights(String matchup) {
    switch (matchup) {
      // TvZ: 견제와 물량이 핵심
      case 'TvZ':
        return {
          'sense': 1.0,
          'control': 1.1,
          'attack': 1.0,
          'harass': 1.4,    // 벌처 견제
          'strategy': 1.2,
          'macro': 1.3,     // 멀티 운영
          'defense': 1.0,
          'scout': 1.2,
        };
      case 'ZvT':
        return {
          'sense': 1.0,
          'control': 1.3,   // 뮤탈 컨트롤
          'attack': 1.0,
          'harass': 1.2,
          'strategy': 1.3,  // 스웜/디파 타이밍
          'macro': 1.4,     // 멀티 확장
          'defense': 1.1,   // 럴커 수비
          'scout': 1.0,
        };

      // TvP: 컨트롤과 전략이 핵심
      case 'TvP':
        return {
          'sense': 1.0,
          'control': 1.4,   // EMP/마린 스플릿
          'attack': 1.1,
          'harass': 1.2,    // 드랍
          'strategy': 1.3,
          'macro': 1.1,
          'defense': 1.2,
          'scout': 1.1,
        };
      case 'PvT':
        return {
          'sense': 1.0,
          'control': 1.4,   // 드라군/리버
          'attack': 1.1,
          'harass': 1.3,    // 리버 드랍
          'strategy': 1.3,  // 스톰 타이밍
          'macro': 1.1,
          'defense': 1.1,
          'scout': 1.2,
        };

      // ZvP: 물량과 컨트롤이 핵심
      case 'ZvP':
        return {
          'sense': 1.0,
          'control': 1.3,
          'attack': 1.0,
          'harass': 1.2,    // 뮤탈 견제
          'strategy': 1.2,
          'macro': 1.5,     // 물량 압도
          'defense': 1.2,   // 럴커 수비
          'scout': 1.0,
        };
      case 'PvZ':
        return {
          'sense': 1.0,
          'control': 1.4,   // 스톰/리버
          'attack': 1.1,
          'harass': 1.3,    // 커세어/리버
          'strategy': 1.4,  // 스톰 타이밍
          'macro': 1.1,
          'defense': 1.0,
          'scout': 1.1,
        };

      // 동족전: 컨트롤과 센스가 핵심
      case 'TvT':
        return {
          'sense': 1.3,     // 읽기 싸움
          'control': 1.5,   // 탱크 라인
          'attack': 1.1,
          'harass': 1.2,    // 레이스
          'strategy': 1.3,
          'macro': 1.0,
          'defense': 1.0,
          'scout': 1.2,
        };
      case 'ZvZ':
        return {
          'sense': 1.3,     // 빌드 읽기
          'control': 1.5,   // 저글링/뮤탈
          'attack': 1.4,    // 선제 공격
          'harass': 1.0,
          'strategy': 1.0,
          'macro': 1.1,
          'defense': 1.3,   // 선링 방어
          'scout': 1.2,
        };
      case 'PvP':
        return {
          'sense': 1.3,     // 다크 읽기
          'control': 1.5,   // 드라군 마이크로
          'attack': 1.2,
          'harass': 1.0,
          'strategy': 1.3,  // 다크/리버
          'macro': 1.0,
          'defense': 1.1,
          'scout': 1.3,     // 다크 탐지
        };

      default:
        return {
          'sense': 1.0,
          'control': 1.0,
          'attack': 1.0,
          'harass': 1.0,
          'strategy': 1.0,
          'macro': 1.0,
          'defense': 1.0,
          'scout': 1.0,
        };
    }
  }

  /// 단계 + 매치업 복합 가중치 계산
  static double getCombinedWeight(String stat, GamePhase phase, String matchup) {
    final phaseWeights = getPhaseWeights(phase);
    final matchupWeights = getMatchupWeights(matchup);

    final phaseWeight = phaseWeights[stat] ?? 1.0;
    final matchupWeight = matchupWeights[stat] ?? 1.0;

    // 두 가중치의 기하평균 사용 (극단적 값 방지)
    return (phaseWeight * matchupWeight).clamp(0.5, 2.0);
  }

  /// 가중치 적용된 능력치 총합 계산
  static double getWeightedTotal({
    required int sense,
    required int control,
    required int attack,
    required int harass,
    required int strategy,
    required int macro,
    required int defense,
    required int scout,
    required GamePhase phase,
    required String matchup,
  }) {
    double total = 0;

    total += sense * getCombinedWeight('sense', phase, matchup);
    total += control * getCombinedWeight('control', phase, matchup);
    total += attack * getCombinedWeight('attack', phase, matchup);
    total += harass * getCombinedWeight('harass', phase, matchup);
    total += strategy * getCombinedWeight('strategy', phase, matchup);
    total += macro * getCombinedWeight('macro', phase, matchup);
    total += defense * getCombinedWeight('defense', phase, matchup);
    total += scout * getCombinedWeight('scout', phase, matchup);

    return total;
  }
}
