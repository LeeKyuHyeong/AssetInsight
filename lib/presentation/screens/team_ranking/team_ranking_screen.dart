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

    // 팀 순위 정렬 (승점 → 세트 득실 → 상대 전적)
    final standings = ref.read(gameStateProvider.notifier).calculateStandings();
    final sortedTeams = standings.map((s) =>
      allTeams.firstWhere((t) => t.id == s.teamId)
    ).toList();

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

                // 상단: 선택된 팀 현재 순위
                _buildTopRankBox(playerTeam, sortedTeams),

                // 하단: 전체 순위표 (전체 가로 사용)
                Expanded(
                  child: _buildRankingList(sortedTeams),
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
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '구단 순위',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // R 버튼 공간 확보
          SizedBox(width: 48.sp),
        ],
      ),
    );
  }

  Widget _buildTopRankBox(Team playerTeam, List<Team> sortedTeams) {
    final displayTeam = _selectedTeamId != null
        ? sortedTeams.firstWhere((t) => t.id == _selectedTeamId, orElse: () => playerTeam)
        : playerTeam;

    final rank = sortedTeams.indexWhere((t) => t.id == displayTeam.id) + 1;
    final setDiff = displayTeam.seasonRecord.setWins - displayTeam.seasonRecord.setLosses;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10.sp),
        border: Border.all(
          color: _getRankColor(rank).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // 순위 배지
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: _getRankColor(rank)),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  color: _getRankColor(rank),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.sp),

          // 팀 로고
          Container(
            width: 48.sp,
            height: 34.sp,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.sp),
              boxShadow: [
                BoxShadow(
                  color: Color(displayTeam.colorValue).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                displayTeam.shortName,
                style: TextStyle(
                  color: Color(displayTeam.colorValue),
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.sp),

          // 팀명
          Expanded(
            child: Text(
              displayTeam.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 전적
          Text(
            '${displayTeam.seasonRecord.wins}W ${displayTeam.seasonRecord.losses}L',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
            ),
          ),

          SizedBox(width: 12.sp),

          // 세트 득실
          Text(
            setDiff >= 0 ? '+$setDiff' : '$setDiff',
            style: TextStyle(
              color: setDiff > 0 ? Colors.green : setDiff < 0 ? Colors.red : Colors.grey,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber;
    if (rank == 2) return Colors.grey[300]!;
    if (rank == 3) return Colors.brown[300]!;
    if (rank <= 4) return Colors.green; // 포스트시즌 진출권
    return Colors.white;
  }

  Widget _buildRankingList(List<Team> sortedTeams) {
    final gameState = ref.read(gameStateProvider);
    final playerTeamId = gameState?.playerTeam.id ?? '';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.sp),
      padding: EdgeInsets.symmetric(horizontal: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 30.sp, child: _headerText('#')),
                SizedBox(width: 40.sp, child: _headerText('로고')),
                Expanded(child: Align(alignment: Alignment.centerLeft, child: _headerText('팀명'))),
                SizedBox(width: 32.sp, child: _headerText('W')),
                SizedBox(width: 32.sp, child: _headerText('L')),
                SizedBox(width: 50.sp, child: _headerText('득실')),
              ],
            ),
          ),

          // 팀 목록
          Expanded(
            child: ListView.builder(
              itemCount: sortedTeams.length,
              itemBuilder: (context, index) {
                final team = sortedTeams[index];
                final rank = index + 1;
                final isMyTeam = team.id == playerTeamId;
                final isSelected = _selectedTeamId == team.id;
                final setDiff = team.seasonRecord.setWins - team.seasonRecord.setLosses;

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
                    padding: EdgeInsets.symmetric(vertical: 10.sp),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.amber.withValues(alpha: 0.3)
                          : isMyTeam
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        // 순위
                        SizedBox(
                          width: 30.sp,
                          child: Text(
                            '$rank',
                            style: TextStyle(
                              color: _getRankColor(rank),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 팀 로고
                        SizedBox(
                          width: 40.sp,
                          child: Container(
                            width: 34.sp,
                            height: 24.sp,
                            decoration: BoxDecoration(
                              color: Color(team.colorValue).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4.sp),
                            ),
                            child: Center(
                              child: Text(
                                team.shortName,
                                style: TextStyle(
                                  color: Color(team.colorValue),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 팀명
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 4.sp),
                            child: Text(
                              team.name,
                              style: TextStyle(
                                color: isMyTeam ? Colors.amber : Colors.white,
                                fontSize: 12.sp,
                                fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        // 승
                        SizedBox(
                          width: 32.sp,
                          child: Text(
                            '${team.seasonRecord.wins}',
                            style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 패
                        SizedBox(
                          width: 32.sp,
                          child: Text(
                            '${team.seasonRecord.losses}',
                            style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 세트 득실
                        SizedBox(
                          width: 50.sp,
                          child: Text(
                            setDiff >= 0 ? '+$setDiff' : '$setDiff',
                            style: TextStyle(
                              color: setDiff > 0
                                  ? Colors.green
                                  : setDiff < 0
                                      ? Colors.red
                                      : Colors.grey,
                              fontSize: 12.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  Widget _headerText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey,
        fontSize: 11.sp,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomButtons(BuildContext context, List<Team> sortedTeams) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      child: Row(
        children: [
          // 팀 선택 드롭다운
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: DropdownButton<String>(
                value: _selectedTeamId,
                hint: Text(
                  '팀 선택',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14.sp,
                ),
                items: sortedTeams.map((team) {
                  return DropdownMenuItem(
                    value: team.id,
                    child: Text(
                      team.name,
                      style: const TextStyle(color: Colors.black87),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTeamId = value;
                  });
                },
              ),
            ),
          ),

          SizedBox(width: 12.sp),

          // EXIT 버튼
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => context.go('/main'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardBackground,
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                    Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                    SizedBox(width: 4.sp),
                    Text(
                      'EXIT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
              ),
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
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
              child: Row(
                children: [
                  // 팀 선택 드롭다운
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.sp),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTeamId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        dropdownColor: Colors.white,
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14.sp,
                        ),
                        items: allTeams.map((t) {
                          return DropdownMenuItem(
                            value: t.id,
                            child: Text(
                              t.name,
                              style: const TextStyle(color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTeamId = value;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(width: 12.sp),

                  // EXIT 버튼
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showDetail = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBackground,
                        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                            Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                            SizedBox(width: 4.sp),
                            Text(
                              'EXIT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
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
