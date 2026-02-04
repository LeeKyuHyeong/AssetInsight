import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
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

class _RosterSelectScreenState extends ConsumerState<RosterSelectScreen>
    with SingleTickerProviderStateMixin {
  // 6세트에 배치된 선수 인덱스 (null = 빈 슬롯)
  final List<int?> selectedPlayers = List.filled(6, null);

  // 선택된 맵 인덱스 (상세정보 표시용)
  int? _selectedMapIndex;

  // 탭 컨트롤러 (내 팀 / 상대 팀)
  late TabController _tabController;

  // 세트별 맵 (랜덤 선정)
  List<GameMap> _matchMaps = [];

  // 스나이핑 사용 여부
  bool _snipingUsed = false;

  // 예측된 상대 로스터 (스나이핑 사용 시)
  List<String?> _predictedOpponentRoster = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 매치용 맵 7개 선정
  List<GameMap> _getMatchMaps(List<String> seasonMapIds) {
    if (_matchMaps.isNotEmpty) return _matchMaps;

    // 시즌 맵에서 7개 랜덤 선정
    final allMaps = seasonMapIds
        .map((id) => GameMaps.getById(id))
        .whereType<GameMap>()
        .toList();

    if (allMaps.isEmpty) {
      // 시즌맵이 없으면 기본 맵 사용
      _matchMaps = GameMaps.all.take(7).toList();
    } else {
      // 랜덤 셔플 후 7개 선택
      final shuffled = List<GameMap>.from(allMaps)..shuffle(Random());
      _matchMaps = shuffled.take(7).toList();
      // 부족하면 반복
      while (_matchMaps.length < 7) {
        _matchMaps.add(allMaps[_matchMaps.length % allMaps.length]);
      }
    }

    return _matchMaps;
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

    // 스케줄에서 다음 경기 찾기 (라운드 순서대로, 미완료 경기 중 가장 먼저)
    final schedule = gameState.saveData.currentSeason.proleagueSchedule;
    final nextMatch = _findNextMatch(schedule, playerTeam.id);

    if (nextMatch == null) {
      // 더 이상 경기가 없음
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 경기가 완료되었습니다.')),
        );
        context.go('/main');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // 실제 스케줄의 상대팀 가져오기
    final isHome = nextMatch.homeTeamId == playerTeam.id;
    final opponentId = isHome ? nextMatch.awayTeamId : nextMatch.homeTeamId;
    final opponentTeam = gameState.saveData.getTeamById(opponentId) ??
        gameState.saveData.allTeams.firstWhere((t) => t.id != playerTeam.id);

    // 상대팀 선수 목록
    final opponentPlayers = gameState.saveData.getTeamPlayers(opponentId);

    // 시즌맵 가져오기
    final seasonMapIds = gameState.saveData.currentSeason.seasonMapIds;
    final matchMaps = _getMatchMaps(seasonMapIds);

    // 선택된 선수 수
    final selectedCount = selectedPlayers.where((p) => p != null).length;
    final canSubmit = selectedCount >= 6; // 6명 필수

    return Scaffold(
      appBar: AppBar(
        title: const Text('로스터 선택'),
        leading: ResetButton.leading(),
      ),
      body: Column(
            children: [
              // 매치 정보
              Container(
                padding: const EdgeInsets.all(12),
                color: AppTheme.cardBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          playerTeam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isHome ? 'HOME' : 'AWAY',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          opponentTeam.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isHome ? 'AWAY' : 'HOME',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 맵 슬롯 (맵 정보 포함)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    const Text(
                      '맵별 선수 배치 (7전 4선승제)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '맵을 터치하면 상세정보 / 선수를 터치하면 배치 해제',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final map = index < matchMaps.length ? matchMaps[index] : null;

                    // 7세트는 에이스 결정전 표시
                    if (index == 6) {
                      return _AceSlot(
                        map: map,
                        isSelected: _selectedMapIndex == 6,
                        onTap: () {
                          setState(() {
                            _selectedMapIndex = _selectedMapIndex == 6 ? null : 6;
                          });
                        },
                      );
                    }

                    final playerIndex = selectedPlayers[index];
                    final player = playerIndex != null && playerIndex < teamPlayers.length
                        ? teamPlayers[playerIndex]
                        : null;

                    return _MapSlot(
                      mapNumber: index + 1,
                      map: map,
                      player: player,
                      isSelected: _selectedMapIndex == index,
                      onMapTap: () {
                        setState(() {
                          _selectedMapIndex = _selectedMapIndex == index ? null : index;
                        });
                      },
                      onPlayerTap: () {
                        // 선수 선택 해제
                        if (selectedPlayers[index] != null) {
                          setState(() {
                            selectedPlayers[index] = null;
                          });
                        }
                      },
                    );
                  },
                ),
              ),

              // 선택된 맵 상세정보
              if (_selectedMapIndex != null && _selectedMapIndex! < matchMaps.length)
                _MapDetailCard(map: matchMaps[_selectedMapIndex!]),

              const Divider(height: 1),

              // 탭바 (내 팀 / 상대 팀)
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: '내 팀 (${teamPlayers.length}명)'),
                  Tab(text: '상대 팀 (${opponentPlayers.length}명)'),
                ],
                indicatorColor: AppTheme.accentGreen,
                labelColor: AppTheme.accentGreen,
                unselectedLabelColor: AppTheme.textSecondary,
              ),

              // 선수 목록 (탭뷰)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // 내 팀 선수 목록
                    _buildMyTeamList(teamPlayers),
                    // 상대 팀 선수 목록
                    _buildOpponentList(opponentPlayers, opponentId),
                  ],
                ),
              ),

              // 제출 버튼
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
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
                      canSubmit
                          ? '로스터 제출'
                          : '선수 배치 필요 ($selectedCount/6)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMyTeamList(List<Player> teamPlayers) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      itemCount: teamPlayers.length,
      itemBuilder: (context, index) {
        final player = teamPlayers[index];
        final isAssigned = selectedPlayers.contains(index);
        final assignedSet = selectedPlayers.indexOf(index);

        return _PlayerCard(
          player: player,
          isAssigned: isAssigned,
          assignedSet: assignedSet >= 0 ? assignedSet + 1 : null,
          onTap: isAssigned
              ? null
              : () {
                  // 빈 슬롯 찾아서 배치 (1~6세트만)
                  final emptySlot = selectedPlayers.indexOf(null);
                  if (emptySlot != -1 && emptySlot < 6) {
                    setState(() {
                      selectedPlayers[emptySlot] = index;
                    });
                  }
                },
        );
      },
    );
  }

  Widget _buildOpponentList(List<Player> opponentPlayers, String opponentTeamId) {
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
        // 스나이핑 버튼
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: AppTheme.cardBackground.withOpacity(0.5),
          child: _snipingUsed
              ? Row(
                  children: [
                    Icon(Icons.visibility, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '스나이핑 발동! 상대 예상 로스터 확인 중',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.track_changes, size: 16, color: snipingCount > 0 ? Colors.orange : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        snipingCount > 0
                            ? '스나이핑 보유: ${snipingCount}개'
                            : '스나이핑 아이템 없음',
                        style: TextStyle(
                          color: snipingCount > 0 ? Colors.orange : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (snipingCount > 0)
                      ElevatedButton.icon(
                        onPressed: () => _useSniping(opponentTeamId, opponentPlayers),
                        icon: const Icon(Icons.visibility, size: 14),
                        label: const Text('사용', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(0, 28),
                        ),
                      ),
                  ],
                ),
        ),
        // 스나이핑 사용 시 예상 로스터 표시
        if (_snipingUsed && _predictedOpponentRoster.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      '예상 로스터 (세트 순서)',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ...List.generate(6, (i) {
                  final playerId = i < _predictedOpponentRoster.length ? _predictedOpponentRoster[i] : null;
                  final player = playerId != null
                      ? opponentPlayers.firstWhere((p) => p.id == playerId, orElse: () => opponentPlayers.first)
                      : null;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (player != null) ...[
                          Text(
                            player.name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${player.race.code})',
                            style: TextStyle(
                              color: _getRaceColor(player.race),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            player.grade.display,
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ] else
                          Text(
                            '?',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            itemCount: sortedPlayers.length,
            itemBuilder: (context, index) {
              final player = sortedPlayers[index];
              // 스나이핑으로 예측된 선수 강조
              final isPredicted = _snipingUsed && _predictedOpponentRoster.contains(player.id);
              return _OpponentPlayerCard(
                player: player,
                isPredicted: isPredicted,
                predictedSet: isPredicted ? _predictedOpponentRoster.indexOf(player.id) + 1 : null,
              );
            },
          ),
        ),
      ],
    );
  }

  /// 스나이핑 아이템 사용
  void _useSniping(String opponentTeamId, List<Player> opponentPlayers) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    // 인벤토리에서 스나이핑 사용
    final updatedInventory = gameState.inventory.useConsumable('sniping');
    ref.read(gameStateProvider.notifier).updateInventory(updatedInventory);

    // AI가 예측할 로스터 생성 (matchProvider의 로직과 동일)
    _predictedOpponentRoster = _generatePredictedRoster(opponentPlayers);

    setState(() {
      _snipingUsed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('스나이핑 발동! 상대 예상 로스터를 확인하세요'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// AI 예측 로스터 생성
  List<String?> _generatePredictedRoster(List<Player> opponentPlayers) {
    if (opponentPlayers.isEmpty) return List.filled(6, null);

    // 컨디션 + 등급 기준으로 정렬
    final sortedPlayers = List<Player>.from(opponentPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    // 상위 6명 선택
    final selectedCount = sortedPlayers.length >= 6 ? 6 : sortedPlayers.length;
    final roster = <String?>[];

    for (int i = 0; i < 6; i++) {
      if (i < selectedCount) {
        roster.add(sortedPlayers[i].id);
      } else {
        roster.add(null);
      }
    }

    // 약간의 랜덤성 (순서 섞기) - 실제 AI와 동일
    final random = Random();
    for (int i = roster.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = roster[i];
      roster[i] = roster[j];
      roster[j] = temp;
    }

    return roster;
  }

  Color _getRaceColor(Race race) {
    switch (race) {
      case Race.terran:
        return Colors.blue;
      case Race.zerg:
        return Colors.purple;
      case Race.protoss:
        return Colors.amber;
    }
  }

  /// 스케줄에서 다음 경기 찾기 (라운드 순서대로)
  ScheduleItem? _findNextMatch(dynamic schedule, String playerTeamId) {
    // 타입 안전하게 변환
    final List<ScheduleItem> typedSchedule = List<ScheduleItem>.from(schedule);

    // 내 팀의 미완료 경기 필터링
    final myIncompleteMatches = typedSchedule.where((s) =>
      !s.isCompleted &&
      (s.homeTeamId == playerTeamId || s.awayTeamId == playerTeamId)
    ).toList();

    if (myIncompleteMatches.isEmpty) return null;

    // 라운드 번호 순으로 정렬하고 첫 번째 반환
    myIncompleteMatches.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return myIncompleteMatches.first;
  }

  void _submitRoster(Team playerTeam, Team opponentTeam, List<Player> teamPlayers) {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    // 스케줄에서 다음 경기 찾기
    final schedule = gameState.saveData.currentSeason.proleagueSchedule;
    final nextMatch = _findNextMatch(schedule, playerTeam.id);
    if (nextMatch == null) return;

    // 홈/어웨이 결정
    final isHome = nextMatch.homeTeamId == playerTeam.id;

    // 선택된 선수 ID 목록 생성
    final roster = selectedPlayers.map((index) {
      if (index != null && index < teamPlayers.length) {
        return teamPlayers[index].id;
      }
      return null;
    }).toList();

    // 매치 시작 (실제 홈/어웨이 기준)
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

    // 경기 화면으로 이동
    context.go('/match');
  }
}

class _MapSlot extends StatelessWidget {
  final int mapNumber;
  final GameMap? map;
  final Player? player;
  final bool isSelected;
  final VoidCallback onMapTap;
  final VoidCallback onPlayerTap;

  const _MapSlot({
    required this.mapNumber,
    required this.map,
    required this.player,
    required this.isSelected,
    required this.onMapTap,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    final raceCode = player?.race.code ?? '';
    final mapName = map?.name ?? '맵 $mapNumber';
    // 맵 이름 축약 (8자 이상이면 줄임)
    final shortMapName = mapName.length > 6 ? '${mapName.substring(0, 5)}..' : mapName;

    return GestureDetector(
      onTap: onMapTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : (player != null ? AppTheme.accentGreen : AppTheme.primaryBlue),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 맵 이름
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Text(
                shortMapName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.orange : AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // 선수 또는 빈 슬롯
            if (player != null) ...[
              GestureDetector(
                onTap: onPlayerTap,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.getRaceColor(raceCode),
                  child: Text(
                    raceCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                player!.name,
                style: const TextStyle(fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.textSecondary,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.add,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Set $mapNumber',
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AceSlot extends StatelessWidget {
  final GameMap? map;
  final bool isSelected;
  final VoidCallback onTap;

  const _AceSlot({
    required this.map,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final mapName = map?.name ?? 'ACE 맵';
    final shortMapName = mapName.length > 6 ? '${mapName.substring(0, 5)}..' : mapName;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.orange.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 맵 이름
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.transparent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Text(
                shortMapName,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.withOpacity(isSelected ? 1.0 : 0.8),
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Icon(
              Icons.star,
              size: 20,
              color: Colors.orange.withOpacity(0.6),
            ),
            const SizedBox(height: 2),
            Text(
              'ACE (3:3)',
              style: TextStyle(
                fontSize: 8,
                color: Colors.orange.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 맵 상세 정보 카드
class _MapDetailCard extends StatelessWidget {
  final GameMap map;

  const _MapDetailCard({required this.map});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, size: 16, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  map.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 맵 속성
          Row(
            children: [
              _MapStatBar(label: '러시거리', value: map.rushDistance, color: Colors.red),
              const SizedBox(width: 8),
              _MapStatBar(label: '자원', value: map.resources, color: Colors.blue),
              const SizedBox(width: 8),
              _MapStatBar(label: '복잡도', value: map.complexity, color: Colors.purple),
            ],
          ),
          const SizedBox(height: 8),
          // 종족 상성
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MatchupChip(
                label: 'TvZ',
                rate1: map.matchup.tvzTerranWinRate,
                race1: 'T',
                race2: 'Z',
              ),
              _MatchupChip(
                label: 'ZvP',
                rate1: map.matchup.zvpZergWinRate,
                race1: 'Z',
                race2: 'P',
              ),
              _MatchupChip(
                label: 'PvT',
                rate1: map.matchup.pvtProtossWinRate,
                race1: 'P',
                race2: 'T',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapStatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MapStatBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: value / 10,
                    backgroundColor: AppTheme.cardBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.7)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$value',
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MatchupChip extends StatelessWidget {
  final String label;
  final int rate1;
  final String race1;
  final String race2;

  const _MatchupChip({
    required this.label,
    required this.rate1,
    required this.race1,
    required this.race2,
  });

  @override
  Widget build(BuildContext context) {
    final rate2 = 100 - rate1;
    final color1 = AppTheme.getRaceColor(race1);
    final color2 = AppTheme.getRaceColor(race2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rate1',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: rate1 >= 50 ? color1 : AppTheme.textSecondary,
            ),
          ),
          Text(
            ' $race1:$race2 ',
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
          Text(
            '$rate2',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: rate2 > 50 ? color2 : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final bool isAssigned;
  final int? assignedSet;
  final VoidCallback? onTap;

  const _PlayerCard({
    required this.player,
    required this.isAssigned,
    this.assignedSet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raceCode = player.race.code;
    final gradeString = player.grade.display;
    final condition = player.condition;

    return Card(
      color: isAssigned
          ? AppTheme.cardBackground.withOpacity(0.5)
          : AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.getRaceColor(raceCode),
                child: Text(
                  raceCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isAssigned ? AppTheme.textSecondary : AppTheme.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Lv.${player.level}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.favorite,
                          size: 10,
                          color: condition >= 80
                              ? Colors.green
                              : (condition >= 50 ? Colors.orange : Colors.red),
                        ),
                        Text(
                          ' $condition%',
                          style: TextStyle(
                            fontSize: 11,
                            color: condition >= 80
                                ? Colors.green
                                : (condition >= 50 ? Colors.orange : Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.getGradeColor(gradeString),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  gradeString,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 11,
                  ),
                ),
              ),
              if (isAssigned && assignedSet != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Set $assignedSet',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 상대팀 선수 카드
class _OpponentPlayerCard extends StatelessWidget {
  final Player player;
  final bool isPredicted;
  final int? predictedSet;

  const _OpponentPlayerCard({
    required this.player,
    this.isPredicted = false,
    this.predictedSet,
  });

  @override
  Widget build(BuildContext context) {
    final raceCode = player.race.code;
    final gradeString = player.grade.display;
    final condition = player.condition;

    return Card(
      color: isPredicted
          ? Colors.green.withOpacity(0.15)
          : AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 4),
      child: Container(
        decoration: isPredicted
            ? BoxDecoration(
                border: Border.all(color: Colors.green.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            // 예측 세트 번호 표시
            if (isPredicted && predictedSet != null) ...[
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '$predictedSet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.getRaceColor(raceCode),
              child: Text(
                raceCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Lv.${player.level}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.favorite,
                        size: 10,
                        color: condition >= 80
                            ? Colors.green
                            : (condition >= 50 ? Colors.orange : Colors.red),
                      ),
                      Text(
                        ' $condition%',
                        style: TextStyle(
                          fontSize: 11,
                          color: condition >= 80
                              ? Colors.green
                              : (condition >= 50 ? Colors.orange : Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 총 능력치 표시
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.getGradeColor(gradeString),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    gradeString,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '총${player.stats.total}',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
