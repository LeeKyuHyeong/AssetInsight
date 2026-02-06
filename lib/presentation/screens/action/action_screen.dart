import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../data/providers/game_provider.dart';
import '../../../domain/models/models.dart';

enum ActionType { rest, training, fanMeeting }

class ActionScreen extends ConsumerStatefulWidget {
  const ActionScreen({super.key});

  @override
  ConsumerState<ActionScreen> createState() => _ActionScreenState();
}

class _ActionScreenState extends ConsumerState<ActionScreen> {
  ActionType _selectedAction = ActionType.rest;
  Set<String> _selectedPlayerIds = {};

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('게임 데이터를 불러올 수 없습니다')),
      );
    }

    final team = gameState.playerTeam;
    final players = gameState.playerTeamPlayers;
    final actionPoints = team.actionPoints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('선수 행동'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 상단: 행동력 표시
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.cardBackground,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '보유 행동력',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$actionPoints',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 메인 콘텐츠
          Expanded(
            child: Row(
              children: [
                // 왼쪽: 선수 목록
                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 선수 목록 헤더 + 전체선택/해제
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '선수 목록',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              children: [
                                _buildSelectAllButton(players, actionPoints),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final player = players[index];
                            final isSelected = _selectedPlayerIds.contains(player.id);
                            final canDoAction = _canPlayerDoAction(player);
                            final cost = _getActionCost();
                            final canAfford = actionPoints >= cost;
                            final isSelectable = canDoAction && canAfford;

                            return Card(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : isSelectable
                                      ? AppTheme.cardBackground
                                      : AppTheme.cardBackground.withOpacity(0.5),
                              margin: const EdgeInsets.only(bottom: 4),
                              child: InkWell(
                                onTap: isSelectable
                                    ? () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedPlayerIds.remove(player.id);
                                          } else {
                                            _selectedPlayerIds.add(player.id);
                                          }
                                        });
                                      }
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      // 체크박스 (행동력 부족 또는 행동 불가 시 숨김)
                                      if (isSelectable)
                                        SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: Checkbox(
                                            value: isSelected,
                                            onChanged: (value) {
                                              setState(() {
                                                if (value == true) {
                                                  _selectedPlayerIds.add(player.id);
                                                } else {
                                                  _selectedPlayerIds.remove(player.id);
                                                }
                                              });
                                            },
                                            activeColor: AppTheme.accentGreen,
                                            checkColor: Colors.black,
                                            side: const BorderSide(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        )
                                      else
                                        const SizedBox(width: 24, height: 24),
                                      const SizedBox(width: 4),
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: isSelectable
                                            ? AppTheme.getRaceColor(player.race.code)
                                            : AppTheme.getRaceColor(player.race.code).withOpacity(0.4),
                                        child: Text(
                                          player.race.code,
                                          style: TextStyle(
                                            color: isSelectable ? Colors.white : Colors.white54,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              player.name,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white
                                                    : isSelectable
                                                        ? AppTheme.textPrimary
                                                        : AppTheme.textSecondary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${player.condition.clamp(0, 100)}%',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: isSelected
                                                        ? Colors.white70
                                                        : isSelectable
                                                            ? _getConditionColor(player.condition)
                                                            : AppTheme.textSecondary.withOpacity(0.5),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                // 필요 행동력 표시
                                                Text(
                                                  '${cost}AP',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: isSelected
                                                        ? Colors.white70
                                                        : canAfford
                                                            ? AppTheme.accentGreen
                                                            : Colors.red.withOpacity(0.7),
                                                  ),
                                                ),
                                                if (!canDoAction && canAfford) ...[
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _getDisabledReason(player),
                                                    style: TextStyle(
                                                      fontSize: 8,
                                                      color: Colors.red.withOpacity(0.7),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // 오른쪽: 행동 선택 및 실행
                Expanded(
                  child: Column(
                    children: [
                      // 행동 선택 버튼
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _buildActionButton(
                              ActionType.rest,
                              '휴식',
                              Icons.hotel,
                              50,
                              actionPoints,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              ActionType.training,
                              '특훈',
                              Icons.fitness_center,
                              100,
                              actionPoints,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              ActionType.fanMeeting,
                              '팬미팅',
                              Icons.people,
                              200,
                              actionPoints,
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // 행동 상세 정보
                      Expanded(
                        child: _buildActionDetail(actionPoints, players),
                      ),
                      // 실행 버튼
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _canExecuteAction(actionPoints)
                                ? () => _executeAction(players)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentGreen,
                              foregroundColor: Colors.black,
                              disabledBackgroundColor: AppTheme.cardBackground,
                            ),
                            child: Text(
                              _getExecuteButtonText(actionPoints),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildSelectAllButton(List<Player> players, int actionPoints) {
    final cost = _getActionCost();
    final canAfford = actionPoints >= cost;
    final availablePlayers = canAfford
        ? players.where(_canPlayerDoAction).toList()
        : <Player>[];
    final allSelected = availablePlayers.isNotEmpty &&
        availablePlayers.every((p) => _selectedPlayerIds.contains(p.id));

    return GestureDetector(
      onTap: () {
        setState(() {
          if (allSelected) {
            // 전체 해제
            _selectedPlayerIds.clear();
          } else {
            // 가능한 선수만 전체 선택
            _selectedPlayerIds = availablePlayers.map((p) => p.id).toSet();
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: allSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppTheme.primaryBlue,
            width: 1,
          ),
        ),
        child: Text(
          allSelected ? '해제' : '전체',
          style: TextStyle(
            fontSize: 10,
            color: allSelected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  int _getActionCost() {
    switch (_selectedAction) {
      case ActionType.rest:
        return 50;
      case ActionType.training:
        return 100;
      case ActionType.fanMeeting:
        return 200;
    }
  }

  bool _canPlayerDoAction(Player player) {
    switch (_selectedAction) {
      case ActionType.rest:
        // 휴식: 컨디션 100 미만인 선수만 가능
        return player.condition < 100;
      case ActionType.training:
        // 특훈: 모든 선수 가능
        return true;
      case ActionType.fanMeeting:
        // 팬미팅: 모든 선수 가능
        return true;
    }
  }

  String _getDisabledReason(Player player) {
    switch (_selectedAction) {
      case ActionType.rest:
        if (player.condition >= 100) {
          return '(최상)';
        }
        return '';
      case ActionType.training:
      case ActionType.fanMeeting:
        return '';
    }
  }

  Widget _buildActionButton(
    ActionType action,
    String label,
    IconData icon,
    int cost,
    int currentPoints,
  ) {
    final isSelected = _selectedAction == action;
    final canAfford = currentPoints >= cost;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedAction = action;
            // 행동 변경 시 선택된 선수 초기화 (새 행동에서 불가능한 선수가 있을 수 있음)
            _selectedPlayerIds.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGreen
                  : canAfford
                      ? AppTheme.primaryBlue
                      : Colors.red.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.accentGreen
                    : canAfford
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : canAfford
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$cost AP',
                style: TextStyle(
                  fontSize: 10,
                  color: canAfford ? AppTheme.accentGreen : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionDetail(int actionPoints, List<Player> players) {
    String title;
    String description;
    String effect;
    int cost;

    switch (_selectedAction) {
      case ActionType.rest:
        title = '휴식';
        description = '선수가 휴식을 취합니다.\n쉬면서 컨디션을 회복합니다.';
        effect = '컨디션 +4~5';
        cost = 50;
        break;
      case ActionType.training:
        title = '특훈';
        description = '선수가 특별 훈련을 합니다.\n능력치가 소폭 상승합니다.';
        effect = '능력치 랜덤 상승 (레벨에 따라 차이)\n컨디션 -1';
        cost = 100;
        break;
      case ActionType.fanMeeting:
        title = '팬미팅';
        description = '선수가 팬미팅을 진행합니다.\n소지금을 획득하고, 치어풀을 얻을 수도 있습니다.';
        effect = '소지금 획득 (등급에 따라 차이)\n치어풀 획득 확률 35~55%\n컨디션 -2';
        cost = 200;
        break;
    }

    final selectedPlayers = players
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();
    final totalCost = cost * selectedPlayers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 행동 정보
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  '효과',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  effect,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('1인당 행동력'),
                    Text(
                      '$cost',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: actionPoints >= cost
                            ? AppTheme.accentGreen
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                if (selectedPlayers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('총 소모 (${selectedPlayers.length}명)'),
                      Text(
                        '$totalCost',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: actionPoints >= totalCost
                              ? AppTheme.accentGreen
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 선택된 선수 정보
          if (selectedPlayers.isNotEmpty) ...[
            Text(
              '선택된 선수 (${selectedPlayers.length}명)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedPlayers.map((player) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppTheme.getRaceColor(player.race.code),
                    child: Text(
                      player.race.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.getGradeColor(player.grade.display),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                player.grade.display,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Lv.${player.level}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '컨디션',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        '${player.condition.clamp(0, 100)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getConditionColor(player.condition),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Text(
                  '왼쪽에서 선수를 선택하세요\n(복수 선택 가능)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getConditionColor(int condition) {
    if (condition >= 80) return AppTheme.accentGreen;
    if (condition >= 50) return Colors.orange;
    return Colors.red;
  }

  bool _canExecuteAction(int actionPoints) {
    if (_selectedPlayerIds.isEmpty) return false;

    int costPerPlayer;
    switch (_selectedAction) {
      case ActionType.rest:
        costPerPlayer = 50;
        break;
      case ActionType.training:
        costPerPlayer = 100;
        break;
      case ActionType.fanMeeting:
        costPerPlayer = 200;
        break;
    }

    final totalCost = costPerPlayer * _selectedPlayerIds.length;
    return actionPoints >= totalCost;
  }

  String _getExecuteButtonText(int actionPoints) {
    if (_selectedPlayerIds.isEmpty) return '선수를 선택하세요';

    int costPerPlayer;
    switch (_selectedAction) {
      case ActionType.rest:
        costPerPlayer = 50;
        break;
      case ActionType.training:
        costPerPlayer = 100;
        break;
      case ActionType.fanMeeting:
        costPerPlayer = 200;
        break;
    }

    final totalCost = costPerPlayer * _selectedPlayerIds.length;

    if (actionPoints < totalCost) {
      return '행동력 부족 (${totalCost - actionPoints} 필요)';
    }

    return '실행 (${_selectedPlayerIds.length}명)';
  }

  void _executeAction(List<Player> players) {
    if (_selectedPlayerIds.isEmpty) return;

    final selectedPlayers = players
        .where((p) => _selectedPlayerIds.contains(p.id))
        .toList();
    final notifier = ref.read(gameStateProvider.notifier);

    List<String> resultMessages = [];
    int totalMoney = 0;
    int cheerfulCount = 0;

    switch (_selectedAction) {
      case ActionType.rest:
        for (final player in selectedPlayers) {
          notifier.playerRest(player.id);
          resultMessages.add('${player.name}: 컨디션 회복');
        }
        _showResultDialog(
          '휴식 완료',
          '${selectedPlayers.length}명의 선수가 휴식을 취했습니다.\n\n${resultMessages.join('\n')}',
          Icons.hotel,
        );
        break;
      case ActionType.training:
        for (final player in selectedPlayers) {
          notifier.playerTraining(player.id);
          resultMessages.add('${player.name}: 능력치 상승');
        }
        _showResultDialog(
          '특훈 완료',
          '${selectedPlayers.length}명의 선수가 특훈을 완료했습니다.\n\n${resultMessages.join('\n')}',
          Icons.fitness_center,
        );
        break;
      case ActionType.fanMeeting:
        for (final player in selectedPlayers) {
          final (gotCheerful, moneyEarned) = notifier.playerFanMeeting(player.id);
          totalMoney += moneyEarned;
          if (gotCheerful) {
            cheerfulCount++;
            resultMessages.add('${player.name}: +${moneyEarned}만원, 치어풀 획득!');
          } else {
            resultMessages.add('${player.name}: +${moneyEarned}만원');
          }
        }
        String summary = '${selectedPlayers.length}명의 선수가 팬미팅을 진행했습니다.\n'
            '총 수입: ${totalMoney}만원';
        if (cheerfulCount > 0) {
          summary += '\n치어풀 획득: ${cheerfulCount}명';
        }
        _showResultDialog(
          '팬미팅 완료',
          '$summary\n\n${resultMessages.join('\n')}',
          Icons.people,
        );
        break;
    }

    // 실행 후 선택 초기화
    setState(() {
      _selectedPlayerIds.clear();
    });
  }

  void _showResultDialog(String title, String message, IconData icon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Row(
          children: [
            Icon(icon, color: AppTheme.accentGreen),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              '확인',
              style: TextStyle(color: AppTheme.accentGreen),
            ),
          ),
        ],
      ),
    );
  }
}
