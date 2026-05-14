enum TaskDifficulty { easy, medium, hard }

extension TaskDifficultyX on TaskDifficulty {
  String get label => switch (this) {
    TaskDifficulty.easy => 'EASY',
    TaskDifficulty.medium => 'MEDIUM',
    TaskDifficulty.hard => 'HARD',
  };

  int get xpReward => switch (this) {
    TaskDifficulty.easy => 50,
    TaskDifficulty.medium => 100,
    TaskDifficulty.hard => 200,
  };

  int get coinReward => switch (this) {
    TaskDifficulty.easy => 20,
    TaskDifficulty.medium => 40,
    TaskDifficulty.hard => 80,
  };

  static TaskDifficulty fromString(String value) {
    switch (value.toUpperCase()) {
      case 'MEDIUM':
        return TaskDifficulty.medium;
      case 'HARD':
        return TaskDifficulty.hard;
      case 'EASY':
      default:
        return TaskDifficulty.easy;
    }
  }
}

class StudyTask {
  StudyTask({
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.difficulty,
    required this.completed,
    required this.completionDate,
    required this.timeLimit,
    this.startedAt,
  });

  factory StudyTask.fromDifficulty(
    String description,
    TaskDifficulty difficulty, {
    int timeLimit = 0,
  }) {
    return StudyTask(
      description: description,
      xpReward: difficulty.xpReward,
      coinReward: difficulty.coinReward,
      difficulty: difficulty,
      completed: false,
      completionDate: null,
      timeLimit: timeLimit,
      startedAt: null,
    );
  }

  factory StudyTask.fromJson(Map<String, dynamic> json) {
    final difficulty = TaskDifficultyX.fromString(
      (json['difficulty'] ?? 'EASY').toString(),
    );
    final completionDateValue = json['completionDate'];
    final startedAtValue = json['startedAt'];

    return StudyTask(
      description: (json['description'] ?? '').toString(),
      xpReward: (json['xpReward'] as num? ?? difficulty.xpReward).toInt(),
      coinReward: (json['coinReward'] as num? ?? difficulty.coinReward).toInt(),
      difficulty: difficulty,
      completed: json['completed'] as bool? ?? false,
      completionDate: completionDateValue == null
          ? null
          : DateTime.tryParse(completionDateValue.toString()),
      timeLimit: (json['timeLimit'] as num? ?? 0).toInt(),
      startedAt: startedAtValue == null
          ? null
          : DateTime.tryParse(startedAtValue.toString()),
    );
  }

  String description;
  int xpReward;
  int coinReward;
  TaskDifficulty difficulty;
  bool completed;
  DateTime? completionDate;
  int timeLimit;
  DateTime? startedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'description': description,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'difficulty': difficulty.label,
      'completed': completed,
      'completionDate': completionDate?.toIso8601String().split('T').first,
      'timeLimit': timeLimit,
      'startedAt': startedAt?.toIso8601String(),
    };
  }

  StudyTask copy() {
    return StudyTask(
      description: description,
      xpReward: xpReward,
      coinReward: coinReward,
      difficulty: difficulty,
      completed: completed,
      completionDate: completionDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              completionDate!.millisecondsSinceEpoch,
            ),
      timeLimit: timeLimit,
      startedAt: startedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              startedAt!.millisecondsSinceEpoch,
            ),
    );
  }

  @override
  String toString() {
    final status = completed ? '✓' : '○';
    final timerText = timeLimit > 0 ? ' ⏱$timeLimit min' : '';
    return '$status $description [${difficulty.label}] ⭐$xpReward 💰$coinReward$timerText';
  }
}
