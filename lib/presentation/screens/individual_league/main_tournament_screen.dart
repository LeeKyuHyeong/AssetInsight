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

/// 본선 토너먼트 화면 (32강/16강/8강 - stage별 분기)
class MainTournamentScreen extends ConsumerStatefulWidget {
  final String stage; // '32', '16', '8'
  final bool viewOnly;

  const MainTournamentScreen({super.key, this.stage = '32', this.viewOnly = false});

  @override
  ConsumerState<MainTournamentScreen> createState() =>
      _MainTournamentScreenState();
}

class _MainTournamentScreenState extends ConsumerState<MainTournamentScreen> {
  final MatchSimulationService _matchService = MatchSimulationService();
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  static MatchSpeed _loadMatchSpeed() {
    final saved = Hive.box('settings').get('matchSpeed', defaultValue: 1) as int;
    return MatchSpeed.values.firstWhere(
      (s) => s.multiplier == saved,
      orElse: () => MatchSpeed.x1,
    );
  }

  bool _isSimulating = false;
  bool _isCompleted = false;
  String _statusMessage = '';

  // 현재 보고 있는 경기 로그
  List<String> _currentBattleLog = [];

  // 배속 설정
  late MatchSpeed _matchSpeed = _loadMatchSpeed();

  // 내 팀 선수 ID 목록
  Set<String> _myTeamPlayerIds = {};

  // 관전 모드
  bool _isSpectatorMode = false;

  // 현재 라운드의 결과 (UI 표시용)
  List<IndividualMatchResult> _roundResults = [];

  String get _stageLabel {
    switch (widget.stage) {
      case '32': return '32강';
      case '16': return '16강';
      case '8': return '8강';
      default: return '본선';
    }
  }

  String get _formatLabel {
    switch (widget.stage) {
      case '32': return '듀얼토너먼트';
      case '16': return 'Bo3 (3판 2선승)';
      case '8': return 'Bo5 (5판 3선승)';
      default: return '';
    }
  }

  /// 현재 진행할 half (1 or 2) 결정
  int _getCurrentHalf(IndividualLeagueBracket bracket) {
    switch (widget.stage) {
      case '32':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.round32)
            .length;
        return count < 20 ? 1 : 2; // 4조 × 5경기 = 20
      case '16':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.round16)
            .length;
        return count < 4 ? 1 : 2;
      case '8':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.quarterFinal)
            .length;
        return count < 2 ? 1 : 2;
      default:
        return 1;
    }
  }

  /// 현재 half가 이미 완료되었는지 확인
  bool _isHalfCompleted(IndividualLeagueBracket bracket) {
    switch (widget.stage) {
      case '32':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.round32)
            .length;
        final half = _getCurrentHalf(bracket);
        return half == 1 ? count >= 20 : count >= 40;
      case '16':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.round16)
            .length;
        final half = _getCurrentHalf(bracket);
        return half == 1 ? count >= 4 : count >= 8;
      case '8':
        final count = bracket.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.quarterFinal)
            .length;
        final half = _getCurrentHalf(bracket);
        return half == 1 ? count >= 2 : count >= 4;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerTeam = gameState.playerTeam;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    _myTeamPlayerIds = gameState.saveData.getTeamPlayers(playerTeam.id).map((p) => p.id).toSet();

    final mainTournamentPlayers = bracket?.mainTournamentPlayers ?? [];
    final hasMyTeamPlayer = mainTournamentPlayers.any((id) => _myTeamPlayerIds.contains(id));
    _isSpectatorMode = !hasMyTeamPlayer;

    // viewOnly이거나 이미 완료된 half면 완료 표시
    if (bracket != null && !_isSimulating) {
      _isCompleted = widget.viewOnly || _isHalfCompleted(bracket);
      if (_isCompleted) {
        _loadExistingResults(bracket);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, playerTeam, bracket),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: widget.stage == '8'
                        ? Row(
                            children: [
                              Expanded(flex: 3, child: _buildResultPanel(bracket, playerMap)),
                              SizedBox(width: 16.sp),
                              SizedBox(width: 300.sp, child: _buildBattleLogPanel()),
                            ],
                          )
                        : _buildResultPanel(bracket, playerMap),
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

  void _loadExistingResults(IndividualLeagueBracket bracket) {
    final stage = widget.stage == '32'
        ? IndividualLeagueStage.round32
        : widget.stage == '16'
            ? IndividualLeagueStage.round16
            : IndividualLeagueStage.quarterFinal;

    _roundResults = bracket.mainTournamentResults
        .where((r) => r.stage == stage)
        .toList();
  }

  Widget _buildHeader(BuildContext context, Team team, IndividualLeagueBracket? bracket) {
    final half = bracket != null ? _getCurrentHalf(bracket) : 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildTeamLogo(team),
              const Spacer(),
              Column(
                children: [
                  Text(
                    '개인리그 $_stageLabel #$half',
                    style: TextStyle(
                      color: Colors.white, fontSize: 22.sp,
                      fontWeight: FontWeight.bold, letterSpacing: 2,
                    ),
                  ),
                  Text(
                    _formatLabel,
                    style: TextStyle(color: AppColors.accent, fontSize: 12.sp),
                  ),
                  if (_statusMessage.isNotEmpty)
                    Text(
                      _statusMessage,
                      style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                    ),
                ],
              ),
              const Spacer(),
              if (widget.stage == '8' && !_isSpectatorMode)
                _buildSpeedSelector()
              else
                SizedBox(width: 60.sp),
            ],
          ),
          if (_isSpectatorMode) ...[
            SizedBox(height: 8.sp),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility, color: Colors.orange, size: 16.sp),
                  SizedBox(width: 6.sp),
                  Text(
                    '관전 모드 - 우리 팀 선수 없음',
                    style: TextStyle(color: Colors.orange, fontSize: 12.sp),
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
      width: 60.sp, height: 40.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Color(team.colorValue)),
      ),
      child: Center(
        child: Text(
          team.shortName,
          style: TextStyle(
            color: Color(team.colorValue), fontWeight: FontWeight.bold, fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: Colors.grey[800], borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('배속: ', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          ...MatchSpeed.values.map((speed) {
            final isSelected = _matchSpeed == speed;
            return GestureDetector(
              onTap: () {
                setState(() => _matchSpeed = speed);
                Hive.box('settings').put('matchSpeed', speed.multiplier);
              },
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

  /// 결과 패널 (stage별 분기)
  Widget _buildResultPanel(IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
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
                  Icon(Icons.sports_esports, color: Colors.grey[700], size: 40.sp),
                  SizedBox(height: 8.sp),
                  Text(
                    'Start를 눌러 ${_stageLabel} 진행',
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ],
              ),
            )
          : widget.stage == '32'
              ? _buildRound32Results(bracket, playerMap)
              : _buildSeriesResults(playerMap),
    );
  }

  /// 32강 결과: 듀얼토너먼트 조별 결과
  Widget _buildRound32Results(IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    // 5경기씩 그룹으로 묶어서 표시
    final groupCount = (_roundResults.length / 5).ceil();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var gi = 0; gi < groupCount; gi++) ...[
            _buildDualGroupResult(gi, playerMap, bracket),
            if (gi < groupCount - 1) Divider(color: Colors.grey[800], height: 16.sp),
          ],
        ],
      ),
    );
  }

  Widget _buildDualGroupResult(int groupIdx, Map<String, Player> playerMap, IndividualLeagueBracket? bracket) {
    final start = groupIdx * 5;
    if (start + 4 >= _roundResults.length) return const SizedBox.shrink();

    final half = bracket != null ? _getCurrentHalf(bracket) : 1;
    final actualGroupIdx = (half - 1) * 4 + groupIdx;
    final groupLabel = String.fromCharCode('A'.codeUnitAt(0) + actualGroupIdx);

    final match1 = _roundResults[start];
    final match2 = _roundResults[start + 1];
    final winnersMatch = _roundResults[start + 2];
    final losersMatch = _roundResults[start + 3];
    final finalMatch = _roundResults[start + 4];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$groupLabel조',
          style: TextStyle(color: AppColors.accent, fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4.sp),
        _buildMatchRow('1경기', match1, playerMap),
        _buildMatchRow('2경기', match2, playerMap),
        _buildMatchRow('승자전', winnersMatch, playerMap, highlight: true),
        _buildMatchRow('패자전', losersMatch, playerMap),
        _buildMatchRow('최종전', finalMatch, playerMap, highlight: true),
        SizedBox(height: 4.sp),
        Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.green, size: 14.sp),
            SizedBox(width: 4.sp),
            Text(
              '진출: ${_getPlayerName(winnersMatch.winnerId, playerMap)}, ${_getPlayerName(finalMatch.winnerId, playerMap)}',
              style: TextStyle(color: Colors.green, fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  /// 16강/8강 시리즈 결과
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

  Widget _buildSeriesResultCard(IndividualMatchResult result, Map<String, Player> playerMap, int matchNum) {
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
            'Match $matchNum (Bo${result.bestOf})',
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
          SizedBox(height: 4.sp),
          Row(
            children: [
              _buildSeriesPlayerName(p1, result.winnerId == result.player1Id, isMyP1),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.sp),
                child: Text(
                  result.bestOf > 1 ? result.seriesScore : (result.winnerId == result.player1Id ? 'WIN' : 'LOSE'),
                  style: TextStyle(
                    color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSeriesPlayerName(p2, result.winnerId == result.player2Id, isMyP2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesPlayerName(Player? player, bool isWinner, bool isMyTeam) {
    if (player == null) return Text('?', style: TextStyle(color: Colors.grey, fontSize: 12.sp));
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            Padding(
              padding: EdgeInsets.only(right: 4.sp),
              child: Icon(Icons.check, size: 14.sp, color: AppColors.accent),
            ),
          if (isMyTeam && !isWinner)
            Container(
              margin: EdgeInsets.only(right: 4.sp),
              padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 1.sp),
              decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(2.sp)),
              child: Text('MY', style: TextStyle(color: Colors.white, fontSize: 7.sp, fontWeight: FontWeight.bold)),
            ),
          Flexible(
            child: Text(
              '${player.name} (${player.race.code})',
              style: TextStyle(
                color: isWinner ? Colors.white : Colors.grey[400],
                fontSize: 12.sp,
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRow(String label, IndividualMatchResult result, Map<String, Player> playerMap, {bool highlight = false}) {
    final isMyP1 = _myTeamPlayerIds.contains(result.player1Id);
    final isMyP2 = _myTeamPlayerIds.contains(result.player2Id);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.sp, horizontal: 4.sp),
      margin: EdgeInsets.only(bottom: 2.sp),
      decoration: BoxDecoration(
        color: highlight ? AppColors.accent.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(2.sp),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50.sp,
            child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
          ),
          Expanded(
            child: Text(
              _getPlayerName(result.player1Id, playerMap),
              style: TextStyle(
                color: result.winnerId == result.player1Id ? Colors.white : Colors.grey,
                fontSize: 11.sp,
                fontWeight: result.winnerId == result.player1Id || isMyP1 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(' vs ', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
          Expanded(
            child: Text(
              _getPlayerName(result.player2Id, playerMap),
              style: TextStyle(
                color: result.winnerId == result.player2Id ? Colors.white : Colors.grey,
                fontSize: 11.sp,
                fontWeight: result.winnerId == result.player2Id || isMyP2 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _getPlayerName(String playerId, Map<String, Player> playerMap) {
    final player = playerMap[playerId];
    if (player == null) return playerId;
    return '${player.name}(${player.race.code})';
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
                style: TextStyle(color: AppColors.accent, fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 4.sp),
          Text(
            '8강 우리팀 선수 경기만 텍스트 시뮬레이션',
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: _currentBattleLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sports_esports, color: Colors.grey[700], size: 40.sp),
                        SizedBox(height: 8.sp),
                        Text(
                          _isSimulating ? '경기 진행중...' : 'Start를 눌러 시작',
                          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
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
    if (log.contains('승리') || log.contains('GG')) return AppColors.accent;
    if (log.contains('공격') || log.contains('러쉬')) return Colors.red[300]!;
    if (log.contains('수비') || log.contains('방어')) return Colors.blue[300]!;
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
                context.go('/main');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text('EXIT', style: TextStyle(color: Colors.white, fontSize: 14.sp)),
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
              backgroundColor: _isSimulating ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Finish' : 'Start',
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
    if (bracket == null) return;

    setState(() {
      _isSimulating = true;
      _roundResults = [];
      _currentBattleLog = [];
    });

    final gameState = ref.read(gameStateProvider);
    final playerTeamId = gameState?.playerTeam.id;
    final half = _getCurrentHalf(bracket);

    setState(() {
      _statusMessage = '#$half 진행 중...';
    });

    IndividualLeagueBracket updatedBracket;

    switch (widget.stage) {
      case '32':
        updatedBracket = _leagueService.simulateRound32Half(
          bracket: bracket, playerMap: playerMap, half: half,
        );
        break;
      case '16':
        updatedBracket = _leagueService.simulateRound16Half(
          bracket: bracket, playerMap: playerMap, half: half,
          playerTeamId: playerTeamId,
        );
        break;
      case '8':
        // 8강은 우리팀 경기만 battle log 표시
        updatedBracket = await _simulate8GangHalf(bracket, playerMap, half, playerTeamId);
        break;
      default:
        updatedBracket = bracket;
    }

    // 결과 저장
    ref.read(gameStateProvider.notifier).updateIndividualLeague(updatedBracket);

    // UI에 표시할 결과 로드
    final stage = widget.stage == '32'
        ? IndividualLeagueStage.round32
        : widget.stage == '16'
            ? IndividualLeagueStage.round16
            : IndividualLeagueStage.quarterFinal;

    _roundResults = updatedBracket.mainTournamentResults
        .where((r) => r.stage == stage)
        .toList();

    // 현재 half에 해당하는 결과만 표시
    if (widget.stage == '32') {
      final start = (half - 1) * 20;
      final end = half * 20;
      if (_roundResults.length >= end) {
        _roundResults = _roundResults.sublist(start, end);
      } else if (_roundResults.length > start) {
        _roundResults = _roundResults.sublist(start);
      }
    } else if (widget.stage == '16') {
      final start = (half - 1) * 4;
      final end = half * 4;
      if (_roundResults.length >= end) {
        _roundResults = _roundResults.sublist(start, end);
      } else if (_roundResults.length > start) {
        _roundResults = _roundResults.sublist(start);
      }
    } else {
      final start = (half - 1) * 2;
      final end = half * 2;
      if (_roundResults.length >= end) {
        _roundResults = _roundResults.sublist(start, end);
      } else if (_roundResults.length > start) {
        _roundResults = _roundResults.sublist(start);
      }
    }

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
      _statusMessage = '#$half 완료';
    });
  }

  /// 8강 시뮬레이션 (우리팀 경기는 텍스트 로그 표시)
  Future<IndividualLeagueBracket> _simulate8GangHalf(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int half,
    String? playerTeamId,
  ) async {
    final existingResults = List<IndividualMatchResult>.from(bracket.mainTournamentResults);
    final advancers = _leagueService.getRound16Advancers(bracket);
    if (advancers.length < 8) return bracket;

    final top8Players = bracket.top8Players.isNotEmpty
        ? bracket.top8Players
        : List<String>.from(advancers.take(8));

    final startIdx = (half - 1) * 2;

    for (var i = startIdx; i < startIdx + 2 && i * 2 + 1 < advancers.length; i++) {
      final p1Id = advancers[i * 2];
      final p2Id = advancers[i * 2 + 1];
      final p1 = playerMap[p1Id]!;
      final p2 = playerMap[p2Id]!;
      final isMyTeamMatch = _myTeamPlayerIds.contains(p1Id) || _myTeamPlayerIds.contains(p2Id);

      setState(() {
        _statusMessage = '${p1.name} vs ${p2.name}';
      });

      if (isMyTeamMatch) {
        // 우리팀 경기: Bo5 텍스트 시뮬레이션
        final result = await _simulateBo5WithLog(p1, p2, playerMap);
        existingResults.add(result);
      } else {
        // 다른 팀 경기: 빠른 시뮬
        final result = _leagueService.simulateQuarterFinalHalf(
          bracket: bracket.copyWith(mainTournamentResults: existingResults, top8Players: top8Players),
          playerMap: playerMap, half: half, playerTeamId: playerTeamId,
        );
        // 새로 추가된 결과만 가져옴
        final newResults = result.mainTournamentResults
            .where((r) => r.stage == IndividualLeagueStage.quarterFinal)
            .toList();
        if (newResults.length > existingResults.where((r) => r.stage == IndividualLeagueStage.quarterFinal).length) {
          existingResults.add(newResults.last);
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    return bracket.copyWith(
      mainTournamentResults: existingResults,
      top8Players: top8Players,
    );
  }

  /// Bo5 텍스트 시뮬레이션 (우리팀 경기용)
  Future<IndividualMatchResult> _simulateBo5WithLog(
    Player p1, Player p2, Map<String, Player> playerMap,
  ) async {
    final maps = GameMaps.all;
    int p1Wins = 0;
    int p2Wins = 0;
    final sets = <SetResult>[];

    while (p1Wins < 3 && p2Wins < 3) {
      final setNum = p1Wins + p2Wins + 1;
      final map = maps[(setNum - 1) % maps.length];

      setState(() {
        _currentBattleLog = [
          ...(_currentBattleLog.isNotEmpty ? [..._currentBattleLog, '', '---', ''] : []),
          'Set $setNum / ${p1.name} vs ${p2.name} (${p1Wins}:${p2Wins})',
        ];
      });

      final stream = _matchService.simulateMatchWithLog(
        homePlayer: p1, awayPlayer: p2, map: map,
        getIntervalMs: () => _matchSpeed.intervalMs,
      );

      SetResult? setResult;
      await for (final state in stream) {
        if (!mounted) break;
        setState(() {
          _currentBattleLog = [
            ...(_currentBattleLog.take(_currentBattleLog.length).toList()),
            ...state.battleLog.skip(_currentBattleLog.length > 0 ? 0 : 0),
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
        if (setResult.homeWin) p1Wins++; else p2Wins++;
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
      id: 'quarterFinal_${p1.id}_${p2.id}',
      player1Id: p1.id,
      player2Id: p2.id,
      winnerId: winnerId,
      mapId: sets.first.mapId,
      stageIndex: IndividualLeagueStage.quarterFinal.index,
      battleLog: [],
      showBattleLog: true,
      sets: sets,
      bestOf: 5,
    );
  }

  void _finish(BuildContext context) {
    context.go('/main');
  }

}
