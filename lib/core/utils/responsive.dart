import 'package:flutter/material.dart';

/// 반응형 디자인을 위한 전역 유틸리티 클래스
/// 세로/가로 모드에 따라 동적으로 기준 해상도 적용
class Responsive {
  // 모바일 세로 모드 기준
  static const double basePortraitWidth = 360;
  static const double basePortraitHeight = 800;

  // 모바일 가로 모드 기준
  static const double baseLandscapeWidth = 800;
  static const double baseLandscapeHeight = 360;

  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double scaleWidth;
  static late double scaleHeight;
  static late double scale;

  /// 앱 시작 시 또는 화면 변경 시 호출
  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;

    // 방향에 따라 기준 해상도 선택
    final bool portrait = screenHeight > screenWidth;
    final double baseWidth = portrait ? basePortraitWidth : baseLandscapeWidth;
    final double baseHeight = portrait ? basePortraitHeight : baseLandscapeHeight;

    // 기준 해상도 대비 현재 화면 비율 계산
    scaleWidth = screenWidth / baseWidth;
    scaleHeight = screenHeight / baseHeight;

    // 너비/높이 중 작은 비율 사용 (비율 유지)
    scale = scaleWidth < scaleHeight ? scaleWidth : scaleHeight;

    // 최소 스케일 보장 (너무 작아지지 않도록)
    if (scale < 0.8) scale = 0.8;
    // 최대 스케일 제한 (태블릿에서 너무 커지지 않도록)
    if (scale > 2.0) scale = 2.0;
  }

  /// 너비 비율 적용
  static double w(double width) {
    return width * scaleWidth;
  }

  /// 높이 비율 적용
  static double h(double height) {
    return height * scaleHeight;
  }

  /// 전체 비율 적용 (정사각형 요소, 폰트 등)
  static double sp(double size) {
    return size * scale;
  }

  /// 폰트 크기 (최소/최대 제한 포함)
  static double fontSize(double size, {double? min, double? max}) {
    double scaled = size * scale;
    if (min != null && scaled < min) return min;
    if (max != null && scaled > max) return max;
    return scaled;
  }

  /// 패딩/마진용
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(sp(all));
    }
    return EdgeInsets.only(
      left: sp(left ?? horizontal ?? 0),
      top: sp(top ?? vertical ?? 0),
      right: sp(right ?? horizontal ?? 0),
      bottom: sp(bottom ?? vertical ?? 0),
    );
  }

  /// 화면 타입 판별 (짧은 축 기준)
  static double get shortestSide => screenWidth < screenHeight ? screenWidth : screenHeight;
  static bool get isMobile => shortestSide < 600;
  static bool get isTablet => shortestSide >= 600 && shortestSide < 900;
  static bool get isDesktop => shortestSide >= 900;

  /// 디바이스 방향
  static bool get isPortrait => screenHeight > screenWidth;
  static bool get isLandscape => screenWidth > screenHeight;
}

/// 반응형 위젯 래퍼
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);
    return builder(context, Responsive());
  }
}

/// 숫자 확장 메서드로 편리하게 사용
extension ResponsiveExtension on num {
  /// 너비 비율 적용
  double get w => Responsive.w(toDouble());

  /// 높이 비율 적용
  double get h => Responsive.h(toDouble());

  /// 전체 비율 적용 (폰트, 아이콘 등)
  double get sp => Responsive.sp(toDouble());
}
