import 'package:flutter_test/flutter_test.dart';
import 'package:study_leveling_flutter/models/reward_item.dart';
import 'package:study_leveling_flutter/models/study_task.dart';
import 'package:study_leveling_flutter/models/user_profile.dart';

void main() {
  group('UserProfile progression', () {
    test('tracks current and longest study streaks', () {
      final user = UserProfile.newUser('tester');

      user.registerStudyCompletion(DateTime(2026, 4, 24));
      user.registerStudyCompletion(DateTime(2026, 4, 25));
      user.registerStudyCompletion(DateTime(2026, 4, 25, 18));
      user.registerStudyCompletion(DateTime(2026, 4, 27));

      expect(user.currentStreak, 1);
      expect(user.longestStreak, 2);
      expect(user.lastStudyDate, DateTime(2026, 4, 27));
    });

    test('persists goals and reward redemption history through JSON', () {
      final user = UserProfile.newUser('tester')
        ..addCoins(500)
        ..tasks.add(
          StudyTask.fromDifficulty(
              'Read operating systems notes',
              TaskDifficulty.medium,
            )
            ..completed = true
            ..completionDate = DateTime(2026, 4, 26),
        );

      user.updateGoals(dailyTasks: 4, weeklyXp: 650, targetLevelValue: 7);
      user.recordRewardRedemption(
        RewardItem(name: 'Long break', cost: 120),
        DateTime(2026, 4, 26, 12),
      );

      final restored = UserProfile.fromJson(user.toJson());

      expect(restored.dailyTaskGoal, 4);
      expect(restored.weeklyXpGoal, 650);
      expect(restored.targetLevel, 7);
      expect(restored.rewardHistory.single.rewardName, 'Long break');
      expect(restored.completedTasksOn(DateTime(2026, 4, 26)), 1);
      expect(restored.xpEarnedThisWeek(DateTime(2026, 4, 26)), 100);
    });
  });
}
