import 'dart:math';
import 'package:hive/hive.dart';
import 'enums.dart';

part 'player.g.dart';

/// 선수 능력치
@HiveType(typeId: 0)
class PlayerStats {
  @HiveField(0)
  final int sense; // 센스: 상대 정보 파악

  @HiveField(1)
  final int control; // 컨트롤: 유닛 조작 능력

  @HiveField(2)
  final int attack; // 공격력: 공격 플레이

  @HiveField(3)
  final int harass; // 견제: 멀티태스킹/견제

  @HiveField(4)
  final int strategy; // 전략: 빌드/전술

  @HiveField(5)
  final int macro; // 물량: 자원/멀티 관리

  @HiveField(6)
  final int defense; // 수비력: 방어 플레이

  @HiveField(7)
  final int scout; // 정찰: 정찰 능력

  const PlayerStats({
    this.sense = 0,
    this.control = 0,
    this.attack = 0,
    this.harass = 0,
    this.strategy = 0,
    this.macro = 0,
    this.defense = 0,
    this.scout = 0,
  });

  /// 능력치 합계
  int get total =>
      sense + control + attack + harass + strategy + macro + defense + scout;

  /// 등급 계산
  Grade get grade => Grade.fromTotalStats(total);

  /// 컨디션 적용된 실제 능력치
  PlayerStats applyCondition(int condition) {
    final multiplier = min(condition, 100) / 100.0;
    return PlayerStats(
      sense: (sense * multiplier).round(),
      control: (control * multiplier).round(),
      attack: (attack * multiplier).round(),
      harass: (harass * multiplier).round(),
      strategy: (strategy * multiplier).round(),
      macro: (macro * multiplier).round(),
      defense: (defense * multiplier).round(),
      scout: (scout * multiplier).round(),
    );
  }

  /// 능력치 성장/하락 적용
  PlayerStats applyGrowth(int baseGrowth) {
    final random = Random();

    int applyToStat(int stat) {
      // 능력치별 변동폭 계수
      double coefficient;
      if (stat <= 200) {
        coefficient = 1.0;
      } else if (stat <= 400) {
        coefficient = 0.8;
      } else if (stat <= 600) {
        coefficient = 0.6;
      } else if (stat <= 800) {
        coefficient = 0.4;
      } else {
        coefficient = 0.2;
      }

      final actualGrowth = (baseGrowth * coefficient).round();
      // 약간의 랜덤성 추가 (-20% ~ +20%)
      final variance = (actualGrowth * 0.2 * (random.nextDouble() * 2 - 1)).round();
      final newStat = stat + actualGrowth + variance;
      return newStat.clamp(0, 999);
    }

    return PlayerStats(
      sense: applyToStat(sense),
      control: applyToStat(control),
      attack: applyToStat(attack),
      harass: applyToStat(harass),
      strategy: applyToStat(strategy),
      macro: applyToStat(macro),
      defense: applyToStat(defense),
      scout: applyToStat(scout),
    );
  }

  /// 특훈 효과 적용 (랜덤 능력치 증가)
  PlayerStats applyTraining(int maxGrowth) {
    final random = Random();
    final statIndex = random.nextInt(8);
    final growth = random.nextInt(maxGrowth + 1);

    switch (statIndex) {
      case 0:
        return copyWith(sense: (sense + growth).clamp(0, 999));
      case 1:
        return copyWith(control: (control + growth).clamp(0, 999));
      case 2:
        return copyWith(attack: (attack + growth).clamp(0, 999));
      case 3:
        return copyWith(harass: (harass + growth).clamp(0, 999));
      case 4:
        return copyWith(strategy: (strategy + growth).clamp(0, 999));
      case 5:
        return copyWith(macro: (macro + growth).clamp(0, 999));
      case 6:
        return copyWith(defense: (defense + growth).clamp(0, 999));
      case 7:
        return copyWith(scout: (scout + growth).clamp(0, 999));
      default:
        return this;
    }
  }

  /// 장비 효과 적용
  PlayerStats applyEquipmentBonus({
    int senseBonus = 0,
    int controlBonus = 0,
    int attackBonus = 0,
    int harassBonus = 0,
    int strategyBonus = 0,
    int macroBonus = 0,
    int defenseBonus = 0,
    int scoutBonus = 0,
  }) {
    return PlayerStats(
      sense: (sense + senseBonus).clamp(0, 999),
      control: (control + controlBonus).clamp(0, 999),
      attack: (attack + attackBonus).clamp(0, 999),
      harass: (harass + harassBonus).clamp(0, 999),
      strategy: (strategy + strategyBonus).clamp(0, 999),
      macro: (macro + macroBonus).clamp(0, 999),
      defense: (defense + defenseBonus).clamp(0, 999),
      scout: (scout + scoutBonus).clamp(0, 999),
    );
  }

  PlayerStats copyWith({
    int? sense,
    int? control,
    int? attack,
    int? harass,
    int? strategy,
    int? macro,
    int? defense,
    int? scout,
  }) {
    return PlayerStats(
      sense: sense ?? this.sense,
      control: control ?? this.control,
      attack: attack ?? this.attack,
      harass: harass ?? this.harass,
      strategy: strategy ?? this.strategy,
      macro: macro ?? this.macro,
      defense: defense ?? this.defense,
      scout: scout ?? this.scout,
    );
  }

  /// 8각형 차트용 리스트
  List<double> toRadarData() {
    return [
      sense / 999.0,
      control / 999.0,
      attack / 999.0,
      harass / 999.0,
      strategy / 999.0,
      macro / 999.0,
      defense / 999.0,
      scout / 999.0,
    ];
  }

  Map<String, int> toMap() {
    return {
      '센스': sense,
      '컨트롤': control,
      '공격력': attack,
      '견제': harass,
      '전략': strategy,
      '물량': macro,
      '수비력': defense,
      '정찰': scout,
    };
  }
}

/// 선수 전적
@HiveType(typeId: 1)
class PlayerRecord {
  @HiveField(0)
  final int wins;

  @HiveField(1)
  final int losses;

  @HiveField(2)
  final int vsTerranWins;

  @HiveField(3)
  final int vsTerranLosses;

  @HiveField(4)
  final int vsZergWins;

  @HiveField(5)
  final int vsZergLosses;

  @HiveField(6)
  final int vsProtossWins;

  @HiveField(7)
  final int vsProtossLosses;

  @HiveField(8)
  final int championships; // 우승 횟수

  @HiveField(9)
  final int runnerUps; // 준우승 횟수

  @HiveField(10)
  final int currentWinStreak; // 현재 연승

  @HiveField(11)
  final int maxWinStreak; // 최대 연승

  @HiveField(12)
  final Map<String, int> vsPlayerWins; // 선수별 승리 (playerId -> wins)

  @HiveField(13)
  final Map<String, int> vsPlayerLosses; // 선수별 패배 (playerId -> losses)

  const PlayerRecord({
    this.wins = 0,
    this.losses = 0,
    this.vsTerranWins = 0,
    this.vsTerranLosses = 0,
    this.vsZergWins = 0,
    this.vsZergLosses = 0,
    this.vsProtossWins = 0,
    this.vsProtossLosses = 0,
    this.championships = 0,
    this.runnerUps = 0,
    this.currentWinStreak = 0,
    this.maxWinStreak = 0,
    this.vsPlayerWins = const {},
    this.vsPlayerLosses = const {},
  });

  /// 특정 선수와의 상대전적 조회
  (int wins, int losses) getVsPlayerRecord(String playerId) {
    final w = vsPlayerWins[playerId] ?? 0;
    final l = vsPlayerLosses[playerId] ?? 0;
    return (w, l);
  }

  /// 상대전적이 있는 모든 선수 ID 목록
  Set<String> get allOpponentIds {
    return {...vsPlayerWins.keys, ...vsPlayerLosses.keys};
  }

  double get winRate => wins + losses > 0 ? wins / (wins + losses) : 0.0;

  double get vsTerranWinRate =>
      vsTerranWins + vsTerranLosses > 0
          ? vsTerranWins / (vsTerranWins + vsTerranLosses)
          : 0.0;

  double get vsZergWinRate =>
      vsZergWins + vsZergLosses > 0
          ? vsZergWins / (vsZergWins + vsZergLosses)
          : 0.0;

  double get vsProtossWinRate =>
      vsProtossWins + vsProtossLosses > 0
          ? vsProtossWins / (vsProtossWins + vsProtossLosses)
          : 0.0;

  PlayerRecord addWin(Race opponentRace, {String? opponentId}) {
    final newVsPlayerWins = Map<String, int>.from(vsPlayerWins);
    if (opponentId != null) {
      newVsPlayerWins[opponentId] = (newVsPlayerWins[opponentId] ?? 0) + 1;
    }

    return PlayerRecord(
      wins: wins + 1,
      losses: losses,
      vsTerranWins: vsTerranWins + (opponentRace == Race.terran ? 1 : 0),
      vsTerranLosses: vsTerranLosses,
      vsZergWins: vsZergWins + (opponentRace == Race.zerg ? 1 : 0),
      vsZergLosses: vsZergLosses,
      vsProtossWins: vsProtossWins + (opponentRace == Race.protoss ? 1 : 0),
      vsProtossLosses: vsProtossLosses,
      championships: championships,
      runnerUps: runnerUps,
      currentWinStreak: currentWinStreak + 1,
      maxWinStreak: max(maxWinStreak, currentWinStreak + 1),
      vsPlayerWins: newVsPlayerWins,
      vsPlayerLosses: vsPlayerLosses,
    );
  }

  PlayerRecord addLoss(Race opponentRace, {String? opponentId}) {
    final newVsPlayerLosses = Map<String, int>.from(vsPlayerLosses);
    if (opponentId != null) {
      newVsPlayerLosses[opponentId] = (newVsPlayerLosses[opponentId] ?? 0) + 1;
    }

    return PlayerRecord(
      wins: wins,
      losses: losses + 1,
      vsTerranWins: vsTerranWins,
      vsTerranLosses: vsTerranLosses + (opponentRace == Race.terran ? 1 : 0),
      vsZergWins: vsZergWins,
      vsZergLosses: vsZergLosses + (opponentRace == Race.zerg ? 1 : 0),
      vsProtossWins: vsProtossWins,
      vsProtossLosses: vsProtossLosses + (opponentRace == Race.protoss ? 1 : 0),
      championships: championships,
      runnerUps: runnerUps,
      currentWinStreak: 0,
      maxWinStreak: maxWinStreak,
      vsPlayerWins: vsPlayerWins,
      vsPlayerLosses: newVsPlayerLosses,
    );
  }

  PlayerRecord addChampionship() {
    return PlayerRecord(
      wins: wins,
      losses: losses,
      vsTerranWins: vsTerranWins,
      vsTerranLosses: vsTerranLosses,
      vsZergWins: vsZergWins,
      vsZergLosses: vsZergLosses,
      vsProtossWins: vsProtossWins,
      vsProtossLosses: vsProtossLosses,
      championships: championships + 1,
      runnerUps: runnerUps,
      currentWinStreak: currentWinStreak,
      maxWinStreak: maxWinStreak,
      vsPlayerWins: vsPlayerWins,
      vsPlayerLosses: vsPlayerLosses,
    );
  }

  PlayerRecord addRunnerUp() {
    return PlayerRecord(
      wins: wins,
      losses: losses,
      vsTerranWins: vsTerranWins,
      vsTerranLosses: vsTerranLosses,
      vsZergWins: vsZergWins,
      vsZergLosses: vsZergLosses,
      vsProtossWins: vsProtossWins,
      vsProtossLosses: vsProtossLosses,
      championships: championships,
      runnerUps: runnerUps + 1,
      currentWinStreak: currentWinStreak,
      maxWinStreak: maxWinStreak,
      vsPlayerWins: vsPlayerWins,
      vsPlayerLosses: vsPlayerLosses,
    );
  }
}

/// 선수 모델
@HiveType(typeId: 2)
class Player {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? nickname; // ID (예: Flash, Bisu)

  @HiveField(3)
  final int raceIndex; // Race enum index

  @HiveField(4)
  final PlayerStats stats;

  @HiveField(5)
  final int levelValue; // PlayerLevel value (1-10)

  @HiveField(6)
  final int condition; // 0-110 (표시는 0-100)

  @HiveField(7)
  final PlayerRecord record;

  @HiveField(8)
  final String? teamId; // 소속팀 ID (null이면 무소속)

  @HiveField(9)
  final bool isSlump; // 슬럼프 상태

  @HiveField(10)
  final int injuryGames; // 부상으로 쉬어야 할 경기 수

  @HiveField(11)
  final int seasonSinceLastLevelUp; // 마지막 레벨업 후 경과 시즌

  @HiveField(12)
  final String? imagePath; // 선수 사진 경로 (로컬 저장소)

  Player({
    required this.id,
    required this.name,
    this.nickname,
    required this.raceIndex,
    required this.stats,
    this.levelValue = 1,
    this.condition = 100,
    this.record = const PlayerRecord(),
    this.teamId,
    this.isSlump = false,
    this.injuryGames = 0,
    this.seasonSinceLastLevelUp = 0,
    this.imagePath,
  });

  Race get race => Race.values[raceIndex];
  PlayerLevel get level => PlayerLevel.fromValue(levelValue);
  Grade get grade => stats.grade;
  int get displayCondition => min(condition, 100);
  bool get isInjured => injuryGames > 0;
  bool get isFreeAgent => teamId == null;

  /// 능력치 합계 (시드 배정 시 동등 등급 비교용)
  int get totalStats => stats.total;

  /// 이적료 계산 (만원)
  int get transferFee {
    return (grade.basePrice * level.priceMultiplier).round();
  }

  /// 컨디션 적용된 실제 능력치
  PlayerStats get effectiveStats => stats.applyCondition(condition);

  /// 경기 후 결과 적용
  Player applyMatchResult({
    required bool isWin,
    required Grade opponentGrade,
    required Race opponentRace,
    String? opponentId,
  }) {
    // 등급 차이 계산 (-값: 상대가 높음)
    final gradeDiff = grade.compareTo(opponentGrade);

    // 성장 범위 결정
    final growthMin = isWin ? level.winGrowthMin : level.loseGrowthMin;
    final growthMax = isWin ? level.winGrowthMax : level.loseGrowthMax;
    final range = growthMax - growthMin;

    // 등급 차이에 따른 실제 성장값 결정
    double position;
    if (gradeDiff <= -2) {
      position = 1.0; // 범위 상위
    } else if (gradeDiff == -1) {
      position = 0.75;
    } else if (gradeDiff == 0) {
      position = 0.5;
    } else if (gradeDiff == 1) {
      position = 0.25;
    } else {
      position = 0.0; // 범위 하위
    }

    final baseGrowth = growthMin + (range * position).round();
    final newStats = stats.applyGrowth(baseGrowth);

    // 컨디션 변화
    final conditionChange = isWin ? -4 : -5;

    // 연승/연패 체크 (상대 종족 및 선수 ID 기록)
    final newRecord = isWin
        ? record.addWin(opponentRace, opponentId: opponentId)
        : record.addLoss(opponentRace, opponentId: opponentId);

    return copyWith(
      stats: newStats,
      condition: (condition + conditionChange).clamp(0, 110),
      record: newRecord,
    );
  }

  /// 휴식 적용
  Player applyRest() {
    final random = Random();
    final recovery = 4 + random.nextInt(2); // +4 or +5
    return copyWith(condition: (condition + recovery).clamp(0, 110));
  }

  /// 특훈 적용
  Player applyTraining() {
    final newStats = stats.applyTraining(level.trainingMax);
    return copyWith(
      stats: newStats,
      condition: (condition - 1).clamp(0, 110),
    );
  }

  /// 팬미팅 적용 (치어풀 획득 여부와 소지금은 외부에서 처리)
  Player applyFanMeeting() {
    return copyWith(condition: (condition - 2).clamp(0, 110));
  }

  /// 레벨업 체크 및 적용
  Player checkLevelUp(int currentSeason) {
    final nextLevel = level.next;
    if (nextLevel == null) return this; // 이미 레벨 10

    final seasonsSinceLevelUp = seasonSinceLastLevelUp + 1;

    // 2시즌마다 레벨업
    if (seasonsSinceLevelUp >= 2) {
      final random = Random();
      // 10~20% 확률로 추가 레벨업
      final extraLevelUp = random.nextDouble() < 0.15;

      return copyWith(
        levelValue: extraLevelUp && nextLevel.next != null
            ? nextLevel.next!.value
            : nextLevel.value,
        seasonSinceLastLevelUp: 0,
      );
    }

    return copyWith(seasonSinceLastLevelUp: seasonsSinceLevelUp);
  }

  /// 슬럼프 체크 (3연패 이상 시 30% 확률)
  Player checkSlump() {
    if (record.currentWinStreak < 0 && record.currentWinStreak <= -3) {
      final random = Random();
      if (random.nextDouble() < 0.3) {
        return copyWith(
          isSlump: true,
          condition: (condition - 15).clamp(0, 110),
        );
      }
    }
    return this;
  }

  /// 슬럼프 해제 (2승 시)
  Player checkSlumpRecovery() {
    if (isSlump && record.currentWinStreak >= 2) {
      return copyWith(isSlump: false);
    }
    return this;
  }

  /// 부상 체크 (경기당 3%)
  Player checkInjury() {
    if (isInjured) return this;

    final random = Random();
    if (random.nextDouble() < 0.03) {
      final injuryDuration = 1 + random.nextInt(3); // 1~3 경기
      return copyWith(injuryGames: injuryDuration);
    }
    return this;
  }

  /// 부상 회복 (경기 후)
  Player recoverInjury() {
    if (!isInjured) return this;
    return copyWith(injuryGames: injuryGames - 1);
  }

  Player copyWith({
    String? id,
    String? name,
    String? nickname,
    int? raceIndex,
    PlayerStats? stats,
    int? levelValue,
    int? condition,
    PlayerRecord? record,
    String? teamId,
    bool? isSlump,
    int? injuryGames,
    int? seasonSinceLastLevelUp,
    String? imagePath,
    bool clearImagePath = false,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      raceIndex: raceIndex ?? this.raceIndex,
      stats: stats ?? this.stats,
      levelValue: levelValue ?? this.levelValue,
      condition: condition ?? this.condition,
      record: record ?? this.record,
      teamId: teamId ?? this.teamId,
      isSlump: isSlump ?? this.isSlump,
      injuryGames: injuryGames ?? this.injuryGames,
      seasonSinceLastLevelUp: seasonSinceLastLevelUp ?? this.seasonSinceLastLevelUp,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    );
  }
}
