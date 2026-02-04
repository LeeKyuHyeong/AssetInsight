import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/models/models.dart';
import '../../../data/providers/game_provider.dart';
import '../../widgets/reset_button.dart';

/// 위너스리그 경기 데이터
class WinnersMatch {
  final Team homeTeam;
  final Team awayTeam;
  final List<_WinnersSetResult> sets;
  final bool isCompleted;

  WinnersMatch({
    required this.homeTeam,
    required this.awayTeam,
    this.sets = const [],
    this.isCompleted = false,
  });

  int get homeWins => sets.where((s) => s.homeWin).length;
  int get awayWins => sets.where((s) => !s.homeWin).length;
  Team? get winner => isCompleted
      ? (homeWins >= 4 ? homeTeam : awayTeam)
      : null;
}

class _WinnersSetResult {
  final Player homePlayer;
  final Player awayPlayer;
  final bool homeWin;
  final String? mapName;

  _WinnersSetResult({
    required this.homePlayer,
    required this.awayPlayer,
    required this.homeWin,
    this.mapName,
  });
}

/// 위너스리그 화면
/// 3번째 시즌에 진행, 참가 자격 없음 (전체 팀 참가), 승자유지 방식
class WinnersLeagueScreen extends ConsumerStatefulWidget {
  const WinnersLeagueScreen({super.key});

  @override
  ConsumerState<WinnersLeagueScreen> createState() => _WinnersLeagueScreenState();
}

class _WinnersLeagueScreenState extends ConsumerState<WinnersLeagueScreen> {
  final int _currentRound = 1; // 현재 라운드
  int _selectedMatchIndex = 0;
  bool _isSimulating = false;
  double _simulationSpeed = 1.0;

  // 임시 대진표 데이터
  List<WinnersMatch> _matches = [];

  @override
  void initState() {
    super.initState();
    _initializeBracket();
  }

  void _initializeBracket() {
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final teams = gameState.saveData.allTeams.toList();
    // 8팀 토너먼트 가정
    _matches = [
      WinnersMatch(homeTeam: teams[0], awayTeam: teams[7]),
      WinnersMatch(homeTeam: teams[1], awayTeam: teams[6]),
      WinnersMatch(homeTeam: teams[2], awayTeam: teams[5]),
      WinnersMatch(homeTeam: teams[3], awayTeam: teams[4]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameStateProvider);
    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                _buildHeader(),

                // 메인 컨텐츠
                Expanded(
                  child: Row(
                    children: [
                      // 좌측: 대진표
                      Expanded(
                        flex: 2,
                        child: _buildBracket(),
                      ),

                      // 우측: 경기 상세
                      Expanded(
                        flex: 3,
                        child: _buildMatchDetail(),
                      ),
                    ],
                  ),
                ),

                // 하단 컨트롤
                _buildBottomControls(context),
              ],
            ),
            ResetButton.positioned(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: Colors.amber.withOpacity(0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.amber, size: 32.sp),
          SizedBox(width: 12.sp),
          Column(
            children: [
              Text(
                'WINNERS LEAGUE',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                '승자유지 방식 • Round $_currentRound',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.sp),
          Icon(Icons.emoji_events, color: Colors.amber, size: 32.sp),
        ],
      ),
    );
  }

  Widget _buildBracket() {
    return Container(
      margin: EdgeInsets.all(16.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '대진표',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.sp),
          Expanded(
            child: ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                return _buildBracketMatch(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketMatch(int index) {
    final match = _matches[index];
    final isSelected = index == _selectedMatchIndex;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMatchIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.sp),
        padding: EdgeInsets.all(12.sp),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.cardBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            // 홈팀
            _buildBracketTeamRow(
              match.homeTeam,
              match.homeWins,
              match.isCompleted && match.winner?.id == match.homeTeam.id,
            ),

            Padding(
              padding: EdgeInsets.symmetric(vertical: 4.sp),
              child: Text(
                'VS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10.sp,
                ),
              ),
            ),

            // 어웨이팀
            _buildBracketTeamRow(
              match.awayTeam,
              match.awayWins,
              match.isCompleted && match.winner?.id == match.awayTeam.id,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBracketTeamRow(Team team, int wins, bool isWinner) {
    return Row(
      children: [
        Container(
          width: 30.sp,
          height: 22.sp,
          decoration: BoxDecoration(
            color: Color(team.colorValue).withOpacity(0.2),
            borderRadius: BorderRadius.circular(2.sp),
          ),
          child: Center(
            child: Text(
              team.shortName,
              style: TextStyle(
                color: Color(team.colorValue),
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 8.sp),
        Expanded(
          child: Text(
            team.name,
            style: TextStyle(
              color: isWinner ? Colors.amber : Colors.white,
              fontSize: 11.sp,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
          decoration: BoxDecoration(
            color: wins > 0 ? AppColors.primary.withOpacity(0.3) : null,
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Text(
            '$wins',
            style: TextStyle(
              color: isWinner ? Colors.amber : Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isWinner) ...[
          SizedBox(width: 4.sp),
          Icon(Icons.emoji_events, color: Colors.amber, size: 16.sp),
        ],
      ],
    );
  }

  Widget _buildMatchDetail() {
    if (_matches.isEmpty) {
      return const Center(child: Text('대진표 로딩 중...'));
    }

    final match = _matches[_selectedMatchIndex];

    return Container(
      margin: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // 경기 헤더 (팀 vs 팀)
          _buildMatchHeader(match),

          SizedBox(height: 16.sp),

          // 세트 결과
          Expanded(
            child: _buildSetResults(match),
          ),

          // 시뮬레이션 진행 영역
          if (!match.isCompleted) _buildSimulationPanel(match),
        ],
      ),
    );
  }

  Widget _buildMatchHeader(WinnersMatch match) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 홈팀
          Expanded(
            child: _buildMatchTeam(match.homeTeam, match.homeWins, true),
          ),

          // 스코어
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Text(
              '${match.homeWins} : ${match.awayWins}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 어웨이팀
          Expanded(
            child: _buildMatchTeam(match.awayTeam, match.awayWins, false),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchTeam(Team team, int wins, bool isHome) {
    return Column(
      children: [
        Container(
          width: 60.sp,
          height: 45.sp,
          decoration: BoxDecoration(
            color: Color(team.colorValue).withOpacity(0.2),
            borderRadius: BorderRadius.circular(4.sp),
          ),
          child: Center(
            child: Text(
              team.shortName,
              style: TextStyle(
                color: Color(team.colorValue),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 8.sp),
        Text(
          team.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSetResults(WinnersMatch match) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '세트 결과',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '승자유지 방식',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          Expanded(
            child: match.sets.isEmpty
                ? Center(
                    child: Text(
                      '경기가 아직 시작되지 않았습니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  )
                : ListView.builder(
                    itemCount: match.sets.length,
                    itemBuilder: (context, index) {
                      final set = match.sets[index];
                      return _buildSetRow(index + 1, set);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int setNumber, _WinnersSetResult set) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(4.sp),
        border: Border.all(
          color: set.homeWin
              ? Colors.green.withOpacity(0.5)
              : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          // 세트 번호
          SizedBox(
            width: 40.sp,
            child: Text(
              'Set $setNumber',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 10.sp,
              ),
            ),
          ),

          // 홈 선수
          Expanded(
            child: Text(
              '${set.homePlayer.name} (${set.homePlayer.race.code})',
              style: TextStyle(
                color: set.homeWin ? Colors.green : Colors.white,
                fontSize: 11.sp,
                fontWeight: set.homeWin ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // 결과
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
            decoration: BoxDecoration(
              color: set.homeWin ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(4.sp),
            ),
            child: Text(
              set.homeWin ? 'WIN' : 'LOSE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 어웨이 선수
          Expanded(
            child: Text(
              '${set.awayPlayer.name} (${set.awayPlayer.race.code})',
              style: TextStyle(
                color: !set.homeWin ? Colors.green : Colors.white,
                fontSize: 11.sp,
                fontWeight: !set.homeWin ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationPanel(WinnersMatch match) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8.sp),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 배속 선택
          Text('배속: ', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
          ...[1.0, 2.0, 4.0, 8.0].map((speed) {
            final isSelected = _simulationSpeed == speed;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.sp),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _simulationSpeed = speed;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : null,
                    borderRadius: BorderRadius.circular(4.sp),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : Colors.grey,
                    ),
                  ),
                  child: Text(
                    'x${speed.toInt()}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 11.sp,
                    ),
                  ),
                ),
              ),
            );
          }),

          SizedBox(width: 24.sp),

          // 시작 버튼
          ElevatedButton(
            onPressed: _isSimulating ? null : () => _startSimulation(match),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 10.sp),
            ),
            child: Row(
              children: [
                Icon(
                  _isSimulating ? Icons.hourglass_empty : Icons.play_arrow,
                  size: 18.sp,
                ),
                SizedBox(width: 4.sp),
                Text(
                  _isSimulating ? '진행 중...' : '경기 시작',
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startSimulation(WinnersMatch match) async {
    setState(() {
      _isSimulating = true;
    });

    // TODO: 실제 경기 시뮬레이션 로직

    setState(() {
      _isSimulating = false;
    });
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.primary.withOpacity(0.3)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // EXIT 버튼
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
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
                  'EXIT',
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
