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
                    padding: EdgeInsets.all(widget.stage == '32' ? 6.sp : 16.sp),
                    child: widget.stage == '32'
                        ? _build32BracketLayout(bracket, playerMap)
                        : widget.stage == '8'
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

    // Slice to current half for grid display
    final half = _getCurrentHalf(bracket);
    final int perHalf;
    switch (widget.stage) {
      case '32': perHalf = 20; break;
      case '16': perHalf = 4; break;
      default: perHalf = 2;
    }
    final start = (half - 1) * perHalf;
    final end = half * perHalf;
    if (_roundResults.length >= end) {
      _roundResults = _roundResults.sublist(start, end);
    } else if (_roundResults.length > start) {
      _roundResults = _roundResults.sublist(start);
    }
  }

  Widget _buildHeader(BuildContext context, Team team, IndividualLeagueBracket? bracket) {
    final half = bracket != null ? _getCurrentHalf(bracket) : 1;

    // 32강: 간결한 헤더
    if (widget.stage == '32') {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3))),
        ),
        child: Row(
          children: [
            ResetButton.back(),
            const Spacer(),
            Text(
              '마 이 스 타 리 그   ${_stageLabel}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            const ResetButton(small: true),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.primary.withOpacity(0.3))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ResetButton.back(),
              SizedBox(width: 8.sp),
              _buildTeamLogo(team),
              SizedBox(width: 8.sp),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '개인리그 $_stageLabel #$half',
                      style: TextStyle(
                        color: Colors.white, fontSize: 20.sp,
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
              ),
              if (widget.stage == '8' && !_isSpectatorMode)
                _buildSpeedSelector(),
              SizedBox(width: 8.sp),
              const ResetButton(small: true),
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
          ? widget.stage == '16'
              ? _buildEmptyBracketLayout(4, 3)
              : widget.stage == '8'
                  ? _buildEmptyBracketLayout(2, 5)
                  : Center(
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
              ? _buildRound32Grid(bracket, playerMap)
              : widget.stage == '16'
                  ? _buildSeriesGrid16(playerMap)
                  : _buildSeriesGrid8(playerMap),
    );
  }

  /// 대전 전 빈 브라켓 레이아웃 (16강/8강 공용)
  Widget _buildEmptyBracketLayout(int matchCount, int bestOf) {
    final half = matchCount ~/ 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 왼쪽: 매치 카드들
        Expanded(
          flex: 5,
          child: Column(
            children: [
              for (var i = 0; i < half; i++) ...[
                if (i > 0) SizedBox(height: 8.sp),
                Expanded(child: _buildEmptyMatchCard(i + 1, bestOf)),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.sp),
        // 중앙: 정보 패널
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: AppColors.accent.withOpacity(0.3), size: 32.sp),
              SizedBox(height: 8.sp),
              Text(
                '진행되지 않았습니다',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.sp),
              // 세트 스케줄
              for (var s = 1; s <= bestOf; s++) ...[
                Text(
                  '<${s}세트>',
                  style: TextStyle(color: Colors.grey[600], fontSize: 9.sp),
                ),
                Text(
                  '미정',
                  style: TextStyle(color: Colors.white, fontSize: 10.sp),
                ),
                SizedBox(height: 4.sp),
              ],
            ],
          ),
        ),
        SizedBox(width: 8.sp),
        // 오른쪽: 매치 카드들
        Expanded(
          flex: 5,
          child: Column(
            children: [
              for (var i = half; i < matchCount; i++) ...[
                if (i > half) SizedBox(height: 8.sp),
                Expanded(child: _buildEmptyMatchCard(i + 1, bestOf)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 빈 매치 카드 (대전 전 플레이스홀더)
  Widget _buildEmptyMatchCard(int matchNum, int bestOf) {
    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 선수 박스 + 스코어
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEmptyPlayerBox(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.sp),
                child: Column(
                  children: [
                    Text(
                      '0 : 0',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '< VS >',
                      style: TextStyle(color: Colors.grey, fontSize: 9.sp),
                    ),
                  ],
                ),
              ),
              _buildEmptyPlayerBox(),
            ],
          ),
          SizedBox(height: 4.sp),
          // 세트 라벨
          Wrap(
            spacing: 6.sp,
            children: [
              for (var s = 1; s <= bestOf; s++)
                Text(
                  '<${s}세트>',
                  style: TextStyle(color: Colors.grey[600], fontSize: 8.sp),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 빈 선수 박스 (EMPTY 플레이스홀더)
  Widget _buildEmptyPlayerBox() {
    return Column(
      children: [
        Container(
          width: 28.sp,
          height: 28.sp,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(4.sp),
            border: Border.all(color: Colors.grey.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              'EMPTY',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 6.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 2.sp),
        Text(
          '???',
          style: TextStyle(color: Colors.grey, fontSize: 9.sp),
        ),
      ],
    );
  }

  /// 32강 결과: 2x2 그리드 레이아웃
  Widget _buildRound32Grid(IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    if (_roundResults.length < 20) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildGroupCard32(0, playerMap, bracket)),
              SizedBox(width: 8.sp),
              Expanded(child: _buildGroupCard32(1, playerMap, bracket)),
            ],
          ),
        ),
        SizedBox(height: 8.sp),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _buildGroupCard32(2, playerMap, bracket)),
              SizedBox(width: 8.sp),
              Expanded(child: _buildGroupCard32(3, playerMap, bracket)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard32(int localGroupIdx, Map<String, Player> playerMap, IndividualLeagueBracket? bracket) {
    final start = localGroupIdx * 5;
    if (start + 5 > _roundResults.length) return const SizedBox.shrink();

    final half = bracket != null ? _getCurrentHalf(bracket) : 1;
    final actualGroupIdx = (half - 1) * 4 + localGroupIdx;
    final groupLabel = String.fromCharCode('A'.codeUnitAt(0) + actualGroupIdx);

    final winnersMatch = _roundResults[start + 2];
    final finalMatch = _roundResults[start + 4];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(6.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              '$groupLabel조',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 4.sp),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGridMatchRow('1경기', _roundResults[start], playerMap)),
                Expanded(child: _buildGridMatchRow('2경기', _roundResults[start + 1], playerMap)),
                Expanded(child: _buildGridMatchRow('승자전', winnersMatch, playerMap, highlight: true)),
                Expanded(child: _buildGridMatchRow('패자전', _roundResults[start + 3], playerMap)),
                Expanded(child: _buildGridMatchRow('최종전', finalMatch, playerMap, highlight: true)),
              ],
            ),
          ),
          SizedBox(height: 2.sp),
          Row(
            children: [
              Icon(Icons.arrow_forward, color: Colors.green, size: 12.sp),
              SizedBox(width: 2.sp),
              Expanded(
                child: Text(
                  '진출: ${_getPlayerName(winnersMatch.winnerId, playerMap)}, ${_getPlayerName(finalMatch.winnerId, playerMap)}',
                  style: TextStyle(color: Colors.green, fontSize: 9.sp, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 16강 결과: 2x2 그리드 레이아웃
  Widget _buildSeriesGrid16(Map<String, Player> playerMap) {
    if (_roundResults.length < 4) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSeriesResultCard(_roundResults[0], playerMap, 1)),
              SizedBox(width: 8.sp),
              Expanded(child: _buildSeriesResultCard(_roundResults[1], playerMap, 2)),
            ],
          ),
        ),
        SizedBox(height: 8.sp),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSeriesResultCard(_roundResults[2], playerMap, 3)),
              SizedBox(width: 8.sp),
              Expanded(child: _buildSeriesResultCard(_roundResults[3], playerMap, 4)),
            ],
          ),
        ),
      ],
    );
  }

  /// 8강 결과: 가로 배치 (1x2)
  Widget _buildSeriesGrid8(Map<String, Player> playerMap) {
    if (_roundResults.length < 2) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildSeriesResultCard(_roundResults[0], playerMap, 1)),
        SizedBox(width: 8.sp),
        Expanded(child: _buildSeriesResultCard(_roundResults[1], playerMap, 2)),
      ],
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
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridMatchRow(String label, IndividualMatchResult result, Map<String, Player> playerMap, {bool highlight = false}) {
    final isMyP1 = _myTeamPlayerIds.contains(result.player1Id);
    final isMyP2 = _myTeamPlayerIds.contains(result.player2Id);

    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 2.sp),
      decoration: highlight ? BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.sp),
      ) : null,
      child: Row(
        children: [
          SizedBox(
            width: 36.sp,
            child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 8.sp)),
          ),
          Expanded(
            child: Text(
              _getPlayerName(result.player1Id, playerMap),
              style: TextStyle(
                color: result.winnerId == result.player1Id ? Colors.white : Colors.grey,
                fontSize: 9.sp,
                fontWeight: result.winnerId == result.player1Id || isMyP1 ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(' v ', style: TextStyle(color: Colors.grey, fontSize: 8.sp)),
          Expanded(
            child: Text(
              _getPlayerName(result.player2Id, playerMap),
              style: TextStyle(
                color: result.winnerId == result.player2Id ? Colors.white : Colors.grey,
                fontSize: 9.sp,
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

  // ─── 32강 전용: 3열 브라켓 레이아웃 ───

  /// 32강 메인 레이아웃: [왼쪽 2조] [중앙 정보] [오른쪽 2조]
  Widget _build32BracketLayout(IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    final half = bracket != null ? _getCurrentHalf(bracket) : 1;
    final groupOffset = (half - 1) * 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 왼쪽: A/E조, B/F조
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(child: _build32GroupCard(0, groupOffset, bracket, playerMap)),
              SizedBox(height: 4.sp),
              Expanded(child: _build32GroupCard(1, groupOffset + 1, bracket, playerMap)),
            ],
          ),
        ),
        SizedBox(width: 4.sp),
        // 중앙: 정보 패널
        Expanded(
          flex: 3,
          child: _build32CenterPanel(bracket),
        ),
        SizedBox(width: 4.sp),
        // 오른쪽: C/G조, D/H조
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(child: _build32GroupCard(2, groupOffset + 2, bracket, playerMap)),
              SizedBox(height: 4.sp),
              Expanded(child: _build32GroupCard(3, groupOffset + 3, bracket, playerMap)),
            ],
          ),
        ),
      ],
    );
  }

  /// 32강 개별 조 카드 (듀얼토너먼트 스타일 브라켓)
  Widget _build32GroupCard(int localIdx, int actualGroupIdx, IndividualLeagueBracket? bracket, Map<String, Player> playerMap) {
    final groupName = String.fromCharCode('A'.codeUnitAt(0) + actualGroupIdx);

    // 조 선수 데이터
    List<String?> groupPlayers = [];
    if (bracket != null && actualGroupIdx < bracket.mainTournamentGroups.length) {
      groupPlayers = List.from(bracket.mainTournamentGroups[actualGroupIdx]);
    }
    while (groupPlayers.length < 4) {
      groupPlayers.add(null);
    }

    final p0 = groupPlayers[0] != null ? playerMap[groupPlayers[0]] : null;
    final p1 = groupPlayers[1] != null ? playerMap[groupPlayers[1]] : null;
    final p2 = groupPlayers[2] != null ? playerMap[groupPlayers[2]] : null;
    final p3 = groupPlayers[3] != null ? playerMap[groupPlayers[3]] : null;

    // 결과 데이터
    final resultStart = localIdx * 5;
    final hasResults = _roundResults.length >= resultStart + 5;

    Player? wP1, wP2, lP1, lP2, fP1, fP2;
    String? m1WinnerId, m2WinnerId;
    String? winnersAdvanceId, losersEliminateId, finalAdvanceId, finalEliminateId;

    if (hasResults) {
      final r1 = _roundResults[resultStart];
      final r2 = _roundResults[resultStart + 1];
      final r3 = _roundResults[resultStart + 2];
      final r4 = _roundResults[resultStart + 3];
      final r5 = _roundResults[resultStart + 4];

      m1WinnerId = r1.winnerId;
      m2WinnerId = r2.winnerId;

      // 승자전: 1경기 승자 vs 2경기 승자
      wP1 = playerMap[r1.winnerId];
      wP2 = playerMap[r2.winnerId];
      winnersAdvanceId = r3.winnerId;

      // 패자전: 1경기 패자 vs 2경기 패자
      final r1LoserId = r1.player1Id == r1.winnerId ? r1.player2Id : r1.player1Id;
      final r2LoserId = r2.player1Id == r2.winnerId ? r2.player2Id : r2.player1Id;
      lP1 = playerMap[r1LoserId];
      lP2 = playerMap[r2LoserId];
      final r4LoserId = r4.player1Id == r4.winnerId ? r4.player2Id : r4.player1Id;
      losersEliminateId = r4LoserId;

      // 최종전: 승자전 패자 vs 패자전 승자
      final r3LoserId = r3.player1Id == r3.winnerId ? r3.player2Id : r3.player1Id;
      fP1 = playerMap[r3LoserId];
      fP2 = playerMap[r4.winnerId];
      finalAdvanceId = r5.winnerId;
      final r5LoserId = r5.player1Id == r5.winnerId ? r5.player2Id : r5.player1Id;
      finalEliminateId = r5LoserId;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조 헤더 + 4명 썸네일
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
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 4.sp),
              ...[p0, p1, p2, p3].where((p) => p != null).map((p) {
                return Padding(
                  padding: EdgeInsets.only(right: 2.sp),
                  child: PlayerThumbnail(
                    player: p!,
                    size: 12,
                    isMyTeam: _myTeamPlayerIds.contains(p.id),
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: 3.sp),
          // 5경기 브라켓
          Expanded(
            child: Column(
              children: [
                Expanded(child: _build32MatchRow('< 1경기 >', p0, p2, winnerId: m1WinnerId)),
                Expanded(child: _build32MatchRow('< 2경기 >', p1, p3, winnerId: m2WinnerId)),
                Expanded(child: _build32MatchRow('< 승자전 >', wP1, wP2, advanceId: winnersAdvanceId)),
                Expanded(child: _build32MatchRow('< 패자전 >', lP1, lP2, eliminateId: losersEliminateId)),
                Expanded(child: _build32MatchRow('< 최종전 >', fP1, fP2, advanceId: finalAdvanceId, eliminateId: finalEliminateId)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 32강 중앙 정보 패널
  Widget _build32CenterPanel(IndividualLeagueBracket? bracket) {
    final half = bracket != null ? _getCurrentHalf(bracket) : 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6.sp),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 8.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 아이콘
          Icon(Icons.emoji_events, color: AppColors.accent, size: 28.sp),
          SizedBox(height: 6.sp),
          // #N 표시
          Text(
            '#$half',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          // 상태
          Text(
            _isSimulating
                ? '진행중...'
                : _isCompleted
                    ? '완료!'
                    : '미진행',
            style: TextStyle(
              color: _isSimulating
                  ? Colors.amber
                  : _isCompleted
                      ? AppColors.accent
                      : Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_isSimulating)
            Padding(
              padding: EdgeInsets.only(top: 8.sp),
              child: SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: const CircularProgressIndicator(
                  color: AppColors.accent,
                  strokeWidth: 2,
                ),
              ),
            ),
          SizedBox(height: 16.sp),
          // 경기 단계 라벨
          Text('< 1경기 >', style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
          Text('< 2경기 >', style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
          SizedBox(height: 4.sp),
          Text('< 승자전 >', style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
          Text('< 패자전 >', style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
          SizedBox(height: 4.sp),
          Text('< 최종전 >', style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
        ],
      ),
    );
  }

  /// 32강 매치 행 (타이틀 + 선수1 vs 선수2)
  Widget _build32MatchRow(String title, Player? player1, Player? player2, {
    String? winnerId,
    String? advanceId,
    String? eliminateId,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 8.sp)),
        SizedBox(height: 1.sp),
        Row(
          children: [
            Expanded(
              child: _build32PlayerName(player1,
                  winnerId: winnerId, advanceId: advanceId, eliminateId: eliminateId),
            ),
            Text(' v ', style: TextStyle(color: Colors.grey[700], fontSize: 7.sp)),
            Expanded(
              child: _build32PlayerName(player2,
                  winnerId: winnerId, advanceId: advanceId, eliminateId: eliminateId, alignEnd: true),
            ),
          ],
        ),
      ],
    );
  }

  /// 32강 선수 이름 표시
  Widget _build32PlayerName(Player? player, {
    String? winnerId,
    String? advanceId,
    String? eliminateId,
    bool alignEnd = false,
  }) {
    if (player == null) {
      return Text(
        '???',
        style: TextStyle(color: Colors.grey[700], fontSize: 8.sp),
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      );
    }

    final isAdvanced = advanceId != null && player.id == advanceId;
    final isEliminated = eliminateId != null && player.id == eliminateId;
    final isWinner = winnerId != null && player.id == winnerId;
    final isMyTeam = _myTeamPlayerIds.contains(player.id);

    Color textColor;
    if (isAdvanced) {
      textColor = Colors.greenAccent;
    } else if (isEliminated) {
      textColor = Colors.grey;
    } else if (isWinner) {
      textColor = AppColors.accent;
    } else if (isMyTeam) {
      textColor = Colors.lightBlueAccent;
    } else {
      textColor = Colors.white;
    }

    return Text(
      '${player.name}(${player.race.code})',
      style: TextStyle(
        color: textColor,
        fontSize: 8.sp,
        fontWeight: (isAdvanced || isWinner || isMyTeam) ? FontWeight.bold : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    );
  }
}
