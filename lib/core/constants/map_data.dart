// 스타크래프트 맵 데이터 상수
//
// 각 맵의 특성:
/// - rushDistance: 러시거리 (0.0~1.0, 높을수록 멀다)
/// - resources: 자원량 (0.0~1.0, 높을수록 풍부)
/// - complexity: 복잡도 (0.0~1.0, 높을수록 복잡)
/// - tvz: TvZ 테란 승률 (35~65)
/// - zvp: ZvP 저그 승률 (35~65)
/// - pvt: PvT 프로토스 승률 (35~65)

import '../../domain/models/game_map.dart';

class MapData {
  final String name;
  final String imageFile;
  final double rushDistance;
  final double resources;
  final double complexity;
  final int tvz;
  final int zvp;
  final int pvt;
  final String? description;

  const MapData({
    required this.name,
    required this.imageFile,
    required this.rushDistance,
    required this.resources,
    required this.complexity,
    required this.tvz,
    required this.zvp,
    required this.pvt,
    this.description,
  });

  /// MapData → GameMap 변환 (시뮬레이션용)
  GameMap toGameMap() {
    final rd = (rushDistance * 10).round().clamp(1, 10);
    final res = (resources * 10).round().clamp(1, 10);
    final comp = (complexity * 10).round().clamp(1, 10);

    return GameMap(
      id: name,
      name: name,
      rushDistance: rd,
      resources: res,
      complexity: comp,
      matchup: RaceMatchup(
        tvzTerranWinRate: tvz.clamp(35, 65),
        zvpZergWinRate: zvp.clamp(35, 65),
        pvtProtossWinRate: pvt.clamp(35, 65),
      ),
      expansionCount: res >= 7 ? 5 : res >= 5 ? 4 : 3,
      terrainComplexity: comp,
      airAccessibility: rd >= 7 ? 7 : rd >= 5 ? 6 : 5,
      centerImportance: rd <= 4 ? 8 : rd <= 6 ? 6 : 4,
      hasIsland: description?.contains('섬') == true ||
          description?.contains('아일랜드') == true,
    );
  }
}

/// 전체 맵 목록 (가나다순)
const List<MapData> allMaps = [
  // ㄱ
  MapData(
    name: '그랜드라인',
    imageFile: '그랜드라인.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.6,
    tvz: 60, zvp: 65, pvt: 51,
    description: '멀티 획득 쉬우나 방어 어려움, 테란맵',
  ),
  MapData(
    name: '글레디에이터',
    imageFile: '글레디에이터.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.6,
    tvz: 55, zvp: 48, pvt: 55,
    description: '역언덕 상성맵, 상성 우위 종족 초반 압박 강력',
  ),

  // ㄴ
  MapData(
    name: '네오그라운드제로',
    imageFile: '네오그라운드제로.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.4,
    tvz: 55, zvp: 48, pvt: 48,
    description: '중앙집중형 힘싸움맵, 넓은 중앙, 테란 유리',
  ),
  MapData(
    name: '네오문글레이브',
    imageFile: '네오문글레이브.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 60, zvp: 64, pvt: 65,
    description: '3인용, 역언덕 힘싸움맵, 저그 불리',
  ),
  MapData(
    name: '네오벨트웨이',
    imageFile: '네오벨트웨이.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.5,
    tvz: 55, zvp: 48, pvt: 48,
    description: '도넛형 센터, 벌처 운영 유리, 테란맵',
  ),
  MapData(
    name: '네오아웃라이어',
    imageFile: '네오아웃라이어.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.6,
    tvz: 35, zvp: 50, pvt: 55,
    description: '3인용, 역언덕, 테란 압살맵, 저그 극유리',
  ),
  MapData(
    name: '네오아즈텍',
    imageFile: '네오아즈텍.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 53, zvp: 53, pvt: 50,
    description: '개념맵, 탱크 드랍 유리한 언덕 지형',
  ),
  MapData(
    name: '네오일렉트릭써킷',
    imageFile: '네오일렉트릭써킷.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 52, zvp: 50, pvt: 50,
    description: '중립건물 특징, 스플래시 유닛 중요',
  ),
  MapData(
    name: '네오제이드',
    imageFile: '네오제이드.gif',
    rushDistance: 0.7,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 60, pvt: 64,
    description: '역언덕, 러시거리 긺, 뮤탈 활용 유리, 저그맵',
  ),
  MapData(
    name: '네오체인리액션',
    imageFile: '네오체인리액션.gif',
    rushDistance: 0.7,
    resources: 0.6,
    complexity: 0.5,
    tvz: 42, zvp: 65, pvt: 55,
    description: '저그맵, 저프전 저그 압도적 유리',
  ),

  // ㄷ
  MapData(
    name: '단장의능선',
    imageFile: '단장의능선.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.7,
    tvz: 49, zvp: 57, pvt: 59,
    description: '2인용, 능선 지형 복잡, 러커 활용 유리, 저그맵',
  ),
  MapData(
    name: '단테스피크SE',
    imageFile: '단테스피크SE.gif',
    rushDistance: 0.5,
    resources: 0.7,
    complexity: 0.6,
    tvz: 50, zvp: 65, pvt: 35,
    description: '멀티 가깝고 방어 용이, 저그맵, 프토 불리',
  ),
  MapData(
    name: '달의눈물',
    imageFile: '달의눈물.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.5,
    tvz: 45, zvp: 65, pvt: 35,
    description: '3인용, 입구 2개, 프토 불리, 저그맵',
  ),
  MapData(
    name: '데스티네이션',
    imageFile: '데스티네이션.gif',
    rushDistance: 0.7,
    resources: 0.6,
    complexity: 0.7,
    tvz: 58, zvp: 50, pvt: 55,
    description: '2인용, 언덕 지형 활용, 메카닉 테란 유리',
  ),
  MapData(
    name: '데스페라도',
    imageFile: '데스페라도.gif',
    rushDistance: 0.5,
    resources: 0.8,
    complexity: 0.5,
    tvz: 62, zvp: 58, pvt: 65,
    description: '본진 10미네랄+2가스, 토스맵 삼대장',
  ),
  MapData(
    name: '데토네이션F',
    imageFile: '데토네이션F.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 45, zvp: 55, pvt: 48,
    description: '저그맵, 저그가 양 종족 상대 유리',
  ),

  // ㄹ
  MapData(
    name: '라만차',
    imageFile: '라만차.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.65,
    tvz: 52, zvp: 59, pvt: 58,
    description: '상성맵, 풍차 능선 지형, 저그 선호',
  ),
  MapData(
    name: '라오발',
    imageFile: '라오발.gif',
    rushDistance: 0.5,
    resources: 0.4,
    complexity: 0.6,
    tvz: 62, zvp: 47, pvt: 50,
    description: '반언덕 멀티, 전형적 테란맵',
  ),
  MapData(
    name: '러시아워3',
    imageFile: '러시아워3.gif',
    rushDistance: 0.4,
    resources: 0.6,
    complexity: 0.7,
    tvz: 59, zvp: 59, pvt: 44,
    description: '회전식 지형, 테란맵, 토스 불리',
  ),
  MapData(
    name: '레이드어썰트2',
    imageFile: '레이드어썰트2.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.7,
    tvz: 39, zvp: 65, pvt: 65,
    description: '이중입구 앞마당, 저그맵',
  ),
  MapData(
    name: '레퀴엠',
    imageFile: '레퀴엠.gif',
    rushDistance: 0.2,
    resources: 0.3,
    complexity: 0.4,
    tvz: 57, zvp: 58, pvt: 59,
    description: '극단적 짧은 거리, 역언덕 압박형',
  ),
  MapData(
    name: '로드런너',
    imageFile: '로드런너.gif',
    rushDistance: 0.4,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 57, pvt: 35,
    description: '다리+중립건물, 토스 불리',
  ),
  MapData(
    name: '로키',
    imageFile: '로키.gif',
    rushDistance: 0.5,
    resources: 0.7,
    complexity: 0.6,
    tvz: 65, zvp: 35, pvt: 53,
    description: '가스 풍부, 길목 난전맵, 토스맵',
  ),
  MapData(
    name: '롱기누스2',
    imageFile: '롱기누스2.gif',
    rushDistance: 0.6,
    resources: 0.8,
    complexity: 0.5,
    tvz: 60, zvp: 35, pvt: 43,
    description: '3인용, 본진10미넬, 2가스멀티, 테란맵',
  ),
  MapData(
    name: '루나',
    imageFile: '루나.gif',
    rushDistance: 0.7,
    resources: 0.6,
    complexity: 0.3,
    tvz: 54, zvp: 60, pvt: 60,
    description: '단순 구조 국민맵, 저그/토스 유리',
  ),
  MapData(
    name: '리버스템플',
    imageFile: '리버스템플.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 62, zvp: 53, pvt: 55,
    description: '로스트템플 반전, 테란 유리',
  ),

  // ㅁ
  MapData(
    name: '매치포인트',
    imageFile: '매치포인트.gif',
    rushDistance: 0.65,
    resources: 0.4,
    complexity: 0.7,
    tvz: 55, zvp: 58, pvt: 57,
    description: '다양한 공격루트, 고지형 난전맵',
  ),
  MapData(
    name: '머큐리',
    imageFile: '머큐리.gif',
    rushDistance: 0.75,
    resources: 0.35,
    complexity: 0.6,
    tvz: 49, zvp: 65, pvt: 40,
    description: '좁은 입구, 저그 유리',
  ),
  MapData(
    name: '메두사',
    imageFile: '메두사.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.7,
    tvz: 57, zvp: 58, pvt: 65,
    description: '뒷문+중립건물, 드롭 플레이 중요',
  ),
  MapData(
    name: '몬테크리스토',
    imageFile: '몬테크리스토.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.8,
    tvz: 45, zvp: 45, pvt: 60,
    description: '중앙 신전, 아일랜드멀티, 토스맵',
  ),
  MapData(
    name: '몬티홀',
    imageFile: '몬티홀.gif',
    rushDistance: 0.3,
    resources: 0.8,
    complexity: 0.7,
    tvz: 61, zvp: 40, pvt: 55,
    description: '3갈래 미네랄 봉쇄, 테란맵',
  ),
  MapData(
    name: '몽환',
    imageFile: '몽환.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.8,
    tvz: 55, zvp: 63, pvt: 57,
    description: '비대칭 4맵 조합, 위치빨 극심',
  ),

  // ㅂ
  MapData(
    name: '배틀로얄',
    imageFile: '배틀로얄.gif',
    rushDistance: 0.4,
    resources: 0.3,
    complexity: 0.5,
    tvz: 35, zvp: 65, pvt: 35,
    description: '극단적 저그맵, 테란·토스 불리',
  ),
  MapData(
    name: '백마고지',
    imageFile: '백마고지.gif',
    rushDistance: 0.6,
    resources: 0.8,
    complexity: 0.7,
    tvz: 65, zvp: 56, pvt: 65,
    description: '본진 2가스, 말 모양 고지대, 토스맵',
  ),
  MapData(
    name: '벤젠',
    imageFile: '벤젠.gif',
    rushDistance: 0.85,
    resources: 0.6,
    complexity: 0.5,
    tvz: 64, zvp: 49, pvt: 49,
    description: '매우 긴 러시거리, 테란맵',
  ),
  MapData(
    name: '블루스톰',
    imageFile: '블루스톰.gif',
    rushDistance: 0.4,
    resources: 0.7,
    complexity: 0.7,
    tvz: 47, zvp: 50, pvt: 50,
    description: '반땅 구도, 장기전 유도, 개념맵',
  ),
  MapData(
    name: '블리츠X',
    imageFile: '블리츠X.gif',
    rushDistance: 0.8,
    resources: 0.6,
    complexity: 0.7,
    tvz: 48, zvp: 57, pvt: 40,
    description: '먼 러시거리, X자 미네랄 구조',
  ),
  MapData(
    name: '비잔티움2',
    imageFile: '비잔티움2.gif',
    rushDistance: 0.5,
    resources: 0.7,
    complexity: 0.6,
    tvz: 55, zvp: 65, pvt: 55,
    description: '역언덕, 미네랄멀티 쟁탈전, 저그맵',
  ),
  MapData(
    name: '비프로스트3',
    imageFile: '비프로스트3.gif',
    rushDistance: 0.3,
    resources: 0.5,
    complexity: 0.7,
    tvz: 48, zvp: 62, pvt: 57,
    description: '램프없는 초크, 저그/토스 유리',
  ),

  // ㅅ
  MapData(
    name: '신백두대간',
    imageFile: '신백두대간.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.75,
    tvz: 56, zvp: 62, pvt: 40,
    description: '언덕 컨트롤이 승패 결정, 저그맵',
  ),
  MapData(
    name: '신용오름',
    imageFile: '신용오름.gif',
    rushDistance: 0.5,
    resources: 0.4,
    complexity: 0.6,
    tvz: 57, zvp: 65, pvt: 42,
    description: '난전 힘싸움맵, 위치운 중요, 저그맵',
  ),
  MapData(
    name: '신의정원',
    imageFile: '신의정원.gif',
    rushDistance: 0.7,
    resources: 0.5,
    complexity: 0.55,
    tvz: 50, zvp: 52, pvt: 48,
    description: '8인용 대형맵, 위치별 불균형',
  ),
  MapData(
    name: '신저격능선',
    imageFile: '신저격능선.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.7,
    tvz: 54, zvp: 61, pvt: 51,
    description: '능선 지형, 러커 차단 유리, 저그맵',
  ),
  MapData(
    name: '신청풍명월',
    imageFile: '신청풍명월.gif',
    rushDistance: 0.7,
    resources: 0.8,
    complexity: 0.5,
    tvz: 40, zvp: 65, pvt: 48,
    description: '3가스 확보 용이, 저그맵',
  ),
  MapData(
    name: '신추풍령',
    imageFile: '신추풍령.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.8,
    tvz: 55, zvp: 48, pvt: 52,
    description: '좁은 통로와 초크, 테란맵',
  ),
  MapData(
    name: '신태양의제국',
    imageFile: '신태양의제국.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.7,
    tvz: 64, zvp: 50, pvt: 51,
    description: '전형적 테란맵, 언덕/능선 다수',
  ),
  MapData(
    name: '신피의능선',
    imageFile: '신피의능선.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.7,
    tvz: 53, zvp: 55, pvt: 38,
    description: '센터 구릉지, 캐리어 유리, 토스 불리',
  ),
  MapData(
    name: '심판의날',
    imageFile: '심판의날.gif',
    rushDistance: 0.4,
    resources: 0.8,
    complexity: 0.8,
    tvz: 48, zvp: 52, pvt: 50,
    description: '얇은 벽, 드랍 클리프, 3본진 자원풍부',
  ),
  MapData(
    name: '써킷브레이커',
    imageFile: '써킷브레이커.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.5,
    tvz: 55, zvp: 42, pvt: 40,
    description: '넓은 지형, 미네랄 풍부, 가스 부족, 테란맵',
  ),

  // ㅇ
  MapData(
    name: '아웃사이더',
    imageFile: '아웃사이더.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.7,
    tvz: 50, zvp: 48, pvt: 50,
    description: '링형 확장 배치, 전략적 운영맵',
  ),
  MapData(
    name: '아카디아2',
    imageFile: '아카디아2.gif',
    rushDistance: 0.5,
    resources: 0.8,
    complexity: 0.4,
    tvz: 52, zvp: 48, pvt: 46,
    description: '미네랄 확장 쉬움, 매크로 중심',
  ),
  MapData(
    name: '아테나2',
    imageFile: '아테나2.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 56, zvp: 35, pvt: 64,
    description: '3인용, 프로토스 유리',
  ),
  MapData(
    name: '안드로메다',
    imageFile: '안드로메다.gif',
    rushDistance: 0.8,
    resources: 0.8,
    complexity: 0.5,
    tvz: 42, zvp: 58, pvt: 55,
    description: '넓은 중앙, 섬멀티, 본진 5미네랄, 저그맵',
  ),
  MapData(
    name: '알포인트',
    imageFile: '알포인트.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.6,
    tvz: 62, zvp: 52, pvt: 49,
    description: '테란맵, 반언덕멀티, 3해처리 강제',
  ),
  MapData(
    name: '얼터너티브',
    imageFile: '얼터너티브.gif',
    rushDistance: 0.4,
    resources: 0.7,
    complexity: 0.8,
    tvz: 35, zvp: 52, pvt: 65,
    description: '뒷문 개방 가능, 테란 약세',
  ),
  MapData(
    name: '오델로',
    imageFile: '오델로.gif',
    rushDistance: 0.5,
    resources: 0.8,
    complexity: 0.4,
    tvz: 65, zvp: 55, pvt: 35,
    description: '테란맵, 탱크 길목 중심',
  ),
  MapData(
    name: '왕의귀환',
    imageFile: '왕의귀환.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 35,
    description: '본진 섬확장, 좁은 계곡, 테프전 테란맵',
  ),
  MapData(
    name: '운고로',
    imageFile: '운고로.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 55, zvp: 65, pvt: 35,
    description: '저그맵, 토스 불리, 다가스 유리',
  ),

  // ㅇ
  MapData(
    name: '이카루스',
    imageFile: '이카루스.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 48, zvp: 59, pvt: 46,
    description: '저그맵, 우주타일셋, 뮤탈 활용 유리',
  ),

  // ㅈ
  MapData(
    name: '조디악',
    imageFile: '조디악.gif',
    rushDistance: 0.6,
    resources: 0.8,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 50,
    description: '가스 멀티 중심 4인용, 섬멀티 2개 포함',
  ),
  MapData(
    name: '지오메트리',
    imageFile: '지오메트리.gif',
    rushDistance: 0.4,
    resources: 0.6,
    complexity: 0.5,
    tvz: 65, zvp: 65, pvt: 43,
    description: '테란맵, 저그·토스 불리',
  ),

  // ㅋ
  MapData(
    name: '카르타고',
    imageFile: '카르타고.gif',
    rushDistance: 0.5,
    resources: 0.7,
    complexity: 0.7,
    tvz: 35, zvp: 65, pvt: 45,
    description: '저그맵, 테란 불리, 넓은 지형과 멀티',
  ),
  MapData(
    name: '카트리나',
    imageFile: '카트리나.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.7,
    tvz: 56, zvp: 39, pvt: 53,
    description: '절벽 지형 많고 캐리어 유리, 저그 불리',
  ),
  MapData(
    name: '콜로세움2',
    imageFile: '콜로세움2.gif',
    rushDistance: 0.4,
    resources: 0.5,
    complexity: 0.6,
    tvz: 57, zvp: 53, pvt: 55,
    description: '좁은 초크와 높은 멀티, 테란 약간 유리',
  ),

  // ㅌ
  MapData(
    name: '타우크로스',
    imageFile: '타우크로스.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.3,
    tvz: 50, zvp: 50, pvt: 52,
    description: '단순 구조 개념맵, 균형 잡힌 맵',
  ),
  MapData(
    name: '태풍의눈',
    imageFile: '태풍의눈.gif',
    rushDistance: 0.5,
    resources: 0.85,
    complexity: 0.6,
    tvz: 58, zvp: 48, pvt: 45,
    description: '자원 풍부, 벌쳐 견제 유리한 테란맵',
  ),
  MapData(
    name: '투혼',
    imageFile: '투혼.gif',
    rushDistance: 0.4,
    resources: 0.6,
    complexity: 0.4,
    tvz: 55, zvp: 48, pvt: 45,
    description: '짧은 러시거리, 테란 약간 유리한 국민맵',
  ),
  MapData(
    name: '트라이애슬론',
    imageFile: '트라이애슬론.gif',
    rushDistance: 0.4,
    resources: 0.6,
    complexity: 0.85,
    tvz: 52, zvp: 50, pvt: 48,
    description: '클로킹 에그 컨셉맵, 높은 복잡도',
  ),
  MapData(
    name: '트로이',
    imageFile: '트로이.gif',
    rushDistance: 0.3,
    resources: 0.6,
    complexity: 0.9,
    tvz: 48, zvp: 42, pvt: 58,
    description: '토스 유리, 저그 최악, 매우 복잡한 지형',
  ),
  MapData(
    name: '티아매트',
    imageFile: '티아매트.gif',
    rushDistance: 0.45,
    resources: 0.65,
    complexity: 0.7,
    tvz: 65, zvp: 45, pvt: 52,
    description: 'TvZ 테란 유리, 저그 불리',
  ),

  // ㅍ
  MapData(
    name: '파이썬',
    imageFile: '파이썬.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 55, zvp: 54, pvt: 45,
    description: '거리 가변(근/중/장거리), 뮤탈 견제 용이',
  ),
  MapData(
    name: '팔진도',
    imageFile: '팔진도.gif',
    rushDistance: 0.6,
    resources: 0.65,
    complexity: 0.65,
    tvz: 50, zvp: 65, pvt: 35,
    description: '뒷마당 기반 후반 힘싸움맵, 저프전 저그 유리',
  ),
  MapData(
    name: '패스파인더',
    imageFile: '패스파인더.gif',
    rushDistance: 0.55,
    resources: 0.55,
    complexity: 0.7,
    tvz: 65, zvp: 65, pvt: 60,
    description: '3인용 상성맵, 공중 가까워 뮤탈 강세',
  ),
  MapData(
    name: '포트리스SE',
    imageFile: '포트리스SE.gif',
    rushDistance: 0.5,
    resources: 0.65,
    complexity: 0.7,
    tvz: 58, zvp: 58, pvt: 45,
    description: '전술형 힘싸움맵, 섬멀티와 리콜 전략 중요',
  ),
  MapData(
    name: '폭풍의언덕',
    imageFile: '폭풍의언덕.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.4,
    tvz: 65, zvp: 45, pvt: 35,
    description: '평지 위주 개테란맵, 개방적 멀티',
  ),
  MapData(
    name: '폴라리스랩소디',
    imageFile: '폴라리스랩소디.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.7,
    tvz: 58, zvp: 40, pvt: 60,
    description: '3갈래 진출로와 역언덕 구조의 토스맵',
  ),
  MapData(
    name: '플라즈마',
    imageFile: '플라즈마.gif',
    rushDistance: 0.4,
    resources: 0.4,
    complexity: 0.8,
    tvz: 60, zvp: 42, pvt: 48,
    description: '중립 에그 시간형 섬맵, 저그 불리',
  ),

  // ㅎ
  MapData(
    name: '화랑도',
    imageFile: '화랑도.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.7,
    tvz: 45, zvp: 58, pvt: 48,
    description: '앞마당 미네랄온리, 저그 유리한 2인용 대형맵',
  ),
  MapData(
    name: '히치하이커',
    imageFile: '히치하이커.gif',
    rushDistance: 0.3,
    resources: 0.4,
    complexity: 0.8,
    tvz: 51, zvp: 53, pvt: 57,
    description: '좁은 통로와 중립건물, 초단거리 치즈맵',
  ),
];

/// 맵 이름으로 검색
MapData? getMapByName(String name) {
  try {
    return allMaps.firstWhere((m) => m.name == name);
  } catch (_) {
    return null;
  }
}

/// 이미지 파일명으로 검색
MapData? getMapByImageFile(String imageFile) {
  try {
    return allMaps.firstWhere((m) => m.imageFile == imageFile);
  } catch (_) {
    return null;
  }
}

/// 시즌별 추천 맵풀 (8개 맵 세트)
const Map<String, List<String>> seasonMapPools = {
  '2010_S1': [
    '투혼',
    '써킷브레이커',
    '신저격능선',
    '네오그라운드제로',
    '네오아웃라이어',
    '네오일렉트릭써킷',
    '네오체인리액션',
    '네오제이드',
  ],
  '2011_S1': [
    '투혼',
    '써킷브레이커',
    '벤젠',
    '이카루스',
    '트라이애슬론',
    '패스파인더',
    '라만차',
    '네오벨트웨이',
  ],
  '2012_S1': [
    '투혼',
    '써킷브레이커',
    '신저격능선',
    '네오그라운드제로',
    '네오아웃라이어',
    '네오일렉트릭써킷',
    '네오체인리액션',
    '네오제이드',
  ],
};

/// 랜덤 시즌맵풀 생성 (8개)
List<MapData> generateRandomSeasonMaps() {
  final shuffled = List<MapData>.from(allMaps)..shuffle();
  return shuffled.take(8).toList();
}

/// 밸런스 맵 (모든 종족 상성이 48~52 범위)
List<MapData> get balancedMaps => allMaps.where((m) =>
    m.tvz >= 48 && m.tvz <= 52 &&
    m.zvp >= 48 && m.zvp <= 52 &&
    m.pvt >= 48 && m.pvt <= 52
).toList();

/// 테란맵 (TvZ 55 이상)
List<MapData> get terranMaps => allMaps.where((m) => m.tvz >= 55).toList();

/// 저그맵 (ZvP 55 이상)
List<MapData> get zergMaps => allMaps.where((m) => m.zvp >= 55).toList();

/// 프로토스맵 (PvT 55 이상)
List<MapData> get protossMaps => allMaps.where((m) => m.pvt >= 55).toList();
