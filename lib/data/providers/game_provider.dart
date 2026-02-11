import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import '../../domain/services/individual_league_service.dart';
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

  /// 최상/최악 이벤트 전 원래 컨디션 백업 (playerId → originalCondition)
  final Map<String, int> _conditionBackup = {};

  GameStateNotifier(this._repository) : super(null);

  /// 컨디션 백업 등록 (최상/최악 적용 전 호출)
  void backupCondition(String playerId, int originalCondition) {
    _conditionBackup[playerId] = originalCondition;
  }

  /// 미출전 선수 컨디션 복구 (매치 종료 시 호출)
  void revertUnplayedConditions(Set<String> playedPlayerIds) {
    if (_conditionBackup.isEmpty) return;

    for (final entry in _conditionBackup.entries) {
      if (!playedPlayerIds.contains(entry.key)) {
        // 미출전 → 원래 컨디션으로 복구
        final player = state?.saveData.getPlayerById(entry.key);
        if (player != null) {
          updatePlayer(player.copyWith(condition: entry.value));
        }
      }
    }
    _conditionBackup.clear();
  }

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

    // 기존 세이브 호환: weekProgress 마이그레이션
    migrateWeekProgress();

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

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return;
    if (player.actionPoints < 50) return; // 행동력 부족

    final updatedPlayer = player.applyRest().spendActionPoints(50);
    updatePlayer(updatedPlayer);
  }

  /// 행동: 특훈
  void playerTraining(String playerId) {
    if (state == null) return;

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return;
    if (player.actionPoints < 100) return; // 행동력 부족

    final updatedPlayer = player.applyTraining().spendActionPoints(100);
    updatePlayer(updatedPlayer);
  }

  /// 행동: 팬미팅
  (bool gotCheerful, int moneyEarned) playerFanMeeting(String playerId) {
    if (state == null) return (false, 0);

    final team = state!.playerTeam;

    final player = state!.saveData.getPlayerById(playerId);
    if (player == null) return (false, 0);
    if (player.actionPoints < 200) return (false, 0); // 행동력 부족

    final updatedPlayer = player.applyFanMeeting().spendActionPoints(200);

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

    var updatedTeam = team.addMoney(moneyEarned);
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
  bool buyItem(String itemId, int price, {int quantity = 1}) {
    if (state == null) return false;

    final team = state!.playerTeam;
    if (team.money < price) return false;

    final updatedTeam = team.spendMoney(price);
    final updatedInventory = state!.inventory.addConsumable(itemId, quantity);

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

    var updatedPlayers = <Player>[];

    // 모든 팀의 선수에게 보너스 적용
    for (final team in state!.saveData.allTeams) {
      final teamPlayers = state!.saveData.getTeamPlayers(team.id);
      for (final player in teamPlayers) {
        // 행동력 +100, 컨디션 +5 (최상 상태 보호: 100 초과 시 유지)
        updatedPlayers.add(
          player.addActionPoints(100).copyWith(
            condition: player.condition > 100
                ? player.condition
                : (player.condition + 5).clamp(0, 100),
          ),
        );
      }
    }

    // 상태 업데이트
    var newSaveData = state!.saveData.updatePlayers(updatedPlayers);
    state = state!.copyWith(saveData: newSaveData);

    // AI 팀 행동 수행
    _performAITeamActions();
  }

  /// 해당 라운드를 건너뛰기 (플레이어 경기 없을 때)
  /// 다른 팀 경기를 시뮬레이션한 후 주간 진행도를 올림
  void skipRound(int roundNumber) {
    _simulateOtherMatchesInRound(roundNumber);
    advanceWeekProgress();
  }

  /// 주간 진행도 증가 (step 0→1→2→다음주 0)
  /// step1→2 전환 시 applyTwoMatchBonus() 자동 호출
  void advanceWeekProgress() {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    final newProgress = season.weekProgress + 1;

    // step1→2 전환 (경기2 완료 → 개인리그 진입) 시 주간 보너스 적용
    if (season.currentStep == 1) {
      // 먼저 weekProgress 업데이트
      final updatedSeason = season.copyWith(weekProgress: newProgress);
      final newSaveData = state!.saveData.updateSeason(updatedSeason);
      state = state!.copyWith(saveData: newSaveData);
      // 보너스 적용
      applyTwoMatchBonus();
    } else {
      final updatedSeason = season.copyWith(weekProgress: newProgress);
      final newSaveData = state!.saveData.updateSeason(updatedSeason);
      state = state!.copyWith(saveData: newSaveData);
    }
  }

  /// 기존 세이브 호환: 완료된 매치 기반으로 weekProgress 자동 계산
  void migrateWeekProgress() {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    // 이미 weekProgress가 설정되어 있으면 스킵
    if (season.weekProgress > 0) return;

    final schedule = season.proleagueSchedule;
    final playerTeamId = state!.saveData.playerTeamId;

    // 플레이어 팀 경기를 슬롯별로 맵핑
    final matchBySlot = <int, ScheduleItem>{};
    for (final match in schedule) {
      if (match.homeTeamId == playerTeamId || match.awayTeamId == playerTeamId) {
        matchBySlot[match.roundNumber] = match;
      }
    }

    // 각 주차의 완료 상태를 순서대로 확인하여 weekProgress 계산
    int progress = 0;
    for (int week = 0; week < 11; week++) {
      final slot1 = week * 2 + 1;
      final slot2 = week * 2 + 2;
      final match1 = matchBySlot[slot1];
      final match2 = matchBySlot[slot2];

      // step 0 (경기1): 매치가 없거나 완료되었으면 진행
      final step0Done = match1 == null || match1.isCompleted;
      if (!step0Done) break;
      progress++;

      // step 1 (경기2): 매치가 없거나 완료되었으면 진행
      final step1Done = match2 == null || match2.isCompleted;
      if (!step1Done) break;
      progress++;

      // step 2 (개인리그): 경기1,2가 모두 완료되었으면 개인리그도 완료로 간주
      progress++;
    }

    if (progress > 0) {
      final updatedSeason = season.copyWith(weekProgress: progress);
      final newSaveData = state!.saveData.updateSeason(updatedSeason);
      state = state!.copyWith(saveData: newSaveData);
    }
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

      Player _getLatest(Player player) => playerUpdates[player.id] ?? player;

      // 1. 컨디션 80% 이하 선수 휴식 (행동력 50)
      for (final player in teamPlayers) {
        final p = _getLatest(player);
        if (p.condition <= 80 && p.actionPoints >= 50) {
          playerUpdates[player.id] = p.applyRest().spendActionPoints(50);
        }
      }

      // 2. 레벨 낮은 순 2명 특훈 (행동력 100)
      final sortedByLevel = teamPlayers.toList()
        ..sort((a, b) => a.levelValue.compareTo(b.levelValue));
      int trainingCount = 0;
      for (final player in sortedByLevel) {
        if (trainingCount >= 2) break;
        // 이미 휴식한 선수는 제외
        if (playerUpdates.containsKey(player.id)) continue;

        final p = _getLatest(player);
        if (p.actionPoints < 100) continue;

        playerUpdates[player.id] = p.applyTraining().spendActionPoints(100);
        trainingCount++;
      }

      // 3. 2주마다 등급 높은 순 2명 팬미팅 (행동력 200)
      if (isSecondWeek) {
        final sortedByGrade = teamPlayers.toList()
          ..sort((a, b) => b.grade.index.compareTo(a.grade.index));
        int fanMeetingCount = 0;
        for (final player in sortedByGrade) {
          if (fanMeetingCount >= 2) break;
          // 이미 다른 행동한 선수는 제외
          if (playerUpdates.containsKey(player.id)) continue;

          final p = _getLatest(player);
          if (p.actionPoints < 200) continue;

          final updatedPlayer = p.applyFanMeeting().spendActionPoints(200);

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
          currentTeam = currentTeam.addMoney(moneyEarned);
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

          final p = _getLatest(player);
          final updatedPlayer = p.copyWith(
            condition: (p.condition + 3).clamp(0, 100),
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

  /// 디버그: 듀얼토너먼트까지 빠르게 진행
  void debugSkipToDualTournament() {
    if (state == null) return;

    final leagueService = IndividualLeagueService();

    // 1. 프로리그 경기 스킵 (week 0 match1, match2)
    for (var wp = state!.saveData.currentSeason.weekProgress; wp < 2; wp++) {
      final season = state!.saveData.currentSeason;
      if (season.currentStep < 2) {
        final roundNumber = season.currentWeek * 2 + season.currentStep + 1;
        skipRound(roundNumber);
      }
    }

    // 2. PC방 예선 대진표 생성 & 시뮬레이션
    final playerMap = {for (var p in state!.saveData.allPlayers) p.id: p};
    var bracket = state!.saveData.currentSeason.individualLeague;

    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      bracket = leagueService.createIndividualLeagueBracket(
        allPlayers: state!.saveData.allPlayers,
        playerTeamId: state!.saveData.playerTeamId,
        seasonNumber: state!.saveData.currentSeason.number,
      );
    }

    if (bracket.pcBangResults.isEmpty) {
      bracket = leagueService.simulateAllPcBangGroups(
        bracket: bracket,
        playerMap: playerMap,
      );
    }

    updateIndividualLeague(bracket);

    // 3. weekProgress를 5로 설정 (week 1, step 2 = 듀얼 1R)
    final updatedSeason = state!.saveData.currentSeason.copyWith(weekProgress: 5);
    final newSaveData = state!.saveData.updateSeason(updatedSeason);
    state = state!.copyWith(saveData: newSaveData);

    save();
  }

  /// 디버그: 8강#2까지만 완료 + 플레이오프 진입 상태로 스킵
  void debugSkipToPlayoffWith8Gang2() {
    if (state == null) return;

    final rand = Random();
    final leagueService = IndividualLeagueService();
    final isWinnersSeason = state!.saveData.currentSeason.isWinnersLeagueSeason;

    // 1. 모든 프로리그 경기 강제 완료
    final scheduleLength = state!.saveData.currentSeason.proleagueSchedule.length;
    for (int i = 0; i < scheduleLength; i++) {
      final match = state!.saveData.currentSeason.proleagueSchedule[i];
      if (match.isCompleted) continue;

      final homePlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.homeTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      final awayPlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.awayTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      if (homePlayers.isEmpty || awayPlayers.isEmpty) continue;

      if (isWinnersSeason) {
        _simulateWinnersLeagueMatch(i, match, homePlayers, awayPlayers, rand);
      } else {
        _simulateNormalMatch(i, match, homePlayers, awayPlayers, rand);
      }
    }

    // 2. PC방 예선 생성 & 시뮬레이션
    final playerMap = {for (var p in state!.saveData.allPlayers) p.id: p};
    var bracketN = state!.saveData.currentSeason.individualLeague;

    if (bracketN == null || bracketN.pcBangGroups.isEmpty) {
      bracketN = leagueService.createIndividualLeagueBracket(
        allPlayers: state!.saveData.allPlayers,
        playerTeamId: state!.saveData.playerTeamId,
        seasonNumber: state!.saveData.currentSeason.number,
      );
    }

    var bracket = bracketN;
    if (bracket.pcBangResults.isEmpty) {
      bracket = leagueService.simulateAllPcBangGroups(
        bracket: bracket,
        playerMap: playerMap,
      );
    }

    // 3. 듀얼토너먼트 (3라운드 전부)
    for (var round = 1; round <= 3; round++) {
      bracket = leagueService.simulateDualTournamentRound(
        bracket: bracket,
        playerMap: playerMap,
        round: round,
      );
    }

    // 4. 조지명식 (mainTournamentGroups 채우기)
    // 듀얼 진출자 추출
    final dualResults = bracket.dualTournamentResults;
    final dualQualifiers = <String>[];
    for (var gi = 0; gi < 12; gi++) {
      final groupStart = gi * 5;
      if (dualResults.length >= groupStart + 5) {
        dualQualifiers.add(dualResults[groupStart + 2].winnerId);
        dualQualifiers.add(dualResults[groupStart + 4].winnerId);
      }
    }
    // 시드 제외
    final seededIds = bracket.mainTournamentGroups
        .map((g) => g.isNotEmpty && g[0] != null ? g[0]! : '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final availableQualifiers = dualQualifiers
        .where((id) => !seededIds.contains(id))
        .toList()
      ..shuffle(rand);
    // 조에 배정
    final filledGroups = bracket.mainTournamentGroups
        .map((g) => List<String?>.from(g))
        .toList();
    var qIdx = 0;
    for (var gi = 0; gi < 8 && gi < filledGroups.length; gi++) {
      for (var si = 1; si < 4; si++) {
        if (qIdx < availableQualifiers.length) {
          filledGroups[gi][si] = availableQualifiers[qIdx++];
        }
      }
    }
    bracket = bracket.copyWith(
      mainTournamentGroups: filledGroups,
      mainTournamentPlayers: filledGroups.expand((g) => g.whereType<String>()).toList(),
    );

    // 5. 본선 32강~8강 전체 시뮬레이션
    bracket = leagueService.simulateRound32Half(half: 1, bracket: bracket, playerMap: playerMap);
    bracket = leagueService.simulateRound32Half(half: 2, bracket: bracket, playerMap: playerMap);
    bracket = leagueService.simulateRound16Half(half: 1, bracket: bracket, playerMap: playerMap);
    bracket = leagueService.simulateRound16Half(half: 2, bracket: bracket, playerMap: playerMap);
    bracket = leagueService.simulateQuarterFinalHalf(half: 1, bracket: bracket, playerMap: playerMap);
    bracket = leagueService.simulateQuarterFinalHalf(half: 2, bracket: bracket, playerMap: playerMap);

    updateIndividualLeague(bracket);

    // 6. weekProgress = 33 (모든 주차 완료)
    final updatedSeason = state!.saveData.currentSeason.copyWith(weekProgress: 33);
    final newSaveData = state!.saveData.updateSeason(updatedSeason);
    state = state!.copyWith(saveData: newSaveData);

    // 7. 플레이오프 시작 (순위 기반 대진표 생성 + phase → playoff34)
    startPlayoff();

    save();
  }

  /// 디버그: 8강 완료 + 플레이오프 진입 상태로 스킵
  void debugSkipToPlayoff() {
    if (state == null) return;

    final rand = Random();
    final leagueService = IndividualLeagueService();
    final isWinnersSeason = state!.saveData.currentSeason.isWinnersLeagueSeason;

    // 1. 모든 프로리그 경기 강제 완료 (플레이어 팀 포함)
    final scheduleLength = state!.saveData.currentSeason.proleagueSchedule.length;
    for (int i = 0; i < scheduleLength; i++) {
      final match = state!.saveData.currentSeason.proleagueSchedule[i];
      if (match.isCompleted) continue;

      final homePlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.homeTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      final awayPlayers = List<Player>.from(
        state!.saveData.getTeamPlayers(match.awayTeamId),
      )..sort((a, b) => b.stats.total.compareTo(a.stats.total));

      if (homePlayers.isEmpty || awayPlayers.isEmpty) continue;

      if (isWinnersSeason) {
        _simulateWinnersLeagueMatch(i, match, homePlayers, awayPlayers, rand);
      } else {
        _simulateNormalMatch(i, match, homePlayers, awayPlayers, rand);
      }
    }

    // 2. PC방 예선 생성 & 시뮬레이션
    final playerMap = {for (var p in state!.saveData.allPlayers) p.id: p};
    var bracketN = state!.saveData.currentSeason.individualLeague;

    if (bracketN == null || bracketN.pcBangGroups.isEmpty) {
      bracketN = leagueService.createIndividualLeagueBracket(
        allPlayers: state!.saveData.allPlayers,
        playerTeamId: state!.saveData.playerTeamId,
        seasonNumber: state!.saveData.currentSeason.number,
      );
    }

    var bracket = bracketN;
    if (bracket.pcBangResults.isEmpty) {
      bracket = leagueService.simulateAllPcBangGroups(
        bracket: bracket,
        playerMap: playerMap,
      );
    }

    // 3. 듀얼토너먼트 (3라운드 전부)
    for (var round = 1; round <= 3; round++) {
      bracket = leagueService.simulateDualTournamentRound(
        bracket: bracket,
        playerMap: playerMap,
        round: round,
      );
    }

    // 4. 조지명식 (mainTournamentGroups 채우기)
    final dualResults2 = bracket.dualTournamentResults;
    final dualQualifiers2 = <String>[];
    for (var gi = 0; gi < 12; gi++) {
      final groupStart = gi * 5;
      if (dualResults2.length >= groupStart + 5) {
        dualQualifiers2.add(dualResults2[groupStart + 2].winnerId);
        dualQualifiers2.add(dualResults2[groupStart + 4].winnerId);
      }
    }
    final seededIds2 = bracket.mainTournamentGroups
        .map((g) => g.isNotEmpty && g[0] != null ? g[0]! : '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final availableQualifiers2 = dualQualifiers2
        .where((id) => !seededIds2.contains(id))
        .toList()
      ..shuffle(rand);
    final filledGroups2 = bracket.mainTournamentGroups
        .map((g) => List<String?>.from(g))
        .toList();
    var qIdx2 = 0;
    for (var gi = 0; gi < 8 && gi < filledGroups2.length; gi++) {
      for (var si = 1; si < 4; si++) {
        if (qIdx2 < availableQualifiers2.length) {
          filledGroups2[gi][si] = availableQualifiers2[qIdx2++];
        }
      }
    }
    bracket = bracket.copyWith(
      mainTournamentGroups: filledGroups2,
      mainTournamentPlayers: filledGroups2.expand((g) => g.whereType<String>()).toList(),
    );

    // 5. 본선 시뮬레이션 (32강~결승 전부)
    bracket = leagueService.simulateMainTournament(
      bracket: bracket,
      playerMap: playerMap,
      showLogFromQuarterFinal: false,
    );

    updateIndividualLeague(bracket);

    // 6. weekProgress = 33 (모든 주차 완료)
    final updatedSeason2 = state!.saveData.currentSeason.copyWith(weekProgress: 33);
    final newSaveData2 = state!.saveData.updateSeason(updatedSeason2);
    state = state!.copyWith(saveData: newSaveData2);

    // 7. 플레이오프 시작 (순위 기반 대진표 생성 + phase → playoff34)
    startPlayoff();

    save();
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
    String? matchId,
  }) {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    final schedule = season.proleagueSchedule;

    // 해당 매치 찾기 (matchId가 있으면 정확히 찾고, 없으면 기존 방식)
    int matchIndex;
    if (matchId != null) {
      matchIndex = schedule.indexWhere((m) =>
          !m.isCompleted && m.matchId == matchId);
    } else {
      matchIndex = schedule.indexWhere((m) =>
          !m.isCompleted &&
          ((m.homeTeamId == homeTeamId && m.awayTeamId == awayTeamId) ||
           (m.homeTeamId == awayTeamId && m.awayTeamId == homeTeamId)));
    }

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

    // 주간 진행도 증가
    advanceWeekProgress();
  }

  /// 같은 라운드의 다른 팀 경기 시뮬레이션
  void _simulateOtherMatchesInRound(int roundNumber) {
    if (state == null) return;

    final season = state!.saveData.currentSeason;
    final schedule = season.proleagueSchedule;
    final playerTeamId = state!.saveData.playerTeamId;
    final rand = Random();
    final isWinnersSeason = season.isWinnersLeagueSeason;

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

      if (isWinnersSeason) {
        // 위너스리그 방식: 승자유지
        _simulateWinnersLeagueMatch(i, match, homePlayers, awayPlayers, rand);
      } else {
        // 일반 프로리그 방식
        _simulateNormalMatch(i, match, homePlayers, awayPlayers, rand);
      }
    }
  }

  /// 일반 프로리그 AI 시뮬레이션
  void _simulateNormalMatch(
    int matchIndex,
    ScheduleItem match,
    List<Player> homePlayers,
    List<Player> awayPlayers,
    Random rand,
  ) {
    final List<SetResult> sets = [];
    final List<Player> updatedPlayersList = [];
    int homeScore = 0;
    int awayScore = 0;
    int setIndex = 0;

    while (homeScore < 4 && awayScore < 4) {
      final homePlayer = homePlayers[setIndex % homePlayers.length];
      final awayPlayer = awayPlayers[setIndex % awayPlayers.length];

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

      final homeIdx = homePlayers.indexWhere((p) => p.id == homePlayer.id);
      if (homeIdx >= 0) homePlayers[homeIdx] = updatedHome;
      final awayIdx = awayPlayers.indexWhere((p) => p.id == awayPlayer.id);
      if (awayIdx >= 0) awayPlayers[awayIdx] = updatedAway;

      setIndex++;
    }

    _recordOtherMatchResult(matchIndex, match, homeScore, awayScore, sets, updatedPlayersList);
  }

  /// 위너스리그 AI 시뮬레이션 (승자유지 방식)
  void _simulateWinnersLeagueMatch(
    int matchIndex,
    ScheduleItem match,
    List<Player> homePlayers,
    List<Player> awayPlayers,
    Random rand,
  ) {
    final List<SetResult> sets = [];
    final List<Player> updatedPlayersList = [];
    int homeScore = 0;
    int awayScore = 0;

    // 승자유지: 첫 선수부터 시작, 패자팀이 다음 선수로 교체
    int homePlayerIndex = 0;
    int awayPlayerIndex = 0;
    final homeUsed = <int>{0}; // 사용된 선수 인덱스
    final awayUsed = <int>{0};

    while (homeScore < 4 && awayScore < 4) {
      final homePlayer = homePlayers[homePlayerIndex % homePlayers.length];
      final awayPlayer = awayPlayers[awayPlayerIndex % awayPlayers.length];

      final homeStrength = homePlayer.stats.applyCondition(homePlayer.displayCondition).total.toDouble();
      final awayStrength = awayPlayer.stats.applyCondition(awayPlayer.displayCondition).total.toDouble();
      final totalStrength = homeStrength + awayStrength;
      final homeWinProb = totalStrength > 0 ? homeStrength / totalStrength : 0.5;

      final homeWin = rand.nextDouble() < homeWinProb;

      if (homeWin) {
        homeScore++;
        // 패자(어웨이) 교체: 미출전 선수 중 다음
        awayPlayerIndex = _nextUnusedIndex(awayUsed, awayPlayers.length, awayPlayerIndex);
        awayUsed.add(awayPlayerIndex);
      } else {
        awayScore++;
        // 패자(홈) 교체: 미출전 선수 중 다음
        homePlayerIndex = _nextUnusedIndex(homeUsed, homePlayers.length, homePlayerIndex);
        homeUsed.add(homePlayerIndex);
      }

      sets.add(SetResult(
        mapId: 'map_${sets.length}',
        homePlayerId: homePlayer.id,
        awayPlayerId: awayPlayer.id,
        homeWin: homeWin,
      ));

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

      final homeIdx = homePlayers.indexWhere((p) => p.id == homePlayer.id);
      if (homeIdx >= 0) homePlayers[homeIdx] = updatedHome;
      final awayIdx = awayPlayers.indexWhere((p) => p.id == awayPlayer.id);
      if (awayIdx >= 0) awayPlayers[awayIdx] = updatedAway;
    }

    _recordOtherMatchResult(matchIndex, match, homeScore, awayScore, sets, updatedPlayersList);
  }

  /// 미출전 선수 중 다음 인덱스 찾기
  int _nextUnusedIndex(Set<int> used, int total, int current) {
    for (int i = 1; i < total; i++) {
      final candidate = (current + i) % total;
      if (!used.contains(candidate)) return candidate;
    }
    // 모든 선수 출전 완료 → 순환
    return (current + 1) % total;
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
    // 데칼코마니: 경기1(홀수슬롯) = 1차 리그, 경기2(짝수슬롯) = 2차 리그 역순
    // 행 r: 경기1=슬롯(2r+1), 경기2=슬롯(2r+2)
    // 1차 리그 행 r → 2차 리그 행 (10-r) = 데칼코마니
    final teams = state!.saveData.allTeams;
    final schedule = <ScheduleItem>[];
    int matchId = 0;

    // 1차 리그: 풀 라운드 로빈 (7라운드, 각 라운드 4경기)
    // 서클 메서드로 공정한 대진 생성
    final firstHalfMatchups = _generateRoundRobinMatchups(teams, rng);

    // 11행(0~10) 중 7행에 경기 배치 (4행은 NO match)
    final rows = List.generate(11, (i) => i);
    rows.shuffle(rng);
    final matchRows = rows.take(7).toList()..sort();

    // 1차 리그 경기 배치 (경기1 컬럼 = 홀수 슬롯)
    // 행 r → 슬롯 2r+1 (1, 3, 5, ..., 21)
    for (int i = 0; i < firstHalfMatchups.length; i++) {
      final matchup = firstHalfMatchups[i];
      final round = i ~/ 4; // 라운드 번호 (0~6)
      final slot = matchRows[round] * 2 + 1; // 경기1 컬럼 (홀수)

      schedule.add(ScheduleItem(
        matchId: 'match_${seasonNumber}_${matchId++}',
        roundNumber: slot,
        homeTeamId: matchup[0],
        awayTeamId: matchup[1],
      ));
    }

    // 2차 리그: 경기2 컬럼 (짝수 슬롯), 데칼코마니 역순
    // 행 r의 1차 리그 → 행 (10-r)의 2차 리그
    // 슬롯 = 23 - firstSlot (홀수→짝수 자연 변환)
    for (int i = 0; i < firstHalfMatchups.length; i++) {
      final matchup = firstHalfMatchups[i];
      final round = i ~/ 4; // 라운드 번호 (0~6)
      final firstSlot = matchRows[round] * 2 + 1;
      final secondSlot = 23 - firstSlot; // 데칼코마니 위치 (짝수)

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
      weekProgress: 0,
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
