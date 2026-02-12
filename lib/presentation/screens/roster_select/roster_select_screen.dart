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

class RosterSelectScreen extends ConsumerStatefulWidget {
  const RosterSelectScreen({super.key});

  @override
  ConsumerState<RosterSelectScreen> createState() => _RosterSelectScreenState();
}

class _RosterSelectScreenState extends ConsumerState<RosterSelectScreen> {
  // 6세트에 배치된 선수 인덱스 (null = 빈 슬롯)
  final List<int?> selectedPlayers = List.filled(6, null);

  // 현재 focus된 맵 인덱스 (0~5, 처음에는 0번 = 1세트)
  int _focusedMapIndex = 0;

  // 선택된 내 팀 선수 인덱스 (상세정보 표시용)
  int? _selectedMyPlayerIndex;

  // 선택된 상대 팀 선수 인덱스 (상세정보 표시용)
  int? _selectedOpponentPlayerIndex;

  // 세트별 맵 (랜덤 선정)
  List<GameMap> _matchMaps = [];

  // 스나이핑 관련 상태
  final List<SnipingAssignment> _snipingAssignments = [];
  // idle: 기본, selectingMyPlayer: 내 선수 선택 중, selectingOpponent: 상대 선수 선택 중
  String _snipingState = 'idle';
  int? _snipingTargetSetIndex;

  // 컨디션 최상/최악 이벤트가 이미 적용되었는지 여부
  bool _conditionRolled = false;

  /// 매치용 맵 7개 선정 (시즌맵 순서 유지)
  List<GameMap> _getMatchMaps(List<String> seasonMapIds) {
    if (_matchMaps.isNotEmpty) return _matchMaps;

    final allMaps = seasonMapIds
        .map((id) => GameMaps.getById(id))
        .whereType<GameMap>()
        .toList();

    if (allMaps.isEmpty) {
      _matchMaps = GameMaps.all.take(7).toList();
    } else {
      // 시즌맵 순서 그대로 사용 (셔플 X)
      _matchMaps = allMaps.take(7).toList();
      while (_matchMaps.length < 7) {
        _matchMaps.add(allMaps[_matchMaps.length % allMaps.length]);
      }
    }

    return _matchMaps;
  }

  /// 다음 빈 슬롯으로 focus 이동
  void _moveToNextEmptySlot() {
    for (int i = 0; i < 6; i++) {
      if (selectedPlayers[i] == null) {
        setState(() {
          _focusedMapIndex = i;
        });
        return;
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 경기가 완료되었습니다.')),
        );
        context.go('/main');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isHome = nextMatch.homeTeamId == playerTeam.id;
    final opponentId = isHome ? nextMatch.awayTeamId : nextMatch.homeTeamId;
    final opponentTeam = gameState.saveData.getTeamById(opponentId) ??
        gameState.saveData.allTeams.firstWhere((t) => t.id != playerTeam.id);

    final opponentPlayers = gameState.saveData.getTeamPlayers(opponentId);
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;
    final matchMaps = _getMatchMaps(seasonMapIds);

    // 로스터 화면 진입 시 전체 팀 선수 대상으로 컨디션 이벤트 롤 (1회만)
    if (!_conditionRolled) {
      _conditionRolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rollConditionsOnEntry(teamPlayers);
      });
    }

    final selectedCount = selectedPlayers.where((p) => p != null).length;
    final canSubmit = selectedCount >= 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('로스터 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/main');
            }
          },
        ),
        actions: [ResetButton.action()],
      ),
      body: Column(
        children: [
          // 1. 우리팀 vs 상대팀
          _buildMatchHeader(playerTeam, opponentTeam, isHome),

          // 2. 아이템 목록 (가로 중앙정렬)
          _buildItemRow(),

          // 3. 맵 정보 패널 (썸네일 크게)
          _buildMapInfoPanel(matchMaps),

          // 4. 3열 구조 (내팀 | 맵순서 | 상대팀)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 내 팀
                Expanded(
                  flex: 3,
                  child: _buildMyTeamSection(teamPlayers),
                ),

                // 중앙: 7개 맵 세로 배치
                SizedBox(
                  width: 100,
                  child: _buildMapColumn(matchMaps, teamPlayers),
                ),

                // 오른쪽: 상대 팀
                Expanded(
                  flex: 3,
                  child: _buildOpponentSection(opponentPlayers, opponentId, teamPlayers),
                ),
              ],
            ),
          ),

          // 제출 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: canSubmit
                    ? () => _submitRoster(playerTeam, opponentTeam, teamPlayers)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.cardBackground,
                ),
                child: Text(
                  canSubmit ? '로스터 제출' : '선수 배치 필요 ($selectedCount/6)',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 매치 헤더 (우리팀 vs 상대팀)
  Widget _buildMatchHeader(Team playerTeam, Team opponentTeam, bool isHome) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: AppTheme.cardBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            children: [
              Text(playerTeam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(isHome ? 'HOME' : 'AWAY', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
            ],
          ),
          const Text('VS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.accentGreen)),
          Column(
            children: [
              Text(opponentTeam.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(isHome ? 'AWAY' : 'HOME', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  /// 아이템 목록 (가로 중앙정렬, 넘치지 않게)
  Widget _buildItemRow() {
    final gameState = ref.watch(gameStateProvider);
    final inventory = gameState?.inventory;
    if (inventory == null) return const SizedBox.shrink();

    final consumableItems = ConsumableItems.all.where((item) {
      return inventory.getConsumableCount(item.id) > 0;
    }).toList();

    if (consumableItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: consumableItems.map((item) {
          final count = inventory.getConsumableCount(item.id);
          final isSnipingItem = item.id == 'sniping';
          final isSnipingActive = _snipingState != 'idle';
          return GestureDetector(
            onTap: isSnipingItem && !isSnipingActive ? _startSnipingFlow : null,
            child: _ItemChip(
              item: item,
              count: count,
              isHighlighted: isSnipingItem && isSnipingActive,
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 내 팀 섹션 (선수 그리드 + 선택 시 상세 정보)
  Widget _buildMyTeamSection(List<Player> teamPlayers) {
    final selectedPlayer = _selectedMyPlayerIndex != null && _selectedMyPlayerIndex! < teamPlayers.length
        ? teamPlayers[_selectedMyPlayerIndex!]
        : null;

    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
          child: Row(
            children: [
              const Icon(Icons.person, size: 10, color: AppTheme.primaryBlue),
              const SizedBox(width: 3),
              Text('내 팀 (${teamPlayers.length})',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            ],
          ),
        ),
        // 선수 그리드 (2열)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: teamPlayers.length,
            itemBuilder: (context, index) {
              final player = teamPlayers[index];
              final isAssigned = selectedPlayers.contains(index);
              final isSelected = _selectedMyPlayerIndex == index;
              final assignedSet = selectedPlayers.indexOf(index);

              return _PlayerGridItem(
                player: player,
                isAssigned: isAssigned,
                isSelected: isSelected,
                assignedSet: assignedSet >= 0 ? assignedSet + 1 : null,
                onTap: () {
                  setState(() {
                    _selectedMyPlayerIndex = index;
                  });
                  // 싱글탭으로 배치 (미배치 선수 + 빈 슬롯일 때)
                  if (!isAssigned && _focusedMapIndex < 6 && selectedPlayers[_focusedMapIndex] == null) {
                    setState(() {
                      selectedPlayers[_focusedMapIndex] = index;
                    });
                    _moveToNextEmptySlot();
                  }
                },
              );
            },
          ),
        ),
        // 선택된 선수 상세 정보 (목록 아래)
        if (selectedPlayer != null)
          _buildPlayerDetailCompact(selectedPlayer, true),
      ],
    );
  }

  /// 맵 태그 위젯 생성 (종족맵, 특성)
  List<Widget> _getMapTagWidgets(GameMap map, String description) {
    final tags = <Widget>[];

    void addTag(String label, Color color) {
      tags.add(Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
      ));
    }

    if (description.contains('테란맵')) {
      addTag('T맵', Colors.blue);
    }
    if (description.contains('저그맵')) {
      addTag('Z맵', Colors.purple);
    }
    if (description.contains('토스맵')) {
      addTag('P맵', Colors.amber);
    }
    if (tags.isEmpty && description.contains('개념맵')) {
      addTag('균형', Colors.teal);
    }
    if (map.hasIsland) addTag('섬', Colors.cyan);
    if (description.contains('3인용')) addTag('3인', AppTheme.textSecondary);

    return tags.take(2).toList();
  }

  /// 맵 정보 패널 (가시성 강화: 썸네일 + 상성 바차트 + 스탯 프로그레스바)
  Widget _buildMapInfoPanel(List<GameMap> matchMaps) {
    final currentMap = _focusedMapIndex < matchMaps.length ? matchMaps[_focusedMapIndex] : null;
    if (currentMap == null) {
      return Container(
        height: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(child: Text('맵 정보 없음', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
      );
    }

    final mapData = getMapByName(currentMap.name);
    final imageFile = mapData?.imageFile ?? '';
    final description = mapData?.description ?? '';
    final mapTags = _getMapTagWidgets(currentMap, description);

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 1행: 세트번호 + 맵이름 + 맵타입 태그
          Row(
            children: [
              Container(
                width: 18, height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text('${_focusedMapIndex + 1}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  currentMap.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ...mapTags,
            ],
          ),
          const SizedBox(height: 4),
          // 2행: 썸네일(좌) + 종족 상성 바차트(우)
          Expanded(
            child: Row(
              children: [
                // 좌: 맵 썸네일 (정사각형)
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: imageFile.isEmpty
                          ? Container(
                              color: AppTheme.cardBackground,
                              child: const Icon(Icons.map, size: 30, color: AppTheme.textSecondary))
                          : Image.asset(
                              'assets/maps/$imageFile',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppTheme.cardBackground,
                                child: const Icon(Icons.map, size: 30, color: AppTheme.textSecondary),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 우: 종족 상성 가로 바차트 (50% 기준선)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MatchupBar(race1: 'T', race2: 'Z', rate: currentMap.matchup.tvzTerranWinRate),
                      const SizedBox(height: 6),
                      _MatchupBar(race1: 'Z', race2: 'P', rate: currentMap.matchup.zvpZergWinRate),
                      const SizedBox(height: 6),
                      _MatchupBar(race1: 'P', race2: 'T', rate: currentMap.matchup.pvtProtossWinRate),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // 3행: 러시/자원/복잡 아이콘 프로그레스바
          Row(
            children: [
              Expanded(child: _StatBar(icon: Icons.flash_on, label: '러시', value: currentMap.rushDistance, maxValue: 10)),
              const SizedBox(width: 8),
              Expanded(child: _StatBar(icon: Icons.diamond_outlined, label: '자원', value: currentMap.resources, maxValue: 10)),
              const SizedBox(width: 8),
              Expanded(child: _StatBar(icon: Icons.terrain, label: '복잡', value: currentMap.complexity, maxValue: 10)),
            ],
          ),
        ],
      ),
    );
  }

  /// 상대 팀 섹션 (선수 그리드 + 선택 시 상세 정보)
  Widget _buildOpponentSection(List<Player> opponentPlayers, String opponentTeamId, List<Player> teamPlayers) {
    // 컨디션 + 등급 기준 정렬
    final sortedPlayers = List<Player>.from(opponentPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    final selectedPlayer = _selectedOpponentPlayerIndex != null && _selectedOpponentPlayerIndex! < sortedPlayers.length
        ? sortedPlayers[_selectedOpponentPlayerIndex!]
        : null;

    final isSelectingOpponent = _snipingState == 'selectingOpponent';

    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          color: isSelectingOpponent
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.2),
          child: Row(
            children: [
              const Icon(Icons.groups, size: 10, color: Colors.red),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  isSelectingOpponent ? '상대 선수 예측' : '상대 (${opponentPlayers.length})',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelectingOpponent ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              if (isSelectingOpponent)
                GestureDetector(
                  onTap: _cancelSnipingFlow,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(2)),
                    child: const Text('취소', style: TextStyle(fontSize: 7, color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
        // 선수 그리드 (2열)
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              final isSelected = _selectedOpponentPlayerIndex == index;

              return _OpponentGridItem(
                player: player,
                isSelected: isSelected,
                isSnipingTarget: isSelectingOpponent,
                onTap: () {
                  if (isSelectingOpponent) {
                    // 스나이핑 모드: 상대 선수 선택
                    _onSnipingSelectOpponent(player, teamPlayers);
                  } else {
                    setState(() {
                      _selectedOpponentPlayerIndex = index;
                    });
                  }
                },
              );
            },
          ),
        ),
        // 선택된 선수 상세 정보 (목록 아래)
        if (selectedPlayer != null && !isSelectingOpponent)
          _buildPlayerDetailCompact(selectedPlayer, false),
      ],
    );
  }

  /// 선수 상세정보 (컴팩트 - 8각형 레이더 + 컨디션)
  Widget _buildPlayerDetailCompact(Player player, bool isMyTeam) {
    final condition = player.displayCondition;
    final stats = player.stats;

    return Container(
      padding: const EdgeInsets.all(4),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isMyTeam ? AppTheme.primaryBlue.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단: 이름 + 종족 + 등급 + 레벨 + 컨디션
          Row(
            children: [
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getRaceColor(player.race.code),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppTheme.getGradeColor(player.grade.display),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  player.grade.display,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(width: 3),
              Text('Lv.${player.level.value}', style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
              const SizedBox(width: 3),
              Text(
                '$condition%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: condition >= 80 ? Colors.green : (condition >= 50 ? Colors.orange : Colors.red),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 8각형 레이더 차트 (능력치 숫자 포함 + 컨디션 이중 폴리곤)
          SizedBox(
            width: 130,
            height: 130,
            child: PlayerRadarChart(
              stats: stats,
              color: AppTheme.getGradeColor(player.grade.display),
              grade: player.grade.display,
              level: player.level.value,
              effectiveStats: player.effectiveStats,
              conditionPercent: condition,
            ),
          ),
        ],
      ),
    );
  }

  /// 중앙 맵 컬럼 (7개 세로 다닥다닥 배치)
  Widget _buildMapColumn(List<GameMap> matchMaps, List<Player> teamPlayers) {
    return Container(
      color: AppTheme.cardBackground.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(7, (index) {
          final map = index < matchMaps.length ? matchMaps[index] : null;

          if (index == 6) {
            return _AceMapRowCompact(map: map);
          }

          final playerIndex = selectedPlayers[index];
          final player = playerIndex != null && playerIndex < teamPlayers.length
              ? teamPlayers[playerIndex]
              : null;
          final isFocused = _focusedMapIndex == index;
          final snipingAssignment = _getSnipingForSet(index);
          final isSnipingSelecting = _snipingState == 'selectingMyPlayer';

          return _MapRowCompact(
            setNumber: index + 1,
            map: map,
            player: player,
            isFocused: isFocused,
            hasSniping: snipingAssignment != null,
            isSnipingSelectable: isSnipingSelecting && player != null,
            onTap: () {
              if (isSnipingSelecting) {
                _onSnipingSelectMyPlayer(index, teamPlayers);
              } else {
                setState(() {
                  _focusedMapIndex = index;
                });
              }
            },
            onPlayerRemove: () {
              _cancelSnipingForSet(index);
              setState(() {
                selectedPlayers[index] = null;
                _focusedMapIndex = index;
              });
            },
          );
        }),
      ),
    );
  }

  /// 스나이핑 칩 탭: selectingMyPlayer 상태로 전환
  void _startSnipingFlow() {
    setState(() {
      _snipingState = 'selectingMyPlayer';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('스나이핑할 세트의 내 선수를 선택하세요'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 맵 슬롯 탭 (스나이핑 selectingMyPlayer 상태에서)
  void _onSnipingSelectMyPlayer(int setIndex, List<Player> teamPlayers) {
    if (selectedPlayers[setIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선수가 배치된 세트를 선택하세요'), backgroundColor: Colors.red, duration: Duration(seconds: 1)),
      );
      return;
    }

    setState(() {
      _snipingTargetSetIndex = setIndex;
      _snipingState = 'selectingOpponent';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('상대 선수를 예측하여 선택하세요'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 상대 선수 탭 (스나이핑 selectingOpponent 상태에서)
  void _onSnipingSelectOpponent(Player opponent, List<Player> teamPlayers) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null || _snipingTargetSetIndex == null) return;

    final setIndex = _snipingTargetSetIndex!;
    final myPlayerIndex = selectedPlayers[setIndex];
    if (myPlayerIndex == null) return;
    final myPlayer = teamPlayers[myPlayerIndex];

    // 같은 세트에 기존 스나이핑이 있으면 취소 + 아이템 반환
    final existingIndex = _snipingAssignments.indexWhere((a) => a.setIndex == setIndex);
    if (existingIndex >= 0) {
      _snipingAssignments.removeAt(existingIndex);
      final returnedInventory = gameState.inventory.addConsumable('sniping');
      ref.read(gameStateProvider.notifier).updateInventory(returnedInventory);
    }

    // 아이템 소모
    final updatedInventory = ref.read(gameStateProvider)!.inventory.useConsumable('sniping');
    ref.read(gameStateProvider.notifier).updateInventory(updatedInventory);

    // 스나이핑 등록
    _snipingAssignments.add(SnipingAssignment(
      setIndex: setIndex,
      myPlayerId: myPlayer.id,
      predictedOpponentId: opponent.id,
    ));

    setState(() {
      _snipingState = 'idle';
      _snipingTargetSetIndex = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${setIndex + 1}세트 스나이핑 설정: ${myPlayer.name} → ${opponent.name}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// 스나이핑 취소
  void _cancelSnipingFlow() {
    setState(() {
      _snipingState = 'idle';
      _snipingTargetSetIndex = null;
    });
  }

  /// 선수 제거/변경 시 해당 세트 스나이핑 자동 취소 + 아이템 반환
  void _cancelSnipingForSet(int setIndex) {
    final existingIndex = _snipingAssignments.indexWhere((a) => a.setIndex == setIndex);
    if (existingIndex >= 0) {
      _snipingAssignments.removeAt(existingIndex);
      final gameState = ref.read(gameStateProvider);
      if (gameState != null) {
        final returnedInventory = gameState.inventory.addConsumable('sniping');
        ref.read(gameStateProvider.notifier).updateInventory(returnedInventory);
      }
    }
  }

  /// 해당 세트에 스나이핑이 설정되어 있는지 확인
  SnipingAssignment? _getSnipingForSet(int setIndex) {
    for (final a in _snipingAssignments) {
      if (a.setIndex == setIndex) return a;
    }
    return null;
  }

  ScheduleItem? _findNextMatch(dynamic schedule, String playerTeamId) {
    final List<ScheduleItem> typedSchedule = List<ScheduleItem>.from(schedule);

    final myIncompleteMatches = typedSchedule.where((s) =>
      !s.isCompleted &&
      (s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId)
    ).toList();

    if (myIncompleteMatches.isEmpty) return null;

    myIncompleteMatches.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return myIncompleteMatches.first;
  }

  void _submitRoster(Team playerTeam, Team opponentTeam, List<Player> teamPlayers) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final schedule = gameState.saveData.currentSeason.proleagueSchedule;
    final nextMatch = _findNextMatch(schedule, playerTeam.id);
    if (nextMatch == null) return;

    final isHome = nextMatch.homeTeamId == playerTeam.id;

    final roster = selectedPlayers.map((index) {
      if (index != null && index < teamPlayers.length) {
        return teamPlayers[index].id;
      }
      return null;
    }).toList();

    _startMatch(isHome, playerTeam, opponentTeam, nextMatch, roster);
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

    // UI 갱신 (setState 호출하여 변경된 컨디션 반영)
    if (mounted) setState(() {});
  }

  void _startMatch(bool isHome, Team playerTeam, Team opponentTeam,
      ScheduleItem nextMatch, List<String?> roster) {
    if (isHome) {
      ref.read(currentMatchProvider.notifier).startMatch(
        homeTeamId: playerTeam.id,
        awayTeamId: opponentTeam.id,
        matchId: nextMatch.matchId,
        homeRoster: roster,
        homeSnipingAssignments: _snipingAssignments,
      );
    } else {
      ref.read(currentMatchProvider.notifier).startMatch(
        homeTeamId: opponentTeam.id,
        awayTeamId: playerTeam.id,
        matchId: nextMatch.matchId,
        awayRoster: roster,
        awaySnipingAssignments: _snipingAssignments,
      );
    }

    context.go('/match');
  }
}

/// 내 팀 선수 그리드 아이템
class _PlayerGridItem extends StatelessWidget {
  final Player player;
  final bool isAssigned;
  final bool isSelected;
  final int? assignedSet;
  final VoidCallback onTap;

  const _PlayerGridItem({
    required this.player,
    required this.isAssigned,
    required this.isSelected,
    this.assignedSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.3)
              : (isAssigned ? AppTheme.accentGreen.withValues(alpha: 0.2) : AppTheme.cardBackground),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : (isAssigned ? AppTheme.accentGreen : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 종족 (T)이영호 형태
            Text(
              '(${player.race.code})',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.getRaceColor(player.race.code),
              ),
            ),
            const SizedBox(width: 2),
            // 이름
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isAssigned ? AppTheme.textSecondary : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 컨디션 표시
            Text(
              '${player.displayCondition}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: player.displayCondition > 100
                    ? Colors.amber
                    : player.displayCondition < 100
                        ? Colors.redAccent
                        : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            // 세트 표시
            if (isAssigned && assignedSet != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.accentGreen, borderRadius: BorderRadius.circular(2)),
                child: Text('$assignedSet', style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black)),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상대 팀 선수 그리드 아이템
class _OpponentGridItem extends StatelessWidget {
  final Player player;
  final bool isSelected;
  final bool isSnipingTarget;
  final VoidCallback onTap;

  const _OpponentGridItem({
    required this.player,
    required this.isSelected,
    this.isSnipingTarget = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.red.withValues(alpha: 0.3)
              : (isSnipingTarget ? Colors.orange.withValues(alpha: 0.15) : AppTheme.cardBackground),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? Colors.red
                : (isSnipingTarget ? Colors.orange : Colors.transparent),
            width: isSelected ? 2 : (isSnipingTarget ? 1.5 : 1),
          ),
        ),
        child: Row(
          children: [
            // 종족 (T)이영호 형태
            Text(
              '(${player.race.code})',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: AppTheme.getRaceColor(player.race.code),
              ),
            ),
            const SizedBox(width: 2),
            // 이름
            Expanded(
              child: Text(
                player.name,
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아이템 칩 (Wrap용 컴팩트 표시)
class _ItemChip extends StatelessWidget {
  final ConsumableItem item;
  final int count;
  final bool isHighlighted;

  const _ItemChip({required this.item, required this.count, this.isHighlighted = false});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (item.id) {
      case 'vita_vita': icon = Icons.local_drink; color = Colors.green; break;
      case 'chewing_gum': icon = Icons.bubble_chart; color = Colors.pink; break;
      case 'ceremony': icon = Icons.celebration; color = Colors.purple; break;
      case 'sniping': icon = Icons.visibility; color = Colors.orange; break;
      case 'cheerful': icon = Icons.favorite; color = Colors.red; break;
      default: icon = Icons.inventory_2; color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? color : color.withValues(alpha: 0.3),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(item.name, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
          Text('x$count', style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

/// 맵 스탯 프로그레스 바 (아이콘 + 라벨 + 바 + 수치)
class _StatBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int maxValue;

  const _StatBar({required this.icon, required this.label, required this.value, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final ratio = (value / maxValue).clamp(0.0, 1.0);
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);

    return Row(
      children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 2),
        Text(label, style: const TextStyle(fontSize: 7, color: AppTheme.textSecondary)),
        const SizedBox(width: 3),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: ratio,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text('$value', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

/// 종족 상성 바 (가로 바차트, 50% 기준선 표시)
class _MatchupBar extends StatelessWidget {
  final String race1;
  final String race2;
  final int rate;

  const _MatchupBar({required this.race1, required this.race2, required this.rate});

  Color _getRaceColor(String race) {
    switch (race) {
      case 'T': return Colors.blue;
      case 'Z': return Colors.purple;
      case 'P': return Colors.amber;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate2 = 100 - rate;
    final color1 = _getRaceColor(race1);
    final color2 = _getRaceColor(race2);

    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(race1, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color1)),
        ),
        SizedBox(
          width: 20,
          child: Text('$rate', textAlign: TextAlign.right,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: rate > 55 ? color1 : Colors.white)),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Container(color: color2.withValues(alpha: 0.15)),
                      Container(
                        width: constraints.maxWidth * rate / 100,
                        color: color1.withValues(alpha: rate > 50 ? 0.5 : 0.3),
                      ),
                      Positioned(
                        left: constraints.maxWidth / 2 - 0.5,
                        top: 0,
                        bottom: 0,
                        child: Container(width: 1, color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 20,
          child: Text('$rate2', textAlign: TextAlign.left,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: rate2 > 55 ? color2 : Colors.white)),
        ),
        SizedBox(
          width: 14,
          child: Text(race2, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color2)),
        ),
      ],
    );
  }
}

/// 컴팩트 맵 행 (다닥다닥)
class _MapRowCompact extends StatelessWidget {
  final int setNumber;
  final GameMap? map;
  final Player? player;
  final bool isFocused;
  final bool hasSniping;
  final bool isSnipingSelectable;
  final VoidCallback onTap;
  final VoidCallback onPlayerRemove;

  const _MapRowCompact({
    required this.setNumber,
    required this.map,
    required this.player,
    required this.isFocused,
    this.hasSniping = false,
    this.isSnipingSelectable = false,
    required this.onTap,
    required this.onPlayerRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mapName = map?.name ?? '맵 $setNumber';
    final shortMapName = mapName.length > 4 ? '${mapName.substring(0, 3)}..' : mapName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: isSnipingSelectable
              ? Colors.orange.withValues(alpha: 0.2)
              : isFocused
                  ? AppTheme.accentGreen.withValues(alpha: 0.2)
                  : (player != null ? AppTheme.primaryBlue.withValues(alpha: 0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSnipingSelectable
                ? Colors.orange
                : isFocused
                    ? AppTheme.accentGreen
                    : (player != null ? AppTheme.primaryBlue : AppTheme.textSecondary.withValues(alpha: 0.3)),
            width: isSnipingSelectable ? 1.5 : (isFocused ? 1.5 : 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: hasSniping
                    ? const Icon(Icons.gps_fixed, size: 8, color: Colors.orange)
                    : Text('$setNumber', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
                        color: isFocused ? Colors.black : AppTheme.textSecondary)),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shortMapName, style: TextStyle(fontSize: 7,
                      color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                  if (player != null)
                    GestureDetector(
                      onTap: onPlayerRemove,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 4, backgroundColor: AppTheme.getRaceColor(player!.race.code),
                              child: Text(player!.race.code, style: const TextStyle(fontSize: 4, color: Colors.white))),
                          const SizedBox(width: 1),
                          Expanded(child: Text(player!.name, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )
                  else
                    Text(isFocused ? '← 선택' : '', style: TextStyle(fontSize: 6,
                        color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 컴팩트 에이스 맵 행
class _AceMapRowCompact extends StatelessWidget {
  final GameMap? map;

  const _AceMapRowCompact({required this.map});

  @override
  Widget build(BuildContext context) {
    final mapName = map?.name ?? 'ACE';
    final shortMapName = mapName.length > 4 ? '${mapName.substring(0, 3)}..' : mapName;

    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Icon(Icons.star, size: 8, color: Colors.orange)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortMapName, style: TextStyle(fontSize: 7, color: Colors.orange.withValues(alpha: 0.8)), overflow: TextOverflow.ellipsis),
                Text('ACE', style: TextStyle(fontSize: 6, color: Colors.orange.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
