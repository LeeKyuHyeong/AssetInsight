import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/initial_data.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';

/// 메인 메뉴 화면 - 일정 및 행동 관리
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen> {
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
    '8강 1R',
    '8강 2R',
  ];

  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final gameState = ref.watch(gameStateProvider);

    // Preview 모드: gameState가 없을 때 초기 데이터 사용
    final isPreviewMode = gameState == null;
    final allTeams = isPreviewMode ? InitialData.createTeams() : gameState.saveData.allTeams;
    final playerTeam = isPreviewMode ? allTeams.first : gameState.playerTeam;
    final seasonNumber = isPreviewMode ? 1 : gameState.saveData.currentSeason.number;

    // 선택된 팀 (기본값: 플레이어 팀)
    _selectedTeamId ??= playerTeam.id;
    final selectedTeam = allTeams.firstWhere(
      (t) => t.id == _selectedTeamId,
      orElse: () => playerTeam,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(selectedTeam, seasonNumber, allTeams, playerTeam),

                // 메인 컨텐츠 - 3열 일정 테이블
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 8.sp),
                    child: _buildScheduleTable(context, gameState, selectedTeam, allTeams, isPreviewMode),
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

  Widget _buildHeader(Team selectedTeam, int seasonNumber, List<Team> allTeams, Team playerTeam) {
    final teamColor = Color(selectedTeam.colorValue);

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
          // 팀 로고 (탭하면 팀 선택 드롭다운)
          GestureDetector(
            onTap: () => _showTeamSelector(allTeams, playerTeam),
            child: Container(
              width: 50.sp,
              height: 50.sp,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: teamColor, width: 2),
              ),
              child: Center(
                child: Text(
                  selectedTeam.shortName,
                  style: TextStyle(
                    color: teamColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sp),

          // 팀명 + 시즌 (탭하면 팀 선택)
          Expanded(
            child: GestureDetector(
              onTap: () => _showTeamSelector(allTeams, playerTeam),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          selectedTeam.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.sp),
                      Icon(
                        Icons.unfold_more,
                        color: Colors.grey[500],
                        size: 16.sp,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.sp),
                  Text(
                    selectedTeam.id == playerTeam.id
                        ? 'S$seasonNumber'
                        : 'S$seasonNumber  (내 팀: ${playerTeam.shortName})',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // R 버튼 공간 확보
          SizedBox(width: 48.sp),
        ],
      ),
    );
  }

  void _showTeamSelector(List<Team> allTeams, Team playerTeam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a2e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.sp)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                child: Text(
                  '구단 선택',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: Colors.grey[700], height: 1),
              ...allTeams.map((team) {
                final isSelected = team.id == _selectedTeamId;
                final isPlayerTeam = team.id == playerTeam.id;
                final teamColor = Color(team.colorValue);
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 32.sp,
                    height: 32.sp,
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: teamColor, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        team.shortName.length >= 2
                            ? team.shortName.substring(0, 2)
                            : team.shortName,
                        style: TextStyle(
                          color: teamColor,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    isPlayerTeam ? '${team.name} (내 팀)' : team.name,
                    style: TextStyle(
                      color: isSelected ? Colors.amber : Colors.white,
                      fontSize: 13.sp,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: Colors.amber, size: 18.sp)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedTeamId = team.id;
                    });
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScheduleTable(BuildContext context, dynamic gameState, Team selectedTeam, List<Team> allTeams, bool isPreviewMode) {
    // 10행 (각 행 = 경기1 + 경기2 + 개인리그)
    final rows = _buildScheduleRows(gameState, selectedTeam, allTeams, isPreviewMode);

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

  List<_ScheduleRowData> _buildScheduleRows(dynamic gameState, Team selectedTeam, List<Team> allTeams, bool isPreviewMode) {
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
          weekIndex: i,
        ));
      }
    } else {
      // 실제 데이터
      final season = gameState.saveData.currentSeason as Season;
      final schedule = season.proleagueSchedule;
      final selectedTeamId = selectedTeam.id;

      // 선택된 팀 경기를 슬롯(roundNumber)별로 맵핑
      final matchBySlot = <int, ScheduleItem>{};
      for (final match in schedule) {
        if (match.homeTeamId == selectedTeamId || match.awayTeamId == selectedTeamId) {
          matchBySlot[match.roundNumber] = match;
        }
      }

      // weekProgress 기반 현재 주차/스텝
      final currentWeekIndex = season.currentWeek;
      final currentStepValue = season.currentStep;

      for (int i = 0; i < 11; i++) {
        final slot1 = i * 2 + 1;
        final slot2 = i * 2 + 2;

        _MatchCellData? match1Data;
        _MatchCellData? match2Data;

        // 슬롯1의 경기 (경기1)
        final match1 = matchBySlot[slot1];
        if (match1 != null) {
          final isHome = match1.homeTeamId == selectedTeamId;
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

        // 슬롯2의 경기 (경기2)
        final match2 = matchBySlot[slot2];
        if (match2 != null) {
          final isHome = match2.homeTeamId == selectedTeamId;
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

        // 개인리그 완료: 현재 주보다 이전 주차면 완료
        final isLeagueCompleted = i < currentWeekIndex || season.isWeekProgressComplete;

        final isThisCurrentWeek = i == currentWeekIndex && !season.isWeekProgressComplete;

        rows.add(_ScheduleRowData(
          match1: match1Data,
          match2: match2Data,
          leagueName: _individualLeagueNames[i],
          isLeagueCompleted: isLeagueCompleted,
          isCurrentWeek: isThisCurrentWeek,
          weekIndex: i,
          currentStep: isThisCurrentWeek ? currentStepValue : null,
        ));
      }
    }

    return rows;
  }

  Widget _buildScheduleRow(BuildContext context, _ScheduleRowData row, int index) {
    final isCurrentWeek = row.isCurrentWeek;
    final currentStep = row.currentStep;

    return Container(
      margin: EdgeInsets.only(bottom: 4.sp),
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: isCurrentWeek ? Colors.amber.withOpacity(0.05) : const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(4.sp),
        border: isCurrentWeek ? Border.all(color: Colors.amber.withOpacity(0.3), width: 1) : null,
      ),
      child: Row(
        children: [
          // 경기 1 (step 0 하이라이트)
          Expanded(
            flex: 3,
            child: Container(
              decoration: currentStep == 0
                  ? BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    )
                  : null,
              child: _buildMatchCell(row.match1),
            ),
          ),

          // 구분선 (회색)
          Container(
            width: 1,
            height: 36.sp,
            color: Colors.grey[700],
          ),

          // 경기 2 (step 1 하이라이트)
          Expanded(
            flex: 3,
            child: Container(
              decoration: currentStep == 1
                  ? BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    )
                  : null,
              child: _buildMatchCell(row.match2),
            ),
          ),

          // 구분선 (녹색) - 컨디션 회복 안내
          Container(
            width: 2.sp,
            height: 36.sp,
            color: Colors.green,
          ),

          // 개인리그 (step 2 하이라이트)
          Expanded(
            flex: 2,
            child: Container(
              decoration: currentStep == 2
                  ? BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: Colors.amber, width: 1.5),
                    )
                  : null,
              child: _buildLeagueCell(context, row.leagueName, row.isLeagueCompleted, row.weekIndex),
            ),
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
          // 팀 로고 (탭하면 구단정보로 이동)
          GestureDetector(
            onTap: () => context.push('/info?teamId=${opponent.id}&tab=1'),
            child: Container(
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

  Widget _buildLeagueCell(BuildContext context, String leagueName, bool isCompleted, int weekIndex) {
    final gameState = ref.read(gameStateProvider);
    final hasLeagueData = gameState?.saveData.currentSeason.individualLeague != null;

    return GestureDetector(
      onTap: hasLeagueData ? () => _navigateToLeague(context, weekIndex, viewOnly: true) : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.sp),
        padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
        child: Center(
          child: Text(
            leagueName,
            style: TextStyle(
              color: isCompleted ? Colors.amber.withOpacity(0.4) : Colors.amber,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              decoration: hasLeagueData ? TextDecoration.underline : null,
              decorationColor: Colors.amber.withOpacity(0.3),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  /// 개인리그 주차별 대진표 화면으로 이동
  /// [viewOnly] false면 실제 진행, true면 조회만
  void _navigateToLeague(BuildContext context, int weekIndex, {bool viewOnly = false}) {
    final vo = viewOnly ? '?viewOnly=true' : '';
    // weekIndex → 개인리그 스테이지 매핑
    // 0: PC방, 1: 듀얼 1R, 2: 듀얼 2R, 3: 듀얼 3R
    // 4: 조지명, 5: 32강 1R, 6: 32강 2R, 7: 16강 1R, 8: 16강 2R, 9: 8강 1R, 10: 8강 2R
    switch (weekIndex) {
      case 0:
        context.push('/individual-league/pcbang$vo');
        break;
      case 1:
        context.push('/individual-league/dual/1$vo');
        break;
      case 2:
        context.push('/individual-league/dual/2$vo');
        break;
      case 3:
        context.push('/individual-league/dual/3$vo');
        break;
      case 4:
        context.push('/individual-league/group-draw$vo');
        break;
      case 5:
      case 6:
        context.push('/individual-league/main/32$vo');
        break;
      case 7:
      case 8:
        context.push('/individual-league/main/16$vo');
        break;
      case 9:
      case 10:
        context.push('/individual-league/main/8$vo');
        break;
    }
  }

  /// NEXT 버튼 정보 계산
  ({String label, VoidCallback? onPressed, Color bgColor}) _getNextButtonInfo(BuildContext context) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) {
      return (label: 'Next ▶▶', onPressed: null, bgColor: Colors.grey);
    }

    final season = gameState.saveData.currentSeason;
    final playerTeamId = gameState.saveData.playerTeamId;

    // 시즌 완료
    if (season.isWeekProgressComplete) {
      return (label: '정규시즌 완료', onPressed: null, bgColor: Colors.grey);
    }

    final currentWeek = season.currentWeek;
    final currentStep = season.currentStep;
    final schedule = season.proleagueSchedule;

    // 현재 스텝의 슬롯 번호
    final slot = currentWeek * 2 + (currentStep == 0 ? 1 : 2);

    // 플레이어 팀의 해당 슬롯 매치 찾기
    ScheduleItem? playerMatch;
    if (currentStep < 2) {
      for (final match in schedule) {
        if (match.roundNumber == slot &&
            (match.homeTeamId == playerTeamId || match.awayTeamId == playerTeamId)) {
          playerMatch = match;
          break;
        }
      }
    }

    final notifier = ref.read(gameStateProvider.notifier);

    if (currentStep == 2) {
      // step 2: 개인리그
      return (
        label: '개인리그 ▶▶',
        onPressed: () {
          notifier.advanceWeekProgress();
          _navigateToLeague(context, currentWeek);
          notifier.save();
        },
        bgColor: Colors.amber,
      );
    } else if (playerMatch != null && !playerMatch.isCompleted) {
      // step 0/1: 매치 있음 → 로스터 선택
      // 위너스리그 시즌이면 위너스리그 로스터로 이동
      final isWinnersSeason = season.isWinnersLeagueSeason;
      return (
        label: isWinnersSeason ? 'Winners ▶▶' : 'Next ▶▶',
        onPressed: () => context.go(isWinnersSeason ? '/wl-roster-select' : '/roster-select'),
        bgColor: isWinnersSeason ? Colors.amber : Colors.amber,
      );
    } else {
      // step 0/1: no match → 건너뛰기 (다른 팀 경기도 시뮬레이션)
      return (
        label: '경기 없음 - 건너뛰기',
        onPressed: () {
          notifier.skipRound(slot);
          notifier.save();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentStep == 1 ? '경기 없음 (주간 보너스 적용)' : '경기 없음',
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        bgColor: const Color(0xFF4a4a5e),
      );
    }
  }

  Widget _buildBottomButtons(BuildContext context) {
    final nextInfo = _getNextButtonInfo(context);

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
              onPressed: nextInfo.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: nextInfo.bgColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.sp),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    nextInfo.label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                onPressed: () => context.push('/shop'),
              ),

              // 장비 관리
              _BottomButton(
                icon: Icons.build,
                label: '장비',
                onPressed: () => context.push('/equipment'),
              ),

              // 정보 관리
              _BottomButton(
                icon: Icons.info_outline,
                label: '정보',
                onPressed: () => context.push('/info'),
              ),

              // 행동 관리
              _BottomButton(
                icon: Icons.fitness_center,
                label: '행동',
                onPressed: () => context.push('/action'),
              ),

              // 디버그: 듀얼토너먼트 스킵
              _BottomButton(
                icon: Icons.fast_forward,
                label: 'DEBUG',
                onPressed: () {
                  final notifier = ref.read(gameStateProvider.notifier);
                  notifier.debugSkipToDualTournament();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('듀얼토너먼트까지 스킵 완료! 개인리그 버튼을 눌러주세요'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),

              // 디버그: 플레이오프 스킵
              _BottomButton(
                icon: Icons.emoji_events,
                label: 'PO',
                onPressed: () {
                  final notifier = ref.read(gameStateProvider.notifier);
                  notifier.debugSkipToPlayoff();
                  setState(() {});
                  context.push('/playoff');
                },
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
  final int weekIndex;
  final int? currentStep; // 현재 주차일 때 0/1/2, 아니면 null

  _ScheduleRowData({
    this.match1,
    this.match2,
    required this.leagueName,
    required this.isLeagueCompleted,
    required this.isCurrentWeek,
    required this.weekIndex,
    this.currentStep,
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
