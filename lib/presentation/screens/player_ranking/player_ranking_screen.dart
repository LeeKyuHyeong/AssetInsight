import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 선수 순위 탭 유형
enum PlayerRankingTab {
  all('BEST PLAYER', null),
  terran('TERRAN', Race.terran),
  zerg('ZERG', Race.zerg),
  protoss('PROTOSS', Race.protoss);

  final String label;
  final Race? raceFilter;

  const PlayerRankingTab(this.label, this.raceFilter);
}

/// 선수 순위 화면
class PlayerRankingScreen extends ConsumerStatefulWidget {
  const PlayerRankingScreen({super.key});

  @override
  ConsumerState<PlayerRankingScreen> createState() => _PlayerRankingScreenState();
}

class _PlayerRankingScreenState extends ConsumerState<PlayerRankingScreen> {
  PlayerRankingTab _currentTab = PlayerRankingTab.all;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allPlayers = gameState.saveData.allPlayers;

    // 종족 필터 적용
    final filteredPlayers = _currentTab.raceFilter != null
        ? allPlayers.where((p) => p.race == _currentTab.raceFilter).toList()
        : allPlayers.toList();

    // 정렬: 우승 > 준우승 > 승수 > 승률
    filteredPlayers.sort((a, b) {
      // 1. 우승 횟수
      final champCompare = b.record.championships.compareTo(a.record.championships);
      if (champCompare != 0) return champCompare;

      // 2. 준우승 횟수
      final runnerUpCompare = b.record.runnerUps.compareTo(a.record.runnerUps);
      if (runnerUpCompare != 0) return runnerUpCompare;

      // 3. 승수
      final winsCompare = b.record.wins.compareTo(a.record.wins);
      if (winsCompare != 0) return winsCompare;

      // 4. 승률
      return b.record.winRate.compareTo(a.record.winRate);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(context),

                // 탭 이미지 + 타이틀
                _buildTabHeader(),

                // 테이블 (가로 스크롤)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _horizontalScrollController,
                    child: SizedBox(
                      width: _totalTableWidth(),
                      child: Column(
                        children: [
                          _buildTableHeader(),
                          Expanded(
                            child: _buildPlayerList(filteredPlayers),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _totalTableWidth() {
    // 순위(35) + 선수명(90) + 우승(35) + 준우승(40) + 전체(85) + vsT(75) + vsZ(75) + vsP(75) + padding(16*2)
    return (35 + 90 + 35 + 40 + 85 + 75 + 75 + 75 + 32).sp;
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
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
          Text(
            'MyStarcraft   Season Mode   2012   S1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          const Spacer(),
          const ResetButton(small: true),
        ],
      ),
    );
  }

  Widget _buildTabHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 좌측 화살표
          IconButton(
            onPressed: () => _changeTab(-1),
            icon: Icon(Icons.arrow_left, color: Colors.white, size: 32.sp),
          ),

          SizedBox(width: 16.sp),

          // 탭 아이콘
          Container(
            width: 60.sp,
            height: 60.sp,
            decoration: BoxDecoration(
              color: _getTabColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: _getTabColor()),
            ),
            child: Center(
              child: _buildTabIcon(),
            ),
          ),

          SizedBox(width: 16.sp),

          // 타이틀
          SizedBox(
            width: 200.sp,
            child: Column(
              children: [
                Text(
                  '선수 순위',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  _currentTab.label,
                  style: TextStyle(
                    color: _getTabColor(),
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.sp),

          // 우측 화살표
          IconButton(
            onPressed: () => _changeTab(1),
            icon: Icon(Icons.arrow_right, color: Colors.white, size: 32.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildTabIcon() {
    switch (_currentTab) {
      case PlayerRankingTab.all:
        return Icon(Icons.emoji_events, color: Colors.amber, size: 32.sp);
      case PlayerRankingTab.terran:
        return Text('T', style: TextStyle(color: AppColors.terran, fontSize: 28.sp, fontWeight: FontWeight.bold));
      case PlayerRankingTab.zerg:
        return Text('Z', style: TextStyle(color: AppColors.zerg, fontSize: 28.sp, fontWeight: FontWeight.bold));
      case PlayerRankingTab.protoss:
        return Text('P', style: TextStyle(color: AppColors.protoss, fontSize: 28.sp, fontWeight: FontWeight.bold));
    }
  }

  Color _getTabColor() {
    switch (_currentTab) {
      case PlayerRankingTab.all:
        return Colors.amber;
      case PlayerRankingTab.terran:
        return AppColors.terran;
      case PlayerRankingTab.zerg:
        return AppColors.zerg;
      case PlayerRankingTab.protoss:
        return AppColors.protoss;
    }
  }

  void _changeTab(int direction) {
    final currentIndex = PlayerRankingTab.values.indexOf(_currentTab);
    final newIndex = (currentIndex + direction) % PlayerRankingTab.values.length;
    setState(() {
      _currentTab = PlayerRankingTab.values[newIndex < 0 ? PlayerRankingTab.values.length - 1 : newIndex];
    });
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _headerCell('순위', 35),
          _headerCell('선수명', 90),
          _headerCell('우승', 35),
          _headerCell('준우승', 40),
          _headerCell('전체', 85),
          _headerCell('vs T', 75),
          _headerCell('vs Z', 75),
          _headerCell('vs P', 75),
        ],
      ),
    );
  }

  Widget _headerCell(String text, double width) {
    return SizedBox(
      width: width.sp,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 10.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPlayerList(List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
      ),
      child: ListView.builder(
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return _buildPlayerRow(index + 1, player);
        },
      ),
    );
  }

  Widget _buildPlayerRow(int rank, Player player) {
    final record = player.record;
    final isHighlighted = rank <= 3;
    final raceCode = player.race.code;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary.withOpacity(0.1) : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // 순위
          SizedBox(
            width: 35.sp,
            child: Text(
              '$rank',
              style: TextStyle(
                color: isHighlighted ? Colors.amber : Colors.white,
                fontSize: 11.sp,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // (종족) 선수명
          SizedBox(
            width: 90.sp,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '($raceCode) ',
                    style: TextStyle(
                      color: _getRaceColor(player.race),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: player.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 우승
          SizedBox(
            width: 35.sp,
            child: Text(
              '${record.championships}',
              style: TextStyle(
                color: record.championships > 0 ? Colors.amber : Colors.grey,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 준우승
          SizedBox(
            width: 40.sp,
            child: Text(
              '${record.runnerUps}',
              style: TextStyle(
                color: record.runnerUps > 0 ? Colors.grey[300] : Colors.grey,
                fontSize: 11.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 전체 전적: "15W 5L (75%)"
          SizedBox(
            width: 85.sp,
            child: Text(
              _formatRecord(record.wins, record.losses, record.winRate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // vs Terran
          SizedBox(
            width: 75.sp,
            child: Text(
              _formatRecord(record.vsTerranWins, record.vsTerranLosses, record.vsTerranWinRate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // vs Zerg
          SizedBox(
            width: 75.sp,
            child: Text(
              _formatRecord(record.vsZergWins, record.vsZergLosses, record.vsZergWinRate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // vs Protoss
          SizedBox(
            width: 75.sp,
            child: Text(
              _formatRecord(record.vsProtossWins, record.vsProtossLosses, record.vsProtossWinRate),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRecord(int wins, int losses, double winRate) {
    final total = wins + losses;
    if (total == 0) return '-';
    return '${wins}W ${losses}L (${(winRate * 100).toStringAsFixed(0)}%)';
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

  Widget _buildBottomButtons(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EXIT 버튼
          ElevatedButton(
            onPressed: () {
              // 뒤로가기 가능하면 pop, 아니면 info로 이동
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/info');
              }
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
                  'EXIT',
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
}
