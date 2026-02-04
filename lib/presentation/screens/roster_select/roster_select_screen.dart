import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../../domain/models/models.dart';
import '../../widgets/reset_button.dart';

class RosterSelectScreen extends ConsumerStatefulWidget {
  const RosterSelectScreen({super.key});

  @override
  ConsumerState<RosterSelectScreen> createState() => _RosterSelectScreenState();
}

class _RosterSelectScreenState extends ConsumerState<RosterSelectScreen> {
  // 7맵에 배치된 선수 인덱스 (null = 빈 슬롯)
  final List<int?> selectedPlayers = List.filled(7, null);

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

    // 상대팀 선택 (현재는 첫 번째 다른 팀)
    final opponentTeam = gameState.saveData.allTeams
        .firstWhere((t) => t.id != playerTeam.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('로스터 선택'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/main'),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 매치 정보
              Container(
                padding: const EdgeInsets.all(16),
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
                        const Text(
                          'HOME',
                          style: TextStyle(
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
                        const Text(
                          'AWAY',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 맵 슬롯
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  '맵별 선수 배치 (7전 4선승제)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final playerIndex = selectedPlayers[index];
                    final player = playerIndex != null && playerIndex < teamPlayers.length
                        ? teamPlayers[playerIndex]
                        : null;

                    return _MapSlot(
                      mapNumber: index + 1,
                      player: player,
                      onTap: () {
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

              const Divider(),

              // 선수 목록
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text('선수 목록', style: TextStyle(fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text(
                      '터치하여 맵에 배치',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: teamPlayers.length,
                  itemBuilder: (context, index) {
                    final player = teamPlayers[index];
                    final isAssigned = selectedPlayers.contains(index);

                    return _PlayerCard(
                      player: player,
                      isAssigned: isAssigned,
                      onTap: isAssigned
                          ? null
                          : () {
                              // 빈 슬롯 찾아서 배치
                              final emptySlot = selectedPlayers.indexOf(null);
                              if (emptySlot != -1) {
                                setState(() {
                                  selectedPlayers[emptySlot] = index;
                                });
                              }
                            },
                    );
                  },
                ),
              ),

              // 제출 버튼
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedPlayers.where((p) => p != null).length >= 4
                        ? () => context.go('/match')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.cardBackground,
                    ),
                    child: Text(
                      '로스터 제출 (${selectedPlayers.where((p) => p != null).length}/7)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          ResetButton.positioned(),
        ],
      ),
    );
  }
}

class _MapSlot extends StatelessWidget {
  final int mapNumber;
  final Player? player;
  final VoidCallback onTap;

  const _MapSlot({
    required this.mapNumber,
    required this.player,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raceCode = player?.race.code ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: player != null ? AppTheme.accentGreen : AppTheme.primaryBlue,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MAP $mapNumber',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            if (player != null) ...[
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
              const SizedBox(height: 4),
              Text(
                player!.name,
                style: const TextStyle(fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.textSecondary,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.add,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '빈 슬롯',
                style: TextStyle(
                  fontSize: 10,
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

class _PlayerCard extends StatelessWidget {
  final Player player;
  final bool isAssigned;
  final VoidCallback? onTap;

  const _PlayerCard({
    required this.player,
    required this.isAssigned,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final raceCode = player.race.code;
    final gradeString = player.grade.display; // Grade enum display name
    final condition = player.condition;

    return Card(
      color: isAssigned
          ? AppTheme.cardBackground.withOpacity(0.5)
          : AppTheme.cardBackground,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.getRaceColor(raceCode),
          child: Text(
            raceCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          player.name,
          style: TextStyle(
            color: isAssigned ? AppTheme.textSecondary : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text('컨디션: $condition%'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.getGradeColor(gradeString),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                gradeString,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            if (isAssigned) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppTheme.accentGreen),
            ],
          ],
        ),
      ),
    );
  }
}
