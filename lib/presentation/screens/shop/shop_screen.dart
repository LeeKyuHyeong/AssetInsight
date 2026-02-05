import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../data/providers/game_provider.dart';
import '../../../domain/models/item.dart';
import '../../../domain/models/enums.dart';
import '../../widgets/reset_button.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  ItemType _selectedCategory = ItemType.consumable;
  String? _selectedItemId;
  final Map<String, int> _cart = {}; // itemId -> quantity

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('게임 데이터를 불러올 수 없습니다')),
      );
    }

    final money = gameState.playerTeam.money;
    final inventory = gameState.inventory;

    return Scaffold(
      appBar: AppBar(
        title: const Text('아이템 상점'),
        leading: ResetButton.leading(),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/main'),
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 18),
            label: const Text('나가기', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: Column(
            children: [
              // 상단: 보유 금액 + 카테고리 선택
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.cardBackground,
                child: Row(
                  children: [
                    // 카테고리 드롭다운
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ItemType>(
                            value: _selectedCategory,
                            isExpanded: true,
                            dropdownColor: AppTheme.primaryBlue,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: ItemType.consumable,
                                child: Row(
                                  children: [
                                    Icon(Icons.shopping_bag, size: 18, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Text('소모품'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ItemType.mouse,
                                child: Row(
                                  children: [
                                    Icon(Icons.mouse, size: 18, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    const Text('마우스'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ItemType.keyboard,
                                child: Row(
                                  children: [
                                    Icon(Icons.keyboard, size: 18, color: Colors.green),
                                    const SizedBox(width: 8),
                                    const Text('키보드'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ItemType.monitor,
                                child: Row(
                                  children: [
                                    Icon(Icons.desktop_windows, size: 18, color: Colors.cyan),
                                    const SizedBox(width: 8),
                                    const Text('모니터'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: ItemType.accessory,
                                child: Row(
                                  children: [
                                    Icon(Icons.diamond, size: 18, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    const Text('기타'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                  _selectedItemId = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 보유 금액
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '보유 금액',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          '$money 만원',
                          style: const TextStyle(
                            fontSize: 18,
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
              // 아이템 목록 (상단 절반)
              Expanded(
                flex: 1,
                child: _buildItemList(inventory),
              ),
              const Divider(height: 1),
              // 아이템 상세 + 구매 (하단 절반)
              Expanded(
                flex: 1,
                child: _buildItemDetailAndPurchase(money, inventory),
              ),
            ],
          ),
    );
  }

  Widget _buildItemList(Inventory inventory) {
    List<dynamic> items;

    if (_selectedCategory == ItemType.consumable) {
      items = ConsumableItems.all;
    } else if (_selectedCategory == ItemType.mouse) {
      items = Equipments.allMice;
    } else if (_selectedCategory == ItemType.keyboard) {
      items = Equipments.allKeyboards;
    } else if (_selectedCategory == ItemType.monitor) {
      items = Equipments.allMonitors;
    } else {
      items = Equipments.allAccessories;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is ConsumableItem) {
          return _buildConsumableItem(item, inventory);
        } else if (item is Equipment) {
          return _buildEquipmentItem(item, inventory);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildConsumableItem(ConsumableItem item, Inventory inventory) {
    final owned = inventory.getConsumableCount(item.id);
    final isSelected = _selectedItemId == item.id;
    final cartCount = _cart[item.id] ?? 0;

    return Card(
      color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedItemId = item.id;
          });
        },
        leading: _getItemIcon(item.id),
        title: Text(
          item.name,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          item.isPurchasable ? '${item.price}만원' : '비매품',
          style: TextStyle(
            color: item.isPurchasable ? AppTheme.accentGreen : Colors.orange,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '보유: $owned',
              style: TextStyle(
                color: owned > 0 ? AppTheme.accentGreen : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            if (cartCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

  Widget _buildEquipmentItem(Equipment equipment, Inventory inventory) {
    final isSelected = _selectedItemId == equipment.id;
    final ownedCount = inventory.equipments
        .where((e) => e.equipmentId == equipment.id)
        .length;
    final cartCount = _cart[equipment.id] ?? 0;

    return Card(
      color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedItemId = equipment.id;
          });
        },
        leading: _getEquipmentIcon(equipment),
        title: Text(
          equipment.name,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${equipment.price}만원',
              style: const TextStyle(color: AppTheme.accentGreen),
            ),
            const SizedBox(width: 8),
            Text(
              '내구도 ${equipment.durability}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '보유: $ownedCount',
              style: TextStyle(
                color: ownedCount > 0 ? AppTheme.accentGreen : AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            if (cartCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '+$cartCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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

  Widget _buildItemDetailAndPurchase(int money, Inventory inventory) {
    if (_selectedItemId == null) {
      return Container(
        color: AppTheme.cardBackground,
        child: const Center(
          child: Text(
            '아이템을 선택하세요',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ),
      );
    }

    // 소모품인지 확인
    if (_selectedCategory == ItemType.consumable) {
      final item = ConsumableItems.all.firstWhere(
        (i) => i.id == _selectedItemId,
        orElse: () => ConsumableItems.vitaVita,
      );
      return _buildConsumableDetail(item, money, inventory);
    }

    // 장비인 경우
    final equipment = Equipments.getById(_selectedItemId!);
    if (equipment == null) {
      return const Center(child: Text('장비를 찾을 수 없습니다'));
    }
    return _buildEquipmentDetail(equipment, money, inventory);
  }

  Widget _buildConsumableDetail(ConsumableItem item, int money, Inventory inventory) {
    final owned = inventory.getConsumableCount(item.id);
    final cartCount = _cart[item.id] ?? 0;
    final totalPrice = item.price * cartCount;
    final canBuy = item.isPurchasable && money >= totalPrice && cartCount > 0;

    return Container(
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 상단: 아이템 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getItemIcon(item.id, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '보유: $owned개',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          // 하단: 수량 선택 + 구매
          if (item.isPurchasable) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: cartCount > 0
                      ? () => setState(() {
                            _cart[item.id] = cartCount - 1;
                            if (_cart[item.id] == 0) _cart.remove(item.id);
                          })
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.textSecondary,
                  iconSize: 32,
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$cartCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: money >= item.price * (cartCount + 1)
                      ? () => setState(() {
                            _cart[item.id] = cartCount + 1;
                          })
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.accentGreen,
                  iconSize: 32,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '단가: ${item.price}만원',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '총액: ${totalPrice}만원',
                        style: const TextStyle(
                          color: AppTheme.accentGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canBuy ? () => _buyConsumables(item, cartCount) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      cartCount > 0 ? '구입 ($cartCount개)' : '수량 선택',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '비매품 - 팬미팅에서 획득 가능',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentDetail(Equipment equipment, int money, Inventory inventory) {
    final ownedCount = inventory.equipments
        .where((e) => e.equipmentId == equipment.id)
        .length;
    final cartCount = _cart[equipment.id] ?? 0;
    final totalPrice = equipment.price * cartCount;
    final canBuy = money >= totalPrice && cartCount > 0;

    return Container(
      color: AppTheme.cardBackground,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 상단: 장비 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _getEquipmentIcon(equipment, size: 48),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '보유: $ownedCount개',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '내구도: ${equipment.durability}경기',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 스탯 보너스
          Expanded(
            child: SingleChildScrollView(
              child: _buildEquipmentStats(equipment),
            ),
          ),
          const SizedBox(height: 12),
          // 하단: 수량 선택 + 구매
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: cartCount > 0
                    ? () => setState(() {
                          _cart[equipment.id] = cartCount - 1;
                          if (_cart[equipment.id] == 0) _cart.remove(equipment.id);
                        })
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppTheme.textSecondary,
                iconSize: 32,
              ),
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$cartCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: money >= equipment.price * (cartCount + 1)
                    ? () => setState(() {
                          _cart[equipment.id] = cartCount + 1;
                        })
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppTheme.accentGreen,
                iconSize: 32,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '단가: ${equipment.price}만원',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '총액: ${totalPrice}만원',
                      style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: canBuy ? () => _buyEquipments(equipment, cartCount) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: AppTheme.primaryBlue.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    cartCount > 0 ? '구입 ($cartCount개)' : '수량 선택',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentStats(Equipment equipment) {
    final stats = <String, int>{};
    if (equipment.senseBonus != 0) stats['센스'] = equipment.senseBonus;
    if (equipment.controlBonus != 0) stats['컨트롤'] = equipment.controlBonus;
    if (equipment.attackBonus != 0) stats['공격력'] = equipment.attackBonus;
    if (equipment.harassBonus != 0) stats['견제'] = equipment.harassBonus;
    if (equipment.strategyBonus != 0) stats['전략'] = equipment.strategyBonus;
    if (equipment.macroBonus != 0) stats['물량'] = equipment.macroBonus;
    if (equipment.defenseBonus != 0) stats['수비력'] = equipment.defenseBonus;
    if (equipment.scoutBonus != 0) stats['정찰'] = equipment.scoutBonus;
    if (equipment.conditionBonus != 0) stats['컨디션'] = equipment.conditionBonus;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: stats.entries.map((entry) {
        final isPositive = entry.value > 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isPositive
                ? AppTheme.accentGreen.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${isPositive ? '+' : ''}${entry.value}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppTheme.accentGreen : Colors.red,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _getItemIcon(String itemId, {double size = 32}) {
    IconData icon;
    Color color;

    switch (itemId) {
      case 'vita_vita':
        icon = Icons.local_drink;
        color = Colors.orange;
        break;
      case 'chewing_gum':
        icon = Icons.bubble_chart;
        color = Colors.pink;
        break;
      case 'ceremony':
        icon = Icons.celebration;
        color = Colors.purple;
        break;
      case 'sniping':
        icon = Icons.gps_fixed;
        color = Colors.red;
        break;
      case 'cheerful':
        icon = Icons.flag;
        color = Colors.amber;
        break;
      default:
        icon = Icons.help_outline;
        color = AppTheme.textSecondary;
    }

    return Icon(icon, size: size, color: color);
  }

  Widget _getEquipmentIcon(Equipment equipment, {double size = 32}) {
    IconData icon;
    Color color;

    // 기타 악세서리는 개별 아이콘
    if (equipment.type == ItemType.accessory) {
      switch (equipment.id) {
        case 'hot_pack':
          icon = Icons.whatshot;
          color = Colors.deepOrange;
          break;
        case 'wrist_guard':
          icon = Icons.sports_handball;
          color = Colors.blue;
          break;
        case 'shiny_sunglasses':
          icon = Icons.wb_sunny;
          color = Colors.amber;
          break;
        case 'devil_pendant':
          icon = Icons.whatshot;
          color = Colors.red;
          break;
        case 'star_necklace':
          icon = Icons.star;
          color = Colors.yellow;
          break;
        case 'power_ring':
          icon = Icons.radio_button_checked;
          color = Colors.deepPurple;
          break;
        default:
          icon = Icons.diamond;
          color = Colors.purple;
      }
    } else {
      switch (equipment.type) {
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
        default:
          icon = Icons.help_outline;
          color = AppTheme.textSecondary;
      }
    }

    return Icon(icon, size: size, color: color);
  }

  void _buyConsumables(ConsumableItem item, int count) {
    final totalPrice = item.price * count;
    bool allSuccess = true;

    for (int i = 0; i < count; i++) {
      final success = ref.read(gameStateProvider.notifier).buyItem(item.id, item.price);
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    if (allSuccess) {
      setState(() {
        _cart.remove(item.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} ${count}개를 구매했습니다! (-$totalPrice만원)'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _buyEquipments(Equipment equipment, int count) {
    final totalPrice = equipment.price * count;
    bool allSuccess = true;

    for (int i = 0; i < count; i++) {
      final success = ref.read(gameStateProvider.notifier).buyEquipment(equipment);
      if (!success) {
        allSuccess = false;
        break;
      }
    }

    if (allSuccess) {
      setState(() {
        _cart.remove(equipment.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${equipment.name} ${count}개를 구매했습니다! (-$totalPrice만원)'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
