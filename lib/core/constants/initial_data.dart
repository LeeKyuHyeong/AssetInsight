import '../../domain/models/models.dart';

/// 2010 신한은행 프로리그 초기 게임 데이터
class InitialData {
  /// 모든 팀 생성
  static List<Team> createTeams() {
    return [
      _createHwaseungOz(),
      _createSktT1(),
      _createSamsungKhan(),
      _createKtRolster(),
      _createCjEntus(),
      _createWoongjinStars(),
      _createHiteSparkyz(),
      _createStxSoul(),
      _createWemadeFox(),
      _createMbcHero(),
      _createEstro(),
      _createAirforceAce(),
    ];
  }

  /// 모든 선수 생성
  static List<Player> createPlayers() {
    return [
      ..._createHwaseungOzPlayers(),
      ..._createSktT1Players(),
      ..._createSamsungKhanPlayers(),
      ..._createKtRolsterPlayers(),
      ..._createCjEntusPlayers(),
      ..._createWoongjinStarsPlayers(),
      ..._createHiteSparkyzPlayers(),
      ..._createStxSoulPlayers(),
      ..._createWemadeFoxPlayers(),
      ..._createMbcHeroPlayers(),
      ..._createEstroPlayers(),
      ..._createAirforceAcePlayers(),
    ];
  }

  /// 무소속 선수 풀 생성
  /// 무소속 선수 풀 - 레전드 및 은퇴/무소속 프로게이머
  static List<Player> createFreeAgentPool() {
    return [
      // ===== 레전드 프로게이머 (은퇴/무소속) =====
      Player(
        id: 'free_nada',
        name: '이윤열',
        nickname: 'NaDa',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 820, control: 880, attack: 840, harass: 800,
          strategy: 900, macro: 860, defense: 780, scout: 820,
        ),
        levelValue: 9, // 레전드, 은퇴 임박
      ),
      Player(
        id: 'free_savior',
        name: '마재윤',
        nickname: 'sAviOr',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 880, control: 900, attack: 860, harass: 880,
          strategy: 940, macro: 920, defense: 800, scout: 860,
        ),
        levelValue: 8, // 마에스트로, 승부조작 전
      ),
      Player(
        id: 'free_kingdom',
        name: '박용욱',
        nickname: 'Kingdom',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 640, control: 700, attack: 680, harass: 660,
          strategy: 720, macro: 680, defense: 620, scout: 660,
        ),
        levelValue: 8, // 악마토스
      ),
      Player(
        id: 'free_gorush',
        name: '박태민',
        nickname: 'GoRush',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 660, control: 720, attack: 680, harass: 740,
          strategy: 700, macro: 760, defense: 640, scout: 680,
        ),
        levelValue: 7, // 운영의 마술사
      ),
      Player(
        id: 'free_anytime',
        name: '안기효',
        nickname: 'Anytime',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 620, harass: 580,
          strategy: 660, macro: 620, defense: 580, scout: 620,
        ),
        levelValue: 6, // 하부리그의 총사령관
      ),
      Player(
        id: 'free_midas',
        name: '전상욱',
        nickname: 'Midas',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 560, control: 620, attack: 640, harass: 540,
          strategy: 600, macro: 560, defense: 540, scout: 520,
        ),
        levelValue: 5,
      ),
      Player(
        id: 'free_roro',
        name: '신노열',
        nickname: 'RorO',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 540, control: 600, attack: 580, harass: 620,
          strategy: 520, macro: 640, defense: 500, scout: 540,
        ),
        levelValue: 3, // 신인
      ),
      Player(
        id: 'free_yeonsung',
        name: '최연성',
        nickname: 'go.go',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 600, harass: 560,
          strategy: 660, macro: 600, defense: 580, scout: 600,
        ),
        levelValue: 8, // 코치 전향
      ),
      Player(
        id: 'free_jungmin',
        name: '김정민',
        nickname: 'Veggie',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 600, control: 660, attack: 640, harass: 580,
          strategy: 680, macro: 620, defense: 600, scout: 620,
        ),
        levelValue: 7, // 해설가 전향
      ),
      Player(
        id: 'free_snow',
        name: '장윤철',
        nickname: 'SnOw',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 480, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 520, defense: 480, scout: 500,
        ),
        levelValue: 2, // 2군본좌 신인
      ),
      // ===== 2010년 이후 데뷔 신인 (미래의 스타) =====
      Player(
        id: 'free_rain',
        name: '정윤종',
        nickname: 'Rain',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 620, harass: 580,
          strategy: 680, macro: 620, defense: 560, scout: 600,
        ),
        levelValue: 1, // 2009 드래프트, 2010 SKT T1 입단
      ),
      Player(
        id: 'free_bogus',
        name: '이신형',
        nickname: 'Bogus',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 560, control: 620, attack: 640, harass: 540,
          strategy: 580, macro: 600, defense: 520, scout: 540,
        ),
        levelValue: 1, // 2008 드래프트, STX 연습생 (훗날 INnoVation)
      ),
      Player(
        id: 'free_mini',
        name: '변현제',
        nickname: 'Mini',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 480, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 520, defense: 480, scout: 500,
        ),
        levelValue: 1, // 2010 상반기 드래프트 STX 4차 지명
      ),
      Player(
        id: 'free_maru',
        name: '조성주',
        nickname: 'Maru',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 520, control: 600, attack: 580, harass: 500,
          strategy: 560, macro: 540, defense: 480, scout: 500,
        ),
        levelValue: 1, // 2010 엘리트 스쿨리그 출신, 훗날 SC2 최강자
      ),
      Player(
        id: 'free_byhydra',
        name: '신동원',
        nickname: 'By.Hydra',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 540, control: 600, attack: 580, harass: 620,
          strategy: 520, macro: 620, defense: 500, scout: 540,
        ),
        levelValue: 2, // 2008 드래프트 CJ 1차 지명, MSL 2010 우승
      ),
      Player(
        id: 'free_yoonsoo',
        name: '어윤수',
        nickname: 'soO',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 500, control: 560, attack: 540, harass: 580,
          strategy: 480, macro: 580, defense: 460, scout: 500,
        ),
        levelValue: 1, // 2010년대 저그 신예
      ),
      // ===== 아마추어/신인 선수 =====
      Player(
        id: 'free_amateur1',
        name: '김성운',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 420, control: 480, attack: 460, harass: 500,
          strategy: 400, macro: 520, defense: 380, scout: 420,
        ),
        levelValue: 1, // 2009 드래프트 1위
      ),
      Player(
        id: 'free_amateur2',
        name: '조기석',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 400, control: 460, attack: 440, harass: 480,
          strategy: 380, macro: 500, defense: 360, scout: 400,
        ),
        levelValue: 1, // IEF 2008 3위
      ),
      Player(
        id: 'free_amateur3',
        name: '이경민',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 420, defense: 380, scout: 420,
        ),
        levelValue: 1, // 스쿨리그 MVP
      ),
      Player(
        id: 'free_amateur4',
        name: '김학수',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 340, control: 400, attack: 420, harass: 360,
          strategy: 380, macro: 360, defense: 340, scout: 320,
        ),
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur5',
        name: '한지원',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 320, control: 380, attack: 360, harass: 400,
          strategy: 340, macro: 420, defense: 300, scout: 340,
        ),
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur6',
        name: '신성은',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 360, control: 420, attack: 400, harass: 360,
          strategy: 440, macro: 400, defense: 360, scout: 380,
        ),
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur7',
        name: '이호준',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 360, attack: 380, harass: 320,
          strategy: 340, macro: 320, defense: 300, scout: 280,
        ),
        levelValue: 1,
      ),
      Player(
        id: 'free_amateur8',
        name: '김봉준',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 280, control: 340, attack: 320, harass: 360,
          strategy: 300, macro: 380, defense: 280, scout: 300,
        ),
        levelValue: 1,
      ),
    ];
  }

  // ===== 팀별 데이터 =====

  // 화승 오즈
  static Team _createHwaseungOz() {
    return Team(
      id: 'hwaseung_oz',
      name: '화승 오즈',
      shortName: 'OZ',
      colorValue: 0xFFFF6600,
      playerIds: [
        'oz_jaedong', 'oz_luxury', 'oz_last', 'oz_cal',
        'oz_free', 'oz_stats', 'oz_byhero', 'oz_jangsoori',
        'oz_zero', 'oz_movie',
      ],
      acePlayerId: 'oz_jaedong',
      money: 0,
    );
  }

  static List<Player> _createHwaseungOzPlayers() {
    return [
      Player(
        id: 'oz_jaedong',
        name: '이제동',
        nickname: 'Jaedong',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 850, control: 920, attack: 900, harass: 880,
          strategy: 820, macro: 900, defense: 800, scout: 830,
        ),
        levelValue: 5,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_luxury',
        name: '구성훈',
        nickname: 'Luxury',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 580, control: 620, attack: 640, harass: 560,
          strategy: 600, macro: 580, defense: 560, scout: 540,
        ),
        levelValue: 5,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_last',
        name: '손주흥',
        nickname: 'Last',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 520, control: 560, attack: 580, harass: 500,
          strategy: 540, macro: 520, defense: 500, scout: 480,
        ),
        levelValue: 3,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_cal',
        name: '박준오',
        nickname: 'Cal',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 420, control: 460, attack: 440, harass: 480,
          strategy: 400, macro: 480, defense: 400, scout: 420,
        ),
        levelValue: 4,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_free',
        name: '손찬웅',
        nickname: 'free',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 460,
          strategy: 540, macro: 500, defense: 480, scout: 500,
        ),
        levelValue: 5,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_stats',
        name: '김태균',
        nickname: 'Stats',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 540, defense: 500, scout: 520,
        ),
        levelValue: 3,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_byhero',
        name: '임원기',
        nickname: 'by.hero',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 420,
          strategy: 500, macro: 460, defense: 440, scout: 460,
        ),
        levelValue: 4,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_jangsoori',
        name: '노영훈',
        nickname: 'Jangsoori',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 420, defense: 400, scout: 420,
        ),
        levelValue: 4,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_zero',
        name: '강동연',
        nickname: 'Zero',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 480, harass: 520,
          strategy: 440, macro: 520, defense: 440, scout: 460,
        ),
        levelValue: 3,
        teamId: 'hwaseung_oz',
      ),
      Player(
        id: 'oz_movie',
        name: '오영종',
        nickname: 'Movie',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 360,
          strategy: 440, macro: 400, defense: 380, scout: 400,
        ),
        levelValue: 6,
        teamId: 'hwaseung_oz',
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
        'skt_bisu', 'skt_best', 'skt_fantasy', 'skt_mind',
        'skt_iris', 'skt_great', 'skt_taek', 'skt_kwonohyuk',
        'skt_reserve1', 'skt_reserve2',
      ],
      acePlayerId: 'skt_bisu',
      money: 0,
    );
  }

  static List<Player> _createSktT1Players() {
    return [
      Player(
        id: 'skt_bisu',
        name: '김택용',
        nickname: 'Bisu',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 880, control: 920, attack: 860, harass: 840,
          strategy: 940, macro: 880, defense: 820, scout: 860,
        ),
        levelValue: 5,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_best',
        name: '도재욱',
        nickname: 'Best',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 620, control: 680, attack: 640, harass: 600,
          strategy: 700, macro: 660, defense: 600, scout: 640,
        ),
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_fantasy',
        name: '정명훈',
        nickname: 'Fantasy',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 700, control: 760, attack: 740, harass: 680,
          strategy: 720, macro: 700, defense: 680, scout: 660,
        ),
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_mind',
        name: '박재혁',
        nickname: 'Mind',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 540, control: 580, attack: 600, harass: 520,
          strategy: 560, macro: 540, defense: 520, scout: 500,
        ),
        levelValue: 5,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_iris',
        name: '이승석',
        nickname: 'Iris',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 540,
          strategy: 460, macro: 540, defense: 460, scout: 480,
        ),
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_great',
        name: '한상봉',
        nickname: 'great',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 500,
          strategy: 420, macro: 500, defense: 420, scout: 440,
        ),
        levelValue: 5,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_taek',
        name: '정경두',
        nickname: 'Taek',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 360,
          strategy: 440, macro: 400, defense: 380, scout: 400,
        ),
        levelValue: 4,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_kwonohyuk',
        name: '권오혁',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 380, harass: 340,
          strategy: 420, macro: 380, defense: 360, scout: 380,
        ),
        levelValue: 8,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_reserve1',
        name: '김성현',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 340, harass: 300,
          strategy: 380, macro: 340, defense: 320, scout: 340,
        ),
        levelValue: 2,
        teamId: 'skt_t1',
      ),
      Player(
        id: 'skt_reserve2',
        name: '이준혁',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 320, harass: 360,
          strategy: 280, macro: 360, defense: 280, scout: 300,
        ),
        levelValue: 1,
        teamId: 'skt_t1',
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
        'ssg_stork', 'ssg_jangbi', 'ssg_zero', 'ssg_reality',
        'ssg_turn', 'ssg_yellow', 'ssg_jokiseok', 'ssg_brave',
        'ssg_reserve1', 'ssg_reserve2',
      ],
      acePlayerId: 'ssg_stork',
      money: 0,
    );
  }

  static List<Player> _createSamsungKhanPlayers() {
    return [
      Player(
        id: 'ssg_stork',
        name: '송병구',
        nickname: 'Stork',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 840, control: 880, attack: 820, harass: 800,
          strategy: 900, macro: 860, defense: 800, scout: 840,
        ),
        levelValue: 5,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_jangbi',
        name: '허영무',
        nickname: 'JangBi',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 720, control: 780, attack: 760, harass: 700,
          strategy: 800, macro: 760, defense: 700, scout: 740,
        ),
        levelValue: 4,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_zero',
        name: '이성은',
        nickname: 'ZerO',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 540, control: 580, attack: 560, harass: 600,
          strategy: 520, macro: 600, defense: 520, scout: 540,
        ),
        levelValue: 5,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_reality',
        name: '김기현',
        nickname: 'Reality',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 560,
          strategy: 480, macro: 560, defense: 480, scout: 500,
        ),
        levelValue: 4,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_turn',
        name: '박대호',
        nickname: 'Turn',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 580, harass: 460,
          strategy: 500, macro: 480, defense: 460, scout: 440,
        ),
        levelValue: 4,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_yellow',
        name: '유준희',
        nickname: 'YellOw',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 480, harass: 520,
          strategy: 440, macro: 520, defense: 440, scout: 460,
        ),
        levelValue: 5,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_jokiseok',
        name: '조기석',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 440,
          strategy: 360, macro: 440, defense: 360, scout: 380,
        ),
        levelValue: 3,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_brave',
        name: '임태규',
        nickname: 'BravE',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 420, control: 460, attack: 440, harass: 400,
          strategy: 480, macro: 440, defense: 420, scout: 440,
        ),
        levelValue: 2,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_reserve1',
        name: '김민수',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 320,
          strategy: 400, macro: 360, defense: 340, scout: 360,
        ),
        levelValue: 2,
        teamId: 'samsung_khan',
      ),
      Player(
        id: 'ssg_reserve2',
        name: '박지훈',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ),
        levelValue: 1,
        teamId: 'samsung_khan',
      ),
    ];
  }

  // KT 롤스터
  static Team _createKtRolster() {
    return Team(
      id: 'kt_rolster',
      name: 'KT 롤스터',
      shortName: 'KT',
      colorValue: 0xFFFF0000,
      playerIds: [
        'kt_flash', 'kt_reach', 'kt_action', 'kt_free',
        'kt_hotsan', 'kt_stats', 'kt_gogangmin', 'kt_hero',
        'kt_choiyongju', 'kt_reserve1',
      ],
      acePlayerId: 'kt_flash',
      money: 0,
    );
  }

  static List<Player> _createKtRolsterPlayers() {
    return [
      Player(
        id: 'kt_flash',
        name: '이영호',
        nickname: 'Flash',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 900, control: 950, attack: 940, harass: 880,
          strategy: 920, macro: 940, defense: 860, scout: 880,
        ),
        levelValue: 4,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_reach',
        name: '박지수',
        nickname: 'Reach',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 540, control: 580, attack: 600, harass: 520,
          strategy: 560, macro: 540, defense: 520, scout: 500,
        ),
        levelValue: 6,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_action',
        name: '김성대',
        nickname: 'Action',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 620, harass: 680,
          strategy: 560, macro: 660, defense: 540, scout: 580,
        ),
        levelValue: 5,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_free',
        name: '우정호',
        nickname: 'Free',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 520, defense: 500, scout: 520,
        ),
        levelValue: 4,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_hotsan',
        name: '박재영',
        nickname: 'HotSan',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 480, harass: 440,
          strategy: 520, macro: 480, defense: 460, scout: 480,
        ),
        levelValue: 4,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_stats',
        name: '김대엽',
        nickname: 'Stats',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 420, control: 460, attack: 440, harass: 400,
          strategy: 480, macro: 440, defense: 420, scout: 440,
        ),
        levelValue: 3,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_gogangmin',
        name: '고강민',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 500,
          strategy: 420, macro: 500, defense: 420, scout: 440,
        ),
        levelValue: 3,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_hero',
        name: '남승현',
        nickname: 'hero',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 440, harass: 360,
          strategy: 400, macro: 380, defense: 360, scout: 340,
        ),
        levelValue: 3,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_choiyongju',
        name: '최용주',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 320,
          strategy: 400, macro: 360, defense: 340, scout: 360,
        ),
        levelValue: 2,
        teamId: 'kt_rolster',
      ),
      Player(
        id: 'kt_reserve1',
        name: '김태현',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ),
        levelValue: 1,
        teamId: 'kt_rolster',
      ),
    ];
  }

  // CJ 엔투스
  static Team _createCjEntus() {
    return Team(
      id: 'cj_entus',
      name: 'CJ 엔투스',
      shortName: 'CJ',
      colorValue: 0xFFE6B800, // CJ 골드/노랑
      playerIds: [
        'cj_effort', 'cj_light', 'cj_skyhigh', 'cj_movie',
        'cj_iris', 'cj_puma', 'cj_reserve1', 'cj_reserve2',
        'cj_reserve3', 'cj_reserve4',
      ],
      acePlayerId: 'cj_effort',
      money: 0,
    );
  }

  static List<Player> _createCjEntusPlayers() {
    return [
      Player(
        id: 'cj_effort',
        name: '김정우',
        nickname: 'Effort',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 700, control: 760, attack: 740, harass: 780,
          strategy: 680, macro: 780, defense: 660, scout: 700,
        ),
        levelValue: 4,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_light',
        name: '이재호',
        nickname: 'Light',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 540, control: 580, attack: 600, harass: 520,
          strategy: 560, macro: 540, defense: 520, scout: 500,
        ),
        levelValue: 4,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_skyhigh',
        name: '정우용',
        nickname: 'sKyHigh',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 540,
          strategy: 460, macro: 540, defense: 460, scout: 480,
        ),
        levelValue: 5,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_movie',
        name: '변형태',
        nickname: 'Movie',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 520, control: 560, attack: 540, harass: 580,
          strategy: 500, macro: 580, defense: 500, scout: 520,
        ),
        levelValue: 5,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_iris',
        name: '조병세',
        nickname: 'Iris',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 520, harass: 440,
          strategy: 480, macro: 460, defense: 440, scout: 420,
        ),
        levelValue: 4,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_puma',
        name: '서지훈',
        nickname: 'PuMa',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 500, harass: 420,
          strategy: 460, macro: 440, defense: 420, scout: 400,
        ),
        levelValue: 3,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_reserve1',
        name: '김민규',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 380, harass: 340,
          strategy: 420, macro: 380, defense: 360, scout: 380,
        ),
        levelValue: 2,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_reserve2',
        name: '이동현',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 400,
          strategy: 320, macro: 400, defense: 320, scout: 340,
        ),
        levelValue: 2,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_reserve3',
        name: '박성우',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ),
        levelValue: 1,
        teamId: 'cj_entus',
      ),
      Player(
        id: 'cj_reserve4',
        name: '최재혁',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 300, harass: 260,
          strategy: 340, macro: 300, defense: 280, scout: 300,
        ),
        levelValue: 1,
        teamId: 'cj_entus',
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
        'wjs_killer', 'wjs_zero', 'wjs_light', 'wjs_soulkey',
        'wjs_bravo', 'wjs_great', 'wjs_reserve1', 'wjs_reserve2',
        'wjs_reserve3', 'wjs_reserve4',
      ],
      acePlayerId: 'wjs_killer',
      money: 0,
    );
  }

  static List<Player> _createWoongjinStarsPlayers() {
    return [
      Player(
        id: 'wjs_killer',
        name: '윤용태',
        nickname: 'Killer',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 680, control: 720, attack: 700, harass: 660,
          strategy: 740, macro: 700, defense: 660, scout: 700,
        ),
        levelValue: 5,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_zero',
        name: '김명운',
        nickname: 'Zero',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 600, control: 660, attack: 640, harass: 680,
          strategy: 580, macro: 680, defense: 560, scout: 600,
        ),
        levelValue: 4,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_light',
        name: '이재호',
        nickname: 'Light',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 520, control: 560, attack: 580, harass: 500,
          strategy: 540, macro: 520, defense: 500, scout: 480,
        ),
        levelValue: 3,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_soulkey',
        name: '김민철',
        nickname: 'SoulKey',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 560, control: 620, attack: 600, harass: 640,
          strategy: 540, macro: 640, defense: 520, scout: 560,
        ),
        levelValue: 2,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_bravo',
        name: '노준규',
        nickname: 'BrAvO',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 460,
          strategy: 540, macro: 500, defense: 480, scout: 500,
        ),
        levelValue: 4,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_great',
        name: '한상봉',
        nickname: 'great',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 500,
          strategy: 420, macro: 500, defense: 420, scout: 440,
        ),
        levelValue: 5,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_reserve1',
        name: '김영호',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 420, harass: 340,
          strategy: 380, macro: 360, defense: 340, scout: 320,
        ),
        levelValue: 2,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_reserve2',
        name: '이성민',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 320,
          strategy: 400, macro: 360, defense: 340, scout: 360,
        ),
        levelValue: 2,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_reserve3',
        name: '박준혁',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 320, harass: 360,
          strategy: 280, macro: 360, defense: 280, scout: 300,
        ),
        levelValue: 1,
        teamId: 'woongjin_stars',
      ),
      Player(
        id: 'wjs_reserve4',
        name: '최민수',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 340, harass: 260,
          strategy: 300, macro: 280, defense: 260, scout: 240,
        ),
        levelValue: 1,
        teamId: 'woongjin_stars',
      ),
    ];
  }

  // 하이트 스파키즈
  static Team _createHiteSparkyz() {
    return Team(
      id: 'hite_sparkyz',
      name: '하이트 스파키즈',
      shortName: 'HITE',
      colorValue: 0xFF66CCFF,
      playerIds: [
        'hite_leta', 'hite_zergbong', 'hite_jobyungse', 'hite_leekyungmin',
        'hite_hydra', 'hite_anytime', 'hite_remember', 'hite_kal',
        'hite_reserve1', 'hite_reserve2',
      ],
      acePlayerId: 'hite_leta',
      money: 0,
    );
  }

  static List<Player> _createHiteSparkyzPlayers() {
    return [
      Player(
        id: 'hite_leta',
        name: '신상문',
        nickname: 'Leta',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 620, control: 680, attack: 700, harass: 600,
          strategy: 660, macro: 620, defense: 580, scout: 560,
        ),
        levelValue: 6,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_zergbong',
        name: '신동원',
        nickname: 'ZergBong',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 560,
          strategy: 480, macro: 560, defense: 480, scout: 500,
        ),
        levelValue: 4,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_jobyungse',
        name: '조병세',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 520, harass: 440,
          strategy: 480, macro: 460, defense: 440, scout: 420,
        ),
        levelValue: 4,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_leekyungmin',
        name: '이경민',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 420,
          strategy: 500, macro: 460, defense: 440, scout: 460,
        ),
        levelValue: 3,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_hydra',
        name: '한두열',
        nickname: 'Hydra',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 540,
          strategy: 460, macro: 540, defense: 460, scout: 480,
        ),
        levelValue: 3,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_anytime',
        name: '진영화',
        nickname: 'Anytime',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 420, defense: 400, scout: 420,
        ),
        levelValue: 4,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_remember',
        name: '김상욱',
        nickname: 'Remember',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 440,
          strategy: 360, macro: 440, defense: 360, scout: 380,
        ),
        levelValue: 3,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_kal',
        name: '장윤철',
        nickname: 'Kal',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 420, control: 460, attack: 440, harass: 400,
          strategy: 480, macro: 440, defense: 420, scout: 440,
        ),
        levelValue: 4,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_reserve1',
        name: '김태수',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 380, harass: 300,
          strategy: 340, macro: 320, defense: 300, scout: 280,
        ),
        levelValue: 1,
        teamId: 'hite_sparkyz',
      ),
      Player(
        id: 'hite_reserve2',
        name: '이준영',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 320, harass: 360,
          strategy: 280, macro: 360, defense: 280, scout: 300,
        ),
        levelValue: 1,
        teamId: 'hite_sparkyz',
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
        'stx_modesty', 'stx_calm', 'stx_joiljang', 'stx_hyvaa',
        'stx_kwanro', 'stx_frozen', 'stx_shindaegeun',
        'stx_july', 'stx_reserve1', 'stx_reserve2',
      ],
      acePlayerId: 'stx_modesty',
      money: 0,
    );
  }

  static List<Player> _createStxSoulPlayers() {
    return [
      Player(
        id: 'stx_modesty',
        name: '김구현',
        nickname: 'Modesty',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 680, control: 740, attack: 720, harass: 680,
          strategy: 760, macro: 720, defense: 680, scout: 720,
        ),
        levelValue: 5,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_calm',
        name: '김윤환',
        nickname: 'Calm',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 560, control: 600, attack: 580, harass: 620,
          strategy: 540, macro: 620, defense: 540, scout: 560,
        ),
        levelValue: 4,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_joiljang',
        name: '조일장',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 500, harass: 540,
          strategy: 460, macro: 540, defense: 460, scout: 480,
        ),
        levelValue: 4,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_hyvaa',
        name: '김건',
        nickname: 'hyvaa',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 520, defense: 500, scout: 520,
        ),
        levelValue: 3,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_kwanro',
        name: '김현우',
        nickname: 'Kwanro',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 480, harass: 520,
          strategy: 440, macro: 520, defense: 440, scout: 460,
        ),
        levelValue: 4,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_frozen',
        name: '김동건',
        nickname: 'FrOzen',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 520, control: 580, attack: 620, harass: 500,
          strategy: 560, macro: 500, defense: 480, scout: 460,
        ),
        levelValue: 5,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_shindaegeun',
        name: '신대근',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 400, control: 440, attack: 460, harass: 380,
          strategy: 420, macro: 400, defense: 380, scout: 360,
        ),
        levelValue: 3,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_july',
        name: '박성준',
        nickname: 'July',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 780, control: 860, attack: 880, harass: 800,
          strategy: 720, macro: 820, defense: 700, scout: 740,
        ),
        levelValue: 6,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_reserve1',
        name: '이상우',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 320,
          strategy: 400, macro: 360, defense: 340, scout: 360,
        ),
        levelValue: 2,
        teamId: 'stx_soul',
      ),
      Player(
        id: 'stx_reserve2',
        name: '박민호',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 340, harass: 380,
          strategy: 300, macro: 380, defense: 300, scout: 320,
        ),
        levelValue: 1,
        teamId: 'stx_soul',
      ),
    ];
  }

  // 위메이드 폭스
  static Team _createWemadeFox() {
    return Team(
      id: 'wemade_fox',
      name: '위메이드 폭스',
      shortName: 'WMF',
      colorValue: 0xFFFF9900,
      playerIds: [
        'wmf_kal', 'wmf_shine', 'wmf_mind', 'wmf_taeyang',
        'wmf_yellow', 'wmf_reserve1', 'wmf_reserve2', 'wmf_reserve3',
        'wmf_reserve4', 'wmf_reserve5',
      ],
      acePlayerId: 'wmf_kal',
      money: 0,
    );
  }

  static List<Player> _createWemadeFoxPlayers() {
    return [
      Player(
        id: 'wmf_kal',
        name: '박세정',
        nickname: 'Kal',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 620, control: 680, attack: 660, harass: 620,
          strategy: 700, macro: 660, defense: 620, scout: 660,
        ),
        levelValue: 5,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_shine',
        name: '이영한',
        nickname: 'Shine',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 560, control: 620, attack: 600, harass: 640,
          strategy: 540, macro: 640, defense: 520, scout: 560,
        ),
        levelValue: 4,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_mind',
        name: '박성균',
        nickname: 'Mind',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 680, harass: 560,
          strategy: 620, macro: 580, defense: 540, scout: 520,
        ),
        levelValue: 5,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_taeyang',
        name: '전태양',
        nickname: 'TaeYang',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 560, harass: 480,
          strategy: 520, macro: 500, defense: 480, scout: 460,
        ),
        levelValue: 3,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_yellow',
        name: '임동혁',
        nickname: 'YellOw',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 540, control: 580, attack: 560, harass: 600,
          strategy: 520, macro: 600, defense: 520, scout: 540,
        ),
        levelValue: 8,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_reserve1',
        name: '김대호',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 360,
          strategy: 440, macro: 400, defense: 380, scout: 400,
        ),
        levelValue: 2,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_reserve2',
        name: '이영수',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 400,
          strategy: 320, macro: 400, defense: 320, scout: 340,
        ),
        levelValue: 2,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_reserve3',
        name: '박준서',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 380, harass: 300,
          strategy: 340, macro: 320, defense: 300, scout: 280,
        ),
        levelValue: 1,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_reserve4',
        name: '최성호',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 320, harass: 280,
          strategy: 360, macro: 320, defense: 300, scout: 320,
        ),
        levelValue: 1,
        teamId: 'wemade_fox',
      ),
      Player(
        id: 'wmf_reserve5',
        name: '김민재',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 300, harass: 340,
          strategy: 260, macro: 340, defense: 260, scout: 280,
        ),
        levelValue: 1,
        teamId: 'wemade_fox',
      ),
    ];
  }

  // MBC게임 히어로
  static Team _createMbcHero() {
    return Team(
      id: 'mbc_hero',
      name: 'MBC게임 히어로',
      shortName: 'MBC',
      colorValue: 0xFF990099,
      playerIds: [
        'mbc_upmagic', 'mbc_gorush', 'mbc_kwanro', 'mbc_leejaeho',
        'mbc_parkjiho', 'mbc_reserve1', 'mbc_reserve2', 'mbc_reserve3',
        'mbc_reserve4', 'mbc_reserve5',
      ],
      acePlayerId: 'mbc_upmagic',
      money: 0,
    );
  }

  static List<Player> _createMbcHeroPlayers() {
    return [
      Player(
        id: 'mbc_upmagic',
        name: '염보성',
        nickname: 'UpMaGiC',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 580, control: 640, attack: 660, harass: 560,
          strategy: 600, macro: 560, defense: 540, scout: 520,
        ),
        levelValue: 5,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_gorush',
        name: '박수범',
        nickname: 'GoRush',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 500, control: 540, attack: 520, harass: 480,
          strategy: 560, macro: 520, defense: 500, scout: 520,
        ),
        levelValue: 4,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_kwanro',
        name: '김재훈',
        nickname: 'Kwanro',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 460, control: 500, attack: 480, harass: 520,
          strategy: 440, macro: 520, defense: 440, scout: 460,
        ),
        levelValue: 4,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_leejaeho',
        name: '이재호',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 420, control: 460, attack: 480, harass: 400,
          strategy: 440, macro: 420, defense: 400, scout: 380,
        ),
        levelValue: 3,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_parkjiho',
        name: '박지호',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 400, control: 440, attack: 420, harass: 380,
          strategy: 460, macro: 420, defense: 400, scout: 420,
        ),
        levelValue: 3,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_reserve1',
        name: '김성훈',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 380, harass: 420,
          strategy: 340, macro: 420, defense: 340, scout: 360,
        ),
        levelValue: 2,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_reserve2',
        name: '이동수',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 400, harass: 320,
          strategy: 360, macro: 340, defense: 320, scout: 300,
        ),
        levelValue: 2,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_reserve3',
        name: '박현수',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 340, harass: 300,
          strategy: 380, macro: 340, defense: 320, scout: 340,
        ),
        levelValue: 1,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_reserve4',
        name: '최준혁',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 320, harass: 360,
          strategy: 280, macro: 360, defense: 280, scout: 300,
        ),
        levelValue: 1,
        teamId: 'mbc_hero',
      ),
      Player(
        id: 'mbc_reserve5',
        name: '김우진',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 340, harass: 260,
          strategy: 300, macro: 280, defense: 260, scout: 240,
        ),
        levelValue: 1,
        teamId: 'mbc_hero',
      ),
    ];
  }

  // 이스트로
  static Team _createEstro() {
    return Team(
      id: 'estro',
      name: '이스트로',
      shortName: 'eSTRO',
      colorValue: 0xFF00CC66,
      playerIds: [
        'estro_action', 'estro_iris', 'estro_joyongho',
        'estro_reserve1', 'estro_reserve2', 'estro_reserve3',
        'estro_reserve4', 'estro_reserve5', 'estro_reserve6',
        'estro_reserve7',
      ],
      acePlayerId: 'estro_action',
      money: 0,
    );
  }

  static List<Player> _createEstroPlayers() {
    return [
      Player(
        id: 'estro_action',
        name: '김성대',
        nickname: 'Action',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 600, control: 660, attack: 640, harass: 700,
          strategy: 580, macro: 680, defense: 560, scout: 600,
        ),
        levelValue: 5,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_iris',
        name: '이병민',
        nickname: 'Iris',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 480, control: 520, attack: 540, harass: 460,
          strategy: 500, macro: 480, defense: 460, scout: 440,
        ),
        levelValue: 4,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_joyongho',
        name: '조용호',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 440, control: 480, attack: 460, harass: 500,
          strategy: 420, macro: 500, defense: 420, scout: 440,
        ),
        levelValue: 3,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve1',
        name: '이민수',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 400, harass: 360,
          strategy: 440, macro: 400, defense: 380, scout: 400,
        ),
        levelValue: 2,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve2',
        name: '김정호',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 420, harass: 340,
          strategy: 380, macro: 360, defense: 340, scout: 320,
        ),
        levelValue: 2,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve3',
        name: '박상우',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 340, control: 380, attack: 360, harass: 400,
          strategy: 320, macro: 400, defense: 320, scout: 340,
        ),
        levelValue: 2,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve4',
        name: '최영민',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 340, harass: 300,
          strategy: 380, macro: 340, defense: 320, scout: 340,
        ),
        levelValue: 1,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve5',
        name: '이준호',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ),
        levelValue: 1,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve6',
        name: '김태호',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 280, control: 320, attack: 300, harass: 340,
          strategy: 260, macro: 340, defense: 260, scout: 280,
        ),
        levelValue: 1,
        teamId: 'estro',
      ),
      Player(
        id: 'estro_reserve7',
        name: '박준영',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 260, control: 300, attack: 280, harass: 240,
          strategy: 320, macro: 280, defense: 260, scout: 280,
        ),
        levelValue: 1,
        teamId: 'estro',
      ),
    ];
  }

  // 공군 에이스
  static Team _createAirforceAce() {
    return Team(
      id: 'airforce_ace',
      name: '공군 에이스',
      shortName: 'ACE',
      colorValue: 0xFF3366CC,
      playerIds: [
        'ace_yellow', 'ace_iloveoov', 'ace_boxer', 'ace_reach',
        'ace_nalra', 'ace_reserve1', 'ace_reserve2', 'ace_reserve3',
        'ace_reserve4', 'ace_reserve5',
      ],
      acePlayerId: 'ace_yellow',
      money: 0,
    );
  }

  static List<Player> _createAirforceAcePlayers() {
    return [
      Player(
        id: 'ace_yellow',
        name: '홍진호',
        nickname: 'YellOw',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 720, control: 780, attack: 760, harass: 800,
          strategy: 700, macro: 800, defense: 680, scout: 720,
        ),
        levelValue: 7,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_iloveoov',
        name: '최인규',
        nickname: 'iloveoov',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 700, control: 760, attack: 740, harass: 680,
          strategy: 720, macro: 740, defense: 700, scout: 680,
        ),
        levelValue: 8,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_boxer',
        name: '임요환',
        nickname: 'BoxeR',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 680, control: 740, attack: 720, harass: 760,
          strategy: 780, macro: 680, defense: 640, scout: 660,
        ),
        levelValue: 9,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reach',
        name: '박정석',
        nickname: 'Reach',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 600, control: 660, attack: 640, harass: 600,
          strategy: 680, macro: 640, defense: 600, scout: 640,
        ),
        levelValue: 7,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_nalra',
        name: '강민',
        nickname: 'Nal_rA',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 640, control: 700, attack: 680, harass: 640,
          strategy: 780, macro: 680, defense: 620, scout: 660,
        ),
        levelValue: 8,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reserve1',
        name: '김영수',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 400, control: 440, attack: 420, harass: 460,
          strategy: 380, macro: 460, defense: 380, scout: 400,
        ),
        levelValue: 3,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reserve2',
        name: '이정현',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 380, control: 420, attack: 440, harass: 360,
          strategy: 400, macro: 380, defense: 360, scout: 340,
        ),
        levelValue: 2,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reserve3',
        name: '박민규',
        raceIndex: Race.protoss.index,
        stats: const PlayerStats(
          sense: 360, control: 400, attack: 380, harass: 340,
          strategy: 420, macro: 380, defense: 360, scout: 380,
        ),
        levelValue: 2,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reserve4',
        name: '최동현',
        raceIndex: Race.zerg.index,
        stats: const PlayerStats(
          sense: 320, control: 360, attack: 340, harass: 380,
          strategy: 300, macro: 380, defense: 300, scout: 320,
        ),
        levelValue: 1,
        teamId: 'airforce_ace',
      ),
      Player(
        id: 'ace_reserve5',
        name: '김준혁',
        raceIndex: Race.terran.index,
        stats: const PlayerStats(
          sense: 300, control: 340, attack: 360, harass: 280,
          strategy: 320, macro: 300, defense: 280, scout: 260,
        ),
        levelValue: 1,
        teamId: 'airforce_ace',
      ),
    ];
  }
}
