import 'dart:math' as math;

import 'reward_item.dart';
import 'reward_redemption.dart';
import 'study_task.dart';

class UserProfile {
  UserProfile({
    required this.username,
    required this.xp,
    required this.level,
    required this.coins,
    required this.tasks,
    required this.totalCompletedTasks,
    required this.customRewards,
    required this.rewardHistory,
    required this.initialXp,
    required this.initialLevel,
    required this.initialCoins,
    required this.trackingInitialized,
    required this.dailyTaskGoal,
    required this.weeklyXpGoal,
    required this.targetLevel,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastStudyDate,
    this.email = '',
    this.emailVerified = false,
    this.profileImageBase64,
  });

  factory UserProfile.newUser(
    String username, {
    String email = '',
    bool emailVerified = false,
  }) {
    return UserProfile(
      username: username,
      email: email,
      emailVerified: emailVerified,
      xp: 0,
      level: 1,
      coins: 0,
      tasks: <StudyTask>[],
      totalCompletedTasks: 0,
      customRewards: <RewardItem>[],
      rewardHistory: <RewardRedemption>[],
      initialXp: 0,
      initialLevel: 0,
      initialCoins: 0,
      trackingInitialized: false,
      dailyTaskGoal: 3,
      weeklyXpGoal: 500,
      targetLevel: 5,
      currentStreak: 0,
      longestStreak: 0,
      lastStudyDate: null,
      profileImageBase64: null,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final profileImageValue = (json['profileImageBase64'] ?? '').toString();

    return UserProfile(
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      emailVerified: json['emailVerified'] as bool? ?? false,
      xp: (json['xp'] as num? ?? 0).toInt(),
      level: (json['level'] as num? ?? 1).toInt(),
      coins: (json['coins'] as num? ?? 0).toInt(),
      tasks: _readTasks(json['tasks']),
      totalCompletedTasks: (json['totalCompletedTasks'] as num? ?? 0).toInt(),
      customRewards: _readRewards(json['customRewards']),
      rewardHistory: _readRewardHistory(json['rewardHistory']),
      initialXp: (json['initialXp'] as num? ?? 0).toInt(),
      initialLevel: (json['initialLevel'] as num? ?? 0).toInt(),
      initialCoins: (json['initialCoins'] as num? ?? 0).toInt(),
      trackingInitialized: json['trackingInitialized'] as bool? ?? false,
      dailyTaskGoal: (json['dailyTaskGoal'] as num? ?? 3).toInt(),
      weeklyXpGoal: (json['weeklyXpGoal'] as num? ?? 500).toInt(),
      targetLevel: (json['targetLevel'] as num? ?? 5).toInt(),
      currentStreak: (json['currentStreak'] as num? ?? 0).toInt(),
      longestStreak: (json['longestStreak'] as num? ?? 0).toInt(),
      lastStudyDate: _readDate(json['lastStudyDate']),
      profileImageBase64: profileImageValue.isEmpty ? null : profileImageValue,
    );
  }

  String username;
  String email;
  bool emailVerified;
  String? profileImageBase64;
  int xp;
  int level;
  int coins;
  final List<StudyTask> tasks;
  int totalCompletedTasks;
  final List<RewardItem> customRewards;
  final List<RewardRedemption> rewardHistory;
  int initialXp;
  int initialLevel;
  int initialCoins;
  bool trackingInitialized;
  int dailyTaskGoal;
  int weeklyXpGoal;
  int targetLevel;
  int currentStreak;
  int longestStreak;
  DateTime? lastStudyDate;

  static List<StudyTask> _readTasks(dynamic rawTasks) {
    if (rawTasks is! List) {
      return <StudyTask>[];
    }

    return rawTasks
        .whereType<Map>()
        .map(
          (dynamic task) =>
              StudyTask.fromJson(Map<String, dynamic>.from(task as Map)),
        )
        .toList();
  }

  static List<RewardItem> _readRewards(dynamic rawRewards) {
    if (rawRewards is! List) {
      return <RewardItem>[];
    }

    return rawRewards
        .whereType<Map>()
        .map(
          (dynamic reward) =>
              RewardItem.fromJson(Map<String, dynamic>.from(reward as Map)),
        )
        .toList();
  }

  static List<RewardRedemption> _readRewardHistory(dynamic rawHistory) {
    if (rawHistory is! List) {
      return <RewardRedemption>[];
    }

    return rawHistory
        .whereType<Map>()
        .map(
          (dynamic redemption) => RewardRedemption.fromJson(
            Map<String, dynamic>.from(redemption as Map),
          ),
        )
        .toList();
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'username': username,
      'email': email,
      'emailVerified': emailVerified,
      'profileImageBase64': profileImageBase64,
      'xp': xp,
      'level': level,
      'coins': coins,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'totalCompletedTasks': totalCompletedTasks,
      'customRewards': customRewards.map((reward) => reward.toJson()).toList(),
      'rewardHistory': rewardHistory
          .map((redemption) => redemption.toJson())
          .toList(),
      'initialXp': initialXp,
      'initialLevel': initialLevel,
      'initialCoins': initialCoins,
      'trackingInitialized': trackingInitialized,
      'dailyTaskGoal': dailyTaskGoal,
      'weeklyXpGoal': weeklyXpGoal,
      'targetLevel': targetLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastStudyDate': lastStudyDate?.toIso8601String().split('T').first,
    };
  }

  UserProfile copy() {
    return UserProfile(
      username: username,
      email: email,
      emailVerified: emailVerified,
      profileImageBase64: profileImageBase64,
      xp: xp,
      level: level,
      coins: coins,
      tasks: tasks.map((task) => task.copy()).toList(),
      totalCompletedTasks: totalCompletedTasks,
      customRewards: customRewards.map((reward) => reward.copy()).toList(),
      rewardHistory: rewardHistory
          .map((redemption) => redemption.copy())
          .toList(),
      initialXp: initialXp,
      initialLevel: initialLevel,
      initialCoins: initialCoins,
      trackingInitialized: trackingInitialized,
      dailyTaskGoal: dailyTaskGoal,
      weeklyXpGoal: weeklyXpGoal,
      targetLevel: targetLevel,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastStudyDate: lastStudyDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              lastStudyDate!.millisecondsSinceEpoch,
            ),
    );
  }

  int xpNeededForLevel(int level) {
    return (100 * math.pow(1.5, level - 1)).toInt();
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpNeededForLevel(level)) {
      xp -= xpNeededForLevel(level);
      level++;
      coins += 50;
    }
  }

  bool spendCoins(int amount) {
    if (coins < amount) {
      return false;
    }

    coins -= amount;
    return true;
  }

  void addCoins(int amount) {
    coins += amount;
  }

  void updateGoals({
    required int dailyTasks,
    required int weeklyXp,
    required int targetLevelValue,
  }) {
    dailyTaskGoal = math.max(1, dailyTasks);
    weeklyXpGoal = math.max(1, weeklyXp);
    targetLevel = math.max(level, targetLevelValue);
  }

  void registerStudyCompletion(DateTime completedAt) {
    final completedDate = _dateOnly(completedAt);
    final previousDate = lastStudyDate == null
        ? null
        : _dateOnly(lastStudyDate!);

    if (previousDate == null) {
      currentStreak = 1;
    } else if (_isSameDay(previousDate, completedDate)) {
      currentStreak = math.max(1, currentStreak);
    } else if (completedDate.difference(previousDate).inDays == 1) {
      currentStreak++;
    } else {
      currentStreak = 1;
    }

    longestStreak = math.max(longestStreak, currentStreak);
    lastStudyDate = completedDate;
  }

  void recordRewardRedemption(RewardItem reward, DateTime redeemedAt) {
    rewardHistory.insert(
      0,
      RewardRedemption(
        rewardName: reward.name,
        cost: reward.cost,
        redeemedAt: redeemedAt,
      ),
    );

    if (rewardHistory.length > 50) {
      rewardHistory.removeRange(50, rewardHistory.length);
    }
  }

  int completedTasksOn(DateTime date) {
    final targetDate = _dateOnly(date);
    return tasks
        .where(
          (task) =>
              task.completed &&
              task.completionDate != null &&
              _isSameDay(_dateOnly(task.completionDate!), targetDate),
        )
        .length;
  }

  int xpEarnedThisWeek(DateTime date) {
    final today = _dateOnly(date);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    return tasks
        .where(
          (task) =>
              task.completed &&
              task.completionDate != null &&
              !_dateOnly(task.completionDate!).isBefore(startOfWeek) &&
              _dateOnly(task.completionDate!).isBefore(endOfWeek),
        )
        .fold<int>(0, (total, task) => total + task.xpReward);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  void setXp(int value) {
    xp = value;
  }

  void setLevel(int value) {
    level = value;
  }

  void setCoins(int value) {
    coins = value;
  }

  void setTotalCompletedTasks(int value) {
    totalCompletedTasks = value;
  }

  void incrementCompletedTasksCounter() {
    totalCompletedTasks++;
  }

  void initializeTracking() {
    initialXp = xp;
    initialLevel = level;
    initialCoins = coins;
    trackingInitialized = true;
  }

  void resetTracking() {
    trackingInitialized = false;
  }

  int getXpGainedInSession() => trackingInitialized ? xp - initialXp : 0;

  int getCoinsGainedInSession() =>
      trackingInitialized ? coins - initialCoins : 0;
}
