import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:study_leveling_flutter/models/leaderboard_entry.dart';
import 'package:study_leveling_flutter/services/leaderboard_service.dart';

void main() {
  test('loads leaderboard entries from a hosted API response', () async {
    final service = LeaderboardService(
      apiUrl: 'https://api.example.com',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), 'https://api.example.com/leaderboard');

        return http.Response(
          jsonEncode(<String, Object>{
            'entries': <Map<String, Object>>[
              <String, Object>{
                'username': 'md',
                'level': 4,
                'xp': 120,
                'completedTasks': 8,
              },
            ],
          }),
          200,
        );
      }),
    );

    final entries = await service.loadEntries();

    expect(entries.single.username, 'md');
    expect(entries.single.level, 4);
    expect(entries.single.completedTasks, 8);
  });

  test('deduplicates usernames and keeps the best leaderboard entry', () async {
    final service = LeaderboardService(
      apiUrl: 'https://api.example.com',
      client: MockClient((request) async {
        return http.Response(
          jsonEncode(<String, Object>{
            'entries': <Map<String, Object>>[
              <String, Object>{
                'username': 'md',
                'level': 3,
                'xp': 90,
                'completedTasks': 5,
                'profileImageBase64': 'profile-image',
                'updatedAt': 100,
              },
              <String, Object>{
                'username': 'raya',
                'level': 2,
                'xp': 50,
                'completedTasks': 8,
              },
              <String, Object>{
                'username': 'MD',
                'level': 4,
                'xp': 10,
                'completedTasks': 2,
                'updatedAt': 200,
              },
            ],
          }),
          200,
        );
      }),
    );

    final entries = await service.loadEntries();

    expect(entries, hasLength(2));
    expect(entries.first.username, 'MD');
    expect(entries.first.level, 4);
    expect(entries.first.profileImageBase64, 'profile-image');
    expect(
      entries.where((entry) => entry.username.toLowerCase() == 'md'),
      hasLength(1),
    );
  });

  test('submits leaderboard entry to the hosted API', () async {
    final service = LeaderboardService(
      apiUrl: 'https://api.example.com/v1',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://api.example.com/v1/leaderboard',
        );

        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['username'], 'arya');
        expect(payload['level'], 5);

        return http.Response('{}', 204);
      }),
    );

    await service.submitEntry(
      const LeaderboardEntry(
        username: 'arya',
        level: 5,
        xp: 40,
        completedTasks: 12,
      ),
    );
  });
}
