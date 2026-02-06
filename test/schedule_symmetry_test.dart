import 'dart:math';

// 일정 대칭 검증 스크립트 (독립 실행)
void main() {
  final rng = Random(42);

  // 11행(0~10) 중 7행에 경기 배치
  final rows = List.generate(11, (i) => i);
  rows.shuffle(rng);
  final matchRows = rows.take(7).toList()..sort();

  print('선택된 행: $matchRows');
  print('');

  // 1차 리그 슬롯 (홀수)
  final firstRoundSlots = matchRows.map((r) => r * 2 + 1).toList();
  // 2차 리그 슬롯 (짝수, 23 - first)
  final secondRoundSlots = firstRoundSlots.map((s) => 23 - s).toList();

  print('1차 리그 슬롯 (경기1/홀수): $firstRoundSlots');
  print('2차 리그 슬롯 (경기2/짝수): $secondRoundSlots');
  print('');

  // 표시 검증
  print('행  | 경기1(홀수) | 경기2(짝수) | 대칭');
  print('----|-------------|-------------|------');

  final allFirstSlots = firstRoundSlots.toSet();
  final allSecondSlots = secondRoundSlots.toSet();

  for (int i = 0; i < 11; i++) {
    final slot1 = i * 2 + 1;
    final slot2 = i * 2 + 2;
    final hasMatch1 = allFirstSlots.contains(slot1);
    final hasMatch2 = allSecondSlots.contains(slot2);

    // 데칼코마니 검증: 행i와 행(10-i)
    final mirrorRow = 10 - i;
    final mirrorSlot1 = mirrorRow * 2 + 1;
    final mirrorSlot2 = mirrorRow * 2 + 2;
    final mirrorHasMatch1 = allFirstSlots.contains(mirrorSlot1);
    final mirrorHasMatch2 = allSecondSlots.contains(mirrorSlot2);

    // 데칼코마니: 행i의 (경기1, 경기2) == 행(10-i)의 (경기2, 경기1)
    final isSymmetric = hasMatch1 == mirrorHasMatch2 && hasMatch2 == mirrorHasMatch1;

    final m1 = hasMatch1 ? 'MATCH' : '  —  ';
    final m2 = hasMatch2 ? 'MATCH' : '  —  ';
    final sym = isSymmetric ? '  OK' : ' FAIL';

    print(' ${i.toString().padLeft(2)} |   $m1   |   $m2   | $sym (↔행$mirrorRow)');
  }

  // 플레이 순서 검증
  print('');
  print('=== 플레이 순서 (roundNumber 순) ===');
  final allSlots = <int>{...allFirstSlots, ...allSecondSlots};
  final sortedSlots = allSlots.toList()..sort();
  for (final slot in sortedSlots) {
    final row = (slot - 1) ~/ 2;
    final col = slot.isOdd ? '경기1(1차)' : '경기2(2차)';
    print('  슬롯 ${slot.toString().padLeft(2)} → 행$row $col');
  }
}
