import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../data/providers/game_provider.dart';
import '../../../domain/models/models.dart';
import '../../widgets/reset_button.dart';

class EquipmentScreen extends ConsumerStatefulWidget {
  const EquipmentScreen({super.key});

  @override
  ConsumerState<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends ConsumerState<EquipmentScreen> {
  String? _selectedPlayerId;
  ItemType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('게임 데이터를 불러올 수 없습니다')),
      );
    }

    final players = gameState.playerTeamPlayers;

    // 첫 번째 선수 자동 선택
    if (_selectedPlayerId == null && players.isNotEmpty) {
      _selectedPlayerId = players.first.id;
    }

    final selectedPlayer = _selectedPlayerId != null
        ? players.cast<Player?>().firstWhere(
              (p) => p?.id == _selectedPlayerId,
              orElse: () => null,
            )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장비 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
        actions: [
          ResetButton.action(),
        ],
      ),
      body: Column(
            children: [
              // 상단: 선수 선택 드롭다운
              _buildPlayerSelector(players, selectedPlayer),
              const Divider(height: 1),
              // 중단: 장착된 장비 / 보유 장비 (반반)
              Expanded(
                child: Row(
                  children: [
                    // 왼쪽: 장착된 장비
                    Expanded(
                      child: _buildEquippedPanel(selectedPlayer, gameState),
                    ),
                    const VerticalDivider(width: 1),
                    // 오른쪽: 보유 장비
                    Expanded(
                      child: _buildInventoryPanel(gameState),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPlayerSelector(List<Player> players, Player? selectedPlayer) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.cardBackground,
      child: Row(
        children: [
          // 선수 선택 드롭다운
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPlayerId,
                isExpanded: true,
                dropdownColor: AppTheme.cardBackground,
                hint: const Text(
                  '선수를 선택하세요',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                items: players.map((player) {
                  final equippedCount = ref
                      .read(gameStateProvider.notifier)
                      .getPlayerEquipments(player.id)
                      .length;
                  return DropdownMenuItem<String>(
                    value: player.id,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            player.name,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.getGradeColor(player.grade.display).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.grade.display,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.getGradeColor(player.grade.display),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (equippedCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '장비 $equippedCount',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.accentGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPlayerId = value;
                    _selectedType = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedPanel(Player? player, GameState gameState) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.primaryBlue.withOpacity(0.3),
          child: const Row(
            children: [
              Icon(Icons.person, color: AppTheme.accentGreen, size: 18),
              SizedBox(width: 8),
              Text(
                '장착된 장비',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 내용
        Expanded(
          child: player == null
              ? const Center(
                  child: Text(
                    '선수를 선택하세요',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : _buildEquipmentSlots(player),
        ),
      ],
    );
  }

  Widget _buildEquipmentSlots(Player player) {
    final equipments = ref
        .read(gameStateProvider.notifier)
        .getPlayerEquipments(player.id);

    // 슬롯별 장비 찾기
    final mouseEquip = equipments.where((e) => e.$3.type == ItemType.mouse).firstOrNull;
    final keyboardEquip = equipments.where((e) => e.$3.type == ItemType.keyboard).firstOrNull;
    final monitorEquip = equipments.where((e) => e.$3.type == ItemType.monitor).firstOrNull;
    final accessoryEquip = equipments.where((e) => e.$3.type == ItemType.accessory).firstOrNull;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildEquipmentSlot(
            icon: Icons.mouse,
            label: '마우스',
            type: ItemType.mouse,
            equipped: mouseEquip,
          ),
          const SizedBox(height: 8),
          _buildEquipmentSlot(
            icon: Icons.keyboard,
            label: '키보드',
            type: ItemType.keyboard,
            equipped: keyboardEquip,
          ),
          const SizedBox(height: 8),
          _buildEquipmentSlot(
            icon: Icons.desktop_windows,
            label: '모니터',
            type: ItemType.monitor,
            equipped: monitorEquip,
          ),
          const SizedBox(height: 8),
          _buildEquipmentSlot(
            icon: Icons.watch,
            label: '기타',
            type: ItemType.accessory,
            equipped: accessoryEquip,
          ),
          const SizedBox(height: 16),
          // 장비 보너스 합계
          _buildEquipmentBonusSummary(equipments),
        ],
      ),
    );
  }

  Widget _buildEquipmentSlot({
    required IconData icon,
    required String label,
    required ItemType type,
    required (int, EquipmentInstance, Equipment)? equipped,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = isSelected ? null : type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentGreen : AppTheme.primaryBlue.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentGreen : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (equipped != null) ...[
                    Text(
                      equipped.$3.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '내구도: ${equipped.$2.currentDurability}/${equipped.$3.durability}',
                      style: TextStyle(
                        fontSize: 10,
                        color: equipped.$2.currentDurability <= 5
                            ? Colors.red
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ] else
                    const Text(
                      '비어있음',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            if (equipped != null)
              IconButton(
                onPressed: () => _unequipItem(equipped.$1),
                icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                tooltip: '해제',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentBonusSummary(
    List<(int, EquipmentInstance, Equipment)> equipments,
  ) {
    if (equipments.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalSense = 0;
    int totalControl = 0;
    int totalAttack = 0;
    int totalHarass = 0;
    int totalStrategy = 0;
    int totalMacro = 0;
    int totalDefense = 0;
    int totalScout = 0;
    int totalCondition = 0;

    for (final e in equipments) {
      final def = e.$3;
      totalSense += def.senseBonus;
      totalControl += def.controlBonus;
      totalAttack += def.attackBonus;
      totalHarass += def.harassBonus;
      totalStrategy += def.strategyBonus;
      totalMacro += def.macroBonus;
      totalDefense += def.defenseBonus;
      totalScout += def.scoutBonus;
      totalCondition += def.conditionBonus;
    }

    final bonuses = <String, int>{};
    if (totalSense != 0) bonuses['센스'] = totalSense;
    if (totalControl != 0) bonuses['컨트롤'] = totalControl;
    if (totalAttack != 0) bonuses['공격력'] = totalAttack;
    if (totalHarass != 0) bonuses['견제'] = totalHarass;
    if (totalStrategy != 0) bonuses['전략'] = totalStrategy;
    if (totalMacro != 0) bonuses['물량'] = totalMacro;
    if (totalDefense != 0) bonuses['수비력'] = totalDefense;
    if (totalScout != 0) bonuses['정찰'] = totalScout;
    if (totalCondition != 0) bonuses['컨디션'] = totalCondition;

    if (bonuses.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '장비 보너스 합계',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentGreen,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: bonuses.entries.map((entry) {
              final isPositive = entry.value > 0;
              return Text(
                '${entry.key} ${isPositive ? '+' : ''}${entry.value}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppTheme.accentGreen : Colors.red,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryPanel(GameState gameState) {
    final unequipped = ref
        .read(gameStateProvider.notifier)
        .getUnequippedEquipments();

    // 선택된 타입으로 필터링
    final filtered = _selectedType != null
        ? unequipped.where((e) => e.$3.type == _selectedType).toList()
        : unequipped;

    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.primaryBlue.withOpacity(0.3),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, color: AppTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '보유 장비',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (_selectedType != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedType = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getTypeName(_selectedType!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.close, size: 12, color: AppTheme.accentGreen),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 장비 목록
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedType != null
                            ? '해당 타입의 장비가 없습니다'
                            : '보유한 장비가 없습니다',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _buildInventoryItem(item);
                  },
                ),
        ),
        // 상점 바로가기 버튼
        Padding(
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/shop'),
              icon: const Icon(Icons.shopping_cart, size: 16),
              label: const Text('상점'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentGreen,
                side: const BorderSide(color: AppTheme.accentGreen),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getTypeName(ItemType type) {
    switch (type) {
      case ItemType.mouse:
        return '마우스';
      case ItemType.keyboard:
        return '키보드';
      case ItemType.monitor:
        return '모니터';
      case ItemType.accessory:
        return '기타';
      default:
        return '';
    }
  }

  Widget _buildInventoryItem((int, EquipmentInstance, Equipment) item) {
    final (index, instance, def) = item;
    final canEquip = _selectedPlayerId != null;

    return Card(
      color: AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _getEquipmentIcon(def.type),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '내구도: ${instance.currentDurability}/${def.durability}',
                    style: TextStyle(
                      fontSize: 10,
                      color: instance.currentDurability <= 5
                          ? Colors.red
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _buildMiniStats(def),
                ],
              ),
            ),
            if (canEquip)
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  onPressed: () => _equipItem(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('장착'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStats(Equipment def) {
    final stats = <String>[];
    if (def.senseBonus != 0) stats.add('센스+${def.senseBonus}');
    if (def.controlBonus != 0) stats.add('컨트롤+${def.controlBonus}');
    if (def.attackBonus != 0) stats.add('공격력+${def.attackBonus}');
    if (def.harassBonus != 0) stats.add('견제+${def.harassBonus}');
    if (def.strategyBonus != 0) stats.add('전략+${def.strategyBonus}');
    if (def.macroBonus != 0) stats.add('물량+${def.macroBonus}');
    if (def.defenseBonus != 0) stats.add('수비력+${def.defenseBonus}');
    if (def.scoutBonus != 0) stats.add('정찰+${def.scoutBonus}');
    if (def.conditionBonus != 0) {
      final sign = def.conditionBonus > 0 ? '+' : '';
      stats.add('컨디션$sign${def.conditionBonus}');
    }

    return Text(
      stats.join(', '),
      style: const TextStyle(
        fontSize: 9,
        color: AppTheme.accentGreen,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _getEquipmentIcon(ItemType type, {double size = 24}) {
    IconData icon;
    Color color;

    switch (type) {
      case ItemType.mouse:
        icon = Icons.mouse;
        color = Colors.blue;
        break;
      case ItemType.keyboard:
        icon = Icons.keyboard;
        color = Colors.green;
        break;
      case ItemType.monitor:
        icon = Icons.desktop_windows;
        color = Colors.cyan;
        break;
      case ItemType.accessory:
        icon = Icons.watch;
        color = Colors.purple;
        break;
      default:
        icon = Icons.help_outline;
        color = AppTheme.textSecondary;
    }

    return Container(
      width: size + 8,
      height: size + 8,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: size, color: color),
    );
  }

  void _equipItem(int index) {
    if (_selectedPlayerId == null) return;

    final success = ref
        .read(gameStateProvider.notifier)
        .equipItem(index, _selectedPlayerId!);

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장비를 장착했습니다!'),
          backgroundColor: AppTheme.accentGreen,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _unequipItem(int index) {
    final success = ref.read(gameStateProvider.notifier).unequipItem(index);

    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장비를 해제했습니다.'),
          backgroundColor: AppTheme.primaryBlue,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('장비 해제에 실패했습니다.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
