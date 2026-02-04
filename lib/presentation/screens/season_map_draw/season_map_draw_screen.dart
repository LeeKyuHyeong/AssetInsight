import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';

/// 시즌 맵 배정 화면
class SeasonMapDrawScreen extends ConsumerStatefulWidget {
  const SeasonMapDrawScreen({super.key});

  @override
  ConsumerState<SeasonMapDrawScreen> createState() => _SeasonMapDrawScreenState();
}

class _SeasonMapDrawScreenState extends ConsumerState<SeasonMapDrawScreen> {
  // 시즌 맵 데이터
  final List<_SeasonMapInfo> _seasonMaps = [
    _SeasonMapInfo(
      name: '리그 평균',
      rushDistance: 0.7,
      resources: 0.8,
      complexity: 0.5,
      tvz: 53, zvp: 54, pvt: 55,
    ),
    _SeasonMapInfo(
      name: '써킷브레이커',
      rushDistance: 0.8,
      resources: 0.8,
      complexity: 0.6,
      tvz: 50, zvp: 50, pvt: 50,
    ),
    _SeasonMapInfo(
      name: '신저격능선',
      rushDistance: 0.6,
      resources: 0.7,
      complexity: 0.5,
      tvz: 50, zvp: 55, pvt: 50,
    ),
    _SeasonMapInfo(
      name: '네오그라운드제로',
      rushDistance: 0.5,
      resources: 0.6,
      complexity: 0.7,
      tvz: 65, zvp: 45, pvt: 55,
    ),
    _SeasonMapInfo(
      name: '네오아웃라이어',
      rushDistance: 0.8,
      resources: 0.8,
      complexity: 0.6,
      tvz: 40, zvp: 55, pvt: 55,
    ),
    _SeasonMapInfo(
      name: '네오일렉트릭써킷',
      rushDistance: 0.6,
      resources: 0.8,
      complexity: 0.5,
      tvz: 60, zvp: 65, pvt: 60,
    ),
    _SeasonMapInfo(
      name: '네오체인리액션',
      rushDistance: 0.5,
      resources: 0.7,
      complexity: 0.7,
      tvz: 45, zvp: 60, pvt: 55,
    ),
    _SeasonMapInfo(
      name: '네오제이드',
      rushDistance: 0.8,
      resources: 0.8,
      complexity: 0.6,
      tvz: 65, zvp: 50, pvt: 60,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(),

                // 메인 컨텐츠
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: _buildMapGrid(),
                  ),
                ),

                // 하단 버튼
                _buildBottomButton(context),
                SizedBox(height: 8.sp),
              ],
            ),

            // R 버튼 (왼쪽 상단)
            Positioned(
              left: 12.sp,
              top: 12.sp,
              child: _buildRButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRButton() {
    return Container(
      width: 36.sp,
      height: 36.sp,
      decoration: BoxDecoration(
        color: Colors.red[800],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.red[400]!, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.sp),
          onTap: () {
            context.go('/');
          },
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          bottom: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star, color: Colors.amber, size: 14.sp),
          SizedBox(width: 12.sp),
          Text(
            'MyStarcraft',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(width: 16.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[600]!, width: 1),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              'Season Mode  2012  S1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(width: 12.sp),
          Icon(Icons.star, color: Colors.amber, size: 14.sp),
        ],
      ),
    );
  }

  Widget _buildMapGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // 3행 높이 계산 (간격 포함)
        final cellHeight = (availableHeight - 16.sp) / 3;

        return Column(
          children: [
            // 상단 행 (맵 0, 중앙 패널, 맵 1)
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  Expanded(child: _buildMapCardFlex(_seasonMaps[0])),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildCenterPanelFlex()),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildMapCardFlex(_seasonMaps[1])),
                ],
              ),
            ),
            SizedBox(height: 6.sp),

            // 중간 행 (맵 2, 3, 4)
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  Expanded(child: _buildMapCardFlex(_seasonMaps[2])),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildMapCardFlex(_seasonMaps[3])),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildMapCardFlex(_seasonMaps[4])),
                ],
              ),
            ),
            SizedBox(height: 6.sp),

            // 하단 행 (맵 5, 6, 7)
            SizedBox(
              height: cellHeight,
              child: Row(
                children: [
                  Expanded(child: _buildMapCardFlex(_seasonMaps[5])),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildMapCardFlex(_seasonMaps[6])),
                  SizedBox(width: 6.sp),
                  Expanded(child: _buildMapCardFlex(_seasonMaps[7])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCenterPanelFlex() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.amber.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.casino, color: Colors.amber, size: 24.sp),
          SizedBox(height: 4.sp),
          Text(
            '맵 추첨',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '2012 S1',
            style: TextStyle(color: Colors.grey[400], fontSize: 9.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCardFlex(_SeasonMapInfo map) {
    return Container(
      padding: EdgeInsets.all(6.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 맵 이름
          Text(
            map.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.sp),

          // 스탯 바 (컴팩트)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatBarCompact('러시', map.rushDistance, Colors.green),
                _buildStatBarCompact('자원', map.resources, Colors.amber),
                _buildStatBarCompact('복잡', map.complexity, Colors.orange),
              ],
            ),
          ),

          SizedBox(height: 2.sp),

          // 종족 상성 (한 줄로)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMatchupCompact('T', 'Z', map.tvz),
              _buildMatchupCompact('Z', 'P', map.zvp),
              _buildMatchupCompact('P', 'T', map.pvt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBarCompact(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 20.sp,
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 7.sp)),
        ),
        Expanded(
          child: Container(
            height: 4.sp,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2.sp)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchupCompact(String race1, String race2, int percentage) {
    return Text(
      '$race1$percentage',
      style: TextStyle(color: Colors.grey[400], fontSize: 7.sp),
    );
  }

  Widget _buildCenterPanel(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.amber.withOpacity(0.1),
            Colors.amber.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.casino,
            color: Colors.amber,
            size: 32.sp,
          ),
          SizedBox(height: 8.sp),
          Text(
            '맵 추첨 결과',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            '2012 S1 시즌',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 12.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              '총 8개 맵',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapCard(_SeasonMapInfo map, double width, double height) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 맵 이미지 + 스탯
          Expanded(
            flex: 5,
            child: Row(
              children: [
                // 맵 썸네일
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.terrain,
                        color: Colors.grey[600],
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.sp),

                // 스탯 바
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBar('러시거리', map.rushDistance, Colors.green),
                      SizedBox(height: 4.sp),
                      _buildStatBar('자원', map.resources, Colors.amber),
                      SizedBox(height: 4.sp),
                      _buildStatBar('복잡도', map.complexity, Colors.orange),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 6.sp),

          // 맵 이름
          Text(
            map.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 4.sp),

          // 종족 상성 (컴팩트)
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMatchupRowCompact('T', 'Z', map.tvz),
                _buildMatchupRowCompact('Z', 'P', map.zvp),
                _buildMatchupRowCompact('P', 'T', map.pvt),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 36.sp,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 8.sp,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6.sp,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(3.sp),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3.sp),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchupRowCompact(String race1, String race2, int percentage) {
    final race1Win = percentage;
    final race2Win = 100 - percentage;
    final race1Color = _getRaceColor(race1);
    final race2Color = _getRaceColor(race2);

    // 어느 쪽이 유리한지 표시
    final isRace1Favored = race1Win > 50;
    final isBalanced = race1Win == 50;

    return Padding(
      padding: EdgeInsets.only(bottom: 2.sp),
      child: Row(
        children: [
          // 종족 1
          Container(
            width: 16.sp,
            height: 16.sp,
            decoration: BoxDecoration(
              color: race1Color.withOpacity(isRace1Favored ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Center(
              child: Text(
                race1,
                style: TextStyle(
                  color: race1Color,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 승률 바
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.sp),
              child: Container(
                height: 10.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: race1Win,
                      child: Container(
                        decoration: BoxDecoration(
                          color: race1Color.withOpacity(0.7),
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(2.sp),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$race1Win',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: race2Win,
                      child: Container(
                        decoration: BoxDecoration(
                          color: race2Color.withOpacity(0.7),
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(2.sp),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$race2Win',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 종족 2
          Container(
            width: 16.sp,
            height: 16.sp,
            decoration: BoxDecoration(
              color: race2Color.withOpacity(!isRace1Favored && !isBalanced ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Center(
              child: Text(
                race2,
                style: TextStyle(
                  color: race2Color,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRaceColor(String race) {
    switch (race) {
      case 'T':
        return Colors.blue;
      case 'Z':
        return Colors.purple;
      case 'P':
        return Colors.amber;
      default:
        return Colors.white;
    }
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      child: ElevatedButton(
        onPressed: () {
          context.go('/initial-recruit');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 12.sp),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.sp),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8.sp),
            Icon(Icons.arrow_forward, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

/// 시즌 맵 정보
class _SeasonMapInfo {
  final String name;
  final double rushDistance;
  final double resources;
  final double complexity;
  final int tvz;
  final int zvp;
  final int pvt;

  _SeasonMapInfo({
    required this.name,
    required this.rushDistance,
    required this.resources,
    required this.complexity,
    required this.tvz,
    required this.zvp,
    required this.pvt,
  });
}
