import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/responsive.dart';

/// 모든 화면에서 사용하는 R(리셋) 버튼
/// AppBar의 leading이나 actions에 배치 권장
class ResetButton extends StatelessWidget {
  final bool small;

  const ResetButton({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    final size = small ? 32.sp : 40.sp;
    final fontSize = small ? 14.sp : 18.sp;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.red[800],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.red[400]!, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.sp),
          onTap: () => _showResetConfirm(context),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _showResetConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('타이틀로 돌아가기'),
        content: const Text('현재 진행 중인 내용은 저장되지 않습니다.\n타이틀 화면으로 돌아가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// AppBar의 leading으로 사용 (왼쪽 상단)
  static Widget leading() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: const ResetButton(small: true),
        );
      },
    );
  }

  /// AppBar의 actions에 추가 (오른쪽 상단)
  static Widget action() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: const ResetButton(small: true),
        );
      },
    );
  }

  /// Positioned로 감싼 R 버튼 (Stack 내에서 사용, AppBar 없는 화면용)
  /// 기본 위치: 좌측 상단 (top: 16, left: 16)
  static Widget positioned({double? top, double? bottom, double? left, double? right}) {
    return Builder(
      builder: (context) {
        Responsive.init(context);
        return Positioned(
          top: top ?? 16.sp,
          bottom: bottom,
          left: left ?? 16.sp,
          right: right,
          child: const ResetButton(small: true),
        );
      },
    );
  }

  /// 뒤로가기 버튼 (커스텀 헤더용, R 버튼과 동일한 크기)
  /// [fallbackRoute] pop 불가 시 이동할 경로 (기본: /main)
  static Widget back({String? fallbackRoute}) {
    return Builder(
      builder: (context) {
        Responsive.init(context);
        return Container(
          width: 32.sp,
          height: 32.sp,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(6.sp),
            border: Border.all(color: Colors.grey[600]!, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6.sp),
              onTap: () {
                if (Navigator.canPop(context)) {
                  context.pop();
                } else {
                  context.go(fallbackRoute ?? '/main');
                }
              },
              child: Center(
                child: Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
        );
      },
    );
  }
}
