import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../repositories/save_repository.dart';

/// 저장소 Provider
final saveRepositoryProvider = Provider<SaveRepository>((ref) {
  return SaveRepository();
});

/// 슬롯 정보 목록 Provider
final slotInfoListProvider = FutureProvider<List<SaveSlotInfo>>((ref) async {
  final repository = ref.watch(saveRepositoryProvider);
  return repository.getSlotInfoList();
});

/// 현재 게임 상태 Provider
final gameStateProvider = StateNotifierProvider<GameStateNotifier, GameState?>((ref) {
  final repository = ref.watch(saveRepositoryProvider);
  return GameStateNotifier(repository);
});

/// 게임 상태
class GameState {
  final SaveData saveData;
  final bool isLoading;
  final String? error;

  const GameState({
    required this.saveData,
    this.isLoading = false,
    this.error,
  });

  // 편의 getter
  Team get playerTeam => saveData.playerTeam;
  Season get currentSeason => saveData.currentSeason;
  Inventory get inventory => saveData.inventory;
  List<Team> get teams => saveData.allTeams;

  List<Player> get playerTeamPlayers => saveData.getTeamPlayers(playerTeam.id);

  GameState copyWith({
    SaveData? saveData,
    bool? isLoading,
    String? error,
  }) {
    return GameState(
      saveData: saveData ?? this.saveData,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 게임 상태 관리자
class GameStateNotifier extends StateNotifier<GameState?> {
  final SaveRepository _repository;

  GameStateNotifier(this._repository) : super(null);

  /// 새 게임 시작
  Future<void> startNewGame({
    required int slotNumber,
    required String selectedTeamId,
  }) async {
    final saveData = _repository.createNewGame(
      slotNumber: slotNumber,
      selectedTeamId: selectedTeamId,
    );

    state = GameState(saveData: saveData);

    // 자동 저장
    await save();
  }

  /// 게임 로드
  Future<bool> loadGame(int slotNumber) async {
    final saveData = await _repository.load(slotNumber);
    if (saveData == null) return false;

    state = GameState(saveData: saveData);
    return true;
  }

  /// 게임 저장
  Future<void> save() async {
    if (state == null) return;

    final updatedSaveData = state!.saveData.updateSavedAt();
    await _repository.save(updatedSaveData);

    state = state!.copyWith(saveData: updatedSaveData);
  }

  /// 선수 업데이트
  void updatePlayer(Player player) {
    if (state == null) return;

    final newSaveData = state!.saveData.updatePlayer(player);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 선수 이미지 업데이트
  void updatePlayerImage(String playerId, String? imagePath) {
    if (state == null) return;

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return;

    final updatedPlayer = imagePath != null
        ? player.copyWith(imagePath: imagePath)
        : player.copyWith(clearImagePath: true);
    updatePlayer(updatedPlayer);
  }

  /// 여러 선수 업데이트
  void updatePlayers(List<Player> players) {
    if (state == null) return;

    final newSaveData = state!.saveData.updatePlayers(players);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 팀 업데이트
  void updateTeam(Team team) {
    if (state == null) return;

    final newSaveData = state!.saveData.updateTeam(team);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 시즌 업데이트
  void updateSeason(Season season) {
    if (state == null) return;

    final newSaveData = state!.saveData.updateSeason(season);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 인벤토리 업데이트
  void updateInventory(Inventory inventory) {
    if (state == null) return;

    final newSaveData = state!.saveData.updateInventory(inventory);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 행동: 휴식
  void playerRest(String playerId) {
    if (state == null) return;

    final team = state!.playerTeam;
    if (team.actionPoints < 50) return; // 행동력 부족

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return;

    final updatedPlayer = player.applyRest();
    final updatedTeam = team.spendActionPoints(50);

    updatePlayer(updatedPlayer);
    updateTeam(updatedTeam);
  }

  /// 행동: 특훈
  void playerTraining(String playerId) {
    if (state == null) return;

    final team = state!.playerTeam;
    if (team.actionPoints < 100) return; // 행동력 부족

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return;

    final updatedPlayer = player.applyTraining();
    final updatedTeam = team.spendActionPoints(100);

    updatePlayer(updatedPlayer);
    updateTeam(updatedTeam);
  }

  /// 행동: 팬미팅
  (bool gotCheerful, int moneyEarned) playerFanMeeting(String playerId) {
    if (state == null) return (false, 0);

    final team = state!.playerTeam;
    if (team.actionPoints < 200) return (false, 0); // 행동력 부족

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return (false, 0);

    final updatedPlayer = player.applyFanMeeting();

    // 치어풀 획득 확률 계산
    final grade = player.grade;
    double cheerfulChance;
    if (grade.index >= Grade.sss.index) {
      cheerfulChance = 0.55;
    } else if (grade.index >= Grade.ssMinus.index) {
      cheerfulChance = 0.50;
    } else if (grade.index >= Grade.sMinus.index) {
      cheerfulChance = 0.45;
    } else if (grade.index >= Grade.aMinus.index) {
      cheerfulChance = 0.40;
    } else {
      cheerfulChance = 0.35;
    }

    final random = DateTime.now().millisecondsSinceEpoch;
    final gotCheerful = (random % 100) / 100.0 < cheerfulChance;

    // 소지금 획득량 계산
    int minMoney, maxMoney;
    if (grade.index >= Grade.sss.index) {
      minMoney = 100;
      maxMoney = 150;
    } else if (grade.index >= Grade.ssMinus.index) {
      minMoney = 50;
      maxMoney = 100;
    } else if (grade.index >= Grade.sMinus.index) {
      minMoney = 35;
      maxMoney = 50;
    } else if (grade.index >= Grade.bMinus.index) {
      minMoney = 20;
      maxMoney = 45;
    } else {
      minMoney = 10;
      maxMoney = 35;
    }
    final moneyEarned = minMoney + (random % (maxMoney - minMoney + 1));

    var updatedTeam = team.spendActionPoints(200).addMoney(moneyEarned);
    var updatedInventory = state!.inventory;

    if (gotCheerful) {
      updatedInventory = updatedInventory.addConsumable('cheerful');
    }

    updatePlayer(updatedPlayer);
    updateTeam(updatedTeam);
    updateInventory(updatedInventory);

    return (gotCheerful, moneyEarned);
  }

  /// 아이템 구매
  bool buyItem(String itemId, int price) {
    if (state == null) return false;

    final team = state!.playerTeam;
    if (team.money < price) return false;

    final updatedTeam = team.spendMoney(price);
    final updatedInventory = state!.inventory.addConsumable(itemId);

    updateTeam(updatedTeam);
    updateInventory(updatedInventory);

    return true;
  }

  /// 장비 구매
  bool buyEquipment(Equipment equipment) {
    if (state == null) return false;

    final team = state!.playerTeam;
    if (team.money < equipment.price) return false;

    final instance = EquipmentInstance(
      equipmentId: equipment.id,
      currentDurability: equipment.durability,
    );

    final updatedTeam = team.spendMoney(equipment.price);
    final updatedInventory = state!.inventory.addEquipment(instance);

    updateTeam(updatedTeam);
    updateInventory(updatedInventory);

    return true;
  }

  /// 장비 장착
  bool equipItem(int equipmentIndex, String playerId) {
    if (state == null) return false;

    final inventory = state!.inventory;
    if (equipmentIndex < 0 || equipmentIndex >= inventory.equipments.length) {
      return false;
    }

    final equipment = inventory.equipments[equipmentIndex];
    if (equipment.equippedPlayerId != null) return false; // 이미 장착됨

    // 장비 타입 확인
    final equipmentDef = Equipments.getById(equipment.equipmentId);
    if (equipmentDef == null) return false;

    // 같은 타입의 장비가 이미 장착되어 있는지 확인
    final existingEquipment = inventory.equipments.asMap().entries.firstWhere(
      (e) {
        if (e.value.equippedPlayerId != playerId) return false;
        final def = Equipments.getById(e.value.equipmentId);
        return def?.type == equipmentDef.type;
      },
      orElse: () => MapEntry(-1, equipment),
    );

    if (existingEquipment.key != -1) {
      // 기존 장비 해제 후 새 장비 장착
      var updatedInventory = inventory.updateEquipment(
        existingEquipment.key,
        existingEquipment.value.unequip(),
      );
      updatedInventory = updatedInventory.updateEquipment(
        equipmentIndex,
        equipment.equip(playerId),
      );
      updateInventory(updatedInventory);
    } else {
      // 새 장비 장착
      final updatedInventory = inventory.updateEquipment(
        equipmentIndex,
        equipment.equip(playerId),
      );
      updateInventory(updatedInventory);
    }

    return true;
  }

  /// 장비 해제
  bool unequipItem(int equipmentIndex) {
    if (state == null) return false;

    final inventory = state!.inventory;
    if (equipmentIndex < 0 || equipmentIndex >= inventory.equipments.length) {
      return false;
    }

    final equipment = inventory.equipments[equipmentIndex];
    if (equipment.equippedPlayerId == null) return false; // 장착되어 있지 않음

    final updatedInventory = inventory.updateEquipment(
      equipmentIndex,
      equipment.unequip(),
    );
    updateInventory(updatedInventory);

    return true;
  }

  /// 선수의 장착된 장비 목록 가져오기
  List<(int index, EquipmentInstance instance, Equipment def)> getPlayerEquipments(String playerId) {
    if (state == null) return [];

    final inventory = state!.inventory;
    final result = <(int, EquipmentInstance, Equipment)>[];

    for (int i = 0; i < inventory.equipments.length; i++) {
      final instance = inventory.equipments[i];
      if (instance.equippedPlayerId == playerId) {
        final def = Equipments.getById(instance.equipmentId);
        if (def != null) {
          result.add((i, instance, def));
        }
      }
    }

    return result;
  }

  /// 장착되지 않은 장비 목록 가져오기
  List<(int index, EquipmentInstance instance, Equipment def)> getUnequippedEquipments() {
    if (state == null) return [];

    final inventory = state!.inventory;
    final result = <(int, EquipmentInstance, Equipment)>[];

    for (int i = 0; i < inventory.equipments.length; i++) {
      final instance = inventory.equipments[i];
      if (instance.equippedPlayerId == null && !instance.isBroken) {
        final def = Equipments.getById(instance.equipmentId);
        if (def != null) {
          result.add((i, instance, def));
        }
      }
    }

    return result;
  }

  /// 2경기 완료 보너스 적용 (모든 팀)
  void applyTwoMatchBonus() {
    if (state == null) return;

    final playerTeamId = state!.saveData.playerTeamId;
    var updatedPlayers = <Player>[];
    var updatedTeams = <Team>[];

    // 모든 팀에 보너스 적용
    for (final team in state!.saveData.allTeams) {
      // 행동력 +100
      updatedTeams.add(team.applyTwoMatchBonus());

      // 전체 선수 컨디션 +5
      final teamPlayers = state!.saveData.getTeamPlayers(team.id);
      for (final player in teamPlayers) {
        updatedPlayers.add(
          player.copyWith(condition: (player.condition + 5).clamp(0, 110)),
        );
      }
    }

    // 상태 업데이트
    var newSaveData = state!.saveData;
    for (final team in updatedTeams) {
      newSaveData = newSaveData.updateTeam(team);
    }
    newSaveData = newSaveData.updatePlayers(updatedPlayers);
    state = state!.copyWith(saveData: newSaveData);

    // AI 팀 행동 수행
    _performAITeamActions();
  }

  /// AI 팀 행동 수행 (2경기마다 호출)
  void _performAITeamActions() {
    if (state == null) return;

    final playerTeamId = state!.saveData.playerTeamId;
    final season = state!.saveData.currentSeason;
    final isSecondWeek = (season.currentMatchIndex ~/ 4) % 2 == 1; // 2주차 판별
    final random = DateTime.now().millisecondsSinceEpoch;

    var updatedPlayers = <Player>[];
    var updatedTeams = <Team>[];

    for (final team in state!.saveData.allTeams) {
      // 플레이어 팀은 직접 관리
      if (team.id == playerTeamId) continue;

      var currentTeam = team;
      final teamPlayers = state!.saveData.getTeamPlayers(team.id);
      final playerUpdates = <String, Player>{};

      // 1. 컨디션 80% 이하 선수 휴식 (행동력 50)
      for (final player in teamPlayers) {
        if (player.condition <= 80 && currentTeam.actionPoints >= 50) {
          final updatedPlayer = player.applyRest();
          playerUpdates[player.id] = updatedPlayer;
          currentTeam = currentTeam.spendActionPoints(50);
        }
      }

      // 2. 레벨 낮은 순 2명 특훈 (행동력 100)
      final sortedByLevel = teamPlayers.toList()
        ..sort((a, b) => a.levelValue.compareTo(b.levelValue));
      int trainingCount = 0;
      for (final player in sortedByLevel) {
        if (trainingCount >= 2) break;
        if (currentTeam.actionPoints < 100) break;
        // 이미 휴식한 선수는 제외
        if (playerUpdates.containsKey(player.id)) continue;

        final basePlayer = playerUpdates[player.id] ?? player;
        final updatedPlayer = basePlayer.applyTraining();
        playerUpdates[player.id] = updatedPlayer;
        currentTeam = currentTeam.spendActionPoints(100);
        trainingCount++;
      }

      // 3. 2주마다 등급 높은 순 2명 팬미팅 (행동력 200)
      if (isSecondWeek) {
        final sortedByGrade = teamPlayers.toList()
          ..sort((a, b) => b.grade.index.compareTo(a.grade.index));
        int fanMeetingCount = 0;
        for (final player in sortedByGrade) {
          if (fanMeetingCount >= 2) break;
          if (currentTeam.actionPoints < 200) break;
          // 이미 다른 행동한 선수는 제외
          if (playerUpdates.containsKey(player.id)) continue;

          final basePlayer = playerUpdates[player.id] ?? player;
          final updatedPlayer = basePlayer.applyFanMeeting();

          // 소지금 획득량 계산 (등급별)
          final grade = player.grade;
          int minMoney, maxMoney;
          if (grade.index >= Grade.sss.index) {
            minMoney = 100;
            maxMoney = 150;
          } else if (grade.index >= Grade.ssMinus.index) {
            minMoney = 50;
            maxMoney = 100;
          } else if (grade.index >= Grade.sMinus.index) {
            minMoney = 35;
            maxMoney = 50;
          } else if (grade.index >= Grade.bMinus.index) {
            minMoney = 20;
            maxMoney = 45;
          } else {
            minMoney = 10;
            maxMoney = 35;
          }
          final moneyEarned = minMoney + ((random + fanMeetingCount) % (maxMoney - minMoney + 1));

          playerUpdates[player.id] = updatedPlayer;
          currentTeam = currentTeam.spendActionPoints(200).addMoney(moneyEarned);
          fanMeetingCount++;
        }
      }

      // 4. 돈이 충분하면 주 1회 2명에게 비타비타 구매 (5만원, 컨디션 +3)
      if (currentTeam.money >= 10) {
        // 컨디션 낮은 순 2명에게 비타비타
        final sortedByCondition = teamPlayers.toList()
          ..sort((a, b) => a.condition.compareTo(b.condition));
        int vitaCount = 0;
        for (final player in sortedByCondition) {
          if (vitaCount >= 2) break;
          if (currentTeam.money < 5) break;
          // 이미 컨디션 높은 선수는 제외
          if (player.condition >= 95) continue;

          final basePlayer = playerUpdates[player.id] ?? player;
          final updatedPlayer = basePlayer.copyWith(
            condition: (basePlayer.condition + 3).clamp(0, 110),
          );
          playerUpdates[player.id] = updatedPlayer;
          currentTeam = currentTeam.spendMoney(5);
          vitaCount++;
        }
      }

      // 업데이트된 선수/팀 수집
      updatedPlayers.addAll(playerUpdates.values);
      updatedTeams.add(currentTeam);
    }

    // 상태 업데이트
    if (updatedPlayers.isNotEmpty || updatedTeams.isNotEmpty) {
      var newSaveData = state!.saveData;
      for (final team in updatedTeams) {
        newSaveData = newSaveData.updateTeam(team);
      }
      if (updatedPlayers.isNotEmpty) {
        newSaveData = newSaveData.updatePlayers(updatedPlayers);
      }
      state = state!.copyWith(saveData: newSaveData);
    }
  }

  /// 개인리그 대진표 업데이트
  void updateIndividualLeague(IndividualLeagueBracket bracket) {
    if (state == null) return;

    final updatedSeason = state!.saveData.currentSeason.updateIndividualLeague(bracket);
    var newSaveData = state!.saveData.updateSeason(updatedSeason);

    // 개인리그 결승 완료 시 상금 지급
    final playerTeamId = state!.saveData.playerTeamId;
    final previousBracket = state!.saveData.currentSeason.individualLeague;
    final wasChampionNull = previousBracket?.championId == null;
    final isChampionNow = bracket.championId != null;

    // 이번 업데이트로 우승자가 결정된 경우에만 상금 지급
    if (wasChampionNull && isChampionNow) {
      final champion = newSaveData.getPlayerById(bracket.championId!);
      final runnerUp = newSaveData.getPlayerById(bracket.runnerUpId!);

      // 우승자가 플레이어 팀 소속이면 80만원
      if (champion?.teamId == playerTeamId) {
        final team = newSaveData.getTeamById(playerTeamId);
        if (team != null) {
          newSaveData = newSaveData.updateTeam(team.addMoney(80));
        }
      }

      // 준우승자가 플레이어 팀 소속이면 40만원
      if (runnerUp?.teamId == playerTeamId) {
        final team = newSaveData.getTeamById(playerTeamId);
        if (team != null) {
          newSaveData = newSaveData.updateTeam(team.addMoney(40));
        }
      }
    }

    state = state!.copyWith(saveData: newSaveData);
  }

  /// 시즌 단계 업데이트
  void updateSeasonPhase(SeasonPhase phase) {
    if (state == null) return;

    final updatedSeason = state!.saveData.currentSeason.updatePhase(phase);
    final newSaveData = state!.saveData.updateSeason(updatedSeason);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 플레이오프 시작
  void startPlayoff() {
    if (state == null) return;

    // 순위 계산
    final standings = calculateStandings();
    if (standings.length < 4) return;

    // 플레이오프 대진표 생성
    final playoff = PlayoffBracket(
      firstPlaceTeamId: standings[0].teamId,
      secondPlaceTeamId: standings[1].teamId,
      thirdPlaceTeamId: standings[2].teamId,
      fourthPlaceTeamId: standings[3].teamId,
    );

    var updatedSeason = state!.saveData.currentSeason
        .updatePlayoff(playoff)
        .updatePhase(SeasonPhase.playoff34);

    final newSaveData = state!.saveData.updateSeason(updatedSeason);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 순위 계산 (public - 결과 화면에서도 사용)
  List<TeamStanding> calculateStandings() {
    if (state == null) return [];

    final standings = <String, TeamStanding>{};

    // 초기화
    for (final team in state!.saveData.allTeams) {
      standings[team.id] = TeamStanding(teamId: team.id);
    }

    // 경기 결과 반영
    for (final item in state!.saveData.currentSeason.proleagueSchedule) {
      if (!item.isCompleted || item.result == null) continue;

      final result = item.result!;
      standings[result.homeTeamId] = standings[result.homeTeamId]!.addResult(
        isWin: result.isHomeWin,
        ourSets: result.homeScore,
        opponentSets: result.awayScore,
      );
      standings[result.awayTeamId] = standings[result.awayTeamId]!.addResult(
        isWin: result.isAwayWin,
        ourSets: result.awayScore,
        opponentSets: result.homeScore,
      );
    }

    // 상대 전적 맵 생성
    final headToHead = _buildHeadToHeadRecord(
      state!.saveData.currentSeason.proleagueSchedule,
    );

    final sortedStandings = standings.values.toList()
      ..sort((a, b) => _compareStandings(a, b, headToHead));

    return sortedStandings;
  }

  /// 상대 전적 맵 생성
  Map<String, Map<String, (int, int)>> _buildHeadToHeadRecord(
    List<ScheduleItem> schedule,
  ) {
    final record = <String, Map<String, (int, int)>>{};

    for (final item in schedule) {
      if (!item.isCompleted || item.result == null) continue;

      final result = item.result!;
      final home = result.homeTeamId;
      final away = result.awayTeamId;
      final homeWin = result.isHomeWin;

      // 홈팀 기록
      record.putIfAbsent(home, () => {});
      final (homeWins, homeLosses) = record[home]![away] ?? (0, 0);
      record[home]![away] = homeWin ? (homeWins + 1, homeLosses) : (homeWins, homeLosses + 1);

      // 어웨이팀 기록
      record.putIfAbsent(away, () => {});
      final (awayWins, awayLosses) = record[away]![home] ?? (0, 0);
      record[away]![home] = homeWin ? (awayWins, awayLosses + 1) : (awayWins + 1, awayLosses);
    }

    return record;
  }

  /// 순위 비교 (승점 → 세트 득실 → 상대 전적)
  int _compareStandings(
    TeamStanding a,
    TeamStanding b,
    Map<String, Map<String, (int, int)>> headToHead,
  ) {
    // 1. 승점 비교
    if (a.points != b.points) return b.points - a.points;

    // 2. 세트 득실 비교
    if (a.setDiff != b.setDiff) return b.setDiff - a.setDiff;

    // 3. 상대 전적 비교
    final aVsB = headToHead[a.teamId]?[b.teamId];
    if (aVsB != null) {
      final (aWins, aLosses) = aVsB;
      if (aWins != aLosses) {
        return aWins > aLosses ? -1 : 1; // A가 이기면 A가 상위
      }
    }

    // 4. 동률이면 그대로
    return 0;
  }

  /// 플레이오프 매치 결과 기록
  void recordPlayoffMatchResult({
    required PlayoffMatchType matchType,
    required MatchResult result,
  }) {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    final playoff = season.playoff;
    if (playoff == null) return;

    PlayoffBracket updatedPlayoff;
    SeasonPhase nextPhase;

    switch (matchType) {
      case PlayoffMatchType.thirdFourth:
        updatedPlayoff = playoff.copyWith(match34: result);
        nextPhase = SeasonPhase.individualSemiFinal;
        break;
      case PlayoffMatchType.secondThird:
        updatedPlayoff = playoff.copyWith(match23: result);
        nextPhase = SeasonPhase.individualFinal;
        break;
      case PlayoffMatchType.final_:
        updatedPlayoff = playoff.copyWith(matchFinal: result);
        nextPhase = SeasonPhase.seasonEnd;
        break;
    }

    var updatedSeason = season
        .updatePlayoff(updatedPlayoff)
        .updatePhase(nextPhase);

    // 결승전 완료 시 우승/준우승 기록 및 상금 지급
    if (matchType == PlayoffMatchType.final_) {
      updatedSeason = updatedSeason.complete(
        championId: updatedPlayoff.champion,
        runnerUpId: updatedPlayoff.runnerUp,
      );
    }

    var newSaveData = state!.saveData.updateSeason(updatedSeason);

    // 플레이어 팀 승리 보상 (+5만원)
    final playerTeamId = state!.saveData.playerTeamId;
    final winnerTeamId = result.isHomeWin ? result.homeTeamId : result.awayTeamId;
    if (winnerTeamId == playerTeamId) {
      final playerTeam = newSaveData.getTeamById(playerTeamId);
      if (playerTeam != null) {
        newSaveData = newSaveData.updateTeam(playerTeam.addMoney(5));
      }
    }

    // 프로리그 결승전 상금 지급
    if (matchType == PlayoffMatchType.final_) {
      final loserTeamId = result.isHomeWin ? result.awayTeamId : result.homeTeamId;
      // 우승 상금: 150만원
      if (winnerTeamId == playerTeamId) {
        final team = newSaveData.getTeamById(playerTeamId);
        if (team != null) {
          newSaveData = newSaveData.updateTeam(team.addMoney(150));
        }
      }
      // 준우승 상금: 70만원
      if (loserTeamId == playerTeamId) {
        final team = newSaveData.getTeamById(playerTeamId);
        if (team != null) {
          newSaveData = newSaveData.updateTeam(team.addMoney(70));
        }
      }
    }

    state = state!.copyWith(saveData: newSaveData);
  }

  /// 전체 팀 컨디션 회복 (플레이오프 사이)
  void recoverAllTeamsCondition() {
    if (state == null) return;

    // 모든 선수 컨디션 100으로 회복
    final updatedPlayers = state!.saveData.allPlayers.map((p) {
      return p.copyWith(condition: 100);
    }).toList();

    final newSaveData = state!.saveData.updatePlayers(updatedPlayers);
    state = state!.copyWith(saveData: newSaveData);
  }

  /// 정규 시즌 완료 체크 및 플레이오프 전환
  void checkAndTransitionToPlayoff() {
    if (state == null) return;

    final season = state!.saveData.currentSeason;

    // 정규 시즌 완료 + 개인리그 8강 완료 확인
    if (!season.hasNextMatch && season.phase == SeasonPhase.regularSeason) {
      // 개인리그 8강 완료 확인
      final individualLeague = season.individualLeague;
      final quarterFinalCount = individualLeague?.mainTournamentResults
          .where((r) => r.stage == IndividualLeagueStage.quarterFinal)
          .length ?? 0;

      if (quarterFinalCount >= 4) {
        // 플레이오프 준비 단계로 전환
        updateSeasonPhase(SeasonPhase.playoffReady);
      }
    }
  }

  /// 프로리그 매치 결과 기록
  void recordMatchResult({
    required String homeTeamId,
    required String awayTeamId,
    required int homeScore,
    required int awayScore,
  }) {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    final schedule = season.proleagueSchedule;

    // 해당 매치 찾기 (완료되지 않은 첫 번째 매치)
    final matchIndex = schedule.indexWhere((m) =>
        !m.isCompleted &&
        ((m.homeTeamId == homeTeamId && m.awayTeamId == awayTeamId) ||
         (m.homeTeamId == awayTeamId && m.awayTeamId == homeTeamId)));

    if (matchIndex == -1) return;

    final match = schedule[matchIndex];
    final isHomeMatch = match.homeTeamId == homeTeamId;

    // 실제 스코어 계산 (홈/어웨이 기준으로 변환)
    final actualHomeScore = isHomeMatch ? homeScore : awayScore;
    final actualAwayScore = isHomeMatch ? awayScore : homeScore;

    // SetResult 생성 (점수에 맞게)
    final List<SetResult> sets = [];
    for (int i = 0; i < actualHomeScore; i++) {
      sets.add(SetResult(
        mapId: 'map_$i',
        homePlayerId: 'home_player_$i',
        awayPlayerId: 'away_player_$i',
        homeWin: true,
      ));
    }
    for (int i = 0; i < actualAwayScore; i++) {
      sets.add(SetResult(
        mapId: 'map_${actualHomeScore + i}',
        homePlayerId: 'home_player_${actualHomeScore + i}',
        awayPlayerId: 'away_player_${actualHomeScore + i}',
        homeWin: false,
      ));
    }

    // 매치 결과 생성
    final matchResult = MatchResult(
      id: match.matchId,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      sets: sets,
      isCompleted: true,
      seasonNumber: season.number,
      roundNumber: match.roundNumber,
    );

    // Season.updateMatchResult 메서드 사용
    var updatedSeason = season.updateMatchResult(matchIndex, matchResult);

    // 팀 전적 업데이트
    final actualHomeTeam = state!.saveData.getTeamById(match.homeTeamId);
    final actualAwayTeam = state!.saveData.getTeamById(match.awayTeamId);

    if (actualHomeTeam != null && actualAwayTeam != null) {
      final homeWin = actualHomeScore > actualAwayScore;
      final playerTeamId = state!.saveData.playerTeamId;

      var updatedHomeTeam = actualHomeTeam.applyMatchResult(
        isWin: homeWin,
        ourSets: actualHomeScore,
        opponentSets: actualAwayScore,
      );

      var updatedAwayTeam = actualAwayTeam.applyMatchResult(
        isWin: !homeWin,
        ourSets: actualAwayScore,
        opponentSets: actualHomeScore,
      );

      // 플레이어 팀 승리 보상 (+5만원)
      if (match.homeTeamId == playerTeamId && homeWin) {
        updatedHomeTeam = updatedHomeTeam.addMoney(5);
      } else if (match.awayTeamId == playerTeamId && !homeWin) {
        updatedAwayTeam = updatedAwayTeam.addMoney(5);
      }

      var newSaveData = state!.saveData
          .updateSeason(updatedSeason)
          .updateTeam(updatedHomeTeam)
          .updateTeam(updatedAwayTeam);

      state = state!.copyWith(saveData: newSaveData);
    } else {
      final newSaveData = state!.saveData.updateSeason(updatedSeason);
      state = state!.copyWith(saveData: newSaveData);
    }

    // 같은 라운드의 다른 팀 경기 시뮬레이션
    _simulateOtherMatchesInRound(match.roundNumber);
  }

  /// 같은 라운드의 다른 팀 경기 시뮬레이션
  void _simulateOtherMatchesInRound(int roundNumber) {
    if (state == null) return;

    final schedule = state!.saveData.currentSeason.proleagueSchedule;
    final playerTeamId = state!.saveData.playerTeamId;
    final rand = Random();

    // 같은 라운드의 미완료 경기 찾기 (플레이어 팀 제외)
    for (int i = 0; i < schedule.length; i++) {
      final match = schedule[i];
      if (match.roundNumber != roundNumber) continue;
      if (match.isCompleted) continue;
      if (match.homeTeamId == playerTeamId || match.awayTeamId == playerTeamId) continue;

      // AI 경기 시뮬레이션
      final homeTeam = state!.saveData.getTeamById(match.homeTeamId);
      final awayTeam = state!.saveData.getTeamById(match.awayTeamId);

      if (homeTeam == null || awayTeam == null) continue;

      // 팀 선수 목록 (능력치 높은 순 정렬)
      final homePlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.homeTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      final awayPlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.awayTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      if (homePlayers.isEmpty || awayPlayers.isEmpty) continue;

      // 세트별 선수 배정 및 시뮬레이션 (7전 4선승)
      final List<SetResult> sets = [];
      final List<Player> updatedPlayersList = [];
      int homeScore = 0;
      int awayScore = 0;
      int setIndex = 0;

      while (homeScore < 4 && awayScore < 4) {
        // 선수 배정 (순환, 최대 7세트이므로 상위 7명 사용)
        final homePlayer = homePlayers[setIndex % homePlayers.length];
        final awayPlayer = awayPlayers[setIndex % awayPlayers.length];

        // 개별 선수 능력치 기반 승패 확률 계산
        final homeStrength = homePlayer.stats.applyCondition(homePlayer.displayCondition).total.toDouble();
        final awayStrength = awayPlayer.stats.applyCondition(awayPlayer.displayCondition).total.toDouble();
        final totalStrength = homeStrength + awayStrength;
        final homeWinProb = totalStrength > 0 ? homeStrength / totalStrength : 0.5;

        final homeWin = rand.nextDouble() < homeWinProb;

        if (homeWin) {
          homeScore++;
        } else {
          awayScore++;
        }

        sets.add(SetResult(
          mapId: 'map_$setIndex',
          homePlayerId: homePlayer.id,
          awayPlayerId: awayPlayer.id,
          homeWin: homeWin,
        ));

        // 개별 선수 전적 업데이트
        final updatedHome = homePlayer.applyMatchResult(
          isWin: homeWin,
          opponentGrade: awayPlayer.grade,
          opponentRace: awayPlayer.race,
          opponentId: awayPlayer.id,
        );
        final updatedAway = awayPlayer.applyMatchResult(
          isWin: !homeWin,
          opponentGrade: homePlayer.grade,
          opponentRace: homePlayer.race,
          opponentId: homePlayer.id,
        );

        updatedPlayersList.add(updatedHome);
        updatedPlayersList.add(updatedAway);

        // 다음 세트에서 업데이트된 선수 반영
        final homeIdx = homePlayers.indexWhere((p) => p.id == homePlayer.id);
        if (homeIdx >= 0) homePlayers[homeIdx] = updatedHome;
        final awayIdx = awayPlayers.indexWhere((p) => p.id == awayPlayer.id);
        if (awayIdx >= 0) awayPlayers[awayIdx] = updatedAway;

        setIndex++;
      }

      // 결과 기록 (팀 전적 + 시즌 업데이트)
      _recordOtherMatchResult(i, match, homeScore, awayScore, sets, updatedPlayersList);
    }
  }

  /// 다른 팀 경기 결과 기록
  void _recordOtherMatchResult(
    int matchIndex,
    ScheduleItem match,
    int homeScore,
    int awayScore,
    List<SetResult> sets,
    List<Player> updatedPlayers,
  ) {
    if (state == null) return;

    final season = state!.saveData.currentSeason;

    // 매치 결과 생성
    final matchResult = MatchResult(
      id: match.matchId,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      sets: sets,
      isCompleted: true,
      seasonNumber: season.number,
      roundNumber: match.roundNumber,
    );

    // 시즌 업데이트
    var updatedSeason = season.updateMatchResult(matchIndex, matchResult);

    // 팀 전적 업데이트
    final homeTeam = state!.saveData.getTeamById(match.homeTeamId);
    final awayTeam = state!.saveData.getTeamById(match.awayTeamId);

    if (homeTeam != null && awayTeam != null) {
      final homeWin = homeScore > awayScore;

      final updatedHomeTeam = homeTeam.applyMatchResult(
        isWin: homeWin,
        ourSets: homeScore,
        opponentSets: awayScore,
      );

      final updatedAwayTeam = awayTeam.applyMatchResult(
        isWin: !homeWin,
        ourSets: awayScore,
        opponentSets: homeScore,
      );

      // 선수 전적 중복 제거 (같은 선수가 여러 세트 출전 시 마지막 상태 사용)
      final playerMap = <String, Player>{};
      for (final p in updatedPlayers) {
        playerMap[p.id] = p;
      }

      var newSaveData = state!.saveData
          .updateSeason(updatedSeason)
          .updateTeam(updatedHomeTeam)
          .updateTeam(updatedAwayTeam)
          .updatePlayers(playerMap.values.toList());

      state = state!.copyWith(saveData: newSaveData);
    } else {
      final newSaveData = state!.saveData.updateSeason(updatedSeason);
      state = state!.copyWith(saveData: newSaveData);
    }
  }

  /// 시즌 완료 처리
  /// 반환값: (은퇴 선수 목록, 신인 선수 목록, 무소속 선수 수)
  (List<Player> retired, List<Player> rookies, int freeAgentCount) completeSeasonAndPrepareNext() {
    if (state == null) return ([], [], 0);

    final random = DateTime.now().millisecondsSinceEpoch;
    final currentSeasonNumber = state!.saveData.currentSeason.number;

    var updatedPlayers = <Player>[];
    var retiredPlayers = <Player>[];
    var newRookies = <Player>[];

    // 1. 모든 선수 커리어 진행 + 은퇴 체크 + 컨디션 리셋
    for (final player in state!.saveData.allPlayers) {
      var updatedPlayer = player;

      // 커리어 진행 (시즌당 +1)
      updatedPlayer = updatedPlayer.advanceCareer();

      // 컨디션 100% 리셋
      updatedPlayer = updatedPlayer.copyWith(condition: 100);

      // 노장(twilight) 선수 은퇴 체크 (커리어 기반)
      if (updatedPlayer.career == Career.twilight) {
        // 노장 선수는 커리어의 declineChance 확률로 은퇴 (30%)
        final retireRoll = ((random + updatedPlayer.id.hashCode) % 100) / 100.0;
        if (retireRoll < updatedPlayer.career.declineChance && updatedPlayer.teamId != null) {
          retiredPlayers.add(updatedPlayer);
          continue; // 은퇴 선수는 업데이트 목록에서 제외
        }
      }

      updatedPlayers.add(updatedPlayer);
    }

    // 2. 은퇴 선수를 팀에서 제거
    var updatedTeams = state!.saveData.allTeams.toList();
    for (final retired in retiredPlayers) {
      if (retired.teamId != null) {
        final teamIndex = updatedTeams.indexWhere((t) => t.id == retired.teamId);
        if (teamIndex != -1) {
          updatedTeams[teamIndex] = updatedTeams[teamIndex].removePlayer(retired.id);
        }
      }
    }

    // 3. 신인 선수 3~5명 생성 (각 팀에 부족한 만큼 배분)
    final rookieCount = 3 + (random % 3); // 3~5명
    final rookieNames = ['김신인', '이루키', '박신성', '최유망', '정재능', '한미래', '윤희망'];
    final races = [Race.terran, Race.zerg, Race.protoss];

    for (int i = 0; i < rookieCount; i++) {
      // 선수 부족한 팀 찾기
      String? targetTeamId;
      int minPlayers = 999;
      for (final team in updatedTeams) {
        final playerCount = team.playerIds.length;
        if (playerCount < minPlayers && playerCount < 10) {
          minPlayers = playerCount;
          targetTeamId = team.id;
        }
      }

      // 모든 팀이 10명 이상이면 랜덤 팀에 배정
      targetTeamId ??= updatedTeams[(random + i) % updatedTeams.length].id;

      final rookieId = 'rookie_${currentSeasonNumber}_$i';
      final rookie = Player(
        id: rookieId,
        name: '${rookieNames[i % rookieNames.length]}${currentSeasonNumber}',
        raceIndex: races[(random + i) % 3].index,
        stats: PlayerStats(
          sense: 300 + (random + i * 10) % 200,
          control: 320 + (random + i * 20) % 200,
          attack: 310 + (random + i * 30) % 200,
          harass: 290 + (random + i * 40) % 200,
          strategy: 300 + (random + i * 50) % 200,
          macro: 310 + (random + i * 60) % 200,
          defense: 280 + (random + i * 70) % 200,
          scout: 290 + (random + i * 80) % 200,
        ),
        levelValue: 1,
        condition: 100,
        teamId: targetTeamId,
      );

      newRookies.add(rookie);
      updatedPlayers.add(rookie);

      // 팀에 신인 추가
      final teamIndex = updatedTeams.indexWhere((t) => t.id == targetTeamId);
      if (teamIndex != -1) {
        updatedTeams[teamIndex] = updatedTeams[teamIndex].addPlayer(rookieId);
      }
    }

    // 4. 무소속 선수 풀 갱신 (11~12명)
    final freeAgentCount = 11 + (random % 2); // 11~12명
    final freeAgentNames = ['무명선수', '신예', '유망주', '아마추어', '도전자', '루키', '신인왕'];
    var newFreeAgents = <Player>[];

    for (int i = 0; i < freeAgentCount; i++) {
      final freeAgentId = 'freeagent_${currentSeasonNumber}_$i';
      final freeAgent = Player(
        id: freeAgentId,
        name: '${freeAgentNames[i % freeAgentNames.length]}${currentSeasonNumber}_${i + 1}',
        raceIndex: races[(random + i * 7) % 3].index,
        stats: PlayerStats(
          sense: 250 + (random + i * 11) % 350,
          control: 270 + (random + i * 22) % 350,
          attack: 260 + (random + i * 33) % 350,
          harass: 240 + (random + i * 44) % 350,
          strategy: 250 + (random + i * 55) % 350,
          macro: 260 + (random + i * 66) % 350,
          defense: 230 + (random + i * 77) % 350,
          scout: 240 + (random + i * 88) % 350,
        ),
        levelValue: 1 + (random + i) % 3, // 1~3레벨
        condition: 100,
        teamId: null, // 무소속
      );
      newFreeAgents.add(freeAgent);
    }

    // 5. 새 시즌 생성
    final newSeason = _createNewSeason(currentSeasonNumber + 1);

    // 6. 상태 업데이트
    var newSaveData = state!.saveData
        .startNewSeason(newSeason)
        .copyWith(
          allPlayers: updatedPlayers,
          allTeams: updatedTeams,
          freeAgentPool: newFreeAgents,
        );

    state = state!.copyWith(saveData: newSaveData);

    return (retiredPlayers, newRookies, freeAgentCount);
  }

  /// 새 시즌 생성
  Season _createNewSeason(int seasonNumber) {
    final random = DateTime.now().millisecondsSinceEpoch;
    final rng = Random(random);

    // 시즌맵 랜덤 선정 (7개) - allMaps에서 동적 생성
    final allMapIds = GameMaps.all.map((m) => m.id).toList();
    final shuffledMaps = List<String>.from(allMapIds)..shuffle(rng);
    final seasonMaps = shuffledMaps.take(7).toList();

    // 프로리그 일정 생성 (각 팀당 14경기 = 풀 라운드 로빈 × 2)
    // 11행 × 2경기 = 22칸, 14경기 + 8개 NO match
    // 데칼코마니: 1~11칸 → 12~22칸 역순
    final teams = state!.saveData.allTeams;
    final schedule = <ScheduleItem>[];
    int matchId = 0;

    // 1차 리그: 풀 라운드 로빈 (7라운드, 각 라운드 4경기)
    // 서클 메서드로 공정한 대진 생성
    final firstHalfMatchups = _generateRoundRobinMatchups(teams, rng);

    // 1~11칸 중 7경기 배치할 위치 랜덤 선택 (4개는 NO match)
    final slots = List.generate(11, (i) => i + 1);
    slots.shuffle(rng);
    final matchSlots = slots.take(7).toList()..sort();

    // 1차 리그 경기 배치 (슬롯 1~11 중 7개)
    // 라운드별로 4경기씩 같은 슬롯에 배치
    for (int i = 0; i < firstHalfMatchups.length; i++) {
      final matchup = firstHalfMatchups[i];
      final round = i ~/ 4; // 라운드 번호 (0~6)
      final slot = matchSlots[round]; // 같은 라운드는 같은 슬롯

      schedule.add(ScheduleItem(
        matchId: 'match_${seasonNumber}_${matchId++}',
        roundNumber: slot,
        homeTeamId: matchup[0],
        awayTeamId: matchup[1],
      ));
    }

    // 2차 리그: 1차 리그의 역순 (데칼코마니)
    // 슬롯 12~22 = 23 - 슬롯(1~11)
    for (int i = 0; i < firstHalfMatchups.length; i++) {
      final matchup = firstHalfMatchups[i];
      final round = i ~/ 4; // 라운드 번호 (0~6)
      final firstSlot = matchSlots[round];
      final secondSlot = 23 - firstSlot; // 데칼코마니 위치

      // 홈/어웨이 반전
      schedule.add(ScheduleItem(
        matchId: 'match_${seasonNumber}_${matchId++}',
        roundNumber: secondSlot,
        homeTeamId: matchup[1],
        awayTeamId: matchup[0],
      ));
    }

    return Season(
      number: seasonNumber,
      seasonMapIds: seasonMaps,
      proleagueSchedule: schedule,
      currentMatchIndex: 0,
      matchesSinceLastBonus: 0,
      phaseIndex: SeasonPhase.regularSeason.index,
    );
  }

  /// 풀 라운드 로빈 대진 생성 (서클 메서드)
  /// 8팀 → 7라운드 × 4경기 = 28경기
  List<List<String>> _generateRoundRobinMatchups(List<Team> teams, Random rng) {
    final matchups = <List<String>>[];
    final teamIds = teams.map((t) => t.id).toList()..shuffle(rng);
    final n = teamIds.length;

    // 서클 메서드: 첫 번째 팀 고정, 나머지 회전
    for (int round = 0; round < n - 1; round++) {
      for (int i = 0; i < n ~/ 2; i++) {
        final home = i == 0 ? teamIds[0] : teamIds[(round + i) % (n - 1) + 1];
        final away = teamIds[(round + n - 1 - i) % (n - 1) + 1];
        if (i == 0) {
          matchups.add([teamIds[0], away]);
        } else {
          matchups.add([home, away]);
        }
      }
    }

    return matchups;
  }
}

/// 현재 플레이어 팀 선수 목록 Provider
final playerTeamPlayersProvider = Provider<List<Player>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  if (gameState == null) return [];
  return gameState.playerTeamPlayers;
});

/// 특정 팀 선수 목록 Provider
final teamPlayersProvider = Provider.family<List<Player>, String>((ref, teamId) {
  final gameState = ref.watch(gameStateProvider);
  if (gameState == null) return [];
  return gameState.saveData.getTeamPlayers(teamId);
});

/// 모든 팀 목록 Provider
final allTeamsProvider = Provider<List<Team>>((ref) {
  final gameState = ref.watch(gameStateProvider);
  if (gameState == null) return [];
  return gameState.saveData.allTeams;
});

/// 현재 시즌 Provider
final currentSeasonProvider = Provider<Season?>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.currentSeason;
});

/// 인벤토리 Provider
final inventoryProvider = Provider<Inventory>((ref) {
  final gameState = ref.watch(gameStateProvider);
  return gameState?.inventory ?? const Inventory();
});
