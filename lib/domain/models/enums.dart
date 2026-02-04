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

/// 선수 레벨 (1~10)
enum PlayerLevel {
  level1(1, 1.8, 20, 40, 5, 25),
  level2(2, 1.5, 15, 35, 0, 20),
  level3(3, 1.3, 10, 25, -5, 15),
  level4(4, 1.0, 5, 15, -10, 5),
  level5(5, 1.0, 5, 15, -10, 5),
  level6(6, 0.8, 0, 10, -15, 0),
  level7(7, 0.8, 0, 10, -15, 0),
  level8(8, 0.5, -5, 5, -20, -5),
  level9(9, 0.3, -10, 3, -25, -10),
  level10(10, 0.1, -15, 0, -35, -15);

  final int value;
  final double priceMultiplier; // 이적료 계수
  final int winGrowthMin; // 승리 시 성장 최소
  final int winGrowthMax; // 승리 시 성장 최대
  final int loseGrowthMin; // 패배 시 성장 최소
  final int loseGrowthMax; // 패배 시 성장 최대

  const PlayerLevel(
    this.value,
    this.priceMultiplier,
    this.winGrowthMin,
    this.winGrowthMax,
    this.loseGrowthMin,
    this.loseGrowthMax,
  );

  /// 특훈 시 능력치 상승 최대값
  int get trainingMax {
    return (11 - value) * 5; // 레벨 1: 50, 레벨 10: 5
  }

  /// 다음 레벨
  PlayerLevel? get next {
    if (value >= 10) return null;
    return PlayerLevel.values[value]; // value가 1부터 시작하므로 index = value
  }

  static PlayerLevel fromValue(int value) {
    return PlayerLevel.values.firstWhere(
      (l) => l.value == value,
      orElse: () => PlayerLevel.level1,
    );
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

/// 빌드 스타일
enum BuildStyle {
  aggressive('공격형'),
  defensive('수비형'),
  balanced('밸런스'),
  cheese('치즈');

  final String koreanName;
  const BuildStyle(this.koreanName);
}

/// 특수 이벤트 타입
enum SpecialEventType {
  awakening('각성'),
  slump('슬럼프'),
  injury('부상'),
  retirement('은퇴'),
  comeback('컴백'),
  bestMatch('최고의 경기');

  final String koreanName;
  const SpecialEventType(this.koreanName);
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
