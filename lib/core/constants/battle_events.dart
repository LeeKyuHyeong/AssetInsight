/// 전투 이벤트 데이터
///
/// 각 이벤트는 다음 정보를 포함:
/// - text: 이벤트 텍스트 ({player}는 해당 선수 이름으로 치환)
/// - stat: 이벤트 발생에 영향을 주는 능력치 (null이면 기본 확률)
/// - myArmy: 내 병력 변화
/// - myResource: 내 자원 변화
/// - enemyArmy: 상대 병력 변화
/// - enemyResource: 상대 자원 변화
/// - decisive: 결정적 이벤트 여부 (true면 즉시 승리)

/// 전투 이벤트
class BattleEvent {
  final String text;
  final String? stat; // 'sense', 'control', 'attack', 'harass', 'strategy', 'macro', 'defense', 'scout'
  final int myArmy;
  final int myResource;
  final int enemyArmy;
  final int enemyResource;
  final bool decisive;

  const BattleEvent({
    required this.text,
    this.stat,
    this.myArmy = 0,
    this.myResource = 0,
    this.enemyArmy = 0,
    this.enemyResource = 0,
    this.decisive = false,
  });
}

/// 매치업별 이벤트 데이터
class MatchupEvents {
  final List<BattleEvent> early;  // 1~30줄
  final List<BattleEvent> mid;    // 31~100줄
  final List<BattleEvent> late;   // 101~200줄

  const MatchupEvents({
    required this.early,
    required this.mid,
    required this.late,
  });
}

/// 전체 이벤트 데이터
class BattleEventsData {
  // ===== TvZ (테란 vs 저그, 테란 시점) =====
  static const tvzEarly = [
    BattleEvent(text: '{player} 선수 배럭 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 마린 생산 시작!', myArmy: 3, myResource: -5),
    BattleEvent(text: '{player} 선수 벙커 건설!', stat: 'defense', myResource: -15),
    BattleEvent(text: '{player} 선수 정찰 SCV 출발!', stat: 'scout'),
    BattleEvent(text: '{player}, 저글링 러쉬 감지!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 벙커로 저글링 방어!', stat: 'defense', myArmy: -2, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 벙커링 실패! 일꾼 피해!', stat: 'defense', myArmy: -5, myResource: -20, enemyArmy: -3),
    BattleEvent(text: '{player} 선수 팩토리 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 벌처로 일꾼 견제!', stat: 'harass', enemyResource: -25),
    BattleEvent(text: '{player} 선수 스파이더 마인 설치!', stat: 'strategy', myResource: -5),
    BattleEvent(text: '{player}, 마인으로 저글링 학살!', stat: 'strategy', enemyArmy: -12),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player}, 초반 올인 러쉬!', stat: 'attack', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player} 선수 올인 성공! 저그 본진 초토화!', stat: 'attack', enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const tvzMid = [
    BattleEvent(text: '{player} 선수 스타포트 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 레이스 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 레이스로 오버로드 사냥!', stat: 'harass', enemyArmy: -3),
    BattleEvent(text: '{player} 선수 드랍십 생산!', myArmy: 2, myResource: -15),
    BattleEvent(text: '{player}, 탱크 드랍 성공!', stat: 'harass', myArmy: -2, enemyArmy: -10, enemyResource: -30),
    BattleEvent(text: '{player}, 탱크 드랍 실패! 뮤탈에 격추!', stat: 'harass', myArmy: -8),
    BattleEvent(text: '{player} 선수 시즈모드 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 시즈탱크 포격 시작!', stat: 'attack', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 터렛 건설로 뮤탈 견제 대비!', stat: 'defense', myResource: -10),
    BattleEvent(text: '{player}, 뮤탈리스크 완벽하게 막아냅니다!', stat: 'defense', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 뮤탈에 일꾼 피해!', stat: 'defense', myResource: -25),
    BattleEvent(text: '{player}, 사이언스 베슬 생산!', myArmy: 2, myResource: -20),
    BattleEvent(text: '{player}, 이레디에이션으로 뮤탈 견제!', stat: 'strategy', enemyArmy: -10),
    BattleEvent(text: '{player} 선수 메카닉 전환!', stat: 'strategy', myResource: -30),
    BattleEvent(text: '{player}, 탱크 골리앗 조합 완성!', stat: 'macro', myArmy: 15, myResource: -40),
    BattleEvent(text: '{player} 선수 3번째 멀티 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 럴커 포진 포격으로 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 럴커에 막혀 진격 멈춤!', stat: 'sense', myArmy: -10, enemyArmy: -3),
    BattleEvent(text: '{player}, 스캔으로 럴커 발견!', stat: 'scout', myResource: -5),
    BattleEvent(text: '{player} 선수 푸시 나갑니다!', stat: 'attack'),
    BattleEvent(text: '{player}, 상대 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '{player}, 디파일러 등장에 푸시 중단!', stat: 'sense', myArmy: -5),
    BattleEvent(text: '{player} 선수 베슬로 디파일러 제거!', stat: 'control', enemyArmy: -5),
  ];

  static const tvzLate = [
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 다크스웜에 갇혔습니다!', stat: 'sense', myArmy: -15, enemyArmy: -5),
    BattleEvent(text: '{player}, 베슬 이레디로 디파일러 저격!', stat: 'control', enemyArmy: -8),
    BattleEvent(text: '{player} 선수 탱크 라인 완벽한 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 울트라리스크 막아냅니다!', stat: 'defense', myArmy: -10, enemyArmy: -25),
    BattleEvent(text: '{player} 선수 울트라에 탱크 라인 붕괴!', stat: 'defense', myArmy: -25, enemyArmy: -10),
    BattleEvent(text: '{player}, 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player} 선수 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 상대 일꾼 대량 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -50),
    BattleEvent(text: '{player} 선수 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player}, 뉴클리어 발사!', stat: 'strategy', myResource: -20, enemyArmy: -30, enemyResource: -30),
    BattleEvent(text: '{player} 선수 고스트 락다운 적중!', stat: 'control', enemyArmy: -10),
    BattleEvent(text: '{player}, 마린 스플릿으로 럴커 회피!', stat: 'control', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 디펜시브 매트릭스! 탱크 보호!', stat: 'strategy', myArmy: 2),
    BattleEvent(text: '{player}, 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 상대 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 상대 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 메카닉 물량으로 완벽한 승리!', decisive: true),
    BattleEvent(text: '자원이 고갈되어가고 있습니다! 양측 소모전!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 탱크 라인으로 최종 진격!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 저그 본진 함락!', decisive: true),
  ];

  // ===== ZvT (저그 vs 테란, 저그 시점) =====
  static const zvtEarly = [
    BattleEvent(text: '{player} 선수 해처리 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 스포닝풀 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 저글링 생산 시작!', myArmy: 4, myResource: -5),
    BattleEvent(text: '{player} 선수 오버로드 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 벙커링 감지!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 저글링 러쉬!', stat: 'attack'),
    BattleEvent(text: '{player}, 저글링으로 일꾼 학살!', stat: 'attack', myArmy: -3, enemyArmy: -5, enemyResource: -25),
    BattleEvent(text: '{player} 선수 저글링 러쉬 실패!', stat: 'attack', myArmy: -8, enemyArmy: -2),
    BattleEvent(text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player} 선수 히드라덴 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 히드라리스크 생산!', myArmy: 5, myResource: -10),
    BattleEvent(text: '{player}, 벌처 견제 막아냅니다!', stat: 'defense', myArmy: -3, enemyArmy: -4),
    BattleEvent(text: '{player} 선수 벌처에 일꾼 피해!', stat: 'defense', myResource: -20),
    BattleEvent(text: '{player}, 마인 피해 최소화!', stat: 'sense', myArmy: -2),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player} 선수 올인 성공! 테란 본진 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const zvtMid = [
    BattleEvent(text: '{player} 선수 레어 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 스파이어 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 뮤탈리스크 생산!', myArmy: 6, myResource: -15),
    BattleEvent(text: '{player}, 뮤탈로 일꾼 견제!', stat: 'harass', enemyResource: -30),
    BattleEvent(text: '{player} 선수 뮤탈 매직!', stat: 'control', enemyArmy: -10),
    BattleEvent(text: '{player}, 뮤탈 터렛에 피해!', stat: 'control', myArmy: -8),
    BattleEvent(text: '{player} 선수 럴커 변태!', stat: 'strategy', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 럴커로 테란 진격 저지!', stat: 'defense', enemyArmy: -12),
    BattleEvent(text: '{player} 선수 럴커 포진 완료!', stat: 'strategy'),
    BattleEvent(text: '{player}, 탱크 포격에 럴커 피해!', stat: 'defense', myArmy: -10),
    BattleEvent(text: '{player} 선수 스커지 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 스커지로 베슬 격추!', stat: 'control', myArmy: -4, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 드랍 방어 성공!', stat: 'defense', myArmy: -2, enemyArmy: -8),
    BattleEvent(text: '{player}, 드랍에 일꾼 피해!', stat: 'defense', myResource: -30),
    BattleEvent(text: '{player} 선수 4번째 해처리 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 저글링 런바이 성공!', stat: 'harass', myArmy: -5, enemyResource: -35),
    BattleEvent(text: '{player} 선수 테란 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player}, 디파일러덴 건설!', stat: 'strategy', myResource: -20),
    BattleEvent(text: '{player} 선수 디파일러 생산!', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player}, 다크스웜 전개!', stat: 'strategy'),
    BattleEvent(text: '{player} 선수 플레이그 적중!', stat: 'strategy', enemyArmy: -15),
    BattleEvent(text: '{player}, 상대 탱크 라인 무력화!', stat: 'strategy', enemyArmy: -10),
  ];

  static const zvtLate = [
    BattleEvent(text: '{player} 선수 울트라리스크 캐번 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 울트라리스크 생산!', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player}, 울트라로 탱크 라인 돌파!', stat: 'attack', myArmy: -8, enemyArmy: -25),
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 저그 물량 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 디파일러 컨슘!', stat: 'strategy', myArmy: -2),
    BattleEvent(text: '{player}, 다크스웜으로 탱크 무력화!', stat: 'strategy', enemyArmy: -5),
    BattleEvent(text: '{player} 선수 이레디 피해!', stat: 'sense', myArmy: -12),
    BattleEvent(text: '{player}, 디파일러 재생산!', stat: 'macro', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player} 선수 멀티 동시 공격!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 저글링으로 일꾼 초토화!', stat: 'harass', myArmy: -3, enemyResource: -50),
    BattleEvent(text: '{player} 선수 자원 우위 압도적!', stat: 'macro', myResource: 40),
    BattleEvent(text: '{player}, 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player} 선수 테란 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 테란 본진 파괴!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 디파일러 조합으로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 멀티가 바닥나고 있습니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 울트라 물량으로 최종 돌파!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 테란 본진 함락!', decisive: true),
  ];

  // ===== TvP (테란 vs 프로토스, 테란 시점) =====
  static const tvpEarly = [
    BattleEvent(text: '{player} 선수 배럭 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 마린 생산 시작!', myArmy: 3, myResource: -5),
    BattleEvent(text: '{player} 선수 정찰 SCV 출발!', stat: 'scout'),
    BattleEvent(text: '{player}, 게이트웨이 타이밍 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 팩토리 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 벌처로 프로브 견제!', stat: 'harass', enemyResource: -25),
    BattleEvent(text: '{player} 선수 벌처 견제 실패!', stat: 'harass', myArmy: -4),
    BattleEvent(text: '{player}, 스파이더 마인 설치!', stat: 'strategy', myResource: -5),
    BattleEvent(text: '{player} 선수 마인으로 질럿 처리!', stat: 'strategy', enemyArmy: -6),
    BattleEvent(text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player}, 질럿 러쉬 방어 성공!', stat: 'defense', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 질럿에 일꾼 피해!', stat: 'defense', myResource: -20, enemyArmy: -2),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 초반 푸시 성공! 프로토스 본진 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const tvpMid = [
    BattleEvent(text: '{player} 선수 아머리 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 골리앗 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 탱크 골리앗 조합 완성!', stat: 'macro', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player} 선수 시즈모드 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 시즈탱크 포격 시작!', stat: 'attack', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 리버 드랍 방어!', stat: 'defense', myArmy: -5, enemyArmy: -3),
    BattleEvent(text: '{player}, 리버에 일꾼 피해!', stat: 'defense', myResource: -35),
    BattleEvent(text: '{player} 선수 터렛 건설!', stat: 'defense', myResource: -10),
    BattleEvent(text: '{player}, 다크템플러 감지!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 다크에 일꾼 피해!', stat: 'sense', myResource: -30),
    BattleEvent(text: '{player}, 스캔으로 다크 처리!', stat: 'scout', myResource: -5, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 3번째 멀티 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 벌처로 프로브 학살!', stat: 'harass', myArmy: -2, enemyResource: -40),
    BattleEvent(text: '{player} 선수 상대 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 탱크 라인으로 밀어붙입니다!', stat: 'attack', myArmy: -5, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 스톰에 병력 피해!', stat: 'sense', myArmy: -15),
    BattleEvent(text: '{player}, 스플릿으로 스톰 회피!', stat: 'control', myArmy: -5),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '{player}, EMP 적중!', stat: 'strategy', myResource: -10, enemyArmy: -8),
  ];

  static const tvpLate = [
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 아비터 스테이시스 피해!', stat: 'sense', myArmy: -10),
    BattleEvent(text: '{player}, EMP로 아비터 무력화!', stat: 'strategy', myResource: -10, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 캐리어 등장에 고전!', stat: 'sense', myArmy: -12, enemyArmy: -3),
    BattleEvent(text: '{player}, 골리앗으로 캐리어 격추!', stat: 'control', myArmy: -8, enemyArmy: -15),
    BattleEvent(text: '{player} 선수 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player} 선수 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player}, 뉴클리어 발사!', stat: 'strategy', myResource: -20, enemyArmy: -30, enemyResource: -30),
    BattleEvent(text: '{player} 선수 EMP로 실드 전부 벗겨냅니다!', stat: 'control', enemyArmy: -12),
    BattleEvent(text: '{player}, 고스트 락다운으로 아비터 무력화!', stat: 'strategy', enemyArmy: -8),
    BattleEvent(text: '{player} 선수 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player}, 상대 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 프로토스 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 EMP 사이언스로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 가스가 부족해지고 있습니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 골리앗 탱크로 최종 밀어붙입니다!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 프로토스 본진 함락!', decisive: true),
  ];

  // ===== PvT (프로토스 vs 테란, 프로토스 시점) =====
  static const pvtEarly = [
    BattleEvent(text: '{player} 선수 게이트웨이 건설합니다.', myResource: -15),
    BattleEvent(text: '{player} 선수 질럿 생산 시작!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player} 선수 프로브 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 팩토리 타이밍 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 사이버네틱스 코어 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 드라군 생산!', myArmy: 5, myResource: -12),
    BattleEvent(text: '{player}, 질럿으로 일꾼 견제!', stat: 'harass', myArmy: -2, enemyResource: -20),
    BattleEvent(text: '{player} 선수 앞마당 넥서스 건설!', stat: 'macro', myResource: -40),
    BattleEvent(text: '{player}, 벌처 견제 방어!', stat: 'defense', myArmy: -3, enemyArmy: -4),
    BattleEvent(text: '{player} 선수 벌처에 프로브 피해!', stat: 'defense', myResource: -25),
    BattleEvent(text: '{player}, 마인 피해 최소화!', stat: 'sense', myArmy: -2),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player} 선수 로보틱스 건설!', myResource: -20),
    BattleEvent(text: '{player}, 초반 질럿 러쉬 성공!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const pvtMid = [
    BattleEvent(text: '{player} 선수 리버 생산!', myArmy: 5, myResource: -20),
    BattleEvent(text: '{player}, 리버 드랍 출발!', stat: 'harass'),
    BattleEvent(text: '{player} 선수 리버 드랍 성공!', stat: 'harass', myArmy: -2, enemyArmy: -8, enemyResource: -35),
    BattleEvent(text: '{player}, 리버 드랍 실패!', stat: 'harass', myArmy: -7),
    BattleEvent(text: '{player} 선수 옵저버 생산!', myArmy: 1, myResource: -10),
    BattleEvent(text: '{player}, 드라군 사거리 업그레이드!', stat: 'strategy', myResource: -15),
    BattleEvent(text: '{player} 선수 드라군으로 탱크 견제!', stat: 'control', myArmy: -5, enemyArmy: -8),
    BattleEvent(text: '{player}, 탱크 포격에 드라군 피해!', stat: 'defense', myArmy: -12),
    BattleEvent(text: '{player} 선수 템플러 아카이브 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 하이템플러 생산!', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player}, 사이오닉 스톰!', stat: 'strategy', enemyArmy: -20),
    BattleEvent(text: '{player} 선수 스톰으로 바이오닉 초토화!', stat: 'control', enemyArmy: -25),
    BattleEvent(text: '{player}, 다크템플러 투입!', stat: 'strategy', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player} 선수 다크로 일꾼 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 다크 스캔에 발각!', stat: 'sense', myArmy: -5),
    BattleEvent(text: '{player} 선수 3번째 넥서스 확장!', stat: 'macro', myResource: -40),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 상대 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '{player}, 아칸 합체!', stat: 'strategy', myArmy: 8),
  ];

  static const pvtLate = [
    BattleEvent(text: '{player} 선수 스타게이트 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 캐리어 생산!', myArmy: 10, myResource: -40),
    BattleEvent(text: '{player}, 캐리어 함대 완성!', stat: 'macro', myArmy: 15, myResource: -50),
    BattleEvent(text: '{player} 선수 아비터 생산!', myArmy: 5, myResource: -25),
    BattleEvent(text: '{player}, 리콜 투입!', stat: 'strategy', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 스테이시스 필드!', stat: 'strategy', enemyArmy: -10),
    BattleEvent(text: '{player}, 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player} 선수 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player}, EMP에 실드 피해!', stat: 'sense', myArmy: -15),
    BattleEvent(text: '{player} 선수 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player} 선수 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player}, 하이템플러 머지! 아칸 완성!', stat: 'strategy', myArmy: 8),
    BattleEvent(text: '{player} 선수 사이오닉 스톰 난무! 바이오닉 초토화!', stat: 'control', enemyArmy: -18),
    BattleEvent(text: '{player}, 스테이시스 필드로 병력 분리!', stat: 'strategy', enemyArmy: -8),
    BattleEvent(text: '{player}, 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 테란 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 테란 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 스톰 아칸으로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 고급 유닛 소모가 심합니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 캐리어 함대로 최종 진격!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 테란 멀티 전부 파괴!', decisive: true),
  ];

  // ===== ZvP (저그 vs 프로토스, 저그 시점) =====
  static const zvpEarly = [
    BattleEvent(text: '{player} 선수 해처리 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 스포닝풀 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 저글링 생산 시작!', myArmy: 4, myResource: -5),
    BattleEvent(text: '{player} 선수 오버로드 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 포지 타이밍 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player}, 3해처리 운영!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player} 선수 히드라덴 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 히드라리스크 생산!', myArmy: 5, myResource: -10),
    BattleEvent(text: '{player}, 질럿 견제 방어!', stat: 'defense', myArmy: -3, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 포톤캐논에 저글링 피해!', stat: 'defense', myArmy: -5),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player}, 저글링 런바이 성공!', stat: 'harass', myArmy: -3, enemyResource: -25),
    BattleEvent(text: '{player} 선수 히드라 올인!', stat: 'attack', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player}, 히드라 올인 성공! 프로토스 본진 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const zvpMid = [
    BattleEvent(text: '{player} 선수 레어 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 스파이어 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 뮤탈리스크 생산!', myArmy: 6, myResource: -15),
    BattleEvent(text: '{player}, 뮤탈로 프로브 견제!', stat: 'harass', enemyResource: -30),
    BattleEvent(text: '{player} 선수 뮤탈 매직!', stat: 'control', enemyArmy: -10),
    BattleEvent(text: '{player}, 커세어에 뮤탈 피해!', stat: 'control', myArmy: -10, enemyArmy: -3),
    BattleEvent(text: '{player} 선수 럴커 변태!', stat: 'strategy', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 럴커로 질럿 학살!', stat: 'defense', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 럴커 포진 완료!', stat: 'strategy'),
    BattleEvent(text: '{player}, 리버에 럴커 피해!', stat: 'defense', myArmy: -12),
    BattleEvent(text: '{player} 선수 스커지 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 스커지로 셔틀 격추!', stat: 'control', myArmy: -4, enemyArmy: -10),
    BattleEvent(text: '{player} 선수 4번째 해처리 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 저글링 런바이로 프로브 학살!', stat: 'harass', myArmy: -5, enemyResource: -35),
    BattleEvent(text: '{player} 선수 프로토스 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player}, 스톰에 히드라 피해!', stat: 'sense', myArmy: -15),
    BattleEvent(text: '{player} 선수 스톰 범위 벗어남!', stat: 'control', myArmy: -5),
    BattleEvent(text: '{player}, 하이브 건설!', stat: 'strategy', myResource: -25),
    BattleEvent(text: '{player} 선수 디파일러 생산!', myArmy: 3, myResource: -15),
  ];

  static const zvpLate = [
    BattleEvent(text: '{player} 선수 울트라리스크 생산!', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player}, 울트라로 질럿 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 저그 물량 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 다크스웜 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 플레이그로 캐리어 피해!', stat: 'strategy', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 스톰에 큰 피해!', stat: 'sense', myArmy: -20),
    BattleEvent(text: '{player}, 디파일러로 스톰 무력화!', stat: 'strategy', myArmy: -2, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 멀티 동시 공격!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 저글링으로 프로브 초토화!', stat: 'harass', myArmy: -3, enemyResource: -50),
    BattleEvent(text: '{player} 선수 자원 우위 압도적!', stat: 'macro', myResource: 40),
    BattleEvent(text: '{player}, 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player} 선수 프로토스 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 프로토스 본진 파괴!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 디파일러 울트라로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 멀티가 바닥나고 있습니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 저글링 물량으로 프로토스 멀티 초토화!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 프로토스 본진 함락!', decisive: true),
  ];

  // ===== PvZ (프로토스 vs 저그, 프로토스 시점) =====
  static const pvzEarly = [
    BattleEvent(text: '{player} 선수 넥서스 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 포지 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 포톤캐논 건설!', stat: 'defense', myResource: -15),
    BattleEvent(text: '{player} 선수 프로브 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 해처리 타이밍 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 게이트웨이 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 질럿 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 저글링 러쉬 방어!', stat: 'defense', myArmy: -2, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 앞마당 넥서스 건설!', stat: 'macro', myResource: -40),
    BattleEvent(text: '{player}, 저글링 런바이 방어!', stat: 'defense', myArmy: -3, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 런바이에 프로브 피해!', stat: 'defense', myResource: -20, enemyArmy: -2),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player} 선수 사이버네틱스 코어 건설!', myResource: -15),
    BattleEvent(text: '{player}, 초반 질럿 러쉬 성공!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
  ];

  static const pvzMid = [
    BattleEvent(text: '{player} 선수 스타게이트 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 커세어 생산!', myArmy: 4, myResource: -15),
    BattleEvent(text: '{player}, 커세어로 오버로드 사냥!', stat: 'harass', enemyArmy: -3),
    BattleEvent(text: '{player} 선수 로보틱스 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 리버 생산!', myArmy: 5, myResource: -20),
    BattleEvent(text: '{player}, 리버 드랍 출발!', stat: 'harass'),
    BattleEvent(text: '{player} 선수 리버 드랍 성공!', stat: 'harass', myArmy: -2, enemyArmy: -10, enemyResource: -35),
    BattleEvent(text: '{player}, 리버 드랍 실패!', stat: 'harass', myArmy: -7),
    BattleEvent(text: '{player} 선수 템플러 아카이브 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 하이템플러 생산!', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player}, 사이오닉 스톰!', stat: 'strategy', enemyArmy: -25),
    BattleEvent(text: '{player} 선수 스톰으로 히드라 초토화!', stat: 'control', enemyArmy: -30),
    BattleEvent(text: '{player}, 다크템플러 투입!', stat: 'strategy', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player} 선수 다크로 드론 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 다크 오버로드에 발각!', stat: 'sense', myArmy: -5),
    BattleEvent(text: '{player} 선수 3번째 넥서스 확장!', stat: 'macro', myResource: -40),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 상대 해처리 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '{player}, 아칸 합체!', stat: 'strategy', myArmy: 8),
  ];

  static const pvzLate = [
    BattleEvent(text: '{player} 선수 캐리어 생산!', myArmy: 10, myResource: -40),
    BattleEvent(text: '{player}, 캐리어 함대 완성!', stat: 'macro', myArmy: 15, myResource: -50),
    BattleEvent(text: '{player} 선수 아비터 생산!', myArmy: 5, myResource: -25),
    BattleEvent(text: '{player}, 리콜 투입!', stat: 'strategy', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 다크스웜에 갇힘!', stat: 'sense', myArmy: -10, enemyArmy: -3),
    BattleEvent(text: '{player}, 스톰으로 다크스웜 안 저그 처리!', stat: 'control', enemyArmy: -20),
    BattleEvent(text: '{player} 선수 플레이그 피해!', stat: 'sense', myArmy: -15),
    BattleEvent(text: '{player}, 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player} 선수 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player} 선수 스톰으로 히드라 무리 초토화!', stat: 'control', enemyArmy: -18),
    BattleEvent(text: '{player}, 하이템플러 머지! 아칸 돌진!', stat: 'strategy', myArmy: 8, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player}, 저그 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 저그 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 스톰 리콜로 완벽한 승리!', decisive: true),
    BattleEvent(text: '후반 가스 부족! 양측 인터셉터도 줄어듭니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 아칸 드라군으로 저그 멀티 전부 파괴!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 저그 본진 함락!', decisive: true),
  ];

  // ===== TvT (테란 동족전) =====
  static const tvtEarly = [
    BattleEvent(text: '{player} 선수 배럭 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 마린 생산 시작!', myArmy: 3, myResource: -5),
    BattleEvent(text: '{player} 선수 정찰 SCV 출발!', stat: 'scout'),
    BattleEvent(text: '{player}, 상대 빌드 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 팩토리 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 벌처 생산!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player}, 벌처로 SCV 견제!', stat: 'harass', enemyResource: -20),
    BattleEvent(text: '{player} 선수 마인 설치!', stat: 'strategy', myResource: -5),
    BattleEvent(text: '{player}, 마인으로 벌처 처리!', stat: 'strategy', enemyArmy: -4),
    BattleEvent(text: '{player} 선수 시즈탱크 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player} 선수 앞마당 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양 선수 초반 안정적으로 운영 중입니다.', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player}, 초반 벌처 러쉬 성공!', stat: 'attack', myArmy: -3, enemyArmy: -10, enemyResource: -30),
    BattleEvent(text: '{player} 선수 초반 올인 성공!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 아카데미 건설! 메딕 준비!', stat: 'strategy', myResource: -15),
    BattleEvent(text: '{player}, 커맨드 센터 앞마당 착지!', stat: 'macro', myResource: -25),
    BattleEvent(text: '{player} 선수 엔지니어링 베이! 터렛 대비!', stat: 'defense', myResource: -10),
  ];

  static const tvtMid = [
    BattleEvent(text: '{player} 선수 스타포트 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 레이스 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 레이스로 SCV 견제!', stat: 'harass', enemyResource: -25),
    BattleEvent(text: '{player} 선수 드랍십 생산!', myArmy: 2, myResource: -15),
    BattleEvent(text: '{player}, 탱크 드랍 성공!', stat: 'harass', myArmy: -2, enemyArmy: -10, enemyResource: -30),
    BattleEvent(text: '{player}, 탱크 드랍 실패!', stat: 'harass', myArmy: -8),
    BattleEvent(text: '{player} 선수 시즈모드 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 시즈탱크 포격전!', stat: 'attack', myArmy: -5, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 고지대 선점!', stat: 'strategy'),
    BattleEvent(text: '{player}, 고지대에서 포격!', stat: 'attack', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 골리앗 생산!', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 레이스 견제 방어!', stat: 'defense', myArmy: -3, enemyArmy: -5),
    BattleEvent(text: '{player} 선수 3번째 멀티 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 탱크 라인 대치 중입니다!', myResource: 5, enemyResource: 5),
    BattleEvent(text: '{player}, 상대 탱크 라인 돌파!', stat: 'attack', myArmy: -10, enemyArmy: -15),
    BattleEvent(text: '{player} 선수 탱크 라인 붕괴!', stat: 'defense', myArmy: -15, enemyArmy: -5),
    BattleEvent(text: '{player}, 상대 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '치열한 탱크전이 이어집니다!', myArmy: -5, enemyArmy: -5),
    BattleEvent(text: '{player}, 사이언스 베슬 이레디에이트!', stat: 'strategy', enemyArmy: -8),
    BattleEvent(text: '{player} 선수 벌처 마인 매설! 상대 진격로 차단!', stat: 'strategy', myResource: -5),
    BattleEvent(text: '{player}, 클로킹 레이스로 커맨드 센터 견제!', stat: 'harass', enemyResource: -25),
    BattleEvent(text: '{player} 선수 메딕 마린 기동! 벌처 처리!', stat: 'control', myArmy: -3, enemyArmy: -6),
  ];

  static const tvtLate = [
    BattleEvent(text: '{player} 선수 배틀크루저 생산!', myArmy: 10, myResource: -40),
    BattleEvent(text: '{player}, 배틀크루저 야마토!', stat: 'strategy', myResource: -10, enemyArmy: -15),
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 뉴클리어 발사!', stat: 'strategy', myResource: -20, enemyArmy: -30, enemyResource: -30),
    BattleEvent(text: '{player}, 상대 탱크 라인 초토화!', stat: 'attack', myArmy: -5, enemyArmy: -25),
    BattleEvent(text: '{player} 선수 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player} 선수 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player}, 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 상대 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 상대 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 탱크 라인 우위로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 가스 기지가 고갈되고 있습니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 배틀크루저로 최종 결전!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 상대 커맨드 전부 파괴!', decisive: true),
    BattleEvent(text: '{player}, 고스트 뉴클리어 유도!', stat: 'strategy', myResource: -15, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 발키리 편대로 레이스 소탕!', stat: 'control', myArmy: -3, enemyArmy: -10),
    BattleEvent(text: '{player}, 드랍십 멀티 기습! 자원 약탈!', stat: 'harass', myArmy: -3, enemyResource: -35),
  ];

  // ===== ZvZ (저그 동족전) =====
  static const zvzEarly = [
    BattleEvent(text: '{player} 선수 해처리 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 스포닝풀 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 저글링 생산 시작!', myArmy: 4, myResource: -5),
    BattleEvent(text: '{player} 선수 오버로드 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 상대 풀 타이밍 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 저글링 러쉬!', stat: 'attack'),
    BattleEvent(text: '{player}, 저글링 싸움 승리!', stat: 'control', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 저글링 싸움 패배!', stat: 'control', myArmy: -8, enemyArmy: -3),
    BattleEvent(text: '{player}, 드론 학살!', stat: 'attack', myArmy: -2, enemyResource: -25),
    BattleEvent(text: '{player} 선수 앞마당 해처리 건설!', stat: 'macro', myResource: -30),
    BattleEvent(text: '{player}, 선풀 저글링 압박!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '양 선수 초반 저글링전 치열합니다!', myArmy: -3, enemyArmy: -3),
    BattleEvent(text: '{player} 선수 초반 올인 성공!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 성큰 건설! 저글링 방어 준비!', stat: 'defense', myResource: -10),
    BattleEvent(text: '{player}, 익스트랙터 트릭으로 저글링 한 마리 더!', stat: 'sense', myArmy: 1),
    BattleEvent(text: '{player} 선수 저글링 서라운드! 상대 일꾼 차단!', stat: 'control', enemyResource: -15),
  ];

  static const zvzMid = [
    BattleEvent(text: '{player} 선수 레어 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 스파이어 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 뮤탈리스크 생산!', myArmy: 6, myResource: -15),
    BattleEvent(text: '{player}, 뮤탈 싸움 승리!', stat: 'control', myArmy: -5, enemyArmy: -12),
    BattleEvent(text: '{player} 선수 뮤탈 싸움 패배!', stat: 'control', myArmy: -12, enemyArmy: -5),
    BattleEvent(text: '{player}, 뮤탈 매직!', stat: 'control', enemyArmy: -10),
    BattleEvent(text: '{player} 선수 뮤탈로 드론 견제!', stat: 'harass', enemyResource: -30),
    BattleEvent(text: '{player}, 스커지로 뮤탈 격추!', stat: 'control', myArmy: -4, myResource: -10, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 럴커 변태!', stat: 'strategy', myArmy: 5, myResource: -15),
    BattleEvent(text: '{player}, 럴커로 저글링 학살!', stat: 'defense', enemyArmy: -15),
    BattleEvent(text: '{player} 선수 4번째 해처리 확장!', stat: 'macro', myResource: -30),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 저글링 런바이 성공!', stat: 'harass', myArmy: -5, enemyResource: -35),
    BattleEvent(text: '{player} 선수 상대 해처리 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player}, 하이브 건설!', stat: 'strategy', myResource: -25),
    BattleEvent(text: '{player} 선수 디파일러 생산!', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player}, 뮤탈 히트앤런으로 해처리 견제!', stat: 'harass', enemyResource: -20),
    BattleEvent(text: '{player} 선수 스커지 매복! 뮤탈 기습!', stat: 'sense', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player}, 저글링으로 멀티 해처리 급습!', stat: 'attack', myArmy: -4, enemyResource: -30),
    BattleEvent(text: '{player} 선수 성큰 라인 구축! 철벽 수비!', stat: 'defense', myResource: -15),
    BattleEvent(text: '{player}, 가디언으로 성큰 제거!', stat: 'strategy', myArmy: -2, enemyArmy: -5),
  ];

  static const zvzLate = [
    BattleEvent(text: '{player} 선수 울트라리스크 생산!', myArmy: 10, myResource: -30),
    BattleEvent(text: '{player}, 울트라로 럴커 돌파!', stat: 'attack', myArmy: -5, enemyArmy: -15),
    BattleEvent(text: '{player} 선수 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player}, 대규모 저그 물량 진격!', stat: 'attack'),
    BattleEvent(text: '{player} 선수 다크스웜 전개!', stat: 'strategy'),
    BattleEvent(text: '{player}, 플레이그 적중!', stat: 'strategy', enemyArmy: -20),
    BattleEvent(text: '{player} 선수 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 멀티 동시 공격!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player} 선수 자원 우위 압도적!', stat: 'macro', myResource: 40),
    BattleEvent(text: '{player}, 상대 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 상대 본진 파괴!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 뮤탈 제공권 장악으로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 미네랄이 바닥나고 있습니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 가디언 물량으로 상대 해처리 전부 파괴!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 상대 해처리 전부 파괴!', decisive: true),
    BattleEvent(text: '{player}, 디파일러 다크스웜으로 저글링 돌격!', stat: 'strategy', myArmy: -8, enemyArmy: -12),
    BattleEvent(text: '{player} 선수 가디언 편대로 성큰 라인 파괴!', stat: 'attack', myArmy: -3, enemyArmy: -10),
    BattleEvent(text: '{player}, 디바우러로 뮤탈 제공권 장악!', stat: 'control', myArmy: 5, myResource: -20, enemyArmy: -8),
  ];

  // ===== PvP (프로토스 동족전) =====
  static const pvpEarly = [
    BattleEvent(text: '{player} 선수 넥서스 건설합니다.', myResource: -10),
    BattleEvent(text: '{player} 선수 게이트웨이 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 질럿 생산 시작!', myArmy: 4, myResource: -10),
    BattleEvent(text: '{player} 선수 프로브 정찰!', stat: 'scout'),
    BattleEvent(text: '{player}, 상대 게이트 수 확인!', stat: 'sense'),
    BattleEvent(text: '{player} 선수 사이버네틱스 코어 건설!', myResource: -15),
    BattleEvent(text: '{player} 선수 드라군 생산!', myArmy: 5, myResource: -12),
    BattleEvent(text: '{player}, 질럿 싸움 승리!', stat: 'control', myArmy: -3, enemyArmy: -6),
    BattleEvent(text: '{player} 선수 질럿 싸움 패배!', stat: 'control', myArmy: -6, enemyArmy: -3),
    BattleEvent(text: '{player}, 드라군 마이크로!', stat: 'control', myArmy: -2, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 앞마당 넥서스 건설!', stat: 'macro', myResource: -40),
    BattleEvent(text: '양 선수 초반 유닛 싸움 치열합니다!', myArmy: -3, enemyArmy: -3),
    BattleEvent(text: '{player}, 초반 러쉬 성공!', stat: 'attack', myArmy: -5, enemyArmy: -30, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 포지 건설! 업그레이드 선행!', stat: 'strategy', myResource: -15),
    BattleEvent(text: '{player}, 프로브로 상대 파일런 위치 정찰!', stat: 'scout'),
    BattleEvent(text: '{player} 선수 앞마당 캐논으로 방어 체계 구축!', stat: 'defense', myResource: -10),
  ];

  static const pvpMid = [
    BattleEvent(text: '{player} 선수 로보틱스 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 리버 생산!', myArmy: 5, myResource: -20),
    BattleEvent(text: '{player}, 리버 드랍 성공!', stat: 'harass', myArmy: -2, enemyArmy: -10, enemyResource: -35),
    BattleEvent(text: '{player}, 리버 드랍 실패!', stat: 'harass', myArmy: -7),
    BattleEvent(text: '{player} 선수 옵저버 생산!', myArmy: 1, myResource: -10),
    BattleEvent(text: '{player}, 다크템플러 투입!', stat: 'strategy', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player} 선수 다크로 프로브 학살!', stat: 'harass', enemyArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player}, 다크 옵저버에 발각!', stat: 'sense', myArmy: -5),
    BattleEvent(text: '{player} 선수 템플러 아카이브 건설!', myResource: -20),
    BattleEvent(text: '{player} 선수 하이템플러 생산!', myArmy: 3, myResource: -15),
    BattleEvent(text: '{player}, 사이오닉 스톰!', stat: 'strategy', enemyArmy: -20),
    BattleEvent(text: '{player} 선수 스톰에 드라군 피해!', stat: 'sense', myArmy: -15),
    BattleEvent(text: '{player}, 아칸 합체!', stat: 'strategy', myArmy: 8),
    BattleEvent(text: '{player} 선수 3번째 넥서스 확장!', stat: 'macro', myResource: -40),
    BattleEvent(text: '양측 멀티 경쟁이 치열합니다!', myResource: 10, enemyResource: 10),
    BattleEvent(text: '{player}, 상대 앞마당 압박!', stat: 'attack', myArmy: -8, enemyArmy: -10, enemyResource: -20),
    BattleEvent(text: '{player} 선수 상대 앞마당 파괴!', stat: 'attack', myArmy: -5, enemyArmy: -10, enemyResource: -40),
    BattleEvent(text: '{player}, 아칸으로 질럿 돌파!', stat: 'attack', myArmy: -3, enemyArmy: -8),
    BattleEvent(text: '{player} 선수 셔틀 리버 드랍으로 프로브 사냥!', stat: 'harass', myArmy: -2, enemyResource: -30),
    BattleEvent(text: '{player}, 옵저버로 상대 다크 탐지!', stat: 'scout', enemyArmy: -5),
    BattleEvent(text: '{player} 선수 드라군 사거리 업! 전투력 향상!', stat: 'strategy', myResource: -10),
  ];

  static const pvpLate = [
    BattleEvent(text: '{player} 선수 스타게이트 건설!', myResource: -25),
    BattleEvent(text: '{player} 선수 캐리어 생산!', myArmy: 10, myResource: -40),
    BattleEvent(text: '{player}, 캐리어 함대 완성!', stat: 'macro', myArmy: 15, myResource: -50),
    BattleEvent(text: '{player} 선수 아비터 생산!', myArmy: 5, myResource: -25),
    BattleEvent(text: '{player}, 리콜 투입!', stat: 'strategy', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player} 선수 스테이시스 필드!', stat: 'strategy', enemyArmy: -10),
    BattleEvent(text: '{player}, 최대 서플라이 도달!', stat: 'macro', myArmy: 20, myResource: -50),
    BattleEvent(text: '{player} 선수 대규모 병력으로 진격!', stat: 'attack'),
    BattleEvent(text: '{player}, 스톰 난무!', stat: 'control', myArmy: -10, enemyArmy: -15),
    BattleEvent(text: '{player} 선수 치열한 물량 싸움!', stat: 'control', myArmy: -15, myResource: -20, enemyArmy: -15, enemyResource: -20),
    BattleEvent(text: '{player}, 멀티 동시 견제!', stat: 'harass', myArmy: -5, enemyResource: -40),
    BattleEvent(text: '{player} 선수 자원 우위 가져갑니다!', stat: 'macro', myResource: 30),
    BattleEvent(text: '{player}, 최종 공세 시작!', stat: 'attack', myArmy: -10, enemyArmy: -20),
    BattleEvent(text: '{player} 선수 상대 본진 진입!', stat: 'attack', myArmy: -5, enemyArmy: -15, enemyResource: -30),
    BattleEvent(text: '{player}, 상대 본진 초토화!', stat: 'attack', myArmy: -3, enemyArmy: -20, enemyResource: -50, decisive: true),
    BattleEvent(text: '{player} 선수 드라군 아칸으로 완벽한 승리!', decisive: true),
    BattleEvent(text: '양측 넥서스 자원이 고갈되어갑니다!', myResource: -5, enemyResource: -5),
    BattleEvent(text: '{player}, 리콜 투입으로 최종 결전!', stat: 'macro', myArmy: -10, enemyArmy: -30),
    BattleEvent(text: '{player} 선수 상대 넥서스 전부 파괴!', decisive: true),
    BattleEvent(text: '{player}, 아비터 리콜로 기습! 상대 본진 초토화!', stat: 'strategy', myArmy: -5, enemyArmy: -15, enemyResource: -25),
    BattleEvent(text: '{player} 선수 캐리어 인터셉터 난무! 상대 항공 방어 무력화!', stat: 'macro', myArmy: -5, enemyArmy: -12),
  ];

  /// 매치업별 이벤트 가져오기
  static MatchupEvents getMatchupEvents(String homeRace, String awayRace) {
    final key = '${homeRace.toLowerCase()}v${awayRace.toLowerCase()}';

    switch (key) {
      case 'tvz':
        return const MatchupEvents(early: tvzEarly, mid: tvzMid, late: tvzLate);
      case 'zvt':
        return const MatchupEvents(early: zvtEarly, mid: zvtMid, late: zvtLate);
      case 'tvp':
        return const MatchupEvents(early: tvpEarly, mid: tvpMid, late: tvpLate);
      case 'pvt':
        return const MatchupEvents(early: pvtEarly, mid: pvtMid, late: pvtLate);
      case 'zvp':
        return const MatchupEvents(early: zvpEarly, mid: zvpMid, late: zvpLate);
      case 'pvz':
        return const MatchupEvents(early: pvzEarly, mid: pvzMid, late: pvzLate);
      case 'tvt':
        return const MatchupEvents(early: tvtEarly, mid: tvtMid, late: tvtLate);
      case 'zvz':
        return const MatchupEvents(early: zvzEarly, mid: zvzMid, late: zvzLate);
      case 'pvp':
        return const MatchupEvents(early: pvpEarly, mid: pvpMid, late: pvpLate);
      default:
        // 기본값으로 TvT 반환
        return const MatchupEvents(early: tvtEarly, mid: tvtMid, late: tvtLate);
    }
  }
}
