# MyStar 구현 TODO

> 마지막 업데이트: 2026-02-04

---

## 구현 현황 요약

| 구분 | 완료 | 미완료 |
|------|------|--------|
| 핵심 시스템 | 7개 | 0개 |
| 화면 | 22개 | 0개 |
| AI/시즌 시스템 | 6개 | 0개 |
| 부가 기능 | 7개 | 0개 |

---

## 남은 구현 항목

### 🟢 우선순위 낮음

#### 밸런싱
- [ ] 아이템 가격 밸런싱
- [ ] 전체 시즌 플레이 테스트

---

## 구현 완료 항목 ✅

### 핵심 시스템
- [x] 데이터 모델 (Player, Team, Match, Season, Item, Equipment, Inventory)
- [x] 상태 관리 (Riverpod - `game_provider.dart`)
- [x] 저장/로드 (Hive - `save_repository.dart`)
- [x] 경기 시뮬레이션 엔진 (`match_simulation_service.dart`)
- [x] 빌드오더 기반 시뮬레이션 (`build_orders.dart`)
- [x] 14경기 + 개인리그 일정 자동 생성
- [x] 선수 성장/하락 시스템
- [x] 선수 vs 선수 상대 전적 기록 (`applyMatchResult`)

### 화면 (22개 완료)
- [x] 타이틀 화면 - 팀 선택, 로스터 순환, 레이더 차트
- [x] 감독명 입력 화면
- [x] 팀 선택 화면
- [x] 맵 추첨 화면
- [x] 이적 화면 - Scout/Trade/Fire
- [x] 메인 메뉴 화면 - 14경기 일정 표시
- [x] 로스터 선택 화면 - 맵 정보, 상대 로스터 확인
- [x] 경기 시뮬레이션 화면 - 텍스트 로그, 배속 조절, 전적 업데이트
- [x] 저장/로드 화면
- [x] 선수 정보 화면 - 상대 전적, 사진 등록 포함
- [x] 선수 순위 화면
- [x] 구단 순위 화면
- [x] 연습경기 화면
- [x] 시즌 종료 화면
- [x] 위너스리그 화면
- [x] PC방 예선 토너먼트 (`/individual-league/pcbang`)
- [x] 듀얼토너먼트 (`/individual-league/dual/:round`)
- [x] 조지명식 (`/individual-league/group-draw`)
- [x] 본선 토너먼트 (`/individual-league/main/:stage`)
- [x] 아이템 상점 화면 - 소모품/장비 구매, 카테고리 필터, 인벤토리
- [x] 행동 관리 화면 - 휴식/특훈/팬미팅, 컨디션 관리
- [x] 정보 화면 - 선수 정보/팀 정보 탭, 순위 이동
- [x] 장비 관리 화면 - 장착/해제, 슬롯별 관리

### AI/시즌 시스템
- [x] AI 컨디션 관리 (80% 이하면 휴식)
- [x] AI 특훈 (주 2명, 레벨 낮은 선수 우선)
- [x] AI 팬미팅 (2주마다 2명, 등급 높은 선수 우선)
- [x] AI 아이템 구매 (주 1회 2명에게 비타비타)
- [x] 시즌 완료 처리 (레벨업, 은퇴, 신인 생성)
- [x] 플레이오프 UI (3/4위전 → 2/3위전 → 결승전)

### 부가 기능
- [x] 선수 사진 등록 (갤러리에서 선택, 앱 내부 저장)
- [x] R 버튼 (Reset) 전체 화면 적용
- [x] Preview 모드 (gameState 없을 때 샘플 데이터)
- [x] go_router 라우팅 설정
- [x] 반응형 레이아웃 (Responsive.sp)
- [x] 승리 보상 시스템 (+5만원/경기)
- [x] 대회 상금 시스템 (프로리그/개인리그 우승/준우승)

---

## 확정된 게임 규칙

| 항목 | 내용 |
|------|------|
| 로스터 | 최소 10명 |
| 경기 형식 | 7전 4선승제 |
| 배속 | x1 / x4 / x8 |
| 능력치 | 센스/컨트롤/공격력/견제/전략/물량/수비력/정찰 (8개) |
| 등급 | F- ~ SSS (25단계) |
| 레벨 | 1~10 (2시즌마다 +1) |
| 컨디션 | 내부 0~110, 표시 0~100 |
| 경기 후 컨디션 | 승리 -4, 패배 -5 |
| 승률 계산 | 능력치 50당 1% (최대 ±40%) |
| 승패 조건 | 병력 4:1 격차 또는 200줄 강제 판정 |
| 승리 보상 | +5만원/경기 (프로리그, 플레이오프) |
| 프로리그 상금 | 우승 150만원, 준우승 70만원 |
| 개인리그 상금 | 우승 80만원, 준우승 40만원 |

---

## 파일 구조

```
lib/
├── app/
│   ├── routes.dart            # go_router 설정 (22개 화면)
│   └── theme.dart             # 테마 (AppColors, AppTheme)
├── core/
│   ├── constants/
│   │   ├── initial_data.dart  # 8팀 선수 데이터
│   │   ├── build_orders.dart  # 빌드오더/이벤트
│   │   └── battle_events.dart # 전투 이벤트
│   └── utils/
│       └── responsive.dart    # 반응형 유틸
├── data/
│   ├── providers/
│   │   ├── game_provider.dart # 게임 상태 관리
│   │   └── match_provider.dart# 매치 상태 관리
│   └── repositories/
│       └── save_repository.dart # Hive 저장/로드
├── domain/
│   ├── models/                # Player, Team, Season, Item 등
│   └── services/
│       ├── match_simulation_service.dart
│       ├── individual_league_service.dart
│       └── playoff_service.dart
└── presentation/
    ├── widgets/
    │   └── reset_button.dart
    └── screens/
        ├── title/             # 타이틀 화면
        ├── main_menu/         # 메인 메뉴 (일정 표시)
        ├── roster_select/     # 로스터 선택
        ├── match_simulation/  # 경기 시뮬레이션
        ├── individual_league/ # PC방예선, 듀얼토너먼트, 조지명식, 본선
        ├── playoff/           # 플레이오프
        ├── info/              # 정보 화면 (선수/팀)
        ├── shop/              # 아이템 상점
        ├── action/            # 행동 관리 (휴식/특훈/팬미팅)
        ├── equipment/         # 장비 관리 (장착/해제)
        ├── player_ranking/    # 선수 순위
        ├── team_ranking/      # 구단 순위
        ├── transfer/          # 이적 시장
        ├── season_map_draw/   # 맵 추첨
        ├── season_schedule/   # 시즌 일정
        ├── save_load/         # 저장/로드
        └── practice_match/    # 연습 경기
```
