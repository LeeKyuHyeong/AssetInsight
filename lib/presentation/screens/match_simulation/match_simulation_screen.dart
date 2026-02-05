import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../../data/providers/match_provider.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/match_simulation_service.dart';
import '../../widgets/reset_button.dart';

class MatchSimulationScreen extends ConsumerStatefulWidget {
  const MatchSimulationScreen({super.key});

  @override
  ConsumerState<MatchSimulationScreen> createState() =>
      _MatchSimulationScreenState();
}

class _MatchSimulationScreenState extends ConsumerState<MatchSimulationScreen> {
  // 시뮬레이션 서비스
  final MatchSimulationService _simulationService = MatchSimulationService();
  StreamSubscription<SimulationState>? _simulationSubscription;

  // 현재 게임 상태
  int player1Resource = 100;
  int player1Army = 50;
  int player2Resource = 100;
  int player2Army = 50;

  // 전투 로그 (BattleLogEntry 사용 - 색상 구분)
  final List<BattleLogEntry> battleLogEntries = [];
  final ScrollController _logScrollController = ScrollController();

  // 배속
  int speed = 1;
  bool isRunning = false;
  bool gameEnded = false;

  // 에이스 결정전 관련
  bool showAceSelection = false;
  int? selectedAceIndex;

  // 세트 종료 시 결과 표시용
  bool showSetResult = false;
  bool? lastSetHomeWin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  void _initGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) {
      // 매치 데이터가 없으면 메인으로 돌아감
      context.go('/main');
      return;
    }

    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    _startGame();
  }

  Player? _getPlayerById(String? playerId) {
    if (playerId == null) return null;
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return null;
    return gameState.saveData.getPlayerById(playerId);
  }

  GameMap? _getCurrentMap() {
    final matchState = ref.read(currentMatchProvider);
    final gameState = ref.read(gameStateProvider);
    if (matchState == null || gameState == null) return null;

    final currentSet = matchState.currentSet;
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;

    if (currentSet < seasonMapIds.length) {
      final mapId = seasonMapIds[currentSet];
      return GameMaps.getById(mapId);
    }

    // 시즌맵이 없거나 인덱스 초과 시 기본 맵
    return GameMaps.fightingSpirit;
  }

  @override
  void dispose() {
    _simulationSubscription?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);
    final map = _getCurrentMap();

    if (homePlayer == null || awayPlayer == null || map == null) return;

    setState(() {
      isRunning = true;
      gameEnded = false;
      battleLogEntries.clear();
      player1Army = 50;
      player2Army = 50;
      player1Resource = 100;
      player2Resource = 100;
    });

    // 특수 컨디션 가져오기
    final homeSpecialCondition = matchState.getSpecialCondition(homePlayer.id);
    final awaySpecialCondition = matchState.getSpecialCondition(awayPlayer.id);

    // 시뮬레이션 스트림 시작 (배속 콜백으로 전달하여 중간 변경 가능)
    final stream = _simulationService.simulateMatchWithLog(
      homePlayer: homePlayer,
      awayPlayer: awayPlayer,
      map: map,
      getIntervalMs: _getIntervalMs,
      homeSpecialCondition: homeSpecialCondition,
      awaySpecialCondition: awaySpecialCondition,
    );

    _simulationSubscription?.cancel();
    _simulationSubscription = stream.listen(
      (state) {
        if (!mounted) return;

        setState(() {
          player1Army = state.homeArmy;
          player2Army = state.awayArmy;
          player1Resource = state.homeResources;
          player2Resource = state.awayResources;

          // 새 로그만 추가 (BattleLogEntry 사용)
          if (state.battleLogEntries.length > battleLogEntries.length) {
            for (int i = battleLogEntries.length; i < state.battleLogEntries.length; i++) {
              battleLogEntries.add(state.battleLogEntries[i]);
            }
            _scrollToBottom();
          }

          // 경기 종료 처리
          if (state.isFinished) {
            isRunning = false;
            gameEnded = true;

            // 점수 업데이트
            if (state.homeWin != null) {
              ref.read(currentMatchProvider.notifier).recordSetResult(state.homeWin!);

              // 선수별 전적 업데이트
              _updatePlayerRecords(state.homeWin!);

              // 세트 결과 저장 (오버레이는 NEXT 버튼 클릭 시 표시)
              lastSetHomeWin = state.homeWin;
              // showSetResult는 false 유지 - NEXT 버튼 클릭 시 true로 변경
            }
          }
        });
      },
      onError: (error) {
        debugPrint('시뮬레이션 오류: $error');
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          isRunning = false;
          gameEnded = true;
        });
      },
    );
  }

  int _getIntervalMs() {
    switch (speed) {
      case 1:
        return 1000;
      case 4:
        return 250;
      case 8:
        return 125;
      default:
        return 1000;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 로그 엔트리에 따른 색상 반환
  Color _getLogColor(BattleLogEntry entry, CurrentMatchState matchState) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return AppTheme.textPrimary;

    // 플레이어 팀이 홈인지 확인
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;

    // 승리/GG 관련 텍스트는 특별 색상
    if (entry.text.contains('승리')) {
      return AppTheme.accentGreen;
    }
    if (entry.text.contains('GG')) {
      return Colors.orange;
    }

    // 소유자에 따른 색상
    switch (entry.owner) {
      case LogOwner.system:
        return AppTheme.textSecondary; // 시스템 메시지는 회색
      case LogOwner.home:
        // 홈 = 플레이어팀이면 녹색, 아니면 빨간색
        return isPlayerHome ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
      case LogOwner.away:
        // 어웨이 = 플레이어팀이면 녹색, 아니면 빨간색
        return isPlayerHome ? const Color(0xFFE57373) : const Color(0xFF4CAF50);
      case LogOwner.clash:
        return Colors.amber; // 충돌/전투는 노란색
    }
  }

  void _changeSpeed(int newSpeed) {
    // 배속만 변경 (스트림은 콜백으로 현재 배속을 참조하므로 재시작 불필요)
    setState(() {
      speed = newSpeed;
    });
  }

  /// 선수별 전적 업데이트
  void _updatePlayerRecords(bool homeWin) {
    final matchState = ref.read(currentMatchProvider);
    final gameState = ref.read(gameStateProvider);
    if (matchState == null || gameState == null) return;

    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);
    if (homePlayer == null || awayPlayer == null) return;

    // 홈 선수 전적 업데이트
    final updatedHomePlayer = homePlayer.applyMatchResult(
      isWin: homeWin,
      opponentGrade: awayPlayer.grade,
      opponentRace: awayPlayer.race,
      opponentId: awayPlayer.id,
    );

    // 어웨이 선수 전적 업데이트
    final updatedAwayPlayer = awayPlayer.applyMatchResult(
      isWin: !homeWin,
      opponentGrade: homePlayer.grade,
      opponentRace: homePlayer.race,
      opponentId: homePlayer.id,
    );

    // 게임 상태 업데이트
    ref.read(gameStateProvider.notifier).updatePlayers([
      updatedHomePlayer,
      updatedAwayPlayer,
    ]);
  }

  void _nextGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    // 오버레이가 아직 표시되지 않은 상태 (배틀 로그 화면)
    if (!showSetResult && lastSetHomeWin != null) {
      setState(() {
        showSetResult = true; // 오버레이 표시
      });
      return;
    }

    // 오버레이에서 NEXT 버튼 클릭
    if (matchState.isMatchEnded) {
      // 매치 종료
      _showMatchResult();
    } else if (matchState.isAceMatch && matchState.homeAcePlayerId == null) {
      // 에이스 결정전 진행 필요
      setState(() {
        showAceSelection = true;
      });
    } else {
      // 다음 게임
      _prepareNextGame();
    }
  }

  void _prepareNextGame() {
    // 기존 스트림 취소
    _simulationSubscription?.cancel();

    setState(() {
      player1Resource = 100;
      player1Army = 50;
      player2Resource = 100;
      player2Army = 50;
      battleLogEntries.clear();
      gameEnded = false;
      showAceSelection = false;
      showSetResult = false;
      lastSetHomeWin = null;
    });

    _startGame();
  }

  void _selectAcePlayer(int playerIndex) {
    final gameState = ref.read(gameStateProvider);
    final matchState = ref.read(currentMatchProvider);
    if (gameState == null || matchState == null) return;

    final teamPlayers = gameState.playerTeamPlayers;
    if (playerIndex < 0 || playerIndex >= teamPlayers.length) return;

    // 플레이어 팀이 홈인지 확인
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;
    final playerRoster = isPlayerHome ? matchState.homeRoster : matchState.awayRoster;

    // 이미 출전한 선수인지 체크
    final usedPlayers = playerRoster.whereType<String>().toSet();
    final selectedPlayer = teamPlayers[playerIndex];

    if (usedPlayers.contains(selectedPlayer.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 출전한 선수입니다.')),
      );
      return;
    }

    // 에이스 선수 설정 (플레이어 팀 위치에 따라)
    if (isPlayerHome) {
      ref.read(currentMatchProvider.notifier).setAcePlayer(
        homeAceId: selectedPlayer.id,
      );
    } else {
      ref.read(currentMatchProvider.notifier).setAcePlayer(
        awayAceId: selectedPlayer.id,
      );
    }

    // 다음 게임 시작
    _prepareNextGame();
  }

  void _showMatchResult() async {
    final matchState = ref.read(currentMatchProvider);
    final gameState = ref.read(gameStateProvider);
    if (matchState == null || gameState == null) return;

    // 플레이어 팀 기준으로 승패 판정
    final playerTeamId = gameState.playerTeam.id;
    final isPlayerHome = matchState.homeTeamId == playerTeamId;
    final playerScore = isPlayerHome ? matchState.homeScore : matchState.awayScore;
    final opponentScore = isPlayerHome ? matchState.awayScore : matchState.homeScore;
    final isWin = playerScore > opponentScore;

    // 매치 결과를 게임 상태에 저장
    ref.read(gameStateProvider.notifier).recordMatchResult(
      homeTeamId: matchState.homeTeamId,
      awayTeamId: matchState.awayTeamId,
      homeScore: matchState.homeScore,
      awayScore: matchState.awayScore,
    );

    // 게임 저장
    await ref.read(gameStateProvider.notifier).save();

    // 팀 정보
    final homeTeam = gameState.saveData.getTeamById(matchState.homeTeamId);
    final awayTeam = gameState.saveData.getTeamById(matchState.awayTeamId);
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;

    // 결과 화면 표시
    setState(() {
      showSetResult = false; // 세트 결과 오버레이 숨김
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단: 팀 스코어
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 홈 팀
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          homeTeam?.name ?? 'HOME',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: matchState.homeScore > matchState.awayScore
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        if (matchState.homeScore > matchState.awayScore)
                          Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
                      ],
                    ),
                  ),
                  // 스코어
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                    child: Text(
                      '${matchState.homeScore} : ${matchState.awayScore}',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                  // 어웨이 팀
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (matchState.awayScore > matchState.homeScore)
                          Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text(
                          awayTeam?.name ?? 'AWAY',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: matchState.awayScore > matchState.homeScore
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.sp),
              Divider(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              SizedBox(height: 8.sp),

              // 세트별 결과
              ...List.generate(7, (index) {
                final isAceSet = index == 6;
                final setPlayed = index < matchState.setResults.length;

                // 선수 정보
                Player? homePlayer;
                Player? awayPlayer;
                if (isAceSet) {
                  homePlayer = _getPlayerById(matchState.homeAcePlayerId);
                  awayPlayer = _getPlayerById(matchState.awayAcePlayerId);
                } else {
                  homePlayer = index < matchState.homeRoster.length
                      ? _getPlayerById(matchState.homeRoster[index])
                      : null;
                  awayPlayer = index < matchState.awayRoster.length
                      ? _getPlayerById(matchState.awayRoster[index])
                      : null;
                }

                // 맵 정보
                final mapId = index < seasonMapIds.length ? seasonMapIds[index] : null;
                final map = mapId != null ? GameMaps.getById(mapId) : null;
                final mapName = map?.name ?? (isAceSet ? 'ACE' : 'Map ${index + 1}');

                // 승패 결과
                bool? homeWin;
                if (setPlayed) {
                  homeWin = matchState.setResults[index];
                }

                // ACE 매치가 없으면 [ACE] 표시
                final aceNotPlayed = isAceSet && !setPlayed;

                return _buildMatchResultRow(
                  setNumber: index + 1,
                  homePlayer: homePlayer,
                  awayPlayer: awayPlayer,
                  mapName: mapName,
                  homeWin: homeWin,
                  isAceSet: isAceSet,
                  aceNotPlayed: aceNotPlayed,
                );
              }),

              SizedBox(height: 16.sp),
              Divider(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              SizedBox(height: 12.sp),

              // 결과 메시지
              Text(
                isWin ? '승리!' : '패배...',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: isWin ? AppTheme.accentGreen : Colors.red,
                ),
              ),
              SizedBox(height: 4.sp),
              Text(
                isWin ? '축하합니다!' : '다음에는 꼭 이기세요!',
                style: TextStyle(fontSize: 12.sp, color: AppTheme.textSecondary),
              ),

              SizedBox(height: 16.sp),

              // NEXT 버튼 (팀 순위 화면으로)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _showTeamStandings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12.sp),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEXT',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8.sp),
                      Icon(Icons.double_arrow, size: 16.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 팀 순위 화면 표시
  void _showTeamStandings() {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final standings = ref.read(gameStateProvider.notifier).calculateStandings();
    final playerTeamId = gameState.playerTeam.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 상단: 제목
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '현재 순위',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Icon(Icons.leaderboard, color: AppTheme.accentGreen, size: 20.sp),
                ],
              ),
              SizedBox(height: 16.sp),
              Divider(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              SizedBox(height: 8.sp),

              // 팀 순위 목록
              ...standings.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final standing = entry.value;
                final team = gameState.saveData.getTeamById(standing.teamId);
                final isPlayerTeam = standing.teamId == playerTeamId;
                final setDiff = standing.setDiff;
                final setDiffStr = setDiff >= 0 ? '+$setDiff' : '$setDiff';

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 2.sp),
                  padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
                  decoration: BoxDecoration(
                    color: isPlayerTeam
                        ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4.sp),
                    border: isPlayerTeam
                        ? Border.all(color: AppTheme.primaryBlue, width: 1)
                        : null,
                  ),
                  child: Row(
                    children: [
                      // 순위
                      Container(
                        width: 24.sp,
                        alignment: Alignment.center,
                        child: Text(
                          '$rank위',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: rank <= 4 ? AppTheme.accentGreen : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      // 팀 로고 (색상 박스로 대체)
                      Container(
                        width: 28.sp,
                        height: 20.sp,
                        decoration: BoxDecoration(
                          color: team != null
                              ? Color(team.colorValue).withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4.sp),
                          border: Border.all(
                            color: team != null ? Color(team.colorValue) : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            team?.shortName ?? '???',
                            style: TextStyle(
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                              color: team != null ? Color(team.colorValue) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      // 팀 이름
                      Expanded(
                        child: Text(
                          team?.name ?? '???',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: isPlayerTeam ? FontWeight.bold : FontWeight.normal,
                            color: isPlayerTeam ? Colors.white : AppTheme.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 승/패
                      Text(
                        '${standing.wins}W ${standing.losses}L',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      // 세트 득실
                      Container(
                        width: 40.sp,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '($setDiffStr)',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: setDiff > 0
                                ? Colors.green
                                : (setDiff < 0 ? Colors.red : AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 16.sp),
              Divider(color: AppTheme.textSecondary.withValues(alpha: 0.3)),
              SizedBox(height: 12.sp),

              // NEXT 버튼 (메인으로)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(currentMatchProvider.notifier).resetMatch();
                    Navigator.pop(dialogContext);
                    context.go('/main');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 12.sp),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'NEXT',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8.sp),
                      Icon(Icons.double_arrow, size: 16.sp),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 매치 결과 행 위젯
  Widget _buildMatchResultRow({
    required int setNumber,
    required Player? homePlayer,
    required Player? awayPlayer,
    required String mapName,
    required bool? homeWin,
    required bool isAceSet,
    required bool aceNotPlayed,
  }) {
    final played = homeWin != null;
    final textColor = played ? Colors.white : AppTheme.textSecondary.withValues(alpha: 0.5);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.sp),
      child: Row(
        children: [
          // 홈 선수 (W/L 아이콘 + 선수 정보)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (played && homeWin == true)
                  Icon(Icons.circle, color: Colors.green, size: 10.sp)
                else if (played && homeWin == false)
                  Icon(Icons.close, color: Colors.red, size: 10.sp)
                else
                  SizedBox(width: 10.sp),
                SizedBox(width: 4.sp),
                if (isAceSet && aceNotPlayed)
                  Text('[ACE]', style: TextStyle(fontSize: 10.sp, color: textColor))
                else if (homePlayer != null)
                  Text(
                    '(${homePlayer.race.code}) ${homePlayer.name}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: played
                          ? (homeWin == true ? Colors.white : AppTheme.textSecondary)
                          : textColor,
                      fontWeight: played && homeWin == true ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text('???', style: TextStyle(fontSize: 10.sp, color: textColor)),
              ],
            ),
          ),

          // 맵 이름
          Container(
            width: 90.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            child: Text(
              '< $mapName >',
              style: TextStyle(
                fontSize: 9.sp,
                color: played ? AppTheme.primaryBlue : textColor,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 어웨이 선수 (선수 정보 + W/L 아이콘)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (isAceSet && aceNotPlayed)
                  Text('[ACE]', style: TextStyle(fontSize: 10.sp, color: textColor))
                else if (awayPlayer != null)
                  Text(
                    '(${awayPlayer.race.code}) ${awayPlayer.name}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: played
                          ? (homeWin == false ? Colors.white : AppTheme.textSecondary)
                          : textColor,
                      fontWeight: played && homeWin == false ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text('???', style: TextStyle(fontSize: 10.sp, color: textColor)),
                SizedBox(width: 4.sp),
                if (played && homeWin == false)
                  Icon(Icons.circle, color: Colors.green, size: 10.sp)
                else if (played && homeWin == true)
                  Icon(Icons.close, color: Colors.red, size: 10.sp)
                else
                  SizedBox(width: 10.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final matchState = ref.watch(currentMatchProvider);
    final gameState = ref.watch(gameStateProvider);

    if (matchState == null || gameState == null) {
      return const Scaffold(
        body: Center(child: Text('매치 데이터를 불러올 수 없습니다')),
      );
    }

    // 에이스 선택 화면
    if (showAceSelection) {
      return _buildAceSelectionScreen(gameState, matchState);
    }

    // 플레이어 팀 기준으로 좌우 배치 결정
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;

    // 왼쪽 = 내 팀, 오른쪽 = 상대 팀
    final leftTeam = isPlayerHome
        ? gameState.saveData.getTeamById(matchState.homeTeamId)
        : gameState.saveData.getTeamById(matchState.awayTeamId);
    final rightTeam = isPlayerHome
        ? gameState.saveData.getTeamById(matchState.awayTeamId)
        : gameState.saveData.getTeamById(matchState.homeTeamId);
    final leftPlayer = isPlayerHome
        ? _getPlayerById(matchState.currentHomePlayerId)
        : _getPlayerById(matchState.currentAwayPlayerId);
    final rightPlayer = isPlayerHome
        ? _getPlayerById(matchState.currentAwayPlayerId)
        : _getPlayerById(matchState.currentHomePlayerId);

    // 특수 컨디션도 내 팀 기준
    final leftSpecialCondition = isPlayerHome
        ? matchState.getSpecialCondition(matchState.currentHomePlayerId ?? '')
        : matchState.getSpecialCondition(matchState.currentAwayPlayerId ?? '');
    final rightSpecialCondition = isPlayerHome
        ? matchState.getSpecialCondition(matchState.currentAwayPlayerId ?? '')
        : matchState.getSpecialCondition(matchState.currentHomePlayerId ?? '');

    // 점수도 내 팀 기준
    final myScore = isPlayerHome ? matchState.homeScore : matchState.awayScore;
    final opponentScore = isPlayerHome ? matchState.awayScore : matchState.homeScore;

    // 자원/병력도 내 팀 기준
    final myResource = isPlayerHome ? player1Resource : player2Resource;
    final opponentResource = isPlayerHome ? player2Resource : player1Resource;
    final myArmy = isPlayerHome ? player1Army : player2Army;
    final opponentArmy = isPlayerHome ? player2Army : player1Army;

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 진행'),
        leading: ResetButton.leading(),
        actions: [
          TextButton(
            onPressed: () {
              _simulationSubscription?.cancel();
              ref.read(currentMatchProvider.notifier).resetMatch();
              context.go('/main');
            },
            child: const Text('나가기'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 매치 스코어 (내 팀 기준)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.cardBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Text(
                        leftTeam?.name ?? '내 팀',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$myScore : $opponentScore',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rightTeam?.name ?? '상대 팀',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 세트 정보
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  matchState.isAceMatch ? 'ACE 결정전' : 'Set ${matchState.currentSet + 1}',
                  style: TextStyle(
                    color: matchState.isAceMatch ? Colors.orange : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 선수 정보 (내 팀 선수가 왼쪽)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _PlayerPanel(player: leftPlayer, isHome: true, specialCondition: leftSpecialCondition)),
                    const SizedBox(width: 16),
                    Expanded(child: _PlayerPanel(player: rightPlayer, isHome: false, specialCondition: rightSpecialCondition)),
                  ],
                ),
              ),

              // 자원/병력 바 (내 팀 기준)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ResourceBar(
                      label: '자원',
                      value1: myResource,
                      value2: opponentResource,
                      maxValue: 500, // 표시용 최대값 (실제 최대 10000)
                      color: Colors.yellow,
                    ),
                    const SizedBox(height: 8),
                    _ResourceBar(
                      label: '병력',
                      value1: myArmy,
                      value2: opponentArmy,
                      maxValue: 100, // 표시용 최대값 (실제 최대 200)
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 전투 로그 (색상 구분)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue),
                  ),
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: battleLogEntries.length,
                    itemBuilder: (context, index) {
                      final entry = battleLogEntries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          entry.text,
                          style: TextStyle(
                            color: _getLogColor(entry, matchState),
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 컨트롤
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 배속 버튼
                    ...[1, 4, 8].map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () => _changeSpeed(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: speed == s
                                  ? AppTheme.accentGreen
                                  : AppTheme.cardBackground,
                              foregroundColor:
                                  speed == s ? Colors.black : AppTheme.textPrimary,
                              minimumSize: const Size(50, 40),
                            ),
                            child: Text('x$s'),
                          ),
                        )),
                    const SizedBox(width: 16),
                    // 다음 게임 / 스킵
                    if (gameEnded)
                      ElevatedButton(
                        onPressed: _nextGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          matchState.isMatchEnded
                              ? '결과 확인'
                              : matchState.isAceMatch
                                  ? '에이스 선택'
                                  : '다음 게임',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          // 세트 결과 오버레이
          if (showSetResult && lastSetHomeWin != null)
            _buildSetResultOverlay(matchState),
        ],
      ),
    );
  }

  Widget _buildSetResultOverlay(CurrentMatchState matchState) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return const SizedBox();

    // 플레이어 팀 기준으로 좌우 배치
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;
    final leftTeam = isPlayerHome
        ? gameState.saveData.getTeamById(matchState.homeTeamId)
        : gameState.saveData.getTeamById(matchState.awayTeamId);
    final rightTeam = isPlayerHome
        ? gameState.saveData.getTeamById(matchState.awayTeamId)
        : gameState.saveData.getTeamById(matchState.homeTeamId);
    final myScore = isPlayerHome ? matchState.homeScore : matchState.awayScore;
    final opponentScore = isPlayerHome ? matchState.awayScore : matchState.homeScore;

    // 다음 세트 번호 (매치 종료가 아닌 경우)
    final nextSet = matchState.isMatchEnded ? -1 : matchState.currentSet + 1;
    final isAceNext = !matchState.isMatchEnded && matchState.homeScore == 3 && matchState.awayScore == 3;

    return Container(
      color: Colors.black.withValues(alpha: 0.95),
      child: SafeArea(
        child: Column(
          children: [
            // 상단: 팀 로고 + 스코어 (내 팀 기준)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16.sp, horizontal: 24.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 내 팀 로고
                  _buildTeamLogo(leftTeam, isHome: true),
                  SizedBox(width: 20.sp),
                  // 스코어 (내 팀 기준)
                  Text(
                    '$myScore',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 36.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '$opponentScore',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentGreen,
                    ),
                  ),
                  SizedBox(width: 20.sp),
                  // 상대 팀 로고
                  _buildTeamLogo(rightTeam, isHome: false),
                ],
              ),
            ),

            // 다음 세트 표시
            if (!matchState.isMatchEnded)
              Container(
                padding: EdgeInsets.symmetric(vertical: 12.sp),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 24.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      isAceNext ? 'ACE Set' : '${nextSet} Set',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isAceNext ? Colors.orange : Colors.white,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 24.sp),
                  ],
                ),
              ),

            // 중앙: 전체 대진표
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                child: _buildFullBracket(matchState, gameState, nextSet, isAceNext),
              ),
            ),

            // 하단: Next 버튼
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16.sp),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        matchState.isMatchEnded
                            ? '결과 확인'
                            : isAceNext
                                ? '에이스 선택'
                                : 'Next',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Icon(Icons.double_arrow, size: 20.sp),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLogo(Team? team, {required bool isHome}) {
    return Container(
      width: 60.sp,
      height: 40.sp,
      decoration: BoxDecoration(
        color: team != null
            ? Color(team.colorValue).withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: team != null ? Color(team.colorValue) : Colors.grey,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          team?.shortName ?? '???',
          style: TextStyle(
            color: team != null ? Color(team.colorValue) : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildFullBracket(CurrentMatchState matchState, GameState gameState, int nextSet, bool isAceNext) {
    // 플레이어 팀 기준으로 좌우 배치
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;

    return Row(
      children: [
        // 내 팀 선수 목록 (왼쪽)
        Expanded(
          child: _buildTeamRoster(
            matchState: matchState,
            gameState: gameState,
            isHome: isPlayerHome, // 내 팀이 홈이면 true, 아니면 false
            isLeftSide: true,
            nextSet: nextSet,
            isAceNext: isAceNext,
          ),
        ),
        // 중앙: 맵 목록
        Container(
          width: 100.sp,
          child: _buildMapList(matchState, gameState, nextSet, isAceNext),
        ),
        // 상대 팀 선수 목록 (오른쪽)
        Expanded(
          child: _buildTeamRoster(
            matchState: matchState,
            gameState: gameState,
            isHome: !isPlayerHome, // 내 팀이 홈이면 상대는 away, 아니면 home
            isLeftSide: false,
            nextSet: nextSet,
            isAceNext: isAceNext,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRoster({
    required CurrentMatchState matchState,
    required GameState gameState,
    required bool isHome,
    required bool isLeftSide, // 화면상 왼쪽인지 (내 팀)
    required int nextSet,
    required bool isAceNext,
  }) {
    final roster = isHome ? matchState.homeRoster : matchState.awayRoster;
    final setResults = matchState.setResults;

    return ListView.builder(
      itemCount: 7, // 6세트 + ACE
      itemBuilder: (context, index) {
        final isAceSlot = index == 6;
        final playerId = isAceSlot
            ? (isHome ? matchState.homeAcePlayerId : matchState.awayAcePlayerId)
            : (index < roster.length ? roster[index] : null);
        final player = playerId != null ? _getPlayerById(playerId) : null;

        // 이 세트가 완료되었는지
        final setCompleted = index < setResults.length;
        // 이 세트를 이겼는지 (isHome 기준으로 판단)
        final setWon = setCompleted && setResults[index] == isHome;
        final setLost = setCompleted && setResults[index] != isHome;

        // 다음 세트인지 하이라이트
        final isNextSet = (isAceNext && isAceSlot) || (!isAceNext && index == nextSet - 1);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.sp),
          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
          decoration: BoxDecoration(
            color: isNextSet
                ? AppTheme.accentGreen.withValues(alpha: 0.2)
                : setCompleted
                    ? (setWon
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4.sp),
            border: isNextSet
                ? Border.all(color: AppTheme.accentGreen, width: 2)
                : null,
          ),
          child: Row(
            // 왼쪽 팀은 오른쪽 정렬, 오른쪽 팀은 왼쪽 정렬
            mainAxisAlignment: isLeftSide ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isLeftSide) ...[
                // 오른쪽 팀: 승/패 아이콘이 앞에
                if (setCompleted)
                  Container(
                    width: 20.sp,
                    child: Icon(
                      setWon ? Icons.circle : Icons.close,
                      size: 14.sp,
                      color: setWon ? Colors.green : Colors.red,
                    ),
                  ),
                SizedBox(width: 4.sp),
              ],
              // 선수 정보
              if (player != null) ...[
                Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isNextSet ? FontWeight.bold : FontWeight.normal,
                    color: setLost
                        ? AppTheme.textSecondary.withValues(alpha: 0.5)
                        : Colors.white,
                    decoration: setLost ? TextDecoration.lineThrough : null,
                  ),
                ),
                SizedBox(width: 4.sp),
                Text(
                  '(${player.race.code})',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: AppTheme.getRaceColor(player.race.code),
                  ),
                ),
              ] else ...[
                Text(
                  isAceSlot ? 'ACE' : '???',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (isLeftSide) ...[
                // 왼쪽 팀: 승/패 아이콘이 뒤에
                SizedBox(width: 4.sp),
                if (setCompleted)
                  Container(
                    width: 20.sp,
                    child: Icon(
                      setWon ? Icons.circle : Icons.close,
                      size: 14.sp,
                      color: setWon ? Colors.green : Colors.red,
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapList(CurrentMatchState matchState, GameState gameState, int nextSet, bool isAceNext) {
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;

    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final isAceSlot = index == 6;
        final mapId = index < seasonMapIds.length ? seasonMapIds[index] : null;
        final map = mapId != null ? GameMaps.getById(mapId) : null;

        final setCompleted = index < matchState.setResults.length;
        final isNextSet = (isAceNext && isAceSlot) || (!isAceNext && index == nextSet - 1);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.sp),
          padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
          decoration: BoxDecoration(
            color: isNextSet
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Center(
            child: Text(
              isAceSlot ? 'ACE' : (map?.name ?? 'Map ${index + 1}'),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isNextSet ? FontWeight.bold : FontWeight.normal,
                color: setCompleted
                    ? AppTheme.textSecondary.withValues(alpha: 0.5)
                    : isNextSet
                        ? Colors.white
                        : AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAceSelectionScreen(GameState gameState, CurrentMatchState matchState) {
    final teamPlayers = gameState.playerTeamPlayers;
    // 플레이어 팀이 홈인지 확인하여 올바른 로스터 사용
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;
    final playerRoster = isPlayerHome ? matchState.homeRoster : matchState.awayRoster;
    final usedPlayers = playerRoster.whereType<String>().toSet();

    // 사용 가능한 선수 (아직 출전하지 않은 선수)
    final availablePlayers = <int>[];
    for (int i = 0; i < teamPlayers.length; i++) {
      if (!usedPlayers.contains(teamPlayers[i].id)) {
        availablePlayers.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('에이스 결정전'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 상단 정보
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.2),
            child: Column(
              children: [
                const Text(
                  'ACE 결정전 (3:3)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '7세트에 출전할 에이스 선수를 선택하세요',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (availablePlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '(모든 선수가 출전했습니다. 아무 선수나 선택하세요)',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // 선수 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teamPlayers.length,
              itemBuilder: (context, index) {
                final player = teamPlayers[index];
                final isUsed = usedPlayers.contains(player.id);
                final raceCode = player.race.code;
                final gradeString = player.grade.display;

                return Card(
                  color: isUsed
                      ? AppTheme.cardBackground.withOpacity(0.3)
                      : AppTheme.cardBackground,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _selectAcePlayer(index),
                    leading: CircleAvatar(
                      backgroundColor: isUsed
                          ? Colors.grey
                          : AppTheme.getRaceColor(raceCode),
                      child: Text(
                        raceCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        color: isUsed ? AppTheme.textSecondary : AppTheme.textPrimary,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      isUsed ? '이미 출전' : '컨디션: ${player.condition}%',
                      style: TextStyle(
                        color: isUsed ? Colors.red.withOpacity(0.7) : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUsed
                            ? Colors.grey
                            : AppTheme.getGradeColor(gradeString),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        gradeString,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
}

class _PlayerPanel extends StatelessWidget {
  final Player? player;
  final bool isHome;
  final SpecialCondition specialCondition;

  const _PlayerPanel({
    required this.player,
    required this.isHome,
    this.specialCondition = SpecialCondition.none,
  });

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHome ? AppTheme.accentGreen : Colors.red,
            width: 2,
          ),
        ),
        child: const Center(
          child: Text('선수 없음', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final raceCode = player!.race.code;
    final gradeString = player!.grade.display;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHome ? AppTheme.accentGreen : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // 특수 컨디션 아이콘 + 아바타
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.getRaceColor(raceCode),
                child: Text(
                  raceCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              // 특수 컨디션 배지
              if (specialCondition != SpecialCondition.none)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: specialCondition == SpecialCondition.best
                          ? Colors.green
                          : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.priority_high,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            player!.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          // 특수 컨디션 라벨
          if (specialCondition != SpecialCondition.none) ...[
            const SizedBox(height: 2),
            Text(
              specialCondition == SpecialCondition.best ? '컨디션 최상!' : '컨디션 최악',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: specialCondition == SpecialCondition.best
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.getGradeColor(gradeString),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              gradeString,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final String label;
  final int value1;
  final int value2;
  final int maxValue;
  final Color color;

  const _ResourceBar({
    required this.label,
    required this.value1,
    required this.value2,
    required this.maxValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 비율 계산 (최대값 기준)
    final ratio1 = (value1 / maxValue).clamp(0.0, 1.0);
    final ratio2 = (value2 / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Player 1 bar (오른쪽으로)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: ratio1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$value1',
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Player 2 bar (왼쪽으로)
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$value2',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ratio2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
