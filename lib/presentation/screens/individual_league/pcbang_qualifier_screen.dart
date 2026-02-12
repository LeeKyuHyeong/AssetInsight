import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../domain/services/individual_league_service.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

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

    // 아마추어 선수 추가 (PC방 예선 조에 있는 경우)
    if (bracket != null) {
      for (final group in bracket.pcBangGroups) {
        for (final playerId in group) {
          if (playerId.startsWith('amateur_') && !playerMap.containsKey(playerId)) {
            playerMap[playerId] = Player(
              id: playerId,
              name: '아마추어',
              raceIndex: Race.values[playerId.hashCode % 3].index,
              stats: const PlayerStats(
                sense: 100, control: 100, attack: 100, harass: 100,
                strategy: 100, macro: 100, defense: 100, scout: 100,
              ),
              levelValue: 1,
            );
          }
        }
      }
    }

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
                        // 상단: 24개 조 버튼 (4줄 × 6개)
                        _buildGroupButtons(bracket),
                        SizedBox(height: 8.sp),
                        // 중앙: 대진표 + 참가 현황 (50:50 분할)
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
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
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 10.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          ResetButton.back(),
          SizedBox(width: 8.sp),
          _buildTeamLogo(team),
          SizedBox(width: 12.sp),
          Expanded(
            child: Text(
              'PC방 예선 토너먼트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const ResetButton(small: true),
        ],
      ),
    );
  }

  Widget _buildTeamLogo(Team team) {
    return Container(
      width: 60.sp,
      height: 40.sp,
      decoration: BoxDecoration(
        color: Color(team.colorValue).withValues(alpha:0.2),
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      padding: EdgeInsets.all(8.sp),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1조 ~ 6조
          _buildGroupRow(bracket, 0, 6),
          SizedBox(height: 4.sp),
          // 7조 ~ 12조
          _buildGroupRow(bracket, 6, 12),
          SizedBox(height: 4.sp),
          // 13조 ~ 18조
          _buildGroupRow(bracket, 12, 18),
          SizedBox(height: 4.sp),
          // 19조 ~ 24조
          _buildGroupRow(bracket, 18, 24),
        ],
      ),
    );
  }

  Widget _buildGroupRow(IndividualLeagueBracket? bracket, int start, int end) {
    return Row(
      children: [
        for (int index = start; index < end; index++) ...[
          Expanded(
            child: _buildGroupButton(bracket, index),
          ),
          if (index < end - 1) SizedBox(width: 4.sp),
        ],
      ],
    );
  }

  Widget _buildGroupButton(IndividualLeagueBracket? bracket, int index) {
    final isSelected = _selectedGroupIndex == index;
    final isRevealed = _currentRevealingGroup >= index;
    final hasResult = bracket != null &&
        _leagueService.getGroupResult(bracket, index) != null;
    final canSelect = bracket != null && index < bracket.pcBangGroups.length;

    return GestureDetector(
      onTap: canSelect
          ? () => setState(() => _selectedGroupIndex = index)
          : null,
      child: Container(
        height: 28.sp,
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
        child: Center(
          child: Text(
            '${index + 1}조',
            style: TextStyle(
              color: isSelected || isRevealed ? Colors.white : Colors.grey,
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
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
      padding: EdgeInsets.all(12.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '대진표',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
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
    // 조 선택 안됨 → '조를 선택해주세요'
    if (_selectedGroupIndex == null) {
      return Center(
        child: Text(
          '조를 선택해주세요',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    // 시뮬레이션 진행 중
    if (_isSimulating) {
      final totalGroups = bracket?.pcBangGroups.length ?? 24;
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
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              '${_currentRevealingGroup + 1} / $totalGroups 조',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // bracket이 없거나 조 편성 안됨
    if (bracket == null || bracket.pcBangGroups.isEmpty) {
      return Center(
        child: Text(
          '조 편성이 필요합니다\nStart 버튼을 눌러주세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    // 선택한 조가 범위 밖
    if (_selectedGroupIndex! >= bracket.pcBangGroups.length) {
      return Center(
        child: Text(
          '${_selectedGroupIndex! + 1}조 정보 없음',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    // 시뮬레이션 완료 후 → 피라미드 대진표 표시
    if (_isCompleted) {
      return _buildPyramidBracket(bracket, playerMap, _selectedGroupIndex!);
    }

    // 시뮬레이션 전 → 참가자 명단으로 피라미드 미리보기
    return _buildPyramidPreview(bracket, playerMap, _selectedGroupIndex!);
  }

  /// 시뮬레이션 전 피라미드 미리보기 (참가자만 표시)
  Widget _buildPyramidPreview(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupPlayers = bracket.pcBangGroups[groupIndex];
    final groupSize = groupPlayers.length;

    return Column(
      children: [
        // 조 번호
        Text(
          '${groupIndex + 1}조',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        // 피라미드 구조
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 최종 승자 자리
              _buildPlayerSlot('?', isWinner: true),
              SizedBox(height: 8.sp),
              // 결승 (2명)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPlayerSlot('?'),
                  SizedBox(width: 16.sp),
                  _buildPlayerSlot('?'),
                ],
              ),
              SizedBox(height: 8.sp),
              // 4강 (인원수에 따라)
              if (groupSize >= 5) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPlayerSlot('?'),
                    SizedBox(width: 8.sp),
                    _buildPlayerSlot('?'),
                    if (groupSize == 5) ...[
                      SizedBox(width: 8.sp),
                      _buildPlayerSlot('부전승', isBye: true),
                    ],
                    if (groupSize == 6) ...[
                      SizedBox(width: 8.sp),
                      _buildPlayerSlot('?'),
                    ],
                  ],
                ),
                SizedBox(height: 8.sp),
              ],
              // 참가자 (맨 아래)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4.sp,
                runSpacing: 4.sp,
                children: groupPlayers.map((playerId) {
                  final player = playerMap[playerId];
                  final name = player?.name ?? '아마추어';
                  final race = player?.race;
                  return _buildPlayerSlot(
                    race != null ? '(${race.code}) $name' : name,
                    isParticipant: true,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시뮬레이션 완료 후 피라미드 대진표 (결과 표시)
  Widget _buildPyramidBracket(
    IndividualLeagueBracket bracket,
    Map<String, Player> playerMap,
    int groupIndex,
  ) {
    final groupResult = _leagueService.getGroupResult(bracket, groupIndex);
    if (groupResult == null) {
      return Center(
        child: Text(
          '결과 없음',
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
      );
    }

    final groupSize = groupResult.groupSize;
    final winner = playerMap[groupResult.winnerId];
    final winnerName = winner != null
        ? '(${winner.race.code})${winner.name}'
        : '?';

    return Column(
      children: [
        // 조 번호
        Text(
          '${groupIndex + 1}조',
          style: TextStyle(
            color: AppColors.accent,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.sp),
        // 피라미드 구조 (위에서 아래로)
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 최종 승자
              _buildWinnerBox(winnerName),
              SizedBox(height: 12.sp),
              // 결승
              _buildMatchResultRow(groupResult.matches.last, playerMap),
              SizedBox(height: 12.sp),
              // 3명 조: 1라운드 1경기 + 부전승
              if (groupSize == 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMatchResultBox(groupResult.matches[0], playerMap),
                    _buildByeBox(),
                  ],
                ),
              // 4명 조: 4강 2경기
              if (groupSize == 4)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMatchResultBox(groupResult.matches[0], playerMap),
                    _buildMatchResultBox(groupResult.matches[1], playerMap),
                  ],
                ),
              // 5명 조: 4강 2경기 + 부전승
              if (groupSize == 5)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMatchResultBox(groupResult.matches[0], playerMap),
                    _buildMatchResultBox(groupResult.matches[1], playerMap),
                    _buildByeBox(),
                  ],
                ),
              // 6명 조: 4강 3경기
              if (groupSize == 6)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMatchResultBox(groupResult.matches[0], playerMap),
                    _buildMatchResultBox(groupResult.matches[1], playerMap),
                    _buildMatchResultBox(groupResult.matches[2], playerMap),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerBox(String name) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMatchResultRow(IndividualMatchResult match, Map<String, Player> playerMap) {
    final p1 = playerMap[match.player1Id];
    final p2 = playerMap[match.player2Id];
    final p1Won = match.winnerId == match.player1Id;

    // 3전 2선승 점수 (승자 2, 패자 0 or 1)
    const winScore = 2;
    final loseScore = match.id.hashCode % 2; // 랜덤하게 0 또는 1

    final p1Score = p1Won ? winScore : loseScore;
    final p2Score = p1Won ? loseScore : winScore;

    final p1Name = p1 != null ? '(${p1.race.code})${p1.name}' : '?';
    final p2Name = p2 != null ? '(${p2.race.code})${p2.name}' : '?';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          p1Name,
          style: TextStyle(
            color: p1Won ? Colors.white : Colors.grey,
            fontSize: 11.sp,
            fontWeight: p1Won ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        SizedBox(width: 6.sp),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Text(
            '$p1Score - $p2Score',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 6.sp),
        Text(
          p2Name,
          style: TextStyle(
            color: !p1Won ? Colors.white : Colors.grey,
            fontSize: 11.sp,
            fontWeight: !p1Won ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchResultBox(IndividualMatchResult match, Map<String, Player> playerMap) {
    final p1 = playerMap[match.player1Id];
    final p2 = playerMap[match.player2Id];
    final p1Won = match.winnerId == match.player1Id;

    // 3전 2선승 점수
    const winScore = 2;
    final loseScore = match.id.hashCode % 2;

    final p1Score = p1Won ? winScore : loseScore;
    final p2Score = p1Won ? loseScore : winScore;

    final p1Name = p1 != null ? '(${p1.race.code})${p1.name}' : '?';
    final p2Name = p2 != null ? '(${p2.race.code})${p2.name}' : '?';

    return Container(
      padding: EdgeInsets.all(6.sp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$p1Name $p1Score',
            style: TextStyle(
              color: p1Won ? Colors.white : Colors.grey,
              fontSize: 9.sp,
              fontWeight: p1Won ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$p2Score $p2Name',
            style: TextStyle(
              color: !p1Won ? Colors.white : Colors.grey,
              fontSize: 9.sp,
              fontWeight: !p1Won ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildByeBox() {
    return Container(
      padding: EdgeInsets.all(6.sp),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(4.sp),
      ),
      child: Text(
        '부전승',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 9.sp,
        ),
      ),
    );
  }

  Widget _buildPlayerSlot(
    String name, {
    bool isWinner = false,
    bool isParticipant = false,
    bool isLoser = false,
    bool isBye = false,
  }) {
    Color bgColor;
    Color textColor;
    double fontSize;

    if (isWinner) {
      bgColor = AppColors.accent.withValues(alpha: 0.3);
      textColor = Colors.white;
      fontSize = 12.sp;
    } else if (isBye) {
      bgColor = Colors.grey[700]!;
      textColor = Colors.grey;
      fontSize = 10.sp;
    } else if (isParticipant) {
      bgColor = Colors.grey[800]!;
      textColor = isLoser ? Colors.grey : Colors.white;
      fontSize = 10.sp;
    } else {
      bgColor = Colors.grey[800]!;
      textColor = isLoser ? Colors.grey : Colors.white;
      fontSize = 11.sp;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4.sp),
        border: isWinner ? Border.all(color: AppColors.accent) : null,
      ),
      child: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildRightPanel(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    // 시뮬레이션 중이거나 완료된 경우: "진출 현황"
    // 시작 전: "우리팀 참가 현황"
    final bool showQualified = _isSimulating || _isCompleted;

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
            showQualified ? '진출 현황' : '우리팀 참가 현황',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.sp),
          Expanded(
            child: showQualified
                ? _buildProgressiveQualifiedList(bracket, playerMap, playerTeamId)
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

  /// 진출 현황 (1초마다 순차 표시)
  Widget _buildProgressiveQualifiedList(
    IndividualLeagueBracket? bracket,
    Map<String, Player> playerMap,
    String playerTeamId,
  ) {
    if (bracket == null) {
      return const Center(child: Text('데이터 없음'));
    }

    // 표시할 조 수 (시뮬레이션 중이면 _currentRevealingGroup까지, 완료면 전체)
    final int displayCount = _isCompleted
        ? bracket.pcBangGroups.length
        : (_currentRevealingGroup + 1).clamp(0, bracket.pcBangGroups.length);

    return ListView.builder(
      itemCount: displayCount,
      itemBuilder: (context, index) {
        // 해당 조의 진출자 찾기
        final groupResult = _leagueService.getGroupResult(bracket, index);
        if (groupResult == null) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 3.sp),
            child: Text(
              '${index + 1}조 ...',
              style: TextStyle(color: Colors.grey, fontSize: 11.sp),
            ),
          );
        }

        final winnerId = groupResult.winnerId;
        final winner = playerMap[winnerId];
        final isMyTeam = winner?.teamId == playerTeamId;
        final name = winner?.name ?? '아마추어';
        final race = winner?.race;

        return Container(
          padding: EdgeInsets.symmetric(vertical: 3.sp),
          child: Row(
            children: [
              SizedBox(
                width: 36.sp,
                child: Text(
                  '${index + 1}조',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              if (race != null)
                Text(
                  '(${race.code}) ',
                  style: TextStyle(
                    color: isMyTeam ? AppColors.accent : _getRaceColor(race),
                    fontSize: 11.sp,
                  ),
                ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isMyTeam ? AppColors.accent : Colors.white,
                    fontSize: 11.sp,
                    fontWeight: isMyTeam ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
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

    // 먼저 모든 조 시뮬레이션 완료 (결과 생성)
    currentBracket = _leagueService.simulateAllPcBangGroups(
      bracket: currentBracket,
      playerMap: playerMap,
    );
    ref.read(gameStateProvider.notifier).updateIndividualLeague(currentBracket);

    final totalGroups = currentBracket.pcBangGroups.length;

    // 시뮬레이션 시작 (결과 순차 표시)
    setState(() {
      _isSimulating = true;
      _currentRevealingGroup = -1;
    });

    // 1초 간격으로 조별 결과 순차 표시
    _revealTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentRevealingGroup++;
      });

      if (_currentRevealingGroup >= totalGroups - 1) {
        timer.cancel();
        _finishSimulation();
      }
    });
  }

  void _finishSimulation() {
    setState(() {
      _isSimulating = false;
      _isCompleted = true;
    });
  }

  void _goToNextStage(BuildContext context) {
    // 메인 메뉴로 이동 (다음 프로리그 매치가 focus됨)
    context.go('/main');
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
