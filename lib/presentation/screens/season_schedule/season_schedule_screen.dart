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

/// 통합 일정 아이템
class UnifiedScheduleItem {
  final ScheduleEventType type;
  final String? opponentTeamId; // 프로리그일 때 상대팀
  final String? score; // 완료된 경기 스코어
  final bool? isWin; // 완료된 경기 승패
  final bool isCompleted;
  final int originalIndex; // 원래 프로리그 인덱스 (프로리그일 때)

  const UnifiedScheduleItem({
    required this.type,
    this.opponentTeamId,
    this.score,
    this.isWin,
    this.isCompleted = false,
    this.originalIndex = -1,
  });
}

/// 시즌 일정 화면 (정규 시즌 일정)
class SeasonScheduleScreen extends ConsumerStatefulWidget {
  const SeasonScheduleScreen({super.key});

  @override
  ConsumerState<SeasonScheduleScreen> createState() => _SeasonScheduleScreenState();
}

class _SeasonScheduleScreenState extends ConsumerState<SeasonScheduleScreen> {
  /// 통합 일정 생성 (프로리그 + 개인리그 인터리빙)
  List<UnifiedScheduleItem> _buildUnifiedSchedule(GameState gameState) {
    final schedule = <UnifiedScheduleItem>[];
    final season = gameState.currentSeason;
    final proleagueSchedule = season.proleagueSchedule;
    final playerTeamId = gameState.playerTeam.id;

    int proleagueIndex = 0;
    int matchCount = 0; // 2경기마다 개인리그 이벤트 삽입

    // 개인리그 이벤트 순서
    final individualEvents = [
      ScheduleEventType.pcbangQualifier,
      ScheduleEventType.dualTournament,
      ScheduleEventType.dualTournament,
      ScheduleEventType.dualTournament,
      ScheduleEventType.groupDraw,
      ScheduleEventType.round32,
      ScheduleEventType.round32,
      ScheduleEventType.round16,
      ScheduleEventType.round16,
      ScheduleEventType.quarterfinal,
      ScheduleEventType.quarterfinal,
    ];
    int individualEventIndex = 0;

    while (proleagueIndex < proleagueSchedule.length || individualEventIndex < individualEvents.length) {
      // 2경기 후 개인리그 이벤트 삽입
      if (matchCount >= 2 && individualEventIndex < individualEvents.length) {
        schedule.add(UnifiedScheduleItem(
          type: individualEvents[individualEventIndex],
          isCompleted: _isIndividualEventCompleted(individualEventIndex, season),
        ));
        individualEventIndex++;
        matchCount = 0;
      }

      // 프로리그 경기 추가
      if (proleagueIndex < proleagueSchedule.length) {
        final match = proleagueSchedule[proleagueIndex];
        final isHome = match.homeTeamId == playerTeamId;
        final opponentId = isHome ? match.awayTeamId : match.homeTeamId;

        String? score;
        bool? isWin;
        if (match.result != null) {
          final homeScore = match.result!.homeScore;
          final awayScore = match.result!.awayScore;
          score = isHome ? '$homeScore:$awayScore' : '$awayScore:$homeScore';
          isWin = isHome ? homeScore > awayScore : awayScore > homeScore;
        }

        schedule.add(UnifiedScheduleItem(
          type: ScheduleEventType.proleague,
          opponentTeamId: opponentId,
          score: score,
          isWin: isWin,
          isCompleted: match.result != null,
          originalIndex: proleagueIndex,
        ));
        proleagueIndex++;
        matchCount++;
      }
    }

    return schedule;
  }

  /// 개인리그 이벤트 완료 여부
  bool _isIndividualEventCompleted(int eventIndex, Season season) {
    final league = season.individualLeague;
    if (league == null) return false;

    switch (eventIndex) {
      case 0: // PC방 예선
        return league.pcBangResults.isNotEmpty;
      case 1: // 듀얼토너먼트 1
      case 2: // 듀얼토너먼트 2
      case 3: // 듀얼토너먼트 3
        return league.dualTournamentResults.length > (eventIndex - 1) * 8;
      case 4: // 조지명식
        return league.mainTournamentPlayers.isNotEmpty;
      case 5: // 32강 1
      case 6: // 32강 2
        return league.mainTournamentResults.length >= (eventIndex - 4) * 16;
      case 7: // 16강 1
      case 8: // 16강 2
        return league.mainTournamentResults.length >= 16 + (eventIndex - 7) * 8;
      case 9: // 8강 1
      case 10: // 8강 2
        return league.mainTournamentResults.length >= 24 + (eventIndex - 9) * 4;
      default:
        return false;
    }
  }

  /// 현재 일정 인덱스 계산
  int _getCurrentScheduleIndex(List<UnifiedScheduleItem> schedule) {
    for (int i = 0; i < schedule.length; i++) {
      if (!schedule[i].isCompleted) {
        return i;
      }
    }
    return schedule.length;
  }

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
    final unifiedSchedule = _buildUnifiedSchedule(gameState);
    final currentIndex = _getCurrentScheduleIndex(unifiedSchedule);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(playerTeam, season),

                // 메인 컨텐츠 (통합 일정)
                Expanded(
                  child: _buildUnifiedScheduleView(gameState, unifiedSchedule, currentIndex),
                ),

                // 하단 버튼
                _buildBottomButtons(context, unifiedSchedule, currentIndex),
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

  /// 통합 일정 뷰 빌드
  Widget _buildUnifiedScheduleView(GameState gameState, List<UnifiedScheduleItem> schedule, int currentIndex) {
    return Container(
      margin: EdgeInsets.all(8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
            child: Row(
              children: [
                Text(
                  '시즌 일정',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
                const Spacer(),
                Text(
                  '진행: ${currentIndex}/${schedule.length}',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),

          // 일정 목록
          Expanded(
            child: ListView.builder(
              itemCount: schedule.length,
              itemBuilder: (context, index) {
                final item = schedule[index];
                final isCurrent = index == currentIndex;
                return _buildUnifiedScheduleItem(gameState, item, isCurrent, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 통합 일정 아이템 빌드
  Widget _buildUnifiedScheduleItem(GameState gameState, UnifiedScheduleItem item, bool isCurrent, int index) {
    Color borderColor = Colors.grey.withOpacity(0.3);
    Color bgColor = AppColors.cardBackground;

    if (isCurrent) {
      borderColor = AppColors.primary;
      bgColor = AppColors.primary.withOpacity(0.15);
    } else if (item.isCompleted) {
      if (item.type == ScheduleEventType.proleague) {
        borderColor = item.isWin == true ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5);
      } else {
        borderColor = Colors.green.withOpacity(0.3);
      }
      bgColor = AppColors.cardBackground.withOpacity(0.6);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 6.sp),
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: borderColor, width: isCurrent ? 2 : 1),
      ),
      child: Row(
        children: [
          // 순번
          Container(
            width: 24.sp,
            height: 24.sp,
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.primary : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12.sp),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: isCurrent ? Colors.white : Colors.grey,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.sp),

          // 아이콘
          Icon(
            item.type.icon,
            color: _getEventColor(item.type),
            size: 20.sp,
          ),
          SizedBox(width: 10.sp),

          // 내용
          Expanded(
            child: item.type == ScheduleEventType.proleague
                ? _buildProleagueContent(gameState, item)
                : Text(
                    item.type.label,
                    style: TextStyle(
                      color: item.isCompleted ? Colors.grey : Colors.white,
                      fontSize: 12.sp,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
          ),

          // 상태 표시
          if (item.isCompleted) ...[
            if (item.type == ScheduleEventType.proleague && item.score != null) ...[
              Text(
                item.score!,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 6.sp),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                decoration: BoxDecoration(
                  color: item.isWin == true ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(3.sp),
                ),
                child: Text(
                  item.isWin == true ? 'W' : 'L',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else ...[
              Icon(Icons.check_circle, color: Colors.green.withOpacity(0.7), size: 16.sp),
            ],
          ] else if (isCurrent) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4.sp),
              ),
              child: Text(
                'NEXT',
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
    );
  }

  /// 프로리그 경기 내용 빌드
  Widget _buildProleagueContent(GameState gameState, UnifiedScheduleItem item) {
    final opponent = gameState.saveData.getTeamById(item.opponentTeamId ?? '');
    if (opponent == null) {
      return Text(
        '프로리그',
        style: TextStyle(color: Colors.white, fontSize: 12.sp),
      );
    }

    return Row(
      children: [
        Text(
          'VS ',
          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 2.sp),
          decoration: BoxDecoration(
            color: Color(opponent.colorValue).withOpacity(0.2),
            borderRadius: BorderRadius.circular(2.sp),
          ),
          child: Text(
            opponent.shortName,
            style: TextStyle(
              color: Color(opponent.colorValue),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 6.sp),
        Expanded(
          child: Text(
            opponent.name,
            style: TextStyle(
              color: item.isCompleted ? Colors.grey : Colors.white,
              fontSize: 11.sp,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getEventColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.proleague:
        return Colors.blue;
      case ScheduleEventType.conditionRecovery:
        return Colors.pink;
      case ScheduleEventType.pcbangQualifier:
        return Colors.cyan;
      case ScheduleEventType.dualTournament:
        return Colors.orange;
      case ScheduleEventType.groupDraw:
        return Colors.purple;
      case ScheduleEventType.round32:
      case ScheduleEventType.round16:
      case ScheduleEventType.quarterfinal:
      case ScheduleEventType.semifinal:
      case ScheduleEventType.final_:
        return Colors.amber;
    }
  }

  String _getNextButtonText(List<UnifiedScheduleItem> schedule, int currentIndex) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return 'Next';

    final season = gameState.currentSeason;
    final phase = season.phase;

    // 정규 시즌이 아닌 경우
    if (phase != SeasonPhase.regularSeason) {
      return '플레이오프';
    }

    // 모든 일정 완료 시
    if (currentIndex >= schedule.length) {
      return '플레이오프 진출';
    }

    // 현재 일정 타입에 따른 버튼 텍스트
    final currentItem = schedule[currentIndex];
    return currentItem.type.label;
  }

  void _handleNextButton(BuildContext context, List<UnifiedScheduleItem> schedule, int currentIndex) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final season = gameState.currentSeason;
    final phase = season.phase;

    // 정규 시즌이 아닌 경우 플레이오프 화면으로
    if (phase != SeasonPhase.regularSeason) {
      context.go('/playoff');
      return;
    }

    // 모든 일정 완료 시 플레이오프로
    if (currentIndex >= schedule.length) {
      ref.read(gameStateProvider.notifier).updateSeasonPhase(SeasonPhase.playoffReady);
      context.go('/playoff');
      return;
    }

    // 현재 일정에 따라 다른 화면으로 이동
    final currentItem = schedule[currentIndex];
    switch (currentItem.type) {
      case ScheduleEventType.proleague:
        context.go('/roster-select');
        break;
      case ScheduleEventType.pcbangQualifier:
        context.go('/pcbang-qualifier');
        break;
      case ScheduleEventType.dualTournament:
        context.go('/dual-tournament');
        break;
      case ScheduleEventType.groupDraw:
        context.go('/group-draw');
        break;
      case ScheduleEventType.round32:
      case ScheduleEventType.round16:
      case ScheduleEventType.quarterfinal:
      case ScheduleEventType.semifinal:
      case ScheduleEventType.final_:
        context.go('/main-tournament');
        break;
      case ScheduleEventType.conditionRecovery:
        // 컨디션 회복은 자동 처리
        _handleConditionRecovery();
        break;
    }
  }

  void _handleConditionRecovery() {
    // TODO: 컨디션 회복 처리
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('팀 컨디션이 회복되었습니다!')),
    );
  }

  Widget _buildBottomButtons(BuildContext context, List<UnifiedScheduleItem> schedule, int currentIndex) {
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
              context.go('/shop');
            },
          ),

          // Next 버튼
          ElevatedButton(
            onPressed: () => _handleNextButton(context, schedule, currentIndex),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _getNextButtonText(schedule, currentIndex),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
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
              context.go('/info');
            },
          ),

          // 행동 관리
          _buildBottomButton(
            label: '행동 관리',
            shortcut: 'C',
            icon: Icons.settings,
            onPressed: () {
              context.go('/action');
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
