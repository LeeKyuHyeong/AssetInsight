import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../../data/providers/match_provider.dart';
import '../../widgets/reset_button.dart';

/// 플레이오프 스케줄 화면
class PlayoffScheduleScreen extends ConsumerStatefulWidget {
  const PlayoffScheduleScreen({super.key});

  @override
  ConsumerState<PlayoffScheduleScreen> createState() => _PlayoffScheduleScreenState();
}

class _PlayoffScheduleScreenState extends ConsumerState<PlayoffScheduleScreen> {
  // 관전 모드 여부
  bool _isSpectatorMode = false;

  // 현재 시뮬레이션 중인 경기 정보
  bool _isSimulating = false;
  String _simulationMessage = '';

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final season = gameState.currentSeason;
    final playoff = season.playoff;
    final playerTeam = gameState.playerTeam;

    // 플레이어 팀이 플레이오프 진출했는지 확인 (상위 4팀)
    final isPlayerInPlayoff = playoff != null && (
      playoff.firstPlaceTeamId == playerTeam.id ||
      playoff.secondPlaceTeamId == playerTeam.id ||
      playoff.thirdPlaceTeamId == playerTeam.id ||
      playoff.fourthPlaceTeamId == playerTeam.id
    );
    _isSpectatorMode = !isPlayerInPlayoff;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(season),

            // 메인 컨텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(12.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 플레이오프 진행 흐름
                    _buildPlayoffFlow(season),

                    SizedBox(height: 16.sp),

                    // 플레이오프 대진표 (시각적)
                    if (playoff != null)
                      _buildTournamentBracket(playoff, gameState),

                    SizedBox(height: 16.sp),

                    // 개인리그 진행 상황
                    _buildIndividualLeagueStatus(season),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildBottomButtons(context, season, playerTeam.id),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Season season) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ResetButton.back(),
              const Spacer(),
              Icon(Icons.emoji_events, color: Colors.amber, size: 24.sp),
              SizedBox(width: 12.sp),
              Text(
                '시즌 ${season.number} 플레이오프',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
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
                    '관전 모드 - 아쉽게 플레이오프 진출 실패',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isSimulating) ...[
            SizedBox(height: 8.sp),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 8.sp),
                Text(
                  _simulationMessage,
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 플레이오프 진행 흐름 (3단계 표시)
  Widget _buildPlayoffFlow(Season season) {
    final phase = season.phase;
    final playoff = season.playoff;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '플레이오프 진행 흐름',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          Row(
            children: [
              // 3,4위전
              Expanded(
                child: _buildFlowStep(
                  '3,4위전',
                  step: 1,
                  isCompleted: playoff?.match34 != null,
                  isCurrent: phase == SeasonPhase.playoff34,
                  score: playoff?.match34 != null
                      ? '${playoff!.match34!.homeScore}:${playoff.match34!.awayScore}'
                      : null,
                ),
              ),
              _buildFlowArrow(playoff?.match34 != null),
              // 2,3위전
              Expanded(
                child: _buildFlowStep(
                  '2,3위전',
                  step: 2,
                  isCompleted: playoff?.match23 != null,
                  isCurrent: phase == SeasonPhase.playoff23,
                  score: playoff?.match23 != null
                      ? '${playoff!.match23!.homeScore}:${playoff.match23!.awayScore}'
                      : null,
                ),
              ),
              _buildFlowArrow(playoff?.match23 != null),
              // 결승전
              Expanded(
                child: _buildFlowStep(
                  '결승전',
                  step: 3,
                  isCompleted: playoff?.matchFinal != null,
                  isCurrent: phase == SeasonPhase.playoffFinal,
                  isFinal: true,
                  score: playoff?.matchFinal != null
                      ? '${playoff!.matchFinal!.homeScore}:${playoff.matchFinal!.awayScore}'
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowStep(
    String label, {
    required int step,
    required bool isCompleted,
    required bool isCurrent,
    bool isFinal = false,
    String? score,
  }) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCompleted) {
      bgColor = Colors.green.withOpacity(0.2);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (isCurrent) {
      bgColor = isFinal ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2);
      borderColor = isFinal ? Colors.amber : Colors.blue;
      textColor = isFinal ? Colors.amber : Colors.blue;
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
      borderColor = Colors.grey.withOpacity(0.3);
      textColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
      ),
      child: Column(
        children: [
          if (isFinal)
            Icon(Icons.emoji_events, color: textColor, size: 20.sp),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (score != null) ...[
            SizedBox(height: 4.sp),
            Text(
              score,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (isCompleted)
            Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildFlowArrow(bool isCompleted) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.sp),
      child: Icon(
        Icons.arrow_forward,
        color: isCompleted ? Colors.green : Colors.grey.withOpacity(0.5),
        size: 20.sp,
      ),
    );
  }

  /// 토너먼트 대진표 (시각적)
  Widget _buildTournamentBracket(PlayoffBracket playoff, GameState gameState) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree, color: Colors.amber, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                '플레이오프 대진표',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),

          // 대진표 그리기
          SizedBox(
            height: 320.sp,
            child: Row(
              children: [
                // 1라운드: 3,4위전
                Expanded(
                  flex: 2,
                  child: _buildRound1(playoff, gameState),
                ),
                // 2라운드: 2,3위전
                Expanded(
                  flex: 2,
                  child: _buildRound2(playoff, gameState),
                ),
                // 결승전
                Expanded(
                  flex: 3,
                  child: _buildFinalRound(playoff, gameState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1라운드: 3,4위전
  Widget _buildRound1(PlayoffBracket playoff, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          '3,4위전',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        // 3위 팀
        _buildBracketTeam(
          playoff.thirdPlaceTeamId,
          gameState,
          rank: '3위',
          isWinner: playoff.winner34 == playoff.thirdPlaceTeamId,
        ),
        // 연결선 + 점수
        _buildBracketConnector(
          playoff.match34,
          showScore: true,
        ),
        // 4위 팀
        _buildBracketTeam(
          playoff.fourthPlaceTeamId,
          gameState,
          rank: '4위',
          isWinner: playoff.winner34 == playoff.fourthPlaceTeamId,
        ),
      ],
    );
  }

  /// 2라운드: 2,3위전
  Widget _buildRound2(PlayoffBracket playoff, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '2,3위전',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        // 2위 팀
        _buildBracketTeam(
          playoff.secondPlaceTeamId,
          gameState,
          rank: '2위',
          isWinner: playoff.winner23 == playoff.secondPlaceTeamId,
        ),
        // 연결선 + 점수
        _buildBracketConnector(
          playoff.match23,
          showScore: true,
        ),
        // 3,4위전 승자 (新3위)
        _buildBracketTeam(
          playoff.winner34,
          gameState,
          rank: '新3위',
          isWinner: playoff.winner23 == playoff.winner34,
          placeholder: '3,4위전 승자',
        ),
      ],
    );
  }

  /// 결승전
  Widget _buildFinalRound(PlayoffBracket playoff, GameState gameState) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 결승전 박스
        Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.withOpacity(0.2),
                Colors.orange.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24.sp),
                  SizedBox(width: 8.sp),
                  Text(
                    '결승전',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.sp),

              // 1위 팀 (결승 직행)
              _buildBracketTeam(
                playoff.firstPlaceTeamId,
                gameState,
                rank: '1위',
                isWinner: playoff.champion == playoff.firstPlaceTeamId,
                compact: false,
                highlight: true,
              ),

              // VS 및 점수
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.sp),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (playoff.matchFinal != null)
                      Container(
                        margin: EdgeInsets.only(top: 4.sp),
                        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.sp),
                        ),
                        child: Text(
                          '${playoff.matchFinal!.homeScore} : ${playoff.matchFinal!.awayScore}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2,3위전 승자
              _buildBracketTeam(
                playoff.winner23,
                gameState,
                rank: '2,3위전 승자',
                isWinner: playoff.champion == playoff.winner23,
                compact: false,
                placeholder: '2,3위전 승자',
                highlight: true,
              ),
            ],
          ),
        ),

        // 우승팀 표시
        if (playoff.champion != null) ...[
          SizedBox(height: 12.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.amber, Colors.orange],
              ),
              borderRadius: BorderRadius.circular(20.sp),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.sp),
                Text(
                  '우승: ${_getTeamName(playoff.champion!, gameState)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBracketTeam(
    String? teamId,
    GameState gameState, {
    required String rank,
    bool isWinner = false,
    bool compact = true,
    bool highlight = false,
    String? placeholder,
  }) {
    if (teamId == null) {
      return Container(
        width: compact ? 60.sp : 100.sp,
        padding: EdgeInsets.all(6.sp),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4.sp),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rank,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 8.sp,
              ),
            ),
            Text(
              placeholder ?? '?',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final team = gameState.teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => gameState.teams.first,
    );
    final isPlayerTeam = team.id == gameState.playerTeam.id;

    Color bgColor = Color(team.colorValue).withOpacity(0.2);
    Color borderColor = Color(team.colorValue);

    if (isWinner) {
      bgColor = Colors.green.withOpacity(0.3);
      borderColor = Colors.green;
    } else if (isPlayerTeam) {
      borderColor = Colors.blue;
    }

    return Container(
      width: compact ? 60.sp : 100.sp,
      padding: EdgeInsets.all(6.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: borderColor,
          width: isWinner || isPlayerTeam || highlight ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            rank,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 8.sp,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWinner)
                Padding(
                  padding: EdgeInsets.only(right: 2.sp),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 12.sp),
                ),
              Flexible(
                child: Text(
                  team.shortName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11.sp : 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isPlayerTeam)
            Container(
              margin: EdgeInsets.only(top: 2.sp),
              padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 1.sp),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2.sp),
              ),
              child: Text(
                'MY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBracketConnector(MatchResult? result, {bool showScore = false}) {
    return Container(
      height: 50.sp,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 2,
            height: 15.sp,
            color: result != null ? Colors.green : Colors.grey.withOpacity(0.3),
          ),
          if (showScore && result != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                '${result.homeScore}:${result.awayScore}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Container(
              width: 8.sp,
              height: 8.sp,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
          Container(
            width: 2,
            height: 15.sp,
            color: result != null ? Colors.green : Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  String _getTeamName(String teamId, GameState gameState) {
    return gameState.teams
        .firstWhere((t) => t.id == teamId, orElse: () => gameState.teams.first)
        .name;
  }

  Widget _buildIndividualLeagueStatus(Season season) {
    final individualLeague = season.individualLeague;
    final phase = season.phase;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.purple, size: 20.sp),
              SizedBox(width: 8.sp),
              Text(
                '개인리그 진행 상황',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),

          // 진행 상황 표시
          _buildProgressItem(
            '8강',
            _getQuarterFinalStatus(individualLeague),
          ),
          _buildProgressItem(
            '4강',
            _getSemiFinalStatus(individualLeague, phase),
            isHighlight: phase == SeasonPhase.individualSemiFinal,
          ),
          _buildProgressItem(
            '결승',
            _getFinalStatus(individualLeague, phase),
            isHighlight: phase == SeasonPhase.individualFinal,
          ),

          if (individualLeague?.championId != null) ...[
            SizedBox(height: 12.sp),
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(color: Colors.purple),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.purple, size: 20.sp),
                  SizedBox(width: 8.sp),
                  Expanded(
                    child: Text(
                      '개인리그 우승: ${individualLeague!.championId}',
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String status, {bool isHighlight = false}) {
    final isCompleted = status == '완료';
    final isInProgress = status.contains('진행');

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 8.sp),
      margin: EdgeInsets.only(bottom: 4.sp),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.purple.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : (isInProgress ? Icons.play_circle : Icons.circle_outlined),
            color: isCompleted
                ? Colors.green
                : (isInProgress ? Colors.purple : Colors.grey),
            size: 16.sp,
          ),
          SizedBox(width: 8.sp),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              color: isCompleted
                  ? Colors.green
                  : (isInProgress ? Colors.purple : Colors.grey),
              fontSize: 12.sp,
              fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getQuarterFinalStatus(IndividualLeagueBracket? league) {
    if (league == null) return '대기';
    final count = league.mainTournamentResults
        .where((r) => r.stage == IndividualLeagueStage.quarterFinal)
        .length;
    if (count >= 4) return '완료';
    if (count > 0) return '진행 중 ($count/4)';
    return '대기';
  }

  String _getSemiFinalStatus(IndividualLeagueBracket? league, SeasonPhase phase) {
    if (league == null) return '대기';
    final count = league.mainTournamentResults
        .where((r) => r.stage == IndividualLeagueStage.semiFinal)
        .length;
    if (count >= 2) return '완료';
    if (phase == SeasonPhase.individualSemiFinal) return '진행 중 ($count/2)';
    return '대기';
  }

  String _getFinalStatus(IndividualLeagueBracket? league, SeasonPhase phase) {
    if (league == null) return '대기';
    if (league.championId != null) return '완료';
    if (phase == SeasonPhase.individualFinal) return '진행 중';
    return '대기';
  }

  Widget _buildBottomButtons(BuildContext context, Season season, String playerTeamId) {
    final phase = season.phase;
    final playoff = season.playoff;

    // 다음 진행할 이벤트 결정
    String nextButtonText = 'Next';
    String? subText;
    VoidCallback? onNextPressed;
    Color buttonColor = AppColors.primary;

    switch (phase) {
      case SeasonPhase.playoffReady:
        nextButtonText = '플레이오프 시작';
        subText = _isSpectatorMode ? '관전 시작' : '3,4위전부터 시작';
        buttonColor = Colors.green;
        onNextPressed = _isSimulating ? null : () => _startPlayoff(context);
        break;
      case SeasonPhase.playoff34:
        final isPlayerMatch = !_isSpectatorMode && playoff != null &&
            (playoff.thirdPlaceTeamId == playerTeamId ||
             playoff.fourthPlaceTeamId == playerTeamId);
        nextButtonText = '3,4위전';
        subText = isPlayerMatch ? '경기 시작' : '결과 확인';
        buttonColor = isPlayerMatch ? Colors.blue : Colors.orange;
        onNextPressed = _isSimulating ? null : () => _startPlayoffMatch(context, PlayoffMatchType.thirdFourth, isPlayerMatch);
        break;
      case SeasonPhase.individualSemiFinal:
        nextButtonText = '개인리그 4강';
        subText = '진행하기';
        buttonColor = Colors.purple;
        onNextPressed = _isSimulating ? null : () => _startIndividualSemiFinal(context);
        break;
      case SeasonPhase.playoff23:
        final isPlayerMatch = !_isSpectatorMode && playoff != null &&
            (playoff.secondPlaceTeamId == playerTeamId ||
             playoff.winner34 == playerTeamId);
        nextButtonText = '2,3위전';
        subText = isPlayerMatch ? '경기 시작' : '결과 확인';
        buttonColor = isPlayerMatch ? Colors.blue : Colors.orange;
        onNextPressed = _isSimulating ? null : () => _startPlayoffMatch(context, PlayoffMatchType.secondThird, isPlayerMatch);
        break;
      case SeasonPhase.individualFinal:
        nextButtonText = '개인리그 결승';
        subText = '진행하기';
        buttonColor = Colors.purple;
        onNextPressed = _isSimulating ? null : () => _startIndividualFinal(context);
        break;
      case SeasonPhase.playoffFinal:
        final isPlayerMatch = !_isSpectatorMode && playoff != null &&
            (playoff.firstPlaceTeamId == playerTeamId ||
             playoff.winner23 == playerTeamId);
        nextButtonText = '결승전';
        subText = isPlayerMatch ? '경기 시작' : '결과 확인';
        buttonColor = isPlayerMatch ? Colors.amber : Colors.orange;
        onNextPressed = _isSimulating ? null : () => _startPlayoffMatch(context, PlayoffMatchType.final_, isPlayerMatch);
        break;
      case SeasonPhase.seasonEnd:
        nextButtonText = '시즌 종료';
        subText = '결과 확인';
        buttonColor = Colors.amber;
        onNextPressed = () => context.go('/season-end');
        break;
      default:
        break;
    }

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // EXIT 버튼
          OutlinedButton(
            onPressed: () => context.go('/main'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey),
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
            ),
            child: Text(
              'EXIT',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
          ),
          const Spacer(),
          // Next 버튼
          ElevatedButton(
            onPressed: onNextPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nextButtonText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subText != null)
                  Text(
                    subText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startPlayoff(BuildContext context) {
    ref.read(gameStateProvider.notifier).startPlayoff();
    setState(() {});
  }

  void _startPlayoffMatch(BuildContext context, PlayoffMatchType matchType, bool isPlayerMatch) async {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final playoff = gameState.currentSeason.playoff;
    if (playoff == null) return;

    // 매치 정보 설정
    final (homeTeamId, awayTeamId) = playoff.nextMatchTeams!;

    if (isPlayerMatch) {
      // 플레이어 경기: 로스터 선택 화면으로
      ref.read(currentMatchProvider.notifier).startMatch(
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
      );
      context.go('/roster-select');
    } else {
      // AI 경기 또는 관전 모드: 시뮬레이션 실행
      await _simulateAIPlayoffMatch(matchType, homeTeamId, awayTeamId);
    }
  }

  Future<void> _simulateAIPlayoffMatch(PlayoffMatchType matchType, String homeTeamId, String awayTeamId) async {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final homeName = _getTeamName(homeTeamId, gameState);
    final awayName = _getTeamName(awayTeamId, gameState);
    final matchName = matchType == PlayoffMatchType.thirdFourth ? '3,4위전' :
                      matchType == PlayoffMatchType.secondThird ? '2,3위전' : '결승전';

    setState(() {
      _isSimulating = true;
      _simulationMessage = '$matchName 진행 중... ($homeName vs $awayName)';
    });

    // 짧은 딜레이로 시뮬레이션 효과
    await Future.delayed(const Duration(milliseconds: 1500));

    // 간단한 AI 시뮬레이션 (팀 전력 기반)
    final homePlayers = gameState.saveData.getTeamPlayers(homeTeamId);
    final awayPlayers = gameState.saveData.getTeamPlayers(awayTeamId);

    final homeStrength = homePlayers.fold<int>(0, (sum, p) => sum + p.stats.total) ~/ (homePlayers.isEmpty ? 1 : homePlayers.length);
    final awayStrength = awayPlayers.fold<int>(0, (sum, p) => sum + p.stats.total) ~/ (awayPlayers.isEmpty ? 1 : awayPlayers.length);
    final totalStrength = homeStrength + awayStrength;

    final homeWinProb = totalStrength > 0 ? homeStrength / totalStrength : 0.5;
    final random = DateTime.now().millisecondsSinceEpoch;

    // 세트 점수 시뮬레이션
    int homeScore = 0;
    int awayScore = 0;
    int setIndex = 0;
    while (homeScore < 4 && awayScore < 4) {
      final setRandom = ((random + setIndex * 137) % 100) / 100.0;
      if (setRandom < homeWinProb) {
        homeScore++;
      } else {
        awayScore++;
      }
      setIndex++;
    }

    // 결과 생성
    final sets = <SetResult>[];
    for (int i = 0; i < homeScore; i++) {
      sets.add(SetResult(
        mapId: 'map_$i',
        homePlayerId: 'ai_home_$i',
        awayPlayerId: 'ai_away_$i',
        homeWin: true,
      ));
    }
    for (int i = 0; i < awayScore; i++) {
      sets.add(SetResult(
        mapId: 'map_${homeScore + i}',
        homePlayerId: 'ai_home_${homeScore + i}',
        awayPlayerId: 'ai_away_${homeScore + i}',
        homeWin: false,
      ));
    }

    final result = MatchResult(
      id: 'playoff_${matchType.name}_${DateTime.now().millisecondsSinceEpoch}',
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      sets: sets,
      isCompleted: true,
      seasonNumber: gameState.currentSeason.number,
      roundNumber: 99, // 플레이오프
    );

    // 결과 기록
    ref.read(gameStateProvider.notifier).recordPlayoffMatchResult(
      matchType: matchType,
      result: result,
    );

    setState(() {
      _isSimulating = false;
      _simulationMessage = '';
    });

    // 결과 다이얼로그 표시
    final winnerTeamId = homeScore > awayScore ? homeTeamId : awayTeamId;
    final winnerName = _getTeamName(winnerTeamId, gameState);
    final loserName = homeScore > awayScore ? awayName : homeName;

    if (mounted) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          title: Row(
            children: [
              Icon(
                matchType == PlayoffMatchType.final_ ? Icons.emoji_events : Icons.sports_esports,
                color: matchType == PlayoffMatchType.final_ ? Colors.amber : Colors.green,
              ),
              SizedBox(width: 8.sp),
              Text(
                '$matchName 결과',
                style: TextStyle(color: Colors.white, fontSize: 18.sp),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDialogTeamBox(homeName, homeScore > awayScore),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp),
                    child: Text(
                      '$homeScore : $awayScore',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDialogTeamBox(awayName, awayScore > homeScore),
                ],
              ),
              SizedBox(height: 16.sp),
              Container(
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.sp),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      '$winnerName 승리!',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDialogTeamBox(String teamName, bool isWinner) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(
          color: isWinner ? Colors.green : Colors.grey.withOpacity(0.3),
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            teamName,
            style: TextStyle(
              color: isWinner ? Colors.white : Colors.grey,
              fontSize: 14.sp,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isWinner) ...[
            SizedBox(height: 4.sp),
            Icon(Icons.check, color: Colors.green, size: 16.sp),
          ],
        ],
      ),
    );
  }

  void _startIndividualSemiFinal(BuildContext context) {
    context.go('/individual-league/main/semifinal');
  }

  void _startIndividualFinal(BuildContext context) {
    context.go('/individual-league/main/final');
  }
}
