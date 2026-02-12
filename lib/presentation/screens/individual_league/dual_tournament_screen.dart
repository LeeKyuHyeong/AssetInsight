import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/player_thumbnail.dart';
import '../../widgets/reset_button.dart';

/// 듀얼토너먼트 화면 - 12개 조 (3개 라운드 × 4개 조)
class DualTournamentScreen extends ConsumerStatefulWidget {
  final int round; // 1, 2, 3 (어떤 듀얼 토너먼트인지)
  final bool viewOnly;

  const DualTournamentScreen({super.key, this.round = 1, this.viewOnly = false});

  @override
  ConsumerState<DualTournamentScreen> createState() =>
      _DualTournamentScreenState();
}

class _DualTournamentScreenState extends ConsumerState<DualTournamentScreen> {
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  bool _isSimulating = false;
  bool _isCompleted = false;
  String _currentMatchInfo = '';
  int _currentStep = 0; // 0=미시작, 1=1경기, 2=2경기, 3=승자전, 4=패자전, 5=최종전
  Set<String> _myTeamPlayerIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAlreadySimulated();
    });
  }

  void _checkIfAlreadySimulated() {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;
    final bracket = gameState.saveData.currentSeason.individualLeague;
    if (bracket == null) return;
    if (bracket.dualTournamentResults.length >= _endGroupIndex * 5) {
      setState(() {
        _isCompleted = true;
        _currentStep = 5;
      });
    }
  }

  // 조 이름 (A~L)
  static const groupNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

  // 현재 라운드의 조 인덱스 범위
  int get _startGroupIndex => (widget.round - 1) * 4;
  int get _endGroupIndex => widget.round * 4;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};
    final playerTeam = gameState.playerTeam;
    _myTeamPlayerIds = gameState.saveData.getTeamPlayers(playerTeam.id).map((p) => p.id).toSet();

    // 아마추어 선수 추가 (듀얼토너먼트에 진출한 경우)
    if (bracket != null) {
      final amateurIds = <String>{};
      // dualTournamentPlayers에서 아마추어 수집
      amateurIds.addAll(
        bracket.dualTournamentPlayers.where((id) => id.startsWith('amateur_')),
      );
      // dualTournamentGroups에서도 아마추어 수집
      for (final group in bracket.dualTournamentGroups) {
        for (final playerId in group) {
          if (playerId != null && playerId.startsWith('amateur_')) {
            amateurIds.add(playerId);
          }
        }
      }
      for (final playerId in amateurIds) {
        if (!playerMap.containsKey(playerId)) {
          playerMap[playerId] = Player(
            id: playerId,
            name: '아마추어',
            raceIndex: Race.values[playerId.hashCode % 3].index,
            stats: const PlayerStats(
              sense: 100, control: 100, attack: 100, harass: 100,
              strategy: 100, macro: 100, defense: 100, scout: 100,
            ),
            levelValue: 1,
          );
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.sp),
                    child: Column(
                      children: [
                        // 상단 정보 패널
                        _buildTopInfoPanel(bracket, playerMap),
                        SizedBox(height: 8.sp),
                        // 4개 조 그리드 (2x2)
                        Expanded(
                          child: Column(
                            children: [
                              // 상단 2개 조 (A/E/I, B/F/J)
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex, // A/E/I 조
                                      ),
                                    ),
                                    SizedBox(width: 8.sp),
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 1, // B/F/J 조
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.sp),
                              // 하단 2개 조 (C/G/K, D/H/L)
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 2, // C/G/K 조
                                      ),
                                    ),
                                    SizedBox(width: 8.sp),
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 3, // D/H/L 조
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(context, bracket, playerMap),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          ResetButton.back(),
          const Spacer(),
          Text(
            '듀얼 토너먼트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          const ResetButton(small: true),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupName = groupIndex < groupNames.length ? groupNames[groupIndex] : '?';

    // 조 데이터 가져오기
    List<String?> groupPlayers = [];
    if (bracket != null &&
        bracket.dualTournamentGroups.isNotEmpty &&
        groupIndex < bracket.dualTournamentGroups.length) {
      groupPlayers = bracket.dualTournamentGroups[groupIndex];
    }

    // 4명 슬롯 보장
    while (groupPlayers.length < 4) {
      groupPlayers = [...groupPlayers, null];
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(6.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조 이름 + 썸네일
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Text(
                  '$groupName조',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 4.sp),
              ...groupPlayers.where((id) => id != null).take(4).map((id) {
                final p = playerMap[id];
                if (p == null) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(right: 2.sp),
                  child: PlayerThumbnail(
                    player: p,
                    size: 14,
                    isMyTeam: _myTeamPlayerIds.contains(p.id),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 4.sp),
          // 대진표
          Expanded(
            child: _buildGroupBracket(groupPlayers, playerMap, groupIndex, bracket),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBracket(
    List<String?> groupPlayers,
    Map<String, Player> playerMap,
    int groupIndex,
    IndividualLeagueBracket? bracket,
  ) {
    // 듀얼 토너먼트 대진표
    // 1경기: 0 vs 2 (1시드 vs PC방 승자)
    // 2경기: 1 vs 3 (3시드 vs PC방 승자)
    // 승자전: 1경기 승자 vs 2경기 승자
    // 패자전: 1경기 패자 vs 2경기 패자
    // 최종전: 승자전 패자 vs 패자전 승자

    final player0 = groupPlayers.length > 0 && groupPlayers[0] != null
        ? playerMap[groupPlayers[0]] : null;
    final player1 = groupPlayers.length > 1 && groupPlayers[1] != null
        ? playerMap[groupPlayers[1]] : null;
    final player2 = groupPlayers.length > 2 && groupPlayers[2] != null
        ? playerMap[groupPlayers[2]] : null;
    final player3 = groupPlayers.length > 3 && groupPlayers[3] != null
        ? playerMap[groupPlayers[3]] : null;

    // _currentStep 기반 단계별 결과 + 선수 세팅
    String? match1WinnerId;
    String? match2WinnerId;
    Player? winnersP1, winnersP2;
    String? winnersWinnerId;
    Player? losersP1, losersP2;
    String? losersLoserId;
    Player? finalP1, finalP2;
    String? finalWinnerId;
    String? finalLoserId;

    if (bracket != null) {
      final groupStart = groupIndex * 5;
      final availableResults = bracket.dualTournamentResults.length;

      // Step 1: 1경기 결과 → 승자전 왼쪽 + 패자전 왼쪽 세팅
      if (_currentStep >= 1 && availableResults >= groupStart + 1) {
        final match1 = bracket.dualTournamentResults[groupStart];
        match1WinnerId = match1.winnerId;
        winnersP1 = playerMap[match1.winnerId];
        losersP1 = playerMap[match1.loserId];
      }

      // Step 2: 2경기 결과 → 승자전 오른쪽 + 패자전 오른쪽 세팅
      if (_currentStep >= 2 && availableResults >= groupStart + 2) {
        final match2 = bracket.dualTournamentResults[groupStart + 1];
        match2WinnerId = match2.winnerId;
        winnersP2 = playerMap[match2.winnerId];
        losersP2 = playerMap[match2.loserId];
      }

      // Step 3: 승자전 결과 → 최종전 왼쪽(패자) 세팅
      if (_currentStep >= 3 && availableResults >= groupStart + 3) {
        final winnersMatch = bracket.dualTournamentResults[groupStart + 2];
        winnersWinnerId = winnersMatch.winnerId;
        finalP1 = playerMap[winnersMatch.loserId];
      }

      // Step 4: 패자전 결과 → 최종전 오른쪽(승자) 세팅
      if (_currentStep >= 4 && availableResults >= groupStart + 4) {
        final losersMatch = bracket.dualTournamentResults[groupStart + 3];
        losersLoserId = losersMatch.loserId;
        finalP2 = playerMap[losersMatch.winnerId];
      }

      // Step 5: 최종전 결과
      if (_currentStep >= 5 && availableResults >= groupStart + 5) {
        final finalMatch = bracket.dualTournamentResults[groupStart + 4];
        finalWinnerId = finalMatch.winnerId;
        finalLoserId = finalMatch.loserId;
      }
    }

    return Column(
      children: [
        // 1경기: 1시드 vs PC방 승자
        Expanded(
          child: _buildMatchRow('< 1경기 >', player0, player2, winnerId: match1WinnerId),
        ),
        // 2경기: 3시드 vs PC방 승자
        Expanded(
          child: _buildMatchRow('< 2경기 >', player1, player3, winnerId: match2WinnerId),
        ),
        // 승자전 (승자 = 진출 확정, 초록)
        Expanded(
          child: _buildMatchRow('< 승자전 >', winnersP1, winnersP2, advanceId: winnersWinnerId),
        ),
        // 패자전 (패자 = 탈락 확정, 회색)
        Expanded(
          child: _buildMatchRow('< 패자전 >', losersP1, losersP2, eliminateId: losersLoserId),
        ),
        // 최종전 (승자 = 진출, 패자 = 탈락)
        Expanded(
          child: _buildMatchRow('< 최종전 >', finalP1, finalP2, advanceId: finalWinnerId, eliminateId: finalLoserId),
        ),
      ],
    );
  }

  Widget _buildMatchRow(String title, Player? player1, Player? player2, {
    String placeholder = '???',
    String? winnerId,
    String? advanceId,
    String? eliminateId,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 2.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildPlayerName(
                player1, placeholder,
                isWinner: winnerId != null && player1?.id == winnerId,
                isAdvanced: advanceId != null && player1?.id == advanceId,
                isEliminated: eliminateId != null && player1?.id == eliminateId,
              ),
            ),
            Text(
              ' vs ',
              style: TextStyle(color: Colors.grey, fontSize: 8.sp),
            ),
            Expanded(
              child: _buildPlayerName(
                player2, placeholder,
                isWinner: winnerId != null && player2?.id == winnerId,
                isAdvanced: advanceId != null && player2?.id == advanceId,
                isEliminated: eliminateId != null && player2?.id == eliminateId,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerName(Player? player, String placeholder, {
    bool isWinner = false,
    bool isAdvanced = false,
    bool isEliminated = false,
  }) {
    if (player == null) {
      return Text(
        placeholder,
        style: TextStyle(color: Colors.grey, fontSize: 10.sp),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 색상 우선순위: 진출(초록) > 탈락(회색) > 승리(accent) > 기본(흰)
    final Color textColor;
    if (isAdvanced) {
      textColor = Colors.greenAccent;
    } else if (isEliminated) {
      textColor = Colors.grey;
    } else if (isWinner) {
      textColor = AppColors.accent;
    } else {
      textColor = Colors.white;
    }

    // "(종족) 이름" 형식으로 표시
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '(${player.race.code})',
          style: TextStyle(
            color: isEliminated ? Colors.grey : _getRaceColor(player.race),
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 2.sp),
        Flexible(
          child: Text(
            player.name,
            style: TextStyle(
              color: textColor,
              fontSize: 10.sp,
              fontWeight: (isAdvanced || isWinner) ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTopInfoPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
      child: Row(
        children: [
          // 라운드 표시
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              '#${widget.round}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.sp),
          // 상태 메시지
          Expanded(
            child: _isSimulating
                ? Row(
                    children: [
                      SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: const CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Text(
                        '경기 진행중${_currentMatchInfo.isNotEmpty ? ' - $_currentMatchInfo' : ''}',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ],
                  )
                : _isCompleted
                    ? Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.accent, size: 20.sp),
                          SizedBox(width: 8.sp),
                          Text(
                            '완료!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '미진행',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
          ),
          // 맵 정보
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '맵',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 9.sp,
                ),
              ),
              SizedBox(height: 2.sp),
              Text(
                '네오아웃라이어',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '네오제이드',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '네오체인리액션',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final bool canStart = !widget.viewOnly && !_isSimulating;

    return Container(
      padding: EdgeInsets.all(12.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canStart)
            ElevatedButton(
              onPressed: _isCompleted
                  ? () => _goToNextStage(context)
                  : () => _startSimulation(bracket, playerMap),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
              ),
              child: Row(
                children: [
                  Text(
                    _isCompleted ? 'Next' : 'Start',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.sp),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static const _stepNames = ['', '1경기', '2경기', '승자전', '패자전', '최종전'];

  Future<void> _startSimulation(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) async {
    if (bracket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대진표 데이터가 없습니다')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _currentStep = 0;
    });

    // 먼저 전체 시뮬레이션 실행 (결과 저장)
    final updatedBracket = _leagueService.simulateDualTournamentRound(
      bracket: bracket,
      playerMap: playerMap,
      round: widget.round,
    );
    ref.read(gameStateProvider.notifier).updateIndividualLeague(updatedBracket);
    ref.read(gameStateProvider.notifier).save();

    // 1초마다 단계별로 결과 공개
    for (var step = 1; step <= 5; step++) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      setState(() {
        _currentStep = step;
        _currentMatchInfo = _stepNames[step];
      });
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
    });
  }

  void _goToNextStage(BuildContext context) {
    // 메인 메뉴로 복귀 (다음 주차 프로리그 진행)
    context.go('/main');
  }

  Color _getRaceColor(Race race) {
    switch (race) {
      case Race.terran:
        return AppColors.terran;
      case Race.zerg:
        return AppColors.zerg;
      case Race.protoss:
        return AppColors.protoss;
    }
  }
}
