import 'package:hive/hive.dart';
import 'player.dart';
import 'team.dart';
import 'item.dart';
import 'season.dart';
import 'match.dart';

part 'save_data.g.dart';

/// 세이브 데이터
@HiveType(typeId: 20)
class SaveData {
  @HiveField(0)
  final int slotNumber; // 슬롯 번호 (1-6)

  @HiveField(1)
  final String playerTeamId; // 플레이어가 선택한 팀 ID

  @HiveField(2)
  final List<Player> allPlayers; // 모든 선수 (8팀 + 무소속)

  @HiveField(3)
  final List<Team> allTeams; // 모든 팀 (8개)

  @HiveField(4)
  final Season currentSeason;

  @HiveField(5)
  final List<SeasonHistory> seasonHistories;

  @HiveField(6)
  final Inventory inventory;

  @HiveField(7)
  final DateTime savedAt;

  @HiveField(8)
  final int totalPlayTime; // 총 플레이 시간 (초)

  @HiveField(9)
  final List<Player> freeAgentPool; // 무소속 선수 풀

  @HiveField(10)
  final IndividualLeagueBracket? previousSeasonIndividualLeague; // 이전 시즌 개인리그 결과 (시드 배정용)

  const SaveData({
    required this.slotNumber,
    required this.playerTeamId,
    required this.allPlayers,
    required this.allTeams,
    required this.currentSeason,
    this.seasonHistories = const [],
    this.inventory = const Inventory(),
    required this.savedAt,
    this.totalPlayTime = 0,
    this.freeAgentPool = const [],
    this.previousSeasonIndividualLeague,
  });

  Team get playerTeam => allTeams.firstWhere((t) => t.id == playerTeamId);

  /// 슬롯 표시용 정보
  String get displayTeamName => playerTeam.name;
  int get displaySeasonNumber => currentSeason.number;
  int get displayRank {
    // TODO: 순위 계산 로직
    return 1;
  }

  /// 선수 조회
  Player? getPlayerById(String id) {
    return allPlayers.cast<Player?>().firstWhere(
      (p) => p?.id == id,
      orElse: () => null,
    );
  }

  /// 팀 조회
  Team? getTeamById(String id) {
    return allTeams.cast<Team?>().firstWhere(
      (t) => t?.id == id,
      orElse: () => null,
    );
  }

  /// 팀 소속 선수 목록
  List<Player> getTeamPlayers(String teamId) {
    final team = getTeamById(teamId);
    if (team == null) return [];
    return team.playerIds
        .map((id) => getPlayerById(id))
        .whereType<Player>()
        .toList();
  }

  /// 선수 업데이트
  SaveData updatePlayer(Player player) {
    final newPlayers = allPlayers.map((p) {
      if (p.id == player.id) return player;
      return p;
    }).toList();

    return copyWith(allPlayers: newPlayers);
  }

  /// 팀 업데이트
  SaveData updateTeam(Team team) {
    final newTeams = allTeams.map((t) {
      if (t.id == team.id) return team;
      return t;
    }).toList();

    return copyWith(allTeams: newTeams);
  }

  /// 여러 선수 업데이트
  SaveData updatePlayers(List<Player> players) {
    final playerMap = {for (var p in players) p.id: p};
    final newPlayers = allPlayers.map((p) {
      return playerMap[p.id] ?? p;
    }).toList();

    return copyWith(allPlayers: newPlayers);
  }

  /// 시즌 업데이트
  SaveData updateSeason(Season season) {
    return copyWith(currentSeason: season);
  }

  /// 인벤토리 업데이트
  SaveData updateInventory(Inventory newInventory) {
    return copyWith(inventory: newInventory);
  }

  /// 새 시즌 시작
  SaveData startNewSeason(Season newSeason) {
    // 이전 시즌 히스토리 추가
    final history = SeasonHistory(
      seasonNumber: currentSeason.number,
      proleagueChampionId: currentSeason.proleagueChampionId,
      proleagueRunnerUpId: currentSeason.proleagueRunnerUpId,
      individualChampionId: currentSeason.individualLeague?.championId,
      individualRunnerUpId: currentSeason.individualLeague?.runnerUpId,
    );

    // 모든 팀 시즌 리셋
    final newTeams = allTeams.map((t) => t.resetForNewSeason()).toList();

    return copyWith(
      currentSeason: newSeason,
      seasonHistories: [...seasonHistories, history],
      allTeams: newTeams,
      // 이전 시즌 개인리그 결과 저장 (다음 시즌 시드 배정용)
      previousSeasonIndividualLeague: currentSeason.individualLeague,
    );
  }

  /// 플레이 시간 추가
  SaveData addPlayTime(int seconds) {
    return copyWith(totalPlayTime: totalPlayTime + seconds);
  }

  /// 저장 시간 업데이트
  SaveData updateSavedAt() {
    return copyWith(savedAt: DateTime.now());
  }

  SaveData copyWith({
    int? slotNumber,
    String? playerTeamId,
    List<Player>? allPlayers,
    List<Team>? allTeams,
    Season? currentSeason,
    List<SeasonHistory>? seasonHistories,
    Inventory? inventory,
    DateTime? savedAt,
    int? totalPlayTime,
    List<Player>? freeAgentPool,
    IndividualLeagueBracket? previousSeasonIndividualLeague,
  }) {
    return SaveData(
      slotNumber: slotNumber ?? this.slotNumber,
      playerTeamId: playerTeamId ?? this.playerTeamId,
      allPlayers: allPlayers ?? this.allPlayers,
      allTeams: allTeams ?? this.allTeams,
      currentSeason: currentSeason ?? this.currentSeason,
      seasonHistories: seasonHistories ?? this.seasonHistories,
      inventory: inventory ?? this.inventory,
      savedAt: savedAt ?? this.savedAt,
      totalPlayTime: totalPlayTime ?? this.totalPlayTime,
      freeAgentPool: freeAgentPool ?? this.freeAgentPool,
      previousSeasonIndividualLeague: previousSeasonIndividualLeague ?? this.previousSeasonIndividualLeague,
    );
  }
}

/// 세이브 슬롯 정보 (목록 표시용)
@HiveType(typeId: 21)
class SaveSlotInfo {
  @HiveField(0)
  final int slotNumber;

  @HiveField(1)
  final String teamName;

  @HiveField(2)
  final int seasonNumber;

  @HiveField(3)
  final int rank;

  @HiveField(4)
  final DateTime savedAt;

  @HiveField(5)
  final bool isEmpty;

  const SaveSlotInfo({
    required this.slotNumber,
    this.teamName = '',
    this.seasonNumber = 0,
    this.rank = 0,
    required this.savedAt,
    this.isEmpty = true,
  });

  factory SaveSlotInfo.empty(int slotNumber) {
    return SaveSlotInfo(
      slotNumber: slotNumber,
      savedAt: DateTime.now(),
      isEmpty: true,
    );
  }

  factory SaveSlotInfo.fromSaveData(SaveData data) {
    return SaveSlotInfo(
      slotNumber: data.slotNumber,
      teamName: data.displayTeamName,
      seasonNumber: data.displaySeasonNumber,
      rank: data.displayRank,
      savedAt: data.savedAt,
      isEmpty: false,
    );
  }
}
