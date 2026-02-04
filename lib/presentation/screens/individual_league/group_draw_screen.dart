import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 조지명식 화면 (32강 조 배정)
class GroupDrawScreen extends ConsumerStatefulWidget {
  const GroupDrawScreen({super.key});

  @override
  ConsumerState<GroupDrawScreen> createState() => _GroupDrawScreenState();
}

class _GroupDrawScreenState extends ConsumerState<GroupDrawScreen> {
  bool _isDrawing = false;
  bool _isCompleted = false;
  int _currentDrawIndex = -1;
  List<List<String>> _groups = [];

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerTeam = gameState.playerTeam;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, playerTeam),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Row(
                      children: [
                        // 좌측: 조 배정 결과
                        Expanded(
                          flex: 3,
                          child: _buildGroupsPanel(bracket, playerMap),
                        ),
                        SizedBox(width: 16.sp),
                        // 우측: 본선 진출자 목록
                        SizedBox(
                          width: 220.sp,
                          child: _buildPlayersPanel(bracket, playerMap),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(context, bracket, playerMap),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildTeamLogo(team),
          const Spacer(),
          Text(
            '조 지 명 식',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          _buildTeamLogo(team),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 60.sp,
      height: 40.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Color(team.colorValue)),
      ),
      child: Center(
        child: Text(
          team.shortName,
          style: TextStyle(
            color: Color(team.colorValue),
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupsPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8강 조 배정',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.sp),
          Expanded(
            child: _buildGroupCards(bracket, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCards(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    if (_groups.isEmpty && !_isDrawing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shuffle,
              size: 60.sp,
              color: Colors.grey,
            ),
            SizedBox(height: 16.sp),
            Text(
              '조 배정이 진행되지 않았습니다',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              'Start 버튼을 눌러 조 추첨을 시작하세요',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_isDrawing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 24.sp),
            Text(
              '조 추첨 중...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${_currentDrawIndex + 1} / 8',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 4개 조 (각 조 2명) 표시 - 8강 대진
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.sp,
        crossAxisSpacing: 16.sp,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final groupIndex = index;
        final isRevealed = groupIndex <= _currentDrawIndex / 2;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: isRevealed ? 1.0 : 0.3,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(
                color: isRevealed ? AppColors.accent : Colors.grey[700]!,
                width: isRevealed ? 2 : 1,
              ),
            ),
            padding: EdgeInsets.all(12.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.sp,
                        vertical: 4.sp,
                      ),
                      decoration: BoxDecoration(
                        color: _getGroupColor(index).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                      child: Text(
                        '${String.fromCharCode(65 + index)}조',
                        style: TextStyle(
                          color: _getGroupColor(index),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isRevealed)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.accent,
                        size: 20.sp,
                      ),
                  ],
                ),
                SizedBox(height: 12.sp),
                Expanded(
                  child: _buildGroupMembers(groupIndex, playerMap, isRevealed),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupMembers(
    int groupIndex,
    Map<String, Player> playerMap,
    bool isRevealed,
  ) {
    if (!isRevealed || _groups.length <= groupIndex) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24.sp,
            ),
          ),
          Text(
            'vs',
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
          Text(
            '?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 24.sp,
            ),
          ),
        ],
      );
    }

    final group = _groups[groupIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < group.length; i++) ...[
          if (i > 0)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.sp),
              child: Text(
                'vs',
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
            ),
          _buildPlayerChip(playerMap[group[i]]),
        ],
      ],
    );
  }

  Widget _buildPlayerChip(Player? player) {
    if (player == null) {
      return Text(
        '?',
        style: TextStyle(color: Colors.grey, fontSize: 14.sp),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            player.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 6.sp),
          Text(
            '(${player.race.code})',
            style: TextStyle(
              color: _getRaceColor(player.race),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final players = bracket?.mainTournamentPlayers ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '본선 진출자',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            '${players.length}명',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: players.isEmpty
                ? Center(
                    child: Text(
                      '진출자 없음',
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  )
                : ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = playerMap[players[index]];
                      if (player == null) return const SizedBox();

                      final isDrawn = _groups.any((g) => g.contains(player.id));

                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 6.sp),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[800]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24.sp,
                              height: 24.sp,
                              decoration: BoxDecoration(
                                color: isDrawn
                                    ? AppColors.accent.withOpacity(0.2)
                                    : Colors.grey[800],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isDrawn
                                    ? Icon(
                                        Icons.check,
                                        size: 14.sp,
                                        color: AppColors.accent,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 10.sp,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 8.sp),
                            Expanded(
                              child: Text(
                                player.name,
                                style: TextStyle(
                                  color: isDrawn ? Colors.grey : Colors.white,
                                  fontSize: 12.sp,
                                  decoration: isDrawn
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              '(${player.race.code})',
                              style: TextStyle(
                                color: _getRaceColor(player.race),
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

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  'EXIT [Bar]',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 24.sp),
          ElevatedButton(
            onPressed: _isDrawing
                ? null
                : () => _isCompleted
                    ? _goToNextStage(context)
                    : _startDraw(bracket),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDrawing ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Next [Bar]' : 'Start [Bar]',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startDraw(IndividualLeagueBracket? bracket) async {
    if (bracket == null || bracket.mainTournamentPlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('듀얼토너먼트를 먼저 진행해주세요')),
      );
      return;
    }

    final players = List<String>.from(bracket.mainTournamentPlayers);

    // 8명 필요, 부족하면 에러
    if (players.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('본선 진출자가 부족합니다 (${players.length}/8)')),
      );
      return;
    }

    setState(() {
      _isDrawing = true;
      _currentDrawIndex = -1;
      _groups = [];
    });

    // 섞기
    players.shuffle();

    // 4개 조로 나누기 (각 조 2명)
    final newGroups = <List<String>>[];
    for (var i = 0; i < 4; i++) {
      newGroups.add([players[i * 2], players[i * 2 + 1]]);
    }

    // 하나씩 공개
    for (var i = 0; i < 8; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() {
        _currentDrawIndex = i;
        if (i % 2 == 1) {
          // 조가 완성될 때마다 추가
          _groups.add(newGroups[i ~/ 2]);
        }
      });
    }

    setState(() {
      _isDrawing = false;
      _isCompleted = true;
    });
  }

  void _goToNextStage(BuildContext context) {
    context.push('/main-tournament');
  }

  Color _getGroupColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
    ];
    return colors[index % colors.length];
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
