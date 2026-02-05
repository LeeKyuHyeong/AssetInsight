// 스타크래프트 맵 데이터 상수
//
// 각 맵의 특성:
/// - rushDistance: 러시거리 (0.0~1.0, 높을수록 멀다)
/// - resources: 자원량 (0.0~1.0, 높을수록 풍부)
/// - complexity: 복잡도 (0.0~1.0, 높을수록 복잡)
/// - tvz: TvZ 테란 승률 (0~100)
/// - zvp: ZvP 저그 승률 (0~100)
/// - pvt: PvT 프로토스 승률 (0~100)

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
}

/// 전체 맵 목록 (가나다순)
const List<MapData> allMaps = [
  // ㄱ
  MapData(
    name: '그랜드라인',
    imageFile: '그랜드라인.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 잡힌 4인용 맵',
  ),
  MapData(
    name: '글레디에이터',
    imageFile: '글레디에이터.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.6,
    tvz: 55, zvp: 48, pvt: 52,
    description: '중앙 싸움이 중요한 맵',
  ),

  // ㄴ
  MapData(
    name: '네오그라운드제로',
    imageFile: '네오그라운드제로.gif',
    rushDistance: 0.8,
    resources: 0.8,
    complexity: 0.4,
    tvz: 40, zvp: 60, pvt: 50,
    description: '넓은 자원, 저그 유리',
  ),
  MapData(
    name: '네오문글레이브',
    imageFile: '네오문글레이브.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '네오벨트웨이',
    imageFile: '네오벨트웨이.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.5,
    tvz: 48, zvp: 55, pvt: 48,
    description: '저그 약간 유리',
  ),
  MapData(
    name: '네오아웃라이어',
    imageFile: '네오아웃라이어.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 45, zvp: 45, pvt: 55,
    description: '프로토스 유리',
  ),
  MapData(
    name: '네오아즈텍',
    imageFile: '네오아즈텍.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '네오일렉트릭써킷',
    imageFile: '네오일렉트릭써킷.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 55, zvp: 50, pvt: 50,
    description: '테란 약간 유리',
  ),
  MapData(
    name: '네오제이드',
    imageFile: '네오제이드.gif',
    rushDistance: 0.4,
    resources: 0.5,
    complexity: 0.4,
    tvz: 60, zvp: 45, pvt: 50,
    description: '짧은 러시거리, 테란맵',
  ),
  MapData(
    name: '네오체인리액션',
    imageFile: '네오체인리액션.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.5,
    tvz: 45, zvp: 55, pvt: 50,
    description: '저그 유리한 편',
  ),

  // ㄷ
  MapData(
    name: '단장의능선',
    imageFile: '단장의능선.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 52,
    description: '능선 지형 활용',
  ),
  MapData(
    name: '단테스피크SE',
    imageFile: '단테스피크SE.gif',
    rushDistance: 0.4,
    resources: 0.7,
    complexity: 0.6,
    tvz: 42, zvp: 58, pvt: 48,
    description: '가까운 자원, 저그맵',
  ),
  MapData(
    name: '달의눈물',
    imageFile: '달의눈물.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '데스티네이션',
    imageFile: '데스티네이션.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.6,
    tvz: 45, zvp: 55, pvt: 50,
    description: '저그 유리',
  ),
  MapData(
    name: '데스페라도',
    imageFile: '데스페라도.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '데토네이션F',
    imageFile: '데토네이션F.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),

  // ㄹ
  MapData(
    name: '라만차',
    imageFile: '라만차.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '라오발',
    imageFile: '라오발.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '러시아워3',
    imageFile: '러시아워3.gif',
    rushDistance: 0.4,
    resources: 0.5,
    complexity: 0.5,
    tvz: 55, zvp: 45, pvt: 52,
    description: '짧은 러시거리, 테란 유리',
  ),
  MapData(
    name: '레이드어썰트2',
    imageFile: '레이드어썰트2.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '레퀴엠',
    imageFile: '레퀴엠.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.6,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '로드런너',
    imageFile: '로드런너.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '로키',
    imageFile: '로키.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '롱기누스2',
    imageFile: '롱기누스2.gif',
    rushDistance: 0.7,
    resources: 0.6,
    complexity: 0.5,
    tvz: 48, zvp: 55, pvt: 48,
    description: '저그 유리',
  ),
  MapData(
    name: '루나',
    imageFile: '루나.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '리버스템플',
    imageFile: '리버스템플.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅁ
  MapData(
    name: '매치포인트',
    imageFile: '매치포인트.gif',
    rushDistance: 0.4,
    resources: 0.4,
    complexity: 0.5,
    tvz: 60, zvp: 40, pvt: 55,
    description: '짧은 러시거리, 테란맵',
  ),
  MapData(
    name: '머큐리',
    imageFile: '머큐리.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '메두사',
    imageFile: '메두사.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '몬테크리스토',
    imageFile: '몬테크리스토.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.6,
    tvz: 48, zvp: 55, pvt: 48,
    description: '저그 유리',
  ),
  MapData(
    name: '몬티홀',
    imageFile: '몬티홀.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '몽환',
    imageFile: '몽환.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.6,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),

  // ㅂ
  MapData(
    name: '배틀로얄',
    imageFile: '배틀로얄.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.6,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '백마고지',
    imageFile: '백마고지.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 52,
    description: '테란 약간 유리',
  ),
  MapData(
    name: '벤젠',
    imageFile: '벤젠.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '블루스톰',
    imageFile: '블루스톰.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '블리츠X',
    imageFile: '블리츠X.gif',
    rushDistance: 0.4,
    resources: 0.5,
    complexity: 0.5,
    tvz: 55, zvp: 45, pvt: 52,
    description: '짧은 러시거리, 테란 유리',
  ),
  MapData(
    name: '비잔티움2',
    imageFile: '비잔티움2.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '비프로스트3',
    imageFile: '비프로스트3.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅅ
  MapData(
    name: '신백두대간',
    imageFile: '신백두대간.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.6,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '신용오름',
    imageFile: '신용오름.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '신의정원',
    imageFile: '신의정원.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '신저격능선',
    imageFile: '신저격능선.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.7,
    tvz: 55, zvp: 45, pvt: 55,
    description: '복잡한 지형, 테란/토스 유리',
  ),
  MapData(
    name: '신청풍명월',
    imageFile: '신청풍명월.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 50, zvp: 48, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '신추풍령',
    imageFile: '신추풍령.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 48, zvp: 45, pvt: 55,
    description: '좁은 길, 프로토스 유리',
  ),
  MapData(
    name: '신태양의제국',
    imageFile: '신태양의제국.gif',
    rushDistance: 0.6,
    resources: 0.7,
    complexity: 0.6,
    tvz: 48, zvp: 55, pvt: 48,
    description: '저그 유리',
  ),
  MapData(
    name: '신피의능선',
    imageFile: '신피의능선.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 52,
    description: '능선 지형',
  ),
  MapData(
    name: '심판의날',
    imageFile: '심판의날.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '써킷브레이커',
    imageFile: '써킷브레이커.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 55, zvp: 45, pvt: 50,
    description: '넓은 지형, 테란 유리',
  ),

  // ㅇ
  MapData(
    name: '아웃사이더',
    imageFile: '아웃사이더.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '아카디아2',
    imageFile: '아카디아2.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '아테나2',
    imageFile: '아테나2.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '안드로메다',
    imageFile: '안드로메다.gif',
    rushDistance: 0.7,
    resources: 0.7,
    complexity: 0.5,
    tvz: 40, zvp: 58, pvt: 48,
    description: '섬멀티, 본진 5미네랄, 저그맵',
  ),
  MapData(
    name: '알포인트',
    imageFile: '알포인트.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '얼터너티브',
    imageFile: '얼터너티브.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '오델로',
    imageFile: '오델로.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '왕의귀환',
    imageFile: '왕의귀환.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '운고로',
    imageFile: '운고로.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅇ
  MapData(
    name: '이카루스',
    imageFile: '이카루스.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),

  // ㅈ
  MapData(
    name: '조디악',
    imageFile: '조디악.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '지오메트리',
    imageFile: '지오메트리.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅋ
  MapData(
    name: '카르타고',
    imageFile: '카르타고.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '카트리나',
    imageFile: '카트리나.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '콜로세움2',
    imageFile: '콜로세움2.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅌ
  MapData(
    name: '타우크로스',
    imageFile: '타우크로스.gif',
    rushDistance: 0.6,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '태풍의눈',
    imageFile: '태풍의눈.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '투혼',
    imageFile: '투혼.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '국민맵, 최고의 밸런스',
  ),
  MapData(
    name: '트라이애슬론',
    imageFile: '트라이애슬론.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.6,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '트로이',
    imageFile: '트로이.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '티아매트',
    imageFile: '티아매트.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅍ
  MapData(
    name: '파이썬',
    imageFile: '파이썬.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 55, pvt: 50,
    description: '저프전 저그 유리',
  ),
  MapData(
    name: '팔진도',
    imageFile: '팔진도.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 50, zvp: 50, pvt: 52,
    description: '균형 맵',
  ),
  MapData(
    name: '패스파인더',
    imageFile: '패스파인더.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 52, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '포트리스SE',
    imageFile: '포트리스SE.gif',
    rushDistance: 0.5,
    resources: 0.6,
    complexity: 0.6,
    tvz: 52, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '폭풍의언덕',
    imageFile: '폭풍의언덕.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.6,
    tvz: 52, zvp: 48, pvt: 52,
    description: '언덕 지형',
  ),
  MapData(
    name: '폴라리스랩소디',
    imageFile: '폴라리스랩소디.gif',
    rushDistance: 0.6,
    resources: 0.6,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '플라즈마',
    imageFile: '플라즈마.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),

  // ㅎ
  MapData(
    name: '화랑도',
    imageFile: '화랑도.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
  ),
  MapData(
    name: '히치하이커',
    imageFile: '히치하이커.gif',
    rushDistance: 0.5,
    resources: 0.5,
    complexity: 0.5,
    tvz: 50, zvp: 50, pvt: 50,
    description: '균형 맵',
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
