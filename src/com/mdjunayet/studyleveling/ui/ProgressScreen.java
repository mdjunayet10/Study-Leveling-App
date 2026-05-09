package com.mdjunayet.studyleveling.ui;

import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.task.Task;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.JTableHeader;
import java.awt.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

public class ProgressScreen extends JFrame {
    private final User user;
    private final FontManager fontManager = FontManager.getInstance();

    public ProgressScreen() {
        // Get the current user from MainMenu
        this.user = MainMenu.getCurrentUser();
        if (user == null) {
            JOptionPane.showMessageDialog(null, "Error: No user logged in!");
            dispose();
            return;
        }

        setTitle("Progress Statistics");
        setSize(900, 700);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout());
        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Header panel
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);

        // Create tabbed pane for different progress views with Solo Leveling style
        JTabbedPane tabbedPane = new JTabbedPane();
        tabbedPane.setFont(fontManager.getSubheaderFont());
        tabbedPane.setBackground(ColorPalette.SL_BACKGROUND);
        tabbedPane.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        // Style the tabs
        UIManager.put("TabbedPane.selected", ColorPalette.SL_PRIMARY);
        UIManager.put("TabbedPane.contentAreaColor", ColorPalette.SL_BACKGROUND);
        UIManager.put("TabbedPane.borderHightlightColor", ColorPalette.SL_PRIMARY_LIGHT);
        UIManager.put("TabbedPane.light", ColorPalette.SL_PRIMARY_DARK);
        UIManager.put("TabbedPane.darkShadow", ColorPalette.SL_PRIMARY_DARK);

        // Add panels to tabbed pane
        tabbedPane.addTab("DASHBOARD", createDashboardPanel());
        tabbedPane.addTab("TASK HISTORY", createTaskHistoryPanel());
        tabbedPane.addTab("ACHIEVEMENTS", createGoalsPanel());
        tabbedPane.addTab("ANALYTICS", createAnalyticsPanel());

        // Set content pane with border
        JPanel contentPanel = new JPanel(new BorderLayout());
        contentPanel.setBackground(ColorPalette.SL_BACKGROUND);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(10, 15, 15, 15));
        contentPanel.add(tabbedPane, BorderLayout.CENTER);

        add(contentPanel, BorderLayout.CENTER);

        // Footer panel
        JPanel footerPanel = createFooterPanel();
        add(footerPanel, BorderLayout.SOUTH);

        setVisible(true);
    }

    private JPanel createHeaderPanel() {
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        headerPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        JLabel titleLabel = new JLabel("PROGRESS STATISTICS");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JLabel userLabel = new JLabel(user.getUsername() + " | LVL " + user.getLevel());
        userLabel.setFont(fontManager.getSubheaderFont());
        userLabel.setForeground(ColorPalette.SL_ACCENT);

        headerPanel.add(titleLabel, BorderLayout.WEST);
        headerPanel.add(userLabel, BorderLayout.EAST);

        return headerPanel;
    }

    private JPanel createDashboardPanel() {
        JPanel panel = new JPanel(new BorderLayout(15, 15));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Create a grid layout for stat cards
        JPanel statsGrid = new JPanel(new GridLayout(2, 2, 15, 15));
        statsGrid.setOpaque(false);

        // Level progress card
        JPanel levelPanel = createStatCard("LEVEL PROGRESS", user.getLevel() + "",
                                          "Current Level", ColorPalette.SL_LEVEL);

        // XP Card
        JPanel xpPanel = createStatCard("TOTAL XP", user.getXp() + "",
                                       "Experience Points", ColorPalette.SL_XP);

        // Tasks completed card - use getTotalCompletedTasks() to match the Global Leaderboard
        int completedTasks = user.getTotalCompletedTasks();
        JPanel tasksPanel = createStatCard("TASKS COMPLETED", completedTasks + "",
                                          "Total Tasks", ColorPalette.SL_SUCCESS);

        // Coins card
        JPanel coinsPanel = createStatCard("COINS EARNED", user.getCoins() + "",
                                          "Study Currency", ColorPalette.SL_COIN);

        statsGrid.add(levelPanel);
        statsGrid.add(xpPanel);
        statsGrid.add(tasksPanel);
        statsGrid.add(coinsPanel);

        // Add a title to the dashboard
        JLabel dashboardTitle = new JLabel("CURRENT STATS");
        dashboardTitle.setFont(fontManager.getSubheaderFont());
        dashboardTitle.setForeground(ColorPalette.SL_ACCENT);
        dashboardTitle.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));

        JPanel titlePanel = new JPanel(new BorderLayout());
        titlePanel.setOpaque(false);
        titlePanel.add(dashboardTitle, BorderLayout.WEST);

        // Put it all together
        panel.add(titlePanel, BorderLayout.NORTH);
        panel.add(statsGrid, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createStatCard(String title, String value, String subtitle, Color valueColor) {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1),
            BorderFactory.createEmptyBorder(20, 20, 20, 20)
        ));

        // Title
        JLabel titleLabel = new JLabel(title);
        titleLabel.setFont(fontManager.getBodyFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        titleLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

        // Value (large font)
        JLabel valueLabel = new JLabel(value);
        valueLabel.setFont(fontManager.getTitleFont());
        valueLabel.setForeground(valueColor);
        valueLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

        // Subtitle
        JLabel subtitleLabel = new JLabel(subtitle);
        subtitleLabel.setFont(fontManager.getSmallFont());
        subtitleLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        subtitleLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

        panel.add(Box.createVerticalGlue());
        panel.add(titleLabel);
        panel.add(Box.createVerticalStrut(10));
        panel.add(valueLabel);
        panel.add(Box.createVerticalStrut(5));
        panel.add(subtitleLabel);
        panel.add(Box.createVerticalGlue());

        return panel;
    }

    private JPanel createFooterPanel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        panel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JButton closeButton = createStyledButton("RETURN TO HUB");
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

    private JPanel createTaskHistoryPanel() {
        JPanel panel = new JPanel(new BorderLayout(10, 10));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // FIX: Filter to show only actually completed tasks
        java.util.List<Task> completedTasksList = user.getTasks().stream()
                .filter(Task::isCompleted)
                .collect(Collectors.toList());

        String[] columnNames = {"Description", "Difficulty", "XP", "Coins", "Status", "Completion Date"};
        Object[][] data = new Object[completedTasksList.size()][6];

        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM d, yyyy");
        int i = 0;
        for (Task task : completedTasksList) {
            data[i][0] = task.getDescription();
            data[i][1] = task.getDifficulty();
            data[i][2] = task.getXpReward();
            data[i][3] = task.getCoinReward();
            data[i][4] = "Completed";
            data[i][5] = task.getCompletionDate() != null ?
                    task.getCompletionDate().format(formatter) : "-";
            i++;
        }

        JTable taskTable = new JTable(data, columnNames);
        taskTable.setFont(new Font("Monospaced", Font.PLAIN, 14));
        taskTable.getTableHeader().setFont(fontManager.getSubheaderFont());
        taskTable.setRowHeight(25);
        taskTable.setAutoCreateRowSorter(true);

        // Set table header color
        JTableHeader tableHeader = taskTable.getTableHeader();
        tableHeader.setBackground(ColorPalette.SL_PRIMARY);
        tableHeader.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        tableHeader.setFont(fontManager.getSubheaderFont());

        // Set alternating row colors
        taskTable.setFillsViewportHeight(true);
        taskTable.setBackground(ColorPalette.SL_BACKGROUND);
        taskTable.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        taskTable.setBorder(BorderFactory.createEmptyBorder());
        taskTable.setIntercellSpacing(new Dimension(0, 1));
        taskTable.setRowHeight(40);

        // Custom cell renderer for row colors
        DefaultTableCellRenderer renderer = new DefaultTableCellRenderer();
        renderer.setBackground(ColorPalette.SL_BACKGROUND);
        renderer.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        renderer.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        taskTable.setDefaultRenderer(Object.class, renderer);

        JLabel titleLabel = new JLabel("Complete Task History");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_ACCENT);

        panel.add(titleLabel, BorderLayout.NORTH);
        panel.add(new JScrollPane(taskTable), BorderLayout.CENTER);

        return panel;
    }

    private JPanel createGoalsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout(10, 10));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Achievement panel with milestones
        JPanel achievementsPanel = createAchievementsPanel();

        // Future goals panel
        JPanel goalsPanel = createGoalsInputPanel();

        // Add both panels to main panel
        JPanel centerPanel = new JPanel();
        centerPanel.setLayout(new BoxLayout(centerPanel, BoxLayout.Y_AXIS));
        centerPanel.setBackground(ColorPalette.SL_BACKGROUND);
        centerPanel.add(achievementsPanel);
        centerPanel.add(Box.createRigidArea(new Dimension(0, 20)));
        centerPanel.add(goalsPanel);

        panel.add(centerPanel, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createAchievementsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Achievements", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // FIX: Look at persistent getTotalCompletedTasks() so achievement progress doesn't vanish if the live task log clears
        long completedTasks = user.getTotalCompletedTasks();

        // FIX: Restored proper Unicode emojis
        String[][] achievements = {
            {"🔰 Beginner", "Complete 1 task", completedTasks >= 1 ? "Unlocked" : "Locked"},
            {"🥉 Bronze Scholar", "Complete 5 tasks", completedTasks >= 5 ? "Unlocked" : "Locked"},
            {"🥈 Silver Scholar", "Complete 10 tasks", completedTasks >= 10 ? "Unlocked" : "Locked"},
            {"🥇 Gold Scholar", "Complete 25 tasks", completedTasks >= 25 ? "Unlocked" : "Locked"},
            {"💎 Diamond Scholar", "Complete 50 tasks", completedTasks >= 50 ? "Unlocked" : "Locked"},
            {"🏆 Study Champion", "Complete 100 tasks", completedTasks >= 100 ? "Unlocked" : "Locked"}
        };

        // Create a table for achievements
        String[] columnNames = {"Title", "Requirement", "Status"};
        JTable achievementTable = new JTable(achievements, columnNames);
        achievementTable.setFont(new Font("Monospaced", Font.PLAIN, 14));
        achievementTable.getTableHeader().setFont(fontManager.getSubheaderFont());
        achievementTable.setRowHeight(30);
        achievementTable.setEnabled(false); // Make it non-editable

        // Set background color for the table
        achievementTable.setBackground(ColorPalette.SL_CARD);
        achievementTable.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        // Add custom cell renderer for achievement status
        achievementTable.getColumnModel().getColumn(2).setCellRenderer(new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(
                        table, value, isSelected, hasFocus, row, column);

                // Highlight unlocked achievements
                if ("Unlocked".equals(value)) {
                    c.setForeground(ColorPalette.SL_SUCCESS);
                    c.setFont(c.getFont().deriveFont(Font.BOLD));
                } else {
                    c.setForeground(ColorPalette.SL_TEXT_SECONDARY);
                    c.setFont(c.getFont().deriveFont(Font.PLAIN));
                }

                return c;
            }
        });

        panel.add(new JScrollPane(achievementTable));

        return panel;
    }

    private JPanel createGoalsInputPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Set Study Goals", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // Form panel for setting goals
        JPanel formPanel = new JPanel(new GridLayout(3, 2, 10, 10));
        formPanel.setBackground(ColorPalette.SL_BACKGROUND);

        JLabel dailyTasksLabel = new JLabel("Daily Tasks Goal:");
        dailyTasksLabel.setFont(fontManager.getBodyFont());
        JSpinner dailyTasksSpinner = new JSpinner(new SpinnerNumberModel(3, 1, 10, 1));

        JLabel weeklyXPLabel = new JLabel("Weekly XP Goal:");
        weeklyXPLabel.setFont(fontManager.getBodyFont());
        JSpinner weeklyXPSpinner = new JSpinner(new SpinnerNumberModel(500, 100, 2000, 100));

        JLabel targetLevelLabel = new JLabel("Target Level:");
        targetLevelLabel.setFont(fontManager.getBodyFont());
        JSpinner targetLevelSpinner = new JSpinner(new SpinnerNumberModel(user.getLevel() + 1, user.getLevel() + 1, 100, 1));

        formPanel.add(dailyTasksLabel);
        formPanel.add(dailyTasksSpinner);
        formPanel.add(weeklyXPLabel);
        formPanel.add(weeklyXPSpinner);
        formPanel.add(targetLevelLabel);
        formPanel.add(targetLevelSpinner);

        // Button to save goals
        JButton saveGoalsButton = new JButton("Save Goals");
        saveGoalsButton.setFont(fontManager.getBodyFont());
        saveGoalsButton.setBackground(ColorPalette.SL_PRIMARY);
        saveGoalsButton.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        saveGoalsButton.setAlignmentX(Component.CENTER_ALIGNMENT);
        saveGoalsButton.addActionListener(e -> {
            JOptionPane.showMessageDialog(this,
                "Goals saved successfully!\n" +
                "Daily Tasks: " + dailyTasksSpinner.getValue() + "\n" +
                "Weekly XP: " + weeklyXPSpinner.getValue() + "\n" +
                "Target Level: " + targetLevelSpinner.getValue(),
                "Goals Saved", JOptionPane.INFORMATION_MESSAGE);
            // Note: In a full implementation, these would be saved to the user profile
        });

        // Add components to panel
        panel.add(formPanel);
        panel.add(Box.createRigidArea(new Dimension(0, 10)));
        panel.add(saveGoalsButton);

        return panel;
    }

    private JPanel createAnalyticsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BoxLayout(panel, BoxLayout.Y_AXIS));
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        // Advanced Stats Panel
        JPanel advancedStatsPanel = createAdvancedStatsPanel();

        // Task completion by difficulty
        JPanel difficultyPanel = createDifficultyAnalyticsPanel();

        // XP and Coins earned over time
        JPanel earningsPanel = createEarningsPanel();

        // Study consistency panel
        JPanel consistencyPanel = createConsistencyPanel();

        // Add all panels
        panel.add(advancedStatsPanel);
        panel.add(Box.createRigidArea(new Dimension(0, 20)));
        panel.add(difficultyPanel);
        panel.add(Box.createRigidArea(new Dimension(0, 20)));
        panel.add(earningsPanel);
        panel.add(Box.createRigidArea(new Dimension(0, 20)));
        panel.add(consistencyPanel);

        return panel;
    }

    private JPanel createDifficultyAnalyticsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout());
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Task Completion by Difficulty", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // Count tasks by difficulty
        Map<Task.Difficulty, Integer> difficultyCount = new HashMap<>();
        for (Task.Difficulty diff : Task.Difficulty.values()) {
            difficultyCount.put(diff, 0);
        }

        for (Task task : user.getTasks()) {
            if (task.isCompleted()) {
                Task.Difficulty diff = task.getDifficulty();
                difficultyCount.put(diff, difficultyCount.get(diff) + 1);
            }
        }

        // Create labels for each difficulty
        JPanel statsPanel = new JPanel(new GridLayout(1, Task.Difficulty.values().length, 10, 0));
        statsPanel.setBackground(ColorPalette.SL_BACKGROUND);

        Color[] colors = {
            new Color(50, 205, 50),  // EASY - Green
            new Color(255, 165, 0),  // MEDIUM - Orange
            new Color(220, 20, 60)   // HARD - Red
        };

        int i = 0;
        for (Task.Difficulty diff : Task.Difficulty.values()) {
            JPanel card = new JPanel();
            card.setLayout(new BoxLayout(card, BoxLayout.Y_AXIS));
            card.setBackground(ColorPalette.SL_CARD);
            card.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(colors[i], 3),
                BorderFactory.createEmptyBorder(15, 15, 15, 15)
            ));

            JLabel titleLabel = new JLabel(diff.toString());
            titleLabel.setFont(fontManager.getSubheaderFont());
            titleLabel.setForeground(colors[i]);
            titleLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

            JLabel countLabel = new JLabel(difficultyCount.get(diff).toString());
            countLabel.setFont(new Font("Monospaced", Font.BOLD, 36));
            countLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

            JLabel tasksLabel = new JLabel("tasks");
            tasksLabel.setFont(new Font("Monospaced", Font.PLAIN, 14));
            tasksLabel.setAlignmentX(Component.CENTER_ALIGNMENT);

            card.add(Box.createRigidArea(new Dimension(0, 10)));
            card.add(titleLabel);
            card.add(Box.createRigidArea(new Dimension(0, 10)));
            card.add(countLabel);
            card.add(tasksLabel);
            card.add(Box.createRigidArea(new Dimension(0, 10)));

            statsPanel.add(card);
            i++;
        }

        panel.add(statsPanel, BorderLayout.CENTER);

        return panel;
    }

    private JPanel createEarningsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout());
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Earnings Summary", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // Calculate total XP and coins by difficulty
        Map<Task.Difficulty, Integer> xpByDifficulty = new HashMap<>();
        Map<Task.Difficulty, Integer> coinsByDifficulty = new HashMap<>();

        for (Task.Difficulty diff : Task.Difficulty.values()) {
            xpByDifficulty.put(diff, 0);
            coinsByDifficulty.put(diff, 0);
        }

        for (Task task : user.getTasks()) {
            if (task.isCompleted()) {
                Task.Difficulty diff = task.getDifficulty();
                xpByDifficulty.put(diff, xpByDifficulty.get(diff) + task.getXpReward());
                coinsByDifficulty.put(diff, coinsByDifficulty.get(diff) + task.getCoinReward());
            }
        }

        // Create data for the table
        String[] columnNames = {"Difficulty", "XP Earned", "Coins Earned"};
        Object[][] data = new Object[Task.Difficulty.values().length + 1][3];

        int i = 0;
        int totalXP = 0;
        int totalCoins = 0;

        for (Task.Difficulty diff : Task.Difficulty.values()) {
            data[i][0] = diff.toString();
            data[i][1] = xpByDifficulty.get(diff);
            data[i][2] = coinsByDifficulty.get(diff);

            totalXP += xpByDifficulty.get(diff);
            totalCoins += coinsByDifficulty.get(diff);
            i++;
        }

        // Add total row
        data[i][0] = "TOTAL";
        data[i][1] = totalXP;
        data[i][2] = totalCoins;

        // Create table
        JTable earningsTable = new JTable(data, columnNames);
        earningsTable.setFont(new Font("Monospaced", Font.PLAIN, 14));
        earningsTable.getTableHeader().setFont(fontManager.getSubheaderFont());
        earningsTable.setRowHeight(30);
        earningsTable.setEnabled(false); // Make it non-editable

        // Make the total row bold
        earningsTable.setDefaultRenderer(Object.class, new DefaultTableCellRenderer() {
            @Override
            public Component getTableCellRendererComponent(JTable table, Object value,
                    boolean isSelected, boolean hasFocus, int row, int column) {
                Component c = super.getTableCellRendererComponent(
                        table, value, isSelected, hasFocus, row, column);

                if (row == Task.Difficulty.values().length) {
                    c.setFont(new Font("Monospaced", Font.BOLD, 14));
                    c.setBackground(new Color(240, 240, 240));
                } else {
                    c.setFont(new Font("Monospaced", Font.PLAIN, 14));
                    c.setBackground(ColorPalette.SL_CARD);
                }

                return c;
            }
        });

        panel.add(new JScrollPane(earningsTable), BorderLayout.CENTER);

        return panel;
    }

    private JPanel createConsistencyPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout());
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Study Consistency", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // For now, just show a placeholder message
        JLabel placeholderLabel = new JLabel(
            "<html><div style='text-align: center;'>" +
            "Study consistency tracking will show your daily and weekly study patterns.<br><br>" +
            "This feature would display a calendar heatmap showing days when you completed tasks.<br>" +
            "It would also calculate your study streaks and average tasks per day.<br><br>" +
            "Complete more tasks to see your study patterns emerge!" +
            "</div></html>"
        );
        placeholderLabel.setFont(new Font("Monospaced", Font.PLAIN, 14));
        placeholderLabel.setHorizontalAlignment(SwingConstants.CENTER);

        panel.add(placeholderLabel, BorderLayout.CENTER);

        return panel;
    }

    // FIX: Match the exact math formula from User.java
    private int calculateXPForLevel(int level) {
        return 100 * (int) Math.pow(1.5, level - 1);
    }

    private JPanel createAdvancedStatsPanel() {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout());
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createCompoundBorder(
            BorderFactory.createTitledBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY),
                "Advanced Statistics", TitledBorder.LEFT, TitledBorder.TOP, fontManager.getSubheaderFont(), ColorPalette.SL_ACCENT),
            BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));

        // Calculate advanced statistics
        double avgXpPerTask = 0;
        double avgCoinsPerTask = 0;
        int totalTasksCompleted = 0;
        int totalHardTasksCompleted = 0;

        for (Task task : user.getTasks()) {
            if (task.isCompleted()) {
                totalTasksCompleted++;
                avgXpPerTask += task.getXpReward();
                avgCoinsPerTask += task.getCoinReward();

                if (task.getDifficulty() == Task.Difficulty.HARD) {
                    totalHardTasksCompleted++;
                }
            }
        }

        if (totalTasksCompleted > 0) {
            avgXpPerTask /= totalTasksCompleted;
            avgCoinsPerTask /= totalTasksCompleted;
        }

        // Format advanced statistics
        String[] statNames = {
            "Average XP Per Task",
            "Average Coins Per Task",
            "Completion Rate",
            "Hard Tasks Completion",
            "Estimated Next Level In"
        };

        String[] statValues = {
            String.format("%.1f", avgXpPerTask),
            String.format("%.1f", avgCoinsPerTask),
            totalTasksCompleted + "/" + user.getTasks().size() + " (" +
                (user.getTasks().size() > 0 ?
                    String.format("%.1f%%", (totalTasksCompleted * 100.0 / user.getTasks().size())) :
                    "0%") + ")",
            totalHardTasksCompleted + " tasks",
            estimateTimeToNextLevel() + " tasks"
        };

        // Create grid panel for stats
        JPanel statsGrid = new JPanel(new GridLayout(statNames.length, 2, 10, 5));
        statsGrid.setBackground(ColorPalette.SL_CARD);

        for (int i = 0; i < statNames.length; i++) {
            JLabel nameLabel = new JLabel(statNames[i]);
            nameLabel.setFont(new Font("Monospaced", Font.BOLD, 14));
            nameLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);

            JLabel valueLabel = new JLabel(statValues[i]);
            valueLabel.setFont(new Font("Monospaced", Font.PLAIN, 14));
            valueLabel.setForeground(ColorPalette.SL_ACCENT);

            statsGrid.add(nameLabel);
            statsGrid.add(valueLabel);
        }

        panel.add(statsGrid, BorderLayout.CENTER);
        return panel;
    }

    private String estimateTimeToNextLevel() {
        int currentLevel = user.getLevel();
        int currentXP = user.getXp();
        
        // FIX: The calculateXPForLevel correctly evaluates the TOTAL xp required for the active level
        int xpNeeded = calculateXPForLevel(currentLevel) - currentXP;

        // Calculate average XP per completed task
        double avgXpPerTask = 0;
        int completedTasks = 0;

        for (Task task : user.getTasks()) {
            if (task.isCompleted()) {
                avgXpPerTask += task.getXpReward();
                completedTasks++;
            }
        }

        if (completedTasks > 0) {
            avgXpPerTask /= completedTasks;
            return String.format("~%.1f", xpNeeded / avgXpPerTask);
        } else {
            return "N/A (no completed tasks)";
        }
    }
}