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
  List<String> _remainingQualifiers = []; // 아직 배정 안된 통과자

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

    // 초기화
    _initializeGroups(bracket);
    _initializeQualifiers(bracket);

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
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                    child: Column(
                      children: [
                        // 상단: A~D 조 (가로 배치)
                        _buildGroupRow(0, 4, playerMap),
                        SizedBox(height: 4.sp),
                        // 중단: E~H 조 (가로 배치)
                        _buildGroupRow(4, 8, playerMap),
                        SizedBox(height: 6.sp),
                        // 하단: 통과자 박스
                        Expanded(
                          child: _buildQualifiersBox(bracket, playerMap),
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

  void _initializeGroups(IndividualLeagueBracket? bracket) {
    if (_groups.isEmpty && bracket != null && bracket.mainTournamentGroups.isNotEmpty) {
      _groups = List.from(bracket.mainTournamentGroups.map((g) => List<String?>.from(g)));
    }
    // 8개 조 보장
    while (_groups.length < 8) {
      _groups.add([null, null, null, null]);
    }
  }

  void _initializeQualifiers(IndividualLeagueBracket? bracket) {
    if (_remainingQualifiers.isEmpty && bracket != null) {
      final dualQualifiers = bracket.dualTournamentPlayers;
      final seededIds = bracket.mainTournamentSeeds.toSet();
      // 이미 조에 배정된 선수 제외
      final assignedIds = _groups.expand((g) => g.whereType<String>()).toSet();
      _remainingQualifiers = dualQualifiers
          .where((id) => !seededIds.contains(id) && !assignedIds.contains(id))
          .toList();
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.sports_esports, color: AppColors.accent, size: 20.sp),
          const Spacer(),
          Text(
            '조 지 명 식',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Icon(Icons.sports_esports, color: AppColors.accent, size: 20.sp),
        ],
      ),
    );
  }

  /// 조 행 빌드 (startIndex부터 endIndex까지)
  Widget _buildGroupRow(int startIndex, int endIndex, Map<String, Player> playerMap) {
    return Row(
      children: List.generate(endIndex - startIndex, (i) {
        final groupIndex = startIndex + i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.sp),
            child: _buildGroupCard(groupIndex, playerMap),
          ),
        );
      }),
    );
  }

  /// 개별 조 카드
  Widget _buildGroupCard(int groupIndex, Map<String, Player> playerMap) {
    final groupPlayers = groupIndex < _groups.length
        ? _groups[groupIndex]
        : <String?>[null, null, null, null];
    final groupName = String.fromCharCode(65 + groupIndex); // A, B, C...

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: _getGroupColor(groupIndex).withOpacity(0.5),
          width: 1,
        ),
      ),
      padding: EdgeInsets.all(4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조 헤더
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 2.sp),
            decoration: BoxDecoration(
              color: _getGroupColor(groupIndex).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Center(
              child: Text(
                '$groupName조',
                style: TextStyle(
                  color: _getGroupColor(groupIndex),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 3.sp),
          // 4명 슬롯
          ...List.generate(4, (i) {
            final playerId = i < groupPlayers.length ? groupPlayers[i] : null;
            final player = playerId != null ? playerMap[playerId] : null;
            final isSeed = i == 0;
            return _buildPlayerSlot(player, isSeed);
          }),
        ],
      ),
    );
  }

  /// 선수 슬롯 (종족) 이름 형식
  Widget _buildPlayerSlot(Player? player, bool isSeed) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 2.sp),
      margin: EdgeInsets.only(bottom: 2.sp),
      decoration: BoxDecoration(
        color: isSeed
            ? AppColors.primary.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.sp),
        border: Border.all(
          color: isSeed ? AppColors.primary.withOpacity(0.4) : Colors.grey.withOpacity(0.2),
          width: isSeed ? 1 : 0.5,
        ),
      ),
      child: player != null
          ? Row(
              children: [
                Text(
                  '(${player.race.code})',
                  style: TextStyle(
                    color: _getRaceColor(player.race),
                    fontSize: 8.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2.sp),
                Expanded(
                  child: Text(
                    player.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: isSeed ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                'empty',
                style: TextStyle(
                  color: Colors.grey.withOpacity(0.4),
                  fontSize: 7.sp,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
    );
  }

  /// 통과자 박스 (하단 전체 너비)
  Widget _buildQualifiersBox(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    // 듀얼 토너먼트 통과자 전체
    final allQualifiers = bracket?.dualTournamentPlayers ?? [];
    final seededIds = (bracket?.mainTournamentSeeds ?? []).toSet();

    // 이미 조에 배정된 선수 ID
    final assignedIds = _groups.expand((g) => g.whereType<String>()).toSet();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(8.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            children: [
              Icon(Icons.people, color: AppColors.accent, size: 14.sp),
              SizedBox(width: 6.sp),
              Text(
                '듀얼토너먼트 통과자',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isDrawing)
                Row(
                  children: [
                    SizedBox(
                      width: 12.sp,
                      height: 12.sp,
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 6.sp),
                    Text(
                      '추첨 중... ${_currentDrawIndex + 1}/24',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 6.sp),
          // 통과자 목록 (Wrap으로 가로 배치)
          Expanded(
            child: allQualifiers.isEmpty
                ? Center(
                    child: Text(
                      '듀얼토너먼트 미진행',
                      style: TextStyle(color: Colors.grey, fontSize: 11.sp),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 6.sp,
                      runSpacing: 4.sp,
                      children: allQualifiers
                          .where((id) => !seededIds.contains(id))
                          .map((playerId) {
                        final player = playerMap[playerId];
                        if (player == null) return const SizedBox.shrink();

                        final isAssigned = assignedIds.contains(playerId);

                        return _buildQualifierChip(player, isAssigned);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 통과자 칩
  Widget _buildQualifierChip(Player player, bool isAssigned) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 3.sp),
      decoration: BoxDecoration(
        color: isAssigned
            ? Colors.grey.withOpacity(0.2)
            : AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: isAssigned
              ? Colors.grey.withOpacity(0.3)
              : AppColors.accent.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '(${player.race.code})',
            style: TextStyle(
              color: isAssigned
                  ? Colors.grey
                  : _getRaceColor(player.race),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              decoration: isAssigned ? TextDecoration.lineThrough : null,
            ),
          ),
          SizedBox(width: 2.sp),
          Text(
            player.name,
            style: TextStyle(
              color: isAssigned ? Colors.grey : Colors.white,
              fontSize: 9.sp,
              decoration: isAssigned ? TextDecoration.lineThrough : null,
            ),
          ),
          if (isAssigned) ...[
            SizedBox(width: 4.sp),
            Icon(Icons.check, size: 10.sp, color: AppColors.accent),
          ],
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
      padding: EdgeInsets.all(10.sp),
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
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 14.sp),
                SizedBox(width: 6.sp),
                Text(
                  'EXIT',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.sp),
          ElevatedButton(
            onPressed: _isDrawing
                ? null
                : () => _isCompleted
                    ? _goToNextStage(context)
                    : _startDraw(bracket),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isDrawing ? Colors.grey : AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
            ),
            child: Row(
              children: [
                Text(
                  _isCompleted ? 'Next' : 'Start',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
                SizedBox(width: 6.sp),
                Icon(Icons.arrow_forward, color: Colors.white, size: 14.sp),
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

    // 기존 조 복사 (시드만 있는 상태)
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
      _groups = existingGroups.map((g) => List<String?>.from(g)).toList();
    });

    // 8개 조 × 3명 = 24명을 채워야 함
    var qualifierIndex = 0;
    var drawIndex = 0;

    for (var groupIdx = 0; groupIdx < 8; groupIdx++) {
      // 각 조의 1~3번 슬롯 채우기 (0번은 이미 시드)
      for (var slotIdx = 1; slotIdx < 4; slotIdx++) {
        await Future.delayed(const Duration(milliseconds: 200));
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
