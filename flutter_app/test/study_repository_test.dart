import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_leveling_flutter/models/user_profile.dart';
import 'package:study_leveling_flutter/services/study_repository.dart';

void main() {
  test('persists profile pictures across repository restarts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final repository = StudyRepository();
    await repository.initialize();

    final user = UserProfile.newUser(
      'photo-user',
      email: 'photo-user@study.local',
      emailVerified: true,
    )..profileImageBase64 = 'saved-profile-image';

    await repository.saveUser(user);

    final restartedRepository = StudyRepository();
    await restartedRepository.initialize();

    final restoredUser = await restartedRepository.loadUser('photo-user');

    expect(restoredUser?.profileImageBase64, 'saved-profile-image');
  });
}
