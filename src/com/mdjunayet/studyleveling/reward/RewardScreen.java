package com.mdjunayet.studyleveling.reward;

import javax.swing.*;
import java.awt.*;
import java.util.List;
import java.util.Arrays;
import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.ui.MainMenu;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

public class RewardScreen extends JFrame {
    private User user;
    private JLabel coinsLabel;
    private MainMenu mainMenu;
    private final FontManager fontManager = FontManager.getInstance();
    private JPanel predefinedRewardsGrid;
    private JPanel customRewardsGrid;
    private List<Reward> predefinedRewards;

    public RewardScreen(User user, MainMenu mainMenu) {
        this.user = user;
        this.mainMenu = mainMenu;

        setTitle("Rewards Shop");
        setSize(900, 700);
        setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());
        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Header panel
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);

        // Create predefined rewards with Solo Leveling style
        predefinedRewards = Arrays.asList(
                new Reward("NETFLIX 30 MINS", 150),
                new Reward("VIDEO GAMES", 250),
                new Reward("GO OUT", 150),
                new Reward("1 HOUR BREAK", 300),
                new Reward("SOCIAL MEDIA", 100),
                new Reward("FAVORITE SNACK", 200)
        );

        // Main content panel
        JPanel contentPanel = new JPanel();
        contentPanel.setLayout(new BoxLayout(contentPanel, BoxLayout.Y_AXIS));
        contentPanel.setBackground(ColorPalette.SL_BACKGROUND);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Create a JScrollPane to handle many rewards
        JScrollPane scrollPane = new JScrollPane(contentPanel);
        scrollPane.setBackground(ColorPalette.SL_BACKGROUND);
        scrollPane.setBorder(BorderFactory.createEmptyBorder());
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);

        // Predefined rewards section
        JPanel predefinedSection = createSectionPanel("✨ PREDEFINED REWARDS", null);
        contentPanel.add(predefinedSection);

        // Predefined rewards grid
        predefinedRewardsGrid = new JPanel();
        predefinedRewardsGrid.setBackground(ColorPalette.SL_BACKGROUND);
        predefinedRewardsGrid.setLayout(new GridLayout(0, 3, 15, 15)); // Use 0 rows to allow dynamic sizing
        predefinedSection.add(predefinedRewardsGrid);

        contentPanel.add(Box.createRigidArea(new Dimension(0, 30))); // Spacing between sections

        // Custom rewards section
        JButton addRewardButton = createStyledButton("➕ ADD CUSTOM REWARD");
        addRewardButton.addActionListener(e -> showAddCustomRewardDialog());

        JPanel customSection = createSectionPanel("🔮 CUSTOM REWARDS", addRewardButton);
        contentPanel.add(customSection);

        // Custom rewards grid
        customRewardsGrid = new JPanel();
        customRewardsGrid.setBackground(ColorPalette.SL_BACKGROUND);
        customRewardsGrid.setLayout(new GridLayout(0, 3, 15, 15)); // Use 0 rows to allow dynamic sizing
        customSection.add(customRewardsGrid);

        add(scrollPane, BorderLayout.CENTER);

        // Footer panel
        JPanel footerPanel = createFooterPanel();
        add(footerPanel, BorderLayout.SOUTH);

        // Load all rewards
        refreshRewardsList();

        setVisible(true);
    }

    private JPanel createSectionPanel(String title, JButton actionButton) {
        JPanel sectionPanel = new JPanel(new BorderLayout(0, 15));
        sectionPanel.setBackground(ColorPalette.SL_BACKGROUND);
        sectionPanel.setBorder(BorderFactory.createEmptyBorder(0, 0, 15, 0));
        sectionPanel.setMaximumSize(new Dimension(Integer.MAX_VALUE, Integer.MAX_VALUE));

        // Section header with title and optional button
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setOpaque(false);
        headerPanel.setBorder(BorderFactory.createMatteBorder(0, 0, 2, 0, ColorPalette.SL_PRIMARY_LIGHT));

        JLabel sectionTitle = new JLabel(title);
        sectionTitle.setFont(fontManager.getSubheaderFont());
        sectionTitle.setForeground(ColorPalette.SL_ACCENT);
        sectionTitle.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));

        headerPanel.add(sectionTitle, BorderLayout.WEST);

        if (actionButton != null) {
            headerPanel.add(actionButton, BorderLayout.EAST);
        }

        sectionPanel.add(headerPanel, BorderLayout.NORTH);

        // Content panel
        JPanel contentPanel = new JPanel();
        contentPanel.setLayout(new GridLayout(0, 3, 15, 15));
        contentPanel.setBackground(ColorPalette.SL_BACKGROUND);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(15, 0, 0, 0));

        sectionPanel.add(contentPanel, BorderLayout.CENTER);

        return sectionPanel;
    }

    private void refreshRewardsList() {
        // Clear both grids
        predefinedRewardsGrid.removeAll();
        customRewardsGrid.removeAll();

        // Add predefined rewards
        for (Reward reward : predefinedRewards) {
            predefinedRewardsGrid.add(createRewardPanel(reward, false));
        }

        // Add custom rewards with edit/delete options
        if (user.getCustomRewards() != null && !user.getCustomRewards().isEmpty()) {
            for (Reward reward : user.getCustomRewards()) {
                customRewardsGrid.add(createRewardPanel(reward, true));
            }
        } else {
            // Show message when no custom rewards exist
            JPanel emptyPanel = new JPanel(new BorderLayout());
            emptyPanel.setBackground(ColorPalette.SL_CARD);
            emptyPanel.setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 2),
                    BorderFactory.createEmptyBorder(20, 20, 20, 20)
            ));

            JLabel emptyLabel = new JLabel("<html><center>No custom rewards yet!<br>🎯 Create your own reward!</center></html>");
            emptyLabel.setFont(fontManager.getBodyFont().deriveFont(Font.ITALIC));
            emptyLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
            emptyLabel.setHorizontalAlignment(SwingConstants.CENTER);

            JButton addButton = createStyledButton("➕ CREATE REWARD");
            addButton.setBackground(new Color(60, 100, 160));
            addButton.addActionListener(e -> showAddCustomRewardDialog());

            JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
            buttonPanel.setOpaque(false);
            buttonPanel.add(addButton);

            emptyPanel.add(emptyLabel, BorderLayout.CENTER);
            emptyPanel.add(buttonPanel, BorderLayout.SOUTH);

            customRewardsGrid.add(emptyPanel);
        }

        predefinedRewardsGrid.revalidate();
        predefinedRewardsGrid.repaint();
        customRewardsGrid.revalidate();
        customRewardsGrid.repaint();
    }

    private JPanel createHeaderPanel() {
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        headerPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        JLabel titleLabel = new JLabel("🏆 REWARDS SHOP");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        // Coins display with icon
        coinsLabel = new JLabel("💰 " + user.getCoins() + " COINS");
        coinsLabel.setFont(fontManager.getSubheaderFont());
        coinsLabel.setForeground(ColorPalette.SL_COIN);

        headerPanel.add(titleLabel, BorderLayout.WEST);
        headerPanel.add(coinsLabel, BorderLayout.EAST);

        return headerPanel;
    }

    private JPanel createRewardPanel(Reward reward, boolean isCustom) {
        JPanel panel = new JPanel(new BorderLayout(0, 10));
        panel.setBackground(ColorPalette.SL_CARD);

        // Add a gradient-like effect with a slightly lighter top
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 2),
                BorderFactory.createCompoundBorder(
                        BorderFactory.createMatteBorder(1, 0, 0, 0, new Color(255, 255, 255, 50)),
                        BorderFactory.createEmptyBorder(20, 20, 20, 20)
                )
        ));

        // Reward name with enhanced styling
        JLabel nameLabel = new JLabel(reward.getName());
        nameLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
        nameLabel.setForeground(ColorPalette.SL_ACCENT_BRIGHT);
        nameLabel.setHorizontalAlignment(SwingConstants.CENTER);
        nameLabel.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));

        // Reward icon/image with enhanced styling
        JLabel iconLabel = new JLabel(getIconForReward(reward.getName()));
        iconLabel.setFont(new Font("Dialog", Font.PLAIN, 60));
        iconLabel.setForeground(ColorPalette.SL_ACCENT);
        iconLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Add a glow effect around the icon (simulated with a panel with a gradient border)
        JPanel iconPanel = new JPanel(new BorderLayout());
        iconPanel.setOpaque(false);
        iconPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(new Color(100, 50, 150, 80), 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));
        iconPanel.add(iconLabel, BorderLayout.CENTER);

        // Cost panel with improved visual styling
        JPanel costPanel = new JPanel();
        costPanel.setLayout(new BoxLayout(costPanel, BoxLayout.X_AXIS));
        costPanel.setOpaque(false);
        costPanel.setBorder(BorderFactory.createEmptyBorder(10, 0, 10, 0));
        costPanel.setAlignmentX(Component.CENTER_ALIGNMENT);

        // Add spacer to center the cost display
        costPanel.add(Box.createHorizontalGlue());

        // Cost badge with better styling
        JPanel costBadge = new JPanel(new FlowLayout(FlowLayout.CENTER, 5, 0));
        costBadge.setBackground(new Color(60, 30, 90));
        costBadge.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                BorderFactory.createEmptyBorder(5, 10, 5, 10)
        ));

        JLabel costLabel = new JLabel(reward.getCost() + "");
        costLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
        costLabel.setForeground(ColorPalette.SL_COIN);

        JLabel coinIcon = new JLabel(" 💰");
        coinIcon.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 16));

        costBadge.add(costLabel);
        costBadge.add(coinIcon);
        costPanel.add(costBadge);

        // Add spacer to center the cost display
        costPanel.add(Box.createHorizontalGlue());

        // Redeem button with enhanced styling
        JButton redeemButton = createStyledButton("🎁 REDEEM");
        redeemButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        redeemButton.setBackground(new Color(80, 40, 140)); // Richer purple
        redeemButton.addActionListener(e -> redeemReward(reward));

        // Action panel for custom rewards with improved layout
        JPanel actionPanel = new JPanel(new BorderLayout(5, 5));
        actionPanel.setOpaque(false);

        if (isCustom) {
            // Add edit and delete buttons for custom rewards with better organization
            JPanel managementPanel = new JPanel(new GridLayout(1, 2, 5, 0));
            managementPanel.setOpaque(false);
            managementPanel.setBorder(BorderFactory.createEmptyBorder(5, 0, 0, 0));

            JButton editButton = createSmallStyledButton("✏️ EDIT");
            editButton.setBackground(new Color(40, 80, 140)); // Blue
            editButton.addActionListener(e -> editCustomReward(reward));

            JButton deleteButton = createSmallStyledButton("🗑️ DELETE");
            deleteButton.setBackground(new Color(140, 40, 40)); // Red
            deleteButton.addActionListener(e -> deleteCustomReward(reward));

            managementPanel.add(editButton);
            managementPanel.add(deleteButton);

            actionPanel.add(redeemButton, BorderLayout.CENTER);
            actionPanel.add(managementPanel, BorderLayout.SOUTH);
        } else {
            actionPanel.add(redeemButton, BorderLayout.CENTER);
        }

        // Organize components in the panel with better spacing
        JPanel centerPanel = new JPanel(new BorderLayout(0, 5));
        centerPanel.setOpaque(false);
        centerPanel.add(iconPanel, BorderLayout.CENTER);
        centerPanel.add(costPanel, BorderLayout.SOUTH);

        panel.add(nameLabel, BorderLayout.NORTH);
        panel.add(centerPanel, BorderLayout.CENTER);
        panel.add(actionPanel, BorderLayout.SOUTH);

        // Add hover effect to the entire panel
        panel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                panel.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 2),
                        BorderFactory.createCompoundBorder(
                                BorderFactory.createMatteBorder(1, 0, 0, 0, new Color(255, 255, 255, 80)),
                                BorderFactory.createEmptyBorder(20, 20, 20, 20)
                        )
                ));
                panel.setBackground(new Color(40, 25, 65)); // Slightly lighter on hover
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                panel.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 2),
                        BorderFactory.createCompoundBorder(
                                BorderFactory.createMatteBorder(1, 0, 0, 0, new Color(255, 255, 255, 50)),
                                BorderFactory.createEmptyBorder(20, 20, 20, 20)
                        )
                ));
                panel.setBackground(ColorPalette.SL_CARD);
            }
        });

        return panel;
    }

    private String getIconForReward(String name) {
        // Return appropriate emoji based on reward name
        if (name.contains("NETFLIX") || name.contains("TV") || name.contains("MOVIE")) {
            return "📺";
        } else if (name.contains("VIDEO GAMES") || name.contains("GAME")) {
            return "🎮";
        } else if (name.contains("GO OUT") || name.contains("WALK")) {
            return "🚶";
        } else if (name.contains("BREAK") || name.contains("REST") || name.contains("COFFEE")) {
            return "☕";
        } else if (name.contains("FOOD") || name.contains("SNACK") || name.contains("DESSERT")) {
            return "🍔";
        } else if (name.contains("MUSIC") || name.contains("SONG")) {
            return "🎵";
        } else if (name.contains("BOOK") || name.contains("READ")) {
            return "📚";
        } else if (name.contains("SOCIAL") || name.contains("FRIEND")) {
            return "👥";
        } else if (name.contains("SOCIAL MEDIA") || name.contains("INSTAGRAM") || name.contains("FACEBOOK")) {
            return "📱";
        } else if (name.contains("SHOPPING") || name.contains("BUY")) {
            return "🛍️";
        } else if (name.contains("SLEEP") || name.contains("NAP")) {
            return "💤";
        } else if (name.contains("BATH") || name.contains("SHOWER")) {
            return "🛁";
        } else if (name.contains("CALL") || name.contains("PHONE")) {
            return "📞";
        } else if (name.contains("DRIVE") || name.contains("CAR")) {
            return "🚗";
        } else if (name.contains("TRAVEL") || name.contains("TRIP")) {
            return "✈️";
        } else if (name.contains("SPORT") || name.contains("EXERCISE")) {
            return "🏃";
        } else if (name.contains("PARTY") || name.contains("CELEBRATE")) {
            return "🎉";
        } else if (name.contains("PET") || name.contains("DOG") || name.contains("CAT")) {
            return "🐾";
        }
        return "🎁"; // Default
    }

    private JPanel createFooterPanel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        panel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JButton closeButton = createStyledButton("🏠 RETURN TO HUB");
        closeButton.addActionListener(e -> dispose());

        panel.add(closeButton);

        return panel;
    }

    private JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFont(fontManager.getBodyFont());
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBackground(ColorPalette.SL_PRIMARY);
        button.setBorder(BorderFactory.createEmptyBorder(8, 15, 8, 15));
        button.setFocusPainted(false);

        // Add hover effect
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                        BorderFactory.createEmptyBorder(7, 14, 7, 14)
                ));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY);
                button.setBorder(BorderFactory.createEmptyBorder(8, 15, 8, 15));
            }
        });

        return button;
    }

    private JButton createSmallStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 10));
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBackground(ColorPalette.SL_PRIMARY);
        button.setBorder(BorderFactory.createEmptyBorder(4, 8, 4, 8));
        button.setFocusPainted(false);

        // Add hover effect
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                        BorderFactory.createEmptyBorder(3, 7, 3, 7)
                ));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY);
                button.setBorder(BorderFactory.createEmptyBorder(4, 8, 4, 8));
            }
        });

        return button;
    }

    private void redeemReward(Reward reward) {
        if (user.getCoins() >= reward.getCost()) {
            user.setCoins(user.getCoins() - reward.getCost());
            coinsLabel.setText("💰 " + user.getCoins() + " COINS");

            // Create a custom panel for a more visible notification
            JPanel messagePanel = new JPanel(new BorderLayout(10, 10));
            messagePanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
            messagePanel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

            JLabel titleLabel = new JLabel("REWARD REDEEMED!");
            titleLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
            titleLabel.setForeground(new Color(255, 215, 0)); // Gold color

            JLabel rewardLabel = new JLabel("<html>" + reward.getName() + "<br><br>Enjoy your reward!</html>");
            rewardLabel.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 14));
            rewardLabel.setForeground(new Color(220, 220, 255)); // Light blue-white

            messagePanel.add(titleLabel, BorderLayout.NORTH);
            messagePanel.add(rewardLabel, BorderLayout.CENTER);

            JOptionPane.showMessageDialog(this,
                    messagePanel,
                    "Reward Redeemed",
                    JOptionPane.INFORMATION_MESSAGE);

            // Update the main menu's display
            if (mainMenu != null) {
                mainMenu.refreshStats();
                DataManager.saveUser(user);
            }
        } else {
            // Create a custom panel for a more visible notification
            JPanel messagePanel = new JPanel(new BorderLayout(10, 10));
            messagePanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
            messagePanel.setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));

            JLabel titleLabel = new JLabel("INSUFFICIENT COINS");
            titleLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
            titleLabel.setForeground(new Color(255, 150, 150)); // Lighter red

            JLabel detailLabel = new JLabel("<html>You need " +
                    (reward.getCost() - user.getCoins()) + " more coins to redeem this reward.</html>");
            detailLabel.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 14));
            detailLabel.setForeground(new Color(220, 220, 255)); // Light blue-white

            messagePanel.add(titleLabel, BorderLayout.NORTH);
            messagePanel.add(detailLabel, BorderLayout.CENTER);

            JOptionPane.showMessageDialog(this,
                    messagePanel,
                    "Insufficient Coins",
                    JOptionPane.WARNING_MESSAGE);
        }
    }

    private void showAddCustomRewardDialog() {
        JPanel panel = new JPanel(new GridLayout(0, 1, 0, 10));
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JLabel nameLabel = new JLabel("Reward Name:");
        nameLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JTextField nameField = new JTextField(20);

        JLabel costLabel = new JLabel("Cost (Coins):");
        costLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JTextField costField = new JTextField("100");

        panel.add(nameLabel);
        panel.add(nameField);
        panel.add(costLabel);
        panel.add(costField);

        UIManager.put("OptionPane.background", ColorPalette.SL_CARD);
        UIManager.put("Panel.background", ColorPalette.SL_CARD);

        int result = JOptionPane.showConfirmDialog(this, panel, "Create Custom Reward",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

        if (result == JOptionPane.OK_OPTION) {
            try {
                String name = nameField.getText().trim().toUpperCase();
                int cost = Integer.parseInt(costField.getText().trim());

                if (!name.isEmpty() && cost > 0) {
                    Reward newReward = new Reward(name, cost);
                    user.addCustomReward(newReward);

                    // Save user data and refresh the rewards list
                    DataManager.saveUser(user);
                    refreshRewardsList();

                    JOptionPane.showMessageDialog(this,
                            "✨ Custom reward created successfully!",
                            "Reward Created",
                            JOptionPane.INFORMATION_MESSAGE);
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Please enter a valid name and a positive cost.",
                            "Invalid Input",
                            JOptionPane.WARNING_MESSAGE);
                }
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(this,
                        "Please enter a valid number for the cost.",
                        "Invalid Input",
                        JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private void editCustomReward(Reward reward) {
        JPanel panel = new JPanel(new GridLayout(0, 1, 0, 10));
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JLabel nameLabel = new JLabel("Reward Name:");
        nameLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JTextField nameField = new JTextField(reward.getName(), 20);

        JLabel costLabel = new JLabel("Cost (Coins):");
        costLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JTextField costField = new JTextField(String.valueOf(reward.getCost()));

        panel.add(nameLabel);
        panel.add(nameField);
        panel.add(costLabel);
        panel.add(costField);

        UIManager.put("OptionPane.background", ColorPalette.SL_CARD);
        UIManager.put("Panel.background", ColorPalette.SL_CARD);

        int result = JOptionPane.showConfirmDialog(this, panel, "Edit Custom Reward",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

        if (result == JOptionPane.OK_OPTION) {
            try {
                String name = nameField.getText().trim().toUpperCase();
                int cost = Integer.parseInt(costField.getText().trim());

                if (!name.isEmpty() && cost > 0) {
                    // Remove the old reward and add the updated one
                    user.removeCustomReward(reward);
                    user.addCustomReward(new Reward(name, cost));

                    // Save user data and refresh the rewards list
                    DataManager.saveUser(user);
                    refreshRewardsList();

                    JOptionPane.showMessageDialog(this,
                            "Custom reward updated successfully!",
                            "Reward Updated",
                            JOptionPane.INFORMATION_MESSAGE);
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Please enter a valid name and a positive cost.",
                            "Invalid Input",
                            JOptionPane.WARNING_MESSAGE);
                }
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(this,
                        "Please enter a valid number for the cost.",
                        "Invalid Input",
                        JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private void deleteCustomReward(Reward reward) {
        int confirm = JOptionPane.showConfirmDialog(this,
                "Are you sure you want to delete the custom reward: " + reward.getName() + "?",
                "Confirm Deletion",
                JOptionPane.YES_NO_OPTION);

        if (confirm == JOptionPane.YES_OPTION) {
            user.removeCustomReward(reward);

            // Save user data and refresh the rewards list
            DataManager.saveUser(user);
            refreshRewardsList();

            JOptionPane.showMessageDialog(this,
                    "Custom reward deleted successfully!",
                    "Reward Deleted",
                    JOptionPane.INFORMATION_MESSAGE);
        }
    }
}