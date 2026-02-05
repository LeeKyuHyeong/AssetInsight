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

  // 스나이핑 사용 여부
  bool _snipingUsed = false;

  // 예측된 상대 로스터 (스나이핑 사용 시)
  List<String?> _predictedOpponentRoster = [];

  // 특수 컨디션 (최상/최악) - 선수ID -> SpecialCondition
  Map<String, SpecialCondition> _specialConditions = {};
  bool _specialConditionsRolled = false;

  // 맵 정보 / 아이템 토글 (true: 맵 정보, false: 아이템)
  bool _showMapInfo = true;

  /// 매치용 맵 7개 선정
  List<GameMap> _getMatchMaps(List<String> seasonMapIds) {
    if (_matchMaps.isNotEmpty) return _matchMaps;

    final allMaps = seasonMapIds
        .map((id) => GameMaps.getById(id))
        .whereType<GameMap>()
        .toList();

    if (allMaps.isEmpty) {
      _matchMaps = GameMaps.all.take(7).toList();
    } else {
      final shuffled = List<GameMap>.from(allMaps)..shuffle(Random());
      _matchMaps = shuffled.take(7).toList();
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

    final scheduleForRoll = gameState.saveData.currentSeason.proleagueSchedule;
    final nextMatchForRoll = _findNextMatch(scheduleForRoll, playerTeam.id);
    if (nextMatchForRoll != null && !_specialConditionsRolled) {
      final isHomeForRoll = nextMatchForRoll.homeTeamId == playerTeam.id;
      final opponentIdForRoll = isHomeForRoll ? nextMatchForRoll.awayTeamId : nextMatchForRoll.homeTeamId;
      final opponentPlayersForRoll = gameState.saveData.getTeamPlayers(opponentIdForRoll);

      _specialConditions = {};
      for (final player in teamPlayers) {
        _specialConditions[player.id] = SpecialCondition.roll();
      }
      for (final player in opponentPlayersForRoll) {
        _specialConditions[player.id] = SpecialCondition.roll();
      }
      _specialConditionsRolled = true;
    }
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

    final selectedCount = selectedPlayers.where((p) => p != null).length;
    final canSubmit = selectedCount >= 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('로스터 선택'),
        leading: ResetButton.leading(),
      ),
      body: Column(
        children: [
          // 매치 정보 헤더
          _buildMatchInfo(playerTeam, opponentTeam, isHome),

          // 상단: 맵 정보 / 아이템 영역
          if (_showMapInfo)
            _buildMapInfoPanel(matchMaps)
          else
            _buildItemPanel(),

          // 하단: 3열 구조 (내팀 | 맵 | 상대팀)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 왼쪽: 내 팀
                Expanded(
                  flex: 3,
                  child: _buildMyTeamSection(teamPlayers),
                ),

                // 중앙: 7개 맵 세로 배치 (다닥다닥)
                SizedBox(
                  width: 100,
                  child: _buildMapColumn(matchMaps, teamPlayers),
                ),

                // 오른쪽: 상대 팀
                Expanded(
                  flex: 3,
                  child: _buildOpponentSection(opponentPlayers, opponentId),
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

  /// 매치 정보 헤더
  Widget _buildMatchInfo(Team playerTeam, Team opponentTeam, bool isHome) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: AppTheme.cardBackground,
      child: Row(
        children: [
          // 전환 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _showMapInfo = !_showMapInfo;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _showMapInfo ? AppTheme.primaryBlue : Colors.orange,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showMapInfo ? Icons.map : Icons.inventory_2,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showMapInfo ? '맵' : '템',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          // 팀 정보
          Expanded(
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
          ),
        ],
      ),
    );
  }

  /// 내 팀 섹션 (선수 그리드만)
  Widget _buildMyTeamSection(List<Player> teamPlayers) {
    return Column(
      children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          color: AppTheme.primaryBlue.withOpacity(0.2),
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
                },
                onDoubleTap: isAssigned
                    ? null
                    : () {
                        if (_focusedMapIndex < 6 && selectedPlayers[_focusedMapIndex] == null) {
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
      ],
    );
  }

  /// 맵 정보 패널 (상단 전체 가로)
  Widget _buildMapInfoPanel(List<GameMap> matchMaps) {
    final currentMap = _focusedMapIndex < matchMaps.length ? matchMaps[_focusedMapIndex] : null;
    if (currentMap == null) {
      return Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(child: Text('맵 정보 없음', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
      );
    }

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // 세트 번호
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Text('${_focusedMapIndex + 1}', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
          const SizedBox(width: 4),
          // 맵 썸네일
          Builder(
            builder: (context) {
              final mapData = getMapByName(currentMap.name);
              final imageFile = mapData?.imageFile ?? '';
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: imageFile.isEmpty
                      ? Container(
                          color: AppTheme.cardBackground,
                          child: const Icon(Icons.map, size: 24, color: AppTheme.textSecondary),
                        )
                      : Image.asset(
                          'assets/maps/$imageFile',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppTheme.cardBackground,
                            child: const Icon(Icons.map, size: 24, color: AppTheme.textSecondary),
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          // 러시/자원/복잡 (세로)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBoxMini(label: '러시', value: currentMap.rushDistance),
              _StatBoxMini(label: '자원', value: currentMap.resources),
              _StatBoxMini(label: '복잡', value: currentMap.complexity),
            ],
          ),
          const SizedBox(width: 8),
          // 맵 이름 + 종족 상성 (가로)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentMap.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _MatchupBoxCompact(label: 'T:Z', value: currentMap.matchup.tvzTerranWinRate),
                    const SizedBox(width: 4),
                    _MatchupBoxCompact(label: 'Z:P', value: currentMap.matchup.zvpZergWinRate),
                    const SizedBox(width: 4),
                    _MatchupBoxCompact(label: 'P:T', value: currentMap.matchup.pvtProtossWinRate),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 아이템 패널 (상단 전체 가로)
  Widget _buildItemPanel() {
    final gameState = ref.watch(gameStateProvider);
    final inventory = gameState?.inventory;

    if (inventory == null) {
      return Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(child: Text('인벤토리 없음', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10))),
      );
    }

    // 보유 중인 소모품 목록
    final consumableItems = ConsumableItems.all.where((item) {
      return inventory.getConsumableCount(item.id) > 0;
    }).toList();

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          if (consumableItems.isEmpty)
            const Expanded(child: Text('보유 아이템 없음', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)))
          else
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: consumableItems.length,
                itemBuilder: (context, index) {
                  final item = consumableItems[index];
                  final count = inventory.getConsumableCount(item.id);
                  return _ItemCardCompact(item: item, count: count);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// 상대 팀 섹션 (선수 그리드만)
  Widget _buildOpponentSection(List<Player> opponentPlayers, String opponentTeamId) {
    // 컨디션 + 등급 기준 정렬
    final sortedPlayers = List<Player>.from(opponentPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    final gameState = ref.watch(gameStateProvider);
    final snipingCount = gameState?.inventory.getConsumableCount('sniping') ?? 0;

    return Column(
      children: [
        // 헤더 + 스나이핑
        Container(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
          color: Colors.red.withOpacity(0.2),
          child: Row(
            children: [
              const Icon(Icons.groups, size: 10, color: Colors.red),
              const SizedBox(width: 3),
              Expanded(
                child: Text('상대 (${opponentPlayers.length})',
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              if (snipingCount > 0 && !_snipingUsed)
                GestureDetector(
                  onTap: () => _useSniping(opponentTeamId, opponentPlayers),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2)),
                    child: Text('스나이핑($snipingCount)', style: const TextStyle(fontSize: 7, color: Colors.white)),
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
              final isPredicted = _snipingUsed && _predictedOpponentRoster.contains(player.id);
              final predictedSet = isPredicted ? _predictedOpponentRoster.indexOf(player.id) + 1 : null;

              return _OpponentGridItem(
                player: player,
                isSelected: isSelected,
                isPredicted: isPredicted,
                predictedSet: predictedSet,
                onTap: () {
                  setState(() {
                    _selectedOpponentPlayerIndex = index;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 선수 상세정보 (8각형 레이더 + 컨디션)
  Widget _buildPlayerDetail(Player player, bool isMyTeam) {
    final specialCondition = _specialConditions[player.id] ?? SpecialCondition.none;
    final condition = player.getDisplayConditionWithSpecial(specialCondition);

    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isMyTeam ? AppTheme.primaryBlue.withOpacity(0.5) : Colors.red.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // (T)이영호 + 배치 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getRaceColor(player.race.code),
                ),
              ),
              const SizedBox(width: 2),
              Text(player.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              if (isMyTeam) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_focusedMapIndex < 6 && selectedPlayers[_focusedMapIndex] == null) {
                      final playerIndex = ref.read(gameStateProvider)!.playerTeamPlayers.indexOf(player);
                      if (!selectedPlayers.contains(playerIndex)) {
                        setState(() {
                          selectedPlayers[_focusedMapIndex] = playerIndex;
                        });
                        _moveToNextEmptySlot();
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('배치', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // 8각형 레이더 차트 + 컨디션
          Row(
            children: [
              // 8각형 레이더 차트
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: CustomPaint(
                    painter: _RadarChartPainter(player.stats),
                  ),
                ),
              ),
              // 컨디션 + 특수 컨디션
              Container(
                width: 50,
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    const Text('컨디션', style: TextStyle(fontSize: 8, color: AppTheme.textSecondary)),
                    const SizedBox(height: 2),
                    if (specialCondition != SpecialCondition.none)
                      Icon(
                        Icons.priority_high,
                        size: 12,
                        color: specialCondition == SpecialCondition.best ? Colors.green : Colors.red,
                      ),
                    Text(
                      '$condition%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: condition >= 80 ? Colors.green : (condition >= 50 ? Colors.orange : Colors.red),
                      ),
                    ),
                    if (specialCondition != SpecialCondition.none)
                      Text(
                        specialCondition == SpecialCondition.best ? '최상' : '최악',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: specialCondition == SpecialCondition.best ? Colors.green : Colors.red,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text('Lv.${player.level}', style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 중앙 맵 컬럼 (7개 세로 다닥다닥 배치)
  Widget _buildMapColumn(List<GameMap> matchMaps, List<Player> teamPlayers) {
    return Container(
      color: AppTheme.cardBackground.withOpacity(0.5),
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

          return _MapRowCompact(
            setNumber: index + 1,
            map: map,
            player: player,
            isFocused: isFocused,
            onTap: () {
              setState(() {
                _focusedMapIndex = index;
              });
            },
            onPlayerRemove: () {
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

  void _useSniping(String opponentTeamId, List<Player> opponentPlayers) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final updatedInventory = gameState.inventory.useConsumable('sniping');
    ref.read(gameStateProvider.notifier).updateInventory(updatedInventory);

    _predictedOpponentRoster = _generatePredictedRoster(opponentPlayers);

    setState(() {
      _snipingUsed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('스나이핑 발동!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
    );
  }

  List<String?> _generatePredictedRoster(List<Player> opponentPlayers) {
    if (opponentPlayers.isEmpty) return List.filled(6, null);

    final sortedPlayers = List<Player>.from(opponentPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    final selectedCount = sortedPlayers.length >= 6 ? 6 : sortedPlayers.length;
    final roster = <String?>[];

    for (int i = 0; i < 6; i++) {
      if (i < selectedCount) {
        roster.add(sortedPlayers[i].id);
      } else {
        roster.add(null);
      }
    }

    final random = Random();
    for (int i = roster.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = roster[i];
      roster[i] = roster[j];
      roster[j] = temp;
    }

    return roster;
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

    if (isHome) {
      ref.read(currentMatchProvider.notifier).startMatch(
        homeTeamId: playerTeam.id,
        awayTeamId: opponentTeam.id,
        homeRoster: roster,
      );
    } else {
      ref.read(currentMatchProvider.notifier).startMatch(
        homeTeamId: opponentTeam.id,
        awayTeamId: playerTeam.id,
        awayRoster: roster,
      );
    }

    ref.read(currentMatchProvider.notifier).setSpecialConditions(_specialConditions);

    context.go('/match');
  }
}

/// 8각형 레이더 차트 페인터
class _RadarChartPainter extends CustomPainter {
  final PlayerStats stats;

  _RadarChartPainter(this.stats);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;

    // 8개 능력치
    final values = [
      stats.sense / 1000,
      stats.control / 1000,
      stats.attack / 1000,
      stats.harass / 1000,
      stats.strategy / 1000,
      stats.macro / 1000,
      stats.defense / 1000,
      stats.scout / 1000,
    ];

    final labels = ['센스', '컨트롤', '공격', '견제', '전략', '물량', '수비', '정찰'];

    // 배경 그리드
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (var i = 1; i <= 4; i++) {
      final path = Path();
      for (var j = 0; j < 8; j++) {
        final angle = (j * 45 - 90) * pi / 180;
        final r = radius * i / 4;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 데이터 영역
    final dataPath = Path();
    final dataPaint = Paint()
      ..color = AppTheme.primaryBlue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppTheme.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * pi / 180;
      final r = radius * values[i].clamp(0.0, 1.0);
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, borderPaint);

    // 라벨
    final textStyle = TextStyle(color: AppTheme.textSecondary, fontSize: 7);
    for (var i = 0; i < 8; i++) {
      final angle = (i * 45 - 90) * pi / 180;
      final x = center.dx + (radius + 10) * cos(angle);
      final y = center.dy + (radius + 10) * sin(angle);

      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 내 팀 선수 그리드 아이템
class _PlayerGridItem extends StatelessWidget {
  final Player player;
  final bool isAssigned;
  final bool isSelected;
  final int? assignedSet;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _PlayerGridItem({
    required this.player,
    required this.isAssigned,
    required this.isSelected,
    this.assignedSet,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withOpacity(0.3)
              : (isAssigned ? AppTheme.accentGreen.withOpacity(0.2) : AppTheme.cardBackground),
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
  final bool isPredicted;
  final int? predictedSet;
  final VoidCallback onTap;

  const _OpponentGridItem({
    required this.player,
    required this.isSelected,
    this.isPredicted = false,
    this.predictedSet,
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
              ? Colors.red.withOpacity(0.3)
              : (isPredicted ? Colors.green.withOpacity(0.2) : AppTheme.cardBackground),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? Colors.red : (isPredicted ? Colors.green : Colors.transparent),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 예측 세트
            if (isPredicted && predictedSet != null) ...[
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(2)),
                child: Center(child: Text('$predictedSet', style: const TextStyle(fontSize: 7, color: Colors.white))),
              ),
              const SizedBox(width: 2),
            ],
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

/// 맵 행
class _MapRow extends StatelessWidget {
  final int setNumber;
  final GameMap? map;
  final Player? player;
  final bool isFocused;
  final VoidCallback onTap;
  final VoidCallback onPlayerRemove;

  const _MapRow({
    required this.setNumber,
    required this.map,
    required this.player,
    required this.isFocused,
    required this.onTap,
    required this.onPlayerRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mapName = map?.name ?? '맵 $setNumber';
    final shortMapName = mapName.length > 5 ? '${mapName.substring(0, 4)}..' : mapName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: isFocused
              ? AppTheme.accentGreen.withOpacity(0.2)
              : (player != null ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isFocused
                ? AppTheme.accentGreen
                : (player != null ? AppTheme.primaryBlue : AppTheme.textSecondary.withOpacity(0.3)),
            width: isFocused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16, height: 16,
              decoration: BoxDecoration(
                color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('$setNumber', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                    color: isFocused ? Colors.black : AppTheme.textSecondary)),
              ),
            ),
            const SizedBox(width: 3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shortMapName, style: TextStyle(fontSize: 8,
                      color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                  if (player != null)
                    GestureDetector(
                      onTap: onPlayerRemove,
                      child: Row(
                        children: [
                          CircleAvatar(radius: 5, backgroundColor: AppTheme.getRaceColor(player!.race.code),
                              child: Text(player!.race.code, style: const TextStyle(fontSize: 5, color: Colors.white))),
                          const SizedBox(width: 2),
                          Expanded(child: Text(player!.name, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    )
                  else
                    Text(isFocused ? '← 선택' : '', style: TextStyle(fontSize: 7,
                        color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 에이스 맵 행
class _AceMapRow extends StatelessWidget {
  final GameMap? map;

  const _AceMapRow({required this.map});

  @override
  Widget build(BuildContext context) {
    final mapName = map?.name ?? 'ACE';
    final shortMapName = mapName.length > 5 ? '${mapName.substring(0, 4)}..' : mapName;

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 16, height: 16,
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
            child: const Center(child: Icon(Icons.star, size: 10, color: Colors.orange)),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortMapName, style: TextStyle(fontSize: 8, color: Colors.orange.withOpacity(0.8)), overflow: TextOverflow.ellipsis),
                Text('ACE (3:3)', style: TextStyle(fontSize: 7, color: Colors.orange.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 맵 스탯 박스 (러시/자원/복잡)
class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 8, color: color)),
            Text('$value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/// 종족 상성 박스 (T:Z, Z:P, P:T)
class _MatchupBox extends StatelessWidget {
  final String label;
  final int value; // 첫 번째 종족의 승률

  const _MatchupBox({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final color = value > 55 ? Colors.green : (value < 45 ? Colors.red : AppTheme.textSecondary);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            const SizedBox(height: 2),
            Text('$value%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

/// 아이템 카드
class _ItemCard extends StatelessWidget {
  final ConsumableItem item;
  final int count;

  const _ItemCard({
    required this.item,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (item.id) {
      case 'vita_vita':
        icon = Icons.local_drink;
        color = Colors.green;
        break;
      case 'chewing_gum':
        icon = Icons.bubble_chart;
        color = Colors.pink;
        break;
      case 'ceremony':
        icon = Icons.celebration;
        color = Colors.purple;
        break;
      case 'sniping':
        icon = Icons.visibility;
        color = Colors.orange;
        break;
      case 'cheerful':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      default:
        icon = Icons.inventory_2;
        color = Colors.grey;
    }

    return Container(
      width: 50,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 2),
          Text(
            item.name,
            style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'x$count',
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트 스탯 박스 (가로형)
class _StatBoxCompact extends StatelessWidget {
  final String label;
  final int value;

  const _StatBoxCompact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 7, color: color)),
          Text('$value', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// 미니 스탯 박스 (세로 배치용)
class _StatBoxMini extends StatelessWidget {
  final String label;
  final int value;

  const _StatBoxMini({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value >= 7 ? Colors.green : (value >= 4 ? Colors.orange : Colors.red);
    return Container(
      width: 36,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 7, color: color)),
          Text('$value', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// 컴팩트 상성 박스 (가로형)
class _MatchupBoxCompact extends StatelessWidget {
  final String label;
  final int value;

  const _MatchupBoxCompact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value > 55 ? Colors.green : (value < 45 ? Colors.red : AppTheme.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 7, color: AppTheme.textSecondary)),
          Text('$value', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// 컴팩트 아이템 카드 (가로 리스트용)
class _ItemCardCompact extends StatelessWidget {
  final ConsumableItem item;
  final int count;

  const _ItemCardCompact({required this.item, required this.count});

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
      width: 55,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: TextStyle(fontSize: 7, color: color, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text('x$count', style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 컴팩트 맵 행 (다닥다닥)
class _MapRowCompact extends StatelessWidget {
  final int setNumber;
  final GameMap? map;
  final Player? player;
  final bool isFocused;
  final VoidCallback onTap;
  final VoidCallback onPlayerRemove;

  const _MapRowCompact({
    required this.setNumber,
    required this.map,
    required this.player,
    required this.isFocused,
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
          color: isFocused
              ? AppTheme.accentGreen.withOpacity(0.2)
              : (player != null ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isFocused
                ? AppTheme.accentGreen
                : (player != null ? AppTheme.primaryBlue : AppTheme.textSecondary.withOpacity(0.3)),
            width: isFocused ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14, height: 14,
              decoration: BoxDecoration(
                color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Center(
                child: Text('$setNumber', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold,
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
                        color: isFocused ? AppTheme.accentGreen : AppTheme.textSecondary.withOpacity(0.5))),
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
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), borderRadius: BorderRadius.circular(7)),
            child: const Center(child: Icon(Icons.star, size: 8, color: Colors.orange)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shortMapName, style: TextStyle(fontSize: 7, color: Colors.orange.withOpacity(0.8)), overflow: TextOverflow.ellipsis),
                Text('ACE', style: TextStyle(fontSize: 6, color: Colors.orange.withOpacity(0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
