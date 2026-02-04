import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/providers/game_provider.dart';
import '../../../data/providers/match_provider.dart';
import '../../../domain/models/models.dart';
import '../../widgets/reset_button.dart';

class MatchSimulationScreen extends ConsumerStatefulWidget {
  const MatchSimulationScreen({super.key});

  @override
  ConsumerState<MatchSimulationScreen> createState() =>
      _MatchSimulationScreenState();
}

class _MatchSimulationScreenState extends ConsumerState<MatchSimulationScreen> {
  // 현재 게임 상태
  int player1Resource = 100;
  int player1Army = 100;
  int player2Resource = 100;
  int player2Army = 100;

  // 전투 로그
  final List<String> battleLog = [];
  final ScrollController _logScrollController = ScrollController();

  // 배속
  int speed = 1;
  Timer? _gameTimer;
  bool isRunning = false;
  bool gameEnded = false;

  // 에이스 결정전 관련
  bool showAceSelection = false;
  int? selectedAceIndex;

  // 전투 텍스트 템플릿
  final List<String> battleTexts = [
    '치열한 교전 중입니다!',
    '양측 모두 물러서지 않습니다!',
    '팽팽한 접전이 이어집니다!',
    '밀고 밀리는 상황!',
    '대규모 교전이 시작됐습니다!',
    '환상적인 컨트롤!',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
    });
  }

  void _initGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) {
      // 매치 데이터가 없으면 메인으로 돌아감
      context.go('/main');
      return;
    }

    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return;

    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);

    _addLog('경기가 시작됩니다!');
    _addLog('${homePlayer?.name ?? "?"} vs ${awayPlayer?.name ?? "?"}');
    _startGame();
  }

  Player? _getPlayerById(String? playerId) {
    if (playerId == null) return null;
    final gameState = ref.read(gameStateProvider);
    if (gameState == null) return null;
    return gameState.saveData.getPlayerById(playerId);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isRunning = true;
      gameEnded = false;
    });

    _gameTimer = Timer.periodic(
      Duration(milliseconds: 1000 ~/ speed),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        _simulateTurn();
      },
    );
  }

  void _simulateTurn() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);

    if (homePlayer == null || awayPlayer == null) return;

    final random = Random();

    // 선수 능력치 기반 이벤트 확률 조정
    final homeTotal = homePlayer.stats.total;
    final awayTotal = awayPlayer.stats.total;
    final homeBias = homeTotal / (homeTotal + awayTotal);

    // 랜덤 이벤트
    final eventType = random.nextInt(10);

    if (eventType < 4) {
      // 자원 변화
      final resourceChange = random.nextInt(10) + 5;
      if (random.nextDouble() < homeBias) {
        player2Resource = (player2Resource - resourceChange).clamp(0, 100);
        player1Resource = (player1Resource + resourceChange ~/ 2).clamp(0, 100);
      } else {
        player1Resource = (player1Resource - resourceChange).clamp(0, 100);
        player2Resource = (player2Resource + resourceChange ~/ 2).clamp(0, 100);
      }
    } else {
      // 전투
      final damage1 = random.nextInt(15) + 5;
      final damage2 = random.nextInt(15) + 5;

      if (random.nextDouble() < homeBias) {
        player2Army = (player2Army - damage1).clamp(0, 100);
        player1Army = (player1Army - damage2 ~/ 2).clamp(0, 100);
        _addLog('${homePlayer.name} 선수, 우세한 상황입니다!');
      } else {
        player1Army = (player1Army - damage2).clamp(0, 100);
        player2Army = (player2Army - damage1 ~/ 2).clamp(0, 100);
        _addLog('${awayPlayer.name} 선수, 우세한 상황입니다!');
      }
    }

    // 랜덤 전투 텍스트
    if (random.nextInt(3) == 0) {
      _addLog(battleTexts[random.nextInt(battleTexts.length)]);
    }

    // 승패 체크
    if (_checkGameEnd(homePlayer, awayPlayer)) {
      _gameTimer?.cancel();
      setState(() {
        isRunning = false;
        gameEnded = true;
      });
    } else {
      setState(() {});
    }
  }

  bool _checkGameEnd(Player homePlayer, Player awayPlayer) {
    if (player1Army <= 0 || player2Army <= 0) {
      final homeWin = player1Army > player2Army;
      final winner = homeWin ? homePlayer : awayPlayer;
      final loser = homeWin ? awayPlayer : homePlayer;

      _addLog('');
      _addLog('${loser.name} 선수, GG를 선언합니다.');
      _addLog('${winner.name} 선수 승리!');

      // 점수 업데이트
      ref.read(currentMatchProvider.notifier).recordSetResult(homeWin);

      return true;
    }

    // GG 조건: (자원+병력) < 상대의 30%
    final player1Total = player1Resource + player1Army;
    final player2Total = player2Resource + player2Army;

    if (player1Total < player2Total * 0.3) {
      _addLog('');
      _addLog('${homePlayer.name} 선수, GG를 선언합니다.');
      _addLog('${awayPlayer.name} 선수 승리!');
      ref.read(currentMatchProvider.notifier).recordSetResult(false);
      return true;
    }

    if (player2Total < player1Total * 0.3) {
      _addLog('');
      _addLog('${awayPlayer.name} 선수, GG를 선언합니다.');
      _addLog('${homePlayer.name} 선수 승리!');
      ref.read(currentMatchProvider.notifier).recordSetResult(true);
      return true;
    }

    return false;
  }

  void _addLog(String text) {
    setState(() {
      battleLog.add(text);
    });

    // 스크롤 아래로
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _changeSpeed(int newSpeed) {
    setState(() {
      speed = newSpeed;
    });

    if (isRunning) {
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(
        Duration(milliseconds: 1000 ~/ speed),
        (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          _simulateTurn();
        },
      );
    }
  }

  void _nextGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    if (matchState.isMatchEnded) {
      // 매치 종료
      _showMatchResult();
    } else if (matchState.isAceMatch && matchState.homeAcePlayerId == null) {
      // 에이스 결정전 진행 필요
      setState(() {
        showAceSelection = true;
      });
    } else {
      // 다음 게임
      _prepareNextGame();
    }
  }

  void _prepareNextGame() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);

    setState(() {
      player1Resource = 100;
      player1Army = 100;
      player2Resource = 100;
      player2Army = 100;
      battleLog.clear();
      gameEnded = false;
      showAceSelection = false;
    });

    _addLog('Game ${matchState.currentSet + 1} 시작!');
    _addLog('${homePlayer?.name ?? "?"} vs ${awayPlayer?.name ?? "?"}');
    _startGame();
  }

  void _selectAcePlayer(int playerIndex) {
    final gameState = ref.read(gameStateProvider);
    final matchState = ref.read(currentMatchProvider);
    if (gameState == null || matchState == null) return;

    final teamPlayers = gameState.playerTeamPlayers;
    if (playerIndex < 0 || playerIndex >= teamPlayers.length) return;

    // 이미 출전한 선수인지 체크
    final usedPlayers = matchState.homeRoster.whereType<String>().toSet();
    final selectedPlayer = teamPlayers[playerIndex];

    if (usedPlayers.contains(selectedPlayer.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 출전한 선수입니다.')),
      );
      return;
    }

    // 에이스 선수 설정
    ref.read(currentMatchProvider.notifier).setAcePlayer(
      homeAceId: selectedPlayer.id,
    );

    // 다음 게임 시작
    _prepareNextGame();
  }

  void _showMatchResult() {
    final matchState = ref.read(currentMatchProvider);
    if (matchState == null) return;

    final isWin = matchState.homeScore > matchState.awayScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          isWin ? '승리!' : '패배...',
          style: TextStyle(
            color: isWin ? AppTheme.accentGreen : Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${matchState.homeScore} : ${matchState.awayScore}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isWin ? '축하합니다!' : '다음에는 꼭 이기세요!',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(currentMatchProvider.notifier).resetMatch();
              Navigator.pop(context);
              context.go('/main');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Responsive.init(context);

    final matchState = ref.watch(currentMatchProvider);
    final gameState = ref.watch(gameStateProvider);

    if (matchState == null || gameState == null) {
      return const Scaffold(
        body: Center(child: Text('매치 데이터를 불러올 수 없습니다')),
      );
    }

    // 에이스 선택 화면
    if (showAceSelection) {
      return _buildAceSelectionScreen(gameState, matchState);
    }

    final homeTeam = gameState.saveData.getTeamById(matchState.homeTeamId);
    final awayTeam = gameState.saveData.getTeamById(matchState.awayTeamId);
    final homePlayer = _getPlayerById(matchState.currentHomePlayerId);
    final awayPlayer = _getPlayerById(matchState.currentAwayPlayerId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('경기 진행'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              _gameTimer?.cancel();
              ref.read(currentMatchProvider.notifier).resetMatch();
              context.go('/main');
            },
            child: const Text('나가기'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 매치 스코어
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.cardBackground,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: Text(
                        homeTeam?.name ?? '홈팀',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${matchState.homeScore} : ${matchState.awayScore}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGreen,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        awayTeam?.name ?? '어웨이팀',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // 세트 정보
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  matchState.isAceMatch ? 'ACE 결정전' : 'Set ${matchState.currentSet + 1}',
                  style: TextStyle(
                    color: matchState.isAceMatch ? Colors.orange : AppTheme.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // 선수 정보
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: _PlayerPanel(player: homePlayer, isHome: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _PlayerPanel(player: awayPlayer, isHome: false)),
                  ],
                ),
              ),

              // 자원/병력 바
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _ResourceBar(
                      label: '자원',
                      value1: player1Resource,
                      value2: player2Resource,
                      color: Colors.yellow,
                    ),
                    const SizedBox(height: 8),
                    _ResourceBar(
                      label: '병력',
                      value1: player1Army,
                      value2: player2Army,
                      color: Colors.red,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 전투 로그
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue),
                  ),
                  child: ListView.builder(
                    controller: _logScrollController,
                    itemCount: battleLog.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          battleLog[index],
                          style: TextStyle(
                            color: battleLog[index].contains('승리')
                                ? AppTheme.accentGreen
                                : battleLog[index].contains('GG')
                                    ? Colors.orange
                                    : AppTheme.textPrimary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 컨트롤
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 배속 버튼
                    ...[1, 2, 4, 8].map((s) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            onPressed: () => _changeSpeed(s),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: speed == s
                                  ? AppTheme.accentGreen
                                  : AppTheme.cardBackground,
                              foregroundColor:
                                  speed == s ? Colors.black : AppTheme.textPrimary,
                              minimumSize: const Size(50, 40),
                            ),
                            child: Text('x$s'),
                          ),
                        )),
                    const SizedBox(width: 16),
                    // 다음 게임 / 스킵
                    if (gameEnded)
                      ElevatedButton(
                        onPressed: _nextGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.black,
                        ),
                        child: Text(
                          matchState.isMatchEnded
                              ? '결과 확인'
                              : matchState.isAceMatch
                                  ? '에이스 선택'
                                  : '다음 게임',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          ResetButton.positioned(),
        ],
      ),
    );
  }

  Widget _buildAceSelectionScreen(GameState gameState, CurrentMatchState matchState) {
    final teamPlayers = gameState.playerTeamPlayers;
    final usedPlayers = matchState.homeRoster.whereType<String>().toSet();

    // 사용 가능한 선수 (아직 출전하지 않은 선수)
    final availablePlayers = <int>[];
    for (int i = 0; i < teamPlayers.length; i++) {
      if (!usedPlayers.contains(teamPlayers[i].id)) {
        availablePlayers.add(i);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('에이스 결정전'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 상단 정보
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.2),
            child: Column(
              children: [
                const Text(
                  'ACE 결정전 (3:3)',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '7세트에 출전할 에이스 선수를 선택하세요',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                if (availablePlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '(모든 선수가 출전했습니다. 아무 선수나 선택하세요)',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // 선수 목록
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teamPlayers.length,
              itemBuilder: (context, index) {
                final player = teamPlayers[index];
                final isUsed = usedPlayers.contains(player.id);
                final raceCode = player.race.code;
                final gradeString = player.grade.display;

                return Card(
                  color: isUsed
                      ? AppTheme.cardBackground.withOpacity(0.3)
                      : AppTheme.cardBackground,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    onTap: () => _selectAcePlayer(index),
                    leading: CircleAvatar(
                      backgroundColor: isUsed
                          ? Colors.grey
                          : AppTheme.getRaceColor(raceCode),
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
                        color: isUsed ? AppTheme.textSecondary : AppTheme.textPrimary,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      isUsed ? '이미 출전' : '컨디션: ${player.condition}%',
                      style: TextStyle(
                        color: isUsed ? Colors.red.withOpacity(0.7) : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUsed
                            ? Colors.grey
                            : AppTheme.getGradeColor(gradeString),
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerPanel extends StatelessWidget {
  final Player? player;
  final bool isHome;

  const _PlayerPanel({required this.player, required this.isHome});

  @override
  Widget build(BuildContext context) {
    if (player == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHome ? AppTheme.accentGreen : Colors.red,
            width: 2,
          ),
        ),
        child: const Center(
          child: Text('선수 없음', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final raceCode = player!.race.code;
    final gradeString = player!.grade.display;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHome ? AppTheme.accentGreen : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.getRaceColor(raceCode),
            child: Text(
              raceCode,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            player!.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.getGradeColor(gradeString),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              gradeString,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceBar extends StatelessWidget {
  final String label;
  final int value1;
  final int value2;
  final Color color;

  const _ResourceBar({
    required this.label,
    required this.value1,
    required this.value2,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              // Player 1 bar (오른쪽으로)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerRight,
                          widthFactor: value1 / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$value1',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Player 2 bar (왼쪽으로)
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '$value2',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: value2 / 100,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
