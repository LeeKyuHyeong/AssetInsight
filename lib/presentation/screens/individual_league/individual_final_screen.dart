import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../domain/services/match_simulation_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 개인리그 결승 화면 (Bo7, 1경기)
class IndividualFinalScreen extends ConsumerStatefulWidget {
  const IndividualFinalScreen({super.key});

  @override
  ConsumerState<IndividualFinalScreen> createState() =>
      _IndividualFinalScreenState();
}

class _IndividualFinalScreenState
    extends ConsumerState<IndividualFinalScreen> {
  final MatchSimulationService _matchService = MatchSimulationService();
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  static MatchSpeed _loadMatchSpeed() {
    final saved =
        Hive.box('settings').get('matchSpeed', defaultValue: 1) as int;
    return MatchSpeed.values.firstWhere(
      (s) => s.multiplier == saved,
      orElse: () => MatchSpeed.x1,
    );
  }

  bool _isSimulating = false;
  bool _isCompleted = false;
  String _statusMessage = '';
  List<String> _currentBattleLog = [];
  late MatchSpeed _matchSpeed = _loadMatchSpeed();
  Set<String> _myTeamPlayerIds = {};
  IndividualMatchResult? _finalResult;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerTeam = gameState.playerTeam;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    _myTeamPlayerIds = gameState.saveData
        .getTeamPlayers(playerTeam.id)
        .map((p) => p.id)
        .toSet();

    // 이미 완료되었는지 확인
    if (bracket != null && !_isSimulating) {
      if (bracket.championId != null) {
        _isCompleted = true;
        final finalResults = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.final_)
            .toList();
        if (finalResults.isNotEmpty) {
          _finalResult = finalResults.first;
        }
      }
    }

    final hasMyTeamPlayer = bracket != null &&
        _leagueService.getSemiFinalAdvancers(bracket).any(
            (id) => _myTeamPlayerIds.contains(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(playerTeam, hasMyTeamPlayer, bracket, playerMap),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: _buildResultPanel(bracket, playerMap)),
                        SizedBox(width: 16.sp),
                        SizedBox(
                            width: 300.sp,
                            child: _buildBattleLogPanel()),
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

  Widget _buildHeader(Team team, bool hasMyTeamPlayer,
      IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
            bottom:
                BorderSide(color: AppColors.primary.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildTeamLogo(team),
              const Spacer(),
              Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events,
                          color: Colors.amber, size: 24.sp),
                      SizedBox(width: 8.sp),
                      Text(
                        '개인리그 결승',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Bo7 (7판 4선승)',
                    style: TextStyle(
                        color: AppColors.accent, fontSize: 12.sp),
                  ),
                  if (_statusMessage.isNotEmpty)
                    Text(
                      _statusMessage,
                      style:
                          TextStyle(color: Colors.grey, fontSize: 11.sp),
                    ),
                ],
              ),
              const Spacer(),
              hasMyTeamPlayer
                  ? _buildSpeedSelector()
                  : SizedBox(width: 60.sp),
            ],
          ),
          if (!hasMyTeamPlayer) ...[
            SizedBox(height: 8.sp),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility,
                      color: Colors.orange, size: 16.sp),
                  SizedBox(width: 6.sp),
                  Text(
                    '관전 모드 - 우리 팀 선수 없음',
                    style: TextStyle(
                        color: Colors.orange, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
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
          Text('배속: ',
              style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          ...MatchSpeed.values.map((speed) {
            final isSelected = _matchSpeed == speed;
            return GestureDetector(
              onTap: () {
                setState(() => _matchSpeed = speed);
                Hive.box('settings').put('matchSpeed', speed.multiplier);
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 2.sp),
                padding: EdgeInsets.symmetric(
                    horizontal: 8.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Text(
                  'x${speed.multiplier}',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 11.sp,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildResultPanel(
      IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: _finalResult == null && !_isCompleted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events,
                      color: Colors.amber.withOpacity(0.3), size: 60.sp),
                  SizedBox(height: 8.sp),
                  Text(
                    'Start를 눌러 결승 진행',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : _buildFinalResultDisplay(bracket, playerMap),
    );
  }

  Widget _buildFinalResultDisplay(
      IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    if (_finalResult == null) return const SizedBox.shrink();

    final result = _finalResult!;
    final p1 = playerMap[result.player1Id];
    final p2 = playerMap[result.player2Id];
    final winner = playerMap[result.winnerId];
    final isMyP1 = _myTeamPlayerIds.contains(result.player1Id);
    final isMyP2 = _myTeamPlayerIds.contains(result.player2Id);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16.sp),
          // 우승자 표시
          if (winner != null) ...[
            Icon(Icons.emoji_events, color: Colors.amber, size: 48.sp),
            SizedBox(height: 8.sp),
            Text(
              '개인리그 챔피언',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4.sp),
            Text(
              '${winner.name} (${winner.race.code})',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24.sp),
          ],
          // 매치 결과 카드
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.withOpacity(0.1),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: Colors.amber.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Text(
                  '결승전 (Bo7)',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12.sp),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildFinalPlayerBox(p1, result.winnerId == result.player1Id, isMyP1),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.sp),
                      child: Text(
                        result.seriesScore,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildFinalPlayerBox(p2, result.winnerId == result.player2Id, isMyP2),
                  ],
                ),
              ],
            ),
          ),
          // 세트별 결과
          if (result.sets.isNotEmpty) ...[
            SizedBox(height: 16.sp),
            ...result.sets.asMap().entries.map((entry) {
              final i = entry.key;
              final set = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 4.sp),
                padding: EdgeInsets.symmetric(
                    vertical: 4.sp, horizontal: 8.sp),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50.sp,
                      child: Text('Set ${i + 1}',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 11.sp)),
                    ),
                    Expanded(
                      child: Text(
                        p1?.name ?? set.homePlayerId,
                        style: TextStyle(
                          color: set.homeWin
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 11.sp,
                          fontWeight: set.homeWin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.sp),
                      child: Text(
                        set.homeWin ? 'WIN' : 'LOSE',
                        style: TextStyle(
                          color: set.homeWin
                              ? AppColors.accent
                              : Colors.red[300],
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p2?.name ?? set.awayPlayerId,
                        style: TextStyle(
                          color: !set.homeWin
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 11.sp,
                          fontWeight: !set.homeWin
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildFinalPlayerBox(
      Player? player, bool isWinner, bool isMyTeam) {
    if (player == null) {
      return Container(
        width: 100.sp,
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Text('?',
            style: TextStyle(color: Colors.grey, fontSize: 14.sp),
            textAlign: TextAlign.center),
      );
    }

    return Container(
      width: 100.sp,
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.amber.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: isWinner ? Colors.amber : Colors.grey.withOpacity(0.3),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isWinner)
            Icon(Icons.emoji_events,
                color: Colors.amber, size: 20.sp),
          Text(
            player.name,
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.grey,
              fontSize: 13.sp,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            player.race.code,
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
          if (isMyTeam)
            Container(
              margin: EdgeInsets.only(top: 4.sp),
              padding: EdgeInsets.symmetric(
                  horizontal: 4.sp, vertical: 1.sp),
              decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2.sp)),
              child: Text('MY',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 7.sp,
                      fontWeight: FontWeight.bold)),
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
              Icon(Icons.list_alt,
                  color: AppColors.accent, size: 18.sp),
              SizedBox(width: 8.sp),
              Text(
                '경기 로그',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4.sp),
          Text(
            '결승 우리팀 선수 경기 텍스트 시뮬레이션',
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _currentBattleLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events,
                            color: Colors.amber.withOpacity(0.2),
                            size: 40.sp),
                        SizedBox(height: 8.sp),
                        Text(
                          _isSimulating ? '경기 진행중...' : 'Start를 눌러 시작',
                          style: TextStyle(
                              color: Colors.grey, fontSize: 12.sp),
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
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                context.go('/playoff');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(
                  horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back,
                    color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text('EXIT',
                    style: TextStyle(
                        color: Colors.white, fontSize: 14.sp)),
              ],
            ),
          ),
          SizedBox(width: 24.sp),
          ElevatedButton(
            onPressed: _isSimulating
                ? null
                : () => _isCompleted
                    ? _finish(context)
                    : _startSimulation(bracket, playerMap),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isSimulating ? Colors.grey : Colors.amber,
              padding: EdgeInsets.symmetric(
                  horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Finish' : 'Start',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14.sp),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.arrow_forward,
                    color: Colors.white, size: 16.sp),
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
    if (bracket == null) return;

    setState(() {
      _isSimulating = true;
      _finalResult = null;
      _currentBattleLog = [];
      _statusMessage = '결승 진행 중...';
    });

    final gameState = ref.read(gameStateProvider);
    final playerTeamId = gameState?.playerTeam.id;
    final finalists = _leagueService.getSemiFinalAdvancers(bracket);

    if (finalists.length < 2) {
      setState(() {
        _isSimulating = false;
        _statusMessage = '4강 결과가 부족합니다';
      });
      return;
    }

    final p1Id = finalists[0];
    final p2Id = finalists[1];
    final p1 = playerMap[p1Id];
    final p2 = playerMap[p2Id];

    if (p1 == null || p2 == null) {
      setState(() {
        _isSimulating = false;
        _statusMessage = '선수 정보를 찾을 수 없습니다';
      });
      return;
    }

    final isMyTeamMatch = _myTeamPlayerIds.contains(p1Id) ||
        _myTeamPlayerIds.contains(p2Id);

    setState(() {
      _statusMessage = '${p1.name} vs ${p2.name}';
    });

    IndividualLeagueBracket updatedBracket;

    if (isMyTeamMatch) {
      final result =
          await _simulateSeriesWithLog(p1, p2, playerMap, 7);
      final existingResults =
          List<IndividualMatchResult>.from(bracket.mainTournamentResults);
      existingResults.add(result);

      final top8 = bracket.top8Players.isNotEmpty
          ? bracket.top8Players
          : _leagueService.getRound16Advancers(bracket);

      updatedBracket = bracket.copyWith(
        mainTournamentResults: existingResults,
        championId: result.winnerId,
        runnerUpId: result.loserId,
        top8Players: top8,
      );
      _finalResult = result;
    } else {
      // AI 경기
      updatedBracket = _leagueService.simulateFinal(
        bracket: bracket,
        playerMap: playerMap,
        playerTeamId: playerTeamId,
      );
      final finalResults = updatedBracket.mainTournamentResults
          .where((r) => r.stage == IndividualLeagueStage.final_)
          .toList();
      if (finalResults.isNotEmpty) {
        _finalResult = finalResults.first;
      }
    }

    ref
        .read(gameStateProvider.notifier)
        .updateIndividualLeague(updatedBracket);

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
      _statusMessage = '결승 완료';
    });
  }

  Future<IndividualMatchResult> _simulateSeriesWithLog(
    Player p1,
    Player p2,
    Map<String, Player> playerMap,
    int bestOf,
  ) async {
    final maps = GameMaps.all;
    final winsNeeded = (bestOf + 1) ~/ 2;
    int p1Wins = 0;
    int p2Wins = 0;
    final sets = <SetResult>[];

    while (p1Wins < winsNeeded && p2Wins < winsNeeded) {
      final setNum = p1Wins + p2Wins + 1;
      final map = maps[(setNum - 1) % maps.length];

      setState(() {
        _currentBattleLog = [
          ...(_currentBattleLog.isNotEmpty
              ? [..._currentBattleLog, '', '---', '']
              : []),
          'Set $setNum / ${p1.name} vs ${p2.name} ($p1Wins:$p2Wins)',
        ];
      });

      final stream = _matchService.simulateMatchWithLog(
        homePlayer: p1,
        awayPlayer: p2,
        map: map,
        getIntervalMs: () => _matchSpeed.intervalMs,
      );

      SetResult? setResult;
      await for (final state in stream) {
        if (!mounted) break;
        setState(() {
          _currentBattleLog = [
            ...(_currentBattleLog.take(_currentBattleLog.length).toList()),
            ...state.battleLog.skip(0),
          ];
        });
        if (state.isFinished && state.homeWin != null) {
          setResult = SetResult(
            mapId: map.id,
            homePlayerId: p1.id,
            awayPlayerId: p2.id,
            homeWin: state.homeWin!,
            battleLog: state.battleLog,
            finalHomeArmy: state.homeArmy,
            finalAwayArmy: state.awayArmy,
            finalHomeResources: state.homeResources,
            finalAwayResources: state.awayResources,
          );
        }
      }

      if (setResult != null) {
        sets.add(setResult);
        if (setResult.homeWin) {
          p1Wins++;
        } else {
          p2Wins++;
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }

    final winnerId = p1Wins > p2Wins ? p1.id : p2.id;

    setState(() {
      _currentBattleLog = [
        ..._currentBattleLog,
        '',
        '=== ${playerMap[winnerId]?.name ?? winnerId} 우승! ($p1Wins:$p2Wins) ===',
      ];
    });

    return IndividualMatchResult(
      id: 'final_${p1.id}_${p2.id}',
      player1Id: p1.id,
      player2Id: p2.id,
      winnerId: winnerId,
      mapId: sets.first.mapId,
      stageIndex: IndividualLeagueStage.final_.index,
      battleLog: [],
      showBattleLog: true,
      sets: sets,
      bestOf: bestOf,
    );
  }

  void _finish(BuildContext context) {
    context.go('/playoff');
  }
}
