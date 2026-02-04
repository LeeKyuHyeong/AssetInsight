import 'dart:math';
import '../models/models.dart';
import 'match_simulation_service.dart';

/// 개인리그 시뮬레이션 서비스
class IndividualLeagueService {
  final MatchSimulationService _matchService = MatchSimulationService();
  final Random _random = Random();

  /// 개인리그 시드 배정 및 조 편성
  ///
  /// 시드 배정 방식:
  /// - 조지명식(32강→8강) 직행: 이전 시즌 8강 진출자 (1~8등)
  /// - 듀얼토너먼트 1,3시드: 이전 시즌 32강 진출자 (조지명식 탈락자 포함)
  /// - PC방 예선: 나머지 선수들
  ///
  /// 첫 시즌(이전 시즌 없음)은 등급순으로 배정
  IndividualLeagueBracket createIndividualLeagueBracket({
    required List<Player> allPlayers,
    required String playerTeamId,
    required int seasonNumber,
    IndividualLeagueBracket? previousSeasonBracket,
  }) {
    // 이전 시즌 정보 추출
    final prevTop8 = previousSeasonBracket?.top8Players ?? [];
    final prevMainTournamentPlayers = previousSeasonBracket?.mainTournamentPlayers ?? [];

    // 이전 시즌 32강 진출자 중 8강 진출자 제외 = 듀얼토너먼트 시드
    final prevDualSeeds = prevMainTournamentPlayers
        .where((id) => !prevTop8.contains(id))
        .toList();

    // 현재 활동 중인 선수만 필터링 (은퇴/이적 고려)
    final activePlayerIds = allPlayers.map((p) => p.id).toSet();
    final activeTop8 = prevTop8.where((id) => activePlayerIds.contains(id)).toList();
    final activeDualSeeds = prevDualSeeds.where((id) => activePlayerIds.contains(id)).toList();

    // 조지명식 직행 선수 (8명)
    final mainTournamentSeeds = <String>[];
    mainTournamentSeeds.addAll(activeTop8);

    // 8명 미만이면 등급순으로 채우기
    if (mainTournamentSeeds.length < 8) {
      final alreadySeeded = mainTournamentSeeds.toSet();
      final remainingPlayers = allPlayers
          .where((p) => !alreadySeeded.contains(p.id))
          .toList()
        ..sort((a, b) {
          final gradeCompare = b.grade.index - a.grade.index;
          if (gradeCompare != 0) return gradeCompare;
          return b.totalStats - a.totalStats;
        });

      for (final player in remainingPlayers) {
        if (mainTournamentSeeds.length >= 8) break;
        mainTournamentSeeds.add(player.id);
      }
    }

    // 듀얼토너먼트 시드 선수 (24명 = 12개 조 × 2명)
    // 이전 시즌 32강 진출자 + 부족하면 등급순으로 채우기
    final dualTournamentSeeds = <String>[];
    dualTournamentSeeds.addAll(activeDualSeeds);

    // 듀얼 토너먼트 시드 24명 필요 (12개 조 × 2명)
    if (dualTournamentSeeds.length < 24) {
      final alreadySeeded = {...mainTournamentSeeds, ...dualTournamentSeeds};
      final remainingPlayers = allPlayers
          .where((p) => !alreadySeeded.contains(p.id))
          .toList()
        ..sort((a, b) {
          final gradeCompare = b.grade.index - a.grade.index;
          if (gradeCompare != 0) return gradeCompare;
          return b.totalStats - a.totalStats;
        });

      for (final player in remainingPlayers) {
        if (dualTournamentSeeds.length >= 24) break;
        dualTournamentSeeds.add(player.id);
      }
    }

    // 듀얼 토너먼트 12개 조 편성 (각 조 2명 시드 + 2명 빈 슬롯)
    // #1: A~D조 (0~3), #2: E~H조 (4~7), #3: I~L조 (8~11)
    final dualTournamentGroups = <List<String?>>[];
    for (var i = 0; i < 12; i++) {
      final seed1Index = i * 2;
      final seed2Index = i * 2 + 1;
      dualTournamentGroups.add([
        seed1Index < dualTournamentSeeds.length ? dualTournamentSeeds[seed1Index] : null,
        seed2Index < dualTournamentSeeds.length ? dualTournamentSeeds[seed2Index] : null,
        null, // PC방 예선 승자 (나중에 채움)
        null, // PC방 예선 승자 (나중에 채움)
      ]);
    }

    // 본선 8개 조 편성 (각 조 1명 시드 + 3명 빈 슬롯)
    final mainTournamentGroups = <List<String?>>[];
    for (var i = 0; i < 8; i++) {
      mainTournamentGroups.add([
        i < mainTournamentSeeds.length ? mainTournamentSeeds[i] : null,
        null, // 듀얼 토너먼트 통과자 (나중에 채움)
        null,
        null,
      ]);
    }

    // PC방 예선 참가자 (나머지)
    final seededPlayerIds = {...mainTournamentSeeds, ...dualTournamentSeeds};
    final pcBangPlayers = allPlayers
        .where((p) => !seededPlayerIds.contains(p.id))
        .toList()
      ..sort((a, b) {
        final gradeCompare = b.grade.index - a.grade.index;
        if (gradeCompare != 0) return gradeCompare;
        return b.totalStats - a.totalStats;
      });

    // PC방 예선 조 편성 (8명 조 + 6명 조 혼합)
    // 총 선수 수에 따라 조 구성 결정
    final totalPcBangPlayers = pcBangPlayers.length;
    final groupConfig = _calculateGroupConfig(totalPcBangPlayers);
    final groups8Count = groupConfig.$1; // 8명 조 개수
    final groups6Count = groupConfig.$2; // 6명 조 개수
    final totalGroups = groups8Count + groups6Count;

    // 우리팀 선수 우선 배정
    final myTeamPcBangPlayers = pcBangPlayers
        .where((p) => p.teamId == playerTeamId)
        .toList();
    final otherPcBangPlayers = pcBangPlayers
        .where((p) => p.teamId != playerTeamId)
        .toList();

    // 조 초기화 (8명 조가 앞에, 6명 조가 뒤에)
    final groups = List.generate(totalGroups, (_) => <String>[]);

    // 우리팀 선수 배정 (상위 등급일수록 낮은 조 번호)
    for (var i = 0; i < myTeamPcBangPlayers.length && i < totalGroups; i++) {
      groups[i].add(myTeamPcBangPlayers[i].id);
    }

    // 남은 선수들 섞어서 배정
    otherPcBangPlayers.shuffle(_random);
    var playerIndex = 0;
    for (var groupIndex = 0; groupIndex < totalGroups; groupIndex++) {
      // 해당 조의 최대 인원 결정 (앞 groups8Count개는 8명, 나머지는 6명)
      final maxPlayers = groupIndex < groups8Count ? 8 : 6;
      while (groups[groupIndex].length < maxPlayers && playerIndex < otherPcBangPlayers.length) {
        groups[groupIndex].add(otherPcBangPlayers[playerIndex].id);
        playerIndex++;
      }
    }

    return IndividualLeagueBracket(
      seasonNumber: seasonNumber,
      pcBangGroups: groups,
      mainTournamentSeeds: mainTournamentSeeds, // 조지명식 직행 8명 (이전 시즌 8강)
      dualTournamentSeeds: dualTournamentSeeds, // 듀얼토너먼트 시드 24명 (12개 조 × 2명)
      dualTournamentGroups: dualTournamentGroups, // 듀얼토너먼트 12개 조 편성
      mainTournamentGroups: mainTournamentGroups, // 본선 8개 조 편성
    );
  }

  /// 하위 호환성을 위한 기존 메서드 (deprecated)
  @Deprecated('Use createIndividualLeagueBracket instead')
  IndividualLeagueBracket createPcBangGroups({
    required List<Player> allPlayers,
    required String playerTeamId,
    required int seasonNumber,
  }) {
    return createIndividualLeagueBracket(
      allPlayers: allPlayers,
      playerTeamId: playerTeamId,
      seasonNumber: seasonNumber,
      previousSeasonBracket: null,
    );
  }

  /// PC방 예선 한 조 시뮬레이션 (단판 토너먼트)
  /// 4명, 6명, 8명 조 모두 지원
  PcBangGroupResult simulatePcBangGroup({
    required int groupIndex,
    required List<String> playerIds,
    required Map<String, Player> playerMap,
  }) {
    final playerCount = playerIds.length;
    if (playerCount < 4 || playerCount > 8) {
      throw ArgumentError('Group must have 4-8 players, got $playerCount');
    }

    final maps = GameMaps.all;

    if (playerCount == 4) {
      // 4명: 4강 → 결승 (3경기)
      return _simulate4PlayerGroup(groupIndex, playerIds, playerMap, maps);
    } else if (playerCount == 6) {
      // 6명: 1라운드(4명) → 4강(4명) → 결승 (5경기)
      return _simulate6PlayerGroup(groupIndex, playerIds, playerMap, maps);
    } else {
      // 8명: 8강 → 4강 → 결승 (7경기)
      return _simulate8PlayerGroup(groupIndex, playerIds, playerMap, maps);
    }
  }

  /// 4명 조 시뮬레이션: 4강 → 결승
  PcBangGroupResult _simulate4PlayerGroup(
    int groupIndex,
    List<String> playerIds,
    Map<String, Player> playerMap,
    List<GameMap> maps,
  ) {
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
      runnerUpId: final_.loserId,
    );
  }

  /// 6명 조 시뮬레이션: 1라운드(하위 4명) → 4강(상위 2명 + 1라운드 승자 2명) → 결승
  PcBangGroupResult _simulate6PlayerGroup(
    int groupIndex,
    List<String> playerIds,
    Map<String, Player> playerMap,
    List<GameMap> maps,
  ) {
    final results = <IndividualMatchResult>[];

    // 시드 배정: 0,1번이 상위 시드 (4강 직행), 2-5번이 하위 시드 (1라운드)
    // 1라운드: 2 vs 3, 4 vs 5
    final round1Match1 = _simulateIndividualMatch(
      player1Id: playerIds[2],
      player2Id: playerIds[3],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(round1Match1);

    final round1Match2 = _simulateIndividualMatch(
      player1Id: playerIds[4],
      player2Id: playerIds[5],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(round1Match2);

    // 4강: 0 vs round1Match2 승자, 1 vs round1Match1 승자
    final semiFinal1 = _simulateIndividualMatch(
      player1Id: playerIds[0],
      player2Id: round1Match2.winnerId,
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal1);

    final semiFinal2 = _simulateIndividualMatch(
      player1Id: playerIds[1],
      player2Id: round1Match1.winnerId,
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal2);

    // 결승
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
      runnerUpId: final_.loserId,
    );
  }

  /// 8명 조 시뮬레이션: 8강 → 4강 → 결승
  PcBangGroupResult _simulate8PlayerGroup(
    int groupIndex,
    List<String> playerIds,
    Map<String, Player> playerMap,
    List<GameMap> maps,
  ) {
    final results = <IndividualMatchResult>[];

    // 8강: 0vs7, 1vs6, 2vs5, 3vs4 (시드 배정)
    final quarterFinal1 = _simulateIndividualMatch(
      player1Id: playerIds[0],
      player2Id: playerIds[7],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(quarterFinal1);

    final quarterFinal2 = _simulateIndividualMatch(
      player1Id: playerIds[1],
      player2Id: playerIds[6],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(quarterFinal2);

    final quarterFinal3 = _simulateIndividualMatch(
      player1Id: playerIds[2],
      player2Id: playerIds[5],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(quarterFinal3);

    final quarterFinal4 = _simulateIndividualMatch(
      player1Id: playerIds[3],
      player2Id: playerIds[4],
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(quarterFinal4);

    // 4강: QF1승자 vs QF4승자, QF2승자 vs QF3승자
    final semiFinal1 = _simulateIndividualMatch(
      player1Id: quarterFinal1.winnerId,
      player2Id: quarterFinal4.winnerId,
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal1);

    final semiFinal2 = _simulateIndividualMatch(
      player1Id: quarterFinal2.winnerId,
      player2Id: quarterFinal3.winnerId,
      playerMap: playerMap,
      map: maps[_random.nextInt(maps.length)],
      stage: IndividualLeagueStage.pcBangQualifier,
    );
    results.add(semiFinal2);

    // 결승
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
      runnerUpId: final_.loserId,
    );
  }

  /// 모든 PC방 예선 시뮬레이션
  /// 듀얼토너먼트 진출자 = PC방 예선 우승자(24명) + 이전시즌 32강 시드
  IndividualLeagueBracket simulateAllPcBangGroups({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
  }) {
    final allResults = <IndividualMatchResult>[];
    final dualTournamentWinners = <String>[];

    for (var i = 0; i < bracket.pcBangGroups.length; i++) {
      final result = simulatePcBangGroup(
        groupIndex: i,
        playerIds: bracket.pcBangGroups[i],
        playerMap: playerMap,
      );
      allResults.addAll(result.matches);
      dualTournamentWinners.add(result.winnerId);
    }

    // 듀얼토너먼트 시드 배정:
    // 1시드 위치 = 이전 시즌 32강 진출자 (bracket.dualTournamentSeeds)
    // 3시드 위치 = PC방 예선 우승자
    final seededPlayers = _assignDualTournamentSeedsWithPrevSeason(
      pcBangWinners: dualTournamentWinners,
      prevSeasonSeeds: bracket.dualTournamentSeeds,
      playerMap: playerMap,
    );

    return bracket.copyWith(
      pcBangResults: allResults,
      dualTournamentPlayers: seededPlayers,
    );
  }

  /// PC방 예선 조 구성 계산 (8명 조 개수, 6명 조 개수)
  /// 총 인원을 8명 조와 6명 조로 나눔
  (int, int) _calculateGroupConfig(int totalPlayers) {
    // 8x + 6y = totalPlayers 를 만족하는 (x, y) 찾기
    // 8명 조를 최대한 많이 사용하되, 나머지는 6명 조로 채움

    // 예시:
    // 112명 = 8*8 + 6*8 = 64 + 48 (8명 조 8개, 6명 조 8개)
    // 112명 = 8*14 + 6*0 = 112 (8명 조 14개)
    // 96명 = 8*12 + 6*0 = 96 (8명 조 12개)
    // 100명 = 8*8 + 6*6 = 64 + 36 (8명 조 8개, 6명 조 6개)

    // 8명 조 위주로 배정, 나머지를 6명 조로
    for (var groups8 = totalPlayers ~/ 8; groups8 >= 0; groups8--) {
      final remaining = totalPlayers - (groups8 * 8);
      if (remaining >= 0 && remaining % 6 == 0) {
        final groups6 = remaining ~/ 6;
        return (groups8, groups6);
      }
    }

    // 6명 조로만 구성 가능한지 체크
    if (totalPlayers % 6 == 0) {
      return (0, totalPlayers ~/ 6);
    }

    // 완벽하게 나눠지지 않으면 최대한 8명 조로 채우고 나머지는 6명 조로
    // (일부 조가 6명 미만일 수 있음 - 실제 상황에선 잘 안 일어남)
    final groups8 = totalPlayers ~/ 8;
    final remaining = totalPlayers - (groups8 * 8);
    final groups6 = remaining > 0 ? 1 : 0; // 남은 인원으로 1개 조 구성
    return (groups8, groups6);
  }

  /// 선수들을 등급순으로 정렬
  List<String> _sortPlayersByGrade(List<String> playerIds, Map<String, Player> playerMap) {
    final players = playerIds.map((id) => playerMap[id]!).toList();
    players.sort((a, b) {
      final gradeCompare = b.grade.index - a.grade.index;
      if (gradeCompare != 0) return gradeCompare;
      return b.totalStats - a.totalStats;
    });
    return players.map((p) => p.id).toList();
  }

  /// 듀얼토너먼트 시드 배정 (이전 시즌 결과 반영)
  /// 1시드 위치 = 이전 시즌 32강 진출자
  /// 3시드 위치 = PC방 예선 우승자
  List<String> _assignDualTournamentSeedsWithPrevSeason({
    required List<String> pcBangWinners,
    required List<String> prevSeasonSeeds,
    required Map<String, Player> playerMap,
  }) {
    // 이전 시즌 32강 진출자가 있으면 1시드로 배정
    // 없으면 등급순으로 배정

    final activeSeeds = prevSeasonSeeds
        .where((id) => playerMap.containsKey(id))
        .toList();

    // PC방 예선 우승자 중 이미 시드인 선수 제외
    final seedSet = activeSeeds.toSet();
    final newQualifiers = pcBangWinners
        .where((id) => !seedSet.contains(id))
        .toList();

    // 총 24명 필요 (12경기)
    final totalPlayers = <String>[];
    totalPlayers.addAll(activeSeeds);
    totalPlayers.addAll(newQualifiers);

    // 24명으로 맞추기
    if (totalPlayers.length < 24) {
      // 부족하면 PC방 예선 우승자로 채우기
      for (final id in pcBangWinners) {
        if (totalPlayers.length >= 24) break;
        if (!totalPlayers.contains(id)) {
          totalPlayers.add(id);
        }
      }
    }

    // 24명을 등급순으로 정렬
    final sortedPlayers = _sortPlayersByGrade(totalPlayers.take(24).toList(), playerMap);

    // 1시드 위치 = 상위 12명 (이전 시즌 시드 + 고등급)
    // 3시드 위치 = 하위 12명
    final result = List<String>.filled(24, '');
    final topSeeds = sortedPlayers.take(12).toList();
    final bottomSeeds = sortedPlayers.skip(12).toList();

    // 하위 시드만 섞기
    bottomSeeds.shuffle(_random);

    for (var i = 0; i < 12; i++) {
      result[i * 2] = topSeeds[i]; // 1시드 위치
      if (i < bottomSeeds.length) {
        result[i * 2 + 1] = bottomSeeds[i]; // 3시드 위치
      }
    }

    return result;
  }

  /// 듀얼토너먼트 시뮬레이션
  /// 24명 → 승자조/패자조 → 8명 진출
  /// 각 라운드에서 1, 3시드 위치에 등급 상위 선수 유지
  IndividualLeagueBracket simulateDualTournament({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
  }) {
    final players = List<String>.from(bracket.dualTournamentPlayers);
    final maps = GameMaps.all;
    final results = <IndividualMatchResult>[];

    // 승자조 (Winners Bracket)
    // Round 1: 24명 → 12승자, 12패자
    // 시드 배정: 짝수 인덱스(0,2,4...)가 1시드, 홀수(1,3,5...)가 2시드
    final winnersR1Winners = <String>[];
    final winnersR1Losers = <String>[];

    for (var i = 0; i < 12; i++) {
      final match = _simulateIndividualMatch(
        player1Id: players[i * 2],     // 1시드 (등급 상위)
        player2Id: players[i * 2 + 1], // 2시드
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      winnersR1Winners.add(match.winnerId);
      winnersR1Losers.add(match.loserId);
    }

    // 승자조 Round 2: 12명 → 6승자, 6패자
    // 시드 재배정: 승자들을 등급순으로 정렬하여 1시드 위치에 배치
    final seededWinnersR1 = _reorderBySeeds(winnersR1Winners, playerMap);
    final winnersR2Winners = <String>[];
    final winnersR2Losers = <String>[];

    for (var i = 0; i < 6; i++) {
      final match = _simulateIndividualMatch(
        player1Id: seededWinnersR1[i * 2],     // 1시드
        player2Id: seededWinnersR1[i * 2 + 1], // 3시드
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      winnersR2Winners.add(match.winnerId);
      winnersR2Losers.add(match.loserId);
    }

    // 패자조 Round 1: 12명 → 6명 탈락
    // 시드 재배정
    final seededLosersR1 = _reorderBySeeds(winnersR1Losers, playerMap);
    final losersR1Winners = <String>[];

    for (var i = 0; i < 6; i++) {
      final match = _simulateIndividualMatch(
        player1Id: seededLosersR1[i * 2],
        player2Id: seededLosersR1[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR1Winners.add(match.winnerId);
    }

    // 패자조 Round 2: 6명(패자조R1승자) vs 6명(승자조R2패자) → 6명 탈락
    // 패자조 승자가 시드 유리 (승자조에서 떨어진 선수보다 유리)
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
    final seededLosersR2 = _reorderBySeeds(losersR2Winners, playerMap);
    final losersR3Winners = <String>[];

    for (var i = 0; i < 3; i++) {
      final match = _simulateIndividualMatch(
        player1Id: seededLosersR2[i * 2],
        player2Id: seededLosersR2[i * 2 + 1],
        playerMap: playerMap,
        map: maps[_random.nextInt(maps.length)],
        stage: IndividualLeagueStage.dualTournament,
      );
      results.add(match);
      losersR3Winners.add(match.winnerId);
    }

    // 승자조 Round 3: 6명 → 3승자, 3패자
    final seededWinnersR2 = _reorderBySeeds(winnersR2Winners, playerMap);
    final winnersR3Winners = <String>[];
    final winnersR3Losers = <String>[];

    for (var i = 0; i < 3; i++) {
      final match = _simulateIndividualMatch(
        player1Id: seededWinnersR2[i * 2],
        player2Id: seededWinnersR2[i * 2 + 1],
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

    // 최종 진출자: 승자조 3명 + 패자조 최종 3명 = 6명
    // + 추가 2명 (와일드카드)
    final advancingPlayers = <String>[
      ...winnersR3Winners,
      ...losersR4Winners,
    ];

    // 부족분 채우기 (8명까지) - 탈락자 중 등급 높은 순
    if (advancingPlayers.length < 8) {
      final allParticipants = players.toSet();
      final eliminated = allParticipants.difference(advancingPlayers.toSet()).toList();
      final sortedEliminated = _sortPlayersByGrade(eliminated, playerMap);

      for (final playerId in sortedEliminated) {
        if (advancingPlayers.length >= 8) break;
        advancingPlayers.add(playerId);
      }
    }

    // 본선 진출자 = 조지명식 직행 시드 + 듀얼토너먼트 통과자
    final mainTournamentSeededPlayers = bracket.mainTournamentSeeds;
    final dualAdvancing = advancingPlayers.take(8).toList();

    // 조지명식 직행 선수 + 듀얼토너먼트 통과자 합치기
    final allMainTournamentPlayers = <String>[
      ...mainTournamentSeededPlayers,
      ...dualAdvancing.where((id) => !mainTournamentSeededPlayers.contains(id)),
    ];

    // 등급순으로 정렬
    final sortedMainPlayers = _sortPlayersByGrade(
      allMainTournamentPlayers.take(8).toList(),
      playerMap,
    );

    return bracket.copyWith(
      dualTournamentResults: results,
      mainTournamentPlayers: sortedMainPlayers,
    );
  }

  /// 선수들을 등급순으로 재정렬하여 시드 배정
  /// 홀수 인덱스(1시드)에 상위 절반, 짝수 인덱스(3시드)에 하위 절반
  List<String> _reorderBySeeds(List<String> playerIds, Map<String, Player> playerMap) {
    final sorted = _sortPlayersByGrade(playerIds, playerMap);
    final halfSize = sorted.length ~/ 2;
    final topHalf = sorted.take(halfSize).toList();
    final bottomHalf = sorted.skip(halfSize).toList();

    // 셔플 적용 (하위 절반만)
    bottomHalf.shuffle(_random);

    final result = <String>[];
    for (var i = 0; i < halfSize; i++) {
      result.add(topHalf[i]);      // 1시드 위치
      if (i < bottomHalf.length) {
        result.add(bottomHalf[i]); // 3시드 위치
      }
    }

    return result;
  }

  /// 본선 (32강~결승) 시뮬레이션
  /// 실제로는 8명이 진출하지만, 명칭상 32강부터 시작
  /// 8강 진출자(top8Players)를 기록하여 다음 시즌 조지명식 직행 시드로 사용
  IndividualLeagueBracket simulateMainTournament({
    required IndividualLeagueBracket bracket,
    required Map<String, Player> playerMap,
    bool showLogFromQuarterFinal = true,
  }) {
    var players = List<String>.from(bracket.mainTournamentPlayers);
    final maps = GameMaps.all;
    final results = <IndividualMatchResult>[];

    // 8강 진출자 기록 (= 조지명식 참가자 = 다음 시즌 직행 시드)
    final top8Players = List<String>.from(players.take(8));

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

      // 8강 진출자를 순위대로 정렬 (1등=우승자, 2등=준우승자, 3-4등=4강, 5-8등=8강)
      final rankedTop8 = _rankTop8Players(
        top8Players: top8Players,
        quarterFinalWinners: quarterFinalWinners,
        semiFinalWinners: semiFinalWinners,
        championId: finalMatch.winnerId,
        runnerUpId: finalMatch.loserId,
      );

      return bracket.copyWith(
        mainTournamentResults: results,
        championId: finalMatch.winnerId,
        runnerUpId: finalMatch.loserId,
        top8Players: rankedTop8,
      );
    }

    return bracket.copyWith(
      mainTournamentResults: results,
      top8Players: top8Players,
    );
  }

  /// 8강 진출자를 순위대로 정렬
  /// 1등=우승자, 2등=준우승자, 3-4등=4강탈락, 5-8등=8강탈락
  List<String> _rankTop8Players({
    required List<String> top8Players,
    required List<String> quarterFinalWinners,
    required List<String> semiFinalWinners,
    required String championId,
    required String runnerUpId,
  }) {
    final ranked = <String>[];

    // 1등: 우승자
    ranked.add(championId);

    // 2등: 준우승자
    ranked.add(runnerUpId);

    // 3-4등: 4강 탈락자 (4강 진출했지만 결승 못 간 선수)
    for (final id in quarterFinalWinners) {
      if (!semiFinalWinners.contains(id) && !ranked.contains(id)) {
        // 이 선수는 4강에서 탈락 (4강 진출 = quarterFinalWinners, 결승 진출 = semiFinalWinners)
      }
    }
    // 실제로 4강 탈락자 = semiFinalWinners에 없는 quarterFinalWinners
    for (final id in quarterFinalWinners) {
      if (!ranked.contains(id)) {
        ranked.add(id);
      }
    }

    // 5-8등: 8강 탈락자
    for (final id in top8Players) {
      if (!ranked.contains(id)) {
        ranked.add(id);
      }
    }

    return ranked;
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
    if (groupIndex >= bracket.pcBangGroups.length) return null;

    // 해당 조의 인원 수로 경기 수 계산
    final groupSize = bracket.pcBangGroups[groupIndex].length;
    final matchCount = _getMatchCountForGroupSize(groupSize);

    // 이전 조들의 경기 수 합산하여 시작 인덱스 계산
    var startIndex = 0;
    for (var i = 0; i < groupIndex; i++) {
      startIndex += _getMatchCountForGroupSize(bracket.pcBangGroups[i].length);
    }

    if (startIndex + matchCount > bracket.pcBangResults.length) return null;

    final groupMatches = bracket.pcBangResults.sublist(startIndex, startIndex + matchCount);
    if (groupMatches.isEmpty) return null;

    // 마지막 경기가 결승전
    final finalMatch = groupMatches.last;

    return PcBangGroupResult(
      groupIndex: groupIndex,
      matches: groupMatches,
      winnerId: finalMatch.winnerId,
      runnerUpId: finalMatch.loserId,
    );
  }

  /// 조 인원에 따른 경기 수 반환
  int _getMatchCountForGroupSize(int groupSize) {
    switch (groupSize) {
      case 4:
        return 3; // 4강 2 + 결승 1
      case 6:
        return 5; // 1라운드 2 + 4강 2 + 결승 1
      case 8:
        return 7; // 8강 4 + 4강 2 + 결승 1
      default:
        return 3;
    }
  }
}

/// PC방 예선 조별 결과
class PcBangGroupResult {
  final int groupIndex;
  final List<IndividualMatchResult> matches;
  final String winnerId;
  final String runnerUpId; // 준우승자

  const PcBangGroupResult({
    required this.groupIndex,
    required this.matches,
    required this.winnerId,
    required this.runnerUpId,
  });

  int get groupSize {
    // 경기 수로 조 인원 추정: 4명=3경기, 6명=5경기, 8명=7경기
    switch (matches.length) {
      case 3:
        return 4;
      case 5:
        return 6;
      case 7:
        return 8;
      default:
        return 4;
    }
  }
}
