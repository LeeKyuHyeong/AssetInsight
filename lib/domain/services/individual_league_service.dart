import 'dart:math';
import '../models/models.dart';
import 'match_simulation_service.dart';

/// 개인리그 시뮬레이션 서비스
class IndividualLeagueService {
  final MatchSimulationService _matchService = MatchSimulationService();
  final Random _random = Random();

  /// PC방 예선 조 편성 (24개 조, 각 조 4명)
  IndividualLeagueBracket createPcBangGroups({
    required List<Player> allPlayers,
    required String playerTeamId,
    required int seasonNumber,
  }) {
    // 모든 선수를 등급순으로 정렬 (높은 등급 먼저)
    final sortedPlayers = List<Player>.from(allPlayers)
      ..sort((a, b) => b.grade.index - a.grade.index);

    // 96명 선발 (24조 × 4명)
    final selectedPlayers = sortedPlayers.take(96).toList();

    // 우리팀 선수들을 먼저 찾기
    final myTeamPlayers =
        selectedPlayers.where((p) => p.teamId == playerTeamId).toList();
    final otherPlayers =
        selectedPlayers.where((p) => p.teamId != playerTeamId).toList();

    // 우리팀 선수들을 등급순으로 상위 조에 배정
    myTeamPlayers.sort((a, b) => b.grade.index - a.grade.index);

    // 24개 조 초기화
    final groups = List.generate(24, (_) => <String>[]);

    // 우리팀 선수 배정 (상위 등급일수록 낮은 조 번호)
    for (var i = 0; i < myTeamPlayers.length && i < 24; i++) {
      groups[i].add(myTeamPlayers[i].id);
    }

    // 남은 선수들 섞기
    otherPlayers.shuffle(_random);

    // 남은 선수들을 각 조에 4명이 될 때까지 배정
    var playerIndex = 0;
    for (var groupIndex = 0; groupIndex < 24; groupIndex++) {
      while (groups[groupIndex].length < 4 && playerIndex < otherPlayers.length) {
        groups[groupIndex].add(otherPlayers[playerIndex].id);
        playerIndex++;
      }
    }

    return IndividualLeagueBracket(
      seasonNumber: seasonNumber,
      pcBangGroups: groups,
    );
  }

  /// PC방 예선 한 조 시뮬레이션 (단판 토너먼트)
  PcBangGroupResult simulatePcBangGroup({
    required int groupIndex,
    required List<String> playerIds,
    required Map<String, Player> playerMap,
  }) {
    if (playerIds.length != 4) {
      throw ArgumentError('Each group must have exactly 4 players');
    }

    final maps = GameMaps.all;
    final results = <IndividualMatchResult>[];

    // 4강전 (0 vs 1, 2 vs 3)
    final semiFinal1 = _simulateIndividualMatch(
      player1Id: playerIds[0],
      player2Id: playerIds[1],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal1);

    final semiFinal2 = _simulateIndividualMatch(
      player1Id: playerIds[2],
      player2Id: playerIds[3],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal2);

    // 결승전
    final final_ = _simulateIndividualMatch(
      player1Id: semiFinal1.winnerId,
      player2Id: semiFinal2.winnerId,
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(final_);

    return PcBangGroupResult(
      groupIndex: groupIndex,
      matches: results,
      winnerId: final_.winnerId,
      semiFinal1WinnerId: semiFinal1.winnerId,
      semiFinal2WinnerId: semiFinal2.winnerId,
    );
  }

  /// 모든 PC방 예선 시뮬레이션
  IndividualLeagueBracket simulateAllPcBangGroups({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
  }) {
    final allResults = <IndividualMatchResult>[];
    final dualTournamentPlayers = <String>[];

    for (var i = 0; i < bracket.pcBangGroups.length; i++) {
      final result = simulatePcBangGroup(
        groupIndex: i,
        playerIds: bracket.pcBangGroups[i],
        playerMap: playerMap,
      );
      allResults.addAll(result.matches);
      dualTournamentPlayers.add(result.winnerId);
    }

    return bracket.copyWith(
      pcBangResults: allResults,
      dualTournamentPlayers: dualTournamentPlayers,
    );
  }

  /// 듀얼토너먼트 시뮬레이션
  /// 24명 → 승자조/패자조 → 8명 진출
  IndividualLeagueBracket simulateDualTournament({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
  }) {
    final players = List<String>.from(bracket.dualTournamentPlayers);
    final maps = GameMaps.all;
    final results = <IndividualMatchResult>[];

    // 승자조 (Winners Bracket)
    // Round 1: 24명 → 12승자, 12패자
    final winnersR1Winners = <String>[];
    final winnersR1Losers = <String>[];

    for (var i = 0; i < 12; i++) {
      final match = _simulateIndividualMatch(
        player1Id: players[i * 2],
        player2Id: players[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      winnersR1Winners.add(match.winnerId);
      winnersR1Losers.add(match.loserId);
    }

    // 승자조 Round 2: 12명 → 6승자, 6패자
    final winnersR2Winners = <String>[];
    final winnersR2Losers = <String>[];

    for (var i = 0; i < 6; i++) {
      final match = _simulateIndividualMatch(
        player1Id: winnersR1Winners[i * 2],
        player2Id: winnersR1Winners[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      winnersR2Winners.add(match.winnerId);
      winnersR2Losers.add(match.loserId);
    }

    // 패자조 Round 1: 12명 → 6명 탈락
    final losersR1Winners = <String>[];

    for (var i = 0; i < 6; i++) {
      final match = _simulateIndividualMatch(
        player1Id: winnersR1Losers[i * 2],
        player2Id: winnersR1Losers[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR1Winners.add(match.winnerId);
    }

    // 패자조 Round 2: 6명(패자조R1승자) vs 6명(승자조R2패자) → 6명 탈락
    final losersR2Winners = <String>[];

    for (var i = 0; i < 6; i++) {
      final match = _simulateIndividualMatch(
        player1Id: losersR1Winners[i],
        player2Id: winnersR2Losers[i],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR2Winners.add(match.winnerId);
    }

    // 패자조 Round 3: 6명 → 3명 탈락
    final losersR3Winners = <String>[];

    for (var i = 0; i < 3; i++) {
      final match = _simulateIndividualMatch(
        player1Id: losersR2Winners[i * 2],
        player2Id: losersR2Winners[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR3Winners.add(match.winnerId);
    }

    // 승자조 Round 3: 6명 → 3승자, 3패자
    final winnersR3Winners = <String>[];
    final winnersR3Losers = <String>[];

    for (var i = 0; i < 3; i++) {
      final match = _simulateIndividualMatch(
        player1Id: winnersR2Winners[i * 2],
        player2Id: winnersR2Winners[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      winnersR3Winners.add(match.winnerId);
      winnersR3Losers.add(match.loserId);
    }

    // 패자조 Round 4: 3명(패자조R3승자) vs 3명(승자조R3패자) → 3명 탈락
    final losersR4Winners = <String>[];

    for (var i = 0; i < 3; i++) {
      final match = _simulateIndividualMatch(
        player1Id: losersR3Winners[i],
        player2Id: winnersR3Losers[i],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR4Winners.add(match.winnerId);
    }

    // 최종 진출자: 승자조 3명 + 패자조 최종 3명 + 시드 2명 = 8명
    // 시드 2명은 지난 시즌 4강 진출자 (여기서는 랜덤)
    final advancingPlayers = <String>[
      ...winnersR3Winners,
      ...losersR4Winners,
    ];

    // 부족분 채우기 (8명까지)
    while (advancingPlayers.length < 8) {
      // 탈락한 선수 중 랜덤 복귀
      final allParticipants = players.toSet();
      final eliminated = allParticipants.difference(advancingPlayers.toSet());
      if (eliminated.isNotEmpty) {
        advancingPlayers.add(eliminated.first);
      }
    }

    return bracket.copyWith(
      dualTournamentResults: results,
      mainTournamentPlayers: advancingPlayers.take(8).toList(),
    );
  }

  /// 본선 (32강~결승) 시뮬레이션
  /// 실제로는 8명이 진출하지만, 명칭상 32강부터 시작
  IndividualLeagueBracket simulateMainTournament({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
    bool showLogFromQuarterFinal = true,
  }) {
    var players = List<String>.from(bracket.mainTournamentPlayers);
    final maps = GameMaps.all;
    final results = <IndividualMatchResult>[];

    // 8강까지 추가 선수 배정 (실제 32명 필요시)
    // 여기서는 8명으로 진행 (8강 = 8명)

    // 8강 (Quarter Final): 8명 → 4명
    final quarterFinalWinners = <String>[];
    for (var i = 0; i < 4 && i * 2 + 1 < players.length; i++) {
      final match = _simulateIndividualMatch(
        player1Id: players[i * 2],
        player2Id: players[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.quarterFinal,
        showBattleLog: showLogFromQuarterFinal,
      );
      results.add(match);
      quarterFinalWinners.add(match.winnerId);
    }

    // 4강 (Semi Final): 4명 → 2명
    final semiFinalWinners = <String>[];
    for (var i = 0; i < 2 && i * 2 + 1 < quarterFinalWinners.length; i++) {
      final match = _simulateIndividualMatch(
        player1Id: quarterFinalWinners[i * 2],
        player2Id: quarterFinalWinners[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.semiFinal,
        showBattleLog: showLogFromQuarterFinal,
      );
      results.add(match);
      semiFinalWinners.add(match.winnerId);
    }

    // 결승 (Final): 2명 → 1명
    if (semiFinalWinners.length >= 2) {
      final finalMatch = _simulateIndividualMatch(
        player1Id: semiFinalWinners[0],
        player2Id: semiFinalWinners[1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.final_,
        showBattleLog: showLogFromQuarterFinal,
      );
      results.add(finalMatch);

      return bracket.copyWith(
        mainTournamentResults: results,
        championId: finalMatch.winnerId,
        runnerUpId: finalMatch.loserId,
      );
    }

    return bracket.copyWith(
      mainTournamentResults: results,
    );
  }

  /// 개인 경기 시뮬레이션
  IndividualMatchResult _simulateIndividualMatch({
    required String player1Id,
    required String player2Id,
    required Map<String, Player> playerMap,
    required GameMap map,
    required IndividualLeagueStage stage,
    bool showBattleLog = false,
  }) {
    final player1 = playerMap[player1Id]!;
    final player2 = playerMap[player2Id]!;

    final setResult = _matchService.simulateMatch(
      homePlayer: player1,
      awayPlayer: player2,
      map: map,
    );

    return IndividualMatchResult(
      id: '${stage.name}_${player1Id}_$player2Id',
      player1Id: player1Id,
      player2Id: player2Id,
      winnerId: setResult.homeWin ? player1Id : player2Id,
      mapId: map.id,
      stageIndex: stage.index,
      battleLog: showBattleLog ? setResult.battleLog : [],
      showBattleLog: showBattleLog,
    );
  }

  /// 조별 결과 가져오기
  PcBangGroupResult? getGroupResult(
    IndividualLeagueBracket bracket,
    int groupIndex,
  ) {
    if (bracket.pcBangResults.isEmpty) return null;

    // 해당 조의 매치 결과들 찾기
    final groupPlayers = bracket.pcBangGroups[groupIndex];
    final groupMatches = <IndividualMatchResult>[];

    // 각 조는 3경기 (4강 2경기 + 결승 1경기)
    final startIndex = groupIndex * 3;
    if (startIndex + 3 <= bracket.pcBangResults.length) {
      groupMatches.addAll(bracket.pcBangResults.sublist(startIndex, startIndex + 3));
    }

    if (groupMatches.length < 3) return null;

    return PcBangGroupResult(
      groupIndex: groupIndex,
      matches: groupMatches,
      winnerId: groupMatches[2].winnerId,
      semiFinal1WinnerId: groupMatches[0].winnerId,
      semiFinal2WinnerId: groupMatches[1].winnerId,
    );
  }
}

/// PC방 예선 조별 결과
class PcBangGroupResult {
  final int groupIndex;
  final List<IndividualMatchResult> matches;
  final String winnerId;
  final String semiFinal1WinnerId;
  final String semiFinal2WinnerId;

  const PcBangGroupResult({
    required this.groupIndex,
    required this.matches,
    required this.winnerId,
    required this.semiFinal1WinnerId,
    required this.semiFinal2WinnerId,
  });
}
