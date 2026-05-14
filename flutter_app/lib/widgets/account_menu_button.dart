import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';
import 'surface_card.dart';

Future<bool> showAccountAuthDialog(
  BuildContext context, {
  String title = 'Login / Sign Up',
  String? message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _AccountAuthDialog(title: title, message: message);
    },
  );

  return result ?? false;
}

Future<bool> showSignInRequiredDialog(
  BuildContext context, {
  required String featureName,
}) async {
  final shouldOpenLogin = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Sign In Required'),
        content: Text(
          '$featureName needs an account so your progress can be saved and synced.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('CANCEL'),
          ),
          PrimaryButton(
            label: 'LOGIN / SIGN UP',
            leading: const Icon(Icons.account_circle_outlined, size: 18),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ],
      );
    },
  );

  if (shouldOpenLogin != true || !context.mounted) {
    return false;
  }

  return showAccountAuthDialog(
    context,
    message: 'Sign in to continue with $featureName.',
  );
}

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser;

    if (user == null || appState.isGuestSession) {
      return Tooltip(
        message: 'Login or create an account',
        child: _AccountPillButton(
          icon: Icons.account_circle_outlined,
          label: 'Login / Sign Up',
          onTap: () => showAccountAuthDialog(context),
        ),
      );
    }

    return Tooltip(
      message: 'Account menu',
      child: _SignedInAccountButton(user: user),
    );
  }
}

class _SignedInAccountButton extends StatelessWidget {
  const _SignedInAccountButton({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAccountMenu(context, user),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
          decoration: BoxDecoration(
            color: AppColors.cardElevated.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _AccountAvatar(user: user, size: 32),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  user.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAccountMenu(BuildContext context, UserProfile user) async {
    final appState = AppScope.of(context);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SurfaceCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              radius: 16,
              borderColor: AppColors.accent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _AccountAvatar(user: user, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              user.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subheader.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (user.email.trim().isNotEmpty)
                              Text(
                                user.email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Upload Photo',
                    leading: const Icon(Icons.upload_rounded, size: 18),
                    isExpanded: true,
                    backgroundColor: AppColors.primaryDark,
                    hoverColor: AppColors.primary,
                    onPressed: () async {
                      await _pickImage(context, appState);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                  if (user.profileImageBase64 != null) ...<Widget>[
                    const SizedBox(height: 10),
                    PrimaryButton(
                      label: 'Remove Photo',
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      isExpanded: true,
                      backgroundColor: AppColors.cardElevated,
                      hoverColor: AppColors.error,
                      onPressed: () async {
                        final synced = await appState
                            .updateCurrentUserProfilePicture(null);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                synced
                                    ? 'Profile picture removed.'
                                    : 'Could not remove this profile picture.',
                              ),
                            ),
                          );
                        }
                        if (sheetContext.mounted) {
                          Navigator.of(sheetContext).pop();
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Sign Out',
                    leading: const Icon(Icons.logout_rounded, size: 18),
                    isExpanded: true,
                    backgroundColor: AppColors.error,
                    hoverColor: AppColors.error,
                    onPressed: () async {
                      await appState.signOut();
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Signed out.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, AppState appState) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read that image.')),
        );
      }
      return;
    }

    final resizedBytes = await _resizeProfileImage(bytes);
    final synced = await appState.updateCurrentUserProfilePicture(
      base64Encode(resizedBytes),
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            synced
                ? 'Profile picture saved.'
                : 'Could not save this profile picture. Please log in first.',
          ),
        ),
      );
    }
  }

  Future<Uint8List> _resizeProfileImage(Uint8List bytes) async {
    const maxSize = 192;

    try {
      final probeCodec = await ui.instantiateImageCodec(bytes);
      final probeFrame = await probeCodec.getNextFrame();
      final sourceImage = probeFrame.image;
      final width = sourceImage.width;
      final height = sourceImage.height;
      sourceImage.dispose();

      final longestSide = math.max(width, height);
      final scale = longestSide <= maxSize ? 1.0 : maxSize / longestSide;
      final targetWidth = math.max(1, (width * scale).round());
      final targetHeight = math.max(1, (height * scale).round());

      final resizedCodec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      final resizedFrame = await resizedCodec.getNextFrame();
      final resizedImage = resizedFrame.image;
      final byteData = await resizedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      resizedImage.dispose();

      return byteData?.buffer.asUint8List() ?? bytes;
    } catch (_) {
      return bytes;
    }
  }
}

class _AccountPillButton extends StatefulWidget {
  const _AccountPillButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_AccountPillButton> createState() => _AccountPillButtonState();
}

class _AccountPillButtonState extends State<_AccountPillButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        onHover: (value) => setState(() => _hovered = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.cardElevated.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.accentBright
                  : AppColors.accent.withValues(alpha: 0.55),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: _hovered ? 0.22 : 0.12,
                ),
                blurRadius: _hovered ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, color: AppColors.accentBright, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AuthMode { login, signUp }

class _AccountAuthDialog extends StatefulWidget {
  const _AccountAuthDialog({required this.title, this.message});

  final String title;
  final String? message;

  @override
  State<_AccountAuthDialog> createState() => _AccountAuthDialogState();
}

class _AccountAuthDialogState extends State<_AccountAuthDialog> {
  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signUpUsernameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _busy = false;
  bool _obscureLoginPassword = true;
  bool _obscureSignUpPassword = true;
  String _message = ' ';
  Color _messageColor = AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _message = widget.message ?? ' ';
  }

  @override
  void dispose() {
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _signUpUsernameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmController.dispose();
    super.dispose();
  }

  Future<void> _submitGoogleLogin() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Opening Google Sign-In...';
      _messageColor = AppColors.warning;
    });

    final result = await AppScope.of(context).signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _message = result.message;
      _messageColor = AppColors.error;
    });
  }

  Future<void> _submitLogin() async {
    if (_busy || !(_loginFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Logging in...';
      _messageColor = AppColors.warning;
    });

    final result = await AppScope.of(context).signIn(
      _loginUsernameController.text.trim(),
      _loginPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _message = result.message;
      _messageColor = AppColors.error;
    });
  }

  Future<void> _submitSignUp() async {
    if (_busy || !(_signUpFormKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _busy = true;
      _message = 'Creating account...';
      _messageColor = AppColors.warning;
    });

    final result = await AppScope.of(context).createAccountWithEmailPassword(
      username: _signUpUsernameController.text,
      email: _signUpEmailController.text,
      password: _signUpPasswordController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _busy = false;
      _message = result.message;
      _messageColor = AppColors.error;
    });
  }

  Future<void> _showForgotPasswordDialog() async {
    final appState = AppScope.of(context);
    final usernameController = TextEditingController(
      text: _loginUsernameController.text.trim(),
    );
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool sending = false;
    String inlineMessage = 'Enter the email linked to this username.';
    Color inlineColor = AppColors.textSecondary;

    final result = await showDialog<AuthResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_search_outlined),
                          labelText: 'USERNAME',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Enter your username.'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                          labelText: 'EMAIL',
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        inlineMessage,
                        style: AppTextStyles.small.copyWith(color: inlineColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                PrimaryButton(
                  label: sending ? 'SENDING...' : 'SEND RESET EMAIL',
                  onPressed: sending
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          setDialogState(() {
                            sending = true;
                            inlineMessage = 'Sending reset email...';
                            inlineColor = AppColors.warning;
                          });

                          final resetResult = await appState
                              .sendPasswordResetEmailForUsername(
                                username: usernameController.text,
                                email: emailController.text,
                              );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          if (resetResult.success) {
                            Navigator.of(dialogContext).pop(resetResult);
                            return;
                          }

                          setDialogState(() {
                            sending = false;
                            inlineMessage = resetResult.message;
                            inlineColor = AppColors.error;
                          });
                        },
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    final recoveredUsername = usernameController.text.trim();
    usernameController.dispose();
    emailController.dispose();

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _loginUsernameController.text = recoveredUsername;
      _loginPasswordController.clear();
      _message = result.message;
      _messageColor = result.success ? AppColors.success : AppColors.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBusy = AppScope.of(context).isBusy;
    final busy = _busy || appBusy;
    final dialogWidth = math.min(
      560.0,
      math.max(340.0, MediaQuery.sizeOf(context).width - 48.0),
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 2),
              _GoogleAuthButton(isBusy: busy, onPressed: _submitGoogleLogin),
              const SizedBox(height: 16),
              _AuthModeSwitcher(
                mode: _mode,
                onChanged: busy
                    ? null
                    : (mode) {
                        setState(() {
                          _mode = mode;
                          _message = widget.message ?? ' ';
                          _messageColor = AppColors.textSecondary;
                        });
                      },
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: _mode == _AuthMode.login
                    ? _buildLoginForm(busy)
                    : _buildSignUpForm(busy),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: Text(
                  _message,
                  key: ValueKey<String>(_message),
                  style: AppTextStyles.body.copyWith(color: _messageColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool busy) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey<String>('login-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _loginUsernameController,
            enabled: !busy,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
              labelText: 'USERNAME',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a username.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _loginPasswordController,
            enabled: !busy,
            obscureText: _obscureLoginPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitLogin(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: 'PASSWORD',
              suffixIcon: IconButton(
                tooltip: _obscureLoginPassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          _obscureLoginPassword = !_obscureLoginPassword;
                        });
                      },
                icon: Icon(
                  _obscureLoginPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter a password.' : null,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy ? null : _showForgotPasswordDialog,
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: busy ? 'WORKING...' : 'LOGIN',
            leading: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.login_rounded, size: 18),
            onPressed: busy ? null : _submitLogin,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(bool busy) {
    return Form(
      key: _signUpFormKey,
      child: Column(
        key: const ValueKey<String>('sign-up-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            controller: _signUpUsernameController,
            enabled: !busy,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_add_alt_1_outlined),
              labelText: 'USERNAME',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Enter a username.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signUpEmailController,
            enabled: !busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.alternate_email_rounded),
              labelText: 'EMAIL',
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signUpPasswordController,
            enabled: !busy,
            obscureText: _obscureSignUpPassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              labelText: 'PASSWORD',
              suffixIcon: IconButton(
                tooltip: _obscureSignUpPassword
                    ? 'Show password'
                    : 'Hide password',
                onPressed: busy
                    ? null
                    : () {
                        setState(() {
                          _obscureSignUpPassword = !_obscureSignUpPassword;
                        });
                      },
                icon: Icon(
                  _obscureSignUpPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter a password.';
              }
              if (value.length < 6) {
                return 'Use at least 6 characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signUpConfirmController,
            enabled: !busy,
            obscureText: _obscureSignUpPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitSignUp(),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.lock_reset_outlined),
              labelText: 'CONFIRM PASSWORD',
            ),
            validator: (value) => value != _signUpPasswordController.text
                ? 'Passwords do not match.'
                : null,
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: busy ? 'CREATING...' : 'CREATE ACCOUNT',
            leading: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.person_add_alt_1_rounded, size: 18),
            onPressed: busy ? null : _submitSignUp,
            isExpanded: true,
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Enter an email.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email.';
    }

    return null;
  }
}

class _AuthModeSwitcher extends StatelessWidget {
  const _AuthModeSwitcher({required this.mode, required this.onChanged});

  final _AuthMode mode;
  final ValueChanged<_AuthMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ModeButton(
              label: 'Login',
              selected: mode == _AuthMode.login,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_AuthMode.login),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeButton(
              label: 'Sign Up',
              selected: mode == _AuthMode.signUp,
              onTap: onChanged == null
                  ? null
                  : () => onChanged!(_AuthMode.signUp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? AppColors.accentBright : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleAuthButton extends StatelessWidget {
  const _GoogleAuthButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isBusy ? 0.7 : 1,
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF9AA0A6), width: 1.1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: isBusy ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (isBusy)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF3C4043),
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CustomPaint(painter: _GoogleLogoPainter()),
                    ),
                  const SizedBox(width: 14),
                  const Flexible(
                    child: Text(
                      'Continue with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF3C4043),
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
    final strokeWidth = size.width * 0.16;
    final radius = size.width * 0.33;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
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

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final y = center.dy + size.height * 0.02;
    canvas.drawLine(
      Offset(center.dx, y),
      Offset(size.width * 0.83, y),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.user, required this.size});

  final UserProfile user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeProfileImage(user.profileImageBase64);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: imageBytes == null
            ? const LinearGradient(
                colors: <Color>[AppColors.primary, AppColors.accent],
              )
            : null,
        border: imageBytes == null
            ? Border.all(color: AppColors.accentBright, width: 1.4)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes == null
          ? Center(
              child: Text(
                _initials(user.username),
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: math.max(11, size * 0.34),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Image.memory(
              imageBytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  _initials(user.username),
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: math.max(11, size * 0.34),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
    );
  }

  Uint8List? _decodeProfileImage(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  String _initials(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return '?';
    }

    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }

    return trimmed.substring(0, 1).toUpperCase();
  }
}
