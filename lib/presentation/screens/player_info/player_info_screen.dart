import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/reset_button.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';

/// 선수 정보 화면 모드
enum PlayerInfoMode {
  teamInfo, // 팀 정보 (선수 미선택)
  teamVsRecord, // 팀별 상대전적
  playerDetail, // 선수 상세
  playerVsRecord, // 선수별 상대전적
}

/// 선수 정보 화면
class PlayerInfoScreen extends ConsumerStatefulWidget {
  final String? initialTeamId; // 초기 표시할 팀 ID
  final bool isOtherTeam; // 상대 팀 조회 모드

  const PlayerInfoScreen({
    super.key,
    this.initialTeamId,
    this.isOtherTeam = false,
  });

  @override
  ConsumerState<PlayerInfoScreen> createState() => _PlayerInfoScreenState();
}

class _PlayerInfoScreenState extends ConsumerState<PlayerInfoScreen> {
  late String _selectedTeamId;
  String? _selectedPlayerId;
  PlayerInfoMode _mode = PlayerInfoMode.teamInfo;

  @override
  void initState() {
    super.initState();
    // 키보드 리스너 설정
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final gameState = ref.read(gameStateProvider);
      if (gameState == null) return false;

      final players = gameState.saveData.getTeamPlayers(_selectedTeamId);
      final currentIndex = _selectedPlayerId != null
          ? players.indexWhere((p) => p.id == _selectedPlayerId)
          : -1;

      if (event.logicalKey == LogicalKeyboardKey.pageUp) {
        // 선수 순서 위로
        if (currentIndex > 0) {
          setState(() {
            _selectedPlayerId = players[currentIndex - 1].id;
          });
        }
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.pageDown) {
        // 선수 순서 아래로
        if (currentIndex < players.length - 1 && currentIndex >= 0) {
          setState(() {
            _selectedPlayerId = players[currentIndex + 1].id;
          });
        }
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 초기 팀 설정
    _selectedTeamId = widget.initialTeamId ?? gameState.playerTeam.id;

    final selectedTeam = gameState.saveData.getTeamById(_selectedTeamId);
    final players = gameState.saveData.getTeamPlayers(_selectedTeamId);
    final selectedPlayer = _selectedPlayerId != null
        ? players.where((p) => p.id == _selectedPlayerId).firstOrNull
        : null;

    if (selectedTeam == null) {
      return const Scaffold(body: Center(child: Text('팀을 찾을 수 없습니다')));
    }

    Responsive.init(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(selectedTeam, gameState),

                // 메인 컨텐츠
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 좌측: 팀 이미지 또는 선수 상세
                      Expanded(
                        flex: 2,
                        child: _buildLeftPanel(selectedTeam, selectedPlayer),
                      ),

                      // 중앙: 선수 목록
                      Expanded(
                        flex: 1,
                        child: _buildPlayerList(players),
                      ),

                      // 우측: 팀 정보 또는 선수 전적
                      Expanded(
                        flex: 2,
                        child: _buildRightPanel(selectedTeam, selectedPlayer, gameState),
                      ),
                    ],
                  ),
                ),

                // 하단 버튼
                _buildBottomButtons(context, gameState),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Team team, GameState gameState) {
    final playerTeam = gameState.playerTeam;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // 좌측 팀 로고
          _buildTeamLogo(playerTeam),

          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    '선수 정보',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    team.name,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // SETTING 배너
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4.sp),
              border: Border.all(color: Colors.amber),
            ),
            child: Text(
              'SETTING',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 50.sp,
      height: 35.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Center(
        child: Text(
          team.shortName,
          style: TextStyle(
            color: Color(team.colorValue),
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(Team team, Player? selectedPlayer) {
    if (selectedPlayer == null) {
      // 팀 이미지 (선수 미선택)
      return Container(
        margin: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isOtherTeam ? Icons.groups : Icons.person,
                size: 80.sp,
                color: Colors.grey,
              ),
              SizedBox(height: 16.sp),
              Text(
                widget.isOtherTeam ? 'OTHER TEAM PLAYER' : 'MY TEAM PLAYER',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 선수 상세 정보
    return _buildPlayerDetailPanel(selectedPlayer);
  }

  Widget _buildPlayerDetailPanel(Player player) {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        children: [
          // 상단: 연패/시즌 전적
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                player.record.currentWinStreak > 0
                    ? '${player.record.currentWinStreak}연승 중'
                    : player.record.currentWinStreak < 0
                        ? '${-player.record.currentWinStreak}연패 중'
                        : '',
                style: TextStyle(
                  color: player.record.currentWinStreak > 0 ? Colors.green : Colors.red,
                  fontSize: 11.sp,
                ),
              ),
              Text(
                '이번 시즌 ${player.record.wins}W ${player.record.losses}L',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.sp),

          // 선수 사진 (실루엣)
          Container(
            width: 80.sp,
            height: 80.sp,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Icon(
              Icons.person,
              size: 50.sp,
              color: Colors.grey[600],
            ),
          ),

          SizedBox(height: 12.sp),

          // 종족 + 선수명
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24.sp,
                height: 24.sp,
                decoration: BoxDecoration(
                  color: _getRaceColor(player.race).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Center(
                  child: Text(
                    player.race.code,
                    style: TextStyle(
                      color: _getRaceColor(player.race),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              Text(
                '${player.name} (${player.race.code})',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.sp),

          // 8각형 레이더 차트
          Expanded(
            child: _buildRadarChart(player),
          ),

          SizedBox(height: 12.sp),

          // 등급 + 레벨
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
                decoration: BoxDecoration(
                  color: _getGradeColor(player.grade),
                  borderRadius: BorderRadius.circular(4.sp),
                ),
                child: Text(
                  player.grade.display,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.sp),
              Text(
                'Lv.${player.level.value}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.sp),

          // 컨디션
          Text(
            'Condition ${player.displayCondition}%',
            style: TextStyle(
              color: _getConditionColor(player.displayCondition),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart(Player player) {
    return CustomPaint(
      painter: _RadarChartPainter(
        stats: player.stats,
        raceColor: _getRaceColor(player.race),
      ),
      size: Size.infinite,
    );
  }

  Widget _buildPlayerList(List<Player> players) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(8.sp),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
            child: Text(
              '선수들',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12.sp,
              ),
            ),
          ),

          // 선수 목록
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                final isSelected = player.id == _selectedPlayerId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPlayerId = player.id;
                      _mode = PlayerInfoMode.playerDetail;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 6.sp),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.3) : null,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          player.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 4.sp),
                        Text(
                          '(${player.race.code})',
                          style: TextStyle(
                            color: _getRaceColor(player.race),
                            fontSize: 10.sp,
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

  Widget _buildRightPanel(Team team, Player? selectedPlayer, GameState gameState) {
    if (selectedPlayer == null || _mode == PlayerInfoMode.teamInfo) {
      return _buildTeamInfoPanel(team, gameState);
    }

    if (_mode == PlayerInfoMode.teamVsRecord) {
      return _buildTeamVsRecordPanel(team, gameState);
    }

    if (_mode == PlayerInfoMode.playerVsRecord) {
      return _buildPlayerVsRecordPanel(selectedPlayer);
    }

    return _buildPlayerRecordPanel(selectedPlayer);
  }

  Widget _buildTeamInfoPanel(Team team, GameState gameState) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = PlayerInfoMode.teamVsRecord;
        });
      },
      child: Container(
        margin: EdgeInsets.all(16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 팀명
            Center(
              child: Text(
                '「 ${team.name} 」',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 24.sp),

            // 프로리그 우승/준우승
            _buildRecordRow('프로리그', team.record.proleagueChampionships, team.record.proleagueRunnerUps),

            SizedBox(height: 8.sp),

            // 개인리그 우승/준우승 (팀 소속 선수 합계)
            _buildRecordRow('개인리그', 0, 0), // TODO: 실제 데이터

            Divider(color: Colors.grey.withOpacity(0.3), height: 32.sp),

            // 전체 시즌 성적
            Text(
              '전체 시즌 성적',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 4.sp),
            _buildWinLossRow(team.record.wins, team.record.losses),
            Text(
              'Set Score: ${team.record.setWins} W ${team.record.setLosses} L (${_calcWinRate(team.record.setWins, team.record.setLosses)}%)',
              style: TextStyle(color: Colors.grey, fontSize: 10.sp),
            ),

            Divider(color: Colors.grey.withOpacity(0.3), height: 32.sp),

            // 이번 시즌 전적
            Text(
              '이번 시즌 전적',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 4.sp),
            _buildWinLossRow(team.seasonRecord.wins, team.seasonRecord.losses),
            Text(
              'Set Score: ${team.seasonRecord.setWins} W ${team.seasonRecord.setLosses} L (${_calcWinRate(team.seasonRecord.setWins, team.seasonRecord.setLosses)}%)',
              style: TextStyle(color: Colors.grey, fontSize: 10.sp),
            ),

            const Spacer(),

            Center(
              child: Text(
                '클릭하여 팀별 상대전적 보기',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordRow(String label, int championships, int runnerUps) {
    return Row(
      children: [
        SizedBox(
          width: 60.sp,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: 11.sp),
          ),
        ),
        Text('우승 ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
        Text(
          '$championships',
          style: TextStyle(
            color: championships > 0 ? Colors.amber : Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(' 회  준우승 ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
        Text(
          '$runnerUps',
          style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        Text(' 회', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
      ],
    );
  }

  Widget _buildWinLossRow(int wins, int losses) {
    return Row(
      children: [
        Text(
          '$wins',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(' W  ', style: TextStyle(color: AppColors.accent, fontSize: 12.sp)),
        Text(
          '$losses',
          style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        Text(' L  ', style: TextStyle(color: Colors.red, fontSize: 12.sp)),
        Text(
          '(${_calcWinRate(wins, losses)}%)',
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
      ],
    );
  }

  String _calcWinRate(int wins, int losses) {
    if (wins + losses == 0) return '0';
    return ((wins / (wins + losses)) * 100).toStringAsFixed(0);
  }

  Widget _buildTeamVsRecordPanel(Team team, GameState gameState) {
    final allTeams = gameState.saveData.allTeams.where((t) => t.id != team.id).toList();

    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = PlayerInfoMode.teamInfo;
        });
      },
      child: Container(
        margin: EdgeInsets.all(16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '팀별 상대전적 조회',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.sp),
            Expanded(
              child: ListView.builder(
                itemCount: allTeams.length,
                itemBuilder: (context, index) {
                  final opponent = allTeams[index];
                  // TODO: 실제 상대전적 데이터
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.sp),
                    child: Row(
                      children: [
                        Text('vs ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
                        Expanded(
                          child: Text(
                            opponent.name,
                            style: TextStyle(color: Colors.white, fontSize: 11.sp),
                          ),
                        ),
                        Text(
                          '0전 0승 0패 (0%)',
                          style: TextStyle(color: Colors.grey, fontSize: 10.sp),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerRecordPanel(Player player) {
    final record = player.record;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = PlayerInfoMode.playerVsRecord;
        });
      },
      child: Container(
        margin: EdgeInsets.all(16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 종족 아이콘 + 현재
            Row(
              children: [
                Text('현재 ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
                Container(
                  width: 20.sp,
                  height: 20.sp,
                  decoration: BoxDecoration(
                    color: _getRaceColor(player.race).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2.sp),
                  ),
                  child: Center(
                    child: Text(
                      player.race.code,
                      style: TextStyle(
                        color: _getRaceColor(player.race),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.sp),

            // 총 전적
            _buildPlayerStatRow('총 전적:', record.wins, record.losses),

            SizedBox(height: 8.sp),

            // vs Terran
            _buildPlayerStatRow('vs Terran:', record.vsTerranWins, record.vsTerranLosses),

            // vs Zerg
            _buildPlayerStatRow('vs Zerg:', record.vsZergWins, record.vsZergLosses),

            // vs Protoss
            _buildPlayerStatRow('vs Protoss:', record.vsProtossWins, record.vsProtossLosses),

            SizedBox(height: 12.sp),

            // 우승/준우승
            Row(
              children: [
                Text('우승 ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
                Text(
                  '${record.championships}',
                  style: TextStyle(color: Colors.amber, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                Text(' 회    준우승 ', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
                Text(
                  '${record.runnerUps}',
                  style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
                Text(' 회', style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
              ],
            ),

            Divider(color: Colors.grey.withOpacity(0.3), height: 24.sp),

            // 연승 정보
            Text(
              record.currentWinStreak > 0
                  ? '${record.currentWinStreak} 연승 중'
                  : record.currentWinStreak < 0
                      ? '${-record.currentWinStreak} 연패 중'
                      : '0 연승 중',
              style: TextStyle(
                color: record.currentWinStreak > 0 ? Colors.green : Colors.red,
                fontSize: 12.sp,
              ),
            ),

            const Spacer(),

            Center(
              child: Text(
                '클릭하여 선수별 상대전적 보기',
                style: TextStyle(color: Colors.grey, fontSize: 10.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStatRow(String label, int wins, int losses) {
    final total = wins + losses;
    final rate = total > 0 ? ((wins / total) * 100).toStringAsFixed(0) : '0';

    return Padding(
      padding: EdgeInsets.only(bottom: 4.sp),
      child: Row(
        children: [
          SizedBox(
            width: 80.sp,
            child: Text(label, style: TextStyle(color: Colors.grey, fontSize: 11.sp)),
          ),
          Text(
            '$wins',
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
          Text(' W ', style: TextStyle(color: AppColors.accent, fontSize: 10.sp)),
          Text(
            '$losses',
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
          Text(' L ', style: TextStyle(color: Colors.red, fontSize: 10.sp)),
          Text(
            '($rate%)',
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerVsRecordPanel(Player player) {
    // TODO: 실제 상대전적 데이터
    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = PlayerInfoMode.playerDetail;
        });
      },
      child: Container(
        margin: EdgeInsets.all(16.sp),
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(8.sp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '상대 전적 조회',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.sp),
            Expanded(
              child: Center(
                child: Text(
                  '상대 전적 데이터 없음',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, GameState gameState) {
    final allTeams = gameState.saveData.allTeams;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          // 팀 선택 드롭다운
          Container(
            width: 180.sp,
            padding: EdgeInsets.symmetric(horizontal: 8.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: DropdownButton<String>(
              value: _selectedTeamId,
              isExpanded: true,
              underline: const SizedBox(),
              items: allTeams.map((team) {
                return DropdownMenuItem(
                  value: team.id,
                  child: Text(team.name, style: TextStyle(fontSize: 12.sp)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedTeamId = value;
                    _selectedPlayerId = null;
                    _mode = PlayerInfoMode.teamInfo;
                  });
                }
              },
            ),
          ),

          SizedBox(width: 16.sp),

          // EXIT 버튼
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
            ),
            child: Row(
              children: [
                Icon(Icons.arrow_left, color: Colors.white, size: 14.sp),
                Icon(Icons.arrow_left, color: Colors.white, size: 14.sp),
                SizedBox(width: 4.sp),
                Text('EXIT [Bar]', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
              ],
            ),
          ),

          const Spacer(),

          // 연습경기 버튼 (내 팀일 때만)
          if (!widget.isOtherTeam)
            ElevatedButton(
              onPressed: () => context.go('/practice-match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
              ),
              child: Text('연습경기 [Z]', style: TextStyle(color: Colors.white, fontSize: 11.sp)),
            ),

          SizedBox(width: 8.sp),

          // 선수순위 버튼
          ElevatedButton(
            onPressed: () => context.go('/player-ranking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
            ),
            child: Text('선수순위 [X]', style: TextStyle(color: Colors.white, fontSize: 11.sp)),
          ),

          SizedBox(width: 8.sp),

          // 구단순위 버튼
          ElevatedButton(
            onPressed: () => context.go('/team-ranking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardBackground,
              padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
            ),
            child: Text('구단순위 [C]', style: TextStyle(color: Colors.white, fontSize: 11.sp)),
          ),
        ],
      ),
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

  Color _getGradeColor(Grade grade) {
    switch (grade) {
      case Grade.sss:
      case Grade.ssPlus:
      case Grade.ss:
      case Grade.ssMinus:
      case Grade.sPlus:
      case Grade.s:
      case Grade.sMinus:
        return Colors.amber;
      case Grade.aPlus:
      case Grade.a:
      case Grade.aMinus:
        return Colors.orange;
      case Grade.bPlus:
      case Grade.b:
      case Grade.bMinus:
        return Colors.green;
      case Grade.cPlus:
      case Grade.c:
      case Grade.cMinus:
        return Colors.teal;
      case Grade.dPlus:
      case Grade.d:
      case Grade.dMinus:
        return Colors.blue;
      case Grade.ePlus:
      case Grade.e:
      case Grade.eMinus:
      case Grade.fPlus:
      case Grade.f:
      case Grade.fMinus:
        return Colors.grey;
    }
  }

  Color _getConditionColor(int condition) {
    if (condition >= 80) return Colors.green;
    if (condition >= 50) return Colors.orange;
    return Colors.red;
  }
}

/// 8각형 레이더 차트 페인터
class _RadarChartPainter extends CustomPainter {
  final PlayerStats stats;
  final Color raceColor;

  _RadarChartPainter({
    required this.stats,
    required this.raceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // 8각형 그리드
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 외곽선
    for (var i = 1; i <= 3; i++) {
      final r = radius * i / 3;
      _drawOctagon(canvas, center, r, gridPaint);
    }

    // 축선
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, gridPaint);
    }

    // 데이터 영역
    final dataPaint = Paint()
      ..color = raceColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final dataStrokePaint = Paint()
      ..color = raceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final radarData = stats.toRadarData();
    final path = Path();

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final value = radarData[i];
      final r = radius * value;
      final point = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, dataPaint);
    canvas.drawPath(path, dataStrokePaint);

    // 라벨
    final labels = ['센스', '컨트롤', '공격력', '견제', '전략', '물량', '수비력', '정찰'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final labelRadius = radius + 15;
      final labelPoint = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(color: Colors.grey, fontSize: 9),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - textPainter.width / 2,
          labelPoint.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
