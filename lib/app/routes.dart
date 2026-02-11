import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/title/title_screen.dart';
import '../presentation/screens/team_select/team_select_screen.dart';
import '../presentation/screens/main_menu/main_menu_screen.dart';
import '../presentation/screens/roster_select/roster_select_screen.dart';
import '../presentation/screens/match_simulation/match_simulation_screen.dart';
import '../presentation/screens/save_load/save_load_screen.dart';
import '../presentation/screens/transfer/transfer_screen.dart';
import '../presentation/screens/practice_match/practice_match_screen.dart';
import '../presentation/screens/team_ranking/team_ranking_screen.dart';
import '../presentation/screens/individual_league/pcbang_qualifier_screen.dart';
import '../presentation/screens/individual_league/dual_tournament_screen.dart';
import '../presentation/screens/individual_league/group_draw_screen.dart';
import '../presentation/screens/individual_league/main_tournament_screen.dart';
import '../presentation/screens/individual_league/individual_semifinal_screen.dart';
import '../presentation/screens/individual_league/individual_final_screen.dart';
import '../presentation/screens/player_ranking/player_ranking_screen.dart';
import '../presentation/screens/match_result/match_result_ranking_screen.dart';
import '../presentation/screens/season_end/season_end_screen.dart';
import '../presentation/screens/winners_league/wl_roster_select_screen.dart';
import '../presentation/screens/director_name/director_name_screen.dart';
import '../presentation/screens/season_map_draw/season_map_draw_screen.dart';
import '../presentation/screens/shop/shop_screen.dart';
import '../presentation/screens/info/info_screen.dart';
import '../presentation/screens/action/action_screen.dart';
import '../presentation/screens/playoff/playoff_schedule_screen.dart';
import '../presentation/screens/equipment/equipment_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'title',
        builder: (context, state) => const TitleScreen(),
      ),
      GoRoute(
        path: '/team-select',
        name: 'teamSelect',
        builder: (context, state) => const TeamSelectScreen(),
      ),
      GoRoute(
        path: '/main',
        name: 'main',
        builder: (context, state) => const MainMenuScreen(),
      ),
      GoRoute(
        path: '/roster-select',
        name: 'rosterSelect',
        builder: (context, state) => const RosterSelectScreen(),
      ),
      GoRoute(
        path: '/match',
        name: 'match',
        builder: (context, state) => const MatchSimulationScreen(),
      ),
      GoRoute(
        path: '/save-load',
        name: 'saveLoad',
        builder: (context, state) => const SaveLoadScreen(),
      ),
      GoRoute(
        path: '/transfer',
        name: 'transfer',
        builder: (context, state) => const TransferScreen(),
      ),
      GoRoute(
        path: '/practice-match',
        name: 'practiceMatch',
        builder: (context, state) => const PracticeMatchScreen(),
      ),
      GoRoute(
        path: '/team-ranking',
        name: 'teamRanking',
        builder: (context, state) => const TeamRankingScreen(),
      ),
      // 개인리그 화면들
      GoRoute(
        path: '/individual-league/pcbang',
        name: 'pcbangQualifier',
        builder: (context, state) {
          final viewOnly = state.uri.queryParameters['viewOnly'] == 'true';
          return PcBangQualifierScreen(viewOnly: viewOnly);
        },
      ),
      GoRoute(
        path: '/individual-league/dual/:round',
        name: 'dualTournament',
        builder: (context, state) {
          final round = int.tryParse(state.pathParameters['round'] ?? '1') ?? 1;
          final viewOnly = state.uri.queryParameters['viewOnly'] == 'true';
          return DualTournamentScreen(round: round, viewOnly: viewOnly);
        },
      ),
      GoRoute(
        path: '/individual-league/group-draw',
        name: 'groupDraw',
        builder: (context, state) {
          final viewOnly = state.uri.queryParameters['viewOnly'] == 'true';
          return GroupDrawScreen(viewOnly: viewOnly);
        },
      ),
      GoRoute(
        path: '/individual-league/main/semifinal',
        name: 'individualSemiFinal',
        builder: (context, state) => const IndividualSemiFinalScreen(),
      ),
      GoRoute(
        path: '/individual-league/main/final',
        name: 'individualFinal',
        builder: (context, state) => const IndividualFinalScreen(),
      ),
      GoRoute(
        path: '/individual-league/main/:stage',
        name: 'mainTournament',
        builder: (context, state) {
          final stage = state.pathParameters['stage'] ?? '32';
          final viewOnly = state.uri.queryParameters['viewOnly'] == 'true';
          return MainTournamentScreen(stage: stage, viewOnly: viewOnly);
        },
      ),
      GoRoute(
        path: '/player-ranking',
        name: 'playerRanking',
        builder: (context, state) => const PlayerRankingScreen(),
      ),
      GoRoute(
        path: '/match-result-ranking',
        name: 'matchResultRanking',
        builder: (context, state) => const MatchResultRankingScreen(),
      ),
      GoRoute(
        path: '/season-end',
        name: 'seasonEnd',
        builder: (context, state) => const SeasonEndScreen(),
      ),
      GoRoute(
        path: '/wl-roster-select',
        name: 'wlRosterSelect',
        builder: (context, state) => const WLRosterSelectScreen(),
      ),
      // 새 게임 시작 플로우
      GoRoute(
        path: '/director-name',
        name: 'directorName',
        builder: (context, state) => const DirectorNameScreen(),
      ),
      GoRoute(
        path: '/season-map-draw',
        name: 'seasonMapDraw',
        builder: (context, state) => const SeasonMapDrawScreen(),
      ),
      GoRoute(
        path: '/initial-recruit',
        name: 'initialRecruit',
        builder: (context, state) => const TransferScreen(isInitialRecruit: true),
      ),
      // 상점, 정보, 행동 화면
      GoRoute(
        path: '/shop',
        name: 'shop',
        builder: (context, state) => const ShopScreen(),
      ),
      GoRoute(
        path: '/info',
        name: 'info',
        builder: (context, state) {
          final teamId = state.uri.queryParameters['teamId'];
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return InfoScreen(initialTeamId: teamId, initialTab: tab);
        },
      ),
      GoRoute(
        path: '/action',
        name: 'action',
        builder: (context, state) => const ActionScreen(),
      ),
      // 플레이오프 화면
      GoRoute(
        path: '/playoff',
        name: 'playoff',
        builder: (context, state) => const PlayoffScheduleScreen(),
      ),
      // 장비 관리 화면
      GoRoute(
        path: '/equipment',
        name: 'equipment',
        builder: (context, state) => const EquipmentScreen(),
      ),
      // 설정 화면
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
