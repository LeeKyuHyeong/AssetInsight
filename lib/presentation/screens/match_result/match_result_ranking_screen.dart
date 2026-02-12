import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 경기 후 팀 순위 화면
/// 프로리그 한 경기가 끝날 때마다 표시
class MatchResultRankingScreen extends ConsumerWidget {
  final VoidCallback? onNext;

  const MatchResultRankingScreen({
    super.key,
    this.onNext,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final playerRank = sortedTeams.indexWhere((t) => t.id == playerTeam.id) + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(),

            // 메인 컨텐츠
            Expanded(
              child: Row(
                children: [
                  // 좌측: 내 팀 순위 패널
                  Expanded(
                    flex: 1,
                    child: _buildMyTeamPanel(playerTeam, playerRank),
                  ),

                  // 우측: 전체 팀 순위 리스트
                  Expanded(
                    flex: 2,
                    child: _buildRankingList(sortedTeams, playerTeam.id),
                  ),
                ],
              ),
            ),

            // 하단 버튼
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          ResetButton.back(),
          const Spacer(),
          Icon(Icons.leaderboard, color: Colors.amber, size: 24.sp),
          SizedBox(width: 12.sp),
          Text(
            '프로리그 순위',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const ResetButton(small: true),
        ],
      ),
    );
  }

  Widget _buildMyTeamPanel(Team playerTeam, int rank) {
    return Container(
      padding: EdgeInsets.all(24.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '현재 순위 >>',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
            ),
          ),

          SizedBox(height: 32.sp),

          // 팀 로고
          Container(
            width: 140.sp,
            height: 100.sp,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.sp),
              boxShadow: [
                BoxShadow(
                  color: Color(playerTeam.colorValue).withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: Color(playerTeam.colorValue),
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(height: 20.sp),

          // 팀명
          Text(
            playerTeam.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12.sp),

          // 순위
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.sp),
              border: Border.all(color: _getRankColor(rank)),
            ),
            child: Text(
              '$rank위',
              style: TextStyle(
                color: _getRankColor(rank),
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          SizedBox(height: 16.sp),

          // 전적
          Text(
            '${playerTeam.seasonRecord.wins}W ${playerTeam.seasonRecord.losses}L',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
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

  Widget _buildRankingList(List<Team> sortedTeams, String playerTeamId) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 50.sp, child: _headerText('순위')),
                SizedBox(width: 50.sp, child: _headerText('팀')),
                Expanded(child: _headerText('팀명')),
                SizedBox(width: 40.sp, child: _headerText('W')),
                SizedBox(width: 40.sp, child: _headerText('L')),
                SizedBox(width: 60.sp, child: _headerText('득실')),
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
                final setDiff = team.seasonRecord.setWins - team.seasonRecord.setLosses;

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 10.sp),
                  decoration: BoxDecoration(
                    color: isMyTeam ? AppColors.primary.withOpacity(0.2) : null,
                    border: isMyTeam
                        ? Border.all(color: AppColors.accent, width: 2)
                        : Border(
                            bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                    borderRadius: isMyTeam ? BorderRadius.circular(4.sp) : null,
                  ),
                  child: Row(
                    children: [
                      // 순위
                      SizedBox(
                        width: 50.sp,
                        child: Text(
                          '$rank위',
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
                        width: 50.sp,
                        child: Container(
                          width: 40.sp,
                          height: 28.sp,
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
                      ),

                      // 팀명
                      Expanded(
                        child: Text(
                          team.name,
                          style: TextStyle(
                            color: isMyTeam ? Colors.white : Colors.grey[300],
                            fontSize: 13.sp,
                            fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),

                      // W
                      SizedBox(
                        width: 40.sp,
                        child: Text(
                          '${team.seasonRecord.wins}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // L
                      SizedBox(
                        width: 40.sp,
                        child: Text(
                          '${team.seasonRecord.losses}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      // 득실차
                      SizedBox(
                        width: 60.sp,
                        child: Text(
                          setDiff >= 0 ? '+$setDiff' : '$setDiff',
                          style: TextStyle(
                            color: setDiff > 0
                                ? Colors.green
                                : (setDiff < 0 ? Colors.red : Colors.grey),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
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
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: ElevatedButton(
        onPressed: onNext ?? () => Navigator.of(context).pop(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 64.sp, vertical: 14.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8.sp),
            Icon(Icons.arrow_right, color: Colors.white, size: 20.sp),
            Icon(Icons.arrow_right, color: Colors.white, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
