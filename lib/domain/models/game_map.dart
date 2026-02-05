import 'package:hive/hive.dart';
import 'enums.dart';

part 'game_map.g.dart';

/// 종족 상성 (특정 맵에서의 종족간 승률)
@HiveType(typeId: 9)
class RaceMatchup {
  @HiveField(0)
  final int tvzTerranWinRate; // TvZ에서 테란 승률 (0-100)

  @HiveField(1)
  final int zvpZergWinRate; // ZvP에서 저그 승률 (0-100)

  @HiveField(2)
  final int pvtProtossWinRate; // PvT에서 프로토스 승률 (0-100)

  const RaceMatchup({
    this.tvzTerranWinRate = 50,
    this.zvpZergWinRate = 50,
    this.pvtProtossWinRate = 50,
  });

  /// 두 종족 간 상성 계산 (player1의 승률 반환)
  int getWinRate(Race player1Race, Race player2Race) {
    if (player1Race == player2Race) return 50; // 동족전

    if (player1Race == Race.terran && player2Race == Race.zerg) {
      return tvzTerranWinRate;
    }
    if (player1Race == Race.zerg && player2Race == Race.terran) {
      return 100 - tvzTerranWinRate;
    }

    if (player1Race == Race.zerg && player2Race == Race.protoss) {
      return zvpZergWinRate;
    }
    if (player1Race == Race.protoss && player2Race == Race.zerg) {
      return 100 - zvpZergWinRate;
    }

    if (player1Race == Race.protoss && player2Race == Race.terran) {
      return pvtProtossWinRate;
    }
    if (player1Race == Race.terran && player2Race == Race.protoss) {
      return 100 - pvtProtossWinRate;
    }

    return 50;
  }
}

/// 게임 맵 정의
@HiveType(typeId: 10)
class GameMap {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int rushDistance; // 러시거리 (1-10, 낮을수록 가까움)

  @HiveField(3)
  final int resources; // 자원량 (1-10, 높을수록 풍부)

  @HiveField(4)
  final int complexity; // 복잡도 (1-10, 높을수록 복잡)

  @HiveField(5)
  final RaceMatchup matchup;

  @HiveField(6)
  final int expansionCount; // 멀티 개수 (2-5)

  @HiveField(7)
  final int terrainComplexity; // 지형 복잡도 - 언덕/좁은길 (1-10)

  @HiveField(8)
  final int airAccessibility; // 공중 접근성 (1-10, 높을수록 공중 유리)

  @HiveField(9)
  final int centerImportance; // 중앙 확보 중요도 (1-10)

  @HiveField(10)
  final bool hasIsland; // 섬 멀티 존재 여부

  const GameMap({
    required this.id,
    required this.name,
    this.rushDistance = 5,
    this.resources = 5,
    this.complexity = 5,
    this.matchup = const RaceMatchup(),
    this.expansionCount = 4,
    this.terrainComplexity = 5,
    this.airAccessibility = 5,
    this.centerImportance = 5,
    this.hasIsland = false,
  });

  /// 러시거리가 짧을수록 공격형 유리
  bool get favorsAggressive => rushDistance <= 4;

  /// 자원이 많을수록 운영형 유리
  bool get favorsMacro => resources >= 7;

  /// 복잡도가 높을수록 전략형 유리
  bool get favorsStrategic => complexity >= 7;

  /// 멀티 확장 용이 (확장 맵)
  bool get favorsExpansion => expansionCount >= 4 && resources >= 6;

  /// 지형이 복잡하면 수비/포지셔닝 유리
  bool get favorsDefensive => terrainComplexity >= 7;

  /// 공중 유닛 활용 맵
  bool get favorsAir => airAccessibility >= 7;

  /// 중앙 싸움 맵
  bool get favorsCenterControl => centerImportance >= 7;

  /// 맵 특성에 따른 능력치 보너스 계산 (해당 선수의 보너스)
  /// statType: 'sense', 'control', 'attack', 'harass', 'strategy', 'macro', 'defense', 'scout'
  double getStatBonus(String statType, int statValue, int opponentStatValue) {
    double bonus = 0;

    switch (statType) {
      case 'attack':
      case 'harass':
        // 러시거리 짧으면 공격/견제 보너스
        if (rushDistance <= 3) {
          bonus += (statValue - opponentStatValue) / 150;
        } else if (rushDistance <= 5) {
          bonus += (statValue - opponentStatValue) / 200;
        }
        // 공중 접근성 높으면 견제 보너스
        if (statType == 'harass' && airAccessibility >= 7) {
          bonus += (statValue - opponentStatValue) / 200;
        }
        break;

      case 'macro':
        // 멀티 많고 자원 풍부하면 물량 보너스
        if (favorsExpansion) {
          bonus += (statValue - opponentStatValue) / 120;
        } else if (resources >= 5) {
          bonus += (statValue - opponentStatValue) / 180;
        }
        break;

      case 'defense':
        // 지형 복잡하면 수비 보너스
        if (terrainComplexity >= 7) {
          bonus += (statValue - opponentStatValue) / 150;
        } else if (terrainComplexity >= 5) {
          bonus += (statValue - opponentStatValue) / 220;
        }
        break;

      case 'control':
        // 중앙 중요도 높으면 컨트롤 보너스
        if (centerImportance >= 7) {
          bonus += (statValue - opponentStatValue) / 150;
        }
        // 지형 복잡하면 컨트롤 보너스
        if (terrainComplexity >= 6) {
          bonus += (statValue - opponentStatValue) / 200;
        }
        break;

      case 'strategy':
        // 복잡도 높으면 전략 보너스
        if (complexity >= 7) {
          bonus += (statValue - opponentStatValue) / 150;
        }
        // 섬 멀티 있으면 전략 보너스
        if (hasIsland) {
          bonus += (statValue - opponentStatValue) / 250;
        }
        break;

      case 'scout':
        // 복잡한 맵일수록 정찰 중요
        if (complexity >= 6) {
          bonus += (statValue - opponentStatValue) / 200;
        }
        break;

      case 'sense':
        // 복잡도/전략성 높은 맵에서 센스 보너스
        if (complexity >= 6 || terrainComplexity >= 6) {
          bonus += (statValue - opponentStatValue) / 200;
        }
        break;
    }

    return bonus.clamp(-8, 8); // 개별 능력치당 최대 ±8%
  }

  /// 맵 전체 보너스 계산
  MapBonus calculateMapBonus({
    required int homeSense,
    required int homeControl,
    required int homeAttack,
    required int homeHarass,
    required int homeStrategy,
    required int homeMacro,
    required int homeDefense,
    required int homeScout,
    required int awaySense,
    required int awayControl,
    required int awayAttack,
    required int awayHarass,
    required int awayStrategy,
    required int awayMacro,
    required int awayDefense,
    required int awayScout,
  }) {
    double homeBonus = 0;
    double awayBonus = 0;

    // 각 능력치별 맵 보너스 계산
    homeBonus += getStatBonus('sense', homeSense, awaySense);
    homeBonus += getStatBonus('control', homeControl, awayControl);
    homeBonus += getStatBonus('attack', homeAttack, awayAttack);
    homeBonus += getStatBonus('harass', homeHarass, awayHarass);
    homeBonus += getStatBonus('strategy', homeStrategy, awayStrategy);
    homeBonus += getStatBonus('macro', homeMacro, awayMacro);
    homeBonus += getStatBonus('defense', homeDefense, awayDefense);
    homeBonus += getStatBonus('scout', homeScout, awayScout);

    awayBonus += getStatBonus('sense', awaySense, homeSense);
    awayBonus += getStatBonus('control', awayControl, homeControl);
    awayBonus += getStatBonus('attack', awayAttack, homeAttack);
    awayBonus += getStatBonus('harass', awayHarass, homeHarass);
    awayBonus += getStatBonus('strategy', awayStrategy, homeStrategy);
    awayBonus += getStatBonus('macro', awayMacro, homeMacro);
    awayBonus += getStatBonus('defense', awayDefense, homeDefense);
    awayBonus += getStatBonus('scout', awayScout, homeScout);

    return MapBonus(
      homeBonus: homeBonus.clamp(-15, 15),
      awayBonus: awayBonus.clamp(-15, 15),
    );
  }
}

/// 맵 보너스 결과
class MapBonus {
  final double homeBonus;
  final double awayBonus;

  const MapBonus({
    required this.homeBonus,
    required this.awayBonus,
  });

  /// 홈 선수 기준 순 보너스
  double get netHomeAdvantage => homeBonus - awayBonus;
}

/// 기본 맵 목록 (2010 프로리그 시즌맵 기반)
class GameMaps {
  static const neoElectricCircuit = GameMap(
    id: 'neo_electric_circuit',
    name: '네오 일렉트릭써킷',
    rushDistance: 6,
    resources: 6,
    complexity: 5,
    expansionCount: 4,
    terrainComplexity: 5,
    airAccessibility: 6,
    centerImportance: 6,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 55,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 50,
    ),
  );

  static const iccupOutlier = GameMap(
    id: 'iccup_outlier',
    name: '아웃라이어',
    rushDistance: 5,
    resources: 5,
    complexity: 6,
    expansionCount: 4,
    terrainComplexity: 7, // 언덕 많음
    airAccessibility: 5,
    centerImportance: 7,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 55,
      pvtProtossWinRate: 45,
    ),
  );

  static const chainReaction = GameMap(
    id: 'chain_reaction',
    name: '체인리액션',
    rushDistance: 7,
    resources: 7,
    complexity: 5,
    expansionCount: 5, // 멀티 많음
    terrainComplexity: 4,
    airAccessibility: 6,
    centerImportance: 5,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 45,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 55,
    ),
  );

  static const neoJade = GameMap(
    id: 'neo_jade',
    name: '네오제이드',
    rushDistance: 4, // 러시거리 짧음
    resources: 5,
    complexity: 4,
    expansionCount: 3,
    terrainComplexity: 4,
    airAccessibility: 5,
    centerImportance: 8, // 중앙 중요
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 60,
      zvpZergWinRate: 45,
      pvtProtossWinRate: 50,
    ),
  );

  static const circuitBreaker = GameMap(
    id: 'circuit_breaker',
    name: '써킷브레이커',
    rushDistance: 6,
    resources: 6,
    complexity: 6,
    expansionCount: 4,
    terrainComplexity: 6,
    airAccessibility: 6,
    centerImportance: 6,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 50,
    ),
  );

  static const newSniperRidge = GameMap(
    id: 'new_sniper_ridge',
    name: '신저격능선',
    rushDistance: 5,
    resources: 5,
    complexity: 7, // 전략 맵
    expansionCount: 4,
    terrainComplexity: 8, // 언덕/좁은길 많음
    airAccessibility: 4,
    centerImportance: 7,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 55,
      zvpZergWinRate: 45,
      pvtProtossWinRate: 55,
    ),
  );

  static const groundZero = GameMap(
    id: 'ground_zero',
    name: '그라운드제로',
    rushDistance: 8, // 러시거리 김
    resources: 8, // 자원 풍부
    complexity: 4,
    expansionCount: 5, // 멀티 많음
    terrainComplexity: 3,
    airAccessibility: 7, // 공중 유리
    centerImportance: 4,
    hasIsland: true, // 섬 멀티 있음
    matchup: RaceMatchup(
      tvzTerranWinRate: 40,
      zvpZergWinRate: 60,
      pvtProtossWinRate: 50,
    ),
  );

  static const neoBitway = GameMap(
    id: 'neo_bit_way',
    name: '네오 비트 웨이',
    rushDistance: 5,
    resources: 6,
    complexity: 5,
    expansionCount: 4,
    terrainComplexity: 5,
    airAccessibility: 7, // 드랍 유리
    centerImportance: 5,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 55,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 45,
    ),
  );

  static const destination = GameMap(
    id: 'destination',
    name: '데스티네이션',
    rushDistance: 7,
    resources: 7,
    complexity: 6,
    expansionCount: 5,
    terrainComplexity: 5,
    airAccessibility: 6,
    centerImportance: 6,
    hasIsland: true, // 섬 멀티
    matchup: RaceMatchup(
      tvzTerranWinRate: 45,
      zvpZergWinRate: 55,
      pvtProtossWinRate: 50,
    ),
  );

  static const fightingSpirit = GameMap(
    id: 'fighting_spirit',
    name: '투혼',
    rushDistance: 5,
    resources: 5,
    complexity: 5,
    expansionCount: 4,
    terrainComplexity: 5,
    airAccessibility: 5,
    centerImportance: 6,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 50,
      pvtProtossWinRate: 50,
    ),
  );

  static const matchPoint = GameMap(
    id: 'match_point',
    name: '매치포인트',
    rushDistance: 4, // 러시 맵
    resources: 4,
    complexity: 5,
    expansionCount: 3, // 멀티 적음
    terrainComplexity: 6,
    airAccessibility: 5,
    centerImportance: 8, // 중앙 싸움
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 60,
      zvpZergWinRate: 40,
      pvtProtossWinRate: 55,
    ),
  );

  static const python = GameMap(
    id: 'python',
    name: '파이썬',
    rushDistance: 6,
    resources: 6,
    complexity: 5,
    expansionCount: 4,
    terrainComplexity: 5,
    airAccessibility: 6,
    centerImportance: 5,
    hasIsland: false,
    matchup: RaceMatchup(
      tvzTerranWinRate: 50,
      zvpZergWinRate: 55,
      pvtProtossWinRate: 50,
    ),
  );

  static List<GameMap> get all => [
    neoElectricCircuit,
    iccupOutlier,
    chainReaction,
    neoJade,
    circuitBreaker,
    newSniperRidge,
    groundZero,
    neoBitway,
    destination,
    fightingSpirit,
    matchPoint,
    python,
  ];

  static GameMap? getById(String id) {
    return all.cast<GameMap?>().firstWhere(
      (m) => m?.id == id,
      orElse: () => null,
    );
  }
}
