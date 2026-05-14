import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'account_menu_button.dart';

class AppPageShell extends StatelessWidget {
  const AppPageShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.footer,
    this.centerTitle = false,
    this.bodyPadding = const EdgeInsets.fromLTRB(20, 22, 20, 22),
    this.scrollBody = true,
    this.showBackButton = true,
    this.showAccountButton = false,
    this.onBackPressed,
    this.fallbackRouteName = '/main-menu',
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  final bool centerTitle;
  final EdgeInsets bodyPadding;
  final bool scrollBody;
  final bool showBackButton;
  final bool showAccountButton;
  final VoidCallback? onBackPressed;
  final String fallbackRouteName;

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final routeName = route?.settings.name ?? '';
    final canPop = route?.canPop ?? false;
    final canReturn =
        showBackButton &&
        (onBackPressed != null || canPop || routeName != fallbackRouteName);

    final trailingWidgets = <Widget>[
      ?trailing,
      if (showAccountButton) const AccountMenuButton(),
    ];

    final backButton = canReturn
        ? Tooltip(
            message: 'Return',
            child: IconButton.filledTonal(
              onPressed: () => _handleBack(context, canPop),
              icon: const Icon(Icons.arrow_back_rounded),
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              color: AppColors.accentBright,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primaryLight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          )
        : null;

    final titleStyle = title == 'Study Leveling'
        ? AppTextStyles.appTitle
        : AppTextStyles.header;

    final titleBlock = Column(
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: titleStyle.copyWith(
            shadows: <Shadow>[
              Shadow(
                color: AppColors.primaryLight.withValues(alpha: 0.65),
                blurRadius: 18,
              ),
            ],
          ),
          textAlign: centerTitle ? TextAlign.center : TextAlign.left,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 5),
          Text(
            subtitle!,
            style: AppTextStyles.small.copyWith(color: AppColors.textMuted),
            textAlign: centerTitle ? TextAlign.center : TextAlign.left,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Stack(
          children: <Widget>[
            const _BackgroundVeil(),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          AppColors.cardElevated.withValues(alpha: 0.96),
                          AppColors.primaryDark.withValues(alpha: 0.92),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.45),
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primaryGlow.withValues(alpha: 0.14),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder:
                          (BuildContext context, BoxConstraints constraints) {
                            final compact = constraints.maxWidth < 620;

                            if (centerTitle || compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  if (backButton != null) ...<Widget>[
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: backButton,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Center(child: titleBlock),
                                  if (trailingWidgets.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: trailingWidgets,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }

                            return Row(
                              children: <Widget>[
                                if (backButton != null) ...<Widget>[
                                  backButton,
                                  const SizedBox(width: 12),
                                ],
                                Expanded(child: titleBlock),
                                const SizedBox(width: 16),
                                ...trailingWidgets,
                              ],
                            );
                          },
                    ),
                  ),
                  Expanded(
                    child: scrollBody
                        ? SingleChildScrollView(
                            padding: bodyPadding,
                            child: child,
                          )
                        : Padding(padding: bodyPadding, child: child),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.divider.withValues(alpha: 0.8),
                      ),
                    ),
                    child:
                        footer ??
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('v1.0', style: AppTextStyles.small),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBack(BuildContext context, bool canPop) {
    final customBack = onBackPressed;
    if (customBack != null) {
      customBack();
      return;
    }

    final navigator = Navigator.of(context);
    if (canPop) {
      navigator.maybePop();
      return;
    }

    navigator.pushNamedAndRemoveUntil(fallbackRouteName, (_) => false);
  }
}

class _BackgroundVeil extends StatelessWidget {
  const _BackgroundVeil();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                AppColors.accent.withValues(alpha: 0.08),
                Colors.transparent,
                AppColors.primaryGlow.withValues(alpha: 0.06),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
