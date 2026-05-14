import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/multiplayer_room.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/primary_button.dart';
import '../widgets/surface_card.dart';
import 'multiplayer_mode_selection_screen.dart';
import 'multiplayer_study_screen.dart';

class MultiplayerLoginScreen extends StatefulWidget {
  const MultiplayerLoginScreen({super.key, this.arguments});

  static const routeName = '/multiplayer-login';
  final MultiplayerLoginArgs? arguments;

  @override
  State<MultiplayerLoginScreen> createState() => _MultiplayerLoginScreenState();
}

enum _AwayRoomAction { create, join }

class _MultiplayerLoginScreenState extends State<MultiplayerLoginScreen> {
  static const Duration _roomActionTimeout = Duration(seconds: 18);

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _joinRoomController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<UserProfile> _players = <UserProfile>[];

  String _message = 'Player 1: sign in, use your account, or join as guest.';
  Color _messageColor = AppColors.textSecondary;
  bool _busy = false;
  bool _openingLocalSession = false;
  _AwayRoomAction? _awayRoomAction;
  late String _roomId;
  int _awayMaxPlayers = MultiplayerRoom.minAllowedPlayers;

  MultiplayerLoginArgs get _args =>
      widget.arguments ??
      const MultiplayerLoginArgs(
        maxPlayers: MultiplayerRoom.minAllowedPlayers,
        isAwayMode: false,
        competitiveTimerMode: false,
        timerMinutes: 30,
      );

  int get _maxPlayers => MultiplayerRoom.clampPlayerCount(_args.maxPlayers);

  int get _playerEntryLimit => _args.isAwayMode ? 1 : _maxPlayers;

  bool get _canAddPlayer =>
      !_busy && !_openingLocalSession && _players.length < _playerEntryLimit;

  @override
  void initState() {
    super.initState();
    _roomId = '';

    if (widget.arguments?.isAwayMode ?? false) {
      _message = 'Choose CREATE ROOM or JOIN ROOM.';
    }

    _awayMaxPlayers = MultiplayerRoom.clampPlayerCount(
      widget.arguments?.maxPlayers ?? MultiplayerRoom.minAllowedPlayers,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_roomId.isEmpty) {
      if (_args.roomId != null && _args.roomId!.trim().isNotEmpty) {
        _roomId = _args.roomId!;
      } else if (!_args.isAwayMode) {
        _roomId = AppScope.of(context).repository.generateRoomId();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _joinRoomController.dispose();
    super.dispose();
  }

  Future<void> _signInPlayer() async {
    if (!_canAddPlayer) {
      setState(() {
        _message = _args.isAwayMode
            ? 'This device already has an online player.'
            : 'Room is full.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _message = 'Verifying player...';
      _messageColor = Colors.orange;
      _busy = true;
    });

    final repo = AppScope.of(context).repository;
    final player = await repo.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (player == null) {
      setState(() {
        _message = 'Invalid username or password.';
        _messageColor = AppColors.error;
        _busy = false;
      });
      return;
    }

    _addPlayer(player);
    if (mounted && !_openingLocalSession) {
      setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGooglePlayer() async {
    if (!_canAddPlayer) {
      setState(() {
        _message = _args.isAwayMode
            ? 'This device already has an online player.'
            : 'Room is full.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    setState(() {
      _message = 'Opening Google Sign-In...';
      _messageColor = Colors.orange;
      _busy = true;
    });

    final appState = AppScope.of(context);
    final result = await appState.signInWithGoogle(forceAccountSelection: true);

    if (!mounted) {
      return;
    }

    final player = result.user ?? appState.currentUser;

    if (result.success && player != null) {
      setState(() => _busy = false);
      _addPlayer(player.copy());
      return;
    }

    setState(() {
      _busy = false;
      _message = result.success
          ? 'Google Sign-In finished, but no player profile was found.'
          : result.message;
      _messageColor = AppColors.error;
    });
  }

  void _useCurrentAccount() {
    final currentUser = AppScope.of(context).currentUser;
    if (currentUser == null) {
      setState(() {
        _message =
            'No signed-in account was found. Sign in or continue as guest.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    _addPlayer(currentUser.copy());
  }

  Future<void> _continueAsGuest() async {
    if (!_canAddPlayer) {
      return;
    }

    final guestName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Guest Login'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Guest name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            PrimaryButton(
              label: 'JOIN',
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
            ),
          ],
        );
      },
    );

    if (!mounted || guestName == null || guestName.trim().isEmpty) {
      return;
    }

    _addPlayer(UserProfile.newUser(guestName.trim()));
  }

  void _addPlayer(UserProfile player) {
    if (_players.length >= _playerEntryLimit) {
      setState(() {
        _message = _args.isAwayMode
            ? 'This device already has an online player.'
            : 'Room is full.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    if (_players.any((existing) => existing.username == player.username)) {
      setState(() {
        _message = '${player.username} is already in the session.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    setState(() {
      _players.add(player);
      _usernameController.clear();
      _passwordController.clear();
      final readyCount = _players.length;
      _message = _args.isAwayMode
          ? 'Player $readyCount: ready.'
          : '$readyCount / $_maxPlayers players ready. ${readyCount == _maxPlayers ? 'Opening room...' : 'Room opens automatically when everyone is ready.'}';
      _messageColor = AppColors.success;
    });

    if (!_args.isAwayMode && _players.length == _maxPlayers) {
      _openingLocalSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openLocalSession();
        }
      });
    }
  }

  Future<UserProfile?> _ensureAwayPlayer() async {
    var currentUser = AppScope.of(context).currentUser;
    if (currentUser == null) {
      final signedIn = await showSignInRequiredDialog(
        context,
        featureName: 'Away Mode',
      );

      if (!signedIn || !mounted) {
        return null;
      }

      currentUser = AppScope.of(context).currentUser;
    }

    if (currentUser != null) {
      return currentUser.copy();
    }

    setState(() {
      _message = 'Please sign in to your account before using Away Mode.';
      _messageColor = AppColors.warning;
    });
    return null;
  }

  Future<void> _createAwayRoom() async {
    if (_busy) {
      return;
    }

    final player = await _ensureAwayPlayer();
    if (player == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Creating Firebase room...';
      _messageColor = Colors.orange;
    });

    final appState = AppScope.of(context);
    MultiplayerRoom? room;
    try {
      room = await appState
          .createRoomForPlayer(
            player: player,
            maxPlayers: _awayMaxPlayers,
            competitiveTimer: _args.competitiveTimerMode,
            timerMinutes: _args.timerMinutes,
          )
          .timeout(_roomActionTimeout);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showRoomActionError('Could not create a Firebase room', error);
      return;
    }

    if (!mounted) {
      return;
    }

    if (room == null) {
      setState(() {
        _busy = false;
        _message =
            'Could not create a Firebase room. Check your connection and database rules.';
        _messageColor = AppColors.error;
      });
      return;
    }

    final createdRoom = room;
    setState(() {
      _busy = false;
      _roomId = createdRoom.roomId;
      _message = 'Room ${createdRoom.roomId} created.';
      _messageColor = AppColors.success;
    });

    await _openAwaySession(createdRoom, player.username);
  }

  Future<void> _joinAwayRoom() async {
    if (_busy) {
      return;
    }

    final player = await _ensureAwayPlayer();
    if (player == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final roomCode = _joinRoomController.text.trim().toUpperCase();
    if (roomCode.isEmpty) {
      setState(() {
        _message = 'Enter the room code from your friend.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Joining Firebase room...';
      _messageColor = Colors.orange;
    });

    final appState = AppScope.of(context);
    MultiplayerRoom? room;
    try {
      room = await appState
          .joinRoomAs(roomId: roomCode, player: player)
          .timeout(_roomActionTimeout);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showRoomActionError('Could not join the Firebase room', error);
      return;
    }

    if (!mounted) {
      return;
    }

    if (room == null) {
      setState(() {
        _busy = false;
        _message =
            'Room not found or already full. Check the code and try again.';
        _messageColor = AppColors.error;
      });
      return;
    }

    final joinedRoom = room;
    setState(() {
      _busy = false;
      _roomId = joinedRoom.roomId;
      _message = 'Joined room ${joinedRoom.roomId}.';
      _messageColor = AppColors.success;
    });

    await _openAwaySession(joinedRoom, player.username);
  }

  Future<void> _openAwaySession(
    MultiplayerRoom room,
    String localUsername,
  ) async {
    final args = MultiplayerStudyArgs(
      users: room.participants.map((player) => player.username).toList(),
      isAwayMode: true,
      roomId: room.roomId,
      competitiveTimerMode: room.competitiveTimer,
      timerMinutes: room.timerMinutes,
      localUsername: localUsername,
    );

    try {
      await AppScope.of(context).rememberNavigation(
        MultiplayerStudyScreen.routeName,
        arguments: args.toJson(),
      );
    } catch (_) {
      // Navigation should continue even if the last-location cache is full.
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed('/multiplayer-study', arguments: args);
  }

  Future<void> _openLocalSession() async {
    if (_args.isAwayMode || _players.length != _maxPlayers) {
      _openingLocalSession = false;
      setState(() {
        _message =
            'Add exactly $_maxPlayers players before opening the session.';
        _messageColor = AppColors.warning;
      });
      return;
    }

    setState(() {
      _busy = true;
      _openingLocalSession = true;
      _message = 'Opening Home room...';
      _messageColor = Colors.orange;
    });

    late final MultiplayerStudyArgs args;

    try {
      final now = DateTime.now();
      final roomParticipants = _players
          .map((player) => _roomOnlyParticipant(player))
          .toList();
      final room = MultiplayerRoom(
        roomId: _roomId,
        maxPlayers: _maxPlayers,
        creatorUsername: roomParticipants.first.username,
        createdAt: now,
        competitiveTimer: _args.competitiveTimerMode,
        timerMinutes: _args.timerMinutes,
        participants: roomParticipants,
        initialCompletedTasks: <String, int>{
          for (final player in roomParticipants)
            MultiplayerRoom.firebaseUserKey(player.username): 0,
        },
        updatedAt: now,
      );

      final appState = AppScope.of(context);
      await appState.repository
          .saveCachedRoom(room)
          .timeout(_roomActionTimeout);

      args = MultiplayerStudyArgs(
        users: roomParticipants.map((player) => player.username).toList(),
        isAwayMode: false,
        roomId: _roomId,
        competitiveTimerMode: _args.competitiveTimerMode,
        timerMinutes: _args.timerMinutes,
        localUsername: roomParticipants.first.username,
      );

      await appState
          .rememberNavigation(
            MultiplayerStudyScreen.routeName,
            arguments: args.toJson(),
          )
          .timeout(_roomActionTimeout);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showRoomActionError('Could not open the Home room', error);
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamed('/multiplayer-study', arguments: args);
  }

  void _showRoomActionError(String action, Object error) {
    setState(() {
      _busy = false;
      _openingLocalSession = false;
      _message = '$action. ${_friendlyRoomError(error)}';
      _messageColor = AppColors.error;
    });
  }

  String _friendlyRoomError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();

    if (error is TimeoutException || lower.contains('timeout')) {
      return 'Firebase did not respond in time. Check your connection and try again.';
    }

    if (lower.contains('permission') || lower.contains('permission_denied')) {
      return 'Firebase Database permission denied. Deploy rules that allow read/write on /multiplayer_rooms/{roomCode}.';
    }

    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network request failed. Check your connection and try again.';
    }

    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Please try again.';
    }

    return trimmed.length > 180 ? '${trimmed.substring(0, 180)}...' : trimmed;
  }

  UserProfile _roomOnlyParticipant(UserProfile player) {
    final roomPlayer = player.copy();
    roomPlayer.tasks.clear();
    roomPlayer.totalCompletedTasks = 0;
    roomPlayer.initialXp = roomPlayer.xp;
    roomPlayer.initialLevel = roomPlayer.level;
    roomPlayer.initialCoins = roomPlayer.coins;
    roomPlayer.trackingInitialized = true;
    return roomPlayer;
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;

    if (args.isAwayMode) {
      return _buildAwayModeScreen();
    }

    return _buildLocalModeScreen();
  }

  Widget _buildAwayModeScreen() {
    return AppPageShell(
      title: 'ONLINE MULTIPLAYER',
      centerTitle: true,
      bodyPadding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: switch (_awayRoomAction) {
            _AwayRoomAction.create => _buildAwayCreateRoomCard(),
            _AwayRoomAction.join => _buildAwayJoinCodeCard(),
            null => _buildAwayActionCard(),
          },
        ),
      ),
    );
  }

  Widget _buildAwayActionCard() {
    final currentUser = AppScope.of(context).currentUser;

    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Text(
              'ONLINE ROOM',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'CREATE ROOM',
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _awayRoomAction = _AwayRoomAction.create;
                      _message = 'Select room members, then create your room.';
                      _messageColor = AppColors.textSecondary;
                    });
                  },
            backgroundColor: AppColors.success,
            hoverColor: AppColors.success,
            leading: const Icon(Icons.add_circle_outline),
            isExpanded: true,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'JOIN ROOM',
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _awayRoomAction = _AwayRoomAction.join;
                      _message = 'Enter the room code to join.';
                      _messageColor = AppColors.textSecondary;
                    });
                  },
            backgroundColor: AppColors.primaryDark,
            hoverColor: AppColors.primary,
            leading: const Icon(Icons.login_outlined),
            isExpanded: true,
          ),
          const SizedBox(height: 18),
          Text(
            currentUser == null
                ? 'Sign in to your account before creating or joining an online room.'
                : 'Using account: ${currentUser.username}',
            style: AppTextStyles.small.copyWith(
              color: currentUser == null
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentUser == null) ...<Widget>[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'LOGIN / SIGN UP',
              leading: const Icon(Icons.account_circle_outlined, size: 18),
              onPressed: _busy
                  ? null
                  : () => showSignInRequiredDialog(
                      context,
                      featureName: 'Away Mode',
                    ),
              isExpanded: true,
            ),
          ],
          if (_message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _message,
              style: AppTextStyles.body.copyWith(color: _messageColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAwayCreateRoomCard() {
    final currentUser = AppScope.of(context).currentUser;

    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Text(
              'CREATE ROOM',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'How many members can join this room?',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int>(
            initialValue: _awayMaxPlayers,
            decoration: const InputDecoration(labelText: 'ROOM MEMBERS'),
            items:
                <int>[
                      for (
                        int count = MultiplayerRoom.minAllowedPlayers;
                        count <= MultiplayerRoom.maxAllowedPlayers;
                        count++
                      )
                        count,
                    ]
                    .map(
                      (count) => DropdownMenuItem<int>(
                        value: count,
                        child: Text('$count members'),
                      ),
                    )
                    .toList(),
            onChanged: _busy
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _awayMaxPlayers = MultiplayerRoom.clampPlayerCount(value);
                    });
                  },
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _busy ? 'CREATING ROOM...' : 'CREATE ROOM',
            onPressed: _busy ? null : _createAwayRoom,
            backgroundColor: AppColors.success,
            hoverColor: AppColors.success,
            leading: const Icon(Icons.add_circle_outline),
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _awayRoomAction = null;
                      _message = 'Choose CREATE ROOM or JOIN ROOM.';
                      _messageColor = AppColors.textSecondary;
                    });
                  },
            icon: const Icon(Icons.arrow_back),
            label: const Text('BACK TO CREATE / JOIN'),
          ),
          const SizedBox(height: 12),
          Text(
            currentUser == null
                ? 'Sign in to your account before creating an online room.'
                : 'Creating as: ${currentUser.username}',
            style: AppTextStyles.small.copyWith(
              color: currentUser == null
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentUser == null) ...<Widget>[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'LOGIN / SIGN UP',
              leading: const Icon(Icons.account_circle_outlined, size: 18),
              onPressed: _busy
                  ? null
                  : () => showSignInRequiredDialog(
                      context,
                      featureName: 'Away Mode',
                    ),
              isExpanded: true,
            ),
          ],
          if (_message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _message,
              style: AppTextStyles.body.copyWith(color: _messageColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAwayJoinCodeCard() {
    final currentUser = AppScope.of(context).currentUser;

    return SurfaceCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Center(
            child: Text(
              'JOIN ROOM',
              style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _joinRoomController,
            enabled: !_busy,
            textAlign: TextAlign.center,
            style: AppTextStyles.subheader.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0,
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: const InputDecoration(
              labelText: 'ROOM CODE',
              hintText: 'Example: AB12CD',
            ),
            onSubmitted: (_) => _joinAwayRoom(),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: _busy ? 'JOINING ROOM...' : 'JOIN ROOM',
            onPressed: _busy ? null : _joinAwayRoom,
            isExpanded: true,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _awayRoomAction = null;
                      _message = 'Choose CREATE ROOM or JOIN ROOM.';
                      _messageColor = AppColors.textSecondary;
                    });
                  },
            icon: const Icon(Icons.arrow_back),
            label: const Text('BACK TO CREATE / JOIN'),
          ),
          const SizedBox(height: 12),
          Text(
            currentUser == null
                ? 'Sign in to your account before joining an online room.'
                : 'Joining as: ${currentUser.username}',
            style: AppTextStyles.small.copyWith(
              color: currentUser == null
                  ? AppColors.warning
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (currentUser == null) ...<Widget>[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'LOGIN / SIGN UP',
              leading: const Icon(Icons.account_circle_outlined, size: 18),
              onPressed: _busy
                  ? null
                  : () => showSignInRequiredDialog(
                      context,
                      featureName: 'Away Mode',
                    ),
              isExpanded: true,
            ),
          ],
          if (_message.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _message,
              style: AppTextStyles.body.copyWith(color: _messageColor),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalModeScreen() {
    final currentUser = AppScope.of(context).currentUser;
    final int playerEntryLimit = _playerEntryLimit;

    return AppPageShell(
      title: 'LOCAL MULTIPLAYER',
      centerTitle: true,
      bodyPadding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SurfaceCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Text(
                      'PLAYER LOGIN',
                      style: AppTextStyles.subheader.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (currentUser != null) ...<Widget>[
                    PrimaryButton(
                      label: 'USE MY ACCOUNT (${currentUser.username})',
                      onPressed: _canAddPlayer ? _useCurrentAccount : null,
                      backgroundColor: AppColors.primaryDark,
                      hoverColor: AppColors.primary,
                      isExpanded: true,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MultiplayerGoogleSignInButton(
                    isBusy: _busy,
                    onPressed: _canAddPlayer ? _continueWithGooglePlayer : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or username / guest',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameController,
                    enabled: !_busy,
                    decoration: const InputDecoration(labelText: 'USERNAME'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Enter a username.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'PASSWORD'),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Enter a password.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: PrimaryButton(
                          label: 'SIGN IN',
                          onPressed: _canAddPlayer ? _signInPlayer : null,
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'CONTINUE AS GUEST',
                          onPressed: _canAddPlayer ? _continueAsGuest : null,
                          backgroundColor: AppColors.primaryDark,
                          hoverColor: AppColors.primary,
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _message,
                    style: AppTextStyles.body.copyWith(color: _messageColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'PLAYERS ${_players.length} / $playerEntryLimit',
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _players
                        .map(
                          (player) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.primaryLight),
                            ),
                            child: Text(
                              player.username,
                              style: AppTextStyles.small.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  if (_args.competitiveTimerMode)
                    Text(
                      'Timer: ${_args.timerMinutes} minutes',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 14),
                  Text(
                    _players.length == _maxPlayers
                        ? 'All players are ready. Opening the room now.'
                        : 'The Home room starts automatically after $_maxPlayers players join.',
                    style: AppTextStyles.small.copyWith(
                      color: _players.length == _maxPlayers
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MultiplayerGoogleSignInButton extends StatelessWidget {
  const _MultiplayerGoogleSignInButton({
    required this.isBusy,
    required this.onPressed,
  });

  final bool isBusy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !isBusy;

    return Opacity(
      opacity: enabled || isBusy ? 1 : 0.6,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFF9AA0A6), width: 1.2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            splashColor: const Color(0x14202124),
            highlightColor: const Color(0x0A202124),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (isBusy) ...<Widget>[
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3C4043),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                  ] else ...<Widget>[
                    const SizedBox(
                      width: 30,
                      height: 30,
                      child: CustomPaint(painter: _GoogleLogoPainter()),
                    ),
                    const SizedBox(width: 18),
                  ],
                  const Flexible(
                    child: Text(
                      'Continue with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF3C4043),
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.16;
    final double radius = size.width * 0.33;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.05 * math.pi, 0.50 * math.pi, false, paint);

    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.45 * math.pi, 0.50 * math.pi, false, paint);

    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 0.95 * math.pi, 0.40 * math.pi, false, paint);

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, 1.35 * math.pi, 0.60 * math.pi, false, paint);

    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final double y = center.dy + size.height * 0.02;
    canvas.drawLine(
      Offset(center.dx, y),
      Offset(size.width * 0.83, y),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
