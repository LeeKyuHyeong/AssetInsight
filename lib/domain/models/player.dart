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

  /// 레벨업 시 능력치 상승 적용 (8개 스탯 각각에 랜덤 상승)
  PlayerStats applyLevelUpBonus(int minGrowth, int maxGrowth) {
    final random = Random();

    int randomGrowth() {
      if (maxGrowth <= minGrowth) return minGrowth;
      return minGrowth + random.nextInt(maxGrowth - minGrowth + 1);
    }

    return PlayerStats(
      sense: (sense + randomGrowth()).clamp(0, 999),
      control: (control + randomGrowth()).clamp(0, 999),
      attack: (attack + randomGrowth()).clamp(0, 999),
      harass: (harass + randomGrowth()).clamp(0, 999),
      strategy: (strategy + randomGrowth()).clamp(0, 999),
      macro: (macro + randomGrowth()).clamp(0, 999),
      defense: (defense + randomGrowth()).clamp(0, 999),
      scout: (scout + randomGrowth()).clamp(0, 999),
    );
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

  @HiveField(11)
  final int careerSeasons; // 경력 시즌 수 (커리어 단계 결정)

  @HiveField(12)
  final String? imagePath; // 선수 사진 경로 (로컬 저장소)

  @HiveField(13)
  final int experience; // 경험치 (레벨 결정)

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
    int? careerSeasons,
    this.imagePath,
    int? experience,
  })  : careerSeasons = careerSeasons ?? _defaultCareerSeasons(levelValue),
        experience = experience ?? _defaultExperience(levelValue);

  /// levelValue를 기반으로 기본 커리어 시즌 계산 (하위 호환성)
  static int _defaultCareerSeasons(int levelValue) {
    // levelValue 1-3: 신인 (0-3 시즌)
    // levelValue 4-5: 상승세 (3-7 시즌)
    // levelValue 6-7: 전성기 (7-14 시즌)
    // levelValue 8-9: 베테랑 (14-20 시즌)
    // levelValue 10: 노장 (20+ 시즌)
    switch (levelValue) {
      case 1:
        return 0;
      case 2:
        return 2;
      case 3:
        return 3;
      case 4:
        return 5;
      case 5:
        return 7;
      case 6:
        return 10;
      case 7:
        return 13;
      case 8:
        return 16;
      case 9:
        return 19;
      case 10:
        return 22;
      default:
        return 0;
    }
  }

  /// levelValue를 기반으로 기본 경험치 계산 (하위 호환성)
  static int _defaultExperience(int levelValue) {
    // 기존 레벨에 맞는 경험치 부여 (새 테이블 기준)
    switch (levelValue) {
      case 1:
        return 0;
      case 2:
        return 200;
      case 3:
        return 500;
      case 4:
        return 1000;
      case 5:
        return 1800;
      case 6:
        return 3000;
      case 7:
        return 4500;
      case 8:
        return 6500;
      case 9:
        return 9000;
      case 10:
        return 12000;
      default:
        return 0;
    }
  }

  Race get race => Race.values[raceIndex];

  /// 레벨 (경험치 기반)
  PlayerLevel get level => PlayerLevel.fromExperience(experience);

  /// 커리어 단계 (시즌 기반)
  Career get career => Career.fromSeasons(careerSeasons);

  Grade get grade => stats.grade;
  int get displayCondition => min(condition, 100);
  bool get isFreeAgent => teamId == null;

  /// 능력치 합계 (시드 배정 시 동등 등급 비교용)
  int get totalStats => stats.total;

  /// 다음 레벨까지 남은 경험치
  int get expToNextLevel {
    final nextLevel = level.next;
    if (nextLevel == null) return 0;
    return nextLevel.requiredExp - experience;
  }

  /// 현재 레벨 내 경험치 진행률 (0.0 ~ 1.0)
  double get levelProgress {
    final nextLevel = level.next;
    if (nextLevel == null) return 1.0;
    final currentLevelExp = experience - level.requiredExp;
    final neededExp = nextLevel.requiredExp - level.requiredExp;
    return currentLevelExp / neededExp;
  }

  /// 이적료 계산 (만원) - 레벨과 커리어 모두 반영
  int get transferFee {
    final levelMultiplier = level.priceMultiplier;
    final careerMultiplier = career.priceMultiplier;
    return (grade.basePrice * levelMultiplier * careerMultiplier).round();
  }

  /// 컨디션 적용된 실제 능력치
  PlayerStats get effectiveStats => stats.applyCondition(condition);

  /// 전투 보정값 (레벨 기반, 0.0 ~ 0.38)
  double get battleBonus => level.battleBonus;

  /// 경기 후 결과 적용
  Player applyMatchResult({
    required bool isWin,
    required Grade opponentGrade,
    required Race opponentRace,
    String? opponentId,
  }) {
    // 등급 차이 계산 (-값: 상대가 높음)
    final gradeDiff = grade.compareTo(opponentGrade);

    // 성장 범위 결정 (커리어 기반)
    final growthMin = isWin ? career.winGrowthMin : career.loseGrowthMin;
    final growthMax = isWin ? career.winGrowthMax : career.loseGrowthMax;
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

    // 경험치 획득 및 레벨업 처리
    final expGain = _calculateExpGain(isWin: isWin, opponentGrade: opponentGrade);

    // 연승/연패 체크 (상대 종족 및 선수 ID 기록)
    final newRecord = isWin
        ? record.addWin(opponentRace, opponentId: opponentId)
        : record.addLoss(opponentRace, opponentId: opponentId);

    // 먼저 스탯과 컨디션 적용
    final afterMatch = copyWith(
      stats: newStats,
      condition: (condition + conditionChange).clamp(0, 110),
      record: newRecord,
    );

    // 경험치 추가 및 레벨업 보너스 적용
    return afterMatch._addExperienceWithLevelUp(expGain);
  }

  /// 경험치 획득량 계산
  int _calculateExpGain({required bool isWin, required Grade opponentGrade}) {
    // 기본 경험치: 승리 30, 패배 15
    int baseExp = isWin ? 30 : 15;

    // 상대 등급에 따른 보너스
    final gradeDiff = opponentGrade.index - grade.index;
    if (gradeDiff >= 2) {
      baseExp = (baseExp * 1.5).round(); // 2단계 이상 높은 상대
    } else if (gradeDiff == 1) {
      baseExp = (baseExp * 1.2).round(); // 1단계 높은 상대
    } else if (gradeDiff <= -2) {
      baseExp = (baseExp * 0.7).round(); // 2단계 이상 낮은 상대
    }

    return baseExp;
  }

  /// 개인리그 보너스 경험치 획득
  Player addLeagueExp(int bonusExp) {
    return _addExperienceWithLevelUp(bonusExp);
  }

  /// 경험치 추가 및 레벨업 처리 (레벨업 시 능력치 상승 적용)
  Player _addExperienceWithLevelUp(int expGain) {
    final oldLevel = level;
    final newExp = experience + expGain;
    final newLevel = PlayerLevel.fromExperience(newExp);

    // 레벨업이 없으면 경험치만 추가
    if (newLevel.value <= oldLevel.value) {
      return copyWith(experience: newExp);
    }

    // 레벨업 발생! 올라간 레벨 수만큼 능력치 상승 적용
    var newStats = stats;
    for (int lv = oldLevel.value + 1; lv <= newLevel.value; lv++) {
      final levelData = PlayerLevel.fromValue(lv);
      newStats = newStats.applyLevelUpBonus(
        levelData.levelUpGrowthMin,
        levelData.levelUpGrowthMax,
      );
    }

    return copyWith(
      experience: newExp,
      stats: newStats,
    );
  }

  /// 휴식 적용
  Player applyRest() {
    final random = Random();
    final recovery = 4 + random.nextInt(2); // +4 or +5
    return copyWith(condition: (condition + recovery).clamp(0, 110));
  }

  /// 특훈 적용 (커리어 기반 성장폭)
  Player applyTraining() {
    final newStats = stats.applyTraining(career.trainingMax);

    // 먼저 스탯과 컨디션 적용
    final afterTraining = copyWith(
      stats: newStats,
      condition: (condition - 1).clamp(0, 110),
    );

    // 특훈도 경험치 획득 (10) 및 레벨업 보너스 적용
    return afterTraining._addExperienceWithLevelUp(10);
  }

  /// 팬미팅 적용 (치어풀 획득 여부와 소지금은 외부에서 처리)
  Player applyFanMeeting() {
    return copyWith(condition: (condition - 2).clamp(0, 110));
  }

  /// 시즌 종료 시 커리어 진행 (시즌 수 증가)
  Player advanceCareer() {
    final newCareerSeasons = careerSeasons + 1;
    final random = Random();

    // 노장 단계에서 은퇴 이벤트 체크
    if (career == Career.twilight && random.nextDouble() < career.declineChance) {
      // 은퇴 대상 마킹 (실제 처리는 외부에서)
      // 여기서는 일단 커리어 시즌만 증가
    }

    return copyWith(careerSeasons: newCareerSeasons);
  }

  /// 레벨업 체크 (경험치 기반 - 자동으로 반영됨)
  /// 이 메서드는 호환성을 위해 유지하지만, 레벨은 experience getter로 자동 계산됨
  @Deprecated('레벨은 경험치로 자동 계산됩니다. advanceCareer()를 사용하세요.')
  Player checkLevelUp(int currentSeason) {
    return advanceCareer();
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
    int? careerSeasons,
    String? imagePath,
    bool clearImagePath = false,
    int? experience,
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
      careerSeasons: careerSeasons ?? this.careerSeasons,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      experience: experience ?? this.experience,
    );
  }
}
