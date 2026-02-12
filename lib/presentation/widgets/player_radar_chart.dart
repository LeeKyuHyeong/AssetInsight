import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// 8각형 레이더 차트 위젯 (통합)
///
/// title_screen의 CompactRadarChartPainter 스타일을 기준으로 통일.
/// - 5단계 그리드
/// - 축선
/// - 꼭짓점에 라벨 + 능력치 수치
/// - 중앙에 등급 + 레벨 (옵션)
/// - 컨디션 이중 폴리곤 (옵션): 기본 능력치 vs 유효 능력치 비교 표시
class PlayerRadarChart extends StatelessWidget {
  final PlayerStats stats;
  final Color color;
  final String? grade;
  final int? level;
  /// 컨디션 적용된 유효 능력치 (null이면 단일 폴리곤)
  final PlayerStats? effectiveStats;
  /// 컨디션 퍼센트 (100 = 기본, >100 = 부스트, <100 = 감소)
  final int? conditionPercent;

  const PlayerRadarChart({
    super.key,
    required this.stats,
    required this.color,
    this.grade,
    this.level,
    this.effectiveStats,
    this.conditionPercent,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlayerRadarChartPainter(
        stats: stats,
        color: color,
        grade: grade,
        level: level,
        effectiveStats: effectiveStats,
        conditionPercent: conditionPercent,
      ),
      size: Size.infinite,
    );
  }
}

class _PlayerRadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  final Color color;
  final String? grade;
  final int? level;
  final PlayerStats? effectiveStats;
  final int? conditionPercent;

  static const _labels = ['센스', '컨트롤', '공격력', '견제', '전략', '물량', '수비력', '정찰'];

  _PlayerRadarChartPainter({
    required this.stats,
    required this.color,
    this.grade,
    this.level,
    this.effectiveStats,
    this.conditionPercent,
  });

  /// 정규화된 값으로 8각형 경로 생성
  Path _buildPolygonPath(List<double> values, Offset center, double radius, int sides) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final value = values[i].clamp(0.0, 1.0);
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 28;
    const sides = 8;

    final baseValues = stats.toRadarData();
    final rawValues = [
      stats.sense, stats.control, stats.attack, stats.harass,
      stats.strategy, stats.macro, stats.defense, stats.scout,
    ];

    // 배경 그리드 (5단계)
    final gridPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var lvl = 1; lvl <= 5; lvl++) {
      final levelRadius = radius * lvl / 5;
      final path = Path();
      for (var i = 0; i < sides; i++) {
        final angle = (i * 2 * pi / sides) - pi / 2;
        final point = Offset(
          center.dx + levelRadius * cos(angle),
          center.dy + levelRadius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 축선
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, gridPaint);
    }

    // 컨디션 이중 폴리곤 or 단일 폴리곤
    final hasConditionEffect = effectiveStats != null &&
        conditionPercent != null &&
        conditionPercent != 100;

    if (hasConditionEffect) {
      final effValues = effectiveStats!.toRadarData();
      final isBoosted = conditionPercent! > 100;

      if (isBoosted) {
        // 컨디션 > 100%: 유효 능력치가 더 큼
        // 1) 유효 폴리곤 (큰 쪽) - 초록빛 배경
        final effPath = _buildPolygonPath(effValues, center, radius, sides);
        canvas.drawPath(effPath, Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill);
        canvas.drawPath(effPath, Paint()
          ..color = Colors.greenAccent.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

        // 2) 기본 폴리곤 (작은 쪽) - 등급 색상
        final basePath = _buildPolygonPath(baseValues, center, radius, sides);
        canvas.drawPath(basePath, Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill);
        canvas.drawPath(basePath, Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      } else {
        // 컨디션 < 100%: 기본 능력치가 더 큼
        // 1) 기본 폴리곤 (큰 쪽) - 등급 색상
        final basePath = _buildPolygonPath(baseValues, center, radius, sides);
        canvas.drawPath(basePath, Paint()
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill);
        canvas.drawPath(basePath, Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

        // 2) 유효 폴리곤 (작은 쪽) - 붉은빛 강조
        final effPath = _buildPolygonPath(effValues, center, radius, sides);
        canvas.drawPath(effPath, Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill);
        canvas.drawPath(effPath, Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
      }
    } else {
      // 컨디션 100% 또는 컨디션 정보 없음: 기존 단일 폴리곤
      final dataPath = _buildPolygonPath(baseValues, center, radius, sides);
      canvas.drawPath(dataPath, Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill);
      canvas.drawPath(dataPath, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }

    // 라벨 + 수치
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final labelRadius = radius + 22;
      var point = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      textPainter.text = TextSpan(
        children: [
          TextSpan(
            text: '${_labels[i]}\n',
            style: TextStyle(color: Colors.grey[400], fontSize: 9),
          ),
          TextSpan(
            text: '${rawValues[i]}',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      );
      textPainter.textAlign = TextAlign.center;
      textPainter.layout();

      point = Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, point);
    }

    // 중앙에 등급 + 레벨 표시
    if (grade != null && level != null) {
      final gradePainter = TextPainter(textDirection: TextDirection.ltr);
      gradePainter.text = TextSpan(
        children: [
          TextSpan(
            text: '$grade\n',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: 'Lv.$level',
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
        ],
      );
      gradePainter.textAlign = TextAlign.center;
      gradePainter.layout();
      gradePainter.paint(
        canvas,
        Offset(center.dx - gradePainter.width / 2, center.dy - gradePainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerRadarChartPainter oldDelegate) {
    return stats != oldDelegate.stats ||
        color != oldDelegate.color ||
        grade != oldDelegate.grade ||
        level != oldDelegate.level ||
        effectiveStats != oldDelegate.effectiveStats ||
        conditionPercent != oldDelegate.conditionPercent;
  }
}
