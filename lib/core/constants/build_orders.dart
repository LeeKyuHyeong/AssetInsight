// 빌드오더 기반 이벤트 시스템
//
// 각 빌드는 순서대로 진행되는 이벤트 단계(step)를 가짐
// 양 선수가 각자의 빌드를 독립적으로 진행하며, 특정 시점에 충돌(clash) 발생

import 'dart:math';

import '../../domain/models/enums.dart' show BuildStyle, BuildType;

export '../../domain/models/enums.dart' show BuildStyle, BuildType;

/// 빌드 단계 (순서대로 진행)
class BuildStep {
  final int line;           // 발생 라인 (기준점)
  final String text;        // 이벤트 텍스트
  final String? stat;       // 관련 능력치
  final int myArmy;         // 내 병력 변화
  final int myResource;     // 내 자원 변화
  final int enemyArmy;      // 상대 병력 변화 (견제 등)
  final int enemyResource;  // 상대 자원 변화
  final bool isClash;       // 충돌 이벤트 여부 (양측 병력 손실)
  final bool decisive;      // 결정적 이벤트 여부

  const BuildStep({
    required this.line,
    required this.text,
    this.stat,
    this.myArmy = 0,
    this.myResource = 0,
    this.enemyArmy = 0,
    this.enemyResource = 0,
    this.isClash = false,
    this.decisive = false,
  });
}

/// 빌드오더 정의
class BuildOrder {
  final String id;
  final String name;
  final String race;      // T, Z, P
  final String vsRace;    // 상대 종족
  final BuildStyle style;
  final List<BuildStep> steps;

  const BuildOrder({
    required this.id,
    required this.name,
    required this.race,
    required this.vsRace,
    required this.style,
    required this.steps,
  });
}

/// 충돌 이벤트
class ClashEvent {
  final String text;
  final int attackerArmy;     // 공격자 병력 변화
  final int defenderArmy;     // 수비자 병력 변화
  final int attackerResource; // 공격자 자원 변화
  final int defenderResource; // 수비자 자원 변화
  final bool decisive;        // 결정적 이벤트
  final String? favorsStat;   // 이 능력치가 높으면 유리

  const ClashEvent({
    required this.text,
    this.attackerArmy = 0,
    this.defenderArmy = 0,
    this.attackerResource = 0,
    this.defenderResource = 0,
    this.decisive = false,
    this.favorsStat,
  });
}

/// 빌드오더 데이터 저장소
class BuildOrderData {
  static final Random _random = Random();
  // ==================== 테란 빌드 ====================

  // TvZ 빌드들 (BuildType: tvzBunkerDefense, tvz2FactoryVulture, tvzSKTerran, tvz3FactoryGoliath, tvzWraithHarass, tvzMechDrop)
  static const terranVsZergBuilds = [
    // 1. 벙커링 수비 (tvzBunkerDefense - Defensive)
    BuildOrder(
      id: 'tvz_bunker',
      name: '벙커링',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산 시작!', myArmy: 2, myResource: -5),
        BuildStep(line: 5, text: '{player} 선수 서플라이 건설!', myResource: -8),
        BuildStep(line: 7, text: '{player} 선수 정찰 SCV 출발!', stat: 'scout'),
        BuildStep(line: 10, text: '{player} 선수 벙커 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 15, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 20, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 25, text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 30, text: '{player}, 마인 설치 완료!', stat: 'strategy', myResource: -5),
        BuildStep(line: 35, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 40, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 50, text: '{player}, 사이언스 베슬 생산!', myArmy: 2, myResource: -20),
        BuildStep(line: 60, text: '{player} 선수 3번째 멀티 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 80, text: '{player}, 탱크 골리앗 조합 완성!', stat: 'macro', myArmy: 15, myResource: -40),
        BuildStep(line: 100, text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
      ],
    ),

    // 2. 2팩 벌처 (tvz2FactoryVulture - Aggressive)
    BuildOrder(
      id: 'tvz_2fac_vulture',
      name: '2팩 벌처',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 9, text: '{player} 선수 두 번째 팩토리!', myResource: -20),
        BuildStep(line: 12, text: '{player} 선수 벌처 더블 생산!', stat: 'harass', myArmy: 6, myResource: -15),
        BuildStep(line: 15, text: '{player}, 벌처 러쉬 시작!', stat: 'harass'),
        BuildStep(line: 18, text: '{player}, 일꾼 라인 견제!', stat: 'harass', enemyResource: -30),
        BuildStep(line: 22, text: '{player} 선수 마인 업그레이드!', stat: 'strategy', myResource: -10),
        BuildStep(line: 26, text: '{player}, 마인으로 저글링 학살!', stat: 'control', enemyArmy: -12),
        BuildStep(line: 30, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 38, text: '{player}, 벌처 추가 생산!', myArmy: 6, myResource: -15),
        BuildStep(line: 45, text: '{player} 선수 상대 멀티 견제!', stat: 'harass', enemyResource: -25, isClash: true),
      ],
    ),

    // 3. SK테란 (tvzSKTerran - Balanced)
    BuildOrder(
      id: 'tvz_sk',
      name: 'SK테란',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 벌처 생산 시작!', myArmy: 4, myResource: -10),
        BuildStep(line: 14, text: '{player}, 벌처로 맵 장악!', stat: 'harass'),
        BuildStep(line: 18, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 22, text: '{player}, 일꾼 견제 성공!', stat: 'harass', enemyResource: -20),
        BuildStep(line: 28, text: '{player} 선수 마인 설치!', stat: 'strategy', myResource: -5),
        BuildStep(line: 32, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 40, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 48, text: '{player}, 드랍십으로 견제!', stat: 'harass', myArmy: 2, myResource: -15),
        BuildStep(line: 55, text: '{player} 선수 3번째 멀티 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 65, text: '{player}, 탱크 드랍 출발!', stat: 'harass', enemyResource: -25),
        BuildStep(line: 80, text: '{player} 선수 메카닉 조합 완성!', stat: 'macro', myArmy: 15, myResource: -40),
      ],
    ),

    // 4. 3팩 골리앗 (tvz3FactoryGoliath - Defensive)
    BuildOrder(
      id: 'tvz_3fac_goliath',
      name: '3팩 골리앗',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 서플라이 건설!', myResource: -8),
        BuildStep(line: 6, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 10, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 15, text: '{player} 선수 벙커 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 20, text: '{player} 선수 팩토리 추가!', myResource: -20),
        BuildStep(line: 25, text: '{player} 선수 3번째 팩토리!', myResource: -20),
        BuildStep(line: 30, text: '{player} 선수 아머리 건설!', myResource: -15),
        BuildStep(line: 35, text: '{player}, 골리앗 대량 생산!', stat: 'defense', myArmy: 8, myResource: -25),
        BuildStep(line: 45, text: '{player} 선수 골리앗 레인지 업!', stat: 'strategy', myResource: -15),
        BuildStep(line: 55, text: '{player}, 대공 진형 완성!', stat: 'defense', myArmy: 10, myResource: -30),
        BuildStep(line: 70, text: '{player} 선수 뮤탈 대비 완료!', stat: 'defense'),
        BuildStep(line: 85, text: '{player}, 골리앗 탱크 조합!', stat: 'macro', myArmy: 15, myResource: -40),
      ],
    ),

    // 5. 레이스 견제 (tvzWraithHarass - Aggressive)
    BuildOrder(
      id: 'tvz_wraith',
      name: '레이스 견제',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 벌처 생산!', myArmy: 3, myResource: -8),
        BuildStep(line: 14, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 18, text: '{player} 선수 레이스 생산!', stat: 'harass', myArmy: 4, myResource: -15),
        BuildStep(line: 22, text: '{player}, 레이스로 오버로드 사냥!', stat: 'harass', enemyArmy: -4),
        BuildStep(line: 26, text: '{player}, 서플라이 블락!', stat: 'strategy', enemyResource: -20),
        BuildStep(line: 30, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 38, text: '{player}, 레이스 추가 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 45, text: '{player}, 일꾼 라인 견제!', stat: 'harass', enemyResource: -25),
        BuildStep(line: 55, text: '{player} 선수 클로킹 연구!', stat: 'strategy', myResource: -20),
        BuildStep(line: 65, text: '{player}, 클로킹 레이스 투입!', stat: 'harass', enemyResource: -30, isClash: true),
      ],
    ),

    // 6. 메카닉 드랍 (tvzMechDrop - Balanced)
    BuildOrder(
      id: 'tvz_mech_drop',
      name: '메카닉 드랍',
      race: 'T',
      vsRace: 'Z',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 14, text: '{player}, 벌처로 맵 장악!', stat: 'harass'),
        BuildStep(line: 18, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 22, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 28, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 32, text: '{player}, 드랍십 생산!', myArmy: 2, myResource: -15),
        BuildStep(line: 38, text: '{player}, 탱크 드랍 준비!', stat: 'control'),
        BuildStep(line: 42, text: '{player}, 탱크 드랍 출발!', stat: 'harass'),
        BuildStep(line: 46, text: '{player} 선수 탱크 드랍 성공!', stat: 'control', enemyArmy: -8, enemyResource: -25),
        BuildStep(line: 55, text: '{player} 선수 추가 드랍!', stat: 'harass', enemyResource: -20),
        BuildStep(line: 65, text: '{player}, 드랍십 2대 운용!', myArmy: 3, myResource: -15),
        BuildStep(line: 80, text: '{player} 선수 멀티 드랍으로 압박!', stat: 'harass', isClash: true),
      ],
    ),
  ];

  // TvP 빌드들 (BuildType: tvpDouble, tvpFakeDouble, tvp1FactDrop, tvp1FactGosu, tvpWraithRush)
  static const terranVsProtossBuilds = [
    // 1. 더블 커맨드 (tvpDouble - Defensive)
    BuildOrder(
      id: 'tvp_double',
      name: '더블 커맨드',
      race: 'T',
      vsRace: 'P',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 5, text: '{player} 선수 서플라이 건설!', myResource: -8),
        BuildStep(line: 8, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 16, text: '{player} 선수 벙커 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 20, text: '{player}, 마린 추가 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 26, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 32, text: '{player}, 탱크 라인 전개!', stat: 'defense'),
        BuildStep(line: 40, text: '{player} 선수 팩토리 추가!', myResource: -20),
        BuildStep(line: 50, text: '{player}, 3번째 멀티 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 65, text: '{player} 선수 골리앗 대량 생산!', myArmy: 10, myResource: -30),
        BuildStep(line: 80, text: '{player}, 탱크 골리앗 조합 완성!', stat: 'macro', myArmy: 15, myResource: -40),
      ],
    ),

    // 2. 페이크 더블 (tvpFakeDouble - Aggressive)
    BuildOrder(
      id: 'tvp_fake_double',
      name: '페이크 더블',
      race: 'T',
      vsRace: 'P',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 앞마당 커맨드 내립니다!', stat: 'strategy', myResource: -20),
        BuildStep(line: 8, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 11, text: '{player}, 앞마당 취소! 페이크였습니다!', stat: 'sense', myResource: 15),
        BuildStep(line: 14, text: '{player} 선수 시즈탱크 생산!', stat: 'attack', myArmy: 5, myResource: -15),
        BuildStep(line: 18, text: '{player}, 시즈모드 연구!', myResource: -15),
        BuildStep(line: 22, text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 26, text: '{player}, 페이크 더블 푸시 시작!', stat: 'attack'),
        BuildStep(line: 30, text: '{player}, 상대 앞마당 압박!', stat: 'attack', isClash: true),
        BuildStep(line: 38, text: '{player} 선수 탱크 추가 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 45, text: '{player}, 결정적인 푸시!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),

    // 3. 원팩 드랍 (tvp1FactDrop - Balanced)
    BuildOrder(
      id: 'tvp_1fac_drop',
      name: '원팩 드랍',
      race: 'T',
      vsRace: 'P',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 14, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 18, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 22, text: '{player}, 드랍십 생산!', stat: 'harass', myArmy: 2, myResource: -15),
        BuildStep(line: 26, text: '{player}, 탱크 드랍 준비!', stat: 'control'),
        BuildStep(line: 30, text: '{player}, 탱크 드랍 출발!', stat: 'harass'),
        BuildStep(line: 34, text: '{player} 선수 드랍 성공!', stat: 'control', enemyArmy: -6, enemyResource: -20),
        BuildStep(line: 42, text: '{player}, 추가 드랍!', stat: 'harass', enemyResource: -15),
        BuildStep(line: 50, text: '{player} 선수 지상군 푸시!', stat: 'attack', myArmy: 8, myResource: -25),
        BuildStep(line: 60, text: '{player}, 멀티 드랍으로 압박!', stat: 'harass', isClash: true),
      ],
    ),

    // 4. 원팩 고수 (tvp1FactGosu - Defensive)
    BuildOrder(
      id: 'tvp_1fac_gosu',
      name: '원팩 고수',
      race: 'T',
      vsRace: 'P',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 14, text: '{player}, 시즈모드 연구!', stat: 'defense', myResource: -15),
        BuildStep(line: 18, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 24, text: '{player}, 탱크 라인 전개!', stat: 'strategy'),
        BuildStep(line: 30, text: '{player} 선수 고수 테크!', stat: 'strategy', myResource: -20),
        BuildStep(line: 38, text: '{player}, 탱크 추가 생산!', myArmy: 6, myResource: -20),
        BuildStep(line: 46, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 54, text: '{player}, 사이언스 베슬 생산!', myArmy: 2, myResource: -20),
        BuildStep(line: 65, text: '{player} 선수 EMP 연구!', stat: 'strategy', myResource: -20),
        BuildStep(line: 75, text: '{player}, EMP로 하이템플러 무력화!', stat: 'strategy', enemyArmy: -5),
        BuildStep(line: 85, text: '{player} 선수 최종 푸시!', stat: 'attack', isClash: true),
      ],
    ),

    // 5. 레이스 난사 (tvpWraithRush - Cheese)
    BuildOrder(
      id: 'tvp_wraith_rush',
      name: '레이스 난사',
      race: 'T',
      vsRace: 'P',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 1, myResource: -3),
        BuildStep(line: 5, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 8, text: '{player} 선수 스타포트 건설!', stat: 'attack', myResource: -25),
        BuildStep(line: 12, text: '{player} 선수 레이스 생산!', stat: 'harass', myArmy: 4, myResource: -15),
        BuildStep(line: 15, text: '{player}, 레이스 난사 시작!', stat: 'attack'),
        BuildStep(line: 18, text: '{player}, 프로브 학살!', stat: 'harass', enemyResource: -30),
        BuildStep(line: 22, text: '{player}, 레이스 추가 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 26, text: '{player} 선수 클로킹 연구!', stat: 'strategy', myResource: -20),
        BuildStep(line: 30, text: '{player}, 클로킹 레이스 투입!', stat: 'harass', enemyResource: -25, enemyArmy: -3),
        BuildStep(line: 35, text: '{player}, 상대 경제 초토화!', stat: 'attack', enemyResource: -35, isClash: true, decisive: true),
      ],
    ),
  ];

  // TvT 빌드들 (BuildType: tvt1FactPush, tvtProxy, tvt2Barracks, tvt2Factory, tvtWraithCloak)
  static const terranVsTerranBuilds = [
    // 1. 원팩 선공 (tvt1FactPush - Aggressive)
    BuildOrder(
      id: 'tvt_1fac_push',
      name: '원팩 선공',
      race: 'T',
      vsRace: 'T',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 시즈탱크 생산!', stat: 'attack', myArmy: 5, myResource: -15),
        BuildStep(line: 14, text: '{player}, 시즈모드 연구!', myResource: -15),
        BuildStep(line: 18, text: '{player}, 빠른 푸시 준비!', stat: 'attack'),
        BuildStep(line: 22, text: '{player} 선수 벌처 생산!', myArmy: 3, myResource: -8),
        BuildStep(line: 26, text: '{player}, 원팩 푸시 시작!', stat: 'attack'),
        BuildStep(line: 30, text: '{player}, 고지대 점령!', stat: 'control', isClash: true),
        BuildStep(line: 38, text: '{player}, 탱크 추가 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 45, text: '{player} 선수 탱크 라인 전진!', stat: 'attack', isClash: true),
      ],
    ),

    // 2. 프록시 배럭 (tvtProxy - Cheese)
    BuildOrder(
      id: 'tvt_proxy',
      name: '프록시 배럭',
      race: 'T',
      vsRace: 'T',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 SCV 출발!', stat: 'sense'),
        BuildStep(line: 3, text: '{player}, 프록시 배럭 건설!', stat: 'attack', myResource: -10),
        BuildStep(line: 6, text: '{player} 선수 마린 생산!', myArmy: 3, myResource: -8),
        BuildStep(line: 9, text: '{player}, 마린 러쉬!', stat: 'attack'),
        BuildStep(line: 12, text: '{player}, SCV 견제!', stat: 'attack', enemyResource: -20, isClash: true),
        BuildStep(line: 16, text: '{player}, 마린 추가 투입!', myArmy: 4, myResource: -10),
        BuildStep(line: 20, text: '{player} 선수 프록시 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),

    // 3. 투배럭 (tvt2Barracks - Defensive)
    BuildOrder(
      id: 'tvt_2rax',
      name: '투배럭',
      race: 'T',
      vsRace: 'T',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 5, text: '{player} 선수 2번째 배럭!', myResource: -10),
        BuildStep(line: 8, text: '{player}, 마린 더블 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 12, text: '{player} 선수 벙커 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 16, text: '{player}, 프록시 방어 태세!', stat: 'defense'),
        BuildStep(line: 20, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 26, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 32, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 40, text: '{player}, 탱크 라인 전개!', stat: 'defense'),
        BuildStep(line: 50, text: '{player} 선수 안정적인 운영!', stat: 'macro', myArmy: 8, myResource: -25),
      ],
    ),

    // 4. 투팩 (tvt2Factory - Balanced)
    BuildOrder(
      id: 'tvt_2fac',
      name: '투팩',
      race: 'T',
      vsRace: 'T',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 3, text: '{player} 선수 마린 생산!', myArmy: 2, myResource: -5),
        BuildStep(line: 6, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 10, text: '{player} 선수 2번째 팩토리!', stat: 'macro', myResource: -20),
        BuildStep(line: 14, text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
        BuildStep(line: 18, text: '{player}, 탱크 더블 생산!', stat: 'strategy', myArmy: 5, myResource: -15),
        BuildStep(line: 22, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 28, text: '{player}, 고지대 점령!', stat: 'strategy'),
        BuildStep(line: 35, text: '{player}, 시즈 라인 전개!', stat: 'strategy'),
        BuildStep(line: 45, text: '{player} 선수 스타포트 건설!', myResource: -25),
        BuildStep(line: 55, text: '{player}, 레이스 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 65, text: '{player} 선수 탱크 라인 확장!', stat: 'macro', myArmy: 10, myResource: -35),
        BuildStep(line: 80, text: '{player}, 대규모 탱크전!', stat: 'control', isClash: true),
      ],
    ),

    // 5. 클로킹 레이스 (tvtWraithCloak - Aggressive)
    BuildOrder(
      id: 'tvt_wraith_cloak',
      name: '클로킹 레이스',
      race: 'T',
      vsRace: 'T',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 배럭 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 팩토리 건설!', myResource: -20),
        BuildStep(line: 8, text: '{player} 선수 스타포트 건설!', stat: 'harass', myResource: -25),
        BuildStep(line: 12, text: '{player} 선수 레이스 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 15, text: '{player}, 레이스로 SCV 견제!', stat: 'harass', enemyResource: -25),
        BuildStep(line: 19, text: '{player} 선수 클로킹 연구!', stat: 'strategy', myResource: -20),
        BuildStep(line: 24, text: '{player}, 클로킹 레이스 투입!', stat: 'harass', enemyResource: -30),
        BuildStep(line: 28, text: '{player}, 레이스 추가 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 34, text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 40, text: '{player}, 상대 탱크 라인 견제!', stat: 'harass', enemyArmy: -5),
        BuildStep(line: 50, text: '{player} 선수 시즈탱크 생산!', myArmy: 6, myResource: -20),
        BuildStep(line: 60, text: '{player}, 레이스 탱크 조합!', stat: 'strategy', myArmy: 8, myResource: -25, isClash: true),
      ],
    ),
  ];

  // ==================== 저그 빌드 ====================

  // ZvT 빌드들 (BuildType: zvt3HatchMutal, zvt2HatchMutal, zvt2HatchLurker, zvtHatchSpore, zvt1HatchAllIn)
  static const zergVsTerranBuilds = [
    // 1. 3해처리 뮤탈 (zvt3HatchMutal - Aggressive)
    BuildOrder(
      id: 'zvt_3hatch_mutal',
      name: '3해처리 뮤탈',
      race: 'Z',
      vsRace: 'T',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
        BuildStep(line: 16, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 20, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 26, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 32, text: '{player} 선수 뮤탈리스크 생산!', stat: 'harass', myArmy: 8, myResource: -20),
        BuildStep(line: 36, text: '{player}, 뮤탈로 일꾼 견제!', stat: 'harass', enemyResource: -30),
        BuildStep(line: 40, text: '{player} 선수 뮤탈 매직!', stat: 'control', enemyArmy: -10),
        BuildStep(line: 48, text: '{player}, 추가 뮤탈 생산!', myArmy: 6, myResource: -15),
        BuildStep(line: 55, text: '{player}, 뮤탈로 드랍십 격추!', stat: 'control', enemyArmy: -8),
        BuildStep(line: 65, text: '{player} 선수 4번째 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 80, text: '{player}, 뮤탈 물량 압도!', stat: 'harass', myArmy: 10, myResource: -25, isClash: true),
      ],
    ),

    // 2. 투해처리 뮤탈 (zvt2HatchMutal - Balanced)
    BuildOrder(
      id: 'zvt_2hatch_mutal',
      name: '투해처리 뮤탈',
      race: 'Z',
      vsRace: 'T',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player} 선수 저글링 생산!', myArmy: 4, myResource: -5),
        BuildStep(line: 16, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 22, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 28, text: '{player} 선수 뮤탈리스크 생산!', stat: 'harass', myArmy: 6, myResource: -15),
        BuildStep(line: 32, text: '{player}, 뮤탈로 견제!', stat: 'harass', enemyResource: -25),
        BuildStep(line: 38, text: '{player} 선수 3해처리 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 45, text: '{player}, 뮤탈 매직!', stat: 'control', enemyArmy: -8),
        BuildStep(line: 55, text: '{player} 선수 히드라덴 건설!', myResource: -15),
        BuildStep(line: 65, text: '{player}, 럴커 변태!', stat: 'strategy', myArmy: 5, myResource: -15),
        BuildStep(line: 75, text: '{player} 선수 뮤탈 럴커 조합!', stat: 'macro', myArmy: 10, myResource: -30),
      ],
    ),

    // 3. 투해처리 럴커 (zvt2HatchLurker - Defensive)
    BuildOrder(
      id: 'zvt_2hatch_lurker',
      name: '투해처리 럴커',
      race: 'Z',
      vsRace: 'T',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 16, text: '{player} 선수 히드라덴 건설!', myResource: -15),
        BuildStep(line: 20, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 26, text: '{player} 선수 히드라리스크 생산!', myArmy: 6, myResource: -15),
        BuildStep(line: 32, text: '{player}, 럴커 변태!', stat: 'defense', myArmy: 4, myResource: -15),
        BuildStep(line: 38, text: '{player} 선수 럴커 포진!', stat: 'defense'),
        BuildStep(line: 45, text: '{player}, 럴커 홀드!', stat: 'defense', enemyArmy: -12),
        BuildStep(line: 55, text: '{player} 선수 3해처리 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 65, text: '{player}, 럴커 추가 변태!', stat: 'strategy', myArmy: 4, myResource: -15),
        BuildStep(line: 80, text: '{player} 선수 디파일러 생산!', myArmy: 3, myResource: -15),
      ],
    ),

    // 4. 해처리 스포어 (zvtHatchSpore - Defensive)
    BuildOrder(
      id: 'zvt_hatch_spore',
      name: '해처리 스포',
      race: 'Z',
      vsRace: 'T',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player} 선수 저글링 생산!', myArmy: 4, myResource: -5),
        BuildStep(line: 16, text: '{player}, 스포어 콜로니 건설!', stat: 'defense', myResource: -10),
        BuildStep(line: 20, text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
        BuildStep(line: 26, text: '{player} 선수 히드라덴 건설!', myResource: -15),
        BuildStep(line: 32, text: '{player} 선수 히드라리스크 생산!', myArmy: 8, myResource: -20),
        BuildStep(line: 40, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 50, text: '{player}, 럴커 변태!', stat: 'strategy', myArmy: 5, myResource: -15),
        BuildStep(line: 60, text: '{player} 선수 4번째 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 75, text: '{player} 선수 하이브 건설!', myResource: -25),
        BuildStep(line: 90, text: '{player}, 디파일러 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
      ],
    ),

    // 5. 원해처리 올인 (zvt1HatchAllIn - Cheese)
    BuildOrder(
      id: 'zvt_1hatch_allin',
      name: '원해처리 올인',
      race: 'Z',
      vsRace: 'T',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 스포닝풀 건설!', stat: 'attack', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 저글링 생산 시작!', myArmy: 6, myResource: -8),
        BuildStep(line: 7, text: '{player}, 저글링 러쉬!', stat: 'attack'),
        BuildStep(line: 10, text: '{player}, 상대 본진 진입!', stat: 'attack', isClash: true),
        BuildStep(line: 14, text: '{player}, 저글링 추가 투입!', stat: 'control', myArmy: 8, myResource: -10),
        BuildStep(line: 18, text: '{player} 선수 올인 공격!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),
  ];

  // ZvP 빌드들 (BuildType: zvp3HatchHydra, zvp2HatchMutal, zvpScourgeDefiler, zvp5DroneZergling)
  static const zergVsProtossBuilds = [
    // 1. 3해처리 히드라 (zvp3HatchHydra - Balanced)
    BuildOrder(
      id: 'zvp_3hatch_hydra',
      name: '3해처리 히드라',
      race: 'Z',
      vsRace: 'P',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
        BuildStep(line: 16, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 20, text: '{player} 선수 히드라덴 건설!', myResource: -15),
        BuildStep(line: 26, text: '{player} 선수 히드라리스크 생산!', stat: 'defense', myArmy: 8, myResource: -20),
        BuildStep(line: 32, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 40, text: '{player}, 럴커 변태!', stat: 'defense', myArmy: 5, myResource: -15),
        BuildStep(line: 48, text: '{player}, 럴커로 질럿 학살!', stat: 'defense', enemyArmy: -15),
        BuildStep(line: 58, text: '{player} 선수 4번째 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 70, text: '{player} 선수 럴커 포진 완료!', stat: 'strategy'),
        BuildStep(line: 85, text: '{player}, 히드라 럴커 물량!', stat: 'macro', myArmy: 12, myResource: -35),
      ],
    ),

    // 2. 투해처리 뮤탈 (zvp2HatchMutal - Aggressive)
    BuildOrder(
      id: 'zvp_2hatch_mutal',
      name: '투해처리 뮤탈',
      race: 'Z',
      vsRace: 'P',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player} 선수 저글링 생산!', myArmy: 4, myResource: -5),
        BuildStep(line: 16, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 22, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 28, text: '{player} 선수 뮤탈리스크 생산!', stat: 'harass', myArmy: 6, myResource: -15),
        BuildStep(line: 32, text: '{player}, 뮤탈로 프로브 견제!', stat: 'harass', enemyResource: -30),
        BuildStep(line: 38, text: '{player}, 커세어 대응!', stat: 'control'),
        BuildStep(line: 45, text: '{player} 선수 뮤탈 추가 생산!', myArmy: 6, myResource: -15),
        BuildStep(line: 52, text: '{player}, 뮤탈 매직!', stat: 'control', enemyArmy: -8),
        BuildStep(line: 60, text: '{player} 선수 히드라 추가!', myArmy: 8, myResource: -20),
        BuildStep(line: 70, text: '{player}, 뮤탈 히드라 콤비네이션!', stat: 'attack', isClash: true),
      ],
    ),

    // 3. 스커지 디파일러 (zvpScourgeDefiler - Defensive)
    BuildOrder(
      id: 'zvp_scourge_defiler',
      name: '스커지 디파일러',
      race: 'Z',
      vsRace: 'P',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 해처리 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 12, text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
        BuildStep(line: 16, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 20, text: '{player} 선수 히드라덴 건설!', myResource: -15),
        BuildStep(line: 26, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 32, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 38, text: '{player}, 스커지 생산!', stat: 'strategy', myArmy: 4, myResource: -10),
        BuildStep(line: 42, text: '{player}, 스커지로 커세어 처리!', stat: 'defense', enemyArmy: -8),
        BuildStep(line: 50, text: '{player} 선수 4번째 확장!', stat: 'macro', myResource: -30),
        BuildStep(line: 60, text: '{player} 선수 하이브 건설!', myResource: -25),
        BuildStep(line: 70, text: '{player} 선수 디파일러 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
        BuildStep(line: 80, text: '{player}, 다크스웜 전개!', stat: 'strategy', enemyArmy: -5),
        BuildStep(line: 90, text: '{player}, 플레이그 투하!', stat: 'strategy', enemyArmy: -15),
      ],
    ),

    // 4. 5드론 저글링 (zvp5DroneZergling - Cheese)
    BuildOrder(
      id: 'zvp_5drone',
      name: '5드론 저글링',
      race: 'Z',
      vsRace: 'P',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 5드론에서 풀!', stat: 'sense', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 저글링 생산 시작!', stat: 'attack', myArmy: 6, myResource: -8),
        BuildStep(line: 7, text: '{player}, 저글링 러쉬!', stat: 'attack'),
        BuildStep(line: 10, text: '{player}, 프로브 라인 공격!', stat: 'attack', enemyResource: -25, isClash: true),
        BuildStep(line: 14, text: '{player}, 저글링 추가 투입!', myArmy: 6, myResource: -8),
        BuildStep(line: 18, text: '{player} 선수 올인 공격!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),
  ];

  // ZvZ 빌드들 (BuildType: zvzPoolFirst, zvz9Pool, zvz12Hatch, zvzOverPool, zvzExtractor)
  static const zergVsZergBuilds = [
    // 1. 선풀 (zvzPoolFirst - Aggressive)
    BuildOrder(
      id: 'zvz_pool_first',
      name: '선풀',
      race: 'Z',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 스포닝풀 건설!', stat: 'attack', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 저글링 생산 시작!', myArmy: 6, myResource: -8),
        BuildStep(line: 7, text: '{player}, 저글링 러쉬!', stat: 'attack'),
        BuildStep(line: 10, text: '{player}, 저글링 싸움 시작!', stat: 'control', isClash: true),
        BuildStep(line: 16, text: '{player}, 저글링 추가 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 22, text: '{player} 선수 해처리 건설!', stat: 'macro', myResource: -30),
        BuildStep(line: 30, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 38, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 46, text: '{player} 선수 뮤탈리스크 생산!', stat: 'control', myArmy: 6, myResource: -15),
        BuildStep(line: 55, text: '{player}, 뮤탈 싸움!', stat: 'control', isClash: true),
      ],
    ),

    // 2. 9풀 (zvz9Pool - Aggressive)
    BuildOrder(
      id: 'zvz_9pool',
      name: '9풀',
      race: 'Z',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 드론 생산!', myResource: 5),
        BuildStep(line: 3, text: '{player} 선수 9드론에 풀!', stat: 'attack', myResource: -15),
        BuildStep(line: 6, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 10, text: '{player}, 선링 공격!', stat: 'attack'),
        BuildStep(line: 14, text: '{player}, 저글링 싸움!', stat: 'control', isClash: true),
        BuildStep(line: 20, text: '{player} 선수 앞마당 해처리!', stat: 'macro', myResource: -30),
        BuildStep(line: 28, text: '{player}, 저글링 추가!', myArmy: 6, myResource: -8),
        BuildStep(line: 35, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 44, text: '{player} 선수 뮤탈리스크 생산!', stat: 'control', myArmy: 6, myResource: -15),
      ],
    ),

    // 3. 12해처리 (zvz12Hatch - Defensive)
    BuildOrder(
      id: 'zvz_12hatch',
      name: '12해처리',
      race: 'Z',
      vsRace: 'Z',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 드론 생산!', stat: 'macro', myResource: 8),
        BuildStep(line: 4, text: '{player} 선수 12드론에 해처리!', stat: 'macro', myResource: -30),
        BuildStep(line: 7, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 12, text: '{player} 선수 저글링 생산!', myArmy: 4, myResource: -5),
        BuildStep(line: 16, text: '{player}, 선링 방어!', stat: 'defense', isClash: true),
        BuildStep(line: 22, text: '{player}, 저글링 추가!', myArmy: 6, myResource: -8),
        BuildStep(line: 28, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 36, text: '{player} 선수 스파이어 건설!', myResource: -25),
        BuildStep(line: 44, text: '{player} 선수 뮤탈리스크 생산!', stat: 'control', myArmy: 8, myResource: -20),
        BuildStep(line: 52, text: '{player}, 뮤탈 물량 우세!', stat: 'macro', myArmy: 6, myResource: -15),
      ],
    ),

    // 4. 오버풀 (zvzOverPool - Balanced)
    BuildOrder(
      id: 'zvz_overpool',
      name: '오버풀',
      race: 'Z',
      vsRace: 'Z',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 오버로드 생산!', myResource: -5),
        BuildStep(line: 4, text: '{player} 선수 스포닝풀 건설!', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 12, text: '{player}, 오버풀 타이밍!', stat: 'control'),
        BuildStep(line: 16, text: '{player}, 저글링 싸움!', stat: 'control', isClash: true),
        BuildStep(line: 22, text: '{player} 선수 앞마당 해처리!', stat: 'macro', myResource: -30),
        BuildStep(line: 30, text: '{player}, 저글링 추가!', myArmy: 6, myResource: -8),
        BuildStep(line: 38, text: '{player} 선수 레어 건설!', myResource: -20),
        BuildStep(line: 46, text: '{player} 선수 뮤탈리스크 생산!', stat: 'control', myArmy: 6, myResource: -15),
        BuildStep(line: 55, text: '{player}, 뮤탈 싸움!', stat: 'control', isClash: true),
      ],
    ),

    // 5. 익스트랙터 트릭 (zvzExtractor - Cheese)
    BuildOrder(
      id: 'zvz_extractor',
      name: '익스트랙터 트릭',
      race: 'Z',
      vsRace: 'Z',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 익스트랙터 건설!', stat: 'sense', myResource: -5),
        BuildStep(line: 2, text: '{player}, 드론 생산 후 취소!', myResource: 3),
        BuildStep(line: 4, text: '{player} 선수 4풀!', stat: 'attack', myResource: -15),
        BuildStep(line: 7, text: '{player} 선수 저글링 생산!', myArmy: 6, myResource: -8),
        BuildStep(line: 10, text: '{player}, 초반 올인!', stat: 'attack'),
        BuildStep(line: 13, text: '{player}, 상대 드론 공격!', stat: 'attack', enemyResource: -20, isClash: true),
        BuildStep(line: 17, text: '{player}, 저글링 추가!', myArmy: 6, myResource: -8),
        BuildStep(line: 22, text: '{player} 선수 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),
  ];

  // ==================== 프로토스 빌드 ====================

  // PvT 빌드들 (BuildType: pvt2GateZealot, pvtDarkSwing, pvt1GateObserver, pvtProxyDark)
  static const protossVsTerranBuilds = [
    // 1. 투게이트 질럿 (pvt2GateZealot - Aggressive)
    BuildOrder(
      id: 'pvt_2gate_zealot',
      name: '투게이트 질럿',
      race: 'P',
      vsRace: 'T',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 2번째 게이트웨이!', stat: 'attack', myResource: -15),
        BuildStep(line: 7, text: '{player} 선수 질럿 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 10, text: '{player}, 질럿 푸시!', stat: 'attack'),
        BuildStep(line: 14, text: '{player}, 상대 본진 압박!', stat: 'attack', isClash: true),
        BuildStep(line: 18, text: '{player}, 질럿 추가 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 22, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 28, text: '{player} 선수 드라군 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 34, text: '{player}, 드라군 사거리!', stat: 'strategy', myResource: -15),
        BuildStep(line: 42, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 50, text: '{player}, 지상군 푸시!', stat: 'attack', isClash: true),
      ],
    ),

    // 2. 다크 스윙 (pvtDarkSwing - Cheese)
    BuildOrder(
      id: 'pvt_dark_swing',
      name: '다크 스윙',
      race: 'P',
      vsRace: 'T',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 9, text: '{player} 선수 시타델 건설!', stat: 'strategy', myResource: -15),
        BuildStep(line: 14, text: '{player} 선수 템플러 아카이브!', myResource: -20),
        BuildStep(line: 20, text: '{player}, 다크템플러 생산!', stat: 'harass', myArmy: 3, myResource: -15),
        BuildStep(line: 25, text: '{player}, 다크 스윙!', stat: 'strategy'),
        BuildStep(line: 28, text: '{player}, 다크로 일꾼 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -40),
        BuildStep(line: 34, text: '{player}, 다크 추가 투입!', myArmy: 2, myResource: -10),
        BuildStep(line: 40, text: '{player} 선수 다크 공습!', stat: 'harass', enemyResource: -30, isClash: true, decisive: true),
      ],
    ),

    // 3. 원게이트 옵저버 (pvt1GateObserver - Defensive)
    BuildOrder(
      id: 'pvt_1gate_obs',
      name: '원게이트 옵저버',
      race: 'P',
      vsRace: 'T',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 10, text: '{player} 선수 드라군 생산!', myArmy: 3, myResource: -10),
        BuildStep(line: 14, text: '{player} 선수 로보틱스 건설!', stat: 'defense', myResource: -20),
        BuildStep(line: 18, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 24, text: '{player} 선수 옵저버 생산!', stat: 'strategy', myArmy: 1, myResource: -10),
        BuildStep(line: 30, text: '{player}, 상대 빌드 정찰!', stat: 'scout'),
        BuildStep(line: 36, text: '{player} 선수 드라군 추가!', myArmy: 6, myResource: -18),
        BuildStep(line: 44, text: '{player}, 드라군 사거리!', stat: 'strategy', myResource: -15),
        BuildStep(line: 52, text: '{player} 선수 템플러 아카이브!', myResource: -20),
        BuildStep(line: 62, text: '{player}, 하이템플러 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
        BuildStep(line: 72, text: '{player}, 스톰 연구!', stat: 'strategy', myResource: -15),
        BuildStep(line: 85, text: '{player}, 사이오닉 스톰!', stat: 'strategy', enemyArmy: -20, isClash: true),
      ],
    ),

    // 4. 프록시 다크 (pvtProxyDark - Cheese)
    BuildOrder(
      id: 'pvt_proxy_dark',
      name: '프록시 다크',
      race: 'P',
      vsRace: 'T',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 프로브 출발!', stat: 'sense'),
        BuildStep(line: 3, text: '{player}, 프록시 게이트웨이!', stat: 'attack', myResource: -15),
        BuildStep(line: 7, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 11, text: '{player} 선수 프록시 시타델!', stat: 'sense', myResource: -15),
        BuildStep(line: 16, text: '{player} 선수 템플러 아카이브!', myResource: -20),
        BuildStep(line: 22, text: '{player}, 다크템플러 생산!', stat: 'attack', myArmy: 2, myResource: -10),
        BuildStep(line: 26, text: '{player}, 다크 투입!', stat: 'attack'),
        BuildStep(line: 28, text: '{player} 선수 SCV 학살!', stat: 'harass', enemyArmy: -3, enemyResource: -35, isClash: true),
        BuildStep(line: 34, text: '{player}, 다크 추가!', myArmy: 2, myResource: -10),
        BuildStep(line: 40, text: '{player} 선수 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),

    // 5. 원게이트 확장 (pvt1GateExpansion - Balanced)
    BuildOrder(
      id: 'pvt_1gate_expand',
      name: '원게이트 확장',
      race: 'P',
      vsRace: 'T',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 사이버네틱스 코어 올립니다.', stat: 'macro', myResource: -10),
        BuildStep(line: 7, text: '{player}, 드라군 생산!', stat: 'control', myArmy: 3, myResource: -10),
        BuildStep(line: 10, text: '{player} 선수 넥서스 확장합니다.', stat: 'macro', myResource: -25),
        BuildStep(line: 14, text: '{player}, 드라군 추가 생산!', myArmy: 3, myResource: -10),
        BuildStep(line: 18, text: '{player} 선수 로보틱스 퍼실리티!', stat: 'strategy', myResource: -15),
        BuildStep(line: 22, text: '{player}, 옵저버 생산 시작!', stat: 'scout', myResource: -5),
        BuildStep(line: 26, text: '{player} 선수 사거리 업그레이드!', stat: 'strategy', myResource: -10),
        BuildStep(line: 30, text: '{player}, 리버 생산!', stat: 'harass', myArmy: 2, myResource: -15),
        BuildStep(line: 35, text: '{player} 선수 리버 드랍 나갑니다!', stat: 'harass', isClash: true),
        BuildStep(line: 40, text: '{player}, 아비터 테크!', stat: 'strategy', myResource: -20),
        BuildStep(line: 50, text: '{player} 선수 병력 모아서 푸시!', stat: 'attack', myArmy: 5, isClash: true),
      ],
    ),
  ];

  // PvZ 빌드들 (BuildType: pvz2GateZealot, pvzForgeCannon, pvzNexusFirst, pvzCorsairReaver, pvzProxyGateway)
  static const protossVsZergBuilds = [
    // 1. 투게이트 질럿 (pvz2GateZealot - Aggressive)
    BuildOrder(
      id: 'pvz_2gate_zealot',
      name: '투게이트 질럿',
      race: 'P',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 4, text: '{player} 선수 2번째 게이트웨이!', stat: 'attack', myResource: -15),
        BuildStep(line: 7, text: '{player} 선수 질럿 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 10, text: '{player}, 질럿 푸시!', stat: 'attack'),
        BuildStep(line: 14, text: '{player}, 앞마당 압박!', stat: 'attack', isClash: true),
        BuildStep(line: 18, text: '{player}, 질럿 추가 생산!', myArmy: 4, myResource: -10),
        BuildStep(line: 22, text: '{player}, 드론 사냥!', stat: 'control', enemyResource: -25),
        BuildStep(line: 28, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 34, text: '{player} 선수 드라군 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 42, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 50, text: '{player}, 지상군 푸시!', stat: 'attack', isClash: true),
      ],
    ),

    // 2. 포지 캐논 (pvzForgeCannon - Defensive)
    BuildOrder(
      id: 'pvz_forge_cannon',
      name: '포지 캐논',
      race: 'P',
      vsRace: 'Z',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 넥서스 건설합니다.', myResource: -10),
        BuildStep(line: 4, text: '{player} 선수 포지 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 8, text: '{player} 선수 포톤캐논 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 12, text: '{player}, 저글링 러쉬 방어!', stat: 'defense', myArmy: -2, enemyArmy: -8),
        BuildStep(line: 16, text: '{player} 선수 게이트웨이 건설!', myResource: -15),
        BuildStep(line: 20, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 26, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 32, text: '{player} 선수 드라군 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 40, text: '{player}, 드라군 사거리!', stat: 'strategy', myResource: -15),
        BuildStep(line: 50, text: '{player} 선수 스타게이트 건설!', myResource: -25),
        BuildStep(line: 58, text: '{player}, 커세어 생산!', stat: 'harass', myArmy: 4, myResource: -15),
        BuildStep(line: 68, text: '{player}, 커세어로 오버로드 사냥!', stat: 'harass', enemyArmy: -5),
        BuildStep(line: 80, text: '{player} 선수 안정적인 운영!', stat: 'macro', myArmy: 10, myResource: -30),
      ],
    ),

    // 3. 넥서스 퍼스트 (pvzNexusFirst - Defensive)
    BuildOrder(
      id: 'pvz_nexus_first',
      name: '넥서스 퍼스트',
      race: 'P',
      vsRace: 'Z',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 넥서스 건설합니다!', stat: 'sense', myResource: -40),
        BuildStep(line: 5, text: '{player} 선수 게이트웨이 건설!', myResource: -15),
        BuildStep(line: 9, text: '{player} 선수 포지 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 13, text: '{player} 선수 캐논 건설!', stat: 'defense', myResource: -15),
        BuildStep(line: 17, text: '{player}, 러쉬 방어!', stat: 'defense', isClash: true),
        BuildStep(line: 22, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 28, text: '{player} 선수 드라군 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 36, text: '{player}, 드라군 사거리!', stat: 'strategy', myResource: -15),
        BuildStep(line: 44, text: '{player} 선수 스타게이트 건설!', myResource: -25),
        BuildStep(line: 52, text: '{player}, 커세어 생산!', stat: 'harass', myArmy: 4, myResource: -15),
        BuildStep(line: 62, text: '{player} 선수 3번째 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 75, text: '{player}, 경제력 우세!', stat: 'macro', myArmy: 12, myResource: -35),
      ],
    ),

    // 4. 커세어 리버 (pvzCorsairReaver - Aggressive)
    BuildOrder(
      id: 'pvz_corsair_reaver',
      name: '커세어 리버',
      race: 'P',
      vsRace: 'Z',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 10, text: '{player} 선수 스타게이트 건설!', stat: 'harass', myResource: -25),
        BuildStep(line: 15, text: '{player} 선수 커세어 생산!', myArmy: 4, myResource: -15),
        BuildStep(line: 18, text: '{player}, 커세어로 오버로드 사냥!', stat: 'harass', enemyArmy: -4),
        BuildStep(line: 22, text: '{player}, 서플라이 블락!', stat: 'strategy', enemyResource: -15),
        BuildStep(line: 26, text: '{player} 선수 로보틱스 건설!', myResource: -20),
        BuildStep(line: 32, text: '{player} 선수 리버 생산!', stat: 'harass', myArmy: 5, myResource: -20),
        BuildStep(line: 36, text: '{player}, 셔틀 생산!', myArmy: 1, myResource: -10),
        BuildStep(line: 40, text: '{player}, 리버 드랍 출발!', stat: 'harass'),
        BuildStep(line: 44, text: '{player} 선수 리버 드랍 성공!', stat: 'control', enemyArmy: -10, enemyResource: -35),
        BuildStep(line: 52, text: '{player}, 리버 추가 생산!', myArmy: 3, myResource: -15),
        BuildStep(line: 60, text: '{player}, 멀티 드랍!', stat: 'harass', enemyResource: -25, isClash: true),
      ],
    ),

    // 5. 프록시 게이트 (pvzProxyGateway - Cheese)
    BuildOrder(
      id: 'pvz_proxy_gate',
      name: '프록시 게이트',
      race: 'P',
      vsRace: 'Z',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 프로브 출발합니다.', stat: 'sense'),
        BuildStep(line: 3, text: '{player}, 프록시 파일런!', stat: 'sense', myResource: -10),
        BuildStep(line: 6, text: '{player} 선수 프록시 게이트웨이!', stat: 'attack', myResource: -15),
        BuildStep(line: 10, text: '{player}, 질럿 생산!', stat: 'attack', myArmy: 3, myResource: -8),
        BuildStep(line: 13, text: '{player} 선수 질럿 투입!', stat: 'attack', isClash: true),
        BuildStep(line: 16, text: '{player}, 드론 사냥!', stat: 'control', enemyResource: -30),
        BuildStep(line: 20, text: '{player}, 질럿 추가!', myArmy: 3, myResource: -8),
        BuildStep(line: 25, text: '{player} 선수 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),
  ];

  // PvP 빌드들 (BuildType: pvp2GateDragoon, pvpDarkAllIn, pvp1GateRobo, pvpCannonRush, pvpReaverDrop)
  static const protossVsProtossBuilds = [
    // 1. 투게이트 드라군 (pvp2GateDragoon - Balanced)
    BuildOrder(
      id: 'pvp_2gate_dragoon',
      name: '투게이트 드라군',
      race: 'P',
      vsRace: 'P',
      style: BuildStyle.balanced,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 9, text: '{player} 선수 2번째 게이트웨이!', stat: 'control', myResource: -15),
        BuildStep(line: 13, text: '{player} 선수 드라군 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 17, text: '{player}, 드라군 사거리!', stat: 'attack', myResource: -15),
        BuildStep(line: 22, text: '{player}, 드라군 마이크로!', stat: 'control', isClash: true),
        BuildStep(line: 28, text: '{player}, 드라군 추가 생산!', myArmy: 4, myResource: -12),
        BuildStep(line: 35, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 44, text: '{player} 선수 로보틱스 건설!', myResource: -20),
        BuildStep(line: 52, text: '{player}, 리버 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
        BuildStep(line: 62, text: '{player}, 지상군 푸시!', stat: 'attack', isClash: true),
      ],
    ),

    // 2. 다크 올인 (pvpDarkAllIn - Cheese)
    BuildOrder(
      id: 'pvp_dark_allin',
      name: '다크 올인',
      race: 'P',
      vsRace: 'P',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 9, text: '{player} 선수 시타델 건설!', stat: 'attack', myResource: -15),
        BuildStep(line: 14, text: '{player} 선수 템플러 아카이브!', myResource: -20),
        BuildStep(line: 20, text: '{player}, 다크템플러 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
        BuildStep(line: 25, text: '{player}, 다크 투입!', stat: 'attack'),
        BuildStep(line: 28, text: '{player}, 프로브 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -40),
        BuildStep(line: 34, text: '{player}, 다크 추가!', myArmy: 2, myResource: -10),
        BuildStep(line: 40, text: '{player} 선수 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),

    // 3. 원게이트 로보 (pvp1GateRobo - Defensive)
    BuildOrder(
      id: 'pvp_1gate_robo',
      name: '원게이트 로보',
      race: 'P',
      vsRace: 'P',
      style: BuildStyle.defensive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 10, text: '{player} 선수 드라군 생산!', myArmy: 3, myResource: -10),
        BuildStep(line: 14, text: '{player} 선수 로보틱스 건설!', stat: 'defense', myResource: -20),
        BuildStep(line: 18, text: '{player}, 드라군 사거리!', stat: 'strategy', myResource: -15),
        BuildStep(line: 24, text: '{player} 선수 옵저버 생산!', stat: 'strategy', myArmy: 1, myResource: -10),
        BuildStep(line: 30, text: '{player}, 다크 탐지!', stat: 'scout'),
        BuildStep(line: 36, text: '{player} 선수 리버 생산!', stat: 'defense', myArmy: 4, myResource: -18),
        BuildStep(line: 44, text: '{player} 선수 앞마당 넥서스!', stat: 'macro', myResource: -40),
        BuildStep(line: 54, text: '{player}, 셔틀 생산!', myArmy: 1, myResource: -10),
        BuildStep(line: 62, text: '{player}, 리버 드랍!', stat: 'harass', enemyArmy: -8, enemyResource: -25),
        BuildStep(line: 72, text: '{player} 선수 안정적인 운영!', stat: 'macro', myArmy: 10, myResource: -30),
      ],
    ),

    // 4. 캐논 러시 (pvpCannonRush - Cheese)
    BuildOrder(
      id: 'pvp_cannon_rush',
      name: '캐논 러시',
      race: 'P',
      vsRace: 'P',
      style: BuildStyle.cheese,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 프로브 출발!', stat: 'sense'),
        BuildStep(line: 3, text: '{player}, 프록시 포지!', stat: 'attack', myResource: -15),
        BuildStep(line: 6, text: '{player} 선수 캐논 건설!', stat: 'attack', myResource: -15),
        BuildStep(line: 9, text: '{player}, 캐논 러시!', stat: 'attack'),
        BuildStep(line: 12, text: '{player}, 상대 본진 캐논!', stat: 'attack', enemyResource: -20, isClash: true),
        BuildStep(line: 16, text: '{player}, 캐논 추가!', myResource: -15),
        BuildStep(line: 20, text: '{player} 선수 캐논 포위!', stat: 'attack', enemyArmy: -5, enemyResource: -25),
        BuildStep(line: 26, text: '{player}, 캐논 올인!', stat: 'attack', isClash: true, decisive: true),
      ],
    ),

    // 5. 리버 드랍 (pvpReaverDrop - Aggressive)
    BuildOrder(
      id: 'pvp_reaver_drop',
      name: '리버 드랍',
      race: 'P',
      vsRace: 'P',
      style: BuildStyle.aggressive,
      steps: [
        BuildStep(line: 1, text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
        BuildStep(line: 5, text: '{player} 선수 사이버네틱스 코어!', myResource: -15),
        BuildStep(line: 9, text: '{player}, 드라군 생산!', stat: 'control', myArmy: 3, myResource: -10),
        BuildStep(line: 12, text: '{player} 선수 로보틱스 퍼실리티!', stat: 'strategy', myResource: -20),
        BuildStep(line: 16, text: '{player}, 리버 생산!', stat: 'harass', myArmy: 2, myResource: -15),
        BuildStep(line: 20, text: '{player} 선수 셔틀 생산!', myArmy: 1, myResource: -10),
        BuildStep(line: 24, text: '{player}, 리버 드랍 출발!', stat: 'harass'),
        BuildStep(line: 28, text: '{player} 선수 리버 드랍 성공!', stat: 'control', enemyArmy: -8, enemyResource: -25, isClash: true),
        BuildStep(line: 34, text: '{player}, 리버 추가 생산!', myArmy: 2, myResource: -15),
        BuildStep(line: 40, text: '{player} 선수 멀티 리버 드랍!', stat: 'harass', enemyResource: -20, isClash: true),
        BuildStep(line: 50, text: '{player}, 병력 모아서 결전!', stat: 'attack', myArmy: 5, isClash: true),
      ],
    ),
  ];

  // ==================== 맵 특성 기반 이벤트 ====================

  /// 러시맵 이벤트 (rushDistance <= 4)
  static const rushMapEvents = [
    ClashEvent(
      text: '짧은 거리! {attacker} 선수 빠른 타이밍 공격!',
      favorsStat: 'attack',
      attackerArmy: -3,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '러시 맵에서 빠른 압박! 수비할 시간이 없습니다!',
      favorsStat: 'attack',
      attackerArmy: -5,
      defenderArmy: -10,
      defenderResource: -15,
    ),
    ClashEvent(
      text: '짧은 이동 거리! {attacker} 선수 초반 올인!',
      favorsStat: 'attack',
      attackerArmy: -8,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '{attacker} 선수, 빠른 타이밍 공격! 멀티 저지!',
      favorsStat: 'harass',
      attackerArmy: -4,
      defenderArmy: -6,
      defenderResource: -20,
    ),
  ];

  /// 넓은 맵 이벤트 (rushDistance >= 7, resources >= 6)
  static const macroMapEvents = [
    ClashEvent(
      text: '넓은 맵! {attacker} 선수 멀티 운영으로 경제력 압도!',
      favorsStat: 'macro',
      attackerArmy: -2,
      defenderArmy: -5,
      attackerResource: 20,
    ),
    ClashEvent(
      text: '자원 많은 맵! 물량 싸움으로 가려합니다!',
      favorsStat: 'macro',
      attackerArmy: -5,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '{attacker} 선수, 넓은 맵 장점 활용! 멀티 기지 우세!',
      favorsStat: 'macro',
      attackerArmy: -3,
      defenderArmy: -6,
      attackerResource: 15,
    ),
    ClashEvent(
      text: '후반 물량 싸움! 넓은 맵에서 경제력이 승부를 가릅니다!',
      favorsStat: 'macro',
      attackerArmy: -8,
      defenderArmy: -10,
    ),
  ];

  /// 복잡한 지형 이벤트 (terrainComplexity >= 7)
  static const complexTerrainEvents = [
    ClashEvent(
      text: '좁은 길목 활용! {attacker} 선수 완벽한 포지셔닝!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
    ClashEvent(
      text: '언덕 위 진형! {defender} 선수 지형 보너스 활용!',
      favorsStat: 'defense',
      attackerArmy: -12,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '복잡한 지형에서 컨트롤 싸움! 기량이 드러납니다!',
      favorsStat: 'control',
      attackerArmy: -6,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '좁은 길목 방어! 물량이 많아도 소용없습니다!',
      favorsStat: 'defense',
      attackerArmy: -15,
      defenderArmy: -5,
    ),
  ];

  /// 공중 유리 맵 이벤트 (airAccessibility >= 7)
  static const airMapEvents = [
    ClashEvent(
      text: '열린 공중! {attacker} 선수 공중 유닛 활용!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -6,
      defenderResource: -20,
    ),
    ClashEvent(
      text: '공중 접근성 좋은 맵! 드랍으로 경제 타격!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -5,
      defenderResource: -30,
    ),
    ClashEvent(
      text: '{attacker} 선수, 공중 유닛으로 멀티 견제 연타!',
      favorsStat: 'harass',
      attackerArmy: -4,
      defenderArmy: -4,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '열린 하늘! 대공이 부족하면 끝납니다!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
  ];

  /// 섬 멀티 맵 이벤트 (hasIsland = true)
  static const islandMapEvents = [
    ClashEvent(
      text: '섬 멀티 확장 성공! {attacker} 선수 안전한 자원 확보!',
      favorsStat: 'strategy',
      attackerArmy: 0,
      defenderArmy: 0,
      attackerResource: 35,
    ),
    ClashEvent(
      text: '섬 기지로 경제력 역전! 드랍십 필수!',
      favorsStat: 'macro',
      attackerArmy: -2,
      defenderArmy: -3,
      attackerResource: 25,
    ),
    ClashEvent(
      text: '{defender} 선수, 섬 멀티 급습! 드랍 성공!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -8,
      defenderResource: -35,
    ),
    ClashEvent(
      text: '섬 기지 발각! 드랍으로 초토화!',
      favorsStat: 'scout',
      attackerArmy: -5,
      defenderArmy: -10,
      defenderResource: -40,
    ),
  ];

  /// 중앙 싸움 맵 이벤트 (centerImportance >= 7)
  static const centerControlEvents = [
    ClashEvent(
      text: '중앙 확보 전쟁! 먼저 잡는 쪽이 유리합니다!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '{attacker} 선수, 중앙 고지대 선점! 유리한 싸움!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '중앙 워치타워 확보! 상대 움직임 완벽 파악!',
      favorsStat: 'scout',
      attackerArmy: -3,
      defenderArmy: -6,
    ),
    ClashEvent(
      text: '중앙에서 대회전! 컨트롤로 승부합니다!',
      favorsStat: 'control',
      attackerArmy: -10,
      defenderArmy: -12,
    ),
  ];

  // ==================== 능력치 특화 이벤트 ====================

  /// 고공격력 이벤트 (attack >= 700)
  static const highAttackEvents = [
    ClashEvent(
      text: '{attacker} 선수, 압도적인 공격력! 상대 진영 초토화!',
      favorsStat: 'attack',
      attackerArmy: -5,
      defenderArmy: -18,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '무자비한 공격! {attacker} 선수 상대 방어선 붕괴!',
      favorsStat: 'attack',
      attackerArmy: -8,
      defenderArmy: -20,
    ),
    ClashEvent(
      text: '{attacker} 선수, 공격 타이밍 완벽! 상대 무력화!',
      favorsStat: 'attack',
      attackerArmy: -6,
      defenderArmy: -15,
      defenderResource: -20,
    ),
  ];

  /// 고견제력 이벤트 (harass >= 700)
  static const highHarassEvents = [
    ClashEvent(
      text: '{attacker} 선수, 환상적인 멀티태스킹! 동시다발 견제!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -8,
      defenderResource: -45,
    ),
    ClashEvent(
      text: '멀티 포인트 견제! 상대 병력이 분산됩니다!',
      favorsStat: 'harass',
      attackerArmy: -4,
      defenderArmy: -10,
      defenderResource: -35,
    ),
    ClashEvent(
      text: '{attacker} 선수, 일꾼 라인 연속 견제! 경제 붕괴!',
      favorsStat: 'harass',
      attackerArmy: -5,
      defenderArmy: -5,
      defenderResource: -50,
    ),
  ];

  /// 고수비력 이벤트 (defense >= 700)
  static const highDefenseEvents = [
    ClashEvent(
      text: '{defender} 선수, 철벽 수비! 모든 공격 막아냅니다!',
      favorsStat: 'defense',
      attackerArmy: -18,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '난공불락! {defender} 선수 완벽한 방어 태세!',
      favorsStat: 'defense',
      attackerArmy: -20,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '{defender} 선수, 방어선 유지! 공격군 전멸!',
      favorsStat: 'defense',
      attackerArmy: -15,
      defenderArmy: -2,
      attackerResource: -15,
    ),
  ];

  /// 고컨트롤 이벤트 (control >= 700)
  static const highControlEvents = [
    ClashEvent(
      text: '이게 컨트롤이다! {attacker} 선수 환상적인 마이크로!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -18,
    ),
    ClashEvent(
      text: '{attacker} 선수, 신들린 컨트롤! 적 핵심 유닛 포커싱!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -20,
    ),
    ClashEvent(
      text: '미친 컨트롤! 상대가 손을 쓸 수가 없습니다!',
      favorsStat: 'control',
      attackerArmy: -2,
      defenderArmy: -15,
    ),
  ];

  /// 고전략력 이벤트 (strategy >= 700)
  static const highStrategyEvents = [
    ClashEvent(
      text: '{attacker} 선수, 완벽한 빌드 읽기! 카운터 성공!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -15,
      attackerResource: 20,
    ),
    ClashEvent(
      text: '한 수 앞서는 전략! 상대 빌드 완전 봉쇄!',
      favorsStat: 'strategy',
      attackerArmy: -8,
      defenderArmy: -12,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '{attacker} 선수, 전략적 우위! 게임 주도권 장악!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
  ];

  /// 고물량력 이벤트 (macro >= 700)
  static const highMacroEvents = [
    ClashEvent(
      text: '{attacker} 선수, 물량으로 압살! 끝이 없는 병력!',
      favorsStat: 'macro',
      attackerArmy: 5,
      defenderArmy: -12,
      attackerResource: -20,
    ),
    ClashEvent(
      text: '경제력 차이! {attacker} 선수 무한 리플레이스!',
      favorsStat: 'macro',
      attackerArmy: 3,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '물량 게임! 상대가 감당을 못합니다!',
      favorsStat: 'macro',
      attackerArmy: 8,
      defenderArmy: -15,
      attackerResource: -25,
    ),
  ];

  /// 고센스력 이벤트 (sense >= 700)
  static const highSenseEvents = [
    ClashEvent(
      text: '{attacker} 선수, 치명적인 타이밍! 상대 허점 포착!',
      favorsStat: 'sense',
      attackerArmy: -5,
      defenderArmy: -15,
      defenderResource: -30,
    ),
    ClashEvent(
      text: '귀신같은 센스! {attacker} 선수 결정적 순간 공격!',
      favorsStat: 'sense',
      attackerArmy: -3,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '{attacker} 선수, 완벽한 타이밍! 상대 대비 전 공격!',
      favorsStat: 'sense',
      attackerArmy: -8,
      defenderArmy: -18,
    ),
  ];

  // ==================== 수비자 고능력치 이벤트 ====================
  // 수비자의 능력치가 높을 때 발생하는 이벤트 (수비자 유리)
  // attackerArmy가 큰 피해, defenderArmy가 작은 피해 = 수비자 유리

  /// 수비자 고전략 이벤트 (defender strategy >= 700)
  static const highDefenderStrategyEvents = [
    ClashEvent(
      text: '{defender} 선수, 상대 빌드 완벽 읽기! 카운터 성공!',
      favorsStat: 'strategy',
      attackerArmy: -15,
      defenderArmy: -5,
      attackerResource: -20,
    ),
    ClashEvent(
      text: '{defender} 선수, 전략적 포지셔닝! 공격군 고립!',
      favorsStat: 'strategy',
      attackerArmy: -12,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '한 수 앞서는 수비! {defender} 선수 함정 카드!',
      favorsStat: 'strategy',
      attackerArmy: -10,
      defenderArmy: -3,
      defenderResource: 15,
    ),
  ];

  /// 수비자 고물량 이벤트 (defender macro >= 700)
  static const highDefenderMacroEvents = [
    ClashEvent(
      text: '{defender} 선수, 압도적 물량 리플레이스! 공격군 녹습니다!',
      favorsStat: 'macro',
      attackerArmy: -12,
      defenderArmy: 5,
      defenderResource: -20,
    ),
    ClashEvent(
      text: '{defender} 선수, 끝없는 병력 보충! 공격이 통하지 않습니다!',
      favorsStat: 'macro',
      attackerArmy: -8,
      defenderArmy: 3,
    ),
    ClashEvent(
      text: '경제력 차이! {defender} 선수 물량으로 역전!',
      favorsStat: 'macro',
      attackerArmy: -15,
      defenderArmy: -5,
      defenderResource: -25,
    ),
  ];

  /// 수비자 고컨트롤 이벤트 (defender control >= 700)
  static const highDefenderControlEvents = [
    ClashEvent(
      text: '{defender} 선수, 환상적인 수비 컨트롤! 공격군 포커싱!',
      favorsStat: 'control',
      attackerArmy: -18,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '{defender} 선수, 완벽한 스플릿! 피해 최소화!',
      favorsStat: 'control',
      attackerArmy: -12,
      defenderArmy: -2,
    ),
    ClashEvent(
      text: '수비 장인! {defender} 선수 적은 병력으로 막아냅니다!',
      favorsStat: 'control',
      attackerArmy: -15,
      defenderArmy: -3,
    ),
  ];

  /// 수비자 고센스 이벤트 (defender sense >= 700)
  static const highDefenderSenseEvents = [
    ClashEvent(
      text: '{defender} 선수, 타이밍 읽기 성공! 공격 무력화!',
      favorsStat: 'sense',
      attackerArmy: -15,
      defenderArmy: -5,
      defenderResource: 10,
    ),
    ClashEvent(
      text: '{defender} 선수, 상대 약점 간파! 역습 성공!',
      favorsStat: 'sense',
      attackerArmy: -12,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '귀신같은 대비! {defender} 선수 공격 예측!',
      favorsStat: 'sense',
      attackerArmy: -10,
      defenderArmy: -2,
      attackerResource: -15,
    ),
  ];

  // ==================== 빌드 타입별 전용 이벤트 ====================

  /// 빌드 타입별 전용 이벤트 맵
  static const Map<BuildType, List<ClashEvent>> buildTypeEvents = {
    // TvZ 빌드들
    BuildType.tvz2FactoryVulture: [
      ClashEvent(text: '벌처 마인 폭발! 저글링 떼가 순식간에 녹습니다!', favorsStat: 'strategy', attackerArmy: -2, defenderArmy: -15),
      ClashEvent(text: '벌처 라인 견제! 드론 학살!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -5, defenderResource: -35),
      ClashEvent(text: '2팩 벌처 타이밍! 상대 물량 전에 끝내야 합니다!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12),
    ],
    BuildType.tvzSKTerran: [
      ClashEvent(text: 'SK테란 스타일! 벌처로 맵 장악 후 점진적 확장!', favorsStat: 'macro', attackerArmy: -3, defenderArmy: -6, attackerResource: 15),
      ClashEvent(text: '탱크 벌처 조합! 안정적인 진형 구축!', favorsStat: 'strategy', attackerArmy: -5, defenderArmy: -8),
    ],
    BuildType.tvzWraithHarass: [
      ClashEvent(text: '레이스 오버로드 사냥! 서플라이 블락!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -6, defenderResource: -25),
      ClashEvent(text: '클로킹 레이스 투입! 드론 학살 시작!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -4, defenderResource: -40),
    ],

    // ZvT 빌드들
    BuildType.zvt3HatchMutal: [
      ClashEvent(text: '뮤탈 11기 완성! 이제 견제 시작입니다!', favorsStat: 'control', attackerArmy: 5, defenderArmy: 0, attackerResource: -20),
      ClashEvent(text: '뮤탈 매직! SCV 라인 초토화!', favorsStat: 'control', attackerArmy: -3, defenderArmy: -4, defenderResource: -40),
      ClashEvent(text: '3해처리 물량! 뮤탈이 쏟아집니다!', favorsStat: 'macro', attackerArmy: 8, defenderArmy: -5, attackerResource: -25),
    ],
    BuildType.zvt2HatchLurker: [
      ClashEvent(text: '럴커 변태 완료! 러시 방어 준비!', favorsStat: 'defense', attackerArmy: 4, defenderArmy: 0, attackerResource: -15),
      ClashEvent(text: '럴커 홀드! 바이오닉 진입 불가!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -18),
    ],

    // PvT 빌드들
    BuildType.pvtDarkSwing: [
      ClashEvent(text: '다크템플러 투입! 감지기 없으면 끝입니다!', favorsStat: 'strategy', attackerArmy: -2, defenderArmy: -8, defenderResource: -40),
      ClashEvent(text: '다크 스윙! SCV 라인이 녹습니다!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -5, defenderResource: -50),
    ],
    BuildType.pvt2GateZealot: [
      ClashEvent(text: '투게이트 질럿 푸시! 앞마당을 밀어버립니다!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12),
      ClashEvent(text: '질럿 러시! 벙커 건설 전에 들어갑니다!', favorsStat: 'attack', attackerArmy: -10, defenderArmy: -15),
    ],

    // ZvZ 빌드들
    BuildType.zvzPoolFirst: [
      ClashEvent(text: '선제 저글링 도착! 해처리 막힙니다!', favorsStat: 'attack', attackerArmy: -5, defenderArmy: -8, defenderResource: -20),
      ClashEvent(text: '선풀 저글링 싸움! 컨트롤로 승부!', favorsStat: 'control', attackerArmy: -8, defenderArmy: -10),
    ],
    BuildType.zvz12Hatch: [
      ClashEvent(text: '12해처리 드론 뽑기! 경제력으로 역전!', favorsStat: 'macro', attackerArmy: 2, defenderArmy: 0, attackerResource: 20),
      ClashEvent(text: '물량 축적 완료! 이제 반격입니다!', favorsStat: 'macro', attackerArmy: 5, defenderArmy: -3, attackerResource: -15),
    ],

    // PvZ 빌드들
    BuildType.pvzCorsairReaver: [
      ClashEvent(text: '커세어 오버로드 사냥! 서플라이 블락!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -5, defenderResource: -20),
      ClashEvent(text: '리버 드랍! 드론 라인이 터집니다!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -8, defenderResource: -45),
    ],
    BuildType.pvzForgeCannon: [
      ClashEvent(text: '포지 캐논 수비! 저글링 러시 막습니다!', favorsStat: 'defense', attackerArmy: -2, defenderArmy: -12),
      ClashEvent(text: '캐논으로 앞마당 보호! 안전한 확장!', favorsStat: 'defense', attackerArmy: 0, defenderArmy: -5, attackerResource: 15),
    ],

    // TvP 빌드들
    BuildType.tvpFakeDouble: [
      ClashEvent(text: '페이크 더블 푸시! 앞마당 캔슬하고 공격!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12),
      ClashEvent(text: '상대가 더블인 줄 알고 방심했습니다!', favorsStat: 'sense', attackerArmy: -5, defenderArmy: -15),
    ],
    BuildType.tvp1FactDrop: [
      ClashEvent(text: '탱크 드랍 성공! 프로브 라인 박살!', favorsStat: 'harass', attackerArmy: -4, defenderArmy: -6, defenderResource: -35),
      ClashEvent(text: '드랍십 멀티태스킹! 상대가 대응을 못합니다!', favorsStat: 'harass', attackerArmy: -5, defenderArmy: -8, defenderResource: -30),
    ],

    // TvT 빌드들
    BuildType.tvt1FactPush: [
      ClashEvent(text: '원팩 선공! 고지대 점령!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12),
      ClashEvent(text: '빠른 탱크 푸시! 상대 대비 전 공격!', favorsStat: 'attack', attackerArmy: -10, defenderArmy: -15),
    ],
    BuildType.tvtWraithCloak: [
      ClashEvent(text: '클로킹 레이스! 탱크 라인 견제!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -8),
      ClashEvent(text: '레이스로 SCV 견제! 경제 타격!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -4, defenderResource: -30),
    ],

    // PvP 빌드들
    BuildType.pvpDarkAllIn: [
      ClashEvent(text: '다크 올인! 옵저버 없으면 GG!', favorsStat: 'strategy', attackerArmy: -3, defenderArmy: -10, defenderResource: -40),
      ClashEvent(text: '다크템플러로 프로브 학살!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -8, defenderResource: -50),
    ],
    BuildType.pvp2GateDragoon: [
      ClashEvent(text: '투게이트 드라군! 컨트롤 싸움!', favorsStat: 'control', attackerArmy: -8, defenderArmy: -10),
      ClashEvent(text: '드라군 마이크로! 포커싱 성공!', favorsStat: 'control', attackerArmy: -5, defenderArmy: -12),
    ],

    // 추가 빌드 전용 이벤트
    BuildType.tvzBunkerDefense: [
      ClashEvent(text: '벙커 수비 성공! 저글링 러시 막아냅니다!', favorsStat: 'defense', attackerArmy: -2, defenderArmy: -12),
      ClashEvent(text: '벙커 뒤에서 마린 화력! 상대 물량 녹입니다!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -10),
    ],
    BuildType.tvz3FactoryGoliath: [
      ClashEvent(text: '3팩 골리앗! 대공 화력 집중!', favorsStat: 'defense', attackerArmy: -4, defenderArmy: -10),
      ClashEvent(text: '골리앗 물량! 뮤탈 접근 불가!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -8, defenderResource: -15),
    ],
    BuildType.tvzMechDrop: [
      ClashEvent(text: '메카닉 드랍! 본진 후방 교란!', favorsStat: 'harass', attackerArmy: -5, defenderArmy: -8, defenderResource: -30),
      ClashEvent(text: '탱크 드랍! 해처리 직접 타격!', favorsStat: 'harass', attackerArmy: -4, defenderArmy: -6, defenderResource: -25),
    ],
    BuildType.tvpDouble: [
      ClashEvent(text: '더블 커맨드! 경제력으로 압도!', favorsStat: 'macro', attackerArmy: 3, defenderArmy: 0, attackerResource: 20),
      ClashEvent(text: '안정적 확장 완료! 물량 생산 시작!', favorsStat: 'macro', attackerArmy: 5, defenderArmy: -2, attackerResource: 10),
    ],
    BuildType.tvp1FactGosu: [
      ClashEvent(text: '원팩 고수 운영! 정확한 타이밍 공격!', favorsStat: 'strategy', attackerArmy: -6, defenderArmy: -10),
      ClashEvent(text: '탱크 시즈 모드! 드라군 접근 차단!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -12),
    ],
    BuildType.tvpWraithRush: [
      ClashEvent(text: '레이스 난사! 프로브 라인 습격!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -4, defenderResource: -35),
      ClashEvent(text: '클로킹 레이스! 감지기 없으면 끝!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -6, defenderResource: -30),
    ],
    BuildType.tvtProxy: [
      ClashEvent(text: '프록시 배럭 들켜버렸습니다!', favorsStat: 'sense', attackerArmy: -8, defenderArmy: -3),
      ClashEvent(text: '프록시 마린 러시 성공! 앞마당 차단!', favorsStat: 'attack', attackerArmy: -5, defenderArmy: -10, defenderResource: -20),
    ],
    BuildType.tvt2Barracks: [
      ClashEvent(text: '투배럭 마린! 안정적 초반 방어!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -8),
      ClashEvent(text: '마린 벙커! 초반 러시 완벽 방어!', favorsStat: 'defense', attackerArmy: -2, defenderArmy: -10),
    ],
    BuildType.tvt2Factory: [
      ClashEvent(text: '투팩 탱크! 화력 집중!', favorsStat: 'strategy', attackerArmy: -5, defenderArmy: -10),
      ClashEvent(text: '투팩 벌처 탱크 조합! 맵 장악!', favorsStat: 'macro', attackerArmy: -4, defenderArmy: -8, attackerResource: 10),
    ],
    BuildType.zvt2HatchMutal: [
      ClashEvent(text: '투해처리 뮤탈! 빠른 견제!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -5, defenderResource: -25),
      ClashEvent(text: '뮤탈 히트앤런! 터렛 전에 피해 줍니다!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -4, defenderResource: -30),
    ],
    BuildType.zvtHatchSpore: [
      ClashEvent(text: '해처리 스포어! 안정적 수비 확보!', favorsStat: 'defense', attackerArmy: -2, defenderArmy: -8),
      ClashEvent(text: '스포어로 공중 방어! 경제 확보!', favorsStat: 'macro', attackerArmy: 2, defenderArmy: 0, attackerResource: 15),
    ],
    BuildType.zvt1HatchAllIn: [
      ClashEvent(text: '원해처리 올인! 저글링 물량 돌격!', favorsStat: 'attack', attackerArmy: -10, defenderArmy: -15),
      ClashEvent(text: '초반 전력 투입! 벙커 전에 들어갑니다!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12, defenderResource: -20),
    ],
    BuildType.zvp3HatchHydra: [
      ClashEvent(text: '3해처리 히드라! 물량으로 밀어붙입니다!', favorsStat: 'macro', attackerArmy: 5, defenderArmy: -5, attackerResource: -20),
      ClashEvent(text: '히드라 물량! 드라군 라인 돌파!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -12),
    ],
    BuildType.zvp2HatchMutal: [
      ClashEvent(text: '투해처리 뮤탈! 프로브 견제!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -4, defenderResource: -30),
      ClashEvent(text: '뮤탈로 맵 장악! 코르세어 없으면 답 없습니다!', favorsStat: 'control', attackerArmy: -2, defenderArmy: -6, defenderResource: -20),
    ],
    BuildType.zvpScourgeDefiler: [
      ClashEvent(text: '스커지로 커세어 격추! 제공권 역전!', favorsStat: 'control', attackerArmy: -4, defenderArmy: -8),
      ClashEvent(text: '디파일러 플레이그! 드라군 편대 녹습니다!', favorsStat: 'strategy', attackerArmy: -2, defenderArmy: -15),
    ],
    BuildType.zvp5DroneZergling: [
      ClashEvent(text: '5드론 저글링! 캐논 전에 돌진!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -10, defenderResource: -25),
      ClashEvent(text: '초반 올인! 프로브 학살!', favorsStat: 'attack', attackerArmy: -5, defenderArmy: -8, defenderResource: -30),
    ],
    BuildType.pvt1GateObserver: [
      ClashEvent(text: '원게이트 옵저버! 다크 완벽 대비!', favorsStat: 'defense', attackerArmy: -3, defenderArmy: -8),
      ClashEvent(text: '옵저버로 상대 빌드 완전 파악!', favorsStat: 'scout', attackerArmy: 0, defenderArmy: -3, attackerResource: 10),
    ],
    BuildType.pvtProxyDark: [
      ClashEvent(text: '프록시 다크 투입! 감지기 확인!', favorsStat: 'strategy', attackerArmy: -3, defenderArmy: -8, defenderResource: -35),
      ClashEvent(text: '다크 은밀히 투입! SCV 학살!', favorsStat: 'harass', attackerArmy: -2, defenderArmy: -5, defenderResource: -40),
    ],
    BuildType.pvzNexusFirst: [
      ClashEvent(text: '넥서스 퍼스트! 경제력으로 승부!', favorsStat: 'macro', attackerArmy: 3, defenderArmy: 0, attackerResource: 25),
      ClashEvent(text: '빠른 확장 성공! 물량 생산 돌입!', favorsStat: 'macro', attackerArmy: 5, defenderArmy: -2, attackerResource: 15),
    ],
    BuildType.pvz2GateZealot: [
      ClashEvent(text: '투게이트 질럿 앞마당 압박!', favorsStat: 'attack', attackerArmy: -8, defenderArmy: -10, defenderResource: -15),
      ClashEvent(text: '질럿 러시! 선큰 전에 들어갑니다!', favorsStat: 'attack', attackerArmy: -6, defenderArmy: -12),
    ],
    BuildType.pvp1GateRobo: [
      ClashEvent(text: '원게이트 로보! 리버로 전환!', favorsStat: 'strategy', attackerArmy: 2, defenderArmy: 0, attackerResource: -15),
      ClashEvent(text: '리버 생산! 셔틀 드랍 준비!', favorsStat: 'harass', attackerArmy: 3, defenderArmy: 0, attackerResource: -20),
    ],
    BuildType.pvpCannonRush: [
      ClashEvent(text: '캐논 러시! 상대 미네랄 라인 차단!', favorsStat: 'attack', attackerArmy: -2, defenderArmy: -5, defenderResource: -25),
      ClashEvent(text: '프록시 캐논 성공! 건물 올라갑니다!', favorsStat: 'attack', attackerArmy: 0, defenderArmy: -8, defenderResource: -20),
    ],
    // 새로 추가된 프로토스 빌드
    BuildType.pvt1GateExpansion: [
      ClashEvent(text: '원게이트 확장! 안정적 운영!', favorsStat: 'macro', attackerArmy: 3, defenderArmy: 0, attackerResource: 20),
      ClashEvent(text: '리버 드랍 타이밍! 확장 후 견제!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -6, defenderResource: -30),
    ],
    BuildType.pvzProxyGateway: [
      ClashEvent(text: '프록시 게이트! 질럿 투입!', favorsStat: 'attack', attackerArmy: -6, defenderArmy: -10, defenderResource: -20),
      ClashEvent(text: '프록시 질럿 드론 사냥!', favorsStat: 'attack', attackerArmy: -5, defenderArmy: -8, defenderResource: -30),
    ],
    BuildType.pvpReaverDrop: [
      ClashEvent(text: '리버 드랍! 프로브 라인 폭격!', favorsStat: 'harass', attackerArmy: -3, defenderArmy: -8, defenderResource: -35),
      ClashEvent(text: '셔틀 리버 멀티 드랍! 대응 불가!', favorsStat: 'harass', attackerArmy: -4, defenderArmy: -6, defenderResource: -40),
    ],
    BuildType.zvz9Pool: [
      ClashEvent(text: '9풀 저글링! 빠른 압박!', favorsStat: 'attack', attackerArmy: -5, defenderArmy: -8),
      ClashEvent(text: '9풀 타이밍 공격! 선큰 전에 들어갑니다!', favorsStat: 'attack', attackerArmy: -6, defenderArmy: -10, defenderResource: -15),
    ],
    BuildType.zvzOverPool: [
      ClashEvent(text: '오버풀! 경제와 병력의 균형!', favorsStat: 'macro', attackerArmy: 3, defenderArmy: -2, attackerResource: 10),
      ClashEvent(text: '오버풀 타이밍! 적절한 저글링 수!', favorsStat: 'control', attackerArmy: -4, defenderArmy: -6),
    ],
    BuildType.zvzExtractor: [
      ClashEvent(text: '익스트랙터 트릭! 서플라이 이득!', favorsStat: 'sense', attackerArmy: 2, defenderArmy: 0),
      ClashEvent(text: '빠른 가스! 스피드 저글링 준비!', favorsStat: 'sense', attackerArmy: -3, defenderArmy: -5, attackerResource: -5),
    ],
  };

  /// 빌드 타입에 맞는 전용 이벤트 가져오기
  static List<ClashEvent> getBuildTypeEvents(BuildType? buildType) {
    if (buildType == null) return [];
    return buildTypeEvents[buildType] ?? [];
  }

  // ==================== 충돌 시나리오 ====================

  /// 공격 vs 수비 충돌
  static const aggressiveVsDefensive = [
    ClashEvent(
      text: '{attacker} 선수 공격 들어갑니다!',
      attackerArmy: -5,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '{defender}, 완벽한 방어!',
      favorsStat: 'defense',
      attackerArmy: -10,
      defenderArmy: -2,
    ),
    ClashEvent(
      text: '{attacker}, 수비를 뚫습니다!',
      favorsStat: 'attack',
      attackerArmy: -5,
      defenderArmy: -12,
      defenderResource: -20,
    ),
    ClashEvent(
      text: '치열한 공방전입니다!',
      attackerArmy: -8,
      defenderArmy: -8,
    ),
    // 역전 이벤트
    ClashEvent(
      text: '{defender}, 물량 열세에서 환상적인 역습!',
      favorsStat: 'strategy',
      attackerArmy: -15,
      defenderArmy: -3,
      attackerResource: -25,
    ),
    ClashEvent(
      text: '{attacker}, 빈틈을 노린 기습 드랍!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -8,
      defenderResource: -35,
    ),
  ];

  /// 공격 vs 공격 충돌
  static const aggressiveVsAggressive = [
    ClashEvent(
      text: '양 선수 정면 충돌!',
      attackerArmy: -10,
      defenderArmy: -10,
    ),
    ClashEvent(
      text: '{attacker}, 컨트롤 싸움 승리!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '{defender}, 역습 성공!',
      favorsStat: 'control',
      attackerArmy: -15,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '피터지는 전투입니다!',
      attackerArmy: -12,
      defenderArmy: -12,
    ),
    // 명장면 이벤트
    ClashEvent(
      text: '{attacker}, 환상적인 마이크로! 이것이 컨트롤입니다!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -18,
    ),
    ClashEvent(
      text: '대단합니다! {defender} 선수 포커싱으로 핵심 유닛 제거!',
      favorsStat: 'control',
      attackerArmy: -20,
      defenderArmy: -5,
    ),
  ];

  /// 수비 vs 수비 충돌 (후반 대회전)
  static const defensiveVsDefensive = [
    ClashEvent(
      text: '양 선수 대치 중입니다...',
      attackerArmy: 0,
      defenderArmy: 0,
    ),
    ClashEvent(
      text: '조심스러운 진격!',
      attackerArmy: -2,
      defenderArmy: -2,
    ),
    ClashEvent(
      text: '최대 서플라이 대회전! 숨막히는 긴장감!',
      attackerArmy: -15,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '후반 물량 싸움! 자원이 승패를 가릅니다!',
      favorsStat: 'macro',
      attackerArmy: -10,
      defenderArmy: -10,
    ),
    // 추가 수비vs수비 이벤트
    ClashEvent(
      text: '양측 진영이 맞붙었습니다!',
      attackerArmy: -8,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '신중한 포지셔닝 싸움!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '양 선수 조금씩 전선을 밀어갑니다.',
      attackerArmy: -4,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '지금까지 쌓아온 물량의 대결!',
      favorsStat: 'macro',
      attackerArmy: -12,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '양측 모두 손해를 최소화하며 싸웁니다.',
      attackerArmy: -5,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '후반 대치 상황! 누가 먼저 실수하느냐!',
      favorsStat: 'sense',
      attackerArmy: -2,
      defenderArmy: -2,
    ),
    ClashEvent(
      text: '치열한 고지대 점령전!',
      favorsStat: 'strategy',
      attackerArmy: -7,
      defenderArmy: -6,
    ),
    ClashEvent(
      text: '장기전으로 흘러가고 있습니다.',
      favorsStat: 'macro',
      attackerArmy: -3,
      defenderArmy: -3,
      attackerResource: 5,
      defenderResource: 5,
    ),
    ClashEvent(
      text: '양 선수 전력을 다해 싸웁니다!',
      attackerArmy: -10,
      defenderArmy: -11,
    ),
    ClashEvent(
      text: '이 전투가 경기의 향방을 결정할 수 있습니다!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -9,
    ),
    ClashEvent(
      text: '양측 병력이 엉키며 혼전 양상!',
      attackerArmy: -9,
      defenderArmy: -9,
    ),
    ClashEvent(
      text: '막상막하의 전투력! 승부를 예측할 수 없습니다!',
      attackerArmy: -7,
      defenderArmy: -7,
    ),
  ];

  // ==================== 명장면 이벤트 (특수) ====================

  /// 드랍 이벤트 (테란 공격자)
  static const dropEventsTerran = [
    ClashEvent(
      text: '{attacker} 선수, 드랍십 투입! 일꾼 라인 초토화!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -5,
      defenderResource: -40,
    ),
    ClashEvent(
      text: '{attacker}, 탱크 드랍! 상대 라인 박살!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -10,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '{defender}, 드랍 미리 읽었습니다! 완벽한 수비!',
      favorsStat: 'scout',
      attackerArmy: -8,
      defenderArmy: -2,
    ),
  ];

  /// 드랍 이벤트 (프로토스 공격자)
  static const dropEventsProtoss = [
    ClashEvent(
      text: '{attacker} 선수, 리버 드랍! 스캐럽이 작렬합니다!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -12,
      defenderResource: -30,
    ),
    ClashEvent(
      text: '{attacker}, 셔틀 드랍! 일꾼 라인 급습!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -5,
      defenderResource: -35,
    ),
    ClashEvent(
      text: '{defender}, 드랍 미리 읽었습니다! 완벽한 수비!',
      favorsStat: 'scout',
      attackerArmy: -8,
      defenderArmy: -2,
    ),
  ];

  /// 드랍 이벤트 (저그 공격자)
  static const dropEventsZerg = [
    ClashEvent(
      text: '{attacker}, 뮤탈 견제! 일꾼 라인 급습!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -5,
      defenderResource: -35,
    ),
    ClashEvent(
      text: '{attacker} 선수, 오버로드 드랍! 저글링 러쉬!',
      favorsStat: 'harass',
      attackerArmy: -5,
      defenderArmy: -8,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '{defender}, 드랍 미리 읽었습니다! 완벽한 수비!',
      favorsStat: 'scout',
      attackerArmy: -8,
      defenderArmy: -2,
    ),
  ];

  /// 스톰/스펠 이벤트 (프로토스 vs 테란/저그)
  static const spellEventsPvTZ = [
    ClashEvent(
      text: '사이오닉 스톰! 상대 병력이 녹습니다!',
      favorsStat: 'strategy',
      attackerArmy: -25,
      defenderArmy: -5,
    ),
  ];

  /// 스톰/스펠 이벤트 (테란이 스톰 상대)
  static const spellEventsTvP = [
    ClashEvent(
      text: '{attacker}, 마린 스플릿! 스톰 피해 최소화!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -3,
    ),
  ];

  /// 저그 스펠 이벤트 (저그 vs 테란)
  static const spellEventsZvT = [
    ClashEvent(
      text: '다크스웜 전개! 탱크 라인이 무력화됩니다!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '디파일러 플레이그! 상대 병력 체력 급감!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -15,
    ),
  ];

  /// 테란 스펠 이벤트 (테란 vs 저그)
  static const spellEventsTvZ = [
    ClashEvent(
      text: '이레디에이트! 뮤탈리스크 편대 박살!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -12,
    ),
  ];

  /// 범용 스펠 이벤트 (모든 매치업)
  static const spellEventsGeneral = [
    ClashEvent(
      text: '결정적인 타이밍에 스킬 사용! 전세 역전!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
  ];

  /// 역전 이벤트
  static const comebackEvents = [
    ClashEvent(
      text: '{defender}, 불리한 상황에서 기적같은 역전!',
      favorsStat: 'sense',
      attackerArmy: -20,
      defenderArmy: -5,
      decisive: true,
    ),
    ClashEvent(
      text: '{defender}, 읽기 싸움 승리! 카운터 빌드 적중!',
      favorsStat: 'strategy',
      attackerArmy: -18,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '{defender}, 히든 테크로 상대 허를 찌릅니다!',
      favorsStat: 'strategy',
      attackerArmy: -15,
      defenderArmy: -2,
      attackerResource: -20,
    ),
  ];

  // ==================== 프로리그 스타일 해설 이벤트 ====================

  /// 명장면 이벤트 (결정적 순간)
  static const epicMomentEvents = [
    ClashEvent(
      text: '대단합니다! 이것이 프로게이머입니다!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '믿을 수가 없습니다! {attacker} 선수의 신의 한수!',
      favorsStat: 'sense',
      attackerArmy: -5,
      defenderArmy: -20,
      decisive: true,
    ),
    ClashEvent(
      text: '역사에 남을 한 판입니다! 명경기가 펼쳐지고 있습니다!',
      favorsStat: 'control',
      attackerArmy: -10,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '이 장면! 다시 보고 싶은 명장면입니다!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '프로리그 역사에 길이 남을 플레이!',
      favorsStat: 'sense',
      attackerArmy: -3,
      defenderArmy: -18,
    ),
  ];

  /// 긴장감 이벤트 (팽팽한 대치)
  static const tensionEvents = [
    ClashEvent(
      text: '팽팽한 신경전입니다! 먼저 움직이는 쪽이 불리합니다!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -2,
    ),
    ClashEvent(
      text: '숨막히는 긴장감! 양 선수 한 치의 실수도 허용되지 않습니다!',
      favorsStat: 'sense',
      attackerArmy: -3,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '극도의 집중! 이 순간이 승부를 가릅니다!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '치열한 읽기 싸움! 누가 먼저 빌드를 파악하느냐!',
      favorsStat: 'scout',
      attackerArmy: -1,
      defenderArmy: -1,
    ),
    ClashEvent(
      text: '경기장 안이 조용해졌습니다... 다음 수가 결정적!',
      favorsStat: 'sense',
      attackerArmy: -2,
      defenderArmy: -3,
    ),
  ];

  /// 역전 드라마 이벤트 (불리한 상황에서)
  static const comebackDramaEvents = [
    ClashEvent(
      text: '{defender} 선수! 죽지 않습니다! 불굴의 정신력!',
      favorsStat: 'defense',
      attackerArmy: -12,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '이것이 역전의 명수! {defender} 선수 기적을 만듭니다!',
      favorsStat: 'sense',
      attackerArmy: -15,
      defenderArmy: -3,
      decisive: true,
    ),
    ClashEvent(
      text: '포기하지 않습니다! {defender} 선수 끈질긴 수비!',
      favorsStat: 'defense',
      attackerArmy: -10,
      defenderArmy: -4,
    ),
    ClashEvent(
      text: '불사조처럼 다시 살아납니다! {defender} 선수!',
      favorsStat: 'sense',
      attackerArmy: -18,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '관객석에서 탄성이 터집니다! 대역전극!',
      favorsStat: 'control',
      attackerArmy: -20,
      defenderArmy: -8,
      decisive: true,
    ),
  ];

  /// 해설자 감탄 이벤트 (놀라운 플레이)
  static const amazingPlayEvents = [
    ClashEvent(
      text: '와! 이게 됩니까?! 상상을 초월하는 플레이!',
      favorsStat: 'control',
      attackerArmy: -2,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '보고도 믿기지 않습니다! 환상적인 컨트롤!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -18,
    ),
    ClashEvent(
      text: '교과서에 실릴 플레이입니다! 완벽합니다!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '아, 이건 정말... 어떻게 이런 생각을 했을까요?',
      favorsStat: 'sense',
      attackerArmy: -8,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '손이 열 개라도 모자랄 멀티태스킹!',
      favorsStat: 'harass',
      attackerArmy: -5,
      defenderArmy: -10,
      defenderResource: -30,
    ),
  ];

  /// 저그 컨트롤 명장면 (저그 사용 시)
  static const microEventsZerg = [
    ClashEvent(
      text: '뮤탈 매직! 환상적인 뮤탈리스크 컨트롤!',
      favorsStat: 'control',
      attackerArmy: -2,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '저글링 서라운드! 병력을 감쌉니다!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -15,
    ),
  ];

  /// 저그 vs 테란 전용 (럴커 홀드)
  static const microEventsZvT = [
    ClashEvent(
      text: '럴커 홀드! 바이오닉이 녹아내립니다!',
      favorsStat: 'defense',
      attackerArmy: -20,
      defenderArmy: -2,
    ),
  ];

  /// 테란 컨트롤 명장면 (테란 사용 시)
  static const microEventsTerran = [
    ClashEvent(
      text: '벌처 컨트롤! 마인을 피하며 일꾼 학살!',
      favorsStat: 'control',
      attackerArmy: -1,
      defenderArmy: -3,
      defenderResource: -30,
    ),
  ];

  /// 프로토스 컨트롤 명장면 (프로토스 사용 시)
  static const microEventsProtoss = [
    ClashEvent(
      text: '드라군 마이크로! 완벽한 포커싱!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
  ];

  /// 범용 컨트롤 명장면 (모든 매치업)
  static const microEventsGeneral = [
    ClashEvent(
      text: '환상적인 컨트롤! 피해 최소화!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
    ClashEvent(
      text: '완벽한 포커싱으로 핵심 유닛 제거!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
  ];

  /// 심리전 이벤트
  static const mindGameEvents = [
    ClashEvent(
      text: '{attacker}, 페이크 멀티로 상대 병력 분산!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '{defender}, 타이밍 완벽히 읽었습니다! 카운터 준비 완료!',
      favorsStat: 'scout',
      attackerArmy: -12,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '{attacker}, 히든 베이스 발각되지 않았습니다!',
      favorsStat: 'sense',
      attackerResource: 30,
      defenderArmy: 0,
    ),
    ClashEvent(
      text: '{defender}, 정찰로 상대 빌드 완벽 파악!',
      favorsStat: 'scout',
      attackerArmy: -5,
      defenderArmy: -2,
    ),
  ];

  // ==================== 매치업별 전용 충돌 이벤트 ====================

  /// TvZ 전용 이벤트
  static const clashEventsTvZ = [
    ClashEvent(
      text: '벌처 마인이 저글링 떼를 초토화!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '시즈 탱크 라인! 저그 병력이 녹아내립니다!',
      favorsStat: 'defense',
      attackerArmy: -5,
      defenderArmy: -18,
    ),
    ClashEvent(
      text: '{attacker}, 탱크 드랍으로 멀티 초토화!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -8,
      defenderResource: -35,
    ),
    ClashEvent(
      text: '사이언스 베슬 이레디에이트! 뮤탈 무력화!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '골리앗 진형! 뮤탈리스크 접근 불가!',
      favorsStat: 'defense',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
  ];

  /// ZvT 전용 이벤트
  static const clashEventsZvT = [
    ClashEvent(
      text: '럴커 홀드! 바이오닉 병력이 녹아내립니다!',
      favorsStat: 'defense',
      attackerArmy: -20,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '뮤탈 매직! 터렛 사각지대 공략!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -3,
      defenderResource: -30,
    ),
    ClashEvent(
      text: '다크스웜 전개! 탱크 라인 무력화!',
      favorsStat: 'strategy',
      attackerArmy: -8,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '울트라리스크 돌진! 탱크 라인 붕괴!',
      favorsStat: 'attack',
      attackerArmy: -10,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '디파일러 플레이그! 베슬 무력화!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -8,
    ),
  ];

  /// TvP 전용 이벤트
  static const clashEventsTvP = [
    ClashEvent(
      text: 'EMP! 하이템플러 마나 전소!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '시즈 탱크 포지션! 드라군 접근 불가!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '벌처 견제로 프로브 라인 괴롭히기!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -1,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '마린 스플릿! 스톰 피해 최소화!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -5,
    ),
    ClashEvent(
      text: '드랍십 투입! 본진 일꾼 학살!',
      favorsStat: 'harass',
      attackerArmy: -4,
      defenderArmy: -5,
      defenderResource: -35,
    ),
  ];

  /// PvT 전용 이벤트
  static const clashEventsPvT = [
    ClashEvent(
      text: '사이오닉 스톰! 바이오닉이 증발합니다!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -20,
    ),
    ClashEvent(
      text: '리버 드랍! SCV 라인 초토화!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -6,
      defenderResource: -40,
    ),
    ClashEvent(
      text: '드라군 사거리로 탱크 포커싱!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '다크템플러 투입! 감지기 없으면 끝!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -5,
      defenderResource: -30,
    ),
    ClashEvent(
      text: '옵저버로 상대 병력 완벽 파악!',
      favorsStat: 'scout',
      attackerArmy: -3,
      defenderArmy: -8,
    ),
  ];

  /// ZvP 전용 이벤트
  static const clashEventsZvP = [
    ClashEvent(
      text: '럴커로 질럿 학살!',
      favorsStat: 'defense',
      attackerArmy: -3,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '뮤탈로 커세어 견제 후 프로브 공략!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -4,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '히드라 물량으로 압박!',
      favorsStat: 'macro',
      attackerArmy: -10,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '디파일러 다크스웜! 리버 무력화!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -3,
    ),
    ClashEvent(
      text: '저글링 서라운드! 드라군 포위 섬멸!',
      favorsStat: 'control',
      attackerArmy: -10,
      defenderArmy: -15,
    ),
  ];

  /// PvZ 전용 이벤트
  static const clashEventsPvZ = [
    ClashEvent(
      text: '사이오닉 스톰! 히드라 편대 초토화!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -25,
    ),
    ClashEvent(
      text: '커세어로 오버로드 사냥! 서플라이 블락!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -5,
      defenderResource: -20,
    ),
    ClashEvent(
      text: '리버 드랍! 드론 라인 학살!',
      favorsStat: 'harass',
      attackerArmy: -2,
      defenderArmy: -8,
      defenderResource: -40,
    ),
    ClashEvent(
      text: '캐리어 진형! 저그 병력 접근 불가!',
      favorsStat: 'macro',
      attackerArmy: -5,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '아칸! 저글링 떼 소탕!',
      favorsStat: 'strategy',
      attackerArmy: -3,
      defenderArmy: -12,
    ),
  ];

  /// TvT 전용 이벤트
  static const clashEventsTvT = [
    ClashEvent(
      text: '탱크 라인 싸움! 포지션이 승부를 가릅니다!',
      favorsStat: 'strategy',
      attackerArmy: -12,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '레이스로 상대 탱크 라인 견제!',
      favorsStat: 'harass',
      attackerArmy: -3,
      defenderArmy: -8,
    ),
    ClashEvent(
      text: '고지대 점령! 유리한 포지션 확보!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -10,
    ),
    ClashEvent(
      text: '드랍십으로 뒤치기! 본진 탱크 무력화!',
      favorsStat: 'harass',
      attackerArmy: -5,
      defenderArmy: -8,
      defenderResource: -20,
    ),
    ClashEvent(
      text: '밸키리로 레이스 편대 격추!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
  ];

  /// ZvZ 전용 이벤트
  static const clashEventsZvZ = [
    ClashEvent(
      text: '저글링 컨트롤 싸움! 서라운드 성공!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '뮤탈 스택! 완벽한 뮤탈 매직!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '스커지로 뮤탈 요격!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -10,
    ),
    ClashEvent(
      text: '해처리 수 싸움! 물량 차이가 압도적!',
      favorsStat: 'macro',
      attackerArmy: -8,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '럴커로 저글링 차단!',
      favorsStat: 'defense',
      attackerArmy: -12,
      defenderArmy: -5,
    ),
  ];

  /// PvP 전용 이벤트
  static const clashEventsPvP = [
    ClashEvent(
      text: '드라군 마이크로 싸움! 포커싱 승리!',
      favorsStat: 'control',
      attackerArmy: -8,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '리버 스캐럽 작렬! 드라군 떼 박살!',
      favorsStat: 'control',
      attackerArmy: -5,
      defenderArmy: -15,
    ),
    ClashEvent(
      text: '다크템플러 투입! 옵저버 없으면 GG!',
      favorsStat: 'strategy',
      attackerArmy: -2,
      defenderArmy: -10,
      defenderResource: -25,
    ),
    ClashEvent(
      text: '아칸으로 질럿 제거!',
      favorsStat: 'strategy',
      attackerArmy: -5,
      defenderArmy: -12,
    ),
    ClashEvent(
      text: '셔틀 마이크로! 리버 생존 성공!',
      favorsStat: 'control',
      attackerArmy: -3,
      defenderArmy: -10,
    ),
  ];

  // ==================== 중후반 일반 이벤트 (빌드 스텝이 없을 때) ====================

  /// 멀티/확장 이벤트 (자원 증가)
  static const expansionEvents = [
    BuildStep(line: 0, text: '{player} 선수 멀티 확장 성공!', stat: 'macro', myResource: 25),
    BuildStep(line: 0, text: '{player}, 새로운 기지에서 자원 채취 시작!', stat: 'macro', myResource: 20),
    BuildStep(line: 0, text: '{player} 선수 자원 라인 풀가동!', stat: 'macro', myResource: 15),
    BuildStep(line: 0, text: '{player}, 확장 기지 완성! 경제력 상승!', stat: 'macro', myResource: 30),
    BuildStep(line: 0, text: '{player} 선수 일꾼 추가 생산!', stat: 'macro', myArmy: 1, myResource: 10),
    BuildStep(line: 0, text: '{player}, 가스 채취 가속!', stat: 'macro', myResource: 12),
    // 추가 확장 이벤트
    BuildStep(line: 0, text: '{player}, 3번째 멀티 가동!', stat: 'macro', myResource: 28),
    BuildStep(line: 0, text: '{player} 선수 히든 확장 성공!', stat: 'sense', myResource: 35),
    BuildStep(line: 0, text: '{player}, 앞마당 미네랄 채취 안정화!', stat: 'macro', myResource: 18),
    BuildStep(line: 0, text: '{player} 선수 가스 멀티 확보!', stat: 'macro', myResource: 22),
    BuildStep(line: 0, text: '{player}, 경제력 우위 확보 중!', stat: 'macro', myResource: 20),
    BuildStep(line: 0, text: '{player} 선수 일꾼 포화 상태!', stat: 'macro', myResource: 25),
    BuildStep(line: 0, text: '{player}, 4번째 확장 시도!', stat: 'macro', myResource: 30),
    BuildStep(line: 0, text: '{player} 선수 자원 수급 원활!', stat: 'macro', myResource: 16),
  ];

  /// 병력 생산 이벤트 (병력 증가)
  static const productionEvents = [
    BuildStep(line: 0, text: '{player} 선수 병력 추가 생산!', myArmy: 5, myResource: -15),
    BuildStep(line: 0, text: '{player}, 주력 유닛 보충 중!', myArmy: 4, myResource: -12),
    BuildStep(line: 0, text: '{player} 선수 물량 빌드업!', stat: 'macro', myArmy: 6, myResource: -18),
    BuildStep(line: 0, text: '{player}, 테크 유닛 생산!', stat: 'strategy', myArmy: 3, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 공격 유닛 대량 생산!', stat: 'attack', myArmy: 7, myResource: -22),
    // 추가 생산 이벤트
    BuildStep(line: 0, text: '{player}, 서플라이 늘리며 물량 보충!', myArmy: 5, myResource: -14),
    BuildStep(line: 0, text: '{player} 선수 더블 프로덕션!', stat: 'macro', myArmy: 8, myResource: -25),
    BuildStep(line: 0, text: '{player}, 지속적인 유닛 생산 중!', myArmy: 4, myResource: -13),
    BuildStep(line: 0, text: '{player} 선수 병력 꾸준히 보충!', myArmy: 5, myResource: -16),
    BuildStep(line: 0, text: '{player}, 생산 시설 풀가동!', stat: 'macro', myArmy: 7, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 최대 서플라이 향해 달려갑니다!', stat: 'macro', myArmy: 6, myResource: -18),
    BuildStep(line: 0, text: '{player}, 병력 손실분 빠르게 보충!', myArmy: 5, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 리플레이스먼트 생산!', myArmy: 4, myResource: -14),
    BuildStep(line: 0, text: '{player}, 다음 전투 준비 완료!', stat: 'attack', myArmy: 6, myResource: -17),
    BuildStep(line: 0, text: '{player} 선수 전선 유지용 병력 생산!', myArmy: 4, myResource: -12),
  ];

  /// 테크 업그레이드 이벤트
  static const techEvents = [
    BuildStep(line: 0, text: '{player} 선수 업그레이드 완료!', stat: 'strategy', myArmy: 2, myResource: -10),
    BuildStep(line: 0, text: '{player}, 공격력 업그레이드!', stat: 'attack', myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 방어력 업그레이드!', stat: 'defense', myResource: -15),
    BuildStep(line: 0, text: '{player}, 테크 트리 확장!', stat: 'strategy', myResource: -20),
    // 추가 테크 이벤트
    BuildStep(line: 0, text: '{player} 선수 2단계 업그레이드 진행!', stat: 'strategy', myArmy: 1, myResource: -18),
    BuildStep(line: 0, text: '{player}, 3-3 업그레이드 돌입!', stat: 'macro', myResource: -25),
    BuildStep(line: 0, text: '{player} 선수 특수 능력 업그레이드!', stat: 'strategy', myResource: -20),
    BuildStep(line: 0, text: '{player}, 이동속도 업그레이드 완료!', stat: 'control', myArmy: 1, myResource: -12),
    BuildStep(line: 0, text: '{player} 선수 사거리 업그레이드!', stat: 'attack', myArmy: 1, myResource: -15),
    BuildStep(line: 0, text: '{player}, 고급 테크 연구 시작!', stat: 'strategy', myResource: -22),
    BuildStep(line: 0, text: '{player} 선수 1-1 업그레이드 완료!', stat: 'macro', myArmy: 2, myResource: -12),
    BuildStep(line: 0, text: '{player}, 업그레이드로 전투력 강화!', stat: 'attack', myArmy: 2, myResource: -14),
  ];

  /// 소규모 교전 이벤트 (충돌 전 작은 전투)
  static const skirmishEvents = [
    BuildStep(line: 0, text: '{player} 선수 소규모 교전 승리!', stat: 'control', myArmy: -2, enemyArmy: -5),
    BuildStep(line: 0, text: '{player}, 정찰 유닛 교환!', stat: 'scout', myArmy: -1, enemyArmy: -2),
    BuildStep(line: 0, text: '{player} 선수 견제 성공!', stat: 'harass', myArmy: -1, enemyResource: -15),
    BuildStep(line: 0, text: '{player}, 상대 확장 견제!', stat: 'harass', enemyResource: -20),
    BuildStep(line: 0, text: '{player} 선수 상대 정찰 저지!', stat: 'defense', enemyArmy: -1),
    // 추가 교전 이벤트
    BuildStep(line: 0, text: '{player}, 맵 중앙에서 접전!', stat: 'control', myArmy: -3, enemyArmy: -4),
    BuildStep(line: 0, text: '{player} 선수 일꾼 견제 성공!', stat: 'harass', myArmy: -1, enemyResource: -18),
    BuildStep(line: 0, text: '{player}, 드랍십으로 견제!', stat: 'harass', myArmy: -2, enemyResource: -22),
    BuildStep(line: 0, text: '{player} 선수 전초전에서 우위!', stat: 'control', myArmy: -2, enemyArmy: -6),
    BuildStep(line: 0, text: '{player}, 상대 일꾼 라인 타격!', stat: 'harass', myArmy: -2, enemyResource: -25),
    BuildStep(line: 0, text: '{player} 선수 확장 저지 성공!', stat: 'harass', enemyResource: -30),
    BuildStep(line: 0, text: '{player}, 소규모 접전에서 이득!', stat: 'control', myArmy: -1, enemyArmy: -4),
    BuildStep(line: 0, text: '{player} 선수 언덕에서 유리한 교전!', stat: 'strategy', myArmy: -2, enemyArmy: -5),
    BuildStep(line: 0, text: '{player}, 상대 테크 건물 견제!', stat: 'harass', myArmy: -1, enemyResource: -20),
    BuildStep(line: 0, text: '{player} 선수 국지전 승리!', stat: 'control', myArmy: -3, enemyArmy: -6),
    BuildStep(line: 0, text: '{player}, 멀티 앞 수비 성공!', stat: 'defense', myArmy: -1, enemyArmy: -3),
    BuildStep(line: 0, text: '{player} 선수 상대 본진 견제!', stat: 'harass', myArmy: -3, enemyResource: -28),
  ];

  /// 중립/대치 이벤트 (변화 적음)
  static const neutralEvents = [
    BuildStep(line: 0, text: '양 선수 신중하게 운영 중입니다.', myResource: 5),
    BuildStep(line: 0, text: '팽팽한 대치 상황이 이어집니다.', myResource: 3),
    BuildStep(line: 0, text: '양측 모두 타이밍을 노리고 있습니다.', myResource: 4),
    BuildStep(line: 0, text: '조심스러운 움직임... 언제 터질지 모릅니다.', myResource: 3),
    BuildStep(line: 0, text: '양 선수 물량 축적 중입니다.', myArmy: 2, myResource: -3),
    // 추가 중립 이벤트 - 해설 스타일
    BuildStep(line: 0, text: '아직 본격적인 전투는 없습니다.', myResource: 4),
    BuildStep(line: 0, text: '양 선수 서로를 견제하며 운영 중입니다.', myResource: 5),
    BuildStep(line: 0, text: '긴장감이 감도는 가운데 경기가 진행됩니다.', myResource: 3),
    BuildStep(line: 0, text: '누가 먼저 움직일 것인가... 눈치 싸움입니다.', myResource: 4),
    BuildStep(line: 0, text: '양측 모두 안정적인 운영을 보여주고 있습니다.', myResource: 6),
    BuildStep(line: 0, text: '잠시 소강상태에 접어들었습니다.', myResource: 5),
    BuildStep(line: 0, text: '양 선수 다음 수를 고민하고 있습니다.', myResource: 4),
    BuildStep(line: 0, text: '전장에 긴장이 흐르고 있습니다.', myResource: 3),
    BuildStep(line: 0, text: '조용한 가운데 경제력 경쟁이 이어집니다.', myResource: 6),
    BuildStep(line: 0, text: '양측 최대한 손실을 줄이며 운영합니다.', myResource: 5),
    // 추가 중립 이벤트 - 상황 묘사
    BuildStep(line: 0, text: '맵 전체에 정적이 흐릅니다.', myResource: 4),
    BuildStep(line: 0, text: '폭풍 전야의 고요함입니다.', myResource: 3),
    BuildStep(line: 0, text: '양 선수 빌드 완성을 향해 달려갑니다.', myArmy: 1, myResource: 2),
    BuildStep(line: 0, text: '언제 터질지 모르는 상황... 긴장됩니다.', myResource: 4),
    BuildStep(line: 0, text: '전략적 대치가 이어지고 있습니다.', myResource: 5),
    BuildStep(line: 0, text: '양측 모두 실수하지 않으려 조심스럽습니다.', myResource: 4),
    BuildStep(line: 0, text: '상대의 움직임을 주시하고 있습니다.', myResource: 3),
    BuildStep(line: 0, text: '양 선수 물량 싸움을 준비합니다.', myArmy: 2, myResource: -2),
    BuildStep(line: 0, text: '다음 전투가 승부를 가를 수 있습니다.', myResource: 3),
    BuildStep(line: 0, text: '지금은 운영의 시간입니다.', myResource: 6),
  ];

  // ==================== 종족별 중후반 이벤트 ====================

  /// 테란 중후반 이벤트
  static const terranMidLateEvents = [
    BuildStep(line: 0, text: '{player} 선수 시즈 탱크 추가 생산!', stat: 'macro', myArmy: 5, myResource: -15),
    BuildStep(line: 0, text: '{player}, 베슬 생산으로 대공 강화!', stat: 'strategy', myArmy: 2, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 골리앗 대량 생산!', stat: 'defense', myArmy: 6, myResource: -18),
    BuildStep(line: 0, text: '{player}, 메카닉 업그레이드 완료!', stat: 'strategy', myArmy: 2, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 드랍십 추가 생산!', stat: 'harass', myArmy: 2, myResource: -15),
    BuildStep(line: 0, text: '{player}, 탱크 라인 전진! 고지대 점령!', stat: 'strategy', myArmy: -2, enemyArmy: -5),
    BuildStep(line: 0, text: '{player} 선수 발키리 생산!', stat: 'strategy', myArmy: 3, myResource: -18),
    BuildStep(line: 0, text: '{player}, 배틀크루저 생산 시작!', stat: 'macro', myArmy: 4, myResource: -30),
    BuildStep(line: 0, text: '{player} 선수 벙커 추가 건설!', stat: 'defense', myArmy: 1, myResource: -10),
    BuildStep(line: 0, text: '{player}, EMP 업그레이드 완료!', stat: 'strategy', myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 마인 매설 확대!', stat: 'defense', myArmy: 1, myResource: -8),
    BuildStep(line: 0, text: '{player}, 팩토리 추가 건설! 생산력 증가!', stat: 'macro', myArmy: 3, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 아머리 업그레이드 진행!', stat: 'strategy', myArmy: 1, myResource: -12),
    BuildStep(line: 0, text: '{player}, 벌처 스피드 업그레이드!', stat: 'control', myArmy: 2, myResource: -10),
    BuildStep(line: 0, text: '{player} 선수 터렛 라인 구축!', stat: 'defense', myArmy: 1, myResource: -10),
  ];

  /// 저그 중후반 이벤트
  static const zergMidLateEvents = [
    BuildStep(line: 0, text: '{player} 선수 뮤탈리스크 추가 생산!', stat: 'harass', myArmy: 6, myResource: -15),
    BuildStep(line: 0, text: '{player}, 디파일러 생산! 후반 준비!', stat: 'strategy', myArmy: 3, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 울트라리스크 생산!', stat: 'attack', myArmy: 5, myResource: -25),
    BuildStep(line: 0, text: '{player}, 럴커 추가 변태!', stat: 'defense', myArmy: 4, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 히드라리스크 물량 생산!', stat: 'macro', myArmy: 8, myResource: -20),
    BuildStep(line: 0, text: '{player}, 다크스웜 업그레이드 완료!', stat: 'strategy', myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 가디언 변태!', stat: 'strategy', myArmy: 4, myResource: -20),
    BuildStep(line: 0, text: '{player}, 디보러 변태! 적진 잠식!', stat: 'strategy', myArmy: 3, myResource: -18),
    BuildStep(line: 0, text: '{player} 선수 스커지 생산!', stat: 'attack', myArmy: 3, myResource: -10),
    BuildStep(line: 0, text: '{player}, 저글링 스피드 업그레이드!', stat: 'control', myArmy: 2, myResource: -10),
    BuildStep(line: 0, text: '{player} 선수 해처리 추가 건설!', stat: 'macro', myArmy: 2, myResource: -15),
    BuildStep(line: 0, text: '{player}, 오버로드 스피드 업그레이드!', stat: 'scout', myArmy: 1, myResource: -10),
    BuildStep(line: 0, text: '{player} 선수 저글링 대량 변태!', stat: 'attack', myArmy: 7, myResource: -15),
    BuildStep(line: 0, text: '{player}, 퀸 생산! 브루들링 준비!', stat: 'strategy', myArmy: 3, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 에볼루션 챔버 업그레이드!', stat: 'strategy', myArmy: 1, myResource: -12),
  ];

  /// 프로토스 중후반 이벤트
  static const protossMidLateEvents = [
    BuildStep(line: 0, text: '{player} 선수 하이템플러 생산!', stat: 'strategy', myArmy: 3, myResource: -15),
    BuildStep(line: 0, text: '{player}, 리버 추가 생산!', stat: 'harass', myArmy: 4, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 아칸 합체!', stat: 'strategy', myArmy: 4, myResource: -15),
    BuildStep(line: 0, text: '{player}, 캐리어 생산 시작!', stat: 'macro', myArmy: 5, myResource: -30),
    BuildStep(line: 0, text: '{player} 선수 옵저버 추가 생산!', stat: 'scout', myArmy: 1, myResource: -10),
    BuildStep(line: 0, text: '{player}, 스톰 준비 완료! 적 병력 초토화!', stat: 'strategy', myArmy: 1, enemyArmy: -8),
    BuildStep(line: 0, text: '{player} 선수 아비터 생산!', stat: 'strategy', myArmy: 3, myResource: -25),
    BuildStep(line: 0, text: '{player}, 드라군 사거리 업그레이드!', stat: 'attack', myArmy: 2, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 포지 업그레이드 진행!', stat: 'macro', myArmy: 1, myResource: -10),
    BuildStep(line: 0, text: '{player}, 다크템플러 생산!', stat: 'harass', myArmy: 3, myResource: -20),
    BuildStep(line: 0, text: '{player} 선수 셔틀 추가 생산!', stat: 'harass', myArmy: 1, myResource: -10),
    BuildStep(line: 0, text: '{player}, 질럿 다수 생산!', stat: 'attack', myArmy: 5, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 포톤캐논 방어선 구축!', stat: 'defense', myArmy: 1, myResource: -15),
    BuildStep(line: 0, text: '{player}, 코르세어 추가 생산!', stat: 'control', myArmy: 2, myResource: -15),
    BuildStep(line: 0, text: '{player} 선수 게이트웨이 추가 건설!', stat: 'macro', myArmy: 2, myResource: -20),
  ];

  // ==================== 유닛 키워드 필터링 ====================

  /// 빌드 스텝 텍스트에서 매칭할 유닛 키워드 목록
  static const _unitKeywords = [
    '드라군', '리버', '캐리어', '아비터', '다크템플러', '하이템플러', '아칸', '커세어', '코르세어', '셔틀',
    '시즈', '탱크', '벌처', '골리앗', '베슬', '드랍십', '발키리', '배틀크루저', '마인',
    '뮤탈', '럴커', '히드라', '울트라', '디파일러', '가디언', '스커지', '디보러', '퀸',
  ];

  /// 빌드의 스텝 텍스트에서 유닛 키워드를 추출
  static Set<String> extractUnitTags(BuildOrder build) {
    final tags = <String>{};
    for (final step in build.steps) {
      for (final keyword in _unitKeywords) {
        if (step.text.contains(keyword)) {
          tags.add(keyword);
        }
      }
    }
    return tags;
  }

  /// 이벤트 텍스트에 유닛 키워드가 포함되어 있으면, 해당 유닛이 availableUnits에 있어야 통과
  static bool _eventTextMatchesUnits(String text, Set<String> availableUnits) {
    for (final keyword in _unitKeywords) {
      if (text.contains(keyword) && !availableUnits.contains(keyword)) {
        return false;
      }
    }
    return true;
  }

  /// 중후반 이벤트 가져오기 (빌드 스텝이 없을 때 사용)
  /// [race] 종족 (T, Z, P)에 따라 종족 특화 이벤트 추가
  /// [rushDistance] 러시 거리 (짧으면 교전 이벤트 증가)
  /// [resources] 자원 풍부도 (높으면 확장 이벤트 증가)
  /// [terrainComplexity] 지형 복잡도 (높으면 전략 이벤트 증가)
  static BuildStep getMidLateEvent({
    required int lineCount,
    required int currentArmy,
    required int currentResource,
    required String race,
    int? rushDistance,
    int? resources,
    int? terrainComplexity,
    Random? random,
    Set<String>? availableUnits,
  }) {
    final rng = random ?? Random();

    // 상황에 따른 이벤트 가중치
    List<BuildStep> candidates = [];

    // 종족별 이벤트 추가
    List<BuildStep> raceEvents = [];
    switch (race) {
      case 'T':
        raceEvents = terranMidLateEvents;
        break;
      case 'Z':
        raceEvents = zergMidLateEvents;
        break;
      case 'P':
        raceEvents = protossMidLateEvents;
        break;
    }

    // 자원이 낮으면 확장/자원 이벤트 우선
    if (currentResource < 100) {
      candidates.addAll(expansionEvents);
      candidates.addAll(expansionEvents); // 가중치 2배
      candidates.addAll(neutralEvents);
      // 넓은 맵이면 확장 추가
      if (resources != null && resources >= 6) {
        candidates.addAll(expansionEvents);
      }
    }
    // 병력이 낮으면 생산 이벤트 우선
    else if (currentArmy < 60) {
      candidates.addAll(productionEvents);
      candidates.addAll(productionEvents); // 가중치 2배
      candidates.addAll(expansionEvents);
      candidates.addAll(raceEvents); // 종족 이벤트 추가
    }
    // 중반 (50줄 이전)
    else if (lineCount < 50) {
      candidates.addAll(expansionEvents);
      candidates.addAll(productionEvents);
      candidates.addAll(techEvents);
      candidates.addAll(skirmishEvents);
      candidates.addAll(neutralEvents);
      candidates.addAll(raceEvents); // 종족 이벤트 추가
      // 러시맵이면 교전 증가
      if (rushDistance != null && rushDistance <= 4) {
        candidates.addAll(skirmishEvents);
      }
    }
    // 중후반 (50~100줄)
    else if (lineCount < 100) {
      candidates.addAll(productionEvents);
      candidates.addAll(skirmishEvents);
      candidates.addAll(skirmishEvents); // 교전 증가
      candidates.addAll(techEvents);
      candidates.addAll(expansionEvents);
      candidates.addAll(raceEvents); // 종족 이벤트 추가
      candidates.addAll(raceEvents); // 종족 특화 가중치 2배
      // 복잡한 지형이면 전략 이벤트 증가
      if (terrainComplexity != null && terrainComplexity >= 7) {
        candidates.addAll(techEvents);
      }
    }
    // 후반 (100줄 이후)
    else {
      candidates.addAll(productionEvents);
      candidates.addAll(productionEvents);
      candidates.addAll(skirmishEvents);
      candidates.addAll(skirmishEvents);
      candidates.addAll(skirmishEvents); // 교전 빈번
      candidates.addAll(raceEvents); // 종족 이벤트 추가
      candidates.addAll(raceEvents);
      candidates.addAll(raceEvents); // 후반엔 종족 특화 3배
    }

    // 유닛 키워드 필터링: 빌드에 없는 유닛 관련 이벤트 제거
    if (availableUnits != null) {
      candidates.removeWhere((s) => !_eventTextMatchesUnits(s.text, availableUnits));
    }

    // 필터링 후 후보가 없으면 범용 이벤트(neutralEvents)에서 선택
    if (candidates.isEmpty) {
      candidates.addAll(neutralEvents);
      candidates.addAll(productionEvents);
    }

    // 랜덤 선택
    return candidates[rng.nextInt(candidates.length)];
  }

  // ==================== 헬퍼 메서드 ====================

  /// 매치업과 스타일에 맞는 빌드 선택
  static BuildOrder? getBuildOrder({
    required String race,
    required String vsRace,
    required BuildStyle preferredStyle,
  }) {
    List<BuildOrder> candidates;

    // 매치업에 맞는 빌드 목록
    final matchupKey = '${race}v$vsRace';
    switch (matchupKey) {
      case 'TvZ':
        candidates = terranVsZergBuilds;
        break;
      case 'TvP':
        candidates = terranVsProtossBuilds;
        break;
      case 'TvT':
        candidates = terranVsTerranBuilds;
        break;
      case 'ZvT':
        candidates = zergVsTerranBuilds;
        break;
      case 'ZvP':
        candidates = zergVsProtossBuilds;
        break;
      case 'ZvZ':
        candidates = zergVsZergBuilds;
        break;
      case 'PvT':
        candidates = protossVsTerranBuilds;
        break;
      case 'PvZ':
        candidates = protossVsZergBuilds;
        break;
      case 'PvP':
        candidates = protossVsProtossBuilds;
        break;
      default:
        return null;
    }

    // 선호 스타일과 일치하는 빌드 우선
    final preferred = candidates.where((b) => b.style == preferredStyle).toList();
    if (preferred.isNotEmpty) {
      return preferred[_random.nextInt(preferred.length)];
    }

    // 없으면 아무거나
    if (candidates.isNotEmpty) {
      return candidates[_random.nextInt(candidates.length)];
    }

    return null;
  }

  /// 충돌 이벤트 가져오기 (매치업별 적절한 이벤트만 반환)
  /// [map] 파라미터 추가하여 맵 특성에 따른 이벤트 포함
  /// [attackerStats], [defenderStats] 추가하여 능력치 기반 이벤트 포함
  static List<ClashEvent> getClashEvents(
    BuildStyle attackerStyle,
    BuildStyle defenderStyle, {
    String? attackerRace,
    String? defenderRace,
    int? rushDistance,
    int? resources,
    int? terrainComplexity,
    int? airAccessibility,
    int? centerImportance,
    bool? hasIsland,
    int? attackerAttack,
    int? attackerHarass,
    int? attackerControl,
    int? attackerStrategy,
    int? attackerMacro,
    int? attackerSense,
    int? defenderDefense,
    int? defenderStrategy,
    int? defenderMacro,
    int? defenderControl,
    int? defenderSense,
    BuildType? attackerBuildType,
    BuildType? defenderBuildType,
    Set<String>? availableUnits,
  }) {
    final baseEvents = <ClashEvent>[];

    // 기본 충돌 이벤트
    if (attackerStyle == BuildStyle.aggressive && defenderStyle == BuildStyle.defensive) {
      baseEvents.addAll(aggressiveVsDefensive);
    } else if (attackerStyle == BuildStyle.aggressive || defenderStyle == BuildStyle.aggressive) {
      baseEvents.addAll(aggressiveVsAggressive);
    } else {
      baseEvents.addAll(defensiveVsDefensive);
    }

    // 범용 이벤트 추가 (모든 경기에 적용)
    baseEvents.addAll(microEventsGeneral);
    baseEvents.addAll(mindGameEvents);
    baseEvents.addAll(spellEventsGeneral);

    // 맵 특성 기반 이벤트 추가
    if (rushDistance != null && rushDistance <= 4) {
      baseEvents.addAll(rushMapEvents);
    }
    if (rushDistance != null && resources != null && rushDistance >= 7 && resources >= 6) {
      baseEvents.addAll(macroMapEvents);
    }
    if (terrainComplexity != null && terrainComplexity >= 7) {
      baseEvents.addAll(complexTerrainEvents);
    }
    if (airAccessibility != null && airAccessibility >= 7) {
      baseEvents.addAll(airMapEvents);
    }
    if (hasIsland == true) {
      baseEvents.addAll(islandMapEvents);
    }
    if (centerImportance != null && centerImportance >= 7) {
      baseEvents.addAll(centerControlEvents);
    }

    // 능력치 특화 이벤트 추가 (고능력치 선수에게 해당 이벤트 확률 증가)
    if (attackerAttack != null && attackerAttack >= 700) {
      baseEvents.addAll(highAttackEvents);
    }
    if (attackerHarass != null && attackerHarass >= 700) {
      baseEvents.addAll(highHarassEvents);
    }
    if (attackerControl != null && attackerControl >= 700) {
      baseEvents.addAll(highControlEvents);
    }
    if (attackerStrategy != null && attackerStrategy >= 700) {
      baseEvents.addAll(highStrategyEvents);
    }
    if (attackerMacro != null && attackerMacro >= 700) {
      baseEvents.addAll(highMacroEvents);
    }
    if (attackerSense != null && attackerSense >= 700) {
      baseEvents.addAll(highSenseEvents);
    }
    if (defenderDefense != null && defenderDefense >= 700) {
      baseEvents.addAll(highDefenseEvents);
    }
    // 수비자의 고능력치 이벤트 추가 (수비자 우위 반영)
    if (defenderStrategy != null && defenderStrategy >= 700) {
      baseEvents.addAll(highDefenderStrategyEvents);
    }
    if (defenderMacro != null && defenderMacro >= 700) {
      baseEvents.addAll(highDefenderMacroEvents);
    }
    if (defenderControl != null && defenderControl >= 700) {
      baseEvents.addAll(highDefenderControlEvents);
    }
    if (defenderSense != null && defenderSense >= 700) {
      baseEvents.addAll(highDefenderSenseEvents);
    }

    // 빌드 타입별 전용 이벤트 추가 (15% 확률로 발생 가중치 증가)
    if (attackerBuildType != null) {
      final buildEvents = getBuildTypeEvents(attackerBuildType);
      baseEvents.addAll(buildEvents);
    }
    if (defenderBuildType != null) {
      final buildEvents = getBuildTypeEvents(defenderBuildType);
      baseEvents.addAll(buildEvents);
    }

    // 매치업별 종족 특화 이벤트 추가
    if (attackerRace != null && defenderRace != null) {
      // 매치업별 전용 이벤트 추가 (새로 추가된 부분)
      final matchup = '${attackerRace}v$defenderRace';
      switch (matchup) {
        case 'TvZ':
          baseEvents.addAll(clashEventsTvZ);
          break;
        case 'ZvT':
          baseEvents.addAll(clashEventsZvT);
          break;
        case 'TvP':
          baseEvents.addAll(clashEventsTvP);
          break;
        case 'PvT':
          baseEvents.addAll(clashEventsPvT);
          break;
        case 'ZvP':
          baseEvents.addAll(clashEventsZvP);
          break;
        case 'PvZ':
          baseEvents.addAll(clashEventsPvZ);
          break;
        case 'TvT':
          baseEvents.addAll(clashEventsTvT);
          break;
        case 'ZvZ':
          baseEvents.addAll(clashEventsZvZ);
          break;
        case 'PvP':
          baseEvents.addAll(clashEventsPvP);
          break;
      }

      // 저그 공격자
      if (attackerRace == 'Z') {
        baseEvents.addAll(microEventsZerg);
        // ZvT 전용
        if (defenderRace == 'T') {
          baseEvents.addAll(microEventsZvT);
          baseEvents.addAll(spellEventsZvT);
        }
      }

      // 테란 공격자
      if (attackerRace == 'T') {
        baseEvents.addAll(microEventsTerran);
        // TvZ 전용
        if (defenderRace == 'Z') {
          baseEvents.addAll(spellEventsTvZ);
        }
        // TvP 전용
        if (defenderRace == 'P') {
          baseEvents.addAll(spellEventsTvP);
        }
      }

      // 프로토스 공격자
      if (attackerRace == 'P') {
        baseEvents.addAll(microEventsProtoss);
        // PvT, PvZ 전용 (스톰)
        if (defenderRace == 'T' || defenderRace == 'Z') {
          baseEvents.addAll(spellEventsPvTZ);
        }
      }

      // 저그 수비자
      if (defenderRace == 'Z') {
        baseEvents.addAll(microEventsZerg);
        // TvZ에서 저그가 수비자일 때
        if (attackerRace == 'T') {
          baseEvents.addAll(microEventsZvT);
          baseEvents.addAll(spellEventsZvT);
        }
      }

      // 테란 수비자
      if (defenderRace == 'T') {
        baseEvents.addAll(microEventsTerran);
        if (attackerRace == 'Z') {
          baseEvents.addAll(spellEventsTvZ);
        }
        if (attackerRace == 'P') {
          baseEvents.addAll(spellEventsTvP);
        }
      }

      // 프로토스 수비자
      if (defenderRace == 'P') {
        baseEvents.addAll(microEventsProtoss);
        if (attackerRace == 'T' || attackerRace == 'Z') {
          baseEvents.addAll(spellEventsPvTZ);
        }
      }
    }

    // 견제형이면 종족별 드랍 이벤트 추가
    if (attackerStyle == BuildStyle.aggressive || attackerStyle == BuildStyle.cheese) {
      if (attackerRace == 'T') {
        baseEvents.addAll(dropEventsTerran);
      } else if (attackerRace == 'P') {
        baseEvents.addAll(dropEventsProtoss);
      } else if (attackerRace == 'Z') {
        baseEvents.addAll(dropEventsZerg);
      }
    }

    // 수비형이면 역전 이벤트 추가
    if (defenderStyle == BuildStyle.defensive) {
      baseEvents.addAll(comebackEvents);
      baseEvents.addAll(comebackDramaEvents);
    }

    // 프로리그 스타일 해설 이벤트 (모든 경기에 일부 확률로 추가)
    baseEvents.addAll(epicMomentEvents);
    baseEvents.addAll(tensionEvents);
    baseEvents.addAll(amazingPlayEvents);

    // 유닛 키워드 필터링: 빌드에 없는 유닛 관련 이벤트 제거
    if (availableUnits != null) {
      baseEvents.removeWhere((e) => !_eventTextMatchesUnits(e.text, availableUnits));
    }

    return baseEvents;
  }

  /// 경기 단계별 특수 이벤트 가져오기
  static ClashEvent? getSpecialEvent({
    required int lineCount,
    required String homeRace,
    required String awayRace,
    required int homeArmy,
    required int awayArmy,
  }) {
    // 병력 열세 역전 가능성
    if (homeArmy < awayArmy * 0.6 || awayArmy < homeArmy * 0.6) {
      // 10% 확률로 역전 이벤트
      if (_random.nextDouble() < 0.1) {
        return comebackEvents[_random.nextInt(comebackEvents.length)];
      }
    }

    // 중반 이후 스펠 이벤트
    if (lineCount >= 40) {
      if (_random.nextDouble() < 0.2) {
        return spellEventsGeneral[_random.nextInt(spellEventsGeneral.length)];
      }
    }

    return null;
  }
}
