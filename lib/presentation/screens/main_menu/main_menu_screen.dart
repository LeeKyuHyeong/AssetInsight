import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/initial_data.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';

/// 메인 메뉴 화면 - 일정 및 행동 관리
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  // 개인리그 일정 이름 (11주차)
  static const List<String> _individualLeagueNames = [
    'PC방',
    '듀얼 1R',
    '듀얼 2R',
    '듀얼 3R',
    '조지명',
    '32강 1R',
    '32강 2R',
    '16강 1R',
    '16강 2R',
    '8강',
    '4강~결승',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Responsive.init(context);
    final gameState = ref.watch(gameStateProvider);

    // Preview 모드: gameState가 없을 때 초기 데이터 사용
    final isPreviewMode = gameState == null;
    final allTeams = isPreviewMode ? InitialData.createTeams() : gameState.saveData.allTeams;
    final playerTeam = isPreviewMode ? allTeams.first : gameState.playerTeam;
    final seasonNumber = isPreviewMode ? 1 : gameState.saveData.currentSeason.number;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(playerTeam, seasonNumber),

                // 메인 컨텐츠 - 3열 일정 테이블
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 8.sp),
                    child: _buildScheduleTable(context, gameState, playerTeam, allTeams, isPreviewMode),
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context),
              ],
            ),

            // R 버튼 (우측 상단, 헤더 내부)
            Positioned(
              top: 12.sp,
              right: 12.sp,
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

  Widget _buildHeader(dynamic playerTeam, int seasonNumber) {
    final teamColor = Color(playerTeam.colorValue);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.sp, horizontal: 16.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!, width: 2),
        ),
      ),
      child: Row(
        children: [
          // 팀 로고
          Container(
            width: 50.sp,
            height: 50.sp,
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: teamColor, width: 2),
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: teamColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sp),

          // 팀명 + 시즌
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerTeam.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.sp),
                Text(
                  'S$seasonNumber',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // R 버튼 공간 확보
          SizedBox(width: 48.sp),
        ],
      ),
    );
  }

  Widget _buildScheduleTable(BuildContext context, dynamic gameState, Team playerTeam, List<Team> allTeams, bool isPreviewMode) {
    // 10행 (각 행 = 경기1 + 경기2 + 개인리그)
    final rows = _buildScheduleRows(gameState, playerTeam, allTeams, isPreviewMode);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121a),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 10.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.sp)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '경기 1',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      '경기 2',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      '개인리그',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 일정 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
              itemCount: rows.length,
              itemBuilder: (ctx, index) => _buildScheduleRow(context, rows[index], index),
            ),
          ),
        ],
      ),
    );
  }

  List<_ScheduleRowData> _buildScheduleRows(dynamic gameState, Team playerTeam, List<Team> allTeams, bool isPreviewMode) {
    final List<_ScheduleRowData> rows = [];

    if (isPreviewMode) {
      // Preview 모드: 샘플 데이터
      for (int i = 0; i < 11; i++) {
        final team1 = allTeams[(i * 2 + 1) % allTeams.length];
        final team2 = allTeams[(i * 2 + 2) % allTeams.length];

        rows.add(_ScheduleRowData(
          match1: _MatchCellData(
            opponent: team1,
            isCompleted: i < 2,
            homeScore: i < 2 ? 4 : null,
            awayScore: i < 2 ? 1 : null,
            isWin: i < 2 ? true : null,
          ),
          match2: _MatchCellData(
            opponent: team2,
            isCompleted: i < 2,
            homeScore: i < 2 ? 2 : null,
            awayScore: i < 2 ? 3 : null,
            isWin: i < 2 ? false : null,
          ),
          leagueName: _individualLeagueNames[i],
          isLeagueCompleted: i < 2,
          isCurrentWeek: i == 2,
        ));
      }
    } else {
      // 실제 데이터
      final schedule = gameState.saveData.currentSeason.proleagueSchedule as List<ScheduleItem>;
      final playerTeamId = gameState.saveData.playerTeamId;

      // 내 팀 경기만 필터링
      final myMatches = schedule.where((s) =>
        s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId
      ).toList()..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

      // 첫 번째 미완료 매치 인덱스 찾기
      final firstIncompleteIndex = myMatches.indexWhere((m) => !m.isCompleted);
      final currentWeekIndex = firstIncompleteIndex >= 0 ? firstIncompleteIndex ~/ 2 : -1;

      for (int i = 0; i < 11; i++) {
        final match1Index = i * 2;
        final match2Index = i * 2 + 1;

        _MatchCellData? match1Data;
        _MatchCellData? match2Data;

        if (match1Index < myMatches.length) {
          final match1 = myMatches[match1Index];
          final isHome = match1.homeTeamId == playerTeamId;
          final opponentId = isHome ? match1.awayTeamId : match1.homeTeamId;
          final opponent = gameState.saveData.getTeamById(opponentId);

          int? homeScore, awayScore;
          bool? isWin;
          if (match1.result != null) {
            homeScore = match1.result!.homeScore;
            awayScore = match1.result!.awayScore;
            isWin = isHome ? homeScore > awayScore : awayScore > homeScore;
          }

          match1Data = _MatchCellData(
            opponent: opponent,
            isCompleted: match1.isCompleted,
            homeScore: isHome ? homeScore : awayScore,
            awayScore: isHome ? awayScore : homeScore,
            isWin: isWin,
          );
        }

        if (match2Index < myMatches.length) {
          final match2 = myMatches[match2Index];
          final isHome = match2.homeTeamId == playerTeamId;
          final opponentId = isHome ? match2.awayTeamId : match2.homeTeamId;
          final opponent = gameState.saveData.getTeamById(opponentId);

          int? homeScore, awayScore;
          bool? isWin;
          if (match2.result != null) {
            homeScore = match2.result!.homeScore;
            awayScore = match2.result!.awayScore;
            isWin = isHome ? homeScore > awayScore : awayScore > homeScore;
          }

          match2Data = _MatchCellData(
            opponent: opponent,
            isCompleted: match2.isCompleted,
            homeScore: isHome ? homeScore : awayScore,
            awayScore: isHome ? awayScore : homeScore,
            isWin: isWin,
          );
        }

        // 개인리그 완료 여부 체크 (해당 주 2경기 모두 완료)
        final isLeagueCompleted = match1Data?.isCompleted == true && match2Data?.isCompleted == true;

        rows.add(_ScheduleRowData(
          match1: match1Data,
          match2: match2Data,
          leagueName: _individualLeagueNames[i],
          isLeagueCompleted: isLeagueCompleted,
          isCurrentWeek: i == currentWeekIndex,
        ));
      }
    }

    return rows;
  }

  Widget _buildScheduleRow(BuildContext context, _ScheduleRowData row, int index) {
    final isCurrentWeek = row.isCurrentWeek;

    return Container(
      margin: EdgeInsets.only(bottom: 4.sp),
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: isCurrentWeek ? Colors.amber.withOpacity(0.1) : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(4.sp),
        border: isCurrentWeek ? Border.all(color: Colors.amber, width: 1.5) : null,
      ),
      child: Row(
        children: [
          // 경기 1
          Expanded(
            flex: 3,
            child: _buildMatchCell(row.match1),
          ),

          // 구분선 (회색)
          Container(
            width: 1,
            height: 36.sp,
            color: Colors.grey[700],
          ),

          // 경기 2
          Expanded(
            flex: 3,
            child: _buildMatchCell(row.match2),
          ),

          // 구분선 (녹색) - 컨디션 회복 안내
          Container(
            width: 2.sp,
            height: 36.sp,
            color: Colors.green,
          ),

          // 개인리그
          Expanded(
            flex: 2,
            child: _buildLeagueCell(row.leagueName, row.isLeagueCompleted),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCell(_MatchCellData? match) {
    if (match == null || match.opponent == null) {
      // No match
      return Center(
        child: Text(
          '-',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.sp,
          ),
        ),
      );
    }

    final opponent = match.opponent!;
    final teamColor = Color(opponent.colorValue);
    final isCompleted = match.isCompleted;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.sp),
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 팀 로고
          Container(
            width: 24.sp,
            height: 24.sp,
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
              border: Border.all(color: teamColor, width: 1),
            ),
            child: Center(
              child: Text(
                opponent.shortName.length >= 2
                    ? opponent.shortName.substring(0, 2)
                    : opponent.shortName,
                style: TextStyle(
                  color: teamColor,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 6.sp),

          // 스코어 또는 대기
          if (isCompleted && match.homeScore != null && match.awayScore != null)
            Text(
              '${match.homeScore}:${match.awayScore}',
              style: TextStyle(
                color: match.isWin == true ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              'vs',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10.sp,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeagueCell(String leagueName, bool isCompleted) {
    // 완료된 개인리그 = opacity 줄임
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.sp),
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
      child: Center(
        child: Text(
          leagueName,
          style: TextStyle(
            color: isCompleted ? Colors.amber.withOpacity(0.4) : Colors.amber,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Next 버튼 (메인)
          SizedBox(
            width: double.infinity,
            height: 44.sp,
            child: ElevatedButton(
              onPressed: () {
                context.go('/roster-select');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.sp),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Icon(Icons.double_arrow, size: 20.sp),
                ],
              ),
            ),
          ),

          SizedBox(height: 8.sp),

          // 하단 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 아이템 상점
              _BottomButton(
                icon: Icons.shopping_cart,
                label: '상점',
                onPressed: () => context.go('/shop'),
              ),

              // 장비 관리
              _BottomButton(
                icon: Icons.build,
                label: '장비',
                onPressed: () => context.go('/equipment'),
              ),

              // 정보 관리
              _BottomButton(
                icon: Icons.info_outline,
                label: '정보',
                onPressed: () => context.go('/info'),
              ),

              // 행동 관리
              _BottomButton(
                icon: Icons.fitness_center,
                label: '행동',
                onPressed: () => context.go('/action'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 일정 행 데이터
class _ScheduleRowData {
  final _MatchCellData? match1;
  final _MatchCellData? match2;
  final String leagueName;
  final bool isLeagueCompleted;
  final bool isCurrentWeek;

  _ScheduleRowData({
    this.match1,
    this.match2,
    required this.leagueName,
    required this.isLeagueCompleted,
    required this.isCurrentWeek,
  });
}

/// 경기 셀 데이터
class _MatchCellData {
  final Team? opponent;
  final bool isCompleted;
  final int? homeScore;
  final int? awayScore;
  final bool? isWin;

  _MatchCellData({
    this.opponent,
    required this.isCompleted,
    this.homeScore,
    this.awayScore,
    this.isWin,
  });
}

class _BottomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _BottomButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.sp,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16.sp),
        label: Text(
          label,
          style: TextStyle(fontSize: 11.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2a2a3e),
          foregroundColor: Colors.white70,
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.sp),
          ),
        ),
      ),
    );
  }
}
