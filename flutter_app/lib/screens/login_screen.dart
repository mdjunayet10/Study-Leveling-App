import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/surface_card.dart';
import 'main_menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _message = ' ';
  Color _messageColor = AppColors.textSecondary;
  bool _obscurePassword = true;
  bool _appClosed = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitGoogleLogin() async {
    final appState = AppScope.of(context);

    setState(() {
      _message = 'Opening Google Sign-In...';
      _messageColor = Colors.orange;
    });

    final result = await appState.signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (result.success) {
      setState(() {
        _message = result.message;
        _messageColor = AppColors.success;
      });

      Navigator.of(context).pushReplacementNamed(MainMenuScreen.routeName);
      return;
    }

    setState(() {
      _message = result.message;
      _messageColor = AppColors.error;
    });
  }

  Future<void> _submitLogin() async {
    final appState = AppScope.of(context);

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _message = 'Logging in...';
      _messageColor = Colors.orange;
    });

    final result = await appState.signIn(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (result.success) {
      setState(() {
        _message = result.message;
        _messageColor = AppColors.success;
      });

      Navigator.of(context).pushReplacementNamed(MainMenuScreen.routeName);
      return;
    }

    setState(() {
      _message = result.message;
      _messageColor = AppColors.error;
    });
  }

  Future<void> _exitApp() async {
    if (kIsWeb) {
      setState(() {
        _appClosed = true;
      });
      return;
    }

    await SystemNavigator.pop();
  }

  void _reopenApp() {
    setState(() {
      _appClosed = false;
      _message = ' ';
      _messageColor = AppColors.textSecondary;
    });
  }

  Future<void> _showCreateAccountDialog() async {
    final appState = AppScope.of(context);
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final createFormKey = GlobalKey<FormState>();

    bool obscurePassword = true;
    bool isCreating = false;
    String inlineMessage =
        'Google Sign-In is recommended. Or create a username/password account below.';
    Color inlineColor = AppColors.textSecondary;

    final result = await showDialog<AuthResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: Text(
                'Create Account',
                style: AppTextStyles.subheader.copyWith(
                  color: AppColors.accentBright,
                ),
              ),
              content: Form(
                key: createFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Use Google Sign-In for the cleanest login experience. Or create a username/password account below.',
                        style: AppTextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                          labelText: 'USERNAME',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a username.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                          labelText: 'EMAIL',
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'PASSWORD',
                          suffixIcon: IconButton(
                            tooltip: obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            onPressed: isCreating
                                ? null
                                : () => setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  }),
                            icon: Icon(
                              obscurePassword
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
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscurePassword,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_reset_outlined),
                          labelText: 'CONFIRM PASSWORD',
                        ),
                        validator: (value) {
                          if (value != passwordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(
                          inlineMessage,
                          key: ValueKey<String>(inlineMessage),
                          style: AppTextStyles.small.copyWith(
                            color: inlineColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (!(createFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }

                          setDialogState(() {
                            isCreating = true;
                            inlineMessage = 'Creating account...';
                            inlineColor = Colors.orange;
                          });

                          final createResult = await appState
                              .createAccountWithEmailPassword(
                                username: usernameController.text,
                                email: emailController.text,
                                password: passwordController.text,
                              );

                          if (!dialogContext.mounted) {
                            return;
                          }

                          if (createResult.success) {
                            Navigator.of(dialogContext).pop(createResult);
                            return;
                          }

                          setDialogState(() {
                            isCreating = false;
                            inlineMessage = createResult.message;
                            inlineColor = AppColors.error;
                          });
                        },
                  child: Text(isCreating ? 'CREATING...' : 'CREATE ACCOUNT'),
                ),
              ],
            );
          },
        );
      },
    );

    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _message = result.message;
      _messageColor = result.success ? AppColors.success : AppColors.error;
    });

    if (result.success) {
      Navigator.of(context).pushReplacementNamed(MainMenuScreen.routeName);
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final appState = AppScope.of(context);
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final resetFormKey = GlobalKey<FormState>();

    bool isSending = false;
    String inlineMessage =
        'Enter the email for this username. Firebase will send a password reset link.';
    Color inlineColor = AppColors.textSecondary;

    final result = await showDialog<AuthResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              title: Text(
                'Reset Password',
                style: AppTextStyles.subheader.copyWith(
                  color: AppColors.accentBright,
                ),
              ),
              content: Form(
                key: resetFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: usernameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person_search_outlined),
                          labelText: 'USERNAME',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your username.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                          labelText: 'EMAIL',
                        ),
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 160),
                        child: Text(
                          inlineMessage,
                          key: ValueKey<String>(inlineMessage),
                          style: AppTextStyles.small.copyWith(
                            color: inlineColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          if (!(resetFormKey.currentState?.validate() ??
                              false)) {
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                            inlineMessage = 'Sending reset email...';
                            inlineColor = Colors.orange;
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
                            isSending = false;
                            inlineMessage = resetResult.message;
                            inlineColor = AppColors.error;
                          });
                        },
                  child: Text(isSending ? 'SENDING...' : 'SEND RESET EMAIL'),
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
      _usernameController.text = recoveredUsername;
      _passwordController.clear();
      _message = result.message;
      _messageColor = result.success ? AppColors.success : AppColors.error;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_appClosed) {
      return _ClosedAppView(onReopen: _reopenApp);
    }

    final appState = AppScope.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Tooltip(
        message: 'Exit app',
        child: FloatingActionButton.small(
          heroTag: 'login-exit',
          onPressed: _exitApp,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.accentBright,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primaryLight),
          ),
          child: const Icon(Icons.close_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 40,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SurfaceCard(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.accent),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppColors.accentBright,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Study Leveling',
                              style: AppTextStyles.appTitle.copyWith(
                                shadows: <Shadow>[
                                  Shadow(
                                    color: AppColors.accent.withValues(
                                      alpha: 0.55,
                                    ),
                                    blurRadius: 18,
                                  ),
                                  Shadow(
                                    color: AppColors.primaryLight.withValues(
                                      alpha: 0.45,
                                    ),
                                    blurRadius: 30,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to save your missions and progress.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            _GoogleSignInButton(
                              isBusy: appState.isBusy,
                              onPressed: appState.isBusy
                                  ? null
                                  : _submitGoogleLogin,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: <Widget>[
                                const Expanded(
                                  child: Divider(color: AppColors.divider),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    'or username login',
                                    style: AppTextStyles.small.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: Divider(color: AppColors.divider),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _usernameController,
                              style: AppTextStyles.body,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                labelText: 'USERNAME',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Enter a username.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AppTextStyles.body,
                              onFieldSubmitted: (_) {
                                if (!appState.isBusy) {
                                  _submitLogin();
                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.lock_outline),
                                labelText: 'PASSWORD',
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Show password'
                                      : 'Hide password',
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter a password.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 160),
                              child: Text(
                                _message,
                                key: ValueKey<String>(_message),
                                style: AppTextStyles.body.copyWith(
                                  color: _messageColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10),
                            PrimaryButton(
                              label: appState.isBusy ? 'WORKING...' : 'LOGIN',
                              onPressed: appState.isBusy ? null : _submitLogin,
                              leading: appState.isBusy
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login, size: 18),
                              isExpanded: true,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Flexible(
                                  child: TextButton(
                                    onPressed: appState.isBusy
                                        ? null
                                        : _showCreateAccountDialog,
                                    child: const Text(
                                      "Don't have an account?",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: TextButton(
                                    onPressed: appState.isBusy
                                        ? null
                                        : _showForgotPasswordDialog,
                                    child: const Text(
                                      'Forgot Password?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'v1.0',
                        style: AppTextStyles.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isBusy, required this.onPressed});

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
                  Flexible(
                    child: Text(
                      'Continue with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
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

class _ClosedAppView extends StatelessWidget {
  const _ClosedAppView({required this.onReopen});

  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SurfaceCard(
                padding: const EdgeInsets.all(24),
                radius: 24,
                borderColor: AppColors.primaryLight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.accentBright),
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: AppColors.accentBright,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'App Closed',
                      style: AppTextStyles.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      kIsWeb
                          ? 'The web version cannot force-close the browser tab. You can now close this tab safely.'
                          : 'Study Leveling has been closed.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Open Study Leveling Again',
                      leading: const Icon(Icons.refresh_rounded),
                      onPressed: onReopen,
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
