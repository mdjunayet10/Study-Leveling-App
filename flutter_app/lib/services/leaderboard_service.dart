import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/leaderboard_entry.dart';

class LeaderboardService {
  LeaderboardService({String? apiUrl, http.Client? client})
    : _apiUrl = apiUrl,
      _client = client ?? http.Client();

  static const String _databaseBaseUrl =
      'https://study-leveling-default-rtdb.asia-southeast1.firebasedatabase.app';

  final http.Client _client;
  final String? _apiUrl;

  bool get isRemoteEnabled => true;

  Future<List<LeaderboardEntry>> loadEntries() async {
    final apiUrl = _apiUrl;
    if (apiUrl != null) {
      return _loadHostedEntries(apiUrl);
    }

    final response = await _client.get(
      Uri.parse('$_databaseBaseUrl/leaderboard.json'),
      headers: const <String, String>{'Accept': 'application/json'},
    );

    _throwIfFailed(response);

    final body = response.body.trim();
    if (body.isEmpty || body == 'null') {
      return <LeaderboardEntry>[];
    }

    final decoded = jsonDecode(body);
    final entries = <LeaderboardEntry>[];

    if (decoded is Map) {
      for (final rawEntry in decoded.entries) {
        final databaseKey = rawEntry.key.toString();
        final rawValue = rawEntry.value;

        if (rawValue is! Map) {
          continue;
        }

        final entryJson = Map<String, dynamic>.from(rawValue);

        final username = (entryJson['username'] ?? '').toString().trim();
        if (username.isEmpty) {
          entryJson['username'] = databaseKey;
        }

        entryJson['level'] = _intValue(entryJson['level'], fallback: 1);
        entryJson['xp'] = _intValue(entryJson['xp'], fallback: 0);
        entryJson['completedTasks'] = _intValue(
          entryJson['completedTasks'],
          fallback: 0,
        );

        entries.add(LeaderboardEntry.fromJson(entryJson));
      }
    }

    final deduplicatedEntries = _deduplicateEntries(entries);
    _sortEntries(deduplicatedEntries);
    return deduplicatedEntries;
  }

  Future<void> submitEntry(LeaderboardEntry entry) async {
    final apiUrl = _apiUrl;
    if (apiUrl != null) {
      await _submitHostedEntry(apiUrl, entry);
      return;
    }

    final userId = _userIdForUsername(entry.username);

    final payload = <String, dynamic>{
      'userId': userId,
      'username': entry.username.trim().isEmpty
          ? userId
          : entry.username.trim(),
      'level': entry.level,
      'xp': entry.xp,
      'completedTasks': entry.completedTasks,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    final profileImageBase64 = entry.profileImageBase64;
    if (profileImageBase64 != null && profileImageBase64.trim().isNotEmpty) {
      payload['profileImageBase64'] = profileImageBase64;
    }

    final response = await _client.put(
      Uri.parse('$_databaseBaseUrl/leaderboard/$userId.json'),
      headers: const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    _throwIfFailed(response);
  }

  Future<List<LeaderboardEntry>> _loadHostedEntries(String apiUrl) async {
    final response = await _client.get(
      Uri.parse('${apiUrl.replaceFirst(RegExp(r'/$'), '')}/leaderboard'),
      headers: const <String, String>{'Accept': 'application/json'},
    );

    _throwIfFailed(response);

    final body = response.body.trim();
    if (body.isEmpty || body == 'null') {
      return <LeaderboardEntry>[];
    }

    final decoded = jsonDecode(body);
    final rawEntries = decoded is Map ? decoded['entries'] : decoded;

    if (rawEntries is! List) {
      return <LeaderboardEntry>[];
    }

    final entries = rawEntries
        .whereType<Map>()
        .map(
          (entry) =>
              LeaderboardEntry.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();

    final deduplicatedEntries = _deduplicateEntries(entries);
    _sortEntries(deduplicatedEntries);
    return deduplicatedEntries;
  }

  Future<void> _submitHostedEntry(String apiUrl, LeaderboardEntry entry) async {
    final response = await _client.post(
      Uri.parse('${apiUrl.replaceFirst(RegExp(r'/$'), '')}/leaderboard'),
      headers: const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(entry.toJson()),
    );

    _throwIfFailed(response);
  }

  int _intValue(Object? value, {required int fallback}) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  String _userIdForUsername(String username) {
    final normalized = username.trim().toLowerCase().isEmpty
        ? 'student'
        : username.trim().toLowerCase();

    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');

    return safe.isEmpty ? 'student' : safe;
  }

  List<LeaderboardEntry> _deduplicateEntries(List<LeaderboardEntry> entries) {
    final bestByUsername = <String, LeaderboardEntry>{};

    for (final entry in entries) {
      final usernameKey = entry.username.trim().toLowerCase();
      if (usernameKey.isEmpty) {
        continue;
      }

      final currentBest = bestByUsername[usernameKey];
      if (currentBest == null || _isBetterEntry(entry, currentBest)) {
        bestByUsername[usernameKey] = _withProfileImageFallback(
          entry,
          currentBest,
        );
      }
    }

    return bestByUsername.values.toList();
  }

  bool _isBetterEntry(
    LeaderboardEntry candidate,
    LeaderboardEntry currentBest,
  ) {
    final rankingCompare = _compareEntries(candidate, currentBest);
    if (rankingCompare != 0) {
      return rankingCompare < 0;
    }

    final candidateUpdatedAt = candidate.updatedAt ?? 0;
    final currentUpdatedAt = currentBest.updatedAt ?? 0;
    if (candidateUpdatedAt != currentUpdatedAt) {
      return candidateUpdatedAt > currentUpdatedAt;
    }

    final candidateHasImage =
        candidate.profileImageBase64 != null &&
        candidate.profileImageBase64!.trim().isNotEmpty;
    final currentHasImage =
        currentBest.profileImageBase64 != null &&
        currentBest.profileImageBase64!.trim().isNotEmpty;

    return candidateHasImage && !currentHasImage;
  }

  LeaderboardEntry _withProfileImageFallback(
    LeaderboardEntry entry,
    LeaderboardEntry? fallback,
  ) {
    final hasImage =
        entry.profileImageBase64 != null &&
        entry.profileImageBase64!.trim().isNotEmpty;
    final fallbackImage = fallback?.profileImageBase64;

    if (hasImage || fallbackImage == null || fallbackImage.trim().isEmpty) {
      return entry;
    }

    return LeaderboardEntry(
      username: entry.username,
      level: entry.level,
      xp: entry.xp,
      completedTasks: entry.completedTasks,
      profileImageBase64: fallbackImage,
      updatedAt: entry.updatedAt,
    );
  }

  int _compareEntries(LeaderboardEntry left, LeaderboardEntry right) {
    final levelCompare = right.level.compareTo(left.level);
    if (levelCompare != 0) {
      return levelCompare;
    }

    final xpCompare = right.xp.compareTo(left.xp);
    if (xpCompare != 0) {
      return xpCompare;
    }

    return right.completedTasks.compareTo(left.completedTasks);
  }

  void _sortEntries(List<LeaderboardEntry> entries) {
    entries.sort(_compareEntries);
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw LeaderboardServiceException(
      'Firebase Realtime Database request failed with status '
      '${response.statusCode}: ${response.body}',
    );
  }
}

class LeaderboardServiceException implements Exception {
  const LeaderboardServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
