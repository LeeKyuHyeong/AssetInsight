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
import '../../widgets/player_thumbnail.dart';
import '../../widgets/reset_button.dart';

/// 개인리그 4강 화면 (Bo5, 2경기)
class IndividualSemiFinalScreen extends ConsumerStatefulWidget {
  const IndividualSemiFinalScreen({super.key});

  @override
  ConsumerState<IndividualSemiFinalScreen> createState() =>
      _IndividualSemiFinalScreenState();
}

class _IndividualSemiFinalScreenState
    extends ConsumerState<IndividualSemiFinalScreen> {
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
  List<IndividualMatchResult> _roundResults = [];

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
      final sfCount = bracket.mainTournamentResults
          .where((r) => r.stage == IndividualLeagueStage.semiFinal)
          .length;
      if (sfCount >= 2) {
        _isCompleted = true;
        _roundResults = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.semiFinal)
            .toList();
      }
    }

    final hasMyTeamPlayer = bracket != null &&
        _leagueService.getQuarterFinalAdvancers(bracket).any(
            (id) => _myTeamPlayerIds.contains(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(playerTeam, hasMyTeamPlayer),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 3,
                            child: _buildResultPanel(playerMap)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Team team, bool hasMyTeamPlayer) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
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
              ResetButton.back(fallbackRoute: '/playoff'),
              SizedBox(width: 8.sp),
              _buildTeamLogo(team),
              SizedBox(width: 8.sp),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '개인리그 4강',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'Bo5 (5판 3선승)',
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
              ),
              if (hasMyTeamPlayer)
                _buildSpeedSelector(),
              SizedBox(width: 8.sp),
              const ResetButton(small: true),
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

  Widget _buildResultPanel(Map<String, Player> playerMap) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: _roundResults.isEmpty && !_isCompleted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports,
                      color: Colors.grey[700], size: 40.sp),
                  SizedBox(height: 8.sp),
                  Text(
                    'Start를 눌러 4강 진행',
                    style:
                        TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : _buildSeriesResults(playerMap),
    );
  }

  Widget _buildSeriesResults(Map<String, Player> playerMap) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _roundResults.length; i++) ...[
            _buildSeriesResultCard(_roundResults[i], playerMap, i + 1),
            if (i < _roundResults.length - 1) SizedBox(height: 8.sp),
          ],
        ],
      ),
    );
  }

  Widget _buildSeriesResultCard(
      IndividualMatchResult result,
      Map<String, Player> playerMap,
      int matchNum) {
    final p1 = playerMap[result.player1Id];
    final p2 = playerMap[result.player2Id];
    final isMyP1 = _myTeamPlayerIds.contains(result.player1Id);
    final isMyP2 = _myTeamPlayerIds.contains(result.player2Id);

    return Container(
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6.sp),
        border: (isMyP1 || isMyP2)
            ? Border.all(color: Colors.blue.withOpacity(0.5))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match $matchNum (Bo5)',
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
          SizedBox(height: 4.sp),
          Row(
            children: [
              _buildPlayerName(p1, result.winnerId == result.player1Id,
                  isMyP1),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.sp),
                child: Text(
                  result.seriesScore,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildPlayerName(p2, result.winnerId == result.player2Id,
                  isMyP2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerName(
      Player? player, bool isWinner, bool isMyTeam) {
    if (player == null) {
      return Text('?',
          style: TextStyle(color: Colors.grey, fontSize: 12.sp));
    }
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Padding(
              padding: EdgeInsets.only(right: 4.sp),
              child: Icon(Icons.check,
                  size: 14.sp, color: AppColors.accent),
            ),
          PlayerThumbnail(
            player: player,
            size: 18,
            isMyTeam: isMyTeam,
          ),
          SizedBox(width: 4.sp),
          Flexible(
            child: Text(
              '${player.name} (${player.race.code})',
              style: TextStyle(
                color: isWinner ? Colors.white : Colors.grey[400],
                fontSize: 12.sp,
                fontWeight:
                    isWinner ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
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
            '4강 우리팀 선수 경기만 텍스트 시뮬레이션',
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _currentBattleLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports,
                            color: Colors.grey[700], size: 40.sp),
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
            onPressed: _isSimulating
                ? null
                : () => _isCompleted
                    ? _finish(context)
                    : _startSimulation(bracket, playerMap),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isSimulating ? Colors.grey : AppColors.primary,
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
      _roundResults = [];
      _currentBattleLog = [];
      _statusMessage = '4강 진행 중...';
    });

    final gameState = ref.read(gameStateProvider);
    final playerTeamId = gameState?.playerTeam.id;
    final advancers = _leagueService.getQuarterFinalAdvancers(bracket);

    if (advancers.length < 4) {
      setState(() {
        _isSimulating = false;
        _statusMessage = '8강 결과가 부족합니다';
      });
      return;
    }

    final existingResults =
        List<IndividualMatchResult>.from(bracket.mainTournamentResults);

    for (var i = 0; i < 2 && i * 2 + 1 < advancers.length; i++) {
      final p1Id = advancers[i * 2];
      final p2Id = advancers[i * 2 + 1];
      final p1 = playerMap[p1Id];
      final p2 = playerMap[p2Id];
      if (p1 == null || p2 == null) continue;

      final isMyTeamMatch = _myTeamPlayerIds.contains(p1Id) ||
          _myTeamPlayerIds.contains(p2Id);

      setState(() {
        _statusMessage = '${p1.name} vs ${p2.name}';
      });

      if (isMyTeamMatch) {
        final result =
            await _simulateSeriesWithLog(p1, p2, playerMap, 5);
        existingResults.add(result);
        _roundResults.add(result);
      } else {
        // AI 경기: 빠른 시뮬
        final tempBracket = bracket.copyWith(
            mainTournamentResults: existingResults);
        final updated = _leagueService.simulateSemiFinal(
          bracket: tempBracket,
          playerMap: playerMap,
          playerTeamId: playerTeamId,
        );
        final newResults = updated.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.semiFinal)
            .toList();
        if (newResults.length >
            existingResults
                .where(
                    (r) => r.stage == IndividualLeagueStage.semiFinal)
                .length) {
          existingResults.add(newResults.last);
          _roundResults.add(newResults.last);
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    final updatedBracket =
        bracket.copyWith(mainTournamentResults: existingResults);
    ref
        .read(gameStateProvider.notifier)
        .updateIndividualLeague(updatedBracket);

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
      _statusMessage = '4강 완료';
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
        '=== ${playerMap[winnerId]?.name ?? winnerId} 승리! ($p1Wins:$p2Wins) ===',
      ];
    });

    return IndividualMatchResult(
      id: 'semiFinal_${p1.id}_${p2.id}',
      player1Id: p1.id,
      player2Id: p2.id,
      winnerId: winnerId,
      mapId: sets.first.mapId,
      stageIndex: IndividualLeagueStage.semiFinal.index,
      battleLog: [],
      showBattleLog: true,
      sets: sets,
      bestOf: bestOf,
    );
  }

  void _finish(BuildContext context) {
    // 4강 완료 후 플레이오프 화면으로 복귀
    context.go('/playoff');
  }
}
