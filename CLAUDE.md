# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyStar - 스타크래프트 프로게이머/팀 육성 시뮬레이션 게임 (Flutter Android App)

## Build Commands

```bash
# 릴리스 APK 빌드
flutter build apk --release

# Hive 모델 변경 시 코드 생성
dart run build_runner build --delete-conflicting-outputs

# 앱 실행
flutter run
```

## Architecture

**Stack**: Flutter + Riverpod (상태관리) + Hive (로컬 저장) + GoRouter (라우팅)

```
lib/
├── app/              # 앱 설정 (theme.dart, routes.dart, app.dart)
├── core/
│   ├── constants/    # 초기 데이터 (team_data, initial_data, build_orders, battle_events)
│   └── utils/        # Responsive 유틸리티
├── data/
│   ├── providers/    # Riverpod providers (game_provider, match_provider)
│   └── repositories/ # Hive 저장소 (save_repository)
├── domain/
│   ├── models/       # 데이터 모델 (Player, Team, Match, Season, Item 등)
│   └── services/     # 비즈니스 로직 (match_simulation_service, individual_league_service, playoff_service)
└── presentation/
    ├── screens/      # 화면별 UI (title, main_menu, match_simulation 등)
    └── widgets/      # 공통 위젯
```

## Key Components

### State Management (`game_provider.dart`)
- `gameStateProvider`: 전체 게임 상태 관리 (StateNotifierProvider)
- `GameState`: SaveData를 감싸는 상태 객체 (playerTeam, currentSeason, inventory 등)
- `GameStateNotifier`: 게임 로직 메서드 (startNewGame, loadGame, save, updatePlayer 등)

### Models (`domain/models/`)
- `Player`: 선수 (능력치 8개: sense, control, attack, harass, strategy, macro, defense, scout)
- `PlayerStats`: 능력치 클래스 (컨디션 적용, 성장/하락 로직 포함)
- `Team`: 팀 (players, money, actionPoints)
- `Match`: 경기 정보 (7전 4선승제)
- `Season`: 시즌 (프로리그 + 개인리그)
- Hive 어노테이션 사용 (`@HiveType`, `@HiveField`) - 모델 변경 시 `build_runner` 실행 필요

### Match Simulation (`match_simulation_service.dart`)
- 빌드오더 기반 경기 시뮬레이션
- `SimulationState`: 병력/자원/로그 상태
- `BattleLogEntry`: 로그 텍스트 + 소유자(home/away/system)

### Responsive System (`core/utils/responsive.dart`)
- `Responsive.sp(size)`: 전체 비율 적용 (폰트, 아이콘)
- `Responsive.w(width)`: 너비 비율 적용
- `Responsive.h(height)`: 높이 비율 적용
- Extension: `14.sp`, `100.w`, `50.h`

## UI/Layout Rules

- **가로 스크롤 금지**: 모든 화면 360~412dp 내 표시
- **Overflow 방지**: `Expanded`, `Flexible`, `TextOverflow.ellipsis` 사용
- **반응형 크기**: `Responsive.sp()` 사용 (고정 픽셀 금지)
- **기준 해상도**: 360 x 800 (세로 모드 고정)

## Game Design Reference

게임 디자인 상세 문서는 `GAME_DESIGN.md` 참조:
- 선수 시스템 (능력치, 등급, 레벨, 컨디션)
- 성장/하락 시스템
- 경기 시뮬레이션 규칙
- 시즌 시스템
- 아이템/장비 시스템
- 이적 시장
