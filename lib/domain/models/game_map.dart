import 'package:hive/hive.dart';
import 'enums.dart';
import '../../core/constants/map_data.dart';

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

/// 전체 맵 목록 (MapData에서 동적 생성)
class GameMaps {
  /// 레거시 ID → 맵 이름 매핑 (기존 세이브 호환)
  static const _legacyIdMap = {
    'neo_electric_circuit': '네오일렉트릭써킷',
    'iccup_outlier': '네오아웃라이어',
    'chain_reaction': '네오체인리액션',
    'neo_jade': '네오제이드',
    'circuit_breaker': '써킷브레이커',
    'new_sniper_ridge': '신저격능선',
    'ground_zero': '네오그라운드제로',
    'neo_bit_way': '네오벨트웨이',
    'destination': '데스티네이션',
    'fighting_spirit': '투혼',
    'match_point': '매치포인트',
    'python': '파이썬',
  };

  static List<GameMap>? _cachedAll;

  /// allMaps(MapData)에서 GameMap 동적 생성 (캐시)
  static List<GameMap> get all {
    _cachedAll ??= allMaps.map((m) => m.toGameMap()).toList();
    return _cachedAll!;
  }

  /// ID로 맵 검색 (레거시 ID 호환)
  static GameMap? getById(String id) {
    final resolvedId = _legacyIdMap[id] ?? id;
    try {
      return all.firstWhere((m) => m.id == resolvedId);
    } catch (_) {
      return null;
    }
  }

  /// 기본 맵 (투혼) - 폴백용
  static GameMap get fightingSpirit =>
      getById('투혼') ?? all.first;
}
