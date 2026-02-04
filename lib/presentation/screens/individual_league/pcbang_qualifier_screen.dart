import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';

/// PC방 예선 토너먼트 화면
class PcBangQualifierScreen extends ConsumerStatefulWidget {
  final bool viewOnly;

  const PcBangQualifierScreen({super.key, this.viewOnly = false});

  @override
  ConsumerState<PcBangQualifierScreen> createState() =>
      _PcBangQualifierScreenState();
}

class _PcBangQualifierScreenState extends ConsumerState<PcBangQualifierScreen> {
  final IndividualLeagueService _leagueService = IndividualLeagueService();

  int? _selectedGroupIndex;
  bool _isSimulating = false;
  bool _isCompleted = false;
  int _currentRevealingGroup = -1;
  List<String> _qualifiedPlayers = [];
  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bracket = gameState.saveData.currentSeason.individualLeague;
    final playerTeam = gameState.playerTeam;
    final playerMap = {for (var p in gameState.saveData.allPlayers) p.id: p};

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, playerTeam),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 8.sp),
                    child: Column(
                      children: [
                        // 상단: 24개 조 버튼 (가로 스크롤)
                        SizedBox(
                          height: 50.sp,
                          child: _buildGroupButtons(bracket),
                        ),
                        SizedBox(height: 8.sp),
                        // 중앙: 대진표 + 참가 현황 (좌우 분할)
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildCenterPanel(bracket, playerMap, playerTeam),
                              ),
                              SizedBox(width: 8.sp),
                              Expanded(
                                flex: 1,
                                child: _buildRightPanel(bracket, playerMap, playerTeam.id),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomButtons(context, bracket, playerMap, widget.viewOnly),
              ],
            ),
            // R 버튼 (오른쪽 상단)
            Positioned(
              right: 12.sp,
              top: 12.sp,
              child: _buildRButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRButton(BuildContext context) {
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
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          _buildTeamLogo(team),
          const Spacer(),
          Text(
            'PC방 예선 토너먼트',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          _buildTeamLogo(team),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 60.sp,
      height: 40.sp,
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
            fontSize: 12.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupButtons(IndividualLeagueBracket? bracket) {
    final groupCount = bracket?.pcBangGroups.length ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      child: Row(
        children: [
          Text(
            '조 선택',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8.sp),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: groupCount > 0 ? groupCount : 16, // 기본 16조 표시
              itemBuilder: (context, index) {
                final isSelected = _selectedGroupIndex == index;
                final isRevealed = _currentRevealingGroup >= index;
                final hasResult = bracket != null &&
                    _leagueService.getGroupResult(bracket, index) != null;

                // 조 인원 수 표시 (8명/6명)
                final groupSize = bracket != null && bracket.pcBangGroups.length > index
                    ? bracket.pcBangGroups[index].length
                    : 0;

                // 조 편성이 되어있으면 선택 가능 (결과 없어도)
                final canSelect = bracket != null && index < bracket.pcBangGroups.length;

                return GestureDetector(
                  onTap: canSelect
                      ? () => setState(() => _selectedGroupIndex = index)
                      : null,
                  child: Container(
                    width: 48.sp,
                    margin: EdgeInsets.only(right: 4.sp),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.3)
                          : hasResult || isRevealed
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : canSelect
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.grey[800],
                      borderRadius: BorderRadius.circular(4.sp),
                      border: isSelected
                          ? Border.all(color: AppColors.accent, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${index + 1}조',
                          style: TextStyle(
                            color: isSelected || isRevealed
                                ? Colors.white
                                : Colors.grey,
                            fontSize: 11.sp,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (groupSize > 0)
                          Text(
                            '(${groupSize}명)',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 8.sp,
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

  Widget _buildCenterPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    Team playerTeam,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // 팀 로고
          Container(
            width: 100.sp,
            height: 60.sp,
            decoration: BoxDecoration(
              color: Color(playerTeam.colorValue).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.sp),
              border: Border.all(color: Color(playerTeam.colorValue)),
            ),
            child: Center(
              child: Text(
                playerTeam.shortName,
                style: TextStyle(
                  color: Color(playerTeam.colorValue),
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.sp),
          // 상태 메시지 또는 대진표
          Expanded(
            child: _buildCenterContent(bracket, playerMap),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) {
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      return Center(
        child: Text(
          '예선이 진행되지 않았습니다',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16.sp,
          ),
        ),
      );
    }

    if (_isSimulating) {
      final totalGroups = bracket.pcBangGroups.length;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 16.sp),
            Text(
              '경기가 진행중입니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${_currentRevealingGroup + 1} / $totalGroups 조',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 시뮬레이션 완료 후 조 선택 시 → 결과 대진표 표시
    if (_selectedGroupIndex != null && _isCompleted) {
      return _buildGroupBracket(bracket, playerMap, _selectedGroupIndex!);
    }

    // 시뮬레이션 완료 → 완료 메시지
    if (_isCompleted) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: AppColors.accent, size: 48.sp),
            SizedBox(height: 16.sp),
            Text(
              '예선 완료!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '좌측에서 조를 선택하여 대진표를 확인하세요',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    // 조 편성은 되어있지만 시뮬레이션 전 → 조 선택 시 참가자 명단 표시
    if (_selectedGroupIndex != null) {
      return _buildGroupParticipants(bracket, playerMap, _selectedGroupIndex!);
    }

    // 조 편성 완료 상태 → 안내 메시지
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups, color: AppColors.primary, size: 48.sp),
          SizedBox(height: 16.sp),
          Text(
            '조 편성 완료',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            '총 ${bracket.pcBangGroups.length}개 조',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 16.sp),
          Text(
            '조를 선택하여 참가자를 확인하거나\nStart 버튼을 눌러 예선을 시작하세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  /// 시뮬레이션 전 조별 참가자 명단 표시
  Widget _buildGroupParticipants(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    if (groupIndex >= bracket.pcBangGroups.length) {
      return const Center(child: Text('조 정보 없음'));
    }

    final groupPlayers = bracket.pcBangGroups[groupIndex];
    final groupSize = groupPlayers.length;

    return Column(
      children: [
        Text(
          '${groupIndex + 1}조 참가자 ($groupSize명)',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          groupSize == 8 ? '8강 → 4강 → 결승' :
          groupSize == 6 ? '1라운드 → 4강 → 결승' : '4강 → 결승',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12.sp,
          ),
        ),
        SizedBox(height: 16.sp),
        Expanded(
          child: ListView.builder(
            itemCount: groupPlayers.length,
            itemBuilder: (context, index) {
              final playerId = groupPlayers[index];
              final player = playerMap[playerId];
              if (player == null) return const SizedBox();

              // 시드 표시 (8명 조: 1-4시드가 상위)
              final seedLabel = groupSize == 8
                  ? '${index + 1}시드'
                  : groupSize == 6
                      ? (index < 2 ? '시드' : '예선')
                      : '';

              return Container(
                margin: EdgeInsets.symmetric(vertical: 4.sp),
                padding: EdgeInsets.all(12.sp),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8.sp),
                  border: player.teamId == ref.read(gameStateProvider)?.playerTeam.id
                      ? Border.all(color: AppColors.accent, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    if (seedLabel.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                        margin: EdgeInsets.only(right: 8.sp),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4.sp),
                        ),
                        child: Text(
                          seedLabel,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        player.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      player.race.code,
                      style: TextStyle(
                        color: _getRaceColor(player.race),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      player.grade.display,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGroupBracket(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupResult = _leagueService.getGroupResult(bracket, groupIndex);
    if (groupResult == null) {
      return const Center(child: Text('결과 없음'));
    }

    final groupPlayers = bracket.pcBangGroups[groupIndex];

    return Column(
      children: [
        Text(
          '${groupIndex + 1}조 대진표',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.sp),
        // 우승자
        Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.sp),
            border: Border.all(color: AppColors.accent),
          ),
          child: Column(
            children: [
              Text(
                '진출자',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 4.sp),
              Text(
                playerMap[groupResult.winnerId]?.name ?? '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.sp),
        // 토너먼트 대진표
        Expanded(
          child: _buildTournamentTree(groupPlayers, groupResult, playerMap),
        ),
      ],
    );
  }

  Widget _buildTournamentTree(
    List<String> playerIds,
    PcBangGroupResult result,
    Map<String, Player> playerMap,
  ) {
    final groupSize = playerIds.length;

    // 조 인원에 따라 다른 레이아웃
    if (groupSize == 4) {
      return _build4PlayerTree(playerIds, result, playerMap);
    } else if (groupSize == 6) {
      return _build6PlayerTree(playerIds, result, playerMap);
    } else {
      return _build8PlayerTree(playerIds, result, playerMap);
    }
  }

  Widget _build4PlayerTree(
    List<String> playerIds,
    PcBangGroupResult result,
    Map<String, Player> playerMap,
  ) {
    // 4명: 4강 → 결승
    // matches: [SF1, SF2, Final]
    final sf1 = result.matches[0];
    final sf2 = result.matches[1];
    final final_ = result.matches[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 좌측 4강
        _buildMatchBox(
          playerMap[sf1.player1Id]?.name ?? '?',
          playerMap[sf1.player2Id]?.name ?? '?',
          sf1.winnerId == sf1.player1Id,
          playerMap,
        ),
        SizedBox(width: 24.sp),
        // 결승
        _buildMatchBox(
          playerMap[final_.player1Id]?.name ?? '?',
          playerMap[final_.player2Id]?.name ?? '?',
          final_.winnerId == final_.player1Id,
          playerMap,
        ),
        SizedBox(width: 24.sp),
        // 우측 4강
        _buildMatchBox(
          playerMap[sf2.player1Id]?.name ?? '?',
          playerMap[sf2.player2Id]?.name ?? '?',
          sf2.winnerId == sf2.player1Id,
          playerMap,
        ),
      ],
    );
  }

  Widget _build6PlayerTree(
    List<String> playerIds,
    PcBangGroupResult result,
    Map<String, Player> playerMap,
  ) {
    // 6명: 1라운드(2경기) → 4강(2경기) → 결승
    // matches: [R1-1, R1-2, SF1, SF2, Final]
    final r1m1 = result.matches[0];
    final r1m2 = result.matches[1];
    final sf1 = result.matches[2];
    final sf2 = result.matches[3];
    final final_ = result.matches[4];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1라운드
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('1라운드', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[r1m1.player1Id]?.name ?? '?',
                playerMap[r1m1.player2Id]?.name ?? '?',
                r1m1.winnerId == r1m1.player1Id,
                playerMap,
              ),
              SizedBox(height: 8.sp),
              _buildMatchBox(
                playerMap[r1m2.player1Id]?.name ?? '?',
                playerMap[r1m2.player2Id]?.name ?? '?',
                r1m2.winnerId == r1m2.player1Id,
                playerMap,
              ),
            ],
          ),
          SizedBox(width: 16.sp),
          // 4강
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('4강', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[sf1.player1Id]?.name ?? '?',
                playerMap[sf1.player2Id]?.name ?? '?',
                sf1.winnerId == sf1.player1Id,
                playerMap,
              ),
              SizedBox(height: 8.sp),
              _buildMatchBox(
                playerMap[sf2.player1Id]?.name ?? '?',
                playerMap[sf2.player2Id]?.name ?? '?',
                sf2.winnerId == sf2.player1Id,
                playerMap,
              ),
            ],
          ),
          SizedBox(width: 16.sp),
          // 결승
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('결승', style: TextStyle(color: AppColors.accent, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[final_.player1Id]?.name ?? '?',
                playerMap[final_.player2Id]?.name ?? '?',
                final_.winnerId == final_.player1Id,
                playerMap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build8PlayerTree(
    List<String> playerIds,
    PcBangGroupResult result,
    Map<String, Player> playerMap,
  ) {
    // 8명: 8강(4경기) → 4강(2경기) → 결승
    // matches: [QF1, QF2, QF3, QF4, SF1, SF2, Final]
    final qf1 = result.matches[0];
    final qf2 = result.matches[1];
    final qf3 = result.matches[2];
    final qf4 = result.matches[3];
    final sf1 = result.matches[4];
    final sf2 = result.matches[5];
    final final_ = result.matches[6];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 8강
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('8강', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[qf1.player1Id]?.name ?? '?',
                playerMap[qf1.player2Id]?.name ?? '?',
                qf1.winnerId == qf1.player1Id,
                playerMap,
              ),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[qf2.player1Id]?.name ?? '?',
                playerMap[qf2.player2Id]?.name ?? '?',
                qf2.winnerId == qf2.player1Id,
                playerMap,
              ),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[qf3.player1Id]?.name ?? '?',
                playerMap[qf3.player2Id]?.name ?? '?',
                qf3.winnerId == qf3.player1Id,
                playerMap,
              ),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[qf4.player1Id]?.name ?? '?',
                playerMap[qf4.player2Id]?.name ?? '?',
                qf4.winnerId == qf4.player1Id,
                playerMap,
              ),
            ],
          ),
          SizedBox(width: 16.sp),
          // 4강
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('4강', style: TextStyle(color: Colors.grey, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[sf1.player1Id]?.name ?? '?',
                playerMap[sf1.player2Id]?.name ?? '?',
                sf1.winnerId == sf1.player1Id,
                playerMap,
              ),
              SizedBox(height: 8.sp),
              _buildMatchBox(
                playerMap[sf2.player1Id]?.name ?? '?',
                playerMap[sf2.player2Id]?.name ?? '?',
                sf2.winnerId == sf2.player1Id,
                playerMap,
              ),
            ],
          ),
          SizedBox(width: 16.sp),
          // 결승
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('결승', style: TextStyle(color: AppColors.accent, fontSize: 10.sp)),
              SizedBox(height: 4.sp),
              _buildMatchBox(
                playerMap[final_.player1Id]?.name ?? '?',
                playerMap[final_.player2Id]?.name ?? '?',
                final_.winnerId == final_.player1Id,
                playerMap,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBox(
    String player1Name,
    String player2Name,
    bool player1Won,
    Map<String, Player> playerMap,
  ) {
    return Container(
      padding: EdgeInsets.all(8.sp),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color:
                  player1Won ? AppColors.accent.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Text(
              player1Name,
              style: TextStyle(
                color: player1Won ? Colors.white : Colors.grey,
                fontSize: 12.sp,
                fontWeight: player1Won ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          SizedBox(height: 4.sp),
          Text(
            'vs',
            style: TextStyle(color: Colors.grey, fontSize: 10.sp),
          ),
          SizedBox(height: 4.sp),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
            decoration: BoxDecoration(
              color: !player1Won
                  ? AppColors.accent.withOpacity(0.3)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(2.sp),
            ),
            child: Text(
              player2Name,
              style: TextStyle(
                color: !player1Won ? Colors.white : Colors.grey,
                fontSize: 12.sp,
                fontWeight: !player1Won ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCompleted ? '예선 통과자' : '우리팀 참가 현황',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Expanded(
            child: _isCompleted && _qualifiedPlayers.isNotEmpty
                ? _buildQualifiedList(playerMap)
                : _buildMyTeamParticipants(bracket, playerMap, playerTeamId),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTeamParticipants(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      return Center(
        child: Text(
          '참가자 없음',
          style: TextStyle(color: Colors.grey, fontSize: 12.sp),
        ),
      );
    }

    final myTeamParticipants = <MapEntry<int, String>>[];

    for (var i = 0; i < bracket.pcBangGroups.length; i++) {
      for (final playerId in bracket.pcBangGroups[i]) {
        final player = playerMap[playerId];
        if (player != null && player.teamId == playerTeamId) {
          myTeamParticipants.add(MapEntry(i + 1, playerId));
        }
      }
    }

    return ListView.builder(
      itemCount: myTeamParticipants.length,
      itemBuilder: (context, index) {
        final entry = myTeamParticipants[index];
        final player = playerMap[entry.value]!;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  '${entry.key}조',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  color: _getRaceColor(player.race),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualifiedList(Map<String, Player> playerMap) {
    return ListView.builder(
      itemCount: _qualifiedPlayers.length,
      itemBuilder: (context, index) {
        final playerId = _qualifiedPlayers[index];
        final player = playerMap[playerId];
        if (player == null) return const SizedBox();

        return Container(
          padding: EdgeInsets.symmetric(vertical: 4.sp),
          child: Row(
            children: [
              SizedBox(
                width: 30.sp,
                child: Text(
                  '${index + 1}.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  player.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              Text(
                '(${player.race.code})',
                style: TextStyle(
                  color: _getRaceColor(player.race),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomButtons(
    BuildContext context,
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    bool viewOnly,
  ) {
    // viewOnly 모드: 앞의 프로리그 경기가 끝나지 않음
    final bool canStart = !viewOnly && !_isSimulating;

    return Container(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (viewOnly)
            Padding(
              padding: EdgeInsets.only(bottom: 8.sp),
              child: Text(
                '⚠️ 프로리그 경기를 먼저 완료해야 진행할 수 있습니다',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12.sp,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    context.pop();
                  } else {
                    context.go('/main');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_back, color: Colors.white, size: 16.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      'EXIT',
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24.sp),
              ElevatedButton(
                onPressed: canStart
                    ? () => _isCompleted
                        ? _goToNextStage(context)
                        : _startSimulation(bracket, playerMap)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canStart ? AppColors.primary : Colors.grey,
                  padding: EdgeInsets.symmetric(horizontal: 32.sp, vertical: 12.sp),
                ),
                child: Row(
                  children: [
                    Text(
                      viewOnly ? '잠금' : (_isCompleted ? 'Next' : 'Start'),
                      style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    ),
                    SizedBox(width: 8.sp),
                    Icon(
                      viewOnly ? Icons.lock : Icons.arrow_forward,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startSimulation(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
  ) async {
    IndividualLeagueBracket currentBracket;

    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      // 조 편성 먼저
      final gameState = ref.read(gameStateProvider)!;
      currentBracket = _leagueService.createIndividualLeagueBracket(
        allPlayers: gameState.saveData.allPlayers,
        playerTeamId: gameState.playerTeam.id,
        seasonNumber: gameState.saveData.currentSeason.number,
        previousSeasonBracket: gameState.saveData.previousSeasonIndividualLeague,
      );

      // 상태 업데이트
      ref.read(gameStateProvider.notifier).updateIndividualLeague(currentBracket);
    } else {
      currentBracket = bracket;
    }

    final totalGroups = currentBracket.pcBangGroups.length;

    // 시뮬레이션 시작
    setState(() {
      _isSimulating = true;
      _currentRevealingGroup = -1;
    });

    // 0.3초 간격으로 조별 결과 표시 (조가 많아졌으므로 더 빠르게)
    _revealTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      setState(() {
        _currentRevealingGroup++;
      });

      if (_currentRevealingGroup >= totalGroups - 1) {
        timer.cancel();
        _finishSimulation(playerMap);
      }
    });
  }

  void _finishSimulation(Map<String, Player> playerMap) {
    final gameState = ref.read(gameStateProvider)!;
    var bracket = gameState.saveData.currentSeason.individualLeague!;

    // 모든 조 시뮬레이션
    bracket = _leagueService.simulateAllPcBangGroups(
      bracket: bracket,
      playerMap: playerMap,
    );

    // 상태 업데이트
    ref.read(gameStateProvider.notifier).updateIndividualLeague(bracket);

    setState(() {
      _isSimulating = false;
      _isCompleted = true;
      _qualifiedPlayers = List.from(bracket.dualTournamentPlayers);
    });
  }

  void _goToNextStage(BuildContext context) {
    context.push('/dual-tournament');
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
