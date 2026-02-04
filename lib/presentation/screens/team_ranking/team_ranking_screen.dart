import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';

/// 구단 순위 화면
class TeamRankingScreen extends ConsumerStatefulWidget {
  const TeamRankingScreen({super.key});

  @override
  ConsumerState<TeamRankingScreen> createState() => _TeamRankingScreenState();
}

class _TeamRankingScreenState extends ConsumerState<TeamRankingScreen> {
  String? _selectedTeamId;
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allTeams = gameState.saveData.allTeams;
    final playerTeam = gameState.playerTeam;

    // 팀 순위 정렬 (승점 기준)
    final sortedTeams = List<Team>.from(allTeams)
      ..sort((a, b) {
        // 승점 비교
        final aPoints = a.seasonRecord.wins * 3;
        final bPoints = b.seasonRecord.wins * 3;
        if (aPoints != bPoints) return bPoints - aPoints;
        // 세트 득실
        final aSetDiff = a.seasonRecord.setWins - a.seasonRecord.setLosses;
        final bSetDiff = b.seasonRecord.setWins - b.seasonRecord.setLosses;
        return bSetDiff - aSetDiff;
      });

    if (_showDetail && _selectedTeamId != null) {
      return _buildDetailScreen(gameState, _selectedTeamId!);
    }

    return _buildRankingScreen(context, sortedTeams, playerTeam);
  }

  Widget _buildRankingScreen(
    BuildContext context,
    List<Team> sortedTeams,
    Team playerTeam,
  ) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(context),

                // 메인 컨텐츠
                Expanded(
                  child: Row(
                    children: [
                      // 좌측: 현재 순위 + 선택된 팀 로고
                      Expanded(
                        flex: 1,
                        child: _buildLeftPanel(playerTeam, sortedTeams),
                      ),

                      // 우측: 순위표
                      Expanded(
                        flex: 2,
                        child: _buildRankingList(sortedTeams),
                      ),
                    ],
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context, sortedTeams),
              ],
            ),
            // R 버튼 (오른쪽 상단)
            Positioned(
              right: 12.sp,
              top: 12.sp,
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MyStarcraft   Season Mode   2012   S1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(Team playerTeam, List<Team> sortedTeams) {
    // 선택된 팀 또는 플레이어 팀
    final displayTeam = _selectedTeamId != null
        ? sortedTeams.firstWhere((t) => t.id == _selectedTeamId, orElse: () => playerTeam)
        : playerTeam;

    final rank = sortedTeams.indexWhere((t) => t.id == displayTeam.id) + 1;

    return Container(
      padding: EdgeInsets.all(24.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '현재 순위 >>',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
            ),
          ),

          SizedBox(height: 24.sp),

          // 팀 로고
          Container(
            width: 120.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Center(
              child: Text(
                displayTeam.shortName,
                style: TextStyle(
                  color: Color(displayTeam.colorValue),
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: 16.sp),

          Text(
            displayTeam.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),

          SizedBox(height: 8.sp),

          Text(
            '$rank위',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<Team> sortedTeams) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      child: ListView.builder(
        itemCount: sortedTeams.length,
        itemBuilder: (context, index) {
          final team = sortedTeams[index];
          final rank = index + 1;
          final isSelected = _selectedTeamId == team.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTeamId = team.id;
              });
            },
            onDoubleTap: () {
              setState(() {
                _selectedTeamId = team.id;
                _showDetail = true;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4.sp),
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(4.sp),
                border: isSelected
                    ? Border.all(color: AppColors.accent)
                    : null,
              ),
              child: Row(
                children: [
                  // 순위
                  SizedBox(
                    width: 40.sp,
                    child: Text(
                      '$rank위',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),

                  // 팀 로고
                  Container(
                    width: 40.sp,
                    height: 30.sp,
                    margin: EdgeInsets.symmetric(horizontal: 8.sp),
                    decoration: BoxDecoration(
                      color: Color(team.colorValue).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Center(
                      child: Text(
                        team.shortName,
                        style: TextStyle(
                          color: Color(team.colorValue),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 팀명
                  Expanded(
                    child: Text(
                      team.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),

                  // 전적
                  Text(
                    '${team.seasonRecord.wins}W ${team.seasonRecord.losses}L',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),

                  SizedBox(width: 16.sp),

                  // 세트 스코어
                  Text(
                    '(${team.seasonRecord.setWins}:${team.seasonRecord.setLosses})',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, List<Team> sortedTeams) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 팀 선택 드롭다운
          Container(
            width: 200.sp,
            padding: EdgeInsets.symmetric(horizontal: 12.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: DropdownButton<String>(
              value: _selectedTeamId,
              hint: const Text('팀 선택'),
              isExpanded: true,
              underline: const SizedBox(),
              items: sortedTeams.map((team) {
                return DropdownMenuItem(
                  value: team.id,
                  child: Text(team.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTeamId = value;
                });
              },
            ),
          ),

          SizedBox(width: 24.sp),

          // EXIT 버튼
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  'EXIT [Bar]',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== 팀 상세 화면 =====

  Widget _buildDetailScreen(GameState gameState, String teamId) {
    final team = gameState.saveData.getTeamById(teamId);
    if (team == null) {
      setState(() => _showDetail = false);
      return const SizedBox();
    }

    final players = gameState.saveData.getTeamPlayers(teamId);
    final allTeams = gameState.saveData.allTeams;
    final rank = allTeams
            .toList()
            .indexWhere((t) => t.id == teamId) + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '0번 시즌 성적',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 팀 정보 요약
            Container(
              padding: EdgeInsets.all(16.sp),
              child: Row(
                children: [
                  // 팀 로고
                  Container(
                    width: 100.sp,
                    height: 70.sp,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Center(
                      child: Text(
                        team.shortName,
                        style: TextStyle(
                          color: Color(team.colorValue),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 24.sp),

                  // 총 전적
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '총 전적',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 4.sp),
                      Row(
                        children: [
                          Text(
                            '${team.seasonRecord.wins}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' Win',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 16.sp),
                          Text(
                            '${team.seasonRecord.losses}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' Loss',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.sp),
                      Text(
                        'Set Score: ${team.seasonRecord.setWins} W ${team.seasonRecord.setLosses} L',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 팀명 + 순위
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.sp),
              child: Row(
                children: [
                  Text(
                    team.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Text(
                    '$rank위',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 8.sp),

            // 선수별 전적 테이블
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16.sp),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Column(
                  children: [
                    // 헤더
                    Container(
                      padding: EdgeInsets.all(8.sp),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 100.sp, child: Text('선수', style: _headerStyle)),
                          Expanded(child: Text('Total', style: _headerStyle, textAlign: TextAlign.center)),
                          Expanded(child: Text('vs T', style: _headerStyle, textAlign: TextAlign.center)),
                          Expanded(child: Text('vs Z', style: _headerStyle, textAlign: TextAlign.center)),
                          Expanded(child: Text('vs P', style: _headerStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),

                    // 선수 목록
                    Expanded(
                      child: ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          return _buildPlayerRecordRow(player);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Container(
              padding: EdgeInsets.all(16.sp),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 팀 선택 드롭다운
                  Container(
                    width: 200.sp,
                    padding: EdgeInsets.symmetric(horizontal: 12.sp),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedTeamId,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: allTeams.map((t) {
                        return DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTeamId = value;
                        });
                      },
                    ),
                  ),

                  SizedBox(width: 24.sp),

                  // EXIT 버튼
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showDetail = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardBackground,
                      padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 12.sp),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                        Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text(
                          'EXIT [Bar]',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _headerStyle => TextStyle(
        color: Colors.grey,
        fontSize: 11.sp,
      );

  Widget _buildPlayerRecordRow(Player player) {
    final record = player.record;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // 선수명 + 종족
          SizedBox(
            width: 100.sp,
            child: Row(
              children: [
                Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                  ),
                ),
                Text(
                  ' (${player.race.code})',
                  style: TextStyle(
                    color: _getRaceColor(player.race),
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),

          // Total
          Expanded(
            child: Text(
              '${record.wins} X ${record.losses}',
              style: TextStyle(color: Colors.white, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
          ),

          // vs T
          Expanded(
            child: Text(
              '${record.vsTerranWins} : ${record.vsTerranLosses}',
              style: TextStyle(color: Colors.white, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
          ),

          // vs Z
          Expanded(
            child: Text(
              '${record.vsZergWins} : ${record.vsZergLosses}',
              style: TextStyle(color: Colors.white, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
          ),

          // vs P
          Expanded(
            child: Text(
              '${record.vsProtossWins} : ${record.vsProtossLosses}',
              style: TextStyle(color: Colors.white, fontSize: 10.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
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
