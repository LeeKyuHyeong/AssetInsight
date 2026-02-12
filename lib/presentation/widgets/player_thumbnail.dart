import 'dart:io';
import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/repositories/player_image_repository.dart';
import '../../domain/models/player.dart';

/// 선수 썸네일 이미지 위젯
/// 이미지가 있으면 사진, 없으면 종족 코드(T/Z/P) 표시
class PlayerThumbnail extends StatelessWidget {
  final Player player;
  final double size; // .sp 적용 전 값
  final bool isMyTeam;
  final BorderRadius? borderRadius;

  const PlayerThumbnail({
    super.key,
    required this.player,
    required this.size,
    this.isMyTeam = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final imagePath = PlayerImageRepository.instance.getImagePath(player.id);
    final raceColor = AppTheme.getRaceColor(player.race.code);
    final borderColor = isMyTeam ? Colors.lightBlueAccent : raceColor;
    final borderWidth = isMyTeam ? 1.5 : 1.0;
    final resolvedRadius = borderRadius ?? BorderRadius.circular(size.sp * 0.2);

    return Container(
      width: size.sp,
      height: size.sp,
      decoration: BoxDecoration(
        borderRadius: resolvedRadius,
        border: Border.all(color: borderColor, width: borderWidth),
        color: Colors.grey[900],
      ),
      child: ClipRRect(
        borderRadius: resolvedRadius.subtract(BorderRadius.circular(borderWidth)),
        child: imagePath != null
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildRaceCode(raceColor),
              )
            : _buildRaceCode(raceColor),
      ),
    );
  }

  Widget _buildRaceCode(Color raceColor) {
    return Center(
      child: Text(
        player.race.code,
        style: TextStyle(
          color: raceColor,
          fontSize: (size * 0.45).sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
