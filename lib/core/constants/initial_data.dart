import '../../domain/models/models.dart';

/// 마이스타크래프트 1.29.01 버전 (2012년 10월) 기준 초기 게임 데이터
/// 8개 팀: KT 롤스터, 삼성전자 칸, STX SouL, SK텔레콤 T1, 웅진 스타즈, CJ 엔투스, 공군 ACE, 제8게임단
///
/// 등급 밸런스 조정 (2026-02-05):
/// - 최고 등급: A+ (각 팀 에이스 1명)
/// - 서브 에이스: A ~ A- (팀당 1~2명)
/// - 일반 선수: B+ 이하
class InitialData {
  /// 모든 팀 생성
  static List<Team> createTeams() {
    return [
      _createKtRolster(),
      _createSamsungKhan(),
      _createStxSoul(),
      _createSktT1(),
      _createWoongjinStars(),
      _createCjEntus(),
      _createAirforceAce(),
      _createTeam8(),
    ];
  }

  /// 모든 선수 생성
  static List<Player> createPlayers() {
    return [
      ..._createKtRolsterPlayers(),
      ..._createSamsungKhanPlayers(),
      ..._createStxSoulPlayers(),
      ..._createSktT1Players(),
      ..._createWoongjinStarsPlayers(),
      ..._createCjEntusPlayers(),
      ..._createAirforceAcePlayers(),
      ..._createTeam8Players(),
    ];
  }

  /// 무소속 선수 풀 생성
  /// 1.29.01 버전 기준 무소속/은퇴 프로게이머
  static List<Player> createFreeAgentPool() {
    return [
      // ===== 레전드 프로게이머 (은퇴/무소속) - A-~B+ =====
      Player(
        id: 'free_nada',
        name: '이윤열',
        nickname: 'NaDa',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 460, control: 480, attack: 460, harass: 440,
          strategy: 480, macro: 460, defense: 420, scout: 430,
        ), // 합계: 3630 (A-)
        levelValue: 10, // 은퇴
      ),
      Player(
        id: 'free_boxer',
        name: '임요환',
        nickname: 'BoxeR',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 420, control: 450, attack: 440, harass: 450,
          strategy: 470, macro: 420, defense: 390, scout: 420,
        ), // 합계: 3460 (B+)
        levelValue: 10, // 은퇴
      ),
      Player(
        id: 'free_iloveoov',
        name: '최인규',
        nickname: 'iloveoov',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 420, control: 440, attack: 430, harass: 400,
          strategy: 430, macro: 440, defense: 420, scout: 400,
        ), // 합계: 3380 (B+)
        levelValue: 10, // 은퇴
      ),
      Player(
        id: 'free_yellow',
        name: '홍진호',
        nickname: 'YellOw',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 420, control: 450, attack: 440, harass: 470,
          strategy: 420, macro: 470, defense: 400, scout: 390,
        ), // 합계: 3460 (B+)
        levelValue: 10, // 은퇴
      ),
      Player(
        id: 'free_nalra',
        name: '강민',
        nickname: 'Nal_rA',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 390, control: 410, attack: 400, harass: 380,
          strategy: 440, macro: 400, defense: 360, scout: 370,
        ), // 합계: 3150 (B)
        levelValue: 10, // 은퇴
      ),
      Player(
        id: 'free_reach',
        name: '박정석',
        nickname: 'Reach',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 350, control: 370, attack: 360, harass: 340,
          strategy: 380, macro: 360, defense: 340, scout: 340,
        ), // 합계: 2840 (B)
        levelValue: 10, // 은퇴
      ),
      // ===== 해체된 팀 출신 =====
      Player(
        id: 'free_luxury',
        name: '구성훈',
        nickname: 'Luxury',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 450, harass: 380,
          strategy: 420, macro: 400, defense: 380, scout: 360,
        ), // 합계: 3220 (B+)
        levelValue: 7,
      ),
      Player(
        id: 'free_kal',
        name: '박세정',
        nickname: 'Kal',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 400, attack: 390, harass: 360,
          strategy: 420, macro: 390, defense: 370, scout: 370,
        ), // 합계: 3080 (B)
        levelValue: 7,
      ),
      // ===== 신인/아마추어 =====
      Player(
        id: 'free_amateur2',
        name: '이준혁',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ), // 합계: 2440 (B-)
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur3',
        name: '박민규',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 300, harass: 280,
          strategy: 340, macro: 300, defense: 280, scout: 300,
        ), // 합계: 2400 (B-)
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur4',
        name: '김태현',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 260, control: 300, attack: 320, harass: 260,
          strategy: 280, macro: 260, defense: 260, scout: 240,
        ), // 합계: 2180 (C+)
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur5',
        name: '이동수',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 240, control: 280, attack: 260, harass: 300,
          strategy: 260, macro: 320, defense: 220, scout: 260,
        ), // 합계: 2140 (C+)
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur6',
        name: '최준혁',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 270, control: 310, attack: 290, harass: 270,
          strategy: 330, macro: 290, defense: 270, scout: 280,
        ), // 합계: 2310 (C+)
        levelValue: 1,
      ),
    ];
  }

  // ===== 팀별 데이터 (1.29.01 버전) =====

  // KT 롤스터
  static Team _createKtRolster() {
    return Team(
      id: 'kt_rolster',
      name: 'KT 롤스터',
      shortName: 'KT',
      colorValue: 0xFFFF0000,
      playerIds: [
        'kt_flash', 'kt_action', 'kt_stats', 'kt_taegyun',
        'kt_woojungho', 'kt_parkseonggyun', 'kt_hwangbyungyoung',
        'kt_imjunghyun', 'kt_gogangmin', 'kt_joosingwook', 'kt_wonsunjae',
      ],
      acePlayerId: 'kt_flash',
      money: 0,
    );
  }

  static List<Player> _createKtRolsterPlayers() {
    return [
      // 이영호 (Flash) - A+, 9레벨
      Player(
        id: 'kt_flash',
        name: '이영호',
        nickname: 'Flash',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 580, control: 620, attack: 600, harass: 560,
          strategy: 590, macro: 600, defense: 570, scout: 570,
        ), // 합계: 4690 (A+)
        levelValue: 9,
        teamId: 'kt_rolster',
      ),
      // 김성대 (Action) - B, 5레벨
      Player(
        id: 'kt_action',
        name: '김성대',
        nickname: 'Action',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 380, control: 410, attack: 390, harass: 420,
          strategy: 360, macro: 410, defense: 340, scout: 370,
        ), // 합계: 3080 (B)
        levelValue: 5,
        teamId: 'kt_rolster',
      ),
      // 김대엽 (Stats) - B+, 6레벨
      Player(
        id: 'kt_stats',
        name: '김대엽',
        nickname: 'Stats',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 410, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 440, defense: 400, scout: 420,
        ), // 합계: 3370 (B+)
        levelValue: 6,
        teamId: 'kt_rolster',
      ),
      // 김태균 - B-, 4레벨
      Player(
        id: 'kt_taegyun',
        name: '김태균',
        nickname: 'TaeGyun',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 340, control: 370, attack: 350, harass: 320,
          strategy: 370, macro: 350, defense: 340, scout: 350,
        ), // 합계: 2790 (B-)
        levelValue: 4,
        teamId: 'kt_rolster',
      ),
      // 우정호 - C+, 6레벨
      Player(
        id: 'kt_woojungho',
        name: '우정호',
        nickname: 'Free',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 290, control: 320, attack: 300, harass: 270,
          strategy: 340, macro: 320, defense: 300, scout: 320,
        ), // 합계: 2460 (B-)
        levelValue: 6,
        teamId: 'kt_rolster',
      ),
      // 박성균 (July) - B, 8레벨
      Player(
        id: 'kt_parkseonggyun',
        name: '박성균',
        nickname: 'July',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 380, control: 410, attack: 430, harass: 360,
          strategy: 400, macro: 380, defense: 360, scout: 340,
        ), // 합계: 3060 (B)
        levelValue: 8,
        teamId: 'kt_rolster',
      ),
      // 황병영 - C, 3레벨
      Player(
        id: 'kt_hwangbyungyoung',
        name: '황병영',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 260, control: 290, attack: 310, harass: 240,
          strategy: 280, macro: 260, defense: 240, scout: 220,
        ), // 합계: 2100 (C+)
        levelValue: 3,
        teamId: 'kt_rolster',
      ),
      // 임정현 - B-, 5레벨
      Player(
        id: 'kt_imjunghyun',
        name: '임정현',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 340, control: 370, attack: 350, harass: 380,
          strategy: 320, macro: 370, defense: 300, scout: 330,
        ), // 합계: 2760 (B-)
        levelValue: 5,
        teamId: 'kt_rolster',
      ),
      // 고강민 - C+, 5레벨
      Player(
        id: 'kt_gogangmin',
        name: '고강민',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 290, control: 320, attack: 300, harass: 340,
          strategy: 270, macro: 320, defense: 270, scout: 290,
        ), // 합계: 2400 (B-)
        levelValue: 5,
        teamId: 'kt_rolster',
      ),
      // 주성욱 - C, 3레벨
      Player(
        id: 'kt_joosingwook',
        name: '주성욱',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 260, control: 290, attack: 270, harass: 240,
          strategy: 310, macro: 280, defense: 260, scout: 280,
        ), // 합계: 2190 (C+)
        levelValue: 3,
        teamId: 'kt_rolster',
      ),
      // 원선재 - C, 2레벨
      Player(
        id: 'kt_wonsunjae',
        name: '원선재',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 240, control: 270, attack: 250, harass: 220,
          strategy: 290, macro: 260, defense: 240, scout: 260,
        ), // 합계: 2030 (C+)
        levelValue: 2,
        teamId: 'kt_rolster',
      ),
    ];
  }

  // 삼성전자 칸
  static Team _createSamsungKhan() {
    return Team(
      id: 'samsung_khan',
      name: '삼성전자 칸',
      shortName: 'SSG',
      colorValue: 0xFF0066CC,
      playerIds: [
        'ssg_jangbi', 'ssg_stork', 'ssg_shine', 'ssg_roro',
        'ssg_reality', 'ssg_turn', 'ssg_brave', 'ssg_jokiseok',
        'ssg_jooyoungdal', 'ssg_yoojoonhee', 'ssg_hanjiwon', 'ssg_imtaegyu',
      ],
      acePlayerId: 'ssg_jangbi',
      money: 0,
    );
  }

  static List<Player> _createSamsungKhanPlayers() {
    return [
      // 허영무 (JangBi) - A+, 8레벨
      Player(
        id: 'ssg_jangbi',
        name: '허영무',
        nickname: 'JangBi',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 560, control: 590, attack: 570, harass: 540,
          strategy: 600, macro: 570, defense: 540, scout: 570,
        ), // 합계: 4540 (A+)
        levelValue: 8,
        teamId: 'samsung_khan',
      ),
      // 송병구 (Stork) - A-, 9레벨
      Player(
        id: 'ssg_stork',
        name: '송병구',
        nickname: 'Stork',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 480, control: 510, attack: 490, harass: 470,
          strategy: 530, macro: 510, defense: 470, scout: 490,
        ), // 합계: 3950 (A-)
        levelValue: 9,
        teamId: 'samsung_khan',
      ),
      // 이영한 (Shine) - B+, 7레벨
      Player(
        id: 'ssg_shine',
        name: '이영한',
        nickname: 'Shine',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 420, control: 450, attack: 430, harass: 470,
          strategy: 400, macro: 450, defense: 400, scout: 420,
        ), // 합계: 3440 (B+)
        levelValue: 7,
        teamId: 'samsung_khan',
      ),
      // 신노열 (RorO) - B, 5레벨
      Player(
        id: 'ssg_roro',
        name: '신노열',
        nickname: 'RorO',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 380, control: 410, attack: 390, harass: 430,
          strategy: 360, macro: 410, defense: 360, scout: 380,
        ), // 합계: 3120 (B)
        levelValue: 5,
        teamId: 'samsung_khan',
      ),
      // 김기현 (Reality) - C+, 3레벨
      Player(
        id: 'ssg_reality',
        name: '김기현',
        nickname: 'Reality',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 290, control: 320, attack: 340, harass: 270,
          strategy: 300, macro: 290, defense: 300, scout: 270,
        ), // 합계: 2380 (C+)
        levelValue: 3,
        teamId: 'samsung_khan',
      ),
      // 박대호 (Turn) - C+, 3레벨
      Player(
        id: 'ssg_turn',
        name: '박대호',
        nickname: 'Turn',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 290, control: 320, attack: 360, harass: 260,
          strategy: 300, macro: 290, defense: 270, scout: 260,
        ), // 합계: 2350 (C+)
        levelValue: 3,
        teamId: 'samsung_khan',
      ),
      // 유병준 (BravE) - B-, 3레벨
      Player(
        id: 'ssg_brave',
        name: '유병준',
        nickname: 'BravE',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 350, attack: 330, harass: 300,
          strategy: 350, macro: 330, defense: 320, scout: 330,
        ), // 합계: 2630 (B-)
        levelValue: 3,
        teamId: 'samsung_khan',
      ),
      // 조기석 - D+, 1레벨
      Player(
        id: 'ssg_jokiseok',
        name: '조기석',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 180, control: 210, attack: 230, harass: 160,
          strategy: 200, macro: 180, defense: 160, scout: 140,
        ), // 합계: 1460 (D+)
        levelValue: 1,
        teamId: 'samsung_khan',
      ),
      // 주영달 - C, 6레벨
      Player(
        id: 'ssg_jooyoungdal',
        name: '주영달',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 240, control: 270, attack: 250, harass: 290,
          strategy: 220, macro: 280, defense: 220, scout: 240,
        ), // 합계: 2010 (C+)
        levelValue: 6,
        teamId: 'samsung_khan',
      ),
      // 유준희 - C, 3레벨
      Player(
        id: 'ssg_yoojoonhee',
        name: '유준희',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 230, harass: 270,
          strategy: 200, macro: 270, defense: 200, scout: 220,
        ), // 합계: 1860 (C)
        levelValue: 3,
        teamId: 'samsung_khan',
      ),
      // 한지원 - C-, 2레벨
      Player(
        id: 'ssg_hanjiwon',
        name: '한지원',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 200, control: 230, attack: 210, harass: 250,
          strategy: 180, macro: 250, defense: 180, scout: 200,
        ), // 합계: 1700 (C)
        levelValue: 2,
        teamId: 'samsung_khan',
      ),
      // 임태규 - C+, 4레벨
      Player(
        id: 'ssg_imtaegyu',
        name: '임태규',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 270, control: 300, attack: 280, harass: 250,
          strategy: 320, macro: 290, defense: 270, scout: 290,
        ), // 합계: 2270 (C+)
        levelValue: 4,
        teamId: 'samsung_khan',
      ),
    ];
  }

  // STX SouL
  static Team _createStxSoul() {
    return Team(
      id: 'stx_soul',
      name: 'STX SouL',
      shortName: 'STX',
      colorValue: 0xFFFFCC00,
      playerIds: [
        'stx_bogus', 'stx_calm', 'stx_shindaegeun', 'stx_kimhyunwoo',
        'stx_mini', 'stx_kimyoonjung', 'stx_josungho', 'stx_kimsunghyun',
        'stx_kimdowoo', 'stx_seojisu', 'stx_baekdongjun', 'stx_parkjongsu',
      ],
      acePlayerId: 'stx_bogus',
      money: 0,
    );
  }

  static List<Player> _createStxSoulPlayers() {
    return [
      // 이신형 (Bogus/INnoVation) - A, 5레벨
      Player(
        id: 'stx_bogus',
        name: '이신형',
        nickname: 'Bogus',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 560, harass: 480,
          strategy: 520, macro: 530, defense: 500, scout: 480,
        ), // 합계: 4110 (A)
        levelValue: 5,
        teamId: 'stx_soul',
      ),
      // 김윤환 (Calm) - A-, 8레벨
      Player(
        id: 'stx_calm',
        name: '김윤환',
        nickname: 'Calm',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 480, harass: 520,
          strategy: 450, macro: 520, defense: 450, scout: 470,
        ), // 합계: 3860 (A-)
        levelValue: 8,
        teamId: 'stx_soul',
      ),
      // 신대근 - B, 7레벨
      Player(
        id: 'stx_shindaegeun',
        name: '신대근',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 370, control: 400, attack: 380, harass: 420,
          strategy: 350, macro: 400, defense: 350, scout: 370,
        ), // 합계: 3040 (B)
        levelValue: 7,
        teamId: 'stx_soul',
      ),
      // 김현우 (Kwanro) - B-, 3레벨
      Player(
        id: 'stx_kimhyunwoo',
        name: '김현우',
        nickname: 'Kwanro',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 320, control: 350, attack: 330, harass: 370,
          strategy: 300, macro: 350, defense: 300, scout: 320,
        ), // 합계: 2640 (B-)
        levelValue: 3,
        teamId: 'stx_soul',
      ),
      // 변현제 (Mini) - B-, 1레벨
      Player(
        id: 'stx_mini',
        name: '변현제',
        nickname: 'Mini',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 330, control: 360, attack: 340, harass: 310,
          strategy: 380, macro: 350, defense: 330, scout: 340,
        ), // 합계: 2740 (B-)
        levelValue: 1,
        teamId: 'stx_soul',
      ),
      // 김윤중 - B-, 5레벨
      Player(
        id: 'stx_kimyoonjung',
        name: '김윤중',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 350, attack: 330, harass: 300,
          strategy: 350, macro: 330, defense: 320, scout: 320,
        ), // 합계: 2620 (B-)
        levelValue: 5,
        teamId: 'stx_soul',
      ),
      // 조성호 - C+, 2레벨
      Player(
        id: 'stx_josungho',
        name: '조성호',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 300, control: 330, attack: 310, harass: 280,
          strategy: 330, macro: 310, defense: 300, scout: 300,
        ), // 합계: 2460 (B-)
        levelValue: 2,
        teamId: 'stx_soul',
      ),
      // 김성현 - B-, 4레벨
      Player(
        id: 'stx_kimsunghyun',
        name: '김성현',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 340, control: 370, attack: 390, harass: 320,
          strategy: 360, macro: 360, defense: 340, scout: 320,
        ), // 합계: 2800 (B)
        levelValue: 4,
        teamId: 'stx_soul',
      ),
      // 김도우 - C+, 4레벨
      Player(
        id: 'stx_kimdowoo',
        name: '김도우',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 280, control: 310, attack: 330, harass: 260,
          strategy: 300, macro: 300, defense: 280, scout: 260,
        ), // 합계: 2320 (C+)
        levelValue: 4,
        teamId: 'stx_soul',
      ),
      // 서지수 - C, 2레벨
      Player(
        id: 'stx_seojisu',
        name: '서지수',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 270, harass: 200,
          strategy: 240, macro: 240, defense: 220, scout: 200,
        ), // 합계: 1840 (C)
        levelValue: 2,
        teamId: 'stx_soul',
      ),
      // 백동준 - C, 2레벨
      Player(
        id: 'stx_baekdongjun',
        name: '백동준',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 240, control: 270, attack: 250, harass: 220,
          strategy: 290, macro: 260, defense: 240, scout: 260,
        ), // 합계: 2030 (C+)
        levelValue: 2,
        teamId: 'stx_soul',
      ),
      // 박종수 - C-, 1레벨
      Player(
        id: 'stx_parkjongsu',
        name: '박종수',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 200, control: 230, attack: 210, harass: 180,
          strategy: 250, macro: 220, defense: 200, scout: 220,
        ), // 합계: 1710 (C)
        levelValue: 1,
        teamId: 'stx_soul',
      ),
    ];
  }

  // SK텔레콤 T1
  static Team _createSktT1() {
    return Team(
      id: 'skt_t1',
      name: 'SK텔레콤 T1',
      shortName: 'SKT',
      colorValue: 0xFFCC0000,
      playerIds: [
        'skt_fantasy', 'skt_bisu', 'skt_best', 'skt_mind',
        'skt_soo', 'skt_iris', 'skt_rain', 'skt_choihosun',
        'skt_jungyoungjae', 'skt_kimyonghyo', 'skt_leeyehoon',
        'skt_bangtaesu', 'skt_imhonggyu', 'skt_jungkyungdoo', 'skt_leehoseong',
      ],
      acePlayerId: 'skt_fantasy',
      money: 0,
    );
  }

  static List<Player> _createSktT1Players() {
    return [
      // 정명훈 (Fantasy) - A+, 9레벨
      Player(
        id: 'skt_fantasy',
        name: '정명훈',
        nickname: 'Fantasy',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 570, control: 600, attack: 580, harass: 550,
          strategy: 580, macro: 580, defense: 560, scout: 560,
        ), // 합계: 4580 (A+)
        levelValue: 9,
        teamId: 'skt_t1',
      ),
      // 김택용 (Bisu) - A, 9레벨
      Player(
        id: 'skt_bisu',
        name: '김택용',
        nickname: 'Bisu',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 510, control: 560, attack: 530, harass: 510,
          strategy: 580, macro: 550, defense: 510, scout: 530,
        ), // 합계: 4280 (A)
        levelValue: 9,
        teamId: 'skt_t1',
      ),
      // 도재욱 (Best) - B+, 8레벨
      Player(
        id: 'skt_best',
        name: '도재욱',
        nickname: 'Best',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 410, harass: 380,
          strategy: 450, macro: 420, defense: 400, scout: 410,
        ), // 합계: 3300 (B+)
        levelValue: 8,
        teamId: 'skt_t1',
      ),
      // 박재혁 (Mind) - B, 6레벨
      Player(
        id: 'skt_mind',
        name: '박재혁',
        nickname: 'Mind',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 360, control: 390, attack: 370, harass: 400,
          strategy: 340, macro: 390, defense: 320, scout: 350,
        ), // 합계: 2920 (B)
        levelValue: 6,
        teamId: 'skt_t1',
      ),
      // 어윤수 (soO) - B-, 5레벨
      Player(
        id: 'skt_soo',
        name: '어윤수',
        nickname: 'soO',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 330, control: 360, attack: 340, harass: 380,
          strategy: 310, macro: 360, defense: 310, scout: 330,
        ), // 합계: 2720 (B-)
        levelValue: 5,
        teamId: 'skt_t1',
      ),
      // 이승석 (Iris) - B-, 4레벨
      Player(
        id: 'skt_iris',
        name: '이승석',
        nickname: 'Iris',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 300, control: 330, attack: 310, harass: 350,
          strategy: 280, macro: 330, defense: 280, scout: 300,
        ), // 합계: 2480 (B-)
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      // 정윤종 (Rain) - B-, 4레벨
      Player(
        id: 'skt_rain',
        name: '정윤종',
        nickname: 'Rain',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 350, attack: 330, harass: 300,
          strategy: 350, macro: 330, defense: 320, scout: 330,
        ), // 합계: 2630 (B-)
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      // 최호선 - C+, 3레벨
      Player(
        id: 'skt_choihosun',
        name: '최호선',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 260, control: 290, attack: 310, harass: 240,
          strategy: 280, macro: 260, defense: 240, scout: 220,
        ), // 합계: 2100 (C+)
        levelValue: 3,
        teamId: 'skt_t1',
      ),
      // 정영재 - D+, 1레벨
      Player(
        id: 'skt_jungyoungjae',
        name: '정영재',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 180, control: 210, attack: 230, harass: 160,
          strategy: 200, macro: 180, defense: 160, scout: 140,
        ), // 합계: 1460 (D+)
        levelValue: 1,
        teamId: 'skt_t1',
      ),
      // 김용효 - C, 2레벨
      Player(
        id: 'skt_kimyonghyo',
        name: '김용효',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 270, harass: 200,
          strategy: 240, macro: 240, defense: 220, scout: 200,
        ), // 합계: 1840 (C)
        levelValue: 2,
        teamId: 'skt_t1',
      ),
      // 이예훈 - C, 2레벨
      Player(
        id: 'skt_leeyehoon',
        name: '이예훈',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 230, harass: 270,
          strategy: 200, macro: 270, defense: 200, scout: 220,
        ), // 합계: 1860 (C)
        levelValue: 2,
        teamId: 'skt_t1',
      ),
      // 방태수 - C-, 1레벨
      Player(
        id: 'skt_bangtaesu',
        name: '방태수',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 200, control: 230, attack: 210, harass: 250,
          strategy: 180, macro: 250, defense: 180, scout: 200,
        ), // 합계: 1700 (C)
        levelValue: 1,
        teamId: 'skt_t1',
      ),
      // 임홍규 - C-, 1레벨
      Player(
        id: 'skt_imhonggyu',
        name: '임홍규',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 200, control: 230, attack: 210, harass: 250,
          strategy: 180, macro: 250, defense: 180, scout: 200,
        ), // 합계: 1700 (C)
        levelValue: 1,
        teamId: 'skt_t1',
      ),
      // 정경두 - C+, 3레벨
      Player(
        id: 'skt_jungkyungdoo',
        name: '정경두',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 260, control: 290, attack: 270, harass: 240,
          strategy: 310, macro: 280, defense: 260, scout: 280,
        ), // 합계: 2190 (C+)
        levelValue: 3,
        teamId: 'skt_t1',
      ),
      // 이호성 - C, 2레벨
      Player(
        id: 'skt_leehoseong',
        name: '이호성',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 230, harass: 200,
          strategy: 290, macro: 240, defense: 220, scout: 240,
        ), // 합계: 1890 (C)
        levelValue: 2,
        teamId: 'skt_t1',
      ),
    ];
  }

  // 웅진 스타즈
  static Team _createWoongjinStars() {
    return Team(
      id: 'woongjin_stars',
      name: '웅진 스타즈',
      shortName: 'WJS',
      colorValue: 0xFF009933,
      playerIds: [
        'wjs_zero', 'wjs_soulkey', 'wjs_light', 'wjs_killer',
        'wjs_jaewook', 'wjs_nojunggyu', 'wjs_hongjinpyo',
        'wjs_kimyoojin', 'wjs_kimseongwoon',
      ],
      acePlayerId: 'wjs_zero',
      money: 0,
    );
  }

  static List<Player> _createWoongjinStarsPlayers() {
    return [
      // 김명운 (Zero) - A, 8레벨
      Player(
        id: 'wjs_zero',
        name: '김명운',
        nickname: 'Zero',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 510, control: 540, attack: 520, harass: 560,
          strategy: 490, macro: 540, defense: 470, scout: 510,
        ), // 합계: 4140 (A)
        levelValue: 8,
        teamId: 'woongjin_stars',
      ),
      // 김민철 (SoulKey) - A-, 7레벨
      Player(
        id: 'wjs_soulkey',
        name: '김민철',
        nickname: 'SoulKey',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 480, harass: 520,
          strategy: 450, macro: 520, defense: 450, scout: 470,
        ), // 합계: 3860 (A-)
        levelValue: 7,
        teamId: 'woongjin_stars',
      ),
      // 이재호 (Light) - A-, 8레벨
      Player(
        id: 'wjs_light',
        name: '이재호',
        nickname: 'Light',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 520, harass: 450,
          strategy: 490, macro: 490, defense: 470, scout: 450,
        ), // 합계: 3840 (A-)
        levelValue: 8,
        teamId: 'woongjin_stars',
      ),
      // 윤용태 (Killer) - B+, 7레벨
      Player(
        id: 'wjs_killer',
        name: '윤용태',
        nickname: 'Killer',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 410, harass: 380,
          strategy: 450, macro: 420, defense: 400, scout: 410,
        ), // 합계: 3300 (B+)
        levelValue: 7,
        teamId: 'woongjin_stars',
      ),
      // 신재욱 - B, 6레벨
      Player(
        id: 'wjs_jaewook',
        name: '신재욱',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 370, control: 400, attack: 380, harass: 350,
          strategy: 410, macro: 390, defense: 370, scout: 370,
        ), // 합계: 3040 (B)
        levelValue: 6,
        teamId: 'woongjin_stars',
      ),
      // 노준규 (BrAvO) - C+, 3레벨
      Player(
        id: 'wjs_nojunggyu',
        name: '노준규',
        nickname: 'BrAvO',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 260, control: 290, attack: 310, harass: 240,
          strategy: 280, macro: 280, defense: 260, scout: 240,
        ), // 합계: 2160 (C+)
        levelValue: 3,
        teamId: 'woongjin_stars',
      ),
      // 홍진표 - D, 1레벨
      Player(
        id: 'wjs_hongjinpyo',
        name: '홍진표',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 160, control: 190, attack: 210, harass: 140,
          strategy: 180, macro: 160, defense: 140, scout: 120,
        ), // 합계: 1300 (D)
        levelValue: 1,
        teamId: 'woongjin_stars',
      ),
      // 김유진 - C, 4레벨
      Player(
        id: 'wjs_kimyoojin',
        name: '김유진',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 250, control: 280, attack: 260, harass: 230,
          strategy: 290, macro: 270, defense: 250, scout: 270,
        ), // 합계: 2100 (C+)
        levelValue: 4,
        teamId: 'woongjin_stars',
      ),
      // 김성운 - D, 1레벨
      Player(
        id: 'wjs_kimseongwoon',
        name: '김성운',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 160, control: 190, attack: 170, harass: 210,
          strategy: 140, macro: 210, defense: 140, scout: 160,
        ), // 합계: 1380 (D)
        levelValue: 1,
        teamId: 'woongjin_stars',
      ),
    ];
  }

  // CJ 엔투스
  static Team _createCjEntus() {
    return Team(
      id: 'cj_entus',
      name: 'CJ 엔투스',
      shortName: 'CJ',
      colorValue: 0xFFE6B800,
      playerIds: [
        'cj_leta', 'cj_hydra', 'cj_snow', 'cj_leekyungmin',
        'cj_jobyungse', 'cj_jungwoyong', 'cj_youyoungjin',
        'cj_kimjungwoo', 'cj_kimjunho', 'cj_songyoungjin', 'cj_handooyeol',
      ],
      acePlayerId: 'cj_leta',
      money: 0,
    );
  }

  static List<Player> _createCjEntusPlayers() {
    return [
      // 신상문 (Leta) - A-, 7레벨
      Player(
        id: 'cj_leta',
        name: '신상문',
        nickname: 'Leta',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 520, harass: 450,
          strategy: 490, macro: 490, defense: 470, scout: 450,
        ), // 합계: 3840 (A-)
        levelValue: 7,
        teamId: 'cj_entus',
      ),
      // 신동원 (Hydra) - A-, 7레벨
      Player(
        id: 'cj_hydra',
        name: '신동원',
        nickname: 'Hydra',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 480, harass: 520,
          strategy: 450, macro: 520, defense: 450, scout: 470,
        ), // 합계: 3860 (A-)
        levelValue: 7,
        teamId: 'cj_entus',
      ),
      // 장윤철 (SnOw) - B+, 5레벨
      Player(
        id: 'cj_snow',
        name: '장윤철',
        nickname: 'SnOw',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 410, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 430, defense: 400, scout: 420,
        ), // 합계: 3360 (B+)
        levelValue: 5,
        teamId: 'cj_entus',
      ),
      // 이경민 - B+, 6레벨
      Player(
        id: 'cj_leekyungmin',
        name: '이경민',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 410, harass: 380,
          strategy: 440, macro: 420, defense: 400, scout: 400,
        ), // 합계: 3280 (B+)
        levelValue: 6,
        teamId: 'cj_entus',
      ),
      // 조병세 (Iris) - B, 5레벨
      Player(
        id: 'cj_jobyungse',
        name: '조병세',
        nickname: 'Iris',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 370, control: 400, attack: 420, harass: 350,
          strategy: 390, macro: 390, defense: 370, scout: 350,
        ), // 합계: 3040 (B)
        levelValue: 5,
        teamId: 'cj_entus',
      ),
      // 정우용 (sKyHigh) - C+, 4레벨
      Player(
        id: 'cj_jungwoyong',
        name: '정우용',
        nickname: 'sKyHigh',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 270, control: 300, attack: 280, harass: 320,
          strategy: 250, macro: 320, defense: 250, scout: 270,
        ), // 합계: 2260 (C+)
        levelValue: 4,
        teamId: 'cj_entus',
      ),
      // 유영진 - C, 3레벨
      Player(
        id: 'cj_youyoungjin',
        name: '유영진',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 250, control: 280, attack: 300, harass: 230,
          strategy: 270, macro: 260, defense: 240, scout: 220,
        ), // 합계: 2050 (C+)
        levelValue: 3,
        teamId: 'cj_entus',
      ),
      // 김정우 (Effort) - B, 5레벨
      Player(
        id: 'cj_kimjungwoo',
        name: '김정우',
        nickname: 'Effort',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 370, control: 400, attack: 380, harass: 420,
          strategy: 350, macro: 400, defense: 350, scout: 370,
        ), // 합계: 3040 (B)
        levelValue: 5,
        teamId: 'cj_entus',
      ),
      // 김준호 - C, 3레벨
      Player(
        id: 'cj_kimjunho',
        name: '김준호',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 230, harass: 270,
          strategy: 200, macro: 270, defense: 200, scout: 220,
        ), // 합계: 1860 (C)
        levelValue: 3,
        teamId: 'cj_entus',
      ),
      // 송영진 - D, 1레벨
      Player(
        id: 'cj_songyoungjin',
        name: '송영진',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 160, control: 190, attack: 170, harass: 210,
          strategy: 140, macro: 210, defense: 140, scout: 160,
        ), // 합계: 1380 (D)
        levelValue: 1,
        teamId: 'cj_entus',
      ),
      // 한두열 - C, 3레벨
      Player(
        id: 'cj_handooyeol',
        name: '한두열',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 230, harass: 270,
          strategy: 200, macro: 270, defense: 200, scout: 220,
        ), // 합계: 1860 (C)
        levelValue: 3,
        teamId: 'cj_entus',
      ),
    ];
  }

  // 공군 ACE
  static Team _createAirforceAce() {
    return Team(
      id: 'airforce_ace',
      name: '공군 ACE',
      shortName: 'ACE',
      colorValue: 0xFF3366CC,
      playerIds: [
        'ace_modesty', 'ace_cha', 'ace_byunhyungtae', 'ace_leeseungeun',
        'ace_koinggyu', 'ace_imjinmook', 'ace_sonseokhee',
        'ace_kimseunghyun', 'ace_leejunghyun', 'ace_ankihyo',
      ],
      acePlayerId: 'ace_modesty',
      money: 0,
    );
  }

  static List<Player> _createAirforceAcePlayers() {
    return [
      // 김구현 (Modesty) - A-, 8레벨
      Player(
        id: 'ace_modesty',
        name: '김구현',
        nickname: 'Modesty',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 480, harass: 450,
          strategy: 500, macro: 490, defense: 470, scout: 480,
        ), // 합계: 3840 (A-)
        levelValue: 8,
        teamId: 'airforce_ace',
      ),
      // 차명환 - B+, 7레벨
      Player(
        id: 'ace_cha',
        name: '차명환',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 410, harass: 450,
          strategy: 380, macro: 430, defense: 380, scout: 400,
        ), // 합계: 3280 (B+)
        levelValue: 7,
        teamId: 'airforce_ace',
      ),
      // 변형태 (Movie) - B, 8레벨
      Player(
        id: 'ace_byunhyungtae',
        name: '변형태',
        nickname: 'Movie',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 350, control: 380, attack: 400, harass: 360,
          strategy: 370, macro: 370, defense: 350, scout: 350,
        ), // 합계: 2930 (B)
        levelValue: 8,
        teamId: 'airforce_ace',
      ),
      // 이성은 (ZerO) - B, 8레벨
      Player(
        id: 'ace_leeseungeun',
        name: '이성은',
        nickname: 'ZerO',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 360, control: 390, attack: 370, harass: 360,
          strategy: 380, macro: 380, defense: 360, scout: 360,
        ), // 합계: 2960 (B)
        levelValue: 8,
        teamId: 'airforce_ace',
      ),
      // 고인규 - B-, 7레벨
      Player(
        id: 'ace_koinggyu',
        name: '고인규',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 310, control: 340, attack: 360, harass: 290,
          strategy: 330, macro: 330, defense: 310, scout: 290,
        ), // 합계: 2560 (B-)
        levelValue: 7,
        teamId: 'airforce_ace',
      ),
      // 임진묵 - B-, 6레벨
      Player(
        id: 'ace_imjinmook',
        name: '임진묵',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 310, control: 340, attack: 360, harass: 290,
          strategy: 330, macro: 330, defense: 310, scout: 290,
        ), // 합계: 2560 (B-)
        levelValue: 6,
        teamId: 'airforce_ace',
      ),
      // 손석희 - B-, 4레벨
      Player(
        id: 'ace_sonseokhee',
        name: '손석희',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 330, control: 360, attack: 340, harass: 310,
          strategy: 360, macro: 350, defense: 330, scout: 340,
        ), // 합계: 2720 (B-)
        levelValue: 4,
        teamId: 'airforce_ace',
      ),
      // 김승현 - C+, 6레벨
      Player(
        id: 'ace_kimseunghyun',
        name: '김승현',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 270, control: 300, attack: 280, harass: 250,
          strategy: 300, macro: 290, defense: 270, scout: 290,
        ), // 합계: 2250 (C+)
        levelValue: 6,
        teamId: 'airforce_ace',
      ),
      // 이정현 - C-, 1레벨
      Player(
        id: 'ace_leejunghyun',
        name: '이정현',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 190, control: 220, attack: 200, harass: 240,
          strategy: 170, macro: 230, defense: 170, scout: 190,
        ), // 합계: 1610 (C)
        levelValue: 1,
        teamId: 'airforce_ace',
      ),
      // 안기효 - C+, 4레벨
      Player(
        id: 'ace_ankihyo',
        name: '안기효',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 270, control: 300, attack: 280, harass: 250,
          strategy: 320, macro: 290, defense: 270, scout: 290,
        ), // 합계: 2270 (C+)
        levelValue: 4,
        teamId: 'airforce_ace',
      ),
    ];
  }

  // 제8게임단 (해체팀 출신 + 신인)
  static Team _createTeam8() {
    return Team(
      id: 'team8',
      name: '제8게임단',
      shortName: 'T8',
      colorValue: 0xFF666666,
      playerIds: [
        't8_jaedong', 't8_upmagic', 't8_taeyang', 't8_anytime',
        't8_jaehoon', 't8_gorush', 't8_cal', 't8_joiljang',
        't8_byungryul', 't8_hajaesang', 't8_kimdowook',
      ],
      acePlayerId: 't8_jaedong',
      money: 0,
    );
  }

  static List<Player> _createTeam8Players() {
    return [
      // 이제동 (Jaedong) - A+, 9레벨
      Player(
        id: 't8_jaedong',
        name: '이제동',
        nickname: 'Jaedong',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 560, control: 590, attack: 570, harass: 560,
          strategy: 540, macro: 570, defense: 530, scout: 560,
        ), // 합계: 4480 (A+)
        levelValue: 9,
        teamId: 'team8',
      ),
      // 염보성 (UpMaGiC) - A-, 8레벨
      Player(
        id: 't8_upmagic',
        name: '염보성',
        nickname: 'UpMaGiC',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 490, control: 520, attack: 540, harass: 470,
          strategy: 510, macro: 510, defense: 490, scout: 470,
        ), // 합계: 4000 (A)
        levelValue: 8,
        teamId: 'team8',
      ),
      // 전태양 (TaeYang) - A-, 6레벨
      Player(
        id: 't8_taeyang',
        name: '전태양',
        nickname: 'TaeYang',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 470, control: 500, attack: 520, harass: 450,
          strategy: 490, macro: 490, defense: 470, scout: 450,
        ), // 합계: 3840 (A-)
        levelValue: 6,
        teamId: 'team8',
      ),
      // 진영화 (Anytime) - B+, 7레벨
      Player(
        id: 't8_anytime',
        name: '진영화',
        nickname: 'Anytime',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 410, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 430, defense: 400, scout: 420,
        ), // 합계: 3360 (B+)
        levelValue: 7,
        teamId: 'team8',
      ),
      // 김재훈 (Kwanro) - B+, 5레벨
      Player(
        id: 't8_jaehoon',
        name: '김재훈',
        nickname: 'Kwanro',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 430, attack: 410, harass: 380,
          strategy: 440, macro: 420, defense: 380, scout: 400,
        ), // 합계: 3260 (B+)
        levelValue: 5,
        teamId: 'team8',
      ),
      // 박수범 (GoRush) - B, 5레벨
      Player(
        id: 't8_gorush',
        name: '박수범',
        nickname: 'GoRush',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 370, control: 400, attack: 380, harass: 350,
          strategy: 400, macro: 390, defense: 370, scout: 370,
        ), // 합계: 3030 (B)
        levelValue: 5,
        teamId: 'team8',
      ),
      // 박준오 (Cal) - B, 5레벨
      Player(
        id: 't8_cal',
        name: '박준오',
        nickname: 'Cal',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 380, control: 410, attack: 390, harass: 430,
          strategy: 360, macro: 410, defense: 360, scout: 380,
        ), // 합계: 3120 (B)
        levelValue: 5,
        teamId: 'team8',
      ),
      // 조일장 - B-, 5레벨
      Player(
        id: 't8_joiljang',
        name: '조일장',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 330, control: 360, attack: 340, harass: 380,
          strategy: 310, macro: 360, defense: 310, scout: 330,
        ), // 합계: 2720 (B-)
        levelValue: 5,
        teamId: 'team8',
      ),
      // 이병렬 - D, 1레벨
      Player(
        id: 't8_byungryul',
        name: '이병렬',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 160, control: 190, attack: 170, harass: 210,
          strategy: 140, macro: 210, defense: 140, scout: 160,
        ), // 합계: 1380 (D)
        levelValue: 1,
        teamId: 'team8',
      ),
      // 하재상 - D, 1레벨
      Player(
        id: 't8_hajaesang',
        name: '하재상',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 160, control: 190, attack: 170, harass: 140,
          strategy: 210, macro: 180, defense: 160, scout: 180,
        ), // 합계: 1390 (D)
        levelValue: 1,
        teamId: 'team8',
      ),
      // 김도욱 - C, 2레벨
      Player(
        id: 't8_kimdowook',
        name: '김도욱',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 220, control: 250, attack: 270, harass: 200,
          strategy: 240, macro: 240, defense: 220, scout: 200,
        ), // 합계: 1840 (C)
        levelValue: 2,
        teamId: 'team8',
      ),
    ];
  }
}
