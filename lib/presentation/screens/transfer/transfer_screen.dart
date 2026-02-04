import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/constants/initial_data.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';

/// 이적 화면 (선수 영입)
class TransferScreen extends ConsumerStatefulWidget {
  final bool isInitialRecruit;

  const TransferScreen({
    super.key,
    this.isInitialRecruit = false,
  });

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  String? _selectedMyPlayerId;
  String? _selectedTargetPlayerId;
  String _selectedSourceId = 'free_agent'; // 기본값: 무소속

  // 영입된 선수 목록 (프리뷰 모드용)
  final List<Player> _recruitedPlayers = [];

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final gameState = ref.watch(gameStateProvider);

    // 테스트용: gameState가 없을 때 플레이스홀더 데이터 사용
    final isPreviewMode = gameState == null;
    final allTeams = isPreviewMode ? InitialData.createTeams() : gameState.saveData.allTeams;
    final playerTeam = isPreviewMode ? allTeams.first : gameState.playerTeam;
    final baseMyPlayers = isPreviewMode
        ? InitialData.createPlayers().where((p) => p.teamId == playerTeam.id).toList()
        : gameState.playerTeamPlayers;
    // 영입된 선수 추가
    final myPlayers = [...baseMyPlayers, ..._recruitedPlayers];

    final baseFreeAgents = isPreviewMode
        ? InitialData.createFreeAgentPool()
        : gameState.saveData.freeAgentPool;
    // 영입된 선수 제외
    final freeAgents = baseFreeAgents
        .where((p) => !_recruitedPlayers.any((r) => r.id == p.id))
        .toList();

    // 선택된 소스에 따른 타겟 선수 목록
    List<Player> targetPlayers;
    final isMyTeamSelected = _selectedSourceId == 'my_team';

    if (_selectedSourceId == 'free_agent') {
      targetPlayers = freeAgents;
    } else if (isMyTeamSelected) {
      // 우리팀 선택 시 - 방출용
      targetPlayers = myPlayers;
    } else if (isPreviewMode) {
      targetPlayers = InitialData.createPlayers()
          .where((p) => p.teamId == _selectedSourceId)
          .where((p) => !_recruitedPlayers.any((r) => r.id == p.id))
          .toList();
    } else {
      targetPlayers = gameState.saveData.getTeamPlayers(_selectedSourceId)
          .where((p) => !_recruitedPlayers.any((r) => r.id == p.id))
          .toList();
    }

    // 선택된 타겟 선수
    Player? selectedTargetPlayer;
    if (_selectedTargetPlayerId != null) {
      selectedTargetPlayer = targetPlayers.cast<Player?>().firstWhere(
        (p) => p?.id == _selectedTargetPlayerId,
        orElse: () => null,
      );
    }

    // 영입 가능 여부
    final canRecruit = selectedTargetPlayer != null &&
        playerTeam.money >= selectedTargetPlayer.transferFee;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a12),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(context, playerTeam),

                // 메인 컨텐츠
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: Row(
                      children: [
                        // 좌측: 내 팀 선수 목록
                        Expanded(
                          flex: 2,
                          child: _buildMyTeamPanel(myPlayers),
                        ),

                        SizedBox(width: 12.sp),

                        // 중앙: 선수 수 / 보유 금액 / 요구 금액
                        SizedBox(
                          width: 120.sp,
                          child: _buildInfoPanel(
                            playerTeam,
                            myPlayers.length,
                            selectedTargetPlayer,
                            isMyTeamSelected,
                          ),
                        ),

                        SizedBox(width: 12.sp),

                        // 타겟 선수 목록
                        Expanded(
                          flex: 2,
                          child: _buildTargetPanel(targetPlayers),
                        ),

                        SizedBox(width: 12.sp),

                        // 선택된 선수 상세 정보
                        Expanded(
                          flex: 3,
                          child: _buildSelectedPlayerPanel(
                            selectedTargetPlayer,
                            playerTeam,
                            isMyTeamSelected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context, canRecruit, allTeams, playerTeam),
                SizedBox(height: 8.sp),
              ],
            ),

            // R 버튼 (왼쪽 상단)
            Positioned(
              left: 12.sp,
              top: 12.sp,
              child: _buildRButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRButton() {
    return Container(
      width: 36.sp,
      height: 36.sp,
      decoration: BoxDecoration(
        color: Colors.red[800],
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.red[400]!, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6.sp),
          onTap: () => context.go('/'),
          child: Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        border: Border(
          bottom: BorderSide(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(width: 50.sp), // R 버튼 공간

          // 팀 로고
          Container(
            width: 70.sp,
            height: 45.sp,
            decoration: BoxDecoration(
              color: Color(team.colorValue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.sp),
              border: Border.all(color: Color(team.colorValue), width: 2),
            ),
            child: Center(
              child: Text(
                team.shortName,
                style: TextStyle(
                  color: Color(team.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),

          const Spacer(),

          // 타이틀
          Text(
            '선 수   영 입',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),

          const Spacer(),

          // MY STARCRAFT 로고
          Column(
            children: [
              Text(
                'MY',
                style: TextStyle(
                  color: Colors.red[400],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
              ),
              Text(
                'STARCRAFT',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamPanel(List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.vertical(top: Radius.circular(6.sp)),
            ),
            child: Column(
              children: [
                Text(
                  'MY TEAM',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  'PLAYER',
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 10.sp,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
                  showGrade: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPanel(List<Player> players) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.vertical(top: Radius.circular(6.sp)),
            ),
            child: Text(
              _selectedSourceId == 'free_agent'
                  ? '무소속 선수'
                  : (_selectedSourceId == 'my_team' ? '우리팀 선수' : '상대팀 선수'),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 선수 목록
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(4.sp),
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isSelected = _selectedTargetPlayerId == player.id;
                return _buildPlayerListItem(
                  player,
                  isSelected,
                  () => setState(() {
                    _selectedTargetPlayerId = isSelected ? null : player.id;
                  }),
                  showGrade: true,
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
    VoidCallback onTap, {
    bool showGrade = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 5.sp),
        margin: EdgeInsets.only(bottom: 2.sp),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(4.sp),
          border: isSelected ? Border.all(color: Colors.amber, width: 1) : null,
        ),
        child: Row(
          children: [
            if (isSelected)
              Icon(Icons.check, size: 12.sp, color: Colors.amber[800]),
            if (isSelected) SizedBox(width: 4.sp),
            Expanded(
              child: Text(
                player.name,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (showGrade) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 1.sp),
                decoration: BoxDecoration(
                  color: _getGradeColor(player.grade).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2.sp),
                ),
                child: Text(
                  player.grade.display,
                  style: TextStyle(
                    fontSize: 8.sp,
                    color: _getGradeColor(player.grade),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 4.sp),
            ],
            Text(
              '(${player.race.code})',
              style: TextStyle(
                fontSize: 10.sp,
                color: _getRaceColor(player.race),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel(Team team, int playerCount, Player? selectedPlayer, bool isRelease) {
    final requiredMoney = selectedPlayer?.transferFee ?? 0;
    final releasePrice = selectedPlayer != null ? (selectedPlayer.transferFee * 0.5).round() : 0;
    final canAfford = team.money >= requiredMoney;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '선수 수',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            '$playerCount / 20',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 20.sp),

          Text(
            '보유 금액',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            '${team.money}',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '만원',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11.sp,
            ),
          ),

          SizedBox(height: 20.sp),

          Text(
            isRelease ? '방출 금액' : '요구 금액',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            selectedPlayer != null
                ? (isRelease ? '+$releasePrice' : '$requiredMoney')
                : '-',
            style: TextStyle(
              color: selectedPlayer != null
                  ? (isRelease ? Colors.green : (canAfford ? Colors.green : Colors.red))
                  : Colors.grey,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '만원',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlayerPanel(Player? player, Team playerTeam, bool isRelease) {
    if (player == null) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: BorderRadius.circular(6.sp),
          border: Border.all(color: Colors.grey[700]!, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 60.sp,
              color: Colors.grey[700],
            ),
            SizedBox(height: 12.sp),
            Text(
              '선수를 선택해주세요',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    final canAfford = playerTeam.money >= player.transferFee;
    // 방출 시 받는 금액 (몸값의 50%)
    final releasePrice = (player.transferFee * 0.5).round();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Column(
        children: [
          // 선수 정보 헤더
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              color: _getRaceColor(player.race).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(5.sp)),
            ),
            child: Row(
              children: [
                // 선수 사진 (placeholder)
                Container(
                  width: 60.sp,
                  height: 70.sp,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(color: _getRaceColor(player.race), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person, color: Colors.grey[600], size: 30.sp),
                      Text(
                        '0 승',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.sp),

                // 선수 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            player.name,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.sp,
                              vertical: 2.sp,
                            ),
                            decoration: BoxDecoration(
                              color: _getRaceColor(player.race).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4.sp),
                            ),
                            child: Text(
                              player.race.code,
                              style: TextStyle(
                                color: _getRaceColor(player.race),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.sp),
                      if (player.nickname != null)
                        Text(
                          'ID: ${player.nickname}',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12.sp,
                          ),
                        ),
                      SizedBox(height: 4.sp),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.sp,
                              vertical: 2.sp,
                            ),
                            decoration: BoxDecoration(
                              color: _getGradeColor(player.grade).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4.sp),
                              border: Border.all(
                                color: _getGradeColor(player.grade),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              player.grade.display,
                              style: TextStyle(
                                color: _getGradeColor(player.grade),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Text(
                            'Lv.${player.levelValue}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 레이더 차트 + 스탯
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.sp),
              child: Row(
                children: [
                  // 레이더 차트
                  Expanded(
                    child: _buildRadarChart(player),
                  ),

                  // 스탯 리스트
                  Expanded(
                    child: _buildStatsList(player),
                  ),
                ],
              ),
            ),
          ),

          // 컨디션 + 영입 버튼
          Container(
            padding: EdgeInsets.all(12.sp),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[700]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Condition  ${player.displayCondition} %',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12.sp,
                  ),
                ),

                // 방출 또는 영입 버튼
                if (isRelease)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // 방출: 영입된 선수 목록에서 제거
                        _recruitedPlayers.removeWhere((p) => p.id == player.id);
                        _selectedTargetPlayerId = null;
                      });
                      _showMessage('${player.name} 선수를 방출했습니다! (+$releasePrice 만원)');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 8.sp,
                      ),
                    ),
                    child: Text(
                      '방출',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (canAfford)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // 영입된 선수를 내 팀에 추가
                        _recruitedPlayers.add(player.copyWith(teamId: 'my_team'));
                        _selectedTargetPlayerId = null;
                      });
                      _showMessage('${player.name} 선수를 영입했습니다!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.sp,
                        vertical: 8.sp,
                      ),
                    ),
                    child: Text(
                      '영입',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '금액 부족',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: 12.sp,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Player player) {
    final stats = player.stats;
    final statValues = [
      stats.sense / 999.0,
      stats.control / 999.0,
      stats.attack / 999.0,
      stats.harass / 999.0,
      stats.strategy / 999.0,
      stats.macro / 999.0,
      stats.defense / 999.0,
      stats.scout / 999.0,
    ];
    final labels = ['센스', '컨트롤', '공격력', '견제', '전략', '물량', '수비력', '정찰'];

    return CustomPaint(
      painter: RadarChartPainter(
        stats: statValues,
        labels: labels,
        color: _getRaceColor(player.race),
      ),
      child: Container(),
    );
  }

  Widget _buildStatsList(Player player) {
    final stats = player.stats;
    final statData = [
      {'name': '센스', 'value': stats.sense},
      {'name': '컨트롤', 'value': stats.control},
      {'name': '공격력', 'value': stats.attack},
      {'name': '견제', 'value': stats.harass},
      {'name': '전략', 'value': stats.strategy},
      {'name': '물량', 'value': stats.macro},
      {'name': '수비력', 'value': stats.defense},
      {'name': '정찰', 'value': stats.scout},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: statData.map((stat) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.sp),
          child: Row(
            children: [
              SizedBox(
                width: 45.sp,
                child: Text(
                  stat['name'] as String,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 10.sp,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 6.sp,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(3.sp),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (stat['value'] as int) / 999.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(3.sp),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.sp),
              SizedBox(
                width: 30.sp,
                child: Text(
                  '${stat['value']}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    bool canRecruit,
    List<Team> allTeams,
    Team playerTeam,
  ) {
    // 선택 가능한 팀 목록 (무소속 + 다른 팀들)
    final selectableTeams = allTeams.where((t) => t.id != playerTeam.id).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Next 버튼
          ElevatedButton(
            onPressed: widget.isInitialRecruit
                ? () => context.go('/main')
                : () => context.go('/main'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2a2a3e),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 40.sp, vertical: 12.sp),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.sp),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Next [Bar]',
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(width: 8.sp),
                Icon(Icons.play_arrow, size: 16.sp),
                Icon(Icons.play_arrow, size: 16.sp),
              ],
            ),
          ),

          SizedBox(width: 24.sp),

          // 팀/무소속 선택 드롭다운
          Container(
            width: 220.sp,
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a3e),
              borderRadius: BorderRadius.circular(4.sp),
              border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSourceId,
                isExpanded: true,
                dropdownColor: const Color(0xFF2a2a3e),
                icon: Icon(Icons.arrow_drop_down, color: Colors.amber, size: 28.sp),
                items: [
                  DropdownMenuItem(
                    value: 'free_agent',
                    child: Text(
                      '무소속',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'my_team',
                    child: Text(
                      '우리팀',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...selectableTeams.map((team) => DropdownMenuItem(
                    value: team.id,
                    child: Text(
                      team.name,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                      ),
                    ),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSourceId = value ?? 'free_agent';
                    _selectedTargetPlayerId = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

/// 8각형 레이더 차트 페인터
class RadarChartPainter extends CustomPainter {
  final List<double> stats;
  final List<String> labels;
  final Color color;

  RadarChartPainter({
    required this.stats,
    required this.labels,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;
    final sides = stats.length;

    // 배경 그리드
    final gridPaint = Paint()
      ..color = Colors.grey[700]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var level = 1; level <= 5; level++) {
      final levelRadius = radius * level / 5;
      final path = Path();
      for (var i = 0; i < sides; i++) {
        final angle = (i * 2 * pi / sides) - pi / 2;
        final point = Offset(
          center.dx + levelRadius * cos(angle),
          center.dy + levelRadius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 축
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      canvas.drawLine(center, endPoint, gridPaint);
    }

    // 데이터 영역
    final dataPath = Path();
    final dataPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final value = stats[i].clamp(0.0, 1.0);
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
    canvas.drawPath(dataPath, dataStrokePaint);

    // 라벨
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final labelRadius = radius + 12;
      var point = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: Colors.grey[500], fontSize: 9),
      );
      textPainter.layout();

      point = Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, point);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
