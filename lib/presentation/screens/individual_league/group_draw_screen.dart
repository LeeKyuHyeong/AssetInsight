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
  final bool viewOnly;

  const GroupDrawScreen({super.key, this.viewOnly = false});

  @override
  ConsumerState<GroupDrawScreen> createState() => _GroupDrawScreenState();
}

class _GroupDrawScreenState extends ConsumerState<GroupDrawScreen> {
  bool _isDrawing = false;
  bool _isCompleted = false;
  int _currentDrawIndex = -1;
  List<List<String?>> _groups = []; // 8개 조, 각 조 4명

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: Row(
                      children: [
                        // 좌측: 조 배정 결과
                        Expanded(
                          flex: 3,
                          child: _buildGroupsPanel(bracket, playerMap),
                        ),
                        SizedBox(width: 10.sp),
                        // 우측: 진출자 목록
                        SizedBox(
                          width: 140.sp,
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
          const Spacer(),
          Text(
            '조 지 명 식',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildGroupsPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    // 초기 그룹 설정 (아직 추첨 안된 경우)
    if (_groups.isEmpty && bracket != null && bracket.mainTournamentGroups.isNotEmpty) {
      _groups = List.from(bracket.mainTournamentGroups.map((g) => List<String?>.from(g)));
    }

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
            '마이스타리그 조지명식',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
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
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${_currentDrawIndex + 1} / 24',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 8개 조 (각 조 4명) 표시 - 2열 4행
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8.sp,
        crossAxisSpacing: 8.sp,
        childAspectRatio: 0.75,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        final groupIndex = index;
        final groupPlayers = _groups.isNotEmpty && groupIndex < _groups.length
            ? _groups[groupIndex]
            : <String?>[null, null, null, null];

        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(6.sp),
            border: Border.all(
              color: _getGroupColor(index).withOpacity(0.5),
              width: 1,
            ),
          ),
          padding: EdgeInsets.all(6.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 조 헤더
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4.sp),
                decoration: BoxDecoration(
                  color: _getGroupColor(index).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Center(
                  child: Text(
                    '${String.fromCharCode(65 + index)}조',
                    style: TextStyle(
                      color: _getGroupColor(index),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6.sp),
              // 4명 슬롯
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (i) {
                    final playerId = i < groupPlayers.length ? groupPlayers[i] : null;
                    final player = playerId != null ? playerMap[playerId] : null;
                    final isSeed = i == 0; // 첫 번째가 시드
                    final isRevealed = _isCompleted || (i == 0); // 시드는 항상 표시

                    return _buildPlayerSlot(player, isSeed, isRevealed);
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerSlot(Player? player, bool isSeed, bool isRevealed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 3.sp),
      margin: EdgeInsets.symmetric(vertical: 2.sp),
      decoration: BoxDecoration(
        color: isSeed
            ? AppColors.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: isSeed ? AppColors.primary : Colors.grey.withOpacity(0.3),
          width: isSeed ? 1.5 : 1,
        ),
      ),
      child: isRevealed && player != null
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: isSeed ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '(${player.race.code})',
                  style: TextStyle(
                    color: _getRaceColor(player.race),
                    fontSize: 8.sp,
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                isRevealed ? '빈 슬롯' : '???',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 8.sp,
                ),
              ),
            ),
    );
  }

  Widget _buildPlayersPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    // 시드 선수 (조지명식 직행)
    final seedPlayers = bracket?.mainTournamentSeeds ?? [];
    // 듀얼 토너먼트 통과자 (나머지 슬롯 채울 선수)
    final dualQualifiers = bracket?.dualTournamentPlayers ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(10.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시드 선수 섹션
          Text(
            '시드 (조지명식 직행)',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.sp),
          SizedBox(
            height: 120.sp,
            child: ListView.builder(
              itemCount: seedPlayers.length,
              itemBuilder: (context, index) {
                final player = playerMap[seedPlayers[index]];
                if (player == null) return const SizedBox();

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 3.sp),
                  child: Row(
                    children: [
                      Container(
                        width: 18.sp,
                        height: 18.sp,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.sp),
                      Expanded(
                        child: Text(
                          player.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '(${player.race.code})',
                        style: TextStyle(
                          color: _getRaceColor(player.race),
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(color: Colors.grey[700], height: 16.sp),
          // 듀얼토너먼트 통과자 섹션
          Text(
            '듀얼토너먼트 통과자',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.sp),
          Expanded(
            child: dualQualifiers.isEmpty
                ? Center(
                    child: Text(
                      '듀얼토너먼트\n미진행',
                      style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    itemCount: dualQualifiers.length,
                    itemBuilder: (context, index) {
                      final player = playerMap[dualQualifiers[index]];
                      if (player == null) return const SizedBox();

                      // 이미 조에 배정된 선수인지 확인
                      final isDrawn = _groups.any((g) => g.contains(player.id));

                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 3.sp),
                        child: Row(
                          children: [
                            Container(
                              width: 18.sp,
                              height: 18.sp,
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
                                        size: 10.sp,
                                        color: AppColors.accent,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 9.sp,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(width: 6.sp),
                            Expanded(
                              child: Text(
                                player.name,
                                style: TextStyle(
                                  color: isDrawn ? Colors.grey : Colors.white,
                                  fontSize: 10.sp,
                                  decoration: isDrawn
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '(${player.race.code})',
                              style: TextStyle(
                                color: _getRaceColor(player.race),
                                fontSize: 9.sp,
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
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                context.go('/main');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  'EXIT',
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
                  _isCompleted ? 'Next' : 'Start',
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
    if (bracket == null || bracket.mainTournamentGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조 데이터가 없습니다')),
      );
      return;
    }

    // 이미 시드가 설정된 조 데이터 가져오기
    final existingGroups = bracket.mainTournamentGroups;

    // 듀얼 토너먼트 통과자 (나머지 슬롯 채울 선수)
    final dualQualifiers = List<String>.from(bracket.dualTournamentPlayers);

    // 시드 선수 ID 목록 (이미 조에 배정된 선수)
    final seededIds = existingGroups
        .map((g) => g.isNotEmpty && g[0] != null ? g[0]! : '')
        .where((id) => id.isNotEmpty)
        .toSet();

    // 듀얼 통과자 중 시드 아닌 선수만 추출
    final availableQualifiers = dualQualifiers
        .where((id) => !seededIds.contains(id))
        .toList();

    // 랜덤 섞기
    availableQualifiers.shuffle();

    setState(() {
      _isDrawing = true;
      _currentDrawIndex = -1;
      // 기존 조 복사 (시드만 있는 상태)
      _groups = existingGroups.map((g) => List<String?>.from(g)).toList();
    });

    // 8개 조 × 3명 = 24명을 채워야 함
    var qualifierIndex = 0;
    var drawIndex = 0;

    for (var groupIdx = 0; groupIdx < 8; groupIdx++) {
      // 각 조의 1~3번 슬롯 채우기 (0번은 이미 시드)
      for (var slotIdx = 1; slotIdx < 4; slotIdx++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;

        setState(() {
          _currentDrawIndex = drawIndex;
          if (qualifierIndex < availableQualifiers.length) {
            _groups[groupIdx][slotIdx] = availableQualifiers[qualifierIndex];
            qualifierIndex++;
          }
        });
        drawIndex++;
      }
    }

    setState(() {
      _isDrawing = false;
      _isCompleted = true;
    });

    // 게임 상태 업데이트
    final notifier = ref.read(gameStateProvider.notifier);
    final updatedBracket = bracket.copyWith(
      mainTournamentGroups: _groups,
    );
    // TODO: 실제 저장 로직 구현
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
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
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
