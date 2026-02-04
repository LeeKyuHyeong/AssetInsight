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

                // 메인 컨텐츠 - 세로 모드용 일정
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
                    child: _buildSeasonScheduleMain(context, gameState, playerTeam, allTeams, isPreviewMode),
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

          // 팀명 + 에이스 (세로 배치)
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

  Widget _buildTeamLogo(dynamic playerTeam) {
    final teamColor = Color(playerTeam.colorValue);
    return Container(
      width: 120.sp,
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF12121a),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: teamColor.withOpacity(0.5), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.sp,
            height: 80.sp,
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
                  fontSize: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 개인리그 일정 이름 (10주차)
  static const List<String> _individualLeagueNames = [
    'PC방 예선전',
    '듀얼토너먼트 1R',
    '듀얼토너먼트 2R',
    '듀얼토너먼트 3R',
    '조지명식',
    '32강 1R',
    '32강 2R',
    '16강 1R',
    '16강 2R',
    '8강 / 4강 / 결승',
  ];

  Widget _buildSeasonScheduleMain(BuildContext context, dynamic gameState, Team playerTeam, List<Team> allTeams, bool isPreviewMode) {
    // Preview 모드일 때 샘플 일정 생성 (20라운드)
    final List<Map<String, dynamic>> previewMatches = isPreviewMode
        ? List.generate(20, (i) {
            final opponentTeam = allTeams[(i + 1) % allTeams.length];
            return {
              'round': i + 1,
              'opponent': opponentTeam.shortName,
              'opponentColor': opponentTeam.colorValue,
              'opponentName': opponentTeam.name,
              'opponentId': opponentTeam.id,
              'isCompleted': i < 4,
              'isHome': i % 2 == 0,
              'homeScore': i < 4 ? (i % 2 == 0 ? 3 : 1) : null,
              'awayScore': i < 4 ? (i % 2 == 0 ? 1 : 3) : null,
            };
          })
        : [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12121a),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // 헤더: 팀명 + 컨디션 회복
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.sp)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  playerTeam.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '총 20경기 | 2경기마다 개인리그 & 컨디션 회복',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // 일정 리스트
          Expanded(
            child: isPreviewMode
                ? ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                    itemCount: 40, // 20 matches + 10 condition rows + 10 league rows
                    itemBuilder: (ctx, index) {
                      // 4개마다 그룹: match1, match2, 컨디션회복, 개인리그
                      final groupIndex = index ~/ 4;
                      final posInGroup = index % 4;

                      if (posInGroup == 2) {
                        // 컨디션 회복 행
                        return _buildConditionRow();
                      } else if (posInGroup == 3) {
                        // 개인리그 행 - Preview에서는 2주차(groupIndex=1)까지만 완료로 표시
                        final weekCompleted = groupIndex < 2;
                        return _buildLeagueRow(context, groupIndex, canStart: weekCompleted);
                      } else {
                        // 매치 행 (posInGroup 0 or 1)
                        final matchIndex = groupIndex * 2 + posInGroup;
                        if (matchIndex >= 20) return const SizedBox.shrink();
                        final match = previewMatches[matchIndex];
                        return _buildScheduleRow(
                          context: context,
                          round: match['round'] as int,
                          opponentShort: match['opponent'] as String,
                          opponentName: match['opponentName'] as String,
                          opponentColor: match['opponentColor'] as int,
                          opponentId: match['opponentId'] as String,
                          isCompleted: match['isCompleted'] as bool,
                          isHome: match['isHome'] as bool,
                          homeScore: match['homeScore'] as int?,
                          awayScore: match['awayScore'] as int?,
                          isNext: matchIndex == 4,
                        );
                      }
                    },
                  )
                : _buildRealScheduleList(context, gameState, playerTeam),
          ),
        ],
      ),
    );
  }

  // 개인리그 라우트 매핑 (10주차)
  static const List<String> _individualLeagueRoutes = [
    '/individual-league/pcbang',      // PC방 예선전
    '/individual-league/dual/1',      // 듀얼토너먼트 1R
    '/individual-league/dual/2',      // 듀얼토너먼트 2R
    '/individual-league/dual/3',      // 듀얼토너먼트 3R
    '/individual-league/group-draw',  // 조지명식
    '/individual-league/main/32-1',   // 32강 1R
    '/individual-league/main/32-2',   // 32강 2R
    '/individual-league/main/16-1',   // 16강 1R
    '/individual-league/main/16-2',   // 16강 2R
    '/individual-league/main/final',  // 8강 / 4강 / 결승
  ];

  Widget _buildConditionRow() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: Colors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(color: Colors.cyan.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: Colors.cyan, size: 14.sp),
          SizedBox(width: 8.sp),
          Text(
            '컨디션 회복',
            style: TextStyle(
              color: Colors.cyan,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeagueRow(BuildContext context, int eventIndex, {bool canStart = false}) {
    final eventName = eventIndex < _individualLeagueNames.length
        ? _individualLeagueNames[eventIndex]
        : '개인리그';
    final route = eventIndex < _individualLeagueRoutes.length
        ? _individualLeagueRoutes[eventIndex]
        : '/individual-league';

    // 시작 불가능하면 대진표 조회만 가능
    final isLocked = !canStart;

    return GestureDetector(
      onTap: () {
        // 개인리그 대진표 화면으로 이동 (조회 or 진행)
        context.go('$route?viewOnly=${isLocked ? 'true' : 'false'}');
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 2.sp),
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.grey.withOpacity(0.1)
              : Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4.sp),
          border: Border.all(
            color: isLocked
                ? Colors.grey.withOpacity(0.3)
                : Colors.amber.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isLocked ? Icons.lock : Icons.emoji_events,
              color: isLocked ? Colors.grey : Colors.amber,
              size: 14.sp,
            ),
            SizedBox(width: 8.sp),
            Text(
              eventName,
              style: TextStyle(
                color: isLocked ? Colors.grey : Colors.amber,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8.sp),
            Text(
              isLocked ? '(대진표 조회)' : '',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 9.sp,
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 10.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildRealScheduleList(BuildContext context, dynamic gameState, Team playerTeam) {
    final List<ScheduleItem> schedule = List<ScheduleItem>.from(
      gameState.saveData.currentSeason.proleagueSchedule
    );
    final playerTeamId = gameState.saveData.playerTeamId;

    // 내 팀 매치만 필터링하고 라운드 순으로 정렬
    final myMatches = schedule.where((s) =>
      s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId
    ).toList()..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    // 첫 번째 미완료 매치 인덱스 찾기
    final firstIncompleteIndex = myMatches.indexWhere((m) => !m.isCompleted);

    // 총 아이템 수: 20매치 + 10개 컨디션 회복 + 10개 개인리그 = 40개
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      itemCount: 40,
      itemBuilder: (ctx, index) {
        // 4개마다 그룹: match1, match2, 컨디션회복, 개인리그
        final groupIndex = index ~/ 4;
        final posInGroup = index % 4;

        if (posInGroup == 2) {
          // 컨디션 회복 행
          return _buildConditionRow();
        } else if (posInGroup == 3) {
          // 개인리그 행 - 이전 2경기 완료 여부 체크
          final weekFirstMatchIndex = groupIndex * 2;
          final weekSecondMatchIndex = groupIndex * 2 + 1;
          final weekCompleted = weekFirstMatchIndex < myMatches.length &&
              weekSecondMatchIndex < myMatches.length &&
              myMatches[weekFirstMatchIndex].isCompleted &&
              myMatches[weekSecondMatchIndex].isCompleted;
          return _buildLeagueRow(context, groupIndex, canStart: weekCompleted);
        } else {
          // 매치 행 (posInGroup 0 or 1)
          final matchIndex = groupIndex * 2 + posInGroup;
          if (matchIndex >= myMatches.length) {
            // No Match 표시
            return _buildNoMatchRow();
          }

          final match = myMatches[matchIndex];
          final isHome = match.homeTeamId == playerTeamId;
          final opponentId = isHome ? match.awayTeamId : match.homeTeamId;
          final opponent = gameState.saveData.getTeamById(opponentId);

          return _buildScheduleRow(
            context: context,
            round: match.roundNumber,
            opponentShort: opponent?.shortName ?? '???',
            opponentName: opponent?.name ?? '???',
            opponentColor: opponent?.colorValue ?? 0xFF888888,
            opponentId: opponentId,
            isCompleted: match.isCompleted,
            isHome: isHome,
            homeScore: match.result?.homeScore,
            awayScore: match.result?.awayScore,
            isNext: matchIndex == firstIncompleteIndex,
          );
        }
      },
    );
  }

  Widget _buildNoMatchRow() {
    return Container(
      margin: EdgeInsets.only(bottom: 4.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.5),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Center(
        child: Text(
          'No Match',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11.sp,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleRow({
    required BuildContext context,
    required int round,
    required String opponentShort,
    required String opponentName,
    required int opponentColor,
    required String opponentId,
    required bool isCompleted,
    required bool isHome,
    int? homeScore,
    int? awayScore,
    required bool isNext,
  }) {
    return GestureDetector(
      onTap: () {
        // 팀 정보 화면으로 이동 (해당 팀 선택)
        context.go('/team-ranking?teamId=$opponentId');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 4.sp),
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
        decoration: BoxDecoration(
          color: isNext ? Colors.amber.withOpacity(0.15) : const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(4.sp),
          border: isNext ? Border.all(color: Colors.amber, width: 1) : null,
        ),
        child: Row(
        children: [
          // 라운드
          Container(
            width: 30.sp,
            height: 24.sp,
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3e),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Center(
              child: Text(
                'R$round',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.sp),

          // VS
          Text(
            'VS',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11.sp,
            ),
          ),

          SizedBox(width: 12.sp),

          // 상대팀 로고
          Container(
            width: 28.sp,
            height: 28.sp,
            decoration: BoxDecoration(
              color: Color(opponentColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
              border: Border.all(color: Color(opponentColor), width: 1),
            ),
            child: Center(
              child: Text(
                opponentShort.length >= 2 ? opponentShort.substring(0, 2) : opponentShort,
                style: TextStyle(
                  color: Color(opponentColor),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 10.sp),

          // 상대팀명
          Expanded(
            child: Text(
              opponentName,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),

          // 결과 또는 상태
          if (isCompleted && homeScore != null && awayScore != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: (isHome ? homeScore > awayScore : awayScore > homeScore)
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                isHome ? '$homeScore : $awayScore' : '$awayScore : $homeScore',
                style: TextStyle(
                  color: (isHome ? homeScore > awayScore : awayScore > homeScore)
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isCompleted)
            Text(
              '완료',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11.sp,
              ),
            )
          else if (isNext)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                '다음 경기',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Text(
              'No Match',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11.sp,
              ),
            ),
        ],
        ),
      ),
    );
  }

  Widget _buildSeasonSchedule(dynamic gameState, Team playerTeam, List<Team> allTeams, bool isPreviewMode) {
    // Preview 모드일 때 샘플 일정 생성
    final List<Map<String, dynamic>> previewMatches = isPreviewMode
        ? List.generate(7, (i) {
            final opponentTeam = allTeams[(i + 1) % allTeams.length];
            return {
              'round': i + 1,
              'opponent': opponentTeam.shortName,
              'opponentColor': opponentTeam.colorValue,
              'isCompleted': i < 3,
              'isHome': i % 2 == 0,
            };
          })
        : [];

    if (isPreviewMode) {
      return Container(
        margin: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          color: const Color(0xFF12121a),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8.sp)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: Colors.amber, size: 16.sp),
                  SizedBox(width: 8.sp),
                  Text(
                    '정 규 시 즌 일 정',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Icon(Icons.flag, color: Colors.amber, size: 16.sp),
                ],
              ),
            ),
            // 일정 리스트
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(8.sp),
                itemCount: previewMatches.length,
                itemBuilder: (context, index) {
                  final match = previewMatches[index];
                  return _buildMatchItem(
                    round: match['round'] as int,
                    opponent: match['opponent'] as String,
                    opponentColor: match['opponentColor'] as int,
                    isCompleted: match['isCompleted'] as bool,
                    result: null,
                    isHome: match['isHome'] as bool,
                    isNext: index == 3,
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    final List<ScheduleItem> schedule = List<ScheduleItem>.from(
      gameState.saveData.currentSeason.proleagueSchedule
    );
    final playerTeamId = gameState.saveData.playerTeamId;

    // 내 팀 경기만 필터링
    final myMatches = schedule.where((s) =>
      s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId
    ).toList();

    return Container(
      margin: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF12121a),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.sp)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.flag, color: Colors.amber, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  '정 규 시 즌 일 정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.flag, color: Colors.amber, size: 16.sp),
              ],
            ),
          ),

          // 일정 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.sp),
              itemCount: myMatches.length,
              itemBuilder: (context, index) {
                final match = myMatches[index];
                final isHome = match.homeTeamId == playerTeamId;
                final opponentId = isHome ? match.awayTeamId : match.homeTeamId;
                final opponent = gameState.saveData.getTeamById(opponentId);

                return _buildMatchItem(
                  round: match.roundNumber,
                  opponent: opponent?.shortName ?? '???',
                  opponentColor: opponent?.colorValue ?? 0xFF888888,
                  isCompleted: match.isCompleted,
                  result: match.result,
                  isHome: isHome,
                  isNext: !match.isCompleted && index == myMatches.indexWhere((m) => !m.isCompleted),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem({
    required int round,
    required String opponent,
    required int opponentColor,
    required bool isCompleted,
    dynamic result,
    required bool isHome,
    required bool isNext,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.sp),
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: isNext ? Colors.amber.withOpacity(0.2) : Colors.black26,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: isNext ? Colors.amber : Colors.transparent,
          width: isNext ? 1 : 0,
        ),
      ),
      child: Row(
        children: [
          // 라운드
          Container(
            width: 28.sp,
            height: 28.sp,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[800],
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Center(
              child: Text(
                'R$round',
                style: TextStyle(
                  color: isCompleted ? Colors.greenAccent : Colors.white70,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 8.sp),

          // VS
          Text(
            'VS',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(width: 8.sp),

          // 상대팀 로고
          Container(
            width: 28.sp,
            height: 28.sp,
            decoration: BoxDecoration(
              color: Color(opponentColor).withOpacity(0.3),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Center(
              child: Text(
                opponent.length >= 2 ? opponent.substring(0, 2) : opponent,
                style: TextStyle(
                  color: Color(opponentColor),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const Spacer(),

          // 결과 또는 상태
          Text(
            isCompleted
                ? (result != null ? '${result.homeScore}:${result.awayScore}' : '완료')
                : (isNext ? '다음 경기' : 'No Match'),
            style: TextStyle(
              color: isNext ? Colors.amber : (isCompleted ? Colors.greenAccent : Colors.grey[600]),
              fontSize: 10.sp,
              fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfo(dynamic playerTeam, dynamic gameState, bool isPreviewMode) {
    final teamColor = Color(playerTeam.colorValue);
    final players = isPreviewMode
        ? InitialData.createPlayers().where((p) => p.teamId == playerTeam.id).toList()
        : gameState.playerTeamPlayers;

    return Container(
      margin: EdgeInsets.all(8.sp),
      child: Column(
        children: [
          // 팀 로고 영역
          Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF12121a),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Column(
              children: [
                // 큰 팀 로고
                Container(
                  width: 100.sp,
                  height: 100.sp,
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: teamColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: teamColor.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      playerTeam.shortName,
                      style: TextStyle(
                        color: teamColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.sp),
                Text(
                  playerTeam.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  isPreviewMode
                      ? '순위: 1위  |  0승 0패'
                      : '순위: ${_calculateRank(gameState)}위  |  ${playerTeam.record.wins}승 ${playerTeam.record.losses}패',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 8.sp),

          // 선수 목록 (간략)
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: const Color(0xFF12121a),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '로스터 (${players.length}명)',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.sp),
                  Expanded(
                    child: ListView.builder(
                      itemCount: players.length > 6 ? 6 : players.length,
                      itemBuilder: (context, index) {
                        final player = players[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 4.sp),
                          child: Row(
                            children: [
                              Container(
                                width: 20.sp,
                                height: 20.sp,
                                decoration: BoxDecoration(
                                  color: _getRaceColor(player.race.code).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4.sp),
                                ),
                                child: Center(
                                  child: Text(
                                    player.race.code[0],
                                    style: TextStyle(
                                      color: _getRaceColor(player.race.code),
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.sp),
                              Text(
                                player.name,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.sp,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '컨디션 ${player.condition}%',
                                style: TextStyle(
                                  color: player.condition >= 80 ? Colors.greenAccent : Colors.orange,
                                  fontSize: 10.sp,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualSchedule() {
    final events = [
      {'name': 'PC방 예선전', 'round': '1R', 'status': 'current'},
      {'name': '듀얼토너먼트', 'round': '2~4R', 'status': 'upcoming'},
      {'name': '조지명식', 'round': '5R', 'status': 'upcoming'},
      {'name': '32강', 'round': '6~7R', 'status': 'upcoming'},
      {'name': '16강', 'round': '8~9R', 'status': 'upcoming'},
      {'name': '8강', 'round': '10~11R', 'status': 'upcoming'},
      {'name': '4강', 'round': '?R', 'status': 'upcoming'},
      {'name': '결승', 'round': '?R', 'status': 'upcoming'},
    ];

    return Container(
      margin: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF12121a),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF1a1a2e),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8.sp)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  '개 인 리 그 일 정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
              ],
            ),
          ),

          // 일정 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(8.sp),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final isCurrent = event['status'] == 'current';

                return Container(
                  margin: EdgeInsets.only(bottom: 6.sp),
                  padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.amber.withOpacity(0.15) : Colors.black26,
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(
                      color: isCurrent ? Colors.amber.withOpacity(0.5) : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCurrent ? Icons.play_circle : Icons.circle,
                        color: isCurrent ? Colors.amber : Colors.grey[700],
                        size: isCurrent ? 16.sp : 8.sp,
                      ),
                      SizedBox(width: 12.sp),
                      Expanded(
                        child: Text(
                          event['name'] as String,
                          style: TextStyle(
                            color: isCurrent ? Colors.amber : Colors.grey[400],
                            fontSize: 13.sp,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        event['round'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11.sp,
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

  int _calculateRank(dynamic gameState) {
    // TODO: 실제 순위 계산
    return 1;
  }

  Color _getRaceColor(String raceCode) {
    switch (raceCode.toUpperCase()) {
      case 'T':
        return Colors.blue;
      case 'Z':
        return Colors.purple;
      case 'P':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
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
