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

/// 경기 진행 단계
enum MatchPhase {
  rosterPreview,  // 로스터 확인 화면 (경기 시작 전)
  matchPlaying,   // 경기 진행 중
  aceSelection,   // 에이스 선택 (3:3일 때)
}

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

  // 경기 진행 단계 관리
  MatchPhase _currentPhase = MatchPhase.rosterPreview;

  // 에이스 결정전 관련
  int? selectedAceIndex;

  // 세트 종료 시 결과 표시용
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

    // 처음에는 로스터 확인 화면으로 시작
    setState(() {
      _currentPhase = MatchPhase.rosterPreview;
    });
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

    // 경기가 끝나면 바로 결과 표시 또는 다음 게임으로 진행 (NEXT 한 번으로)
    if (matchState.isMatchEnded) {
      // 매치 종료 → 전체 결과 화면
      _showMatchResult();
    } else if (matchState.isAceMatch && matchState.homeAcePlayerId == null) {
      // 에이스 결정전 진행 필요 → 에이스 선택 화면
      setState(() {
        _currentPhase = MatchPhase.aceSelection;
      });
    } else {
      // 다음 게임 → 로스터 확인 화면
      ref.read(currentMatchProvider.notifier).advanceToNextSet();
      setState(() {
        _currentPhase = MatchPhase.rosterPreview;
        gameEnded = false;
        lastSetHomeWin = null;
      });
    }
  }

  /// 로스터 확인 화면에서 경기 시작
  void _startMatchFromPreview() {
    // 기존 스트림 취소
    _simulationSubscription?.cancel();

    setState(() {
      player1Resource = 100;
      player1Army = 50;
      player2Resource = 100;
      player2Army = 50;
      battleLogEntries.clear();
      gameEnded = false;
      _currentPhase = MatchPhase.matchPlaying;
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
    final selectedPlayer = teamPlayers[playerIndex];

    // 에이스결정전은 전체 선수 중 선택 가능 (중복 출전 체크 없음)

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

    // 다음 세트로 이동 후 로스터 확인 화면으로
    ref.read(currentMatchProvider.notifier).advanceToNextSet();
    setState(() {
      _currentPhase = MatchPhase.rosterPreview;
      gameEnded = false;
      lastSetHomeWin = null;
    });
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

    // 팀 정보 (플레이어 팀이 항상 왼쪽)
    final homeTeam = gameState.saveData.getTeamById(matchState.homeTeamId);
    final awayTeam = gameState.saveData.getTeamById(matchState.awayTeamId);
    final leftTeam = isPlayerHome ? homeTeam : awayTeam;
    final rightTeam = isPlayerHome ? awayTeam : homeTeam;
    final leftScore = isPlayerHome ? matchState.homeScore : matchState.awayScore;
    final rightScore = isPlayerHome ? matchState.awayScore : matchState.homeScore;
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;

    if (!mounted) return;

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
              // 상단: 팀 스코어 (플레이어 팀이 왼쪽)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 내 팀 (왼쪽)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          leftTeam?.name ?? 'MY TEAM',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: leftScore > rightScore
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        if (leftScore > rightScore)
                          Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
                      ],
                    ),
                  ),
                  // 스코어
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                    child: Text(
                      '$leftScore : $rightScore',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ),
                  // 상대 팀 (오른쪽)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (rightScore > leftScore)
                          Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text(
                          rightTeam?.name ?? 'OPPONENT',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: rightScore > leftScore
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

              // 세트별 결과 (플레이어 팀 기준)
              ...List.generate(7, (index) {
                final isAceSet = index == 6;
                final setPlayed = index < matchState.setResults.length;

                // 선수 정보 (플레이어 팀이 왼쪽)
                Player? leftPlayer;
                Player? rightPlayer;
                if (isAceSet) {
                  final homeAce = _getPlayerById(matchState.homeAcePlayerId);
                  final awayAce = _getPlayerById(matchState.awayAcePlayerId);
                  leftPlayer = isPlayerHome ? homeAce : awayAce;
                  rightPlayer = isPlayerHome ? awayAce : homeAce;
                } else {
                  final homeP = index < matchState.homeRoster.length
                      ? _getPlayerById(matchState.homeRoster[index])
                      : null;
                  final awayP = index < matchState.awayRoster.length
                      ? _getPlayerById(matchState.awayRoster[index])
                      : null;
                  leftPlayer = isPlayerHome ? homeP : awayP;
                  rightPlayer = isPlayerHome ? awayP : homeP;
                }

                // 맵 정보
                final mapId = index < seasonMapIds.length ? seasonMapIds[index] : null;
                final map = mapId != null ? GameMaps.getById(mapId) : null;
                final mapName = map?.name ?? (isAceSet ? 'ACE' : 'Map ${index + 1}');

                // 승패 결과 (플레이어 팀 기준)
                bool? leftWin;
                if (setPlayed) {
                  final homeWin = matchState.setResults[index];
                  leftWin = isPlayerHome ? homeWin : !homeWin;
                }

                // ACE 매치가 없으면 [ACE] 표시
                final aceNotPlayed = isAceSet && !setPlayed;

                return _buildMatchResultRow(
                  setNumber: index + 1,
                  homePlayer: leftPlayer,
                  awayPlayer: rightPlayer,
                  mapName: mapName,
                  homeWin: leftWin,
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
    if (_currentPhase == MatchPhase.aceSelection) {
      return _buildAceSelectionScreen(gameState, matchState);
    }

    // 로스터 확인 화면
    if (_currentPhase == MatchPhase.rosterPreview) {
      return _buildRosterPreviewScreen(gameState, matchState);
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
                    color: Colors.black.withValues(alpha: 0.5),
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
        ],
      ),
    );
  }

  /// 로스터 확인 화면 (경기 시작 전)
  Widget _buildRosterPreviewScreen(GameState gameState, CurrentMatchState matchState) {
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

    // 다음 세트 번호
    final nextSet = matchState.currentSet;
    final isAceSet = matchState.isAceMatch;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('로스터 확인'),
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
      body: SafeArea(
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
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, color: AppTheme.textSecondary, size: 24.sp),
                  SizedBox(width: 8.sp),
                  Text(
                    isAceSet ? 'ACE Set' : 'Set ${nextSet + 1}',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: isAceSet ? Colors.orange : Colors.white,
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
                child: _buildFullBracketForPreview(matchState, gameState, nextSet, isAceSet),
              ),
            ),

            // 하단: Next 버튼 (경기 시작)
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startMatchFromPreview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16.sp),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAceSet ? 'ACE 결정전 시작' : '${nextSet + 1}세트 시작',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.sp),
                      Icon(Icons.play_arrow, size: 20.sp),
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

  /// 로스터 확인용 대진표 (현재 세트 하이라이트)
  Widget _buildFullBracketForPreview(CurrentMatchState matchState, GameState gameState, int currentSet, bool isAceSet) {
    // 플레이어 팀 기준으로 좌우 배치
    final isPlayerHome = matchState.homeTeamId == gameState.playerTeam.id;

    return Row(
      children: [
        // 내 팀 선수 목록 (왼쪽)
        Expanded(
          child: _buildTeamRosterForPreview(
            matchState: matchState,
            gameState: gameState,
            isHome: isPlayerHome,
            isLeftSide: true,
            currentSet: currentSet,
            isAceSet: isAceSet,
          ),
        ),
        // 중앙: 맵 목록
        SizedBox(
          width: 100.sp,
          child: _buildMapListForPreview(matchState, gameState, currentSet, isAceSet),
        ),
        // 상대 팀 선수 목록 (오른쪽)
        Expanded(
          child: _buildTeamRosterForPreview(
            matchState: matchState,
            gameState: gameState,
            isHome: !isPlayerHome,
            isLeftSide: false,
            currentSet: currentSet,
            isAceSet: isAceSet,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRosterForPreview({
    required CurrentMatchState matchState,
    required GameState gameState,
    required bool isHome,
    required bool isLeftSide,
    required int currentSet,
    required bool isAceSet,
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

        // 현재 세트인지 하이라이트
        final isCurrentSet = (isAceSet && isAceSlot) || (!isAceSet && index == currentSet);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.sp),
          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
          decoration: BoxDecoration(
            color: isCurrentSet
                ? AppTheme.accentGreen.withValues(alpha: 0.2)
                : setCompleted
                    ? (setWon
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4.sp),
            border: isCurrentSet
                ? Border.all(color: AppTheme.accentGreen, width: 2)
                : null,
          ),
          child: Row(
            mainAxisAlignment: isLeftSide ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isLeftSide) ...[
                if (setCompleted)
                  SizedBox(
                    width: 20.sp,
                    child: Icon(
                      setWon ? Icons.circle : Icons.close,
                      size: 14.sp,
                      color: setWon ? Colors.green : Colors.red,
                    ),
                  ),
                SizedBox(width: 4.sp),
              ],
              if (player != null) ...[
                Text(
                  player.name,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isCurrentSet ? FontWeight.bold : FontWeight.normal,
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
                SizedBox(width: 4.sp),
                if (setCompleted)
                  SizedBox(
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

  Widget _buildMapListForPreview(CurrentMatchState matchState, GameState gameState, int currentSet, bool isAceSet) {
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;

    return ListView.builder(
      itemCount: 7,
      itemBuilder: (context, index) {
        final isAceSlot = index == 6;
        final mapId = index < seasonMapIds.length ? seasonMapIds[index] : null;
        final map = mapId != null ? GameMaps.getById(mapId) : null;

        final setCompleted = index < matchState.setResults.length;
        final isCurrentSet = (isAceSet && isAceSlot) || (!isAceSet && index == currentSet);

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.sp),
          padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
          decoration: BoxDecoration(
            color: isCurrentSet
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Center(
            child: Text(
              isAceSlot ? 'ACE' : (map?.name ?? 'Map ${index + 1}'),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: isCurrentSet ? FontWeight.bold : FontWeight.normal,
                color: setCompleted
                    ? AppTheme.textSecondary.withValues(alpha: 0.5)
                    : isCurrentSet
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

  Widget _buildAceSelectionScreen(GameState gameState, CurrentMatchState matchState) {
    final teamPlayers = gameState.playerTeamPlayers;

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
            color: Colors.orange.withValues(alpha: 0.2),
            child: const Column(
              children: [
                Text(
                  'ACE 결정전 (3:3)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '7세트에 출전할 에이스 선수를 선택하세요\n(전체 선수 중 선택 가능)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
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
                final playerRaceCode = player.race.code;
                final gradeString = player.grade.display;

                return Card(
                  color: AppTheme.cardBackground,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _selectAcePlayer(index),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.getRaceColor(playerRaceCode),
                      child: Text(
                        playerRaceCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '컨디션: ${player.condition}%',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.getGradeColor(gradeString),
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
                              color: color.withValues(alpha: 0.8),
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
                              color: color.withValues(alpha: 0.8),
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
