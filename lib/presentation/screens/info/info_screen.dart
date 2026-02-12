import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme.dart';
import '../../../data/providers/game_provider.dart';
import '../../../data/repositories/player_image_repository.dart';
import '../../../domain/models/models.dart';
import '../../widgets/player_radar_chart.dart';
import '../../widgets/reset_button.dart';

class InfoScreen extends ConsumerStatefulWidget {
  final String? initialTeamId;
  final int initialTab;

  const InfoScreen({super.key, this.initialTeamId, this.initialTab = 0});

  @override
  ConsumerState<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends ConsumerState<InfoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedTeamId;
  String? _selectedPlayerId;
  int _recordTabIndex = 0; // 0: 전체전적, 1: 상대전적

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab);
    _selectedTeamId = widget.initialTeamId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: Text('게임 데이터를 불러올 수 없습니다')),
      );
    }

    _selectedTeamId ??= gameState.playerTeam.id;
    final allTeams = gameState.saveData.allTeams;
    final selectedTeam = allTeams.firstWhere(
      (t) => t.id == _selectedTeamId,
      orElse: () => gameState.playerTeam,
    );
    final teamPlayers = gameState.saveData.getTeamPlayers(selectedTeam.id);

    if (_selectedPlayerId == null && teamPlayers.isNotEmpty) {
      _selectedPlayerId = teamPlayers.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('정보'),
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
        actions: [
          ResetButton.action(),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '선수 정보'),
            Tab(text: '구단 정보'),
          ],
        ),
      ),
      body: Column(
            children: [
              // 팀 선택 드롭다운
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.cardBackground,
                child: Row(
                  children: [
                    const Text(
                      '팀: ',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedTeamId,
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        underline: Container(),
                        items: allTeams.map((team) {
                          final isPlayerTeam = team.id == gameState.playerTeam.id;
                          return DropdownMenuItem(
                            value: team.id,
                            child: Text(
                              isPlayerTeam ? '${team.name} (내 팀)' : team.name,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: isPlayerTeam ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                        selectedItemBuilder: (context) {
                          return allTeams.map((team) {
                            final isPlayerTeam = team.id == gameState.playerTeam.id;
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isPlayerTeam ? '${team.name} (내 팀)' : team.name,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: isPlayerTeam ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        onChanged: (value) {
                          setState(() {
                            _selectedTeamId = value;
                            _selectedPlayerId = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 탭 내용
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildPlayerInfoTab(teamPlayers, gameState),
                    _buildTeamInfoTab(selectedTeam, gameState),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPlayerInfoTab(List<Player> players, GameState gameState) {
    if (players.isEmpty) {
      return const Center(child: Text('선수가 없습니다'));
    }

    final selectedPlayer = players.firstWhere(
      (p) => p.id == _selectedPlayerId,
      orElse: () => players.first,
    );

    return Row(
      children: [
        // 왼쪽: 선수 목록
        SizedBox(
          width: 140,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final isSelected = player.id == _selectedPlayerId;
              return Card(
                color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBackground,
                margin: const EdgeInsets.only(bottom: 4),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPlayerId = player.id;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.getRaceColor(player.race.code),
                          child: Text(
                            player.race.code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            player.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 오른쪽: 선수 상세 정보
        Expanded(
          child: _buildPlayerDetail(selectedPlayer, gameState),
        ),
      ],
    );
  }

  final _imageRepo = PlayerImageRepository.instance;

  /// 갤러리에서 선수 사진 선택
  Future<void> _pickPlayerImage(Player player) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    await _imageRepo.setImagePath(player.id, pickedFile.path);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} 사진이 등록되었습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 이미지 옵션 메뉴 (탭)
  void _showImageOptions(Player player) {
    if (_imageRepo.getImagePath(player.id) == null) {
      _pickPlayerImage(player);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('사진 변경', style: TextStyle(color: Colors.white, fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _pickPlayerImage(player);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('사진 삭제', style: TextStyle(color: Colors.red, fontSize: 14)),
              onTap: () async {
                Navigator.pop(context);
                await _deletePlayerImage(player);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 선수 사진 삭제
  Future<void> _deletePlayerImage(Player player) async {
    await _imageRepo.removeImage(player.id);

    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} 사진이 삭제되었습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildPlayerDetail(Player player, GameState gameState) {
    final stats = player.stats;
    final grade = player.grade;
    final conditionColor = player.condition >= 80
        ? AppTheme.accentGreen
        : player.condition >= 50
            ? Colors.orange
            : Colors.red;
    final imagePath = _imageRepo.getImagePath(player.id);
    final hasImage = imagePath != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선수 사진 + 이름 + 종족 + 컨디션
          Row(
            children: [
              // 선수 사진 (모든 선수 탭하여 관리)
              GestureDetector(
                onTap: () => _showImageOptions(player),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.getRaceColor(player.race.code).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.getRaceColor(player.race.code),
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: hasImage
                        ? Image.file(
                            File(imagePath),
                            fit: BoxFit.cover,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                player.race.code,
                                style: TextStyle(
                                  color: AppTheme.getRaceColor(player.race.code),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.add_a_photo,
                                size: 10,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '컨디션 ${player.condition}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: conditionColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 총합
          Text(
            '총합 ${stats.total}  |  ${grade.display}  |  Lv.${player.level.value}',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          // 8각형 레이더 차트 (등급+레벨 중앙 표시)
          SizedBox(
            height: 180,
            child: PlayerRadarChart(
              stats: stats,
              color: AppTheme.getGradeColor(grade.display),
              grade: grade.display,
              level: player.level.value,
            ),
          ),
          const SizedBox(height: 8),
          // 전적 토글 (전체전적 / 상대전적)
          _buildRecordToggle(player, gameState),
        ],
      ),
    );
  }

  Widget _buildRecordToggle(Player player, GameState gameState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 탭 바
        Row(
          children: [
            _buildToggleTab('전체전적', 0),
            const SizedBox(width: 4),
            _buildToggleTab('상대전적', 1),
          ],
        ),
        const SizedBox(height: 8),
        // 탭 컨텐츠
        if (_recordTabIndex == 0) _buildOverallRecord(player),
        if (_recordTabIndex == 1) _buildVsRecord(player, gameState),
      ],
    );
  }

  Widget _buildToggleTab(String label, int index) {
    final isActive = _recordTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _recordTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBlue : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? AppTheme.primaryBlue : AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildOverallRecord(Player player) {
    final record = player.record;
    return Column(
      children: [
        _buildRecordLine('총 전적', record.wins, record.losses),
        _buildRecordLine('vs 테란', record.vsTerranWins, record.vsTerranLosses),
        _buildRecordLine('vs 저그', record.vsZergWins, record.vsZergLosses),
        _buildRecordLine('vs 프로토스', record.vsProtossWins, record.vsProtossLosses),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '우승 ${record.championships}회  준우승 ${record.runnerUps}회',
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            Text(
              record.currentWinStreak > 0
                  ? '${record.currentWinStreak}연승'
                  : record.currentWinStreak < 0
                      ? '${-record.currentWinStreak}연패'
                      : '',
              style: TextStyle(
                fontSize: 11,
                color: record.currentWinStreak > 0 ? AppTheme.accentGreen : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordLine(String label, int wins, int losses) {
    final total = wins + losses;
    final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(1) : '0.0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          Text(
            '$wins승 $losses패',
            style: const TextStyle(fontSize: 11),
          ),
          const Spacer(),
          Text(
            '($winRate%)',
            style: TextStyle(
              fontSize: 11,
              color: double.parse(winRate) >= 50
                  ? AppTheme.accentGreen
                  : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVsRecord(Player player, GameState gameState) {
    final opponentIds = player.record.allOpponentIds.toList();
    if (opponentIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            '상대전적이 없습니다',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    // 대전 횟수 많은 순 정렬
    opponentIds.sort((a, b) {
      final (aW, aL) = player.record.getVsPlayerRecord(a);
      final (bW, bL) = player.record.getVsPlayerRecord(b);
      return (bW + bL).compareTo(aW + aL);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opId in opponentIds.take(8)) // 상위 8명까지 표시
          _buildVsRecordLine(opId, player, gameState),
        if (opponentIds.length > 8)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '외 ${opponentIds.length - 8}명...',
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ),
      ],
    );
  }

  Widget _buildVsRecordLine(String opponentId, Player player, GameState gameState) {
    final opponent = gameState.saveData.getPlayerById(opponentId);
    final (wins, losses) = player.record.getVsPlayerRecord(opponentId);
    final total = wins + losses;
    final winRate = total > 0 ? (wins / total * 100).toStringAsFixed(0) : '0';
    final name = opponent?.name ?? '알 수 없음';
    final raceCode = opponent?.race.code ?? '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '($raceCode) ',
            style: TextStyle(
              fontSize: 10,
              color: opponent != null
                  ? AppTheme.getRaceColor(opponent.race.code)
                  : AppTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '$wins승 $losses패 ($winRate%)',
            style: TextStyle(
              fontSize: 10,
              color: wins > losses
                  ? AppTheme.accentGreen
                  : wins < losses
                      ? Colors.red
                      : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamInfoTab(Team team, GameState gameState) {
    final record = team.record;
    final totalMatches = record.wins + record.losses;
    final winRate = totalMatches > 0
        ? (record.wins / totalMatches * 100).toStringAsFixed(1)
        : '0.0';

    // 이번 시즌 전적 계산
    final season = gameState.saveData.currentSeason;
    final seasonMatches = season.proleagueSchedule.where(
      (m) => m.isCompleted && (m.homeTeamId == team.id || m.awayTeamId == team.id),
    );
    int seasonWins = 0;
    int seasonLosses = 0;
    int seasonSetsWon = 0;
    int seasonSetsLost = 0;

    for (final match in seasonMatches) {
      final result = match.result;
      if (result == null) continue;
      final isHome = match.homeTeamId == team.id;
      final ourScore = isHome ? result.homeScore : result.awayScore;
      final theirScore = isHome ? result.awayScore : result.homeScore;

      if (ourScore > theirScore) {
        seasonWins++;
      } else {
        seasonLosses++;
      }
      seasonSetsWon += ourScore;
      seasonSetsLost += theirScore;
    }

    final seasonTotal = seasonWins + seasonLosses;
    final seasonWinRate = seasonTotal > 0
        ? (seasonWins / seasonTotal * 100).toStringAsFixed(1)
        : '0.0';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 팀 기본 정보
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '자금: ${team.money}만원',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 전체 전적
          const Text(
            '전체 전적',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStatColumn('승', record.wins, AppTheme.accentGreen),
                    _buildTeamStatColumn('패', record.losses, Colors.red),
                    _buildTeamStatColumn('승률', '$winRate%',
                        double.parse(winRate) >= 50 ? AppTheme.accentGreen : AppTheme.textSecondary),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStatColumn('프로리그 우승', record.proleagueChampionships, Colors.amber),
                    _buildTeamStatColumn('프로리그 준우승', record.proleagueRunnerUps, Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStatColumn('개인리그 우승', record.individualChampionships, Colors.amber),
                    _buildTeamStatColumn('개인리그 준우승', record.individualRunnerUps, Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 이번 시즌 전적
          const Text(
            '이번 시즌 전적',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStatColumn('승', seasonWins, AppTheme.accentGreen),
                    _buildTeamStatColumn('패', seasonLosses, Colors.red),
                    _buildTeamStatColumn('승률', '$seasonWinRate%',
                        double.parse(seasonWinRate) >= 50 ? AppTheme.accentGreen : AppTheme.textSecondary),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStatColumn('세트 득', seasonSetsWon, AppTheme.accentGreen),
                    _buildTeamStatColumn('세트 실', seasonSetsLost, Colors.red),
                    _buildTeamStatColumn('세트 차', seasonSetsWon - seasonSetsLost,
                        seasonSetsWon >= seasonSetsLost ? AppTheme.accentGreen : Colors.red),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 하단 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/player-ranking'),
                  icon: const Icon(Icons.person),
                  label: const Text('선수 순위'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/team-ranking'),
                  icon: const Icon(Icons.groups),
                  label: const Text('구단 순위'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentGreen,
                    side: const BorderSide(color: AppTheme.accentGreen),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStatColumn(String label, dynamic value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

