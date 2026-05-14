class LeaderboardEntry {
  const LeaderboardEntry({
    required this.username,
    required this.level,
    required this.xp,
    required this.completedTasks,
    this.profileImageBase64,
    this.updatedAt,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: (json['username'] ?? '').toString(),
      level: _intValue(json['level'], fallback: 1),
      xp: _intValue(json['xp'], fallback: 0),
      completedTasks: _intValue(json['completedTasks'], fallback: 0),
      profileImageBase64: (json['profileImageBase64'] ?? '').toString().isEmpty
          ? null
          : (json['profileImageBase64'] ?? '').toString(),
      updatedAt: _optionalIntValue(json['updatedAt']),
    );
  }

  final String username;
  final int level;
  final int xp;
  final int completedTasks;
  final String? profileImageBase64;
  final int? updatedAt;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'username': username,
      'level': level,
      'xp': xp,
      'completedTasks': completedTasks,
      'profileImageBase64': profileImageBase64,
    };

    final timestamp = updatedAt;
    if (timestamp != null) {
      json['updatedAt'] = timestamp;
    }

    return json;
  }

  static int _intValue(Object? value, {required int fallback}) {
    return _optionalIntValue(value) ?? fallback;
  }

  static int? _optionalIntValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
