package com.mdjunayet.studyleveling.ui;

import com.mdjunayet.studyleveling.leaderboard.GlobalLeaderboardScreen;
import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.multiplayer.MultiplayerModeSelectionScreen;
import com.mdjunayet.studyleveling.reward.RewardScreen;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.service.FirebaseManager;
import com.mdjunayet.studyleveling.task.StudyScreen;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

import javax.swing.*;
import javax.swing.border.Border;
import java.awt.*;

public class MainMenu extends JFrame {
    private User user;
    private static User currentUser;
    private static MainMenu currentInstance;

    private JLabel levelLabel;
    private JLabel xpLabel;
    private JLabel coinLabel;
    private final FontManager fontManager = FontManager.getInstance();

    public MainMenu(User user) {
        this.user = user;
        MainMenu.currentUser = user;
        MainMenu.currentInstance = this;

        setTitle("Study Leveling");
        setSize(900, 650);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());

        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Create header panel
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);

        // Create main content panel
        JPanel contentPanel = new JPanel(new BorderLayout(20, 20));
        contentPanel.setBackground(ColorPalette.SL_BACKGROUND);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(22, 30, 30, 30));

        // Create left stats panel
        JPanel statsPanel = createStatsPanel();
        contentPanel.add(statsPanel, BorderLayout.WEST);

        // Create central menu panel
        JPanel menuPanel = createMenuPanel();
        contentPanel.add(menuPanel, BorderLayout.CENTER);

        add(contentPanel, BorderLayout.CENTER);

        // Footer with version info
        JPanel footerPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        footerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        footerPanel.setBorder(BorderFactory.createEmptyBorder(8, 18, 8, 18));
        JLabel versionLabel = new JLabel("v1.0");
        versionLabel.setFont(fontManager.getSmallFont());
        versionLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        footerPanel.add(versionLabel);

        add(footerPanel, BorderLayout.SOUTH);

        setVisible(true);

        // Upload user stats to Firebase
        FirebaseManager.uploadUserStats(user);
    }

    private JPanel createHeaderPanel() {
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        headerPanel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createMatteBorder(0, 0, 1, 0, ColorPalette.SL_DIVIDER),
                BorderFactory.createEmptyBorder(16, 22, 16, 22)
        ));

        JLabel titleLabel = new JLabel("STUDY LEVELING");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JLabel userLabel = new JLabel(user.getUsername());
        userLabel.setFont(fontManager.getSubheaderFont());
        userLabel.setForeground(ColorPalette.SL_ACCENT);

        headerPanel.add(titleLabel, BorderLayout.WEST);
        headerPanel.add(userLabel, BorderLayout.EAST);

        return headerPanel;
    }

    private JPanel createStatsPanel() {
        JPanel statsPanel = new JPanel();
        statsPanel.setLayout(new BoxLayout(statsPanel, BoxLayout.Y_AXIS));
        statsPanel.setBackground(ColorPalette.SL_CARD);
        statsPanel.setBorder(createCardBorder(22));
        statsPanel.setPreferredSize(new Dimension(215, 320));

        // User status title
        JLabel statusTitle = new JLabel("STATUS");
        statusTitle.setFont(fontManager.getSubheaderFont());
        statusTitle.setForeground(ColorPalette.SL_ACCENT);
        statusTitle.setAlignmentX(Component.CENTER_ALIGNMENT);
        statsPanel.add(statusTitle);

        statsPanel.add(Box.createVerticalStrut(20));

        // Level indicator
        JPanel levelPanel = createStatPanel("LEVEL", user.getLevel() + "", ColorPalette.SL_LEVEL);
        statsPanel.add(levelPanel);

        statsPanel.add(Box.createVerticalStrut(15));

        // XP indicator
        JPanel xpPanel = createStatPanel("EXP", user.getXp() + "", ColorPalette.SL_XP);
        statsPanel.add(xpPanel);

        statsPanel.add(Box.createVerticalStrut(15));

        // Coins indicator
        JPanel coinsPanel = createStatPanel("COINS", user.getCoins() + "", ColorPalette.SL_COIN);
        statsPanel.add(coinsPanel);

        // Save references for updating
        levelLabel = (JLabel)levelPanel.getComponent(1);
        xpLabel = (JLabel)xpPanel.getComponent(1);
        coinLabel = (JLabel)coinsPanel.getComponent(1);

        statsPanel.add(Box.createVerticalGlue());

        return statsPanel;
    }

    private JPanel createStatPanel(String name, String value, Color valueColor) {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setOpaque(false);

        JLabel nameLabel = new JLabel(name);
        nameLabel.setFont(fontManager.getSmallFont());
        nameLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        nameLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

        JLabel valueLabel = new JLabel(value);
        valueLabel.setFont(fontManager.getHeaderFont());
        valueLabel.setForeground(valueColor);
        valueLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

        panel.add(nameLabel);
        panel.add(valueLabel);

        return panel;
    }

    private JPanel createMenuPanel() {
        JPanel menuPanel = new JPanel(new BorderLayout());
        menuPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        menuPanel.setBorder(createCardBorder(24));

        // Title panel
        JPanel titlePanel = new JPanel(new BorderLayout());
        titlePanel.setBackground(ColorPalette.SL_CARD_ELEVATED);
        titlePanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        JLabel menuTitle = new JLabel("MAIN MENU");
        menuTitle.setFont(fontManager.getSubheaderFont());
        menuTitle.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        titlePanel.add(menuTitle, BorderLayout.CENTER);

        menuPanel.add(titlePanel, BorderLayout.NORTH);

        // Menu options panel
        JPanel optionsPanel = new JPanel(new GridLayout(5, 1, 0, 12));
        optionsPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        optionsPanel.setBorder(BorderFactory.createEmptyBorder(18, 18, 18, 18));

        // Menu buttons
        JButton startButton = createMenuButton("START", "📝");
        JButton rewardsButton = createMenuButton("REWARDS", "🎁");
        JButton progressButton = createMenuButton("PROGRESS", "📊");
        JButton multiplayerButton = createMenuButton("MULTIPLAYER MODE", "👥");
        JButton leaderboardButton = createMenuButton("GLOBAL LEADERBOARD", "🌎");

        startButton.addActionListener(e -> new StudyScreen(this));
        rewardsButton.addActionListener(e -> new RewardScreen(user, this));
        progressButton.addActionListener(e -> new ProgressScreen());
        multiplayerButton.addActionListener(e -> openMultiplayerMode());
        leaderboardButton.addActionListener(e -> new GlobalLeaderboardScreen());

        optionsPanel.add(startButton);
        optionsPanel.add(rewardsButton);
        optionsPanel.add(progressButton);
        optionsPanel.add(multiplayerButton);
        optionsPanel.add(leaderboardButton);

        menuPanel.add(optionsPanel, BorderLayout.CENTER);

        return menuPanel;
    }

    private JButton createMenuButton(String text, String icon) {
        JButton button = new JButton(icon + " " + text);
        button.setFont(fontManager.getSubheaderFont());
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBackground(ColorPalette.SL_CARD);
        button.setBorder(createButtonBorder(ColorPalette.SL_DIVIDER));
        button.setHorizontalAlignment(SwingConstants.LEFT);
        button.setFocusPainted(false);
        button.setCursor(Cursor.getPredefinedCursor(Cursor.HAND_CURSOR));

        // Add hover effect
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                button.setBorder(createButtonBorder(ColorPalette.SL_ACCENT_BRIGHT));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_CARD);
                button.setBorder(createButtonBorder(ColorPalette.SL_DIVIDER));
            }
        });

        return button;
    }

    private Border createCardBorder(int padding) {
        return BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_DIVIDER, 1),
                BorderFactory.createEmptyBorder(padding, padding, padding, padding)
        );
    }

    private Border createButtonBorder(Color borderColor) {
        return BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(borderColor, 1),
                BorderFactory.createEmptyBorder(14, 18, 14, 18)
        );
    }

    private void openMultiplayerMode() {
        new MultiplayerModeSelectionScreen();
    }

    // Static methods to access current user and instance
    public static User getCurrentUser() {
        return currentUser;
    }

    public static MainMenu getCurrentInstance() {
        return currentInstance;
    }

    /**
     * Get the current user
     */
    public User getUser() {
        return user;
    }

    // Method to update user data from multiplayer mode
    public void updateUserFromMultiplayer(int xpGained, int coinsGained) {
        // Add the gained XP and coins to the main user
        if (xpGained > 0) {
            user.addXP(xpGained);
        }

        if (coinsGained > 0) {
            user.addCoins(coinsGained);
        }

        // Update the UI
        refreshStats();

        // Save the updated user data
        DataManager.saveUser(user);

        // Upload updated stats to Firebase
        FirebaseManager.uploadUserStats(user);
    }

    /**
     * Update the UI to reflect the current user stats
     */
    public void refreshStats() {
        // Update the stat labels with current values
        if (levelLabel != null) {
            levelLabel.setText(String.valueOf(user.getLevel()));
        }

        if (xpLabel != null) {
            xpLabel.setText(String.valueOf(user.getXp()));
        }

        if (coinLabel != null) {
            coinLabel.setText(String.valueOf(user.getCoins()));
        }
    }
}
