import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/leaderboard_entry.dart';
import '../models/multiplayer_room.dart';
import '../models/reward_item.dart';
import '../models/reward_redemption.dart';
import '../models/study_task.dart';
import '../models/user_profile.dart';
import 'leaderboard_service.dart';

class StudyRepository {
  StudyRepository({LeaderboardService? leaderboardService})
    : leaderboardService = leaderboardService ?? LeaderboardService();

  static const _usersKey = 'study_leveling.users';
  static const _profileImagesKey = 'study_leveling.profile_images';
  static const _passwordsKey = 'study_leveling.passwords';
  static const _roomsKey = 'study_leveling.rooms';
  static const _activeUsernameKey = 'study_leveling.active_username';
  static const _lastLocationKey = 'study_leveling.last_location';
  static const _firebaseOperationTimeout = Duration(seconds: 12);

  final LeaderboardService leaderboardService;

  final Map<String, UserProfile> _users = <String, UserProfile>{};
  final Map<String, String> _profileImages = <String, String>{};
  final Map<String, String> _passwords = <String, String>{};
  final Map<String, MultiplayerRoom> _rooms = <String, MultiplayerRoom>{};
  String? _lastLocationSignature;

  SharedPreferences? _prefs;

  DatabaseReference get _database => FirebaseDatabase.instance.ref();

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadUsers();
    _loadProfileImages();
    await _syncProfileImageStorage();
    _loadPasswords();
    _loadRooms();

    if (_users.isEmpty) {
      await _seedDefaults();
    }
  }

  Future<void> _seedDefaults() async {
    _users
      ..clear()
      ..addAll(<String, UserProfile>{
        'md': UserProfile(
          username: 'md',
          email: 'md@study.local',
          emailVerified: true,
          xp: 80,
          level: 3,
          coins: 220,
          tasks: <StudyTask>[
            StudyTask.fromDifficulty(
                'Read a chapter',
                TaskDifficulty.easy,
                timeLimit: 30,
              )
              ..completed = true
              ..completionDate = DateTime.parse('2026-04-24'),
            StudyTask.fromDifficulty(
                'Create study notes',
                TaskDifficulty.medium,
                timeLimit: 45,
              )
              ..completed = true
              ..completionDate = DateTime.parse('2026-04-24'),
            StudyTask.fromDifficulty(
                'Teach a concept to someone',
                TaskDifficulty.hard,
                timeLimit: 60,
              )
              ..completed = true
              ..completionDate = DateTime.parse('2026-04-24'),
          ],
          totalCompletedTasks: 3,
          customRewards: <RewardItem>[],
          rewardHistory: <RewardRedemption>[],
          initialXp: 0,
          initialLevel: 0,
          initialCoins: 0,
          trackingInitialized: false,
          dailyTaskGoal: 3,
          weeklyXpGoal: 500,
          targetLevel: 5,
          currentStreak: 1,
          longestStreak: 1,
          lastStudyDate: DateTime.parse('2026-04-24'),
        ),
        'arya': UserProfile(
          username: 'arya',
          email: 'arya@study.local',
          emailVerified: true,
          xp: 140,
          level: 4,
          coins: 360,
          tasks: <StudyTask>[
            StudyTask.fromDifficulty(
              'Practice flashcards',
              TaskDifficulty.easy,
            ),
            StudyTask.fromDifficulty(
              'Review summary notes',
              TaskDifficulty.medium,
            ),
          ],
          totalCompletedTasks: 6,
          customRewards: <RewardItem>[],
          rewardHistory: <RewardRedemption>[],
          initialXp: 0,
          initialLevel: 0,
          initialCoins: 0,
          trackingInitialized: false,
          dailyTaskGoal: 3,
          weeklyXpGoal: 500,
          targetLevel: 6,
          currentStreak: 2,
          longestStreak: 3,
          lastStudyDate: DateTime.parse('2026-04-24'),
        ),
        'jin': UserProfile(
          username: 'jin',
          email: 'jin@study.local',
          emailVerified: true,
          xp: 45,
          level: 2,
          coins: 180,
          tasks: <StudyTask>[
            StudyTask.fromDifficulty(
              'Solve a practice problem set',
              TaskDifficulty.medium,
            ),
          ],
          totalCompletedTasks: 2,
          customRewards: <RewardItem>[],
          rewardHistory: <RewardRedemption>[],
          initialXp: 0,
          initialLevel: 0,
          initialCoins: 0,
          trackingInitialized: false,
          dailyTaskGoal: 2,
          weeklyXpGoal: 350,
          targetLevel: 4,
          currentStreak: 1,
          longestStreak: 1,
          lastStudyDate: DateTime.parse('2026-04-24'),
        ),
      });

    _passwords
      ..clear()
      ..addAll(<String, String>{'md': '1234', 'arya': '1234', 'jin': '1234'});

    await _persistUsers();
    await _persistProfileImages();
    await _persistPasswords();
    await _persistRooms();
  }

  void _loadUsers() {
    final encoded = _prefs?.getString(_usersKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    _users
      ..clear()
      ..addEntries(
        decoded.entries.map((entry) {
          return MapEntry(
            entry.key,
            UserProfile.fromJson(Map<String, dynamic>.from(entry.value as Map)),
          );
        }),
      );
  }

  void _loadPasswords() {
    final encoded = _prefs?.getString(_passwordsKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    _passwords
      ..clear()
      ..addEntries(
        decoded.entries.map(
          (entry) => MapEntry(entry.key, entry.value.toString()),
        ),
      );
  }

  void _loadProfileImages() {
    final encoded = _prefs?.getString(_profileImagesKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      _profileImages
        ..clear()
        ..addEntries(
          decoded.entries
              .map(
                (entry) => MapEntry(entry.key, entry.value.toString().trim()),
              )
              .where((entry) => entry.value.isNotEmpty),
        );
    } on FormatException {
      _profileImages.clear();
    }
  }

  Future<void> _syncProfileImageStorage() async {
    var changed = false;

    for (final entry in _users.entries) {
      final username = entry.key;
      final user = entry.value;
      final embeddedImage = user.profileImageBase64;
      final storedImage = _profileImages[username];

      if (storedImage != null && storedImage.trim().isNotEmpty) {
        if (user.profileImageBase64 != storedImage) {
          user.profileImageBase64 = storedImage;
          changed = true;
        }
        continue;
      }

      if (embeddedImage != null && embeddedImage.trim().isNotEmpty) {
        _profileImages[username] = embeddedImage;
        changed = true;
      }
    }

    if (changed) {
      await _persistProfileImages();
      await _persistUsers();
    }
  }

  void _loadRooms() {
    final encoded = _prefs?.getString(_roomsKey);
    if (encoded == null || encoded.isEmpty) {
      return;
    }

    final decoded = jsonDecode(encoded) as Map<String, dynamic>;
    _rooms
      ..clear()
      ..addEntries(
        decoded.entries.map((entry) {
          return MapEntry(
            entry.key,
            MultiplayerRoom.fromJson(
              Map<String, dynamic>.from(entry.value as Map),
            ),
          );
        }),
      );
  }

  Future<void> _persistUsers() async {
    await _prefs?.setString(
      _usersKey,
      jsonEncode(<String, dynamic>{
        for (final entry in _users.entries)
          entry.key: _userJsonWithoutProfileImage(entry.value),
      }),
    );
  }

  Map<String, dynamic> _userJsonWithoutProfileImage(UserProfile user) {
    final json = user.toJson();
    json.remove('profileImageBase64');
    return json;
  }

  Future<void> _persistProfileImages() async {
    await _prefs?.setString(_profileImagesKey, jsonEncode(_profileImages));
  }

  Future<void> _persistPasswords() async {
    await _prefs?.setString(_passwordsKey, jsonEncode(_passwords));
  }

  Future<void> _persistRooms() async {
    await _prefs?.setString(
      _roomsKey,
      jsonEncode(<String, dynamic>{
        for (final entry in _rooms.entries) entry.key: entry.value.toJson(),
      }),
    );
  }

  String? loadActiveUsername() {
    final username = _prefs?.getString(_activeUsernameKey)?.trim();
    return username == null || username.isEmpty ? null : username;
  }

  Future<void> saveActiveUsername(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      await _prefs?.remove(_activeUsernameKey);
      return;
    }

    await _prefs?.setString(_activeUsernameKey, normalized);
  }

  Future<void> clearActiveSession() async {
    await _prefs?.remove(_activeUsernameKey);
    await _prefs?.remove(_lastLocationKey);
  }

  Map<String, dynamic>? loadLastLocation() {
    final encoded = _prefs?.getString(_lastLocationKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  Future<void> saveLastLocation({
    required String routeName,
    Map<String, dynamic> arguments = const <String, dynamic>{},
  }) async {
    final normalizedRoute = routeName.trim();
    if (normalizedRoute.isEmpty) {
      await _prefs?.remove(_lastLocationKey);
      _lastLocationSignature = null;
      return;
    }

    final signature = jsonEncode(<String, dynamic>{
      'routeName': normalizedRoute,
      'arguments': arguments,
    });

    if (_lastLocationSignature == signature) {
      return;
    }

    final previousLocation = loadLastLocation();
    if (previousLocation != null &&
        previousLocation['routeName'] == normalizedRoute &&
        _jsonSignature(previousLocation['arguments']) ==
            _jsonSignature(arguments)) {
      _lastLocationSignature = signature;
      return;
    }

    await _prefs?.setString(
      _lastLocationKey,
      jsonEncode(<String, dynamic>{
        'routeName': normalizedRoute,
        'arguments': arguments,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
    _lastLocationSignature = signature;
  }

  Future<void> clearLastLocation() async {
    await _prefs?.remove(_lastLocationKey);
    _lastLocationSignature = null;
  }

  String _jsonSignature(Object? value) {
    return jsonEncode(value ?? const <String, dynamic>{});
  }

  Future<UserProfile?> loadRemoteUserByUid(String uid) async {
    final safeUid = uid.trim();
    if (safeUid.isEmpty) {
      return null;
    }

    final snapshot = await _database.child('users_by_uid/$safeUid').get();
    final data = _snapshotMap(snapshot.value);
    if (data == null) {
      return null;
    }

    return UserProfile.fromJson(data).copy();
  }

  Future<void> saveRemoteUserByUid(String uid, UserProfile user) async {
    final safeUid = uid.trim();
    if (safeUid.isEmpty) {
      return;
    }

    await _database.child('users_by_uid/$safeUid').set(user.toJson());
  }

  Future<RemoteUsernameRecord?> loadRemoteUsernameRecord(
    String username,
  ) async {
    final key = _usernameDatabaseKey(username);
    if (key.isEmpty) {
      return null;
    }

    final snapshot = await _database.child('usernames/$key').get();
    final data = _snapshotMap(snapshot.value);
    if (data == null) {
      return null;
    }

    return RemoteUsernameRecord.fromJson(data);
  }

  Future<bool> remoteUsernameExists(String username) async {
    final record = await loadRemoteUsernameRecord(username);
    return record != null;
  }

  Future<bool> remoteEmailExists(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    final snapshot = await _database
        .child('emails/${_emailDatabaseKey(normalizedEmail)}')
        .get();
    return snapshot.exists && snapshot.value != null;
  }

  Future<void> saveRemoteUsernameRecord({
    required String username,
    required String email,
    required String uid,
  }) async {
    final normalizedUsername = username.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final safeUid = uid.trim();
    final usernameKey = _usernameDatabaseKey(normalizedUsername);
    final emailKey = _emailDatabaseKey(normalizedEmail);

    if (usernameKey.isEmpty || emailKey.isEmpty || safeUid.isEmpty) {
      return;
    }

    final record = <String, dynamic>{
      'username': normalizedUsername,
      'email': normalizedEmail,
      'uid': safeUid,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _database.child('usernames/$usernameKey').set(record);
    await _database.child('emails/$emailKey').set(record);
  }

  Future<UserProfile?> loadUser(String username) async {
    final user = _users[username];
    return user == null ? null : _withStoredProfileImage(user).copy();
  }

  Future<UserProfile?> signIn(String username, String password) async {
    if (_passwords[username] != password) {
      return null;
    }

    final user = _users[username];
    return user == null ? null : _withStoredProfileImage(user).copy();
  }

  Future<UserProfile?> signUp(
    String username,
    String password, {
    required String email,
  }) async {
    if (_users.containsKey(username)) {
      return null;
    }

    if (emailExistsSync(email)) {
      return null;
    }

    final user = UserProfile.newUser(
      username,
      email: email.trim().toLowerCase(),
      emailVerified: true,
    );
    _users[username] = user;
    _passwords[username] = password;
    await _persistUsers();
    await _persistPasswords();
    return user.copy();
  }

  Future<void> saveUser(UserProfile user) async {
    final savedUser = user.copy();
    _syncStoredProfileImage(savedUser);
    _users[user.username] = savedUser;
    await _persistUsers();
    await _persistProfileImages();
  }

  void _syncStoredProfileImage(UserProfile user) {
    final profileImage = user.profileImageBase64;
    if (profileImage == null || profileImage.trim().isEmpty) {
      _profileImages.remove(user.username);
      return;
    }

    _profileImages[user.username] = profileImage;
  }

  UserProfile _withStoredProfileImage(UserProfile user) {
    final storedImage = _profileImages[user.username];
    if (storedImage == null || storedImage.trim().isEmpty) {
      return user;
    }

    if (user.profileImageBase64 == storedImage) {
      return user;
    }

    final copy = user.copy();
    copy.profileImageBase64 = storedImage;
    return copy;
  }

  Future<void> savePassword(String username, String password) async {
    _passwords[username] = password;
    await _persistPasswords();
  }

  Future<List<String>> loadUsernames() async {
    final usernames = _users.keys.toList()
      ..sort(
        (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
      );
    return usernames;
  }

  bool emailExistsSync(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    return _users.values.any(
      (user) => user.email.trim().toLowerCase() == normalizedEmail,
    );
  }

  Future<bool> emailExists(String email) async {
    return emailExistsSync(email);
  }

  Future<bool> emailMatchesUsername(String username, String email) async {
    final user = _users[username];
    if (user == null || !user.emailVerified) {
      return false;
    }

    return user.email.trim().toLowerCase() == email.trim().toLowerCase();
  }

  Future<bool> userExists(String username) async {
    return _passwords.containsKey(username);
  }

  Future<bool> verifyPassword(String username, String input) async {
    return _passwords[username] == input;
  }

  Future<List<UserProfile>> loadAllUsers() async {
    return _users.values
        .map((user) => _withStoredProfileImage(user).copy())
        .toList();
  }

  Future<List<LeaderboardEntry>> loadLeaderboardEntries() async {
    if (leaderboardService.isRemoteEnabled) {
      final entries = await leaderboardService.loadEntries();
      _sortLeaderboard(entries);
      return entries;
    }

    return loadLocalLeaderboardEntries();
  }

  Future<List<LeaderboardEntry>> loadLocalLeaderboardEntries() async {
    final entries = _users.values
        .map(
          (user) => LeaderboardEntry(
            username: user.username,
            level: user.level,
            xp: user.xp,
            completedTasks: user.totalCompletedTasks,
            profileImageBase64: user.profileImageBase64,
          ),
        )
        .toList();

    _sortLeaderboard(entries);
    return entries;
  }

  Future<void> submitLeaderboardEntry(UserProfile user) async {
    if (!leaderboardService.isRemoteEnabled) {
      return;
    }

    await leaderboardService.submitEntry(
      LeaderboardEntry(
        username: user.username,
        level: user.level,
        xp: user.xp,
        completedTasks: user.totalCompletedTasks,
        profileImageBase64: user.profileImageBase64,
      ),
    );
  }

  Map<String, dynamic>? _snapshotMap(Object? value) {
    if (value is Map) {
      final converted = <String, dynamic>{};
      value.forEach((dynamic key, dynamic mapValue) {
        converted[key.toString()] = mapValue;
      });
      return converted;
    }

    return null;
  }

  String _usernameDatabaseKey(String username) {
    final normalized = username.trim().toLowerCase();
    return normalized.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
  }

  String _emailDatabaseKey(String email) {
    final normalized = email.trim().toLowerCase();
    return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
  }

  void _sortLeaderboard(List<LeaderboardEntry> entries) {
    entries.sort((left, right) {
      if (right.level != left.level) {
        return right.level.compareTo(left.level);
      }
      if (right.xp != left.xp) {
        return right.xp.compareTo(left.xp);
      }
      return right.completedTasks.compareTo(left.completedTasks);
    });
  }

  Future<MultiplayerRoom?> createRoom({
    required String roomId,
    required int maxPlayers,
    required UserProfile creator,
    required bool competitiveTimer,
    required int timerMinutes,
  }) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return null;
    }

    if (_rooms.containsKey(normalizedRoomId)) {
      return null;
    }

    final roomRef = _remoteRoomRef(normalizedRoomId);
    final existingSnapshot = await roomRef.get().timeout(
      _firebaseOperationTimeout,
    );
    if (existingSnapshot.exists && existingSnapshot.value != null) {
      return null;
    }

    final now = DateTime.now();
    final playerLimit = MultiplayerRoom.clampPlayerCount(maxPlayers);
    final creatorKey = MultiplayerRoom.firebaseUserKey(creator.username);
    final roomCreator = _roomOnlyParticipant(creator);
    final room = MultiplayerRoom(
      roomId: normalizedRoomId,
      maxPlayers: playerLimit,
      creatorUsername: creator.username,
      createdAt: now,
      competitiveTimer: competitiveTimer,
      timerMinutes: timerMinutes,
      participants: <UserProfile>[roomCreator],
      initialCompletedTasks: <String, int>{creatorKey: 0},
      updatedAt: now,
    );

    await roomRef.set(room.toFirebaseJson()).timeout(_firebaseOperationTimeout);
    _rooms[normalizedRoomId] = room;
    await _persistRooms();
    return room.copy();
  }

  Future<MultiplayerRoom?> createUniqueRoom({
    required int maxPlayers,
    required UserProfile creator,
    required bool competitiveTimer,
    required int timerMinutes,
  }) async {
    for (int attempt = 0; attempt < 12; attempt++) {
      final room = await createRoom(
        roomId: generateRoomId(),
        maxPlayers: maxPlayers,
        creator: creator,
        competitiveTimer: competitiveTimer,
        timerMinutes: timerMinutes,
      );

      if (room != null) {
        return room;
      }
    }

    return null;
  }

  Future<MultiplayerRoom?> joinRoom({
    required String roomId,
    required UserProfile user,
    bool forceJoin = false,
  }) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return null;
    }

    final roomRef = _remoteRoomRef(normalizedRoomId);
    final snapshot = await roomRef.get().timeout(_firebaseOperationTimeout);
    final data = _snapshotMap(snapshot.value);

    MultiplayerRoom? room;
    if (data != null) {
      room = MultiplayerRoom.fromJson(data);
    } else {
      room = _rooms[normalizedRoomId];
    }

    if (room == null) {
      return null;
    }

    final alreadyJoined = room.participants.any(
      (participant) => participant.username == user.username,
    );
    if (room.isFull && !alreadyJoined && !forceJoin) {
      return null;
    }

    final participantKey = MultiplayerRoom.firebaseUserKey(user.username);
    final roomParticipant = _roomOnlyParticipant(user);
    if (!alreadyJoined) {
      await roomRef
          .child('participants/$participantKey')
          .set(roomParticipant.toJson())
          .timeout(_firebaseOperationTimeout);
    }

    if (!room.initialCompletedTasks.containsKey(participantKey)) {
      await roomRef
          .child('initialCompletedTasks/$participantKey')
          .set(0)
          .timeout(_firebaseOperationTimeout);
    }

    await roomRef
        .child('updatedAt')
        .set(DateTime.now().toIso8601String())
        .timeout(_firebaseOperationTimeout);

    final localParticipants =
        room.participants
            .where((participant) => participant.username != user.username)
            .map((participant) => participant.copy())
            .toList()
          ..add(
            alreadyJoined
                ? room.participants
                      .firstWhere(
                        (participant) => participant.username == user.username,
                      )
                      .copy()
                : roomParticipant.copy(),
          );
    final localInitialCompletedTasks = Map<String, int>.from(
      room.initialCompletedTasks,
    )..putIfAbsent(participantKey, () => 0);
    final updatedRoom = MultiplayerRoom(
      roomId: room.roomId,
      maxPlayers: room.maxPlayers,
      creatorUsername: room.creatorUsername,
      createdAt: room.createdAt,
      competitiveTimer: room.competitiveTimer,
      timerMinutes: room.timerMinutes,
      participants: localParticipants,
      initialCompletedTasks: localInitialCompletedTasks,
      updatedAt: DateTime.now(),
    );

    _rooms[normalizedRoomId] = updatedRoom;
    await _persistRooms();

    try {
      final latest = await loadRoom(normalizedRoomId);
      return latest ?? updatedRoom.copy();
    } catch (_) {
      return updatedRoom.copy();
    }
  }

  Future<MultiplayerRoom?> loadRoom(String roomId) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return null;
    }

    final snapshot = await _remoteRoomRef(
      normalizedRoomId,
    ).get().timeout(_firebaseOperationTimeout);
    final data = _snapshotMap(snapshot.value);
    if (data == null) {
      return _rooms[normalizedRoomId]?.copy();
    }

    final room = MultiplayerRoom.fromJson(data);
    _rooms[normalizedRoomId] = room;
    await _persistRooms();
    return room.copy();
  }

  Future<MultiplayerRoom?> loadCachedRoom(String roomId) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return null;
    }

    return _rooms[normalizedRoomId]?.copy();
  }

  Future<void> saveCachedRoom(MultiplayerRoom room) async {
    final normalizedRoomId = _normalizeRoomId(room.roomId);
    if (normalizedRoomId.isEmpty) {
      return;
    }

    _rooms[normalizedRoomId] = room.copy();
    await _persistRooms();
  }

  Future<void> removeCachedRoom(String roomId) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return;
    }

    _rooms.remove(normalizedRoomId);
    await _persistRooms();
  }

  Stream<MultiplayerRoom?> watchRoom(String roomId) {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return const Stream<MultiplayerRoom?>.empty();
    }

    return _remoteRoomRef(normalizedRoomId).onValue.map((event) {
      final data = _snapshotMap(event.snapshot.value);
      if (data == null) {
        _rooms.remove(normalizedRoomId);
        unawaited(_persistRooms());
        return null;
      }

      final room = MultiplayerRoom.fromJson(data);
      _rooms[normalizedRoomId] = room;
      unawaited(_persistRooms());
      return room.copy();
    });
  }

  Future<void> updateRoomParticipant({
    required String roomId,
    required UserProfile participant,
  }) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return;
    }

    await _remoteRoomRef(normalizedRoomId)
        .child(
          'participants/${MultiplayerRoom.firebaseUserKey(participant.username)}',
        )
        .set(participant.toJson())
        .timeout(_firebaseOperationTimeout);
    await _remoteRoomRef(normalizedRoomId)
        .child('updatedAt')
        .set(DateTime.now().toIso8601String())
        .timeout(_firebaseOperationTimeout);

    final localRoom = _rooms[normalizedRoomId];
    if (localRoom == null) {
      return;
    }

    final updatedParticipants =
        localRoom.participants
            .where((user) => user.username != participant.username)
            .map((user) => user.copy())
            .toList()
          ..add(participant.copy());

    _rooms[normalizedRoomId] = MultiplayerRoom(
      roomId: localRoom.roomId,
      maxPlayers: localRoom.maxPlayers,
      creatorUsername: localRoom.creatorUsername,
      createdAt: localRoom.createdAt,
      competitiveTimer: localRoom.competitiveTimer,
      timerMinutes: localRoom.timerMinutes,
      participants: updatedParticipants,
      initialCompletedTasks: Map<String, int>.from(
        localRoom.initialCompletedTasks,
      ),
      updatedAt: DateTime.now(),
    );
    await _persistRooms();
  }

  Future<void> leaveRoom(String roomId, String username) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return;
    }

    final room = await loadRoom(normalizedRoomId);
    final participantKey = MultiplayerRoom.firebaseUserKey(username);
    final roomRef = _remoteRoomRef(normalizedRoomId);

    if (room == null) {
      _rooms.remove(normalizedRoomId);
      await _persistRooms();
      return;
    }

    final remainingParticipants = room.participants
        .where((participant) => participant.username != username)
        .toList();
    final remainingInitialCompletedTasks = Map<String, int>.from(
      room.initialCompletedTasks,
    )..remove(participantKey);

    if (remainingParticipants.isEmpty || room.creatorUsername == username) {
      await roomRef.remove().timeout(_firebaseOperationTimeout);
      _rooms.remove(normalizedRoomId);
    } else {
      await roomRef
          .child('participants/$participantKey')
          .remove()
          .timeout(_firebaseOperationTimeout);
      await roomRef
          .child('updatedAt')
          .set(DateTime.now().toIso8601String())
          .timeout(_firebaseOperationTimeout);
      _rooms[normalizedRoomId] = MultiplayerRoom(
        roomId: room.roomId,
        maxPlayers: room.maxPlayers,
        creatorUsername: room.creatorUsername,
        createdAt: room.createdAt,
        competitiveTimer: room.competitiveTimer,
        timerMinutes: room.timerMinutes,
        participants: remainingParticipants,
        initialCompletedTasks: remainingInitialCompletedTasks,
        updatedAt: DateTime.now(),
      );
    }

    await _persistRooms();
  }

  Future<bool> deleteUserRooms(String username) async {
    final keysToRemove = _rooms.entries
        .where(
          (entry) =>
              entry.value.creatorUsername == username ||
              entry.value.participants.any(
                (participant) => participant.username == username,
              ),
        )
        .map((entry) => entry.key)
        .toList();

    if (keysToRemove.isEmpty) {
      return false;
    }

    for (final key in keysToRemove) {
      _rooms.remove(key);
    }

    await _persistRooms();
    return true;
  }

  Future<bool> roomExists(String roomId) async {
    final normalizedRoomId = _normalizeRoomId(roomId);
    if (normalizedRoomId.isEmpty) {
      return false;
    }

    final snapshot = await _remoteRoomRef(
      normalizedRoomId,
    ).get().timeout(_firebaseOperationTimeout);
    return snapshot.exists && snapshot.value != null;
  }

  Future<List<String>> usersInRoom(String roomId) async {
    final room = await loadRoom(roomId);
    return room?.participants
            .map((participant) => participant.username)
            .toList() ??
        <String>[];
  }

  String generateRoomId([int length = 6]) {
    const characters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List<String>.generate(
      length,
      (_) => characters[random.nextInt(characters.length)],
    ).join();
  }

  UserProfile _roomOnlyParticipant(UserProfile user) {
    final participant = user.copy();
    participant.tasks.clear();
    participant.totalCompletedTasks = 0;
    participant.initialXp = participant.xp;
    participant.initialLevel = participant.level;
    participant.initialCoins = participant.coins;
    participant.trackingInitialized = true;
    return participant;
  }

  DatabaseReference _remoteRoomRef(String roomId) {
    return _database.child('multiplayer_rooms/${_normalizeRoomId(roomId)}');
  }

  String _normalizeRoomId(String roomId) {
    return roomId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }
}

class RemoteUsernameRecord {
  const RemoteUsernameRecord({
    required this.username,
    required this.email,
    required this.uid,
  });

  factory RemoteUsernameRecord.fromJson(Map<String, dynamic> json) {
    return RemoteUsernameRecord(
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      uid: (json['uid'] ?? '').toString(),
    );
  }

  final String username;
  final String email;
  final String uid;
}
