import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 감독 이름 입력 화면
class DirectorNameScreen extends ConsumerStatefulWidget {
  const DirectorNameScreen({super.key});

  @override
  ConsumerState<DirectorNameScreen> createState() => _DirectorNameScreenState();
}

class _DirectorNameScreenState extends ConsumerState<DirectorNameScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = 'UserName';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final playerTeam = gameState.playerTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(),

                // 메인 컨텐츠
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 타이틀
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
                            SizedBox(width: 8.sp),
                            Text(
                              '프 로 게 임 단   선 택',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.sp,
                                letterSpacing: 4,
                              ),
                            ),
                            SizedBox(width: 8.sp),
                            Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
                          ],
                        ),

                        SizedBox(height: 40.sp),

                        // 팀 로고
                        Container(
                          width: 180.sp,
                          height: 120.sp,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.sp),
                            boxShadow: [
                              BoxShadow(
                                color: Color(playerTeam.colorValue).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              playerTeam.shortName,
                              style: TextStyle(
                                color: Color(playerTeam.colorValue),
                                fontSize: 36.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.sp),

                        // 팀명
                        Text(
                          playerTeam.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                          ),
                        ),

                        SizedBox(height: 48.sp),

                        // 이름 입력란
                        SizedBox(
                          width: 200.sp,
                          child: TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.sp,
                                vertical: 12.sp,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4.sp),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 16.sp),

                        // 안내 텍스트
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '△',
                              style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            ),
                            SizedBox(width: 8.sp),
                            Text(
                              '감독 이름 입력란',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(width: 8.sp),
                            Text(
                              '△',
                              style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 버튼
                _buildBottomButton(context),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, color: Colors.white, size: 16.sp),
          SizedBox(width: 16.sp),
          Text(
            'MyStarcraft    Season Mode    2012    S1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(width: 16.sp),
          Icon(Icons.star_border, color: Colors.white, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      child: ElevatedButton(
        onPressed: () {
          // 감독 이름 저장 후 다음 화면으로
          final directorName = _nameController.text.trim();
          if (directorName.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('감독 이름을 입력해주세요')),
            );
            return;
          }
          // TODO: 감독 이름 저장
          context.go('/season-map-draw');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 14.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Next [Bar]',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(width: 8.sp),
            Icon(Icons.play_arrow, color: Colors.white, size: 20.sp),
            Icon(Icons.play_arrow, color: Colors.white, size: 20.sp),
          ],
        ),
      ),
    );
  }
}
