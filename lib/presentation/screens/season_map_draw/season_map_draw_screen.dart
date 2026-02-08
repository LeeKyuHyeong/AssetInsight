import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/map_data.dart';
import '../../../core/utils/responsive.dart';

/// 시즌 맵 배정 화면
class SeasonMapDrawScreen extends ConsumerStatefulWidget {
  const SeasonMapDrawScreen({super.key});

  @override
  ConsumerState<SeasonMapDrawScreen> createState() => _SeasonMapDrawScreenState();
}

class _SeasonMapDrawScreenState extends ConsumerState<SeasonMapDrawScreen> {
  // 시즌 맵 데이터 (map_data.dart에서 가져옴)
  late final List<MapData> _seasonMaps;

  @override
  void initState() {
    super.initState();
    // 2012 S1 시즌맵풀 로드 (첫번째는 리그 평균)
    final mapPool = seasonMapPools['2012_S1'] ?? [];
    final actualMaps = mapPool.map((name) => getMapByName(name)).whereType<MapData>().take(7).toList();

    // 7개 맵 평균 계산
    final avgRush = actualMaps.isEmpty ? 0.5 : actualMaps.map((m) => m.rushDistance).reduce((a, b) => a + b) / actualMaps.length;
    final avgRes = actualMaps.isEmpty ? 0.5 : actualMaps.map((m) => m.resources).reduce((a, b) => a + b) / actualMaps.length;
    final avgComp = actualMaps.isEmpty ? 0.5 : actualMaps.map((m) => m.complexity).reduce((a, b) => a + b) / actualMaps.length;
    final avgTvz = actualMaps.isEmpty ? 50 : (actualMaps.map((m) => m.tvz).reduce((a, b) => a + b) / actualMaps.length).round();
    final avgZvp = actualMaps.isEmpty ? 50 : (actualMaps.map((m) => m.zvp).reduce((a, b) => a + b) / actualMaps.length).round();
    final avgPvt = actualMaps.isEmpty ? 50 : (actualMaps.map((m) => m.pvt).reduce((a, b) => a + b) / actualMaps.length).round();

    _seasonMaps = [
      MapData(
        name: '리그 평균',
        imageFile: '',
        rushDistance: avgRush,
        resources: avgRes,
        complexity: avgComp,
        tvz: avgTvz, zvp: avgZvp, pvt: avgPvt,
        description: '7개 시즌맵 평균 상성',
      ),
      ...actualMaps,
    ];
  }

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

  Widget _buildMapCardFlex(MapData map) {
    return Container(
      padding: EdgeInsets.all(4.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 맵 썸네일 + 이름
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF252540),
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(color: Colors.grey[600]!, width: 1),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 맵 썸네일 이미지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.sp),
                    child: map.imageFile.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.analytics,
                              color: Colors.amber[600],
                              size: 28.sp,
                            ),
                          )
                        : Image.asset(
                            'assets/maps/${map.imageFile}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.map,
                                  color: Colors.grey[500],
                                  size: 28.sp,
                                ),
                              );
                            },
                          ),
                  ),
                  // 맵 이름 오버레이
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 2.sp),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(3.sp),
                          bottomRight: Radius.circular(3.sp),
                        ),
                      ),
                      child: Text(
                        map.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.sp),

          // 맵 특성 + 종족 상성 통합 박스
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // 맵 특성 (러시/자원/복잡)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 2.sp),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252540),
                      borderRadius: BorderRadius.circular(4.sp),
                      border: Border.all(color: Colors.grey[700]!, width: 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBarCompact('러시', map.rushDistance, Colors.green),
                        _buildStatBarCompact('자원', map.resources, Colors.amber),
                        _buildStatBarCompact('복잡', map.complexity, Colors.orange),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 3.sp),
                // 종족 상성 박스 (세로 배치)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 2.sp),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252540),
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(color: Colors.grey[700]!, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMatchupRow('T', 'Z', map.tvz),
                      _buildMatchupRow('Z', 'P', map.zvp),
                      _buildMatchupRow('P', 'T', map.pvt),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchupRow(String race1, String race2, int percentage) {
    final race1Color = _getRaceColor(race1);
    final race2Color = _getRaceColor(race2);
    final race2Percentage = 100 - percentage;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          race1,
          style: TextStyle(
            color: race1Color,
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 2.sp),
        Text(
          '$percentage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 2.sp),
        Text(
          '$race2Percentage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 2.sp),
        Text(
          race2,
          style: TextStyle(
            color: race2Color,
            fontSize: 7.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
