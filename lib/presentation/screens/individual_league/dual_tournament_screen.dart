import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 듀얼토너먼트 화면
class DualTournamentScreen extends ConsumerStatefulWidget {
  final int round;

  const DualTournamentScreen({super.key, this.round = 1});

  @override
  ConsumerState<DualTournamentScreen> createState() =>
      _DualTournamentScreenState();
}

class _DualTournamentScreenState extends ConsumerState<DualTournamentScreen> {
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  bool _isSimulating = false;
  bool _isCompleted = false;
  int _currentRound = 0;
  String _currentMatchInfo = '';

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
                        // 좌측: 승자조 대진표
                        Expanded(
                          child: _buildWinnersBracket(bracket, playerMap),
                        ),
                        SizedBox(width: 16.sp),
                        // 중앙: 상태 표시 및 진출자
                        SizedBox(
                          width: 200.sp,
                          child: _buildCenterPanel(bracket, playerMap),
                        ),
                        SizedBox(width: 16.sp),
                        // 우측: 패자조 대진표
                        Expanded(
                          child: _buildLosersBracket(bracket, playerMap),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(context, bracket, playerMap),
              ],
            ),
            ResetButton.positioned(),
          ],
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
            '듀얼 토너먼트',
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

  Widget _buildWinnersBracket(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
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
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                '승자조 (Winners Bracket)',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _buildBracketView(
              bracket,
              playerMap,
              isWinners: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLosersBracket(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
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
          Row(
            children: [
              Icon(Icons.replay, color: Colors.orange, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                '패자조 (Losers Bracket)',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _buildBracketView(
              bracket,
              playerMap,
              isWinners: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketView(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap, {
    required bool isWinners,
  }) {
    if (bracket == null || bracket.dualTournamentPlayers.isEmpty) {
      return Center(
        child: Text(
          '대진표가 없습니다',
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
      );
    }

    final players = bracket.dualTournamentPlayers;

    // 간단한 참가자 목록 표시
    return ListView.builder(
      itemCount: isWinners ? (players.length / 2).ceil() : (players.length / 2).ceil(),
      itemBuilder: (context, index) {
        final player1Index = index * 2;
        final player2Index = index * 2 + 1;

        if (player1Index >= players.length) return const SizedBox();

        final player1 = playerMap[players[player1Index]];
        final player2 = player2Index < players.length
            ? playerMap[players[player2Index]]
            : null;

        // 결과가 있으면 표시
        IndividualMatchResult? matchResult;
        if (bracket.dualTournamentResults.isNotEmpty &&
            index < bracket.dualTournamentResults.length) {
          matchResult = bracket.dualTournamentResults[index];
        }

        return Container(
          margin: EdgeInsets.only(bottom: 8.sp),
          padding: EdgeInsets.all(8.sp),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildPlayerSlot(
                  player1,
                  isWinner: matchResult?.winnerId == player1?.id,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.sp),
                child: Text(
                  'vs',
                  style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                ),
              ),
              Expanded(
                child: _buildPlayerSlot(
                  player2,
                  isWinner: matchResult?.winnerId == player2?.id,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerSlot(Player? player, {bool isWinner = false}) {
    if (player == null) {
      return Container(
        padding: EdgeInsets.all(4.sp),
        child: Text(
          '-',
          style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.sp),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accent.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(2.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Icon(Icons.check, size: 12.sp, color: AppColors.accent),
          Expanded(
            child: Text(
              player.name,
              style: TextStyle(
                color: isWinner ? Colors.white : Colors.grey[400],
                fontSize: 11.sp,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '(${player.race.code})',
            style: TextStyle(
              color: _getRaceColor(player.race),
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        children: [
          // 상태 메시지
          if (_isSimulating) ...[
            const CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16.sp),
            Text(
              '경기 진행중',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Round $_currentRound',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_currentMatchInfo.isNotEmpty) ...[
              SizedBox(height: 8.sp),
              Text(
                _currentMatchInfo,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ] else if (_isCompleted) ...[
            Icon(Icons.check_circle, color: AppColors.accent, size: 40.sp),
            SizedBox(height: 12.sp),
            Text(
              '듀얼토너먼트 완료!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Icon(Icons.sports_esports, color: Colors.grey, size: 40.sp),
            SizedBox(height: 12.sp),
            Text(
              '듀얼토너먼트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              '24명 참가',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          ],
          SizedBox(height: 24.sp),
          // 본선 진출자 목록
          Expanded(
            child: _buildAdvancingPlayers(bracket, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancingPlayers(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final advancingPlayers = bracket?.mainTournamentPlayers ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '본선 진출자 (${advancingPlayers.length}/8)',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        Expanded(
          child: advancingPlayers.isEmpty
              ? Center(
                  child: Text(
                    '아직 없음',
                    style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                  ),
                )
              : ListView.builder(
                  itemCount: advancingPlayers.length,
                  itemBuilder: (context, index) {
                    final player = playerMap[advancingPlayers[index]];
                    if (player == null) return const SizedBox();

                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 4.sp),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11.sp,
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Expanded(
                            child: Text(
                              player.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          Text(
                            '(${player.race.code})',
                            style: TextStyle(
                              color: _getRaceColor(player.race),
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
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
              backgroundColor: _isSimulating ? Colors.grey : AppColors.primary,
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
    if (bracket == null || bracket.dualTournamentPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PC방 예선을 먼저 진행해주세요')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _currentRound = 1;
    });

    // 시뮬레이션 진행 (애니메이션 효과)
    for (var i = 1; i <= 7; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _currentRound = i;
        _currentMatchInfo = _getRoundName(i);
      });
    }

    // 실제 시뮬레이션
    final newBracket = _leagueService.simulateDualTournament(
      bracket: bracket,
      playerMap: playerMap,
    );

    ref.read(gameStateProvider.notifier).updateIndividualLeague(newBracket);

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
    });
  }

  String _getRoundName(int round) {
    switch (round) {
      case 1:
        return '승자조 1라운드';
      case 2:
        return '승자조 2라운드';
      case 3:
        return '패자조 1라운드';
      case 4:
        return '패자조 2라운드';
      case 5:
        return '승자조 3라운드';
      case 6:
        return '패자조 3라운드';
      case 7:
        return '최종 라운드';
      default:
        return '';
    }
  }

  void _goToNextStage(BuildContext context) {
    context.push('/group-draw');
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
