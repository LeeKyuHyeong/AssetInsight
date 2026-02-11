import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/team_data.dart';
import '../../../core/constants/initial_data.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../../domain/models/models.dart';
import '../../../app/theme.dart';
import '../../widgets/player_radar_chart.dart';

/// 타이틀 화면 - 팀 선택 및 게임 시작
class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen> {
  String? selectedTeamId;
  int focusedPlayerIndex = 0;
  Timer? _focusTimer;
  List<Player> _teamRoster = [];

  Map<String, dynamic>? get selectedTeam {
    if (selectedTeamId == null) return null;
    return TeamData.teams.firstWhere(
      (t) => t['id'] == selectedTeamId,
      orElse: () => TeamData.teams.first,
    );
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  void _startFocusTimer() {
    _focusTimer?.cancel();
    if (_teamRoster.isEmpty) return;

    _focusTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        focusedPlayerIndex = (focusedPlayerIndex + 1) % _teamRoster.length;
      });
    });
  }

  void _loadTeamRoster(String teamId) {
    final allPlayers = InitialData.createPlayers();
    _teamRoster = allPlayers.where((p) => p.teamId == teamId).toList();
    focusedPlayerIndex = 0;
    _startFocusTimer();
  }

  void _onTeamSelected(String? teamId) {
    if (teamId == null) return;
    setState(() {
      selectedTeamId = teamId;
    });
    _loadTeamRoster(teamId);
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            Column(
              children: [
                SizedBox(height: 16.sp),
                // 상단: 로고 + 팀 선택 드롭다운
                _buildHeader(),
                SizedBox(height: 16.sp),

                // 중앙: 팀 로고 | 로스터 | 선수 정보
                Expanded(
                  child: selectedTeamId == null
                      ? _buildNoTeamSelected()
                      : _buildTeamContent(),
                ),

                SizedBox(height: 16.sp),
                // 하단 버튼
                _buildBottomButtons(),
                SizedBox(height: 12.sp),

                // 푸터
                Text(
                  'MyStar Pro Gamer Simulation  |  ver 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 8.sp),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 로고
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!, width: 2),
            borderRadius: BorderRadius.circular(8.sp),
          ),
          child: Column(
            children: [
              Text(
                'MY',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                  fontStyle: FontStyle.italic,
                  height: 0.9,
                ),
              ),
              Text(
                'STARCRAFT',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.sp),

        // 팀 선택 드롭다운
        Container(
          constraints: BoxConstraints(maxWidth: 280.sp),
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          decoration: BoxDecoration(
            color: const Color(0xFF1a1a2e),
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(color: Colors.grey[600]!, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTeamId,
              hint: Text(
                '프로게임단 선택',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16.sp,
                ),
              ),
              dropdownColor: const Color(0xFF1a1a2e),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: Colors.amber, size: 28.sp),
              items: TeamData.teams.map((team) {
                final teamColor = Color(team['color'] as int);
                return DropdownMenuItem<String>(
                  value: team['id'] as String,
                  child: Row(
                    children: [
                      Container(
                        width: 24.sp,
                        height: 24.sp,
                        decoration: BoxDecoration(
                          color: teamColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: teamColor, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            team['shortName'] as String,
                            style: TextStyle(
                              color: teamColor,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.sp),
                      Text(
                        team['name'] as String,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onTeamSelected,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTeamSelected() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_esports,
            size: 80.sp,
            color: Colors.grey[700],
          ),
          SizedBox(height: 16.sp),
          Text(
            '팀을 선택해주세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamContent() {
    final team = selectedTeam!;
    final teamColor = Color(team['color'] as int);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      child: Column(
        children: [
          // 상단: 팀 정보 (컴팩트)
          _buildTeamHeader(team, teamColor),

          SizedBox(height: 12.sp),

          // 중단: 로스터 + 선수 정보 (탭 또는 분할)
          Expanded(
            child: Row(
              children: [
                // 로스터 리스트
                Expanded(
                  flex: 1,
                  child: _buildRosterList(teamColor),
                ),
                SizedBox(width: 8.sp),
                // 선수 정보
                Expanded(
                  flex: 1,
                  child: _buildPlayerInfo(teamColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamHeader(Map<String, dynamic> team, Color teamColor) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: teamColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: teamColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          // 팀 로고
          Container(
            width: 50.sp,
            height: 50.sp,
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: teamColor, width: 2),
            ),
            child: Center(
              child: Text(
                team['shortName'] as String,
                style: TextStyle(
                  color: teamColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.sp),
          // 팀 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team['name'] as String,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.sp),
                Text(
                  'ACE: ${team['ace']}',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          // 선수 수
          Text(
            '${_teamRoster.length}명',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRosterList(Color teamColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 12.sp),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7.sp)),
            ),
            child: Row(
              children: [
                Text(
                  'ROSTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_teamRoster.length}명',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // 선수 리스트
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 4.sp),
              itemCount: _teamRoster.length,
              itemBuilder: (context, index) {
                final player = _teamRoster[index];
                final isFocused = index == focusedPlayerIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      focusedPlayerIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(
                      horizontal: 4.sp,
                      vertical: 2.sp,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.sp,
                      vertical: 8.sp,
                    ),
                    decoration: BoxDecoration(
                      color: isFocused
                          ? teamColor.withValues(alpha: 0.3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4.sp),
                      border: isFocused
                          ? Border.all(color: teamColor, width: 2)
                          : null,
                    ),
                    child: Row(
                      children: [
                        // 종족 아이콘
                        Container(
                          width: 24.sp,
                          height: 24.sp,
                          decoration: BoxDecoration(
                            color: _getRaceColor(player.race).withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              player.race.code,
                              style: TextStyle(
                                color: _getRaceColor(player.race),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.sp),

                        // 선수 이름
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.name,
                                style: TextStyle(
                                  color: isFocused ? Colors.white : Colors.grey[300],
                                  fontSize: 13.sp,
                                  fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (player.nickname != null)
                                Text(
                                  player.nickname!,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 10.sp,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),

                        // 등급
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.sp,
                            vertical: 2.sp,
                          ),
                          decoration: BoxDecoration(
                            color: _getGradeColor(player.grade).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4.sp),
                          ),
                          child: Text(
                            player.grade.display,
                            style: TextStyle(
                              color: _getGradeColor(player.grade),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo(Color teamColor) {
    if (_teamRoster.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: teamColor, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.sp),
        child: _buildRadarChart(teamColor),
      ),
    );
  }

  Widget _buildRadarChart(Color teamColor) {
    final player = _teamRoster[focusedPlayerIndex];

    return PlayerRadarChart(
      stats: player.stats,
      color: AppTheme.getGradeColor(player.grade.display),
      grade: player.grade.display,
      level: player.levelValue,
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1행: New Season + Load
          Row(
            children: [
              // New Season Mode 버튼
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 48.sp,
                  child: ElevatedButton(
                    onPressed: selectedTeamId == null
                        ? null
                        : () async {
                            await ref.read(gameStateProvider.notifier).startNewGame(
                              slotNumber: 1,
                              selectedTeamId: selectedTeamId!,
                            );
                            if (mounted) {
                              context.go('/director-name');
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedTeamId != null
                          ? Colors.amber
                          : Colors.grey[700],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20.sp),
                          SizedBox(width: 4.sp),
                          Text(
                            'New Season',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.sp),

              // Load 버튼
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 48.sp,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/save-load');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2a2a3e),
                      foregroundColor: Colors.white70,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open, size: 18.sp),
                          SizedBox(width: 4.sp),
                          Text(
                            'Load',
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.sp),

          // 2행: 설정 버튼
          SizedBox(
            width: double.infinity,
            height: 36.sp,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/settings'),
              icon: Icon(Icons.settings, size: 16.sp),
              label: Text(
                '설정',
                style: TextStyle(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2a2a3e),
                foregroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4.sp),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Color _getGradeColor(Grade grade) {
    if (grade.index >= Grade.sss.index) return Colors.red;
    if (grade.index >= Grade.ss.index) return Colors.orange;
    if (grade.index >= Grade.s.index) return Colors.amber;
    if (grade.index >= Grade.a.index) return Colors.green;
    if (grade.index >= Grade.b.index) return Colors.blue;
    if (grade.index >= Grade.c.index) return Colors.cyan;
    return Colors.grey;
  }
}

