import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/map_data.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../../data/providers/match_provider.dart';
import '../../../domain/models/models.dart';
import '../../widgets/player_radar_chart.dart';
import '../../widgets/reset_button.dart';

/// 위너스리그 로스터 선택 화면 (1번 맵 선수 1명만 선택)
class WLRosterSelectScreen extends ConsumerStatefulWidget {
  const WLRosterSelectScreen({super.key});

  @override
  ConsumerState<WLRosterSelectScreen> createState() => _WLRosterSelectScreenState();
}

class _WLRosterSelectScreenState extends ConsumerState<WLRosterSelectScreen> {
  int? _selectedPlayerIndex;
  int? _detailPlayerIndex;

  // 스나이핑 관련
  List<SnipingAssignment> _snipingAssignments = [];
  bool _isSnipingMode = false;

  // 컨디션 최상/최악 이벤트가 이미 적용되었는지 여부
  bool _conditionRolled = false;

  ScheduleItem? _findNextMatch(List<ScheduleItem> schedule, String playerTeamId) {
    final myIncompleteMatches = schedule.where((s) =>
      !s.isCompleted &&
      (s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId)
    ).toList();

    if (myIncompleteMatches.isEmpty) return null;
    myIncompleteMatches.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return myIncompleteMatches.first;
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('게임 데이터를 불러올 수 없습니다')),
      );
    }

    final playerTeam = gameState.playerTeam;
    final teamPlayers = gameState.playerTeamPlayers;
    final schedule = gameState.saveData.currentSeason.proleagueSchedule;
    final nextMatch = _findNextMatch(schedule, playerTeam.id);

    if (nextMatch == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/main');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isHome = nextMatch.homeTeamId == playerTeam.id;
    final opponentId = isHome ? nextMatch.awayTeamId : nextMatch.homeTeamId;
    final opponentTeam = gameState.saveData.getTeamById(opponentId) ??
        gameState.saveData.allTeams.firstWhere((t) => t.id != playerTeam.id);
    final opponentPlayers = gameState.saveData.getTeamPlayers(opponentId);

    // 1번 맵 정보
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;
    final firstMapId = seasonMapIds.isNotEmpty ? seasonMapIds[0] : null;
    final firstMap = firstMapId != null ? GameMaps.getById(firstMapId) : null;

    // 로스터 화면 진입 시 전체 팀 선수 대상으로 컨디션 이벤트 롤 (1회만)
    if (!_conditionRolled) {
      _conditionRolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rollConditionsOnEntry(teamPlayers);
      });
    }

    final canSubmit = _selectedPlayerIndex != null;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Winners League'),
        leading: ResetButton.leading(),
        backgroundColor: Colors.amber.withValues(alpha: 0.15),
      ),
      body: Column(
        children: [
          // 상단: 위너스리그 헤더
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 16.sp),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber, size: 20.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      '승자유지 방식',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Icon(Icons.emoji_events, color: Colors.amber, size: 20.sp),
                  ],
                ),
                SizedBox(height: 4.sp),
                Text(
                  '1번 맵 선수를 선택하세요 (4선승제, 에이스전 없음)',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ),

          // 매치 헤더
          _buildMatchHeader(playerTeam, opponentTeam, isHome),

          // 아이템 행
          _buildItemRow(),

          // 1번 맵 정보
          if (firstMap != null) _buildMapInfo(firstMap),

          // 3열 구조
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 내 팀 선수 목록
                Expanded(
                  flex: 3,
                  child: _buildMyTeamSection(teamPlayers),
                ),

                // 중앙: 선택된 선수 상세
                SizedBox(
                  width: 120.sp,
                  child: _buildSelectedPlayerDetail(teamPlayers),
                ),

                // 우측: 상대 팀 선수 목록
                Expanded(
                  flex: 3,
                  child: _buildOpponentSection(opponentPlayers, teamPlayers),
                ),
              ],
            ),
          ),

          // 제출 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            child: SizedBox(
              width: double.infinity,
              height: 44.sp,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () => _submitRoster(playerTeam, opponentTeam, teamPlayers, nextMatch, isHome)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.cardBackground,
                ),
                child: Text(
                  canSubmit ? '출전!' : '선수를 선택하세요',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(Team playerTeam, Team opponentTeam, bool isHome) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.sp, horizontal: 12.sp),
      color: AppTheme.cardBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(playerTeam.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
              Text(isHome ? 'HOME' : 'AWAY',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.sp)),
            ],
          ),
          Text('VS',
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber)),
          Column(
            children: [
              Text(opponentTeam.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.sp)),
              Text(isHome ? 'AWAY' : 'HOME',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 9.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow() {
    final gameState = ref.watch(gameStateProvider);
    final inventory = gameState?.inventory;
    if (inventory == null) return const SizedBox.shrink();

    final consumableItems = ConsumableItems.all.where((item) {
      return inventory.getConsumableCount(item.id) > 0;
    }).toList();

    if (consumableItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4.sp, horizontal: 8.sp),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: consumableItems.map((item) {
          final count = inventory.getConsumableCount(item.id);
          final isSnipingItem = item.id == 'sniping';
          return GestureDetector(
            onTap: isSnipingItem && !_isSnipingMode
                ? () {
                    if (_selectedPlayerIndex == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('먼저 내 선수를 선택하세요'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                      return;
                    }
                    setState(() { _isSnipingMode = true; });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('상대 선수를 예측하여 선택하세요'),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (isSnipingItem && _isSnipingMode)
                    ? Colors.orange.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (isSnipingItem && _isSnipingMode) ? Colors.orange : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSnipingItem ? Icons.visibility : Icons.inventory_2,
                    size: 12,
                    color: isSnipingItem ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 3),
                  Text(item.name,
                      style: TextStyle(
                          fontSize: 8,
                          color: isSnipingItem ? Colors.orange : Colors.grey,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 2),
                  Text('x$count',
                      style: TextStyle(
                          fontSize: 8,
                          color: isSnipingItem ? Colors.orange : Colors.grey)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMapInfo(GameMap map) {
    final mapData = getMapByName(map.name);
    final imageFile = mapData?.imageFile ?? '';

    return Container(
      height: 60.sp,
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      margin: EdgeInsets.symmetric(horizontal: 4.sp),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // 맵 썸네일
          AspectRatio(
            aspectRatio: 1.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.sp),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.sp),
                child: imageFile.isEmpty
                    ? const Icon(Icons.map, size: 24, color: AppTheme.textSecondary)
                    : Image.asset(
                        'assets/maps/$imageFile',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.map, size: 24, color: AppTheme.textSecondary),
                      ),
              ),
            ),
          ),
          SizedBox(width: 8.sp),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 1.sp),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(2.sp),
                      ),
                      child: Text('1st MAP',
                          style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                    ),
                    SizedBox(width: 6.sp),
                    Expanded(
                      child: Text(
                        map.name,
                        style: TextStyle(
                            fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.amber),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.sp),
                Row(
                  children: [
                    Text('T:Z ${map.matchup.tvzTerranWinRate}%',
                        style: TextStyle(fontSize: 8.sp, color: AppTheme.textSecondary)),
                    SizedBox(width: 8.sp),
                    Text('Z:P ${map.matchup.zvpZergWinRate}%',
                        style: TextStyle(fontSize: 8.sp, color: AppTheme.textSecondary)),
                    SizedBox(width: 8.sp),
                    Text('P:T ${map.matchup.pvtProtossWinRate}%',
                        style: TextStyle(fontSize: 8.sp, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamSection(List<Player> teamPlayers) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 3.sp, horizontal: 6.sp),
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          child: Row(
            children: [
              Icon(Icons.person, size: 10.sp, color: AppTheme.primaryBlue),
              SizedBox(width: 3.sp),
              Text('내 팀 (${teamPlayers.length})',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(2.sp),
            itemCount: teamPlayers.length,
            itemBuilder: (context, index) {
              final player = teamPlayers[index];
              final isSelected = _selectedPlayerIndex == index;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlayerIndex = index;
                    _detailPlayerIndex = index;
                    _isSnipingMode = false;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 1.sp),
                  padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGreen.withValues(alpha: 0.3)
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentGreen : Colors.transparent,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('(${player.race.code})',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getRaceColor(player.race.code))),
                      SizedBox(width: 2.sp),
                      Expanded(
                        child: Text(player.name,
                            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 1.sp),
                        decoration: BoxDecoration(
                          color: AppTheme.getGradeColor(player.grade.display),
                          borderRadius: BorderRadius.circular(2.sp),
                        ),
                        child: Text(player.grade.display,
                            style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
                      SizedBox(width: 3.sp),
                      Text('${player.displayCondition}%',
                          style: TextStyle(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                              color: player.displayCondition > 100
                                  ? Colors.amber
                                  : player.displayCondition < 100
                                      ? Colors.redAccent
                                      : AppTheme.textSecondary)),
                      if (isSelected) ...[
                        SizedBox(width: 3.sp),
                        Icon(Icons.check_circle, size: 12.sp, color: AppTheme.accentGreen),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedPlayerDetail(List<Player> teamPlayers) {
    final player = _detailPlayerIndex != null && _detailPlayerIndex! < teamPlayers.length
        ? teamPlayers[_detailPlayerIndex!]
        : null;

    if (player == null) {
      return Container(
        padding: EdgeInsets.all(8.sp),
        child: Center(
          child: Text(
            '선수를 선택하면\n상세 정보가\n표시됩니다',
            style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.sp),
      margin: EdgeInsets.symmetric(vertical: 4.sp),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text('(${player.race.code})',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getRaceColor(player.race.code))),
              SizedBox(width: 2.sp),
              Expanded(
                child: Text(player.name,
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          SizedBox(height: 2.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 1.sp),
                decoration: BoxDecoration(
                  color: AppTheme.getGradeColor(player.grade.display),
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Text(player.grade.display,
                    style: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
              SizedBox(width: 4.sp),
              Text('Lv.${player.level.value}',
                  style: TextStyle(fontSize: 8.sp, color: AppTheme.textSecondary)),
              SizedBox(width: 4.sp),
              Text('${player.displayCondition}%',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: player.displayCondition >= 80 ? Colors.green : Colors.orange)),
            ],
          ),
          SizedBox(height: 4.sp),
          SizedBox(
            width: 110.sp,
            height: 110.sp,
            child: PlayerRadarChart(
              stats: player.stats,
              color: AppTheme.getGradeColor(player.grade.display),
              grade: player.grade.display,
              level: player.level.value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSection(List<Player> opponentPlayers, List<Player> teamPlayers) {
    final sortedPlayers = List<Player>.from(opponentPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 3.sp, horizontal: 6.sp),
          color: _isSnipingMode
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.2),
          child: Row(
            children: [
              Icon(Icons.groups, size: 10.sp, color: Colors.red),
              SizedBox(width: 3.sp),
              Expanded(
                child: Text(
                  _isSnipingMode ? '상대 예측' : '상대 (${opponentPlayers.length})',
                  style: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                      color: _isSnipingMode ? Colors.orange : Colors.red),
                ),
              ),
              if (_isSnipingMode)
                GestureDetector(
                  onTap: () => setState(() { _isSnipingMode = false; }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
                    child: const Text('취소', style: TextStyle(fontSize: 7, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(2.sp),
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];

              return GestureDetector(
                onTap: _isSnipingMode
                    ? () => _onSnipingSelectOpponent(player, teamPlayers)
                    : null,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 1.sp),
                  padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: _isSnipingMode
                        ? Colors.orange.withValues(alpha: 0.15)
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(
                      color: _isSnipingMode ? Colors.orange : Colors.transparent,
                      width: _isSnipingMode ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('(${player.race.code})',
                          style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.getRaceColor(player.race.code))),
                      SizedBox(width: 2.sp),
                      Expanded(
                        child: Text(player.name,
                            style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 3.sp, vertical: 1.sp),
                        decoration: BoxDecoration(
                          color: AppTheme.getGradeColor(player.grade.display),
                          borderRadius: BorderRadius.circular(2.sp),
                        ),
                        child: Text(player.grade.display,
                            style: TextStyle(
                                fontSize: 7.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onSnipingSelectOpponent(Player opponent, List<Player> teamPlayers) {
    if (_selectedPlayerIndex == null) return;
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final myPlayer = teamPlayers[_selectedPlayerIndex!];

    // 아이템 소모
    final updatedInventory = gameState.inventory.useConsumable('sniping');
    ref.read(gameStateProvider.notifier).updateInventory(updatedInventory);

    _snipingAssignments = [
      SnipingAssignment(
        setIndex: 0,
        myPlayerId: myPlayer.id,
        predictedOpponentId: opponent.id,
      ),
    ];

    setState(() { _isSnipingMode = false; });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('1세트 스나이핑: ${myPlayer.name} → ${opponent.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _submitRoster(
    Team playerTeam,
    Team opponentTeam,
    List<Player> teamPlayers,
    ScheduleItem nextMatch,
    bool isHome,
  ) {
    _startMatch(playerTeam, opponentTeam, teamPlayers, nextMatch, isHome);
  }

  /// 로스터 화면 진입 시 전체 팀 선수 대상 컨디션 최상/최악 이벤트 (각 2%)
  void _rollConditionsOnEntry(List<Player> teamPlayers) {
    final random = Random();
    final gameNotifier = ref.read(gameStateProvider.notifier);

    for (final player in teamPlayers) {
      final roll = random.nextDouble();

      if (roll < 0.02) {
        // 최상: +20, 최대 120
        final newCondition = min(player.condition + 20, 120);
        gameNotifier.backupCondition(player.id, player.condition);
        gameNotifier.updatePlayer(player.copyWith(condition: newCondition));
      } else if (roll < 0.04) {
        // 최악: -20, 최저 80
        final newCondition = max(player.condition - 20, 80);
        gameNotifier.backupCondition(player.id, player.condition);
        gameNotifier.updatePlayer(player.copyWith(condition: newCondition));
      }
    }

    if (mounted) setState(() {});
  }

  void _startMatch(
    Team playerTeam,
    Team opponentTeam,
    List<Player> teamPlayers,
    ScheduleItem nextMatch,
    bool isHome,
  ) {
    final selectedPlayer = teamPlayers[_selectedPlayerIndex!];

    ref.read(currentMatchProvider.notifier).startWinnersLeagueMatch(
      homeTeamId: isHome ? playerTeam.id : opponentTeam.id,
      awayTeamId: isHome ? opponentTeam.id : playerTeam.id,
      matchId: nextMatch.matchId,
      firstPlayerId: selectedPlayer.id,
      isPlayerHome: isHome,
      snipingAssignments: _snipingAssignments.isNotEmpty ? _snipingAssignments : null,
    );

    context.go('/match');
  }
}
