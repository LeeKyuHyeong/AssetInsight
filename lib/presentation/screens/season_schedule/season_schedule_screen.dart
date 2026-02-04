import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 시즌 일정 이벤트 타입
enum ScheduleEventType {
  proleague('프로리그', Icons.sports_esports),
  conditionRecovery('컨디션 회복', Icons.favorite),
  pcbangQualifier('PC방 예선전', Icons.computer),
  dualTournament('듀얼토너먼트', Icons.emoji_events),
  groupDraw('조지명식', Icons.groups),
  round32('32강', Icons.looks_one),
  round16('16강', Icons.looks_two),
  quarterfinal('8강', Icons.emoji_events),
  semifinal('4강', Icons.emoji_events),
  final_('결승', Icons.emoji_events);

  final String label;
  final IconData icon;

  const ScheduleEventType(this.label, this.icon);
}

/// 시즌 일정 화면 (정규 시즌 일정)
class SeasonScheduleScreen extends ConsumerStatefulWidget {
  const SeasonScheduleScreen({super.key});

  @override
  ConsumerState<SeasonScheduleScreen> createState() => _SeasonScheduleScreenState();
}

class _SeasonScheduleScreenState extends ConsumerState<SeasonScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final playerTeam = gameState.playerTeam;
    final season = gameState.currentSeason;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(playerTeam, season),

                // 메인 컨텐츠 (3열 레이아웃)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측 열: 프로리그 일정 (완료된 경기)
                      Expanded(
                        child: _buildProleagueColumn(
                          '프로리그 (완료)',
                          _getCompletedMatches(gameState),
                          isCompleted: true,
                        ),
                      ),

                      // 중앙 열: 프로리그 일정 (예정된 경기)
                      Expanded(
                        child: _buildProleagueColumn(
                          '프로리그 (예정)',
                          _getUpcomingMatches(gameState),
                          isCompleted: false,
                        ),
                      ),

                      // 우측 열: 개인리그 일정
                      Expanded(
                        child: _buildIndividualLeagueColumn(gameState),
                      ),
                    ],
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Team playerTeam, Season season) {
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
          // 좌측 팀 로고
          Container(
            width: 50.sp,
            height: 35.sp,
            decoration: BoxDecoration(
              color: Color(playerTeam.colorValue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: Color(playerTeam.colorValue),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          SizedBox(width: 16.sp),

          // 타이틀
          Expanded(
            child: Column(
              children: [
                Text(
                  '정규 시즌 일정',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '프로리그 ${2012} S${season.number}',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.sp),

          // 우측 팀 로고 (같은 팀)
          Container(
            width: 50.sp,
            height: 35.sp,
            decoration: BoxDecoration(
              color: Color(playerTeam.colorValue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: Color(playerTeam.colorValue),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_ProleagueMatch> _getCompletedMatches(GameState gameState) {
    // TODO: 실제 경기 데이터에서 완료된 경기 가져오기
    // 임시 데이터
    return [
      _ProleagueMatch(
        opponentName: '삼성전자 KHAN',
        opponentShortName: 'SAM',
        opponentColor: 0xFF0047AB,
        score: '4:3',
        isWin: true,
      ),
      _ProleagueMatch(
        opponentName: 'STX SouL',
        opponentShortName: 'STX',
        opponentColor: 0xFFE31937,
        score: '4:0',
        isWin: true,
      ),
    ];
  }

  List<_ProleagueMatch> _getUpcomingMatches(GameState gameState) {
    // TODO: 실제 경기 데이터에서 예정된 경기 가져오기
    // 임시 데이터
    return [
      _ProleagueMatch(
        opponentName: '웅진 Stars',
        opponentShortName: 'WJS',
        opponentColor: 0xFF00843D,
        score: null,
        isWin: null,
      ),
      _ProleagueMatch(
        opponentName: 'KT 롤스터',
        opponentShortName: 'KT',
        opponentColor: 0xFFFF0000,
        score: null,
        isWin: null,
      ),
      _ProleagueMatch(
        opponentName: 'CJ Entus',
        opponentShortName: 'CJ',
        opponentColor: 0xFF0033A0,
        score: null,
        isWin: null,
      ),
    ];
  }

  Widget _buildProleagueColumn(
    String title,
    List<_ProleagueMatch> matches, {
    required bool isCompleted,
  }) {
    return Container(
      margin: EdgeInsets.all(8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 열 제목
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          ),

          // 경기 목록
          Expanded(
            child: ListView.builder(
              itemCount: matches.length + (isCompleted ? 0 : 3), // 예정된 경기는 빈 슬롯 추가
              itemBuilder: (context, index) {
                if (index < matches.length) {
                  return _buildMatchItem(matches[index], isCompleted);
                } else {
                  return _buildNoMatchItem();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(_ProleagueMatch match, bool isCompleted) {
    return GestureDetector(
      onTap: () {
        // 상대 팀 정보 화면으로 이동
        // TODO: 팀 정보 화면 연결
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.sp),
        padding: EdgeInsets.all(8.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(4.sp),
          border: Border.all(
            color: isCompleted
                ? (match.isWin == true ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5))
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Text(
              'VS',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10.sp,
              ),
            ),

            SizedBox(width: 8.sp),

            // 팀 로고
            Container(
              width: 30.sp,
              height: 22.sp,
              decoration: BoxDecoration(
                color: Color(match.opponentColor).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.sp),
              ),
              child: Center(
                child: Text(
                  match.opponentShortName,
                  style: TextStyle(
                    color: Color(match.opponentColor),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(width: 8.sp),

            // 팀명
            Expanded(
              child: Text(
                match.opponentName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 스코어 또는 Win 표시
            if (isCompleted && match.score != null) ...[
              Text(
                match.score!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                decoration: BoxDecoration(
                  color: match.isWin == true ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Text(
                  match.isWin == true ? 'Win' : 'Lose',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchItem() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Center(
        child: Text(
          'No Match',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 11.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildIndividualLeagueColumn(GameState gameState) {
    // 개인리그 일정 이벤트 목록
    final events = <_IndividualEvent>[
      _IndividualEvent(type: ScheduleEventType.conditionRecovery, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.pcbangQualifier, playerRace: Race.protoss),
      _IndividualEvent(type: ScheduleEventType.dualTournament, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.dualTournament, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.dualTournament, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.groupDraw, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.round32, playerRace: Race.terran),
      _IndividualEvent(type: ScheduleEventType.round32, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.round16, playerRace: Race.zerg),
      _IndividualEvent(type: ScheduleEventType.round16, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.quarterfinal, playerRace: null),
      _IndividualEvent(type: ScheduleEventType.quarterfinal, playerRace: null),
    ];

    return Container(
      margin: EdgeInsets.all(8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 열 제목
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp),
            child: Text(
              '개인리그 일정',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          ),

          // 이벤트 목록
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildIndividualEventItem(events[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndividualEventItem(_IndividualEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 6.sp),
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Row(
        children: [
          // 종족 아이콘 (있는 경우)
          if (event.playerRace != null) ...[
            Container(
              width: 20.sp,
              height: 20.sp,
              decoration: BoxDecoration(
                color: _getRaceColor(event.playerRace!).withOpacity(0.2),
                borderRadius: BorderRadius.circular(2.sp),
              ),
              child: Center(
                child: Text(
                  event.playerRace!.code,
                  style: TextStyle(
                    color: _getRaceColor(event.playerRace!),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.sp),
          ] else ...[
            Icon(
              event.type.icon,
              color: _getEventColor(event.type),
              size: 18.sp,
            ),
            SizedBox(width: 8.sp),
          ],

          // 이벤트명
          Expanded(
            child: Text(
              event.type.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
              ),
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

  Color _getEventColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.conditionRecovery:
        return Colors.pink;
      case ScheduleEventType.pcbangQualifier:
        return Colors.blue;
      case ScheduleEventType.dualTournament:
      case ScheduleEventType.groupDraw:
      case ScheduleEventType.round32:
      case ScheduleEventType.round16:
      case ScheduleEventType.quarterfinal:
      case ScheduleEventType.semifinal:
      case ScheduleEventType.final_:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 아이템 상점
          _buildBottomButton(
            label: '아이템 상점',
            shortcut: 'Z',
            icon: Icons.store,
            onPressed: () {
              // TODO: 아이템 상점 화면
            },
          ),

          // Next 버튼
          ElevatedButton(
            onPressed: () => context.go('/roster-select'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
              ],
            ),
          ),

          // 정보 관리
          _buildBottomButton(
            label: '정보 관리',
            shortcut: 'X',
            icon: Icons.info_outline,
            onPressed: () {
              // TODO: 선수 정보 화면
            },
          ),

          // 행동 관리
          _buildBottomButton(
            label: '행동 관리',
            shortcut: 'C',
            icon: Icons.settings,
            onPressed: () {
              // TODO: 행동 관리 화면
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required String shortcut,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20.sp),
            SizedBox(height: 4.sp),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
            ),
            Text(
              '[$shortcut]',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프로리그 경기 데이터
class _ProleagueMatch {
  final String opponentName;
  final String opponentShortName;
  final int opponentColor;
  final String? score;
  final bool? isWin;

  _ProleagueMatch({
    required this.opponentName,
    required this.opponentShortName,
    required this.opponentColor,
    this.score,
    this.isWin,
  });
}

/// 개인리그 이벤트 데이터
class _IndividualEvent {
  final ScheduleEventType type;
  final Race? playerRace; // 참가 선수 종족 (있는 경우)

  _IndividualEvent({
    required this.type,
    this.playerRace,
  });
}
