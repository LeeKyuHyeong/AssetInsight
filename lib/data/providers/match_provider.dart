import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/models.dart';
import 'game_provider.dart';

/// 현재 매치 상태
class CurrentMatchState {
  final String homeTeamId;
  final String awayTeamId;
  final List<String?> homeRoster; // 인덱스 = 세트 번호 (0-5), 값 = 선수 ID
  final List<String?> awayRoster;
  final String? homeAcePlayerId; // 7세트 에이스 (3:3일 때)
  final String? awayAcePlayerId;
  final int homeScore;
  final int awayScore;
  final int currentSet; // 현재 진행 중인 세트 (0-6)

  const CurrentMatchState({
    required this.homeTeamId,
    required this.awayTeamId,
    this.homeRoster = const [null, null, null, null, null, null],
    this.awayRoster = const [null, null, null, null, null, null],
    this.homeAcePlayerId,
    this.awayAcePlayerId,
    this.homeScore = 0,
    this.awayScore = 0,
    this.currentSet = 0,
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

  CurrentMatchState copyWith({
    String? homeTeamId,
    String? awayTeamId,
    List<String?>? homeRoster,
    List<String?>? awayRoster,
    String? homeAcePlayerId,
    String? awayAcePlayerId,
    int? homeScore,
    int? awayScore,
    int? currentSet,
  }) {
    return CurrentMatchState(
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeRoster: homeRoster ?? this.homeRoster,
      awayRoster: awayRoster ?? this.awayRoster,
      homeAcePlayerId: homeAcePlayerId ?? this.homeAcePlayerId,
      awayAcePlayerId: awayAcePlayerId ?? this.awayAcePlayerId,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      currentSet: currentSet ?? this.currentSet,
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
    required List<String?> homeRoster,
  }) {
    // 상대팀 로스터 자동 생성
    final awayRoster = _generateOpponentRoster(awayTeamId);

    state = CurrentMatchState(
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeRoster: homeRoster,
      awayRoster: awayRoster,
    );
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

  /// 세트 결과 기록
  void recordSetResult(bool homeWin) {
    if (state == null) return;

    final newHomeScore = homeWin ? state!.homeScore + 1 : state!.homeScore;
    final newAwayScore = homeWin ? state!.awayScore : state!.awayScore + 1;

    // 다음 세트로 이동 (매치가 끝나지 않았다면)
    int nextSet = state!.currentSet;
    if (newHomeScore < 4 && newAwayScore < 4) {
      nextSet++;
    }

    state = state!.copyWith(
      homeScore: newHomeScore,
      awayScore: newAwayScore,
      currentSet: nextSet,
    );
  }

  /// 에이스 선수 설정 (3:3일 때)
  void setAcePlayer({String? homeAceId, String? awayAceId}) {
    if (state == null) return;

    // 상대 에이스 자동 선택 (설정 안 된 경우)
    String? finalAwayAceId = awayAceId;
    if (finalAwayAceId == null && state!.isAceMatch) {
      finalAwayAceId = _selectOpponentAce();
    }

    state = state!.copyWith(
      homeAcePlayerId: homeAceId,
      awayAcePlayerId: finalAwayAceId,
    );
  }

  /// 상대팀 에이스 자동 선택
  String? _selectOpponentAce() {
    if (state == null) return null;

    final gameState = _ref.read(gameStateProvider);
    if (gameState == null) return null;

    final awayPlayers = gameState.saveData.getTeamPlayers(state!.awayTeamId);
    if (awayPlayers.isEmpty) return null;

    // 이미 출전한 선수 제외
    final usedPlayers = state!.awayRoster.whereType<String>().toSet();
    final availablePlayers = awayPlayers.where((p) => !usedPlayers.contains(p.id)).toList();

    if (availablePlayers.isEmpty) {
      // 사용 가능한 선수가 없으면 가장 높은 등급 선수 재출전
      final bestPlayer = awayPlayers.reduce((a, b) =>
          a.grade.index > b.grade.index ? a : b);
      return bestPlayer.id;
    }

    // 사용 가능한 선수 중 가장 높은 등급
    final bestAvailable = availablePlayers.reduce((a, b) =>
        a.grade.index > b.grade.index ? a : b);
    return bestAvailable.id;
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
