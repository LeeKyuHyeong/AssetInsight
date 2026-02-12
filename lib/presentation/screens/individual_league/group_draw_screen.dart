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
  bool _isWaitingForPick = false;
  int _currentGroupIdx = -1;
  int _currentSlotIdx = -1;
  int _currentRound = 0;
  String _currentPickerName = '';
  List<List<String?>> _groups = [];
  List<String> _availableQualifiers = [];
  Completer<String>? _pickCompleter;
  String? _playerTeamId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAlreadyCompleted();
    });
  }

  void _checkIfAlreadyCompleted() {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;
    _playerTeamId = gameState.saveData.playerTeamId;
    final bracket = gameState.saveData.currentSeason.individualLeague;
    if (bracket == null) return;

    if (bracket.mainTournamentGroups.isNotEmpty) {
      final allFilled = bracket.mainTournamentGroups.every(
        (g) => g.length >= 4 && g.every((p) => p != null),
      );
      if (allFilled) {
        setState(() => _isCompleted = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    // 항상 그룹 초기화 (시드 선수 표시)
    _initializeGroups(bracket);

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
                        _buildGroupRow(0, 4, playerMap),
                        SizedBox(height: 4.sp),
                        _buildGroupRow(4, 8, playerMap),
                        SizedBox(height: 6.sp),
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
          ],
        ),
      ),
    );
  }

  void _initializeGroups(IndividualLeagueBracket? bracket) {
    if (_groups.isEmpty && bracket != null && bracket.mainTournamentGroups.isNotEmpty) {
      _groups = List.from(bracket.mainTournamentGroups.map((g) => List<String?>.from(g)));
    }
    while (_groups.length < 8) {
      _groups.add([null, null, null, null]);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
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
            '조 지 명 식',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          const ResetButton(small: true),
        ],
      ),
    );
  }

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

  Widget _buildGroupCard(int groupIndex, Map<String, Player> playerMap) {
    final groupPlayers = groupIndex < _groups.length
        ? _groups[groupIndex]
        : <String?>[null, null, null, null];
    final groupName = String.fromCharCode(65 + groupIndex);

    // 현재 선택 대기중인 조인지 확인
    final isActiveGroup = _isWaitingForPick && _currentGroupIdx == groupIndex;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: isActiveGroup
              ? AppColors.accent
              : _getGroupColor(groupIndex).withOpacity(0.5),
          width: isActiveGroup ? 2 : 1,
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
              color: isActiveGroup
                  ? AppColors.accent.withOpacity(0.3)
                  : _getGroupColor(groupIndex).withOpacity(0.2),
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Center(
              child: Text(
                '$groupName조',
                style: TextStyle(
                  color: isActiveGroup
                      ? AppColors.accent
                      : _getGroupColor(groupIndex),
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
            final isMyTeam = player != null && player.teamId == _playerTeamId;
            // 현재 선택 대기 슬롯인지
            final isWaitingSlot = isActiveGroup && i == _currentSlotIdx;
            // 현재 지명자 슬롯인지
            final isPickerSlot = isActiveGroup && _currentRound > 0 && i == (_currentRound - 1);
            return _buildPlayerSlot(player, isSeed, isMyTeam: isMyTeam, isWaitingSlot: isWaitingSlot, isPickerSlot: isPickerSlot);
          }),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(Player? player, bool isSeed, {
    bool isMyTeam = false,
    bool isWaitingSlot = false,
    bool isPickerSlot = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 2.sp),
      margin: EdgeInsets.only(bottom: 2.sp),
      decoration: BoxDecoration(
        color: isWaitingSlot
            ? AppColors.accent.withOpacity(0.2)
            : isPickerSlot
                ? Colors.amber.withOpacity(0.15)
                : isSeed
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.sp),
        border: Border.all(
          color: isWaitingSlot
              ? AppColors.accent
              : isPickerSlot
                  ? Colors.amber
                  : isSeed
                      ? AppColors.primary.withOpacity(0.4)
                      : Colors.grey.withOpacity(0.2),
          width: isWaitingSlot ? 1.5 : isPickerSlot ? 1.5 : isSeed ? 1 : 0.5,
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
                      color: isMyTeam ? Colors.purpleAccent : Colors.white,
                      fontSize: 8.sp,
                      fontWeight: (isSeed || isMyTeam) ? FontWeight.bold : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : Center(
              child: isWaitingSlot
                  ? Text(
                      '선택 대기',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 7.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
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

  /// 듀얼토너먼트 결과에서 라운드별 진출자 추출
  List<String> _getAdvancingPlayersFromResults(IndividualLeagueBracket bracket) {
    final results = bracket.dualTournamentResults;
    final advancing = <String>[];

    // 완료된 조별로 승자전 승자 + 최종전 승자 추출
    for (var gi = 0; gi < 12; gi++) {
      final groupStart = gi * 5;
      if (results.length >= groupStart + 5) {
        advancing.add(results[groupStart + 2].winnerId); // 승자전 승자
        advancing.add(results[groupStart + 4].winnerId); // 최종전 승자
      }
    }
    return advancing;
  }

  /// 완료된 듀얼 라운드 수 (0~3)
  int _getCompletedDualRounds(IndividualLeagueBracket? bracket) {
    if (bracket == null) return 0;
    final resultCount = bracket.dualTournamentResults.length;
    // 라운드 1: 0~19 (4조×5경기), 라운드 2: 20~39, 라운드 3: 40~59
    if (resultCount >= 60) return 3;
    if (resultCount >= 40) return 2;
    if (resultCount >= 20) return 1;
    return 0;
  }

  Widget _buildQualifiersBox(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    // 듀얼토너먼트 결과에서 실제 진출자 계산
    final advancingPlayers = bracket != null
        ? _getAdvancingPlayersFromResults(bracket)
        : <String>[];
    final completedRounds = _getCompletedDualRounds(bracket);
    final assignedIds = _groups.expand((g) => g.whereType<String>()).toSet();

    // 상태 텍스트
    final String statusText;
    final Color statusColor;
    if (_isWaitingForPick) {
      statusText = '${_currentRound}라운드 - $_currentPickerName의 선택';
      statusColor = AppColors.accent;
    } else if (_isDrawing) {
      statusText = '${_currentRound}라운드 - $_currentPickerName 지명중...';
      statusColor = AppColors.accent;
    } else if (completedRounds < 3) {
      statusText = '#$completedRounds/3 완료 (${advancingPlayers.length}/24명)';
      statusColor = Colors.grey;
    } else {
      statusText = '${advancingPlayers.length}명 진출';
      statusColor = AppColors.accent;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(
          color: _isWaitingForPick
              ? AppColors.accent
              : AppColors.accent.withOpacity(0.3),
          width: _isWaitingForPick ? 2 : 1,
        ),
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
                _isWaitingForPick ? '선수를 선택하세요' : '듀얼토너먼트 통과자',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (statusText.isNotEmpty)
                Row(
                  children: [
                    if (_isDrawing && !_isWaitingForPick)
                      Padding(
                        padding: EdgeInsets.only(right: 6.sp),
                        child: SizedBox(
                          width: 12.sp,
                          height: 12.sp,
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10.sp,
                        fontWeight: _isWaitingForPick ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 6.sp),
          // 통과자 목록
          Expanded(
            child: advancingPlayers.isEmpty
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
                      children: advancingPlayers.map((playerId) {
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

  Widget _buildQualifierChip(Player player, bool isAssigned) {
    // 선택 가능 여부
    final bool isTappable = _isWaitingForPick && !isAssigned;
    final bool isMyTeam = player.teamId == _playerTeamId;

    return GestureDetector(
      onTap: isTappable ? () => _onQualifierPicked(player.id) : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 3.sp),
        decoration: BoxDecoration(
          color: isAssigned
              ? Colors.grey.withOpacity(0.2)
              : isTappable
                  ? AppColors.accent.withOpacity(0.3)
                  : AppColors.accent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4.sp),
          border: Border.all(
            color: isAssigned
                ? Colors.grey.withOpacity(0.3)
                : isTappable
                    ? AppColors.accent
                    : AppColors.accent.withOpacity(0.4),
            width: isTappable ? 1.5 : 1,
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
                color: isAssigned ? Colors.grey : isMyTeam ? Colors.purpleAccent : Colors.white,
                fontSize: 9.sp,
                fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                decoration: isAssigned ? TextDecoration.lineThrough : null,
              ),
            ),
            if (isAssigned) ...[
              SizedBox(width: 4.sp),
              Icon(Icons.check, size: 10.sp, color: AppColors.accent),
            ],
          ],
        ),
      ),
    );
  }

  void _onQualifierPicked(String playerId) {
    if (_isWaitingForPick && _pickCompleter != null && !_pickCompleter!.isCompleted) {
      _pickCompleter!.complete(playerId);
    }
  }

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final bool canStart = !widget.viewOnly && !_isDrawing && !_isWaitingForPick;

    return Container(
      padding: EdgeInsets.all(10.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (canStart)
            ElevatedButton(
              onPressed: _isCompleted
                  ? () => _goToNextStage(context)
                  : () => _startDraw(bracket, playerMap),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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

  Future<void> _startDraw(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) async {
    if (bracket == null || bracket.mainTournamentGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('조 데이터가 없습니다')),
      );
      return;
    }

    // 듀얼토너먼트 완료 확인 (12개 조 × 5경기 = 60)
    if (bracket.dualTournamentResults.length < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('듀얼토너먼트가 완료되지 않았습니다')),
      );
      return;
    }

    final existingGroups = bracket.mainTournamentGroups;
    // 듀얼토너먼트 결과에서 실제 진출자 추출
    final dualQualifiers = _getAdvancingPlayersFromResults(bracket);
    final seededIds = existingGroups
        .map((g) => g.isNotEmpty && g[0] != null ? g[0]! : '')
        .where((id) => id.isNotEmpty)
        .toSet();

    _availableQualifiers = dualQualifiers
        .where((id) => !seededIds.contains(id))
        .toList()
      ..shuffle();

    setState(() {
      _isDrawing = true;
      _currentRound = 0;
      _currentPickerName = '';
      _groups = existingGroups.map((g) => List<String?>.from(g)).toList();
    });

    // 3라운드 스네이크 드래프트
    for (var round = 1; round <= 3; round++) {
      // 스네이크 순서: 홀수 라운드 A→H, 짝수 라운드 H→A
      final groupOrder = (round % 2 == 1)
          ? List.generate(8, (i) => i)
          : List.generate(8, (i) => 7 - i);

      final pickerSlot = round - 1; // 지명자 슬롯 (0=1시드, 1=2시드, 2=3시드)
      final targetSlot = round;     // 배정 슬롯 (1=2시드, 2=3시드, 3=4시드)

      for (var groupIdx in groupOrder) {
        if (!mounted) return;

        // 현재 지명자 확인
        final pickerId = _groups[groupIdx][pickerSlot];
        final picker = pickerId != null ? playerMap[pickerId] : null;
        final isPickerMyTeam = picker != null && picker.teamId == _playerTeamId;

        String? pickedId;

        if (isPickerMyTeam && _availableQualifiers.isNotEmpty) {
          // 우리팀 선수가 지명자 → 유저가 선택
          _pickCompleter = Completer<String>();
          setState(() {
            _isWaitingForPick = true;
            _currentGroupIdx = groupIdx;
            _currentSlotIdx = targetSlot;
            _currentRound = round;
            _currentPickerName = picker.name;
          });

          pickedId = await _pickCompleter!.future;

          setState(() {
            _isWaitingForPick = false;
          });
        } else if (_availableQualifiers.isNotEmpty) {
          // AI 선수가 지명자 → 랜덤 선택
          setState(() {
            _currentGroupIdx = groupIdx;
            _currentSlotIdx = targetSlot;
            _currentRound = round;
            _currentPickerName = picker?.name ?? '';
          });
          await Future.delayed(const Duration(milliseconds: 200));
          pickedId = _availableQualifiers[0];
        }

        if (pickedId != null && mounted) {
          _availableQualifiers.remove(pickedId);
          setState(() {
            _groups[groupIdx][targetSlot] = pickedId;
          });
        }

      }
    }

    if (!mounted) return;

    // 결과 저장
    final updatedBracket = bracket.copyWith(
      mainTournamentGroups: _groups,
      mainTournamentPlayers: _groups.expand((g) => g.whereType<String>()).toList(),
    );
    ref.read(gameStateProvider.notifier).updateIndividualLeague(updatedBracket);
    ref.read(gameStateProvider.notifier).save();

    setState(() {
      _isDrawing = false;
      _isCompleted = true;
      _currentRound = 0;
      _currentPickerName = '';
    });
  }

  void _goToNextStage(BuildContext context) {
    context.go('/main');
  }

  Color _getGroupColor(int index) {
    const colors = [
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
