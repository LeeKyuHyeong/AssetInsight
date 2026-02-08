import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import 'game_provider.dart';

/// 스나이핑 배정 정보
class SnipingAssignment {
  final int setIndex;              // 세트 (0-5)
  final String myPlayerId;         // 스나이핑 사용 선수
  final String predictedOpponentId; // 예측 상대 선수

  const SnipingAssignment({
    required this.setIndex,
    required this.myPlayerId,
    required this.predictedOpponentId,
  });
}

/// 현재 매치 상태
class CurrentMatchState {
  final String homeTeamId;
  final String awayTeamId;
  final String? matchId; // 스케줄 상의 매치 ID (정확한 매치 식별용)
  final List<String?> homeRoster; // 인덱스 = 세트 번호 (0-5), 값 = 선수 ID
  final List<String?> awayRoster;
  final String? homeAcePlayerId; // 7세트 에이스 (3:3일 때)
  final String? awayAcePlayerId;
  final int homeScore;
  final int awayScore;
  final int currentSet; // 현재 진행 중인 세트 (0-6)
  final List<bool> setResults; // 각 세트 결과 (true = 홈 승리, false = 어웨이 승리)
  final List<SnipingAssignment> homeSnipingAssignments;
  final List<SnipingAssignment> awaySnipingAssignments;
  const CurrentMatchState({
    required this.homeTeamId,
    required this.awayTeamId,
    this.matchId,
    this.homeRoster = const [null, null, null, null, null, null],
    this.awayRoster = const [null, null, null, null, null, null],
    this.homeAcePlayerId,
    this.awayAcePlayerId,
    this.homeScore = 0,
    this.awayScore = 0,
    this.currentSet = 0,
    this.setResults = const [],
    this.homeSnipingAssignments = const [],
    this.awaySnipingAssignments = const [],
  });

  /// 현재 세트의 홈 선수 ID
  String? get currentHomePlayerId {
    if (currentSet < 6) {
      return homeRoster[currentSet];
    } else {
      return homeAcePlayerId;
    }
  }

  /// 현재 세트의 어웨이 선수 ID
  String? get currentAwayPlayerId {
    if (currentSet < 6) {
      return awayRoster[currentSet];
    } else {
      return awayAcePlayerId;
    }
  }

  /// 에이스 결정전 여부 (3:3)
  bool get isAceMatch => homeScore == 3 && awayScore == 3;

  /// 매치 종료 여부
  bool get isMatchEnded => homeScore >= 4 || awayScore >= 4;

  /// 특정 세트에서 성공한 스나이핑 확인 (예측이 실제 상대와 일치)
  /// 반환: 성공한 스나이핑의 선수 이름 (실패 시 null)
  SnipingAssignment? getSuccessfulSniping({required bool isHome, required int setIndex}) {
    final assignments = isHome ? homeSnipingAssignments : awaySnipingAssignments;
    final opponentRoster = isHome ? awayRoster : homeRoster;

    for (final assignment in assignments) {
      if (assignment.setIndex == setIndex) {
        // 실제 상대 선수와 예측이 일치하는지 확인
        if (setIndex < opponentRoster.length &&
            opponentRoster[setIndex] == assignment.predictedOpponentId) {
          return assignment;
        }
      }
    }
    return null;
  }

  CurrentMatchState copyWith({
    String? homeTeamId,
    String? awayTeamId,
    String? matchId,
    List<String?>? homeRoster,
    List<String?>? awayRoster,
    String? homeAcePlayerId,
    String? awayAcePlayerId,
    int? homeScore,
    int? awayScore,
    int? currentSet,
    List<bool>? setResults,
    List<SnipingAssignment>? homeSnipingAssignments,
    List<SnipingAssignment>? awaySnipingAssignments,
  }) {
    return CurrentMatchState(
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      matchId: matchId ?? this.matchId,
      homeRoster: homeRoster ?? this.homeRoster,
      awayRoster: awayRoster ?? this.awayRoster,
      homeAcePlayerId: homeAcePlayerId ?? this.homeAcePlayerId,
      awayAcePlayerId: awayAcePlayerId ?? this.awayAcePlayerId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      currentSet: currentSet ?? this.currentSet,
      setResults: setResults ?? this.setResults,
      homeSnipingAssignments: homeSnipingAssignments ?? this.homeSnipingAssignments,
      awaySnipingAssignments: awaySnipingAssignments ?? this.awaySnipingAssignments,
    );
  }
}

/// 현재 매치 상태 Notifier
class CurrentMatchNotifier extends StateNotifier<CurrentMatchState?> {
  final Ref _ref;

  CurrentMatchNotifier(this._ref) : super(null);

  /// 매치 시작 (로스터 설정)
  void startMatch({
    required String homeTeamId,
    required String awayTeamId,
    String? matchId,
    List<String?>? homeRoster,
    List<String?>? awayRoster,
    List<SnipingAssignment>? homeSnipingAssignments,
    List<SnipingAssignment>? awaySnipingAssignments,
  }) {
    final gameState = _ref.read(gameStateProvider);
    final playerTeamId = gameState?.playerTeam.id;
    final isPlayerHome = homeTeamId == playerTeamId;

    // 플레이어가 홈일 때: homeRoster 지정, awayRoster 자동 생성
    // 플레이어가 어웨이일 때: awayRoster 지정, homeRoster 자동 생성
    final finalHomeRoster = homeRoster ?? _generateOpponentRoster(homeTeamId);
    final finalAwayRoster = awayRoster ?? _generateOpponentRoster(awayTeamId);

    // AI 스나이핑 생성 (상대팀이 AI인 경우, 조지명식 이후부터)
    List<SnipingAssignment> finalHomeSniping = homeSnipingAssignments ?? const [];
    List<SnipingAssignment> finalAwaySniping = awaySnipingAssignments ?? const [];

    final individualLeague = gameState?.currentSeason.individualLeague;
    final isAfterGroupDraw = individualLeague != null &&
        individualLeague.mainTournamentPlayers.isNotEmpty;

    if (isPlayerHome && isAfterGroupDraw) {
      // 플레이어가 홈이면 AI는 어웨이
      finalAwaySniping = _generateAISniping(
        aiRoster: finalAwayRoster,
        opponentRoster: finalHomeRoster,
        gameState: gameState,
      );
    } else if (!isPlayerHome && isAfterGroupDraw) {
      // 플레이어가 어웨이면 AI는 홈
      finalHomeSniping = _generateAISniping(
        aiRoster: finalHomeRoster,
        opponentRoster: finalAwayRoster,
        gameState: gameState,
      );
    }

    state = CurrentMatchState(
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      matchId: matchId,
      homeRoster: finalHomeRoster,
      awayRoster: finalAwayRoster,
      homeSnipingAssignments: finalHomeSniping,
      awaySnipingAssignments: finalAwaySniping,
    );
  }

  /// AI 스나이핑 생성 (경기당 0~2개)
  List<SnipingAssignment> _generateAISniping({
    required List<String?> aiRoster,
    required List<String?> opponentRoster,
    GameState? gameState,
  }) {
    final random = Random();
    final assignments = <SnipingAssignment>[];

    // 50%: 0개, 30%: 1개, 20%: 2개
    final roll = random.nextDouble();
    int snipingCount;
    if (roll < 0.5) {
      snipingCount = 0;
    } else if (roll < 0.8) {
      snipingCount = 1;
    } else {
      snipingCount = 2;
    }

    if (snipingCount == 0) return assignments;

    // 유효한 세트 (AI 선수가 배치된 세트) 중 랜덤 선택
    final validSets = <int>[];
    for (int i = 0; i < 6; i++) {
      if (aiRoster.length > i && aiRoster[i] != null) {
        validSets.add(i);
      }
    }
    if (validSets.isEmpty) return assignments;

    validSets.shuffle(random);

    for (int i = 0; i < snipingCount && i < validSets.length; i++) {
      final setIndex = validSets[i];
      final myPlayerId = aiRoster[setIndex]!;

      // 40% 확률로 정확 예측, 60% 랜덤 예측
      String? predictedOpponentId;
      if (random.nextDouble() < 0.4) {
        // 정확 예측: 실제 상대 선수
        if (setIndex < opponentRoster.length && opponentRoster[setIndex] != null) {
          predictedOpponentId = opponentRoster[setIndex];
        }
      }

      if (predictedOpponentId == null) {
        // 랜덤 예측: 상대 로스터에서 랜덤
        final validOpponents = opponentRoster.where((id) => id != null).toList();
        if (validOpponents.isNotEmpty) {
          predictedOpponentId = validOpponents[random.nextInt(validOpponents.length)];
        }
      }

      if (predictedOpponentId != null) {
        assignments.add(SnipingAssignment(
          setIndex: setIndex,
          myPlayerId: myPlayerId,
          predictedOpponentId: predictedOpponentId,
        ));
      }
    }

    return assignments;
  }

  /// 상대팀 로스터 자동 생성
  List<String?> _generateOpponentRoster(String teamId) {
    final gameState = _ref.read(gameStateProvider);
    if (gameState == null) return List.filled(6, null);

    final teamPlayers = gameState.saveData.getTeamPlayers(teamId);
    if (teamPlayers.isEmpty) return List.filled(6, null);

    // 컨디션 + 등급 기준으로 정렬
    final sortedPlayers = List<Player>.from(teamPlayers)
      ..sort((a, b) {
        final scoreA = a.condition + a.grade.index * 10;
        final scoreB = b.condition + b.grade.index * 10;
        return scoreB - scoreA;
      });

    // 상위 6명 선택 (또는 전원)
    final selectedCount = sortedPlayers.length >= 6 ? 6 : sortedPlayers.length;
    final roster = <String?>[];

    for (int i = 0; i < 6; i++) {
      if (i < selectedCount) {
        roster.add(sortedPlayers[i].id);
      } else {
        roster.add(null);
      }
    }

    // 약간의 랜덤성 추가 (순서 섞기)
    final random = Random();
    for (int i = roster.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = roster[i];
      roster[i] = roster[j];
      roster[j] = temp;
    }

    return roster;
  }

  /// 세트 결과 기록 (currentSet은 변경하지 않음 - advanceToNextSet에서 별도 처리)
  void recordSetResult(bool homeWin) {
    if (state == null) return;

    final newHomeScore = homeWin ? state!.homeScore + 1 : state!.homeScore;
    final newAwayScore = homeWin ? state!.awayScore : state!.awayScore + 1;

    // 세트 결과 추가
    final newSetResults = [...state!.setResults, homeWin];

    // 점수와 세트 결과만 업데이트 (currentSet은 유지)
    state = state!.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      setResults: newSetResults,
    );
  }

  /// 다음 세트로 이동 (NEXT 버튼 클릭 시 호출)
  void advanceToNextSet() {
    if (state == null) return;
    if (state!.isMatchEnded) return;

    state = state!.copyWith(
      currentSet: state!.currentSet + 1,
    );
  }

  /// 에이스 선수 설정 (3:3일 때)
  void setAcePlayer({String? homeAceId, String? awayAceId}) {
    if (state == null) return;

    final gameState = _ref.read(gameStateProvider);
    if (gameState == null) return;

    // 플레이어 팀이 홈인지 확인
    final isPlayerHome = state!.homeTeamId == gameState.playerTeam.id;

    // 상대 에이스 자동 선택 (설정 안 된 경우)
    String? finalHomeAceId = homeAceId;
    String? finalAwayAceId = awayAceId;

    if (state!.isAceMatch) {
      if (isPlayerHome) {
        // 플레이어가 홈이면, away 에이스 자동 선택
        if (finalAwayAceId == null) {
          finalAwayAceId = _selectOpponentAce(isOpponentHome: false);
        }
      } else {
        // 플레이어가 away이면, home 에이스 자동 선택
        if (finalHomeAceId == null) {
          finalHomeAceId = _selectOpponentAce(isOpponentHome: true);
        }
      }
    }

    state = state!.copyWith(
      homeAcePlayerId: finalHomeAceId,
      awayAcePlayerId: finalAwayAceId,
    );
  }

  /// 상대팀 에이스 자동 선택 (에이스결정전은 전체 선수 중 선택 가능)
  String? _selectOpponentAce({required bool isOpponentHome}) {
    if (state == null) return null;

    final gameState = _ref.read(gameStateProvider);
    if (gameState == null) return null;

    // 상대팀 ID 결정
    final opponentTeamId = isOpponentHome ? state!.homeTeamId : state!.awayTeamId;

    final opponentPlayers = gameState.saveData.getTeamPlayers(opponentTeamId);
    if (opponentPlayers.isEmpty) return null;

    // 에이스결정전은 전체 선수 중 가장 높은 등급 선수 선택 (이전 출전자 제외 없음)
    final bestPlayer = opponentPlayers.reduce((a, b) =>
        a.grade.index > b.grade.index ? a : b);
    return bestPlayer.id;
  }

  /// 매치 초기화
  void resetMatch() {
    state = null;
  }
}

/// 현재 매치 상태 Provider
final currentMatchProvider = StateNotifierProvider<CurrentMatchNotifier, CurrentMatchState?>((ref) {
  return CurrentMatchNotifier(ref);
});
