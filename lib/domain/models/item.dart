import 'package:hive/hive.dart';
import 'enums.dart';

part 'item.g.dart';

/// 아이템 정의 (소모품)
@HiveType(typeId: 5)
class ConsumableItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final int price; // 만원

  @HiveField(4)
  final bool isPurchasable; // 구매 가능 여부 (치어풀은 비매품)

  const ConsumableItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.isPurchasable = true,
  });
}

/// 기본 소모품 아이템 목록
class ConsumableItems {
  static const vitaVita = ConsumableItem(
    id: 'vita_vita',
    name: '비타비타',
    description: '즉시 컨디션 +3\n힘들고 지칠 때 비타민을 마시면 기운이 난다',
    price: 5,
  );

  static const chewingGum = ConsumableItem(
    id: 'chewing_gum',
    name: '츄잉껌',
    description: '패배 시 능력치 감소 -66%',
    price: 5,
  );

  static const ceremony = ConsumableItem(
    id: 'ceremony',
    name: '세레모니',
    description: '승리 시 전원 컨디션 +1, 소지금 +15만원',
    price: 10,
  );

  static const sniping = ConsumableItem(
    id: 'sniping',
    name: '스나이핑',
    description: '내 선수에게 사용, 상대 선수 예측 성공 시 승률 +20%',
    price: 5,
  );

  static const cheerful = ConsumableItem(
    id: 'cheerful',
    name: '치어풀',
    description: '한 경기 동안 전체 능력치 +75',
    price: 0,
    isPurchasable: false, // 팬미팅 랜덤 획득
  );

  static List<ConsumableItem> get all => [
    vitaVita,
    chewingGum,
    ceremony,
    sniping,
    cheerful,
  ];

  static List<ConsumableItem> get purchasable =>
      all.where((item) => item.isPurchasable).toList();
}

/// 장비 아이템 정의
@HiveType(typeId: 6)
class Equipment {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int typeIndex; // ItemType enum index

  @HiveField(3)
  final int price; // 만원

  @HiveField(4)
  final int durability; // 내구도 (경기 수)

  @HiveField(5)
  final int senseBonus;

  @HiveField(6)
  final int controlBonus;

  @HiveField(7)
  final int attackBonus;

  @HiveField(8)
  final int harassBonus;

  @HiveField(9)
  final int strategyBonus;

  @HiveField(10)
  final int macroBonus;

  @HiveField(11)
  final int defenseBonus;

  @HiveField(12)
  final int scoutBonus;

  @HiveField(13)
  final int conditionBonus;

  const Equipment({
    required this.id,
    required this.name,
    required this.typeIndex,
    required this.price,
    required this.durability,
    this.senseBonus = 0,
    this.controlBonus = 0,
    this.attackBonus = 0,
    this.harassBonus = 0,
    this.strategyBonus = 0,
    this.macroBonus = 0,
    this.defenseBonus = 0,
    this.scoutBonus = 0,
    this.conditionBonus = 0,
  });

  ItemType get type => ItemType.values[typeIndex];

  /// 전체 스탯 보너스 합계
  int get totalStatBonus =>
      senseBonus +
      controlBonus +
      attackBonus +
      harassBonus +
      strategyBonus +
      macroBonus +
      defenseBonus +
      scoutBonus;

  /// 경기당 비용
  double get costPerGame => price / durability;
}

/// 장비 인스턴스 (내구도 포함)
@HiveType(typeId: 7)
class EquipmentInstance {
  @HiveField(0)
  final String equipmentId;

  @HiveField(1)
  final int currentDurability;

  @HiveField(2)
  final String? equippedPlayerId;

  const EquipmentInstance({
    required this.equipmentId,
    required this.currentDurability,
    this.equippedPlayerId,
  });

  bool get isBroken => currentDurability <= 0;

  EquipmentInstance use() {
    return EquipmentInstance(
      equipmentId: equipmentId,
      currentDurability: currentDurability - 1,
      equippedPlayerId: equippedPlayerId,
    );
  }

  EquipmentInstance equip(String playerId) {
    return EquipmentInstance(
      equipmentId: equipmentId,
      currentDurability: currentDurability,
      equippedPlayerId: playerId,
    );
  }

  EquipmentInstance unequip() {
    return EquipmentInstance(
      equipmentId: equipmentId,
      currentDurability: currentDurability,
      equippedPlayerId: null,
    );
  }
}

/// 기본 장비 목록
class Equipments {
  // 마우스
  static const mickeyMouse = Equipment(
    id: 'mickey_mouse',
    name: '미키마우스',
    typeIndex: 1, // ItemType.mouse
    price: 30,
    durability: 20,
    controlBonus: 30,
    attackBonus: 15,
    harassBonus: 15,
  );

  static const mBlack = Equipment(
    id: 'm_black',
    name: 'M-BLACK',
    typeIndex: 1,
    price: 60,
    durability: 20,
    controlBonus: 60,
    attackBonus: 30,
    harassBonus: 30,
  );

  static const mSharp = Equipment(
    id: 'm_sharp',
    name: 'M-SHARP',
    typeIndex: 1,
    price: 60,
    durability: 10,
    controlBonus: 80,
    attackBonus: 60,
    harassBonus: 60,
    strategyBonus: 40,
  );

  static const mSilver = Equipment(
    id: 'm_silver',
    name: 'M-SILVER',
    typeIndex: 1,
    price: 180,
    durability: 50,
    controlBonus: 80,
    attackBonus: 60,
    harassBonus: 60,
  );

  // 키보드 (마우스와 유사한 스탯)
  static const basicKeyboard = Equipment(
    id: 'basic_keyboard',
    name: '기본 키보드',
    typeIndex: 2, // ItemType.keyboard
    price: 30,
    durability: 20,
    controlBonus: 30,
    attackBonus: 15,
    harassBonus: 15,
  );

  static const kBlack = Equipment(
    id: 'k_black',
    name: 'K-BLACK',
    typeIndex: 2,
    price: 60,
    durability: 20,
    controlBonus: 60,
    attackBonus: 30,
    harassBonus: 30,
  );

  static const kSharp = Equipment(
    id: 'k_sharp',
    name: 'K-SHARP',
    typeIndex: 2,
    price: 60,
    durability: 10,
    controlBonus: 80,
    attackBonus: 60,
    harassBonus: 60,
    strategyBonus: 40,
  );

  static const kSilver = Equipment(
    id: 'k_silver',
    name: 'K-SILVER',
    typeIndex: 2,
    price: 180,
    durability: 50,
    controlBonus: 80,
    attackBonus: 60,
    harassBonus: 60,
  );

  // 모니터
  static const crtMonitor = Equipment(
    id: 'crt_monitor',
    name: 'CRT 평면모니터',
    typeIndex: 3, // ItemType.monitor
    price: 80,
    durability: 50,
    scoutBonus: 40,
    conditionBonus: 2,
  );

  static const smallLcdMonitor = Equipment(
    id: 'small_lcd_monitor',
    name: '소형 LCD모니터',
    typeIndex: 3,
    price: 120,
    durability: 50,
    scoutBonus: 60,
    conditionBonus: 3,
  );

  static const largeLcdMonitor = Equipment(
    id: 'large_lcd_monitor',
    name: '대형 LCD모니터',
    typeIndex: 3,
    price: 150,
    durability: 50,
    scoutBonus: 80,
    conditionBonus: 4,
  );

  // 기타 악세서리
  static const hotPack = Equipment(
    id: 'hot_pack',
    name: '핫팩',
    typeIndex: 4, // ItemType.accessory
    price: 5,
    durability: 10,
    conditionBonus: 1,
  );

  static const wristGuard = Equipment(
    id: 'wrist_guard',
    name: '손목 아대',
    typeIndex: 4,
    price: 10,
    durability: 10,
    senseBonus: 20,
    controlBonus: 20,
  );

  static const shinySunglasses = Equipment(
    id: 'shiny_sunglasses',
    name: '광택 썬글라스',
    typeIndex: 4,
    price: 20,
    durability: 10,
    senseBonus: 40,
    controlBonus: 40,
  );

  static const devilPendant = Equipment(
    id: 'devil_pendant',
    name: '악마의 펜던트',
    typeIndex: 4,
    price: 40,
    durability: 20,
    senseBonus: 5,
    controlBonus: 6,
    attackBonus: 6,
    harassBonus: 6,
    strategyBonus: 6,
    macroBonus: 5,
    defenseBonus: 5,
    scoutBonus: 5,
    conditionBonus: -4, // 전체 +44, 컨디션 -4
  );

  static const starNecklace = Equipment(
    id: 'star_necklace',
    name: '별 목걸이',
    typeIndex: 4,
    price: 70,
    durability: 20,
    senseBonus: 2,
    controlBonus: 2,
    attackBonus: 2,
    harassBonus: 2,
    strategyBonus: 2,
    macroBonus: 2,
    defenseBonus: 2,
    scoutBonus: 1,
    conditionBonus: 1, // 전체 +15, 컨디션 +1
  );

  static const powerRing = Equipment(
    id: 'power_ring',
    name: '힘의 반지',
    typeIndex: 4,
    price: 100,
    durability: 20,
    attackBonus: 110,
    defenseBonus: 110,
  );

  static List<Equipment> get allMice =>
      [mickeyMouse, mBlack, mSharp, mSilver];

  static List<Equipment> get allKeyboards =>
      [basicKeyboard, kBlack, kSharp, kSilver];

  static List<Equipment> get allMonitors =>
      [crtMonitor, smallLcdMonitor, largeLcdMonitor];

  static List<Equipment> get allAccessories =>
      [hotPack, wristGuard, shinySunglasses, devilPendant, starNecklace, powerRing];

  static List<Equipment> get all => [
    ...allMice,
    ...allKeyboards,
    ...allMonitors,
    ...allAccessories,
  ];

  static Equipment? getById(String id) {
    return all.cast<Equipment?>().firstWhere(
      (e) => e?.id == id,
      orElse: () => null,
    );
  }
}

/// 플레이어 인벤토리
@HiveType(typeId: 8)
class Inventory {
  @HiveField(0)
  final Map<String, int> consumables; // itemId -> 수량

  @HiveField(1)
  final List<EquipmentInstance> equipments;

  const Inventory({
    this.consumables = const {},
    this.equipments = const [],
  });

  int getConsumableCount(String itemId) => consumables[itemId] ?? 0;

  Inventory addConsumable(String itemId, [int count = 1]) {
    final newConsumables = Map<String, int>.from(consumables);
    newConsumables[itemId] = (newConsumables[itemId] ?? 0) + count;
    return Inventory(consumables: newConsumables, equipments: equipments);
  }

  Inventory useConsumable(String itemId) {
    final currentCount = consumables[itemId] ?? 0;
    if (currentCount <= 0) return this;

    final newConsumables = Map<String, int>.from(consumables);
    newConsumables[itemId] = currentCount - 1;
    if (newConsumables[itemId] == 0) {
      newConsumables.remove(itemId);
    }
    return Inventory(consumables: newConsumables, equipments: equipments);
  }

  Inventory addEquipment(EquipmentInstance equipment) {
    return Inventory(
      consumables: consumables,
      equipments: [...equipments, equipment],
    );
  }

  Inventory removeEquipment(int index) {
    final newEquipments = List<EquipmentInstance>.from(equipments);
    newEquipments.removeAt(index);
    return Inventory(consumables: consumables, equipments: newEquipments);
  }

  Inventory updateEquipment(int index, EquipmentInstance equipment) {
    final newEquipments = List<EquipmentInstance>.from(equipments);
    newEquipments[index] = equipment;
    return Inventory(consumables: consumables, equipments: newEquipments);
  }

  /// 깨진 장비 제거
  Inventory removeBrokenEquipments() {
    return Inventory(
      consumables: consumables,
      equipments: equipments.where((e) => !e.isBroken).toList(),
    );
  }
}
