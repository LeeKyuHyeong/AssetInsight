import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'data/repositories/save_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 전체 화면 모드 (상태바, 네비게이션바 숨김)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  // Hive 초기화
  await Hive.initFlutter();

  // 세이브 데이터 초기화 (첫 시즌용 - 세이브 파일 없음)
  final saveRepository = SaveRepository();
  await saveRepository.clearAllSaves();

  runApp(
    const ProviderScope(
      child: MyStarApp(),
    ),
  );
}
