import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';

/// PC방 예선 토너먼트 화면
class PcBangQualifierScreen extends ConsumerStatefulWidget {
  const PcBangQualifierScreen({super.key});

  @override
  ConsumerState<PcBangQualifierScreen> createState() =>
      _PcBangQualifierScreenState();
}

class _PcBangQualifierScreenState extends ConsumerState<PcBangQualifierScreen> {
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  int? _selectedGroupIndex;
  bool _isSimulating = false;
  bool _isCompleted = false;
  int _currentRevealingGroup = -1;
  List<String> _qualifiedPlayers = [];
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerTeam = gameState.playerTeam;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, playerTeam),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Row(
                      children: [
                        // 좌측: 24개 조 버튼
                    SizedBox(
                      width: 180.sp,
                      child: _buildGroupButtons(bracket),
                    ),
                    SizedBox(width: 16.sp),
                    // 중앙: 대진표 또는 상태 메시지
                    Expanded(
                      flex: 3,
                      child: _buildCenterPanel(bracket, playerMap, playerTeam),
                    ),
                    SizedBox(width: 16.sp),
                    // 우측: 참가 현황 또는 통과자 명단
                    SizedBox(
                      width: 220.sp,
                      child: _buildRightPanel(bracket, playerMap, playerTeam.id),
                    ),
                  ],
                ),
              ),
            ),
                _buildBottomButtons(context, bracket, playerMap),
              ],
            ),
            // R 버튼 (오른쪽 상단)
            Positioned(
              right: 12.sp,
              top: 12.sp,
              child: _buildRButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRButton(BuildContext context) {
    return Container(
      width: 36.sp,
      height: 36.sp,
      decoration: BoxDecoration(
        color: Colors.red[800],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.red[400]!, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.sp),
          onTap: () => context.go('/'),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildTeamLogo(team),
          const Spacer(),
          Text(
            'PC방 예선 토너먼트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          _buildTeamLogo(team),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 60.sp,
      height: 40.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Color(team.colorValue)),
      ),
      child: Center(
        child: Text(
          team.shortName,
          style: TextStyle(
            color: Color(team.colorValue),
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupButtons(IndividualLeagueBracket? bracket) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '조 선택',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4.sp,
                crossAxisSpacing: 4.sp,
                childAspectRatio: 2,
              ),
              itemCount: 24,
              itemBuilder: (context, index) {
                final isSelected = _selectedGroupIndex == index;
                final isRevealed = _currentRevealingGroup >= index;
                final hasResult = bracket != null &&
                    bracket.pcBangResults.length >= (index + 1) * 3;

                return GestureDetector(
                  onTap: hasResult
                      ? () => setState(() => _selectedGroupIndex = index)
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withOpacity(0.3)
                          : isRevealed
                              ? AppColors.primary.withOpacity(0.5)
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4.sp),
                      border: isSelected
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}조',
                        style: TextStyle(
                          color: isSelected || isRevealed
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 12.sp,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    Team playerTeam,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // 팀 로고
          Container(
            width: 100.sp,
            height: 60.sp,
            decoration: BoxDecoration(
              color: Color(playerTeam.colorValue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: Color(playerTeam.colorValue)),
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: Color(playerTeam.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.sp),
          // 상태 메시지 또는 대진표
          Expanded(
            child: _buildCenterContent(bracket, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      return Center(
        child: Text(
          '예선이 진행되지 않았습니다',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    if (_isSimulating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16.sp),
            Text(
              '경기가 진행중입니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${_currentRevealingGroup + 1} / 24 조',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedGroupIndex != null && _isCompleted) {
      return _buildGroupBracket(bracket, playerMap, _selectedGroupIndex!);
    }

    if (_isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.accent, size: 48.sp),
            SizedBox(height: 16.sp),
            Text(
              '예선 완료!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '좌측에서 조를 선택하여 대진표를 확인하세요',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '예선이 진행되지 않았습니다',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.sp),
          Text(
            'Next 버튼을 눌러 예선을 시작하세요',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupBracket(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupResult = _leagueService.getGroupResult(bracket, groupIndex);
    if (groupResult == null) {
      return const Center(child: Text('결과 없음'));
    }

    final groupPlayers = bracket.pcBangGroups[groupIndex];

    return Column(
      children: [
        Text(
          '${groupIndex + 1}조 대진표',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        // 우승자
        Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(color: AppColors.accent),
          ),
          child: Column(
            children: [
              Text(
                '진출자',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.sp),
              Text(
                playerMap[groupResult.winnerId]?.name ?? '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.sp),
        // 토너먼트 대진표
        Expanded(
          child: _buildTournamentTree(groupPlayers, groupResult, playerMap),
        ),
      ],
    );
  }

  Widget _buildTournamentTree(
    List<String> playerIds,
    PcBangGroupResult result,
    Map<String, Player> playerMap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측 4강
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMatchBox(
              playerMap[playerIds[0]]?.name ?? '?',
              playerMap[playerIds[1]]?.name ?? '?',
              result.semiFinal1WinnerId == playerIds[0],
              playerMap,
            ),
          ],
        ),
        SizedBox(width: 24.sp),
        // 결승
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMatchBox(
              playerMap[result.semiFinal1WinnerId]?.name ?? '?',
              playerMap[result.semiFinal2WinnerId]?.name ?? '?',
              result.winnerId == result.semiFinal1WinnerId,
              playerMap,
            ),
          ],
        ),
        SizedBox(width: 24.sp),
        // 우측 4강
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMatchBox(
              playerMap[playerIds[2]]?.name ?? '?',
              playerMap[playerIds[3]]?.name ?? '?',
              result.semiFinal2WinnerId == playerIds[2],
              playerMap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchBox(
    String player1Name,
    String player2Name,
    bool player1Won,
    Map<String, Player> playerMap,
  ) {
    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color:
                  player1Won ? AppColors.accent.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Text(
              player1Name,
              style: TextStyle(
                color: player1Won ? Colors.white : Colors.grey,
                fontSize: 12.sp,
                fontWeight: player1Won ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            'vs',
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
          SizedBox(height: 4.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: !player1Won
                  ? AppColors.accent.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Text(
              player2Name,
              style: TextStyle(
                color: !player1Won ? Colors.white : Colors.grey,
                fontSize: 12.sp,
                fontWeight: !player1Won ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCompleted ? '예선 통과자' : '우리팀 참가 현황',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Expanded(
            child: _isCompleted && _qualifiedPlayers.isNotEmpty
                ? _buildQualifiedList(playerMap)
                : _buildMyTeamParticipants(bracket, playerMap, playerTeamId),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamParticipants(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      return Center(
        child: Text(
          '참가자 없음',
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
      );
    }

    final myTeamParticipants = <MapEntry<int, String>>[];

    for (var i = 0; i < bracket.pcBangGroups.length; i++) {
      for (final playerId in bracket.pcBangGroups[i]) {
        final player = playerMap[playerId];
        if (player != null && player.teamId == playerTeamId) {
          myTeamParticipants.add(MapEntry(i + 1, playerId));
        }
      }
    }

    return ListView.builder(
      itemCount: myTeamParticipants.length,
      itemBuilder: (context, index) {
        final entry = myTeamParticipants[index];
        final player = playerMap[entry.value]!;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  '${entry.key}조',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  color: _getRaceColor(player.race),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualifiedList(Map<String, Player> playerMap) {
    return ListView.builder(
      itemCount: _qualifiedPlayers.length,
      itemBuilder: (context, index) {
        final playerId = _qualifiedPlayers[index];
        final player = playerMap[playerId];
        if (player == null) return const SizedBox();

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              SizedBox(
                width: 30.sp,
                child: Text(
                  '${index + 1}.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  color: _getRaceColor(player.race),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  'EXIT [Bar]',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 24.sp),
          ElevatedButton(
            onPressed: _isSimulating
                ? null
                : () => _isCompleted
                    ? _goToNextStage(context)
                    : _startSimulation(bracket, playerMap),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isSimulating ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Next [Bar]' : 'Start [Bar]',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
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

  Future<void> _startSimulation(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) async {
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      // 조 편성 먼저
      final gameState = ref.read(gameStateProvider)!;
      final newBracket = _leagueService.createPcBangGroups(
        allPlayers: gameState.saveData.allPlayers,
        playerTeamId: gameState.playerTeam.id,
        seasonNumber: gameState.saveData.currentSeason.number,
      );

      // 상태 업데이트
      ref.read(gameStateProvider.notifier).updateIndividualLeague(newBracket);

      // 시뮬레이션 시작
      setState(() {
        _isSimulating = true;
        _currentRevealingGroup = -1;
      });

      // 0.5초 간격으로 조별 결과 표시
      _revealTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          _currentRevealingGroup++;
        });

        if (_currentRevealingGroup >= 23) {
          timer.cancel();
          _finishSimulation(playerMap);
        }
      });
    } else {
      // 이미 조 편성됨, 시뮬레이션만
      setState(() {
        _isSimulating = true;
        _currentRevealingGroup = -1;
      });

      _revealTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          _currentRevealingGroup++;
        });

        if (_currentRevealingGroup >= 23) {
          timer.cancel();
          _finishSimulation(playerMap);
        }
      });
    }
  }

  void _finishSimulation(Map<String, Player> playerMap) {
    final gameState = ref.read(gameStateProvider)!;
    var bracket = gameState.saveData.currentSeason.individualLeague!;

    // 모든 조 시뮬레이션
    bracket = _leagueService.simulateAllPcBangGroups(
      bracket: bracket,
      playerMap: playerMap,
    );

    // 상태 업데이트
    ref.read(gameStateProvider.notifier).updateIndividualLeague(bracket);

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
      _qualifiedPlayers = List.from(bracket.dualTournamentPlayers);
    });
  }

  void _goToNextStage(BuildContext context) {
    context.push('/dual-tournament');
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
