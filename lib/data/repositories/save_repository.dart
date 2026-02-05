import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/models.dart';
import '../../core/constants/initial_data.dart';
import '../../domain/services/individual_league_service.dart';

/// 세이브 데이터 저장소
class SaveRepository {
  static const String _saveBoxName = 'save_data';
  static const String _slotInfoBoxName = 'slot_info';
  static const int maxSlots = 6;

  late Box<Map<dynamic, dynamic>> _saveBox;
  late Box<Map<dynamic, dynamic>> _slotInfoBox;

  bool _isInitialized = false;

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    _saveBox = await Hive.openBox<Map<dynamic, dynamic>>(_saveBoxName);
    _slotInfoBox = await Hive.openBox<Map<dynamic, dynamic>>(_slotInfoBoxName);
    _isInitialized = true;
  }

  /// 모든 세이브 데이터 삭제 (앱 최초 실행 시)
  Future<void> clearAllSaves() async {
    await initialize();
    await _saveBox.clear();
    await _slotInfoBox.clear();
  }

  /// 슬롯 정보 목록 조회
  Future<List<SaveSlotInfo>> getSlotInfoList() async {
    await initialize();

    final List<SaveSlotInfo> slots = [];
    for (int i = 1; i <= maxSlots; i++) {
      final data = _slotInfoBox.get('slot_$i');
      if (data != null) {
        slots.add(SaveSlotInfo(
          slotNumber: i,
          teamName: (data['teamName'] as String?) ?? '',
          seasonNumber: (data['seasonNumber'] as int?) ?? 0,
          rank: (data['rank'] as int?) ?? 0,
          savedAt: DateTime.parse(data['savedAt'] as String),
          isEmpty: false,
        ));
      } else {
        slots.add(SaveSlotInfo.empty(i));
      }
    }
    return slots;
  }

  /// 세이브 데이터 저장
  Future<void> save(SaveData data) async {
    await initialize();

    // 세이브 데이터 직렬화
    final serialized = _serializeSaveData(data);
    await _saveBox.put('slot_${data.slotNumber}', serialized);

    // 슬롯 정보 업데이트
    await _slotInfoBox.put('slot_${data.slotNumber}', {
      'teamName': data.displayTeamName,
      'seasonNumber': data.displaySeasonNumber,
      'rank': data.displayRank,
      'savedAt': data.savedAt.toIso8601String(),
    });
  }

  /// 세이브 데이터 로드
  Future<SaveData?> load(int slotNumber) async {
    await initialize();

    final data = _saveBox.get('slot_$slotNumber');
    if (data == null) return null;

    return _deserializeSaveData(Map<String, dynamic>.from(data));
  }

  /// 슬롯 삭제
  Future<void> delete(int slotNumber) async {
    await initialize();

    await _saveBox.delete('slot_$slotNumber');
    await _slotInfoBox.delete('slot_$slotNumber');
  }

  /// 슬롯 사용 여부 확인
  Future<bool> isSlotUsed(int slotNumber) async {
    await initialize();
    return _saveBox.containsKey('slot_$slotNumber');
  }

  /// 새 게임 데이터 생성
  SaveData createNewGame({
    required int slotNumber,
    required String selectedTeamId,
  }) {
    final teams = InitialData.createTeams();
    final players = InitialData.createPlayers();
    final freeAgents = InitialData.createFreeAgentPool();

    // 선택된 팀을 플레이어 팀으로 설정
    final updatedTeams = teams.map((team) {
      if (team.id == selectedTeamId) {
        return team.copyWith(isPlayerTeam: true);
      }
      return team;
    }).toList();

    // 첫 시즌 생성 (개인리그 대진표 포함)
    final firstSeason = _createFirstSeason(
      teams: updatedTeams,
      players: players,
      playerTeamId: selectedTeamId,
    );

    return SaveData(
      slotNumber: slotNumber,
      playerTeamId: selectedTeamId,
      allPlayers: players,
      allTeams: updatedTeams,
      currentSeason: firstSeason,
      freeAgentPool: freeAgents,
      savedAt: DateTime.now(),
    );
  }

  /// 첫 시즌 생성
  Season _createFirstSeason({
    required List<Team> teams,
    required List<Player> players,
    required String playerTeamId,
  }) {
    // 시즌맵 랜덤 선정 (12개 중 7개)
    final allMaps = GameMaps.all;
    final shuffledMaps = List<GameMap>.from(allMaps)..shuffle(Random());
    final seasonMaps = shuffledMaps.take(7).map((m) => m.id).toList();

    // 프로리그 일정 생성
    final schedule = _createProleagueSchedule(teams);

    // 개인리그 대진표 생성 (PC방 예선 조 편성까지)
    final leagueService = IndividualLeagueService();
    final individualLeague = leagueService.createIndividualLeagueBracket(
      allPlayers: players,
      playerTeamId: playerTeamId,
      seasonNumber: 1,
      previousSeasonBracket: null,
    );

    return Season(
      number: 1,
      seasonMapIds: seasonMaps,
      proleagueSchedule: schedule,
      individualLeague: individualLeague,
    );
  }

  /// 프로리그 일정 생성 (각 팀당 14경기 = 7주차 × 2경기)
  List<ScheduleItem> _createProleagueSchedule(List<Team> teams) {
    final schedule = <ScheduleItem>[];
    final teamIds = teams.map((t) => t.id).toList();
    final random = Random();
    final teamCount = teams.length; // 8팀
    final matchesPerRound = teamCount ~/ 2; // 4경기

    // 라운드 로빈 방식으로 일정 생성
    int matchId = 1;
    final shuffledTeams = List<String>.from(teamIds)..shuffle(random);

    // 14라운드 진행 (각 팀당 14경기, 7주차 × 2경기)
    // 8팀 기준: (n-1)*2 = 14 라운드로 모든 팀이 두 번씩 대결
    final totalRounds = (teamCount - 1) * 2;
    for (int round = 1; round <= totalRounds; round++) {
      // 매 라운드 4경기 (8팀 / 2)
      for (int i = 0; i < matchesPerRound; i++) {
        final homeIndex = i;
        final awayIndex = teamCount - 1 - i;

        schedule.add(ScheduleItem(
          matchId: 'match_$matchId',
          homeTeamId: shuffledTeams[homeIndex],
          awayTeamId: shuffledTeams[awayIndex],
          roundNumber: round,
        ));
        matchId++;
      }

      // 라운드 로빈 회전
      final last = shuffledTeams.removeLast();
      shuffledTeams.insert(1, last);
    }

    return schedule;
  }

  // ===== 직렬화/역직렬화 =====

  Map<String, dynamic> _serializeSaveData(SaveData data) {
    return {
      'slotNumber': data.slotNumber,
      'playerTeamId': data.playerTeamId,
      'allPlayers': data.allPlayers.map(_serializePlayer).toList(),
      'allTeams': data.allTeams.map(_serializeTeam).toList(),
      'currentSeason': _serializeSeason(data.currentSeason),
      'seasonHistories': data.seasonHistories.map(_serializeSeasonHistory).toList(),
      'inventory': _serializeInventory(data.inventory),
      'savedAt': data.savedAt.toIso8601String(),
      'totalPlayTime': data.totalPlayTime,
      'freeAgentPool': data.freeAgentPool.map(_serializePlayer).toList(),
    };
  }

  SaveData _deserializeSaveData(Map<String, dynamic> data) {
    return SaveData(
      slotNumber: data['slotNumber'] as int,
      playerTeamId: data['playerTeamId'] as String,
      allPlayers: (data['allPlayers'] as List).map((p) => _deserializePlayer(Map<String, dynamic>.from(p as Map))).toList(),
      allTeams: (data['allTeams'] as List).map((t) => _deserializeTeam(Map<String, dynamic>.from(t as Map))).toList(),
      currentSeason: _deserializeSeason(Map<String, dynamic>.from(data['currentSeason'] as Map)),
      seasonHistories: (data['seasonHistories'] as List?)?.map((h) => _deserializeSeasonHistory(Map<String, dynamic>.from(h as Map))).toList() ?? [],
      inventory: _deserializeInventory(Map<String, dynamic>.from((data['inventory'] as Map?) ?? {})),
      savedAt: DateTime.parse(data['savedAt'] as String),
      totalPlayTime: (data['totalPlayTime'] as int?) ?? 0,
      freeAgentPool: (data['freeAgentPool'] as List?)?.map((p) => _deserializePlayer(Map<String, dynamic>.from(p as Map))).toList() ?? [],
    );
  }

  Map<String, dynamic> _serializePlayer(Player player) {
    return {
      'id': player.id,
      'name': player.name,
      'nickname': player.nickname,
      'raceIndex': player.raceIndex,
      'stats': _serializeStats(player.stats),
      'levelValue': player.levelValue,
      'condition': player.condition,
      'record': _serializeRecord(player.record),
      'teamId': player.teamId,
      'isSlump': player.isSlump,
      'injuryGames': player.injuryGames,
      'careerSeasons': player.careerSeasons,
      'experience': player.experience,
    };
  }

  Player _deserializePlayer(Map<String, dynamic> data) {
    // 하위 호환성: 기존 seasonSinceLastLevelUp을 careerSeasons로 마이그레이션
    final careerSeasons = (data['careerSeasons'] as int?) ??
        (data['seasonSinceLastLevelUp'] as int?) ??
        0;

    return Player(
      id: data['id'] as String,
      name: data['name'] as String,
      nickname: data['nickname'] as String,
      raceIndex: data['raceIndex'] as int,
      stats: _deserializeStats(Map<String, dynamic>.from(data['stats'] as Map)),
      levelValue: data['levelValue'] as int,
      condition: data['condition'] as int,
      record: _deserializeRecord(Map<String, dynamic>.from(data['record'] as Map)),
      teamId: data['teamId'] as String?,
      isSlump: (data['isSlump'] as bool?) ?? false,
      injuryGames: (data['injuryGames'] as int?) ?? 0,
      careerSeasons: careerSeasons,
      experience: (data['experience'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> _serializeStats(PlayerStats stats) {
    return {
      'sense': stats.sense,
      'control': stats.control,
      'attack': stats.attack,
      'harass': stats.harass,
      'strategy': stats.strategy,
      'macro': stats.macro,
      'defense': stats.defense,
      'scout': stats.scout,
    };
  }

  PlayerStats _deserializeStats(Map<String, dynamic> data) {
    return PlayerStats(
      sense: data['sense'] as int,
      control: data['control'] as int,
      attack: data['attack'] as int,
      harass: data['harass'] as int,
      strategy: data['strategy'] as int,
      macro: data['macro'] as int,
      defense: data['defense'] as int,
      scout: data['scout'] as int,
    );
  }

  Map<String, dynamic> _serializeRecord(PlayerRecord record) {
    return {
      'wins': record.wins,
      'losses': record.losses,
      'vsTerranWins': record.vsTerranWins,
      'vsTerranLosses': record.vsTerranLosses,
      'vsZergWins': record.vsZergWins,
      'vsZergLosses': record.vsZergLosses,
      'vsProtossWins': record.vsProtossWins,
      'vsProtossLosses': record.vsProtossLosses,
      'championships': record.championships,
      'runnerUps': record.runnerUps,
      'currentWinStreak': record.currentWinStreak,
      'maxWinStreak': record.maxWinStreak,
    };
  }

  PlayerRecord _deserializeRecord(Map<String, dynamic> data) {
    return PlayerRecord(
      wins: data['wins'] as int,
      losses: data['losses'] as int,
      vsTerranWins: data['vsTerranWins'] as int,
      vsTerranLosses: data['vsTerranLosses'] as int,
      vsZergWins: data['vsZergWins'] as int,
      vsZergLosses: data['vsZergLosses'] as int,
      vsProtossWins: data['vsProtossWins'] as int,
      vsProtossLosses: data['vsProtossLosses'] as int,
      championships: data['championships'] as int,
      runnerUps: data['runnerUps'] as int,
      currentWinStreak: data['currentWinStreak'] as int,
      maxWinStreak: data['maxWinStreak'] as int,
    );
  }

  Map<String, dynamic> _serializeTeam(Team team) {
    return {
      'id': team.id,
      'name': team.name,
      'shortName': team.shortName,
      'colorValue': team.colorValue,
      'playerIds': team.playerIds,
      'acePlayerId': team.acePlayerId,
      'money': team.money,
      'actionPoints': team.actionPoints,
      'record': _serializeTeamRecord(team.record),
      'seasonRecord': _serializeTeamRecord(team.seasonRecord),
      'isPlayerTeam': team.isPlayerTeam,
    };
  }

  Team _deserializeTeam(Map<String, dynamic> data) {
    return Team(
      id: data['id'] as String,
      name: data['name'] as String,
      shortName: data['shortName'] as String,
      colorValue: data['colorValue'] as int,
      playerIds: List<String>.from(data['playerIds'] as List),
      acePlayerId: data['acePlayerId'] as String?,
      money: data['money'] as int,
      actionPoints: data['actionPoints'] as int,
      record: _deserializeTeamRecord(Map<String, dynamic>.from(data['record'] as Map)),
      seasonRecord: _deserializeTeamRecord(Map<String, dynamic>.from(data['seasonRecord'] as Map)),
      isPlayerTeam: (data['isPlayerTeam'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> _serializeTeamRecord(TeamRecord record) {
    return {
      'wins': record.wins,
      'losses': record.losses,
      'setWins': record.setWins,
      'setLosses': record.setLosses,
      'proleagueChampionships': record.proleagueChampionships,
      'proleagueRunnerUps': record.proleagueRunnerUps,
      'individualChampionships': record.individualChampionships,
      'individualRunnerUps': record.individualRunnerUps,
    };
  }

  TeamRecord _deserializeTeamRecord(Map<String, dynamic> data) {
    return TeamRecord(
      wins: data['wins'] as int,
      losses: data['losses'] as int,
      setWins: data['setWins'] as int,
      setLosses: data['setLosses'] as int,
      proleagueChampionships: data['proleagueChampionships'] as int,
      proleagueRunnerUps: data['proleagueRunnerUps'] as int,
      individualChampionships: data['individualChampionships'] as int,
      individualRunnerUps: data['individualRunnerUps'] as int,
    );
  }

  Map<String, dynamic> _serializeSeason(Season season) {
    return {
      'number': season.number,
      'seasonMapIds': season.seasonMapIds,
      'proleagueSchedule': season.proleagueSchedule.map(_serializeScheduleItem).toList(),
      'currentMatchIndex': season.currentMatchIndex,
      'matchesSinceLastBonus': season.matchesSinceLastBonus,
      'individualLeague': season.individualLeague != null
          ? _serializeIndividualLeague(season.individualLeague!)
          : null,
      'isCompleted': season.isCompleted,
      'proleagueChampionId': season.proleagueChampionId,
      'proleagueRunnerUpId': season.proleagueRunnerUpId,
      'phaseIndex': season.phaseIndex,
      'playoff': season.playoff != null ? _serializePlayoff(season.playoff!) : null,
    };
  }

  Season _deserializeSeason(Map<String, dynamic> data) {
    return Season(
      number: data['number'] as int,
      seasonMapIds: List<String>.from(data['seasonMapIds'] as List),
      proleagueSchedule: (data['proleagueSchedule'] as List)
          .map((s) => _deserializeScheduleItem(Map<String, dynamic>.from(s as Map)))
          .toList(),
      currentMatchIndex: data['currentMatchIndex'] as int,
      matchesSinceLastBonus: data['matchesSinceLastBonus'] as int,
      individualLeague: data['individualLeague'] != null
          ? _deserializeIndividualLeague(Map<String, dynamic>.from(data['individualLeague'] as Map))
          : null,
      isCompleted: data['isCompleted'] as bool,
      proleagueChampionId: data['proleagueChampionId'] as String?,
      proleagueRunnerUpId: data['proleagueRunnerUpId'] as String?,
      phaseIndex: (data['phaseIndex'] as int?) ?? 0,
      playoff: data['playoff'] != null
          ? _deserializePlayoff(Map<String, dynamic>.from(data['playoff'] as Map))
          : null,
    );
  }

  Map<String, dynamic> _serializePlayoff(PlayoffBracket playoff) {
    return {
      'firstPlaceTeamId': playoff.firstPlaceTeamId,
      'secondPlaceTeamId': playoff.secondPlaceTeamId,
      'thirdPlaceTeamId': playoff.thirdPlaceTeamId,
      'fourthPlaceTeamId': playoff.fourthPlaceTeamId,
      'match34': playoff.match34 != null ? _serializeMatchResult(playoff.match34!) : null,
      'match23': playoff.match23 != null ? _serializeMatchResult(playoff.match23!) : null,
      'matchFinal': playoff.matchFinal != null ? _serializeMatchResult(playoff.matchFinal!) : null,
    };
  }

  PlayoffBracket _deserializePlayoff(Map<String, dynamic> data) {
    return PlayoffBracket(
      firstPlaceTeamId: data['firstPlaceTeamId'] as String,
      secondPlaceTeamId: data['secondPlaceTeamId'] as String,
      thirdPlaceTeamId: data['thirdPlaceTeamId'] as String,
      fourthPlaceTeamId: data['fourthPlaceTeamId'] as String,
      match34: data['match34'] != null
          ? _deserializeMatchResult(Map<String, dynamic>.from(data['match34'] as Map))
          : null,
      match23: data['match23'] != null
          ? _deserializeMatchResult(Map<String, dynamic>.from(data['match23'] as Map))
          : null,
      matchFinal: data['matchFinal'] != null
          ? _deserializeMatchResult(Map<String, dynamic>.from(data['matchFinal'] as Map))
          : null,
    );
  }

  Map<String, dynamic> _serializeScheduleItem(ScheduleItem item) {
    return {
      'matchId': item.matchId,
      'homeTeamId': item.homeTeamId,
      'awayTeamId': item.awayTeamId,
      'roundNumber': item.roundNumber,
      'isCompleted': item.isCompleted,
      'result': item.result != null ? _serializeMatchResult(item.result!) : null,
    };
  }

  ScheduleItem _deserializeScheduleItem(Map<String, dynamic> data) {
    return ScheduleItem(
      matchId: data['matchId'] as String,
      homeTeamId: data['homeTeamId'] as String,
      awayTeamId: data['awayTeamId'] as String,
      roundNumber: data['roundNumber'] as int,
      isCompleted: data['isCompleted'] as bool,
      result: data['result'] != null
          ? _deserializeMatchResult(Map<String, dynamic>.from(data['result'] as Map))
          : null,
    );
  }

  Map<String, dynamic> _serializeMatchResult(MatchResult result) {
    return {
      'id': result.id,
      'homeTeamId': result.homeTeamId,
      'awayTeamId': result.awayTeamId,
      'sets': result.sets.map(_serializeSetResult).toList(),
      'isCompleted': result.isCompleted,
      'seasonNumber': result.seasonNumber,
      'roundNumber': result.roundNumber,
    };
  }

  MatchResult _deserializeMatchResult(Map<String, dynamic> data) {
    return MatchResult(
      id: data['id'] as String,
      homeTeamId: data['homeTeamId'] as String,
      awayTeamId: data['awayTeamId'] as String,
      sets: (data['sets'] as List)
          .map((s) => _deserializeSetResult(Map<String, dynamic>.from(s as Map)))
          .toList(),
      isCompleted: data['isCompleted'] as bool,
      seasonNumber: data['seasonNumber'] as int,
      roundNumber: data['roundNumber'] as int,
    );
  }

  Map<String, dynamic> _serializeSetResult(SetResult result) {
    return {
      'mapId': result.mapId,
      'homePlayerId': result.homePlayerId,
      'awayPlayerId': result.awayPlayerId,
      'homeWin': result.homeWin,
      'battleLog': result.battleLog,
      'finalHomeArmy': result.finalHomeArmy,
      'finalAwayArmy': result.finalAwayArmy,
      'finalHomeResources': result.finalHomeResources,
      'finalAwayResources': result.finalAwayResources,
    };
  }

  SetResult _deserializeSetResult(Map<String, dynamic> data) {
    return SetResult(
      mapId: data['mapId'] as String,
      homePlayerId: data['homePlayerId'] as String,
      awayPlayerId: data['awayPlayerId'] as String,
      homeWin: data['homeWin'] as bool,
      battleLog: List<String>.from(data['battleLog'] as List),
      finalHomeArmy: data['finalHomeArmy'] as int,
      finalAwayArmy: data['finalAwayArmy'] as int,
      finalHomeResources: data['finalHomeResources'] as int,
      finalAwayResources: data['finalAwayResources'] as int,
    );
  }

  Map<String, dynamic> _serializeIndividualLeague(IndividualLeagueBracket bracket) {
    return {
      'seasonNumber': bracket.seasonNumber,
      'pcBangGroups': bracket.pcBangGroups,
      'dualTournamentPlayers': bracket.dualTournamentPlayers,
      'mainTournamentPlayers': bracket.mainTournamentPlayers,
      'championId': bracket.championId,
      'runnerUpId': bracket.runnerUpId,
    };
  }

  IndividualLeagueBracket _deserializeIndividualLeague(Map<String, dynamic> data) {
    return IndividualLeagueBracket(
      seasonNumber: data['seasonNumber'] as int,
      pcBangGroups: (data['pcBangGroups'] as List?)?.map((g) => List<String>.from(g as List)).toList() ?? [],
      dualTournamentPlayers: List<String>.from((data['dualTournamentPlayers'] as List?) ?? []),
      mainTournamentPlayers: List<String>.from((data['mainTournamentPlayers'] as List?) ?? []),
      championId: data['championId'] as String?,
      runnerUpId: data['runnerUpId'] as String?,
    );
  }

  Map<String, dynamic> _serializeSeasonHistory(SeasonHistory history) {
    return {
      'seasonNumber': history.seasonNumber,
      'proleagueChampionId': history.proleagueChampionId,
      'proleagueRunnerUpId': history.proleagueRunnerUpId,
      'individualChampionId': history.individualChampionId,
      'individualRunnerUpId': history.individualRunnerUpId,
      'mvpPlayerId': history.mvpPlayerId,
    };
  }

  SeasonHistory _deserializeSeasonHistory(Map<String, dynamic> data) {
    return SeasonHistory(
      seasonNumber: data['seasonNumber'] as int,
      proleagueChampionId: data['proleagueChampionId'] as String?,
      proleagueRunnerUpId: data['proleagueRunnerUpId'] as String?,
      individualChampionId: data['individualChampionId'] as String?,
      individualRunnerUpId: data['individualRunnerUpId'] as String?,
      mvpPlayerId: data['mvpPlayerId'] as String?,
    );
  }

  Map<String, dynamic> _serializeInventory(Inventory inventory) {
    return {
      'consumables': inventory.consumables,
      'equipments': inventory.equipments.map(_serializeEquipmentInstance).toList(),
    };
  }

  Inventory _deserializeInventory(Map<String, dynamic> data) {
    return Inventory(
      consumables: Map<String, int>.from((data['consumables'] as Map?) ?? {}),
      equipments: (data['equipments'] as List?)
          ?.map((e) => _deserializeEquipmentInstance(Map<String, dynamic>.from(e as Map)))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> _serializeEquipmentInstance(EquipmentInstance instance) {
    return {
      'equipmentId': instance.equipmentId,
      'currentDurability': instance.currentDurability,
      'equippedPlayerId': instance.equippedPlayerId,
    };
  }

  EquipmentInstance _deserializeEquipmentInstance(Map<String, dynamic> data) {
    return EquipmentInstance(
      equipmentId: data['equipmentId'] as String,
      currentDurability: data['currentDurability'] as int,
      equippedPlayerId: data['equippedPlayerId'] as String?,
    );
  }
}
