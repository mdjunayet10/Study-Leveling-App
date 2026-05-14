import 'dart:convert';

import 'user_profile.dart';

class MultiplayerRoom {
  static const int minAllowedPlayers = 2;
  static const int maxAllowedPlayers = 4;

  MultiplayerRoom({
    required this.roomId,
    required this.maxPlayers,
    required this.creatorUsername,
    required this.createdAt,
    required this.competitiveTimer,
    required this.timerMinutes,
    required this.participants,
    this.initialCompletedTasks = const <String, int>{},
    this.updatedAt,
  });

  factory MultiplayerRoom.fromJson(Map<String, dynamic> json) {
    final rawMaxPlayers = (json['maxPlayers'] as num? ?? minAllowedPlayers)
        .toInt();

    return MultiplayerRoom(
      roomId: (json['roomId'] ?? '').toString(),
      maxPlayers: clampPlayerCount(rawMaxPlayers),
      creatorUsername: (json['creatorUsername'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      competitiveTimer: json['competitiveTimer'] as bool? ?? false,
      timerMinutes: (json['timerMinutes'] as num? ?? 30).toInt(),
      participants: _readParticipants(json['participants']),
      initialCompletedTasks: _readCompletedTaskMap(
        json['initialCompletedTasks'],
      ),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  final String roomId;
  final int maxPlayers;
  final String creatorUsername;
  final DateTime createdAt;
  final bool competitiveTimer;
  final int timerMinutes;
  final List<UserProfile> participants;
  final Map<String, int> initialCompletedTasks;
  final DateTime? updatedAt;

  static List<UserProfile> _readParticipants(dynamic rawParticipants) {
    if (rawParticipants is List) {
      return rawParticipants
          .whereType<Map>()
          .map(
            (dynamic participant) => UserProfile.fromJson(
              Map<String, dynamic>.from(participant as Map),
            ),
          )
          .toList()
        ..sort(_sortUsersByUsername);
    }

    if (rawParticipants is Map) {
      return rawParticipants.values
          .whereType<Map>()
          .map(
            (dynamic participant) => UserProfile.fromJson(
              Map<String, dynamic>.from(participant as Map),
            ),
          )
          .toList()
        ..sort(_sortUsersByUsername);
    }

    return <UserProfile>[];
  }

  static int _sortUsersByUsername(UserProfile left, UserProfile right) {
    return left.username.toLowerCase().compareTo(right.username.toLowerCase());
  }

  static Map<String, int> _readCompletedTaskMap(dynamic rawValue) {
    if (rawValue is! Map) {
      return const <String, int>{};
    }

    return <String, int>{
      for (final entry in rawValue.entries)
        entry.key.toString(): (entry.value as num? ?? 0).toInt(),
    };
  }

  static int clampPlayerCount(int value) {
    if (value < minAllowedPlayers) {
      return minAllowedPlayers;
    }

    if (value > maxAllowedPlayers) {
      return maxAllowedPlayers;
    }

    return value;
  }

  bool get isFull => participants.length >= maxPlayers;

  int initialCompletedTasksFor(String username) {
    return initialCompletedTasks[firebaseUserKey(username)] ??
        initialCompletedTasks[username] ??
        0;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roomId': roomId,
      'maxPlayers': maxPlayers,
      'creatorUsername': creatorUsername,
      'createdAt': createdAt.toIso8601String(),
      'competitiveTimer': competitiveTimer,
      'timerMinutes': timerMinutes,
      'participants': participants
          .map((participant) => participant.toJson())
          .toList(),
      'initialCompletedTasks': initialCompletedTasks,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirebaseJson() {
    return <String, dynamic>{
      'roomId': roomId,
      'maxPlayers': maxPlayers,
      'creatorUsername': creatorUsername,
      'createdAt': createdAt.toIso8601String(),
      'competitiveTimer': competitiveTimer,
      'timerMinutes': timerMinutes,
      'participants': <String, dynamic>{
        for (final participant in participants)
          firebaseUserKey(participant.username): participant.toJson(),
      },
      'initialCompletedTasks': initialCompletedTasks,
      'updatedAt': (updatedAt ?? DateTime.now()).toIso8601String(),
    };
  }

  MultiplayerRoom copy() {
    return MultiplayerRoom(
      roomId: roomId,
      maxPlayers: maxPlayers,
      creatorUsername: creatorUsername,
      createdAt: createdAt,
      competitiveTimer: competitiveTimer,
      timerMinutes: timerMinutes,
      participants: participants
          .map((participant) => participant.copy())
          .toList(),
      initialCompletedTasks: Map<String, int>.from(initialCompletedTasks),
      updatedAt: updatedAt,
    );
  }

  static String firebaseUserKey(String username) {
    final normalized = username.trim().toLowerCase();
    final safe = normalized
        .replaceAll(RegExp(r'[^a-z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (safe.isNotEmpty) {
      return safe;
    }

    final encodedUsername = base64Url
        .encode(utf8.encode(normalized))
        .replaceAll('=', '');
    return 'user_$encodedUsername';
  }
}
