import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 연습경기 화면
class PracticeMatchScreen extends ConsumerStatefulWidget {
  const PracticeMatchScreen({super.key});

  @override
  ConsumerState<PracticeMatchScreen> createState() => _PracticeMatchScreenState();
}

class _PracticeMatchScreenState extends ConsumerState<PracticeMatchScreen> {
  String? _selectedMyPlayerId;
  String? _selectedOpponentPlayerId;
  String _selectedMapId = '';
  final bool _isSimulating = false;

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final playerTeam = gameState.playerTeam;
    final myPlayers = gameState.playerTeamPlayers;
    final allPlayers = gameState.saveData.allPlayers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(context, playerTeam),

                // 세팅 이미지 영역
                _buildSettingBanner(),

                // 메인 컨텐츠
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16.sp),
                    child: Row(
                      children: [
                        // 좌측: 내 팀 선수 목록
                        Expanded(
                          flex: 2,
                          child: _buildMyTeamPanel(myPlayers),
                        ),

                        SizedBox(width: 16.sp),

                        // 중앙: VS + 맵 선택
                    Expanded(
                      flex: 2,
                      child: _buildCenterPanel(gameState),
                    ),

                    SizedBox(width: 16.sp),

                    // 우측: 상대 선수 목록
                    Expanded(
                      flex: 2,
                      child: _buildOpponentPanel(allPlayers, playerTeam.id),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            _buildBottomButtons(context),
          ],
            ),
            // R 버튼
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // 좌측 팀 로고
          _buildTeamLogo(team),

          const Spacer(),

          // 타이틀
          Text(
            '연 습   경 기',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),

          const Spacer(),

          // 우측 팀 로고
          _buildTeamLogo(team),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 80.sp,
      height: 50.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: Color(team.colorValue)),
      ),
      child: Center(
        child: Text(
          team.shortName,
          style: TextStyle(
            color: Color(team.colorValue),
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingBanner() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.sp),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // SETTING 배너 이미지 (실제로는 이미지 사용)
          Container(
            width: 200.sp,
            height: 100.sp,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: Colors.grey[600]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SETTING...',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: 8.sp),
                // 프로그레스 바
                Container(
                  width: 150.sp,
                  height: 8.sp,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4.sp),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamPanel(List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Column(
        children: [
          // MY TEAM PLAYER 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            child: Column(
              children: [
                Text(
                  'MY TEAM',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'PLAYER',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // 선수 이미지 (실루엣)
          Container(
            width: 100.sp,
            height: 80.sp,
            margin: EdgeInsets.symmetric(vertical: 8.sp),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: Colors.grey[600],
            ),
          ),
          // 선수 목록
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.sp),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isSelected = _selectedMyPlayerId == player.id;
                return _buildPlayerListItem(
                  player,
                  isSelected,
                  () => setState(() {
                    _selectedMyPlayerId = isSelected ? null : player.id;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterPanel(GameState gameState) {
    final maps = GameMaps.all;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // VS
        Text(
          '< V S >',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16.sp),

        // 맵 선택 드롭다운
        Container(
          width: 200.sp,
          padding: EdgeInsets.symmetric(horizontal: 12.sp),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: DropdownButton<String>(
            value: _selectedMapId.isEmpty ? null : _selectedMapId,
            hint: const Text('맵 선택'),
            isExpanded: true,
            underline: const SizedBox(),
            items: maps.map((map) {
              return DropdownMenuItem(
                value: map.id,
                child: Text(
                  map.name,
                  style: TextStyle(fontSize: 12.sp),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMapId = value ?? '';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOpponentPanel(List<Player> allPlayers, String myTeamId) {
    // 모든 선수 목록 (내 팀 제외 가능, 또는 포함)
    final opponents = allPlayers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Column(
        children: [
          // MY TEAM PLAYER 헤더 (상대방도 동일한 스타일)
          Container(
            padding: EdgeInsets.all(8.sp),
            child: Column(
              children: [
                Text(
                  'MY TEAM',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'PLAYER',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // 선수 이미지 (실루엣)
          Container(
            width: 100.sp,
            height: 80.sp,
            margin: EdgeInsets.symmetric(vertical: 8.sp),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: Colors.grey[600],
            ),
          ),
          // 선수 목록
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.sp),
              itemCount: opponents.length,
              itemBuilder: (context, index) {
                final player = opponents[index];
                final isSelected = _selectedOpponentPlayerId == player.id;
                return _buildPlayerListItem(
                  player,
                  isSelected,
                  () => setState(() {
                    _selectedOpponentPlayerId = isSelected ? null : player.id;
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerListItem(
    Player player,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
        color: isSelected ? AppColors.accent.withOpacity(0.3) : null,
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check, size: 14.sp, color: AppColors.accent),
            SizedBox(width: 4.sp),
            Text(
              player.name,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '(${player.race.code})',
              style: TextStyle(
                fontSize: 10.sp,
                color: _getRaceColor(player.race),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    final canStart = _selectedMyPlayerId != null &&
        _selectedOpponentPlayerId != null &&
        _selectedMapId.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 정보 관리 버튼
          ElevatedButton(
            onPressed: () {
              // TODO: 정보 관리 화면으로 이동
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                Icon(Icons.arrow_left, color: Colors.white, size: 16.sp),
                SizedBox(width: 8.sp),
                Text(
                  '정보 관리',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.check_box_outlined, color: Colors.white, size: 16.sp),
              ],
            ),
          ),

          SizedBox(width: 24.sp),

          // Start 버튼
          ElevatedButton(
            onPressed: canStart ? _startMatch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canStart ? AppColors.primary : Colors.grey,
              padding: EdgeInsets.symmetric(horizontal: 48.sp, vertical: 12.sp),
            ),
            child: Row(
              children: [
                Text(
                  'Start',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.play_arrow, color: Colors.white, size: 16.sp),
                Icon(Icons.play_arrow, color: Colors.white, size: 16.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startMatch() {
    if (_selectedMyPlayerId == null ||
        _selectedOpponentPlayerId == null ||
        _selectedMapId.isEmpty) {
      return;
    }

    // TODO: 경기 시뮬레이션 화면으로 이동
    // 연습경기는 스탯에 영향 없음
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('연습경기를 시작합니다...')),
    );
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
