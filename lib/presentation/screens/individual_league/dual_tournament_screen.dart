import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 듀얼토너먼트 화면 - 12개 조 (3개 라운드 × 4개 조)
class DualTournamentScreen extends ConsumerStatefulWidget {
  final int round; // 1, 2, 3 (어떤 듀얼 토너먼트인지)
  final bool viewOnly;

  const DualTournamentScreen({super.key, this.round = 1, this.viewOnly = false});

  @override
  ConsumerState<DualTournamentScreen> createState() =>
      _DualTournamentScreenState();
}

class _DualTournamentScreenState extends ConsumerState<DualTournamentScreen> {
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  bool _isSimulating = false;
  bool _isCompleted = false;
  String _currentMatchInfo = '';

  // 조 이름 (A~L)
  static const groupNames = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

  // 현재 라운드의 조 인덱스 범위
  int get _startGroupIndex => (widget.round - 1) * 4;
  int get _endGroupIndex => widget.round * 4;

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.sp),
                    child: Column(
                      children: [
                        // 상단 정보 패널
                        _buildTopInfoPanel(bracket, playerMap),
                        SizedBox(height: 8.sp),
                        // 4개 조 그리드 (2x2)
                        Expanded(
                          child: Column(
                            children: [
                              // 상단 2개 조 (A/E/I, B/F/J)
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex, // A/E/I 조
                                      ),
                                    ),
                                    SizedBox(width: 8.sp),
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 1, // B/F/J 조
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8.sp),
                              // 하단 2개 조 (C/G/K, D/H/L)
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 2, // C/G/K 조
                                      ),
                                    ),
                                    SizedBox(width: 8.sp),
                                    Expanded(
                                      child: _buildGroupCard(
                                        bracket,
                                        playerMap,
                                        _startGroupIndex + 3, // D/H/L 조
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(context, bracket, playerMap),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
          const Spacer(),
          Text(
            '듀얼 토너먼트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_drop_down, color: Colors.white, size: 24.sp),
        ],
      ),
    );
  }

  Widget _buildGroupCard(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupName = groupIndex < groupNames.length ? groupNames[groupIndex] : '?';

    // 조 데이터 가져오기
    List<String?> groupPlayers = [];
    if (bracket != null &&
        bracket.dualTournamentGroups.isNotEmpty &&
        groupIndex < bracket.dualTournamentGroups.length) {
      groupPlayers = bracket.dualTournamentGroups[groupIndex];
    }

    // 4명 슬롯 보장
    while (groupPlayers.length < 4) {
      groupPlayers = [...groupPlayers, null];
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      padding: EdgeInsets.all(6.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 조 헤더 (조 이름 + 4명 슬롯)
          Row(
            children: [
              // 조 로고/이름
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Text(
                  '$groupName조',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 4.sp),
              // 4명 슬롯 미니 표시 - Expanded로 감싸기
              Expanded(
                child: Row(
                  children: List.generate(4, (i) {
                    final playerId = i < groupPlayers.length ? groupPlayers[i] : null;
                    final player = playerId != null ? playerMap[playerId] : null;
                    return Expanded(child: _buildMiniPlayerSlot(player, i));
                  }),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.sp),
          // 대진표
          Expanded(
            child: _buildGroupBracket(groupPlayers, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayerSlot(Player? player, int index) {
    final isSeeded = index < 2; // 0, 1번은 시드

    return Container(
      height: 20.sp,
      margin: EdgeInsets.only(left: 2.sp),
      decoration: BoxDecoration(
        color: player != null
            ? AppColors.primary.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(3.sp),
        border: Border.all(
          color: isSeeded ? AppColors.primary : Colors.grey,
          width: isSeeded ? 1.5 : 1,
        ),
      ),
      child: Center(
        child: player != null
            ? Text(
                player.race.code,
                style: TextStyle(
                  color: _getRaceColor(player.race),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                ),
              )
            : Text(
                '?',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 8.sp,
                ),
              ),
      ),
    );
  }

  Widget _buildGroupBracket(List<String?> groupPlayers, Map<String, Player> playerMap) {
    // 듀얼 토너먼트 대진표
    // 1경기: 0 vs 2 (1시드 vs PC방 승자)
    // 2경기: 1 vs 3 (3시드 vs PC방 승자)
    // 승자전: 1경기 승자 vs 2경기 승자
    // 패자전: 1경기 패자 vs 2경기 패자
    // 최종전: 승자전 패자 vs 패자전 승자

    final player0 = groupPlayers.length > 0 && groupPlayers[0] != null
        ? playerMap[groupPlayers[0]] : null;
    final player1 = groupPlayers.length > 1 && groupPlayers[1] != null
        ? playerMap[groupPlayers[1]] : null;
    final player2 = groupPlayers.length > 2 && groupPlayers[2] != null
        ? playerMap[groupPlayers[2]] : null;
    final player3 = groupPlayers.length > 3 && groupPlayers[3] != null
        ? playerMap[groupPlayers[3]] : null;

    return Column(
      children: [
        // 1경기: 1시드 vs PC방 승자
        Expanded(
          child: _buildSeededMatchRow(
            player0, '1시드',
            player2, 'PC방',
          ),
        ),
        // 2경기: 3시드 vs PC방 승자
        Expanded(
          child: _buildSeededMatchRow(
            player1, '3시드',
            player3, 'PC방',
          ),
        ),
        // 승자전
        Expanded(
          child: _buildMatchRow('< 승자전 >', null, null, placeholder: '???'),
        ),
        // 패자전
        Expanded(
          child: _buildMatchRow('< 패자전 >', null, null, placeholder: '???'),
        ),
        // 최종전
        Expanded(
          child: _buildMatchRow('< 최종전 >', null, null, placeholder: '???'),
        ),
      ],
    );
  }

  /// 시드 정보가 포함된 대진 행
  Widget _buildSeededMatchRow(Player? player1, String seed1, Player? player2, String seed2) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1.sp),
      child: Row(
        children: [
          // 왼쪽 선수 (시드)
          Expanded(
            child: _buildSeededPlayerSlot(player1, seed1),
          ),
          // VS
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.sp),
            child: Text(
              'vs',
              style: TextStyle(color: Colors.grey, fontSize: 9.sp),
            ),
          ),
          // 오른쪽 선수 (PC방 승자)
          Expanded(
            child: _buildSeededPlayerSlot(player2, seed2),
          ),
        ],
      ),
    );
  }

  /// 시드 정보가 포함된 선수 슬롯
  Widget _buildSeededPlayerSlot(Player? player, String seedLabel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: player != null
            ? AppColors.primary.withOpacity(0.15)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3.sp),
        border: Border.all(
          color: player != null
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 시드 라벨
          Text(
            seedLabel,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 7.sp,
            ),
          ),
          // (종족) 이름
          if (player != null)
            Row(
              children: [
                Text(
                  '(${player.race.code})',
                  style: TextStyle(
                    color: _getRaceColor(player.race),
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 2.sp),
                Expanded(
                  child: Text(
                    player.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          else
            Text(
              'empty',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 9.sp,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchRow(String title, Player? player1, Player? player2, {String placeholder = '???'}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 2.sp),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _buildPlayerName(player1, placeholder),
            ),
            Text(
              ' vs ',
              style: TextStyle(color: Colors.grey, fontSize: 8.sp),
            ),
            Expanded(
              child: _buildPlayerName(player2, placeholder),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayerName(Player? player, String placeholder) {
    if (player == null) {
      return Text(
        placeholder,
        style: TextStyle(color: Colors.grey, fontSize: 10.sp),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      );
    }

    // "(종족) 이름" 형식으로 표시
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '(${player.race.code})',
          style: TextStyle(
            color: _getRaceColor(player.race),
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 2.sp),
        Flexible(
          child: Text(
            player.name,
            style: TextStyle(color: Colors.white, fontSize: 10.sp),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTopInfoPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
      child: Row(
        children: [
          // 라운드 표시
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              '#${widget.round}',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.sp),
          // 상태 메시지
          Expanded(
            child: _isSimulating
                ? Row(
                    children: [
                      SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: const CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Text(
                        '경기 진행중${_currentMatchInfo.isNotEmpty ? ' - $_currentMatchInfo' : ''}',
                        style: TextStyle(color: Colors.white, fontSize: 12.sp),
                      ),
                    ],
                  )
                : _isCompleted
                    ? Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.accent, size: 20.sp),
                          SizedBox(width: 8.sp),
                          Text(
                            '완료!',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        '진행되지 않았습니다',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12.sp,
                        ),
                      ),
          ),
          // 맵 정보
          Row(
            children: [
              Text(
                '맵: ',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                '네오아웃라이어 / 네오제이드 / 네오체인리액션',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    final bool canStart = !widget.viewOnly && !_isSimulating;

    return Container(
      padding: EdgeInsets.all(12.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                context.pop();
              } else {
                context.go('/main');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  'EXIT (Bar)',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.sp),
          if (canStart)
            ElevatedButton(
              onPressed: _isCompleted
                  ? () => _goToNextStage(context)
                  : () => _startSimulation(bracket, playerMap),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
              ),
              child: Row(
                children: [
                  Text(
                    _isCompleted ? 'Next' : 'Start',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.sp),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16.sp),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _startSimulation(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) async {
    if (bracket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('대진표 데이터가 없습니다')),
      );
      return;
    }

    setState(() {
      _isSimulating = true;
    });

    // 시뮬레이션 애니메이션
    for (var i = _startGroupIndex; i < _endGroupIndex; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _currentMatchInfo = '${groupNames[i]}조 경기 진행중...';
      });
    }

    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: 실제 시뮬레이션 로직 구현

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
    });
  }

  void _goToNextStage(BuildContext context) {
    if (widget.round < 3) {
      // 다음 듀얼 토너먼트
      context.push('/dual-tournament/${widget.round + 1}');
    } else {
      // 조지명식으로
      context.push('/group-draw');
    }
  }

  Color _getRaceColor(Race race) {
    switch (race) {
      case Race.terran:
        return AppColors.terran;
      case Race.zerg:
        return AppColors.zerg;
      case Race.protoss:
        return AppColors.protoss;
    }
  }
}
