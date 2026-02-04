import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/constants/team_data.dart';
import '../../widgets/reset_button.dart';

class TeamSelectScreen extends ConsumerStatefulWidget {
  const TeamSelectScreen({super.key});

  @override
  ConsumerState<TeamSelectScreen> createState() => _TeamSelectScreenState();
}

class _TeamSelectScreenState extends ConsumerState<TeamSelectScreen> {
  String? selectedTeamId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임단 선택'),
        leading: ResetButton.leading(),
      ),
      body: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '운영할 게임단을 선택하세요',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

              // 팀 그리드
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: TeamData.teams.length,
                    itemBuilder: (context, index) {
                      final team = TeamData.teams[index];
                      final teamId = team['id'] as String;
                      final isSelected = selectedTeamId == teamId;

                      return _TeamCard(
                        team: team,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            selectedTeamId = teamId;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),

              // 선택된 팀 정보
              if (selectedTeamId != null) ...[
                Builder(
                  builder: (context) {
                    final selectedTeam = TeamData.teams.firstWhere(
                      (t) => t['id'] == selectedTeamId,
                    );
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: AppTheme.cardBackground,
                      child: Column(
                        children: [
                          Text(
                            selectedTeam['name'] as String,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '에이스: ${selectedTeam['ace'] as String}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              // 확정 버튼
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedTeamId == null
                        ? null
                        : () {
                            // TODO: 선택한 팀으로 게임 시작
                            context.go('/director-name');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.cardBackground,
                    ),
                    child: const Text(
                      '게임 시작',
                      style: TextStyle(
                        fontSize: 18,
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
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final bool isSelected;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(team['color'] as int);
    final teamName = team['name'] as String;
    final teamShortName = team['shortName'] as String;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? teamColor : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: teamColor.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 팀 로고 플레이스홀더
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: teamColor,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  teamShortName,
                  style: TextStyle(
                    color: teamColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 팀명
            Text(
              teamName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
