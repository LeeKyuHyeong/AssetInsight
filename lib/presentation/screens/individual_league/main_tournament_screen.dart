import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/match_simulation_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 본선 토너먼트 화면 (32강~결승)
class MainTournamentScreen extends ConsumerStatefulWidget {
  final String stage; // '32', '16', 'final'

  const MainTournamentScreen({super.key, this.stage = '32'});

  @override
  ConsumerState<MainTournamentScreen> createState() =>
      _MainTournamentScreenState();
}

class _MainTournamentScreenState extends ConsumerState<MainTournamentScreen> {
  final MatchSimulationService _matchService = MatchSimulationService();

  bool _isSimulating = false;
  bool _isCompleted = false;
  String _currentStage = '';
  String _currentMatch = '';

  // 시뮬레이션 결과 저장
  List<String> _quarterFinalWinners = [];
  List<String> _semiFinalWinners = [];
  String? _champion;
  String? _runnerUp;

  // 현재 보고 있는 경기 로그
  List<String> _currentBattleLog = [];

  // 배속 설정
  MatchSpeed _matchSpeed = MatchSpeed.x1;

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
                        // 좌측: 토너먼트 대진표
                        Expanded(
                          flex: 3,
                          child: _buildTournamentBracket(bracket, playerMap),
                        ),
                        SizedBox(width: 16.sp),
                        // 우측: 배틀 로그
                        SizedBox(
                          width: 300.sp,
                          child: _buildBattleLogPanel(),
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
          Column(
            children: [
              Text(
                '개인리그 본선',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              if (_currentStage.isNotEmpty)
                Text(
                  _currentStage,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14.sp,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // 배속 선택
          _buildSpeedSelector(),
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

  Widget _buildSpeedSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '배속: ',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
          ...MatchSpeed.values.map((speed) {
            final isSelected = _matchSpeed == speed;
            return GestureDetector(
              onTap: () => setState(() => _matchSpeed = speed),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.sp),
                padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Text(
                  'x${speed.multiplier}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTournamentBracket(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // 우승자 표시
          if (_champion != null) ...[
            Container(
              padding: EdgeInsets.all(16.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.withOpacity(0.3),
                    Colors.orange.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 40.sp),
                  SizedBox(height: 8.sp),
                  Text(
                    '우승',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    playerMap[_champion]?.name ?? '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.sp),
          ],
          // 대진표
          Expanded(
            child: _buildBracketTree(bracket, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketTree(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final players = bracket?.mainTournamentPlayers ?? [];

    if (players.isEmpty) {
      return Center(
        child: Text(
          '진출자가 없습니다',
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }

    return Row(
      children: [
        // 8강 (4 matches)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '8강',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (var i = 0; i < 4; i++)
                _buildMatchCard(
                  player1: i * 2 < players.length
                      ? playerMap[players[i * 2]]
                      : null,
                  player2: i * 2 + 1 < players.length
                      ? playerMap[players[i * 2 + 1]]
                      : null,
                  winner: i < _quarterFinalWinners.length
                      ? playerMap[_quarterFinalWinners[i]]
                      : null,
                  stage: '8강',
                ),
            ],
          ),
        ),
        // 연결선
        _buildConnector(),
        // 4강 (2 matches)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '4강',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              for (var i = 0; i < 2; i++)
                _buildMatchCard(
                  player1: i * 2 < _quarterFinalWinners.length
                      ? playerMap[_quarterFinalWinners[i * 2]]
                      : null,
                  player2: i * 2 + 1 < _quarterFinalWinners.length
                      ? playerMap[_quarterFinalWinners[i * 2 + 1]]
                      : null,
                  winner: i < _semiFinalWinners.length
                      ? playerMap[_semiFinalWinners[i]]
                      : null,
                  stage: '4강',
                ),
            ],
          ),
        ),
        // 연결선
        _buildConnector(),
        // 결승 (1 match)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '결승',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.sp),
              _buildMatchCard(
                player1: _semiFinalWinners.isNotEmpty
                    ? playerMap[_semiFinalWinners[0]]
                    : null,
                player2: _semiFinalWinners.length > 1
                    ? playerMap[_semiFinalWinners[1]]
                    : null,
                winner: _champion != null ? playerMap[_champion] : null,
                stage: '결승',
                isFinal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnector() {
    return SizedBox(
      width: 20.sp,
      child: CustomPaint(
        painter: _BracketLinePainter(),
        size: Size(20.sp, double.infinity),
      ),
    );
  }

  Widget _buildMatchCard({
    Player? player1,
    Player? player2,
    Player? winner,
    required String stage,
    bool isFinal = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: isFinal
            ? Colors.amber.withOpacity(0.1)
            : Colors.grey[850],
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: isFinal ? Colors.amber : Colors.grey[700]!,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayerRow(player1, isWinner: winner?.id == player1?.id),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            child: Text(
              'vs',
              style: TextStyle(color: Colors.grey, fontSize: 10.sp),
            ),
          ),
          _buildPlayerRow(player2, isWinner: winner?.id == player2?.id),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(Player? player, {bool isWinner = false}) {
    if (player == null) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
        child: Text(
          '?',
          style: TextStyle(color: Colors.grey, fontSize: 11.sp),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: isWinner ? AppColors.accent.withOpacity(0.2) : null,
        borderRadius: BorderRadius.circular(2.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Padding(
              padding: EdgeInsets.only(right: 4.sp),
              child: Icon(
                Icons.check,
                size: 12.sp,
                color: AppColors.accent,
              ),
            ),
          Text(
            player.name,
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.grey[400],
              fontSize: 11.sp,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          SizedBox(width: 4.sp),
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

  Widget _buildBattleLogPanel() {
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
              Icon(Icons.list_alt, color: AppColors.accent, size: 18.sp),
              SizedBox(width: 8.sp),
              Text(
                '경기 로그',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.sp),
          Text(
            _currentMatch.isEmpty ? '8강부터 텍스트 시뮬레이션' : _currentMatch,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _currentBattleLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_esports,
                          color: Colors.grey[700],
                          size: 40.sp,
                        ),
                        SizedBox(height: 8.sp),
                        Text(
                          _isSimulating ? '경기 진행중...' : 'Start를 눌러 시작',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    padding: EdgeInsets.all(8.sp),
                    child: ListView.builder(
                      itemCount: _currentBattleLog.length,
                      itemBuilder: (context, index) {
                        final log = _currentBattleLog[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.sp),
                          child: Text(
                            log,
                            style: TextStyle(
                              color: _getLogColor(log),
                              fontSize: 11.sp,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('승리') || log.contains('GG')) {
      return AppColors.accent;
    }
    if (log.contains('공격') || log.contains('러쉬')) {
      return Colors.red[300]!;
    }
    if (log.contains('수비') || log.contains('방어')) {
      return Colors.blue[300]!;
    }
    return Colors.grey[400]!;
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
                    ? _finishTournament(context)
                    : _startSimulation(bracket, playerMap),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isSimulating ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Finish [Bar]' : 'Start [Bar]',
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
    if (bracket == null || bracket.mainTournamentPlayers.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조지명식을 먼저 진행해주세요')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
      _currentBattleLog = [];
      _quarterFinalWinners = [];
      _semiFinalWinners = [];
      _champion = null;
      _runnerUp = null;
    });

    final players = bracket.mainTournamentPlayers;
    final maps = GameMaps.all;

    // 8강
    setState(() {
      _currentStage = '8강';
    });

    for (var i = 0; i < 4; i++) {
      final player1 = playerMap[players[i * 2]]!;
      final player2 = playerMap[players[i * 2 + 1]]!;
      final map = maps[i % maps.length];

      setState(() {
        _currentMatch = '${player1.name} vs ${player2.name}';
        _currentBattleLog = [];
      });

      final winner = await _simulateMatchWithLog(player1, player2, map, playerMap);
      _quarterFinalWinners.add(winner);

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 4강
    setState(() {
      _currentStage = '4강';
    });

    for (var i = 0; i < 2; i++) {
      final player1 = playerMap[_quarterFinalWinners[i * 2]]!;
      final player2 = playerMap[_quarterFinalWinners[i * 2 + 1]]!;
      final map = maps[(i + 4) % maps.length];

      setState(() {
        _currentMatch = '${player1.name} vs ${player2.name}';
        _currentBattleLog = [];
      });

      final winner = await _simulateMatchWithLog(player1, player2, map, playerMap);
      _semiFinalWinners.add(winner);

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // 결승
    setState(() {
      _currentStage = '결승';
    });

    final finalist1 = playerMap[_semiFinalWinners[0]]!;
    final finalist2 = playerMap[_semiFinalWinners[1]]!;
    final finalMap = maps[6 % maps.length];

    setState(() {
      _currentMatch = '${finalist1.name} vs ${finalist2.name}';
      _currentBattleLog = [];
    });

    final championId = await _simulateMatchWithLog(finalist1, finalist2, finalMap, playerMap);

    setState(() {
      _champion = championId;
      _runnerUp = championId == finalist1.id ? finalist2.id : finalist1.id;
      _isSimulating = false;
      _isCompleted = true;
      _currentStage = '완료';
    });

    // 결과 저장
    final newBracket = bracket.copyWith(
      championId: _champion,
      runnerUpId: _runnerUp,
    );
    ref.read(gameStateProvider.notifier).updateIndividualLeague(newBracket);
  }

  Future<String> _simulateMatchWithLog(
    Player player1,
    Player player2,
    GameMap map,
    Map<String, Player> playerMap,
  ) async {
    final stream = _matchService.simulateMatchWithLog(
      homePlayer: player1,
      awayPlayer: player2,
      map: map,
      intervalMs: _matchSpeed.intervalMs,
    );

    String? winnerId;

    await for (final state in stream) {
      if (!mounted) break;

      setState(() {
        _currentBattleLog = state.battleLog;
      });

      if (state.isFinished && state.homeWin != null) {
        winnerId = state.homeWin! ? player1.id : player2.id;
      }
    }

    return winnerId ?? player1.id;
  }

  void _finishTournament(BuildContext context) {
    // 메인 메뉴로 돌아가기
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

/// 대진표 연결선 페인터
class _BracketLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[700]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 간단한 연결선
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width / 2, size.height * 0.25),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width / 2, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.25),
      Offset(size.width / 2, size.height * 0.75),
      paint,
    );
    canvas.drawLine(
      Offset(size.width / 2, size.height * 0.5),
      Offset(size.width, size.height * 0.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
