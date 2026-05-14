import 'dart:async';

import 'package:flutter/material.dart';

import '../models/reward_item.dart';
import '../models/user_profile.dart';
import '../services/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/app_page_shell.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/placeholder_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/reward_tile.dart';
import '../widgets/section_header.dart';
import '../widgets/surface_card.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  static const routeName = '/rewards';

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  static final List<RewardItem> _predefinedRewards = <RewardItem>[
    RewardItem(name: 'VIDEO GAMES', cost: 250),
    RewardItem(name: 'GO OUT', cost: 150),
    RewardItem(name: '1 HOUR BREAK', cost: 300),
    RewardItem(name: 'SOCIAL MEDIA', cost: 100),
    RewardItem(name: 'FAVORITE SNACK', cost: 200),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppScope.of(context);
    final user = appState.currentUser;

    if (user == null) {
      return PlaceholderScreen(
        title: 'REWARDS SHOP',
        description:
            'Login or create an account to spend coins, create custom rewards, and keep your redemption history.',
        icon: Icons.card_giftcard_rounded,
        primaryActionLabel: 'LOGIN / SIGN UP',
        onPrimaryAction: () =>
            showSignInRequiredDialog(context, featureName: 'Rewards'),
      );
    }

    unawaited(appState.rememberNavigation(RewardScreen.routeName));

    return AppPageShell(
      title: 'REWARDS SHOP',
      trailing: Text(
        '${user.coins} COINS',
        style: AppTextStyles.subheader.copyWith(color: AppColors.coin),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 700
              ? 2
              : 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSection(
                title: 'PREDEFINED REWARDS',
                child: GridView.builder(
                  itemCount: _predefinedRewards.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 1.05 : 0.9,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final reward = _predefinedRewards[index];
                    return RewardTile(
                      reward: reward,
                      onRedeem: () async {
                        final success = await appState.redeemReward(reward);
                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Redeemed ${reward.name}.'
                                  : 'Not enough coins for ${reward.name}.',
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'CUSTOM REWARDS',
                action: Tooltip(
                  message: 'Add custom reward',
                  child: IconButton.filledTonal(
                    onPressed: () => _showRewardDialog(context, appState),
                    icon: const Icon(Icons.add),
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
                ),
                child: user.customRewards.isEmpty
                    ? SurfaceCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            Text(
                              'No custom rewards yet! Create your own reward.',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            PrimaryButton(
                              label: 'CREATE REWARD',
                              onPressed: () =>
                                  _showRewardDialog(context, appState),
                              backgroundColor: AppColors.primary,
                              hoverColor: AppColors.primaryLight,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        itemCount: user.customRewards.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: columns == 1 ? 1.08 : 0.92,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final reward = user.customRewards[index];
                          return RewardTile(
                            reward: reward.copy()..isCustom = true,
                            onRedeem: () async {
                              final success = await appState.redeemReward(
                                reward,
                              );
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Redeemed ${reward.name}.'
                                        : 'Not enough coins for ${reward.name}.',
                                  ),
                                ),
                              );
                            },
                            onEdit: () => _showRewardDialog(
                              context,
                              appState,
                              reward: reward,
                              index: index,
                            ),
                            onDelete: () => _confirmAndDeleteReward(
                              context,
                              appState,
                              index,
                              reward.name,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              _buildRewardHistorySection(user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRewardHistorySection(UserProfile user) {
    final history = user.rewardHistory.take(6).toList();

    return _buildSection(
      title: 'REWARD HISTORY',
      child: history.isEmpty
          ? Text(
              'Redeemed rewards will appear here.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          : Column(
              children: <Widget>[
                for (final redemption in history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SurfaceCard(
                      color: AppColors.primaryDark,
                      borderColor: AppColors.primaryLight,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              redemption.rewardName,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${redemption.cost} COINS',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.coin,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    Widget? action,
    required Widget child,
  }) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SectionHeader(title: title, action: action),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteReward(
    BuildContext context,
    AppState appState,
    int index,
    String rewardName,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Delete Reward',
      message: 'Delete "$rewardName" from your custom rewards?',
      confirmLabel: 'DELETE',
    );

    if (!confirmed) {
      return;
    }

    await appState.removeCustomRewardAt(index);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Custom reward deleted.')));
  }

  Future<void> _showRewardDialog(
    BuildContext context,
    AppState appState, {
    RewardItem? reward,
    int? index,
  }) async {
    final nameController = TextEditingController(text: reward?.name ?? '');
    final costController = TextEditingController(
      text: reward?.cost.toString() ?? '100',
    );

    final result = await showDialog<RewardItem>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            reward == null ? 'Add Custom Reward' : 'Edit Custom Reward',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Reward name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost in coins'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('CANCEL'),
            ),
            PrimaryButton(
              label: 'SAVE',
              onPressed: () {
                final name = nameController.text.trim();
                final cost = int.tryParse(costController.text.trim()) ?? 0;
                if (name.isEmpty || cost <= 0) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop(RewardItem(name: name, cost: cost, isCustom: true));
              },
            ),
          ],
        );
      },
    );

    nameController.dispose();
    costController.dispose();

    if (result == null) {
      return;
    }

    if (index == null) {
      await appState.addCustomReward(result);
    } else {
      await appState.updateCustomRewardAt(index, result);
    }

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == null ? 'Custom reward added.' : 'Custom reward updated.',
        ),
      ),
    );
  }
}
