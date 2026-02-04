import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 모든 방향 허용 (사용자가 필요에 따라 회전)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 전체 화면 모드 (상태바, 네비게이션바 숨김)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Hive 초기화
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: MyStarApp(),
    ),
  );
}
