package com.mdjunayet.studyleveling.multiplayer;

import com.mdjunayet.studyleveling.leaderboard.LeaderboardScreen;
import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.service.FirebaseManager;
import com.mdjunayet.studyleveling.service.FirebaseRoomManager;
import com.mdjunayet.studyleveling.task.Task;
import com.mdjunayet.studyleveling.ui.MainMenu;
import com.mdjunayet.studyleveling.util.ThemeManager;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MultiplayerStudyScreen extends JFrame {
    private final List<User> users;
    private final Map<String, User> originalUserData = new HashMap<>(); // Store original user data snapshots
    private final MainMenu mainMenu; // Reference to the main menu for direct updates
    private final ThemeManager themeManager = ThemeManager.getInstance();
    private final boolean isAwayMode;
    private final String roomId;

    // Competitive timer properties
    private final boolean competitiveTimerMode;
    private final int timerMinutes;
    private CompetitiveTimerPanel competitiveTimer;

    // Map to track completion times for competitive mode
    private final Map<String, Long> completionTimes = new HashMap<>();
    private Long firstCompletionTime = null;

    private JLabel roomInfoLabel;
    private JButton copyRoomIdButton;

    // Constructor for backward compatibility
    public MultiplayerStudyScreen(List<User> users, MainMenu mainMenu) {
        this(users, mainMenu, false, null, 0, false, 30);
    }

    // Constructor with support for Away mode
    public MultiplayerStudyScreen(List<User> users, MainMenu mainMenu, boolean isAwayMode, String roomId) {
        this(users, mainMenu, isAwayMode, roomId, 0, false, 30);
    }

    // Constructor with maxPlayers parameter
    public MultiplayerStudyScreen(List<User> users, MainMenu mainMenu, boolean isAwayMode, String roomId, int maxPlayers) {
        this(users, mainMenu, isAwayMode, roomId, maxPlayers, false, 30);
    }

    // New constructor with competitive timer parameters
    public MultiplayerStudyScreen(List<User> users, MainMenu mainMenu, boolean isAwayMode, String roomId, int maxPlayers,
                                  boolean competitiveTimerMode, int timerMinutes) {
        this.users = users;
        this.mainMenu = mainMenu;
        this.isAwayMode = isAwayMode;
        this.roomId = roomId;
        this.competitiveTimerMode = competitiveTimerMode;
        this.timerMinutes = timerMinutes;

        // Save a snapshot of each user's initial state for comparison when closing
        for (User user : users) {
            if (DataManager.userExists(user.getUsername())) {
                // Store the original user data from disk before any multiplayer changes
                originalUserData.put(user.getUsername(), DataManager.loadUser(user.getUsername()));
                System.out.println("Stored original state for " + user.getUsername());

                // Clear all existing tasks for this multiplayer session
                user.getTasks().clear();
                System.out.println("Cleared existing tasks for fresh multiplayer session: " + user.getUsername());
            }
        }

        setTitle(isAwayMode ? "🌐 Online Multiplayer - " + (roomId != null ? "Room: " + roomId : "Joining") : "🤝 Local Multiplayer");
        setSize(1000, 650);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);

        // Use theme-aware background color
        getContentPane().setBackground(themeManager.getColor("background"));

        // Add window listener to sync progress with main accounts when closing
        addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowClosing(java.awt.event.WindowEvent windowEvent) {
                // If in away mode, leave the room in Firebase
                if (isAwayMode && roomId != null && !users.isEmpty()) {
                    FirebaseRoomManager.leaveRoom(roomId, users.get(0).getUsername());
                }

                // If competitive timer is running, stop it
                if (competitiveTimerMode && competitiveTimer != null && competitiveTimer.isTimerRunning()) {
                    competitiveTimer.stopTimer();
                }

                syncUsersWithMainAccounts();
            }
        });

        // Listen for theme changes and update UI accordingly
        themeManager.addThemeChangeListener(e -> refreshTheme());

        // Create the main layout
        setLayout(new BorderLayout(10, 10));

        // Add room info panel if in away mode
        if (isAwayMode && roomId != null) {
            JPanel roomPanel = createRoomInfoPanel();
            add(roomPanel, BorderLayout.NORTH);
        }

        // Main content panel
        JPanel contentPanel = new JPanel(new BorderLayout(10, 10));
        contentPanel.setBackground(themeManager.getColor("background"));

        // Create tabbed pane for users
        JTabbedPane tabbedPane = new JTabbedPane();

        // If competitive mode is enabled, create a prominent timer panel
        if (competitiveTimerMode) {
            // Create our countdown timer
            competitiveTimer = new CompetitiveTimerPanel(timerMinutes);
            competitiveTimer.setOnTimerEndCallback(v -> handleTimerEnd());

            // Create a distinctive panel for the timer
            JPanel timerPanel = new JPanel(new BorderLayout());
            timerPanel.setBackground(new Color(40, 20, 80)); // Dark purple background
            timerPanel.setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createLineBorder(new Color(160, 80, 220), 3), // Bright purple border
                    BorderFactory.createEmptyBorder(10, 10, 10, 10)
            ));

            // Make the timer title
            JLabel timerTitle = new JLabel("⏱️ COMPETITION TIMER");
            timerTitle.setFont(new Font("SansSerif", Font.BOLD, 20));
            timerTitle.setForeground(Color.WHITE);
            timerTitle.setHorizontalAlignment(SwingConstants.CENTER);
            timerTitle.setBorder(BorderFactory.createEmptyBorder(0, 0, 10, 0));

            // Add the timer to the panel with the title
            JPanel innerTimerPanel = new JPanel(new BorderLayout());
            innerTimerPanel.setOpaque(false);
            innerTimerPanel.add(timerTitle, BorderLayout.NORTH);
            innerTimerPanel.add(competitiveTimer, BorderLayout.CENTER);
            timerPanel.add(innerTimerPanel);

            // Add the timer panel to the top of the screen
            add(timerPanel, BorderLayout.NORTH);

            // Note: We no longer start the timer automatically
            // The user will start it manually using the START button
            System.out.println("Competitive timer created with duration: " + timerMinutes + " minutes");
        }

        // Add user tabs
        for (User user : users) {
            JPanel panel = createUserPanel(user);
            tabbedPane.addTab("👤 " + user.getUsername(), panel);
        }

        // Combine the tabbed pane and footer in the main content
        contentPanel.add(tabbedPane, BorderLayout.CENTER);

        // Create footer panel with leaderboard button
        JPanel footerPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        footerPanel.setBackground(themeManager.getColor("panelBackground"));
        footerPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JButton leaderboardBtn = createStyledButton("🏆 Leaderboard");
        leaderboardBtn.addActionListener(e -> new LeaderboardScreen(users));
        footerPanel.add(leaderboardBtn);


        // Only add the footer panel if not in competitive mode (otherwise timer is at bottom)
        if (!competitiveTimerMode) {
            contentPanel.add(footerPanel, BorderLayout.SOUTH);
        } else {
            // If in competitive mode, put leaderboard button at the top right
            JPanel topButtonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
            topButtonPanel.setOpaque(false);
            topButtonPanel.add(leaderboardBtn);
            contentPanel.add(topButtonPanel, BorderLayout.NORTH);
        }

        add(contentPanel, BorderLayout.CENTER);

        setVisible(true);
    }

    private JPanel createRoomInfoPanel() {
        JPanel roomPanel = new JPanel(new BorderLayout());
        roomPanel.setBackground(themeManager.getColor("panelBackground"));
        roomPanel.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));

        roomInfoLabel = new JLabel("<html><div style='text-align: center;'>" +
                "🌐 <b>Online Room:</b> " + roomId +
                (users.size() > 1 ? " | <b>" + users.size() + "</b> user" + (users.size() > 1 ? "s" : "") + " connected" : "") +
                "</div></html>");
        roomInfoLabel.setFont(new Font("Monospaced", Font.BOLD, 14));
        roomInfoLabel.setForeground(themeManager.getColor("text"));
        roomInfoLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Copy Room ID button
        copyRoomIdButton = new JButton("📋 Copy Room ID");
        copyRoomIdButton.setFont(new Font("Monospaced", Font.BOLD, 14));
        copyRoomIdButton.setForeground(themeManager.getColor("buttonText"));
        copyRoomIdButton.setBackground(themeManager.getColor("buttonBackground"));
        copyRoomIdButton.setBorder(BorderFactory.createLineBorder(
                themeManager.isDarkTheme() ? Color.GRAY : Color.BLACK, 2));
        copyRoomIdButton.addActionListener(e -> {
            StringSelection selection = new StringSelection(roomId);
            Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
            clipboard.setContents(selection, null);
            JOptionPane.showMessageDialog(this, "Room ID copied to clipboard!");
        });

        // Add a button to refresh room participants
        JButton refreshRoomButton = new JButton("🔄 Refresh Room");
        refreshRoomButton.setFont(new Font("Monospaced", Font.BOLD, 14));
        refreshRoomButton.setForeground(themeManager.getColor("buttonText"));
        refreshRoomButton.setBackground(themeManager.getColor("buttonBackground"));
        refreshRoomButton.setBorder(BorderFactory.createLineBorder(
                themeManager.isDarkTheme() ? Color.GRAY : Color.BLACK, 2));
        refreshRoomButton.addActionListener(e -> {
            refreshRoomParticipants();
        });

        JPanel roomControlsPanel = new JPanel(new FlowLayout(FlowLayout.CENTER));
        roomControlsPanel.setOpaque(false);
        roomControlsPanel.add(copyRoomIdButton);
        roomControlsPanel.add(refreshRoomButton);

        roomPanel.add(roomInfoLabel, BorderLayout.CENTER);
        roomPanel.add(roomControlsPanel, BorderLayout.EAST);
        return roomPanel;
    }

    private JPanel createUserPanel(User user) {
        JPanel panel = new JPanel();
        panel.setLayout(new BorderLayout(10, 10));
        // Use theme-aware background color
        panel.setBackground(themeManager.getColor("panelBackground"));
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // === Task List ===
        DefaultListModel<Task> model = new DefaultListModel<>();
        JList<Task> taskList = new JList<>(model);
        user.getTasks().forEach(model::addElement);
        taskList.setFont(new Font("Monospaced", Font.PLAIN, 14));
        // Set foreground for dark mode compatibility
        taskList.setForeground(themeManager.getColor("text"));
        taskList.setBackground(themeManager.getColor("cardBackground"));

        // Add a custom cell renderer to handle theme-specific text colors
        taskList.setCellRenderer(new DefaultListCellRenderer() {
            @Override
            public Component getListCellRendererComponent(JList<?> list, Object value, int index,
                                                          boolean isSelected, boolean cellHasFocus) {
                super.getListCellRendererComponent(list, value, index, isSelected, cellHasFocus);

                if (value instanceof Task) {
                    Task task = (Task) value;
                    String status = task.isCompleted() ? "✓" : "○";
                    String text = status + " " + task.getDescription() + " [" + task.getDifficulty() + "] ⭐" +
                            task.getXpReward() + " 💰" + task.getCoinReward();
                    setText(text);

                    // Set appropriate foreground color based on theme and selection state
                    if (!isSelected) {
                        setForeground(themeManager.getColor("text"));
                    }
                }

                return this;
            }
        });

        JScrollPane scrollPane = new JScrollPane(taskList);

        // Create a titled border with proper theme-aware colors
        javax.swing.border.TitledBorder titledBorder = BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(themeManager.getColor("accent"), 1),
                "📋 Tasks"
        );
        titledBorder.setTitleFont(new Font("Monospaced", Font.BOLD, 14));
        titledBorder.setTitleColor(themeManager.getColor("text")); // Use text color instead of accent for better visibility
        titledBorder.setTitleJustification(TitledBorder.LEFT);
        titledBorder.setTitlePosition(TitledBorder.TOP);

        scrollPane.setBorder(titledBorder);

        // === Input Fields ===
        JTextField taskField = new JTextField(20);
        JTextField xpField = new JTextField("50", 4);
        JTextField coinField = new JTextField("20", 4);
        JComboBox<Task.Difficulty> difficultyBox = new JComboBox<>(Task.Difficulty.values());

        JButton add = createStyledButton("➕ Add Task");
        JButton complete = createStyledButton("✅ Complete Task");
        JButton delete = createStyledButton("🗑 Delete Task");  // New delete task button

        JPanel inputPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        inputPanel.setOpaque(false);
        inputPanel.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createLineBorder(themeManager.getColor("accent"), 1),
                "📝 Add New Task",
                TitledBorder.LEFT,
                TitledBorder.TOP,
                new Font("Monospaced", Font.BOLD, 14),
                themeManager.getColor("accent")
        ));

        // Create labels with theme-aware text colors
        JLabel xpLabel = new JLabel("⭐ XP:");
        JLabel coinsLabel = new JLabel("💰 Coins:");
        JLabel difficultyLabel = new JLabel("⚙ Difficulty:");

        // Set foreground color for labels
        xpLabel.setForeground(themeManager.getColor("text"));
        coinsLabel.setForeground(themeManager.getColor("text"));
        difficultyLabel.setForeground(themeManager.getColor("text"));

        inputPanel.add(taskField);
        inputPanel.add(xpLabel);
        inputPanel.add(xpField);
        inputPanel.add(coinsLabel);
        inputPanel.add(coinField);
        inputPanel.add(difficultyLabel);
        inputPanel.add(difficultyBox);
        inputPanel.add(add);

        JPanel buttonPanel = new JPanel();
        buttonPanel.setOpaque(false);
        buttonPanel.add(complete);
        buttonPanel.add(delete); // Add delete button to the panel

        JPanel listPanel = new JPanel(new BorderLayout());
        listPanel.setOpaque(false);
        listPanel.add(scrollPane, BorderLayout.CENTER);
        listPanel.add(buttonPanel, BorderLayout.SOUTH);

        panel.add(inputPanel, BorderLayout.NORTH);
        panel.add(listPanel, BorderLayout.CENTER);

        // === Event Handlers ===
        add.addActionListener(e -> {
            String desc = taskField.getText().trim();
            if (!desc.isEmpty()) {
                try {
                    Task.Difficulty diff = (Task.Difficulty) difficultyBox.getSelectedItem();

                    // Create task with automatic XP and coin rewards based on difficulty
                    Task task = new Task(desc, diff);

                    // Update the XP and coin fields to show the auto-calculated values
                    xpField.setText(String.valueOf(task.getXpReward()));
                    coinField.setText(String.valueOf(task.getCoinReward()));

                    user.getTasks().add(task);
                    model.addElement(task);
                    taskField.setText("");
                    DataManager.saveUser(user);
                } catch (NumberFormatException ex) {
                    JOptionPane.showMessageDialog(this, "XP and Coins must be numbers.");
                }
            }
        });

        complete.addActionListener(e -> {
            Task task = taskList.getSelectedValue();
            if (task != null && !task.isCompleted()) {
                task.setCompleted(true);

                // Handle XP reward based on competitive mode
                int xpReward = task.getXpReward();
                int coinReward = task.getCoinReward();

                if (competitiveTimerMode && competitiveTimer != null && competitiveTimer.isTimerRunning()) {
                    // Calculate adjusted XP based on completion order
                    xpReward = recordCompetitiveTaskCompletion(user, task);

                    // Show completion message with adjusted XP
                    String completionMessage = user.getUsername() + " completed a task!";

                    if (firstCompletionTime != null && completionTimes.get(user.getUsername()) == firstCompletionTime) {
                        completionMessage += "\n🥇 FIRST TO COMPLETE - FULL REWARD!";
                    } else {
                        double reductionPercent = 100.0 * (1 - (double)xpReward / task.getXpReward());
                        completionMessage += String.format("\n⏱️ XP reduced by %.0f%% due to later completion", reductionPercent);
                    }

                    completionMessage += "\n+ " + xpReward + " XP (original: " + task.getXpReward() + ")";
                    completionMessage += "\n+ " + coinReward + " Coins";

                    JOptionPane.showMessageDialog(this, completionMessage, "Task Completed", JOptionPane.INFORMATION_MESSAGE);
                } else {
                    // Standard completion message (non-competitive mode)
                    JOptionPane.showMessageDialog(this,
                            user.getUsername() + " completed a task! + " +
                                    xpReward + " XP, + " + coinReward + " Coins!",
                            "Task Completed", JOptionPane.INFORMATION_MESSAGE);
                }

                // Apply the rewards to the user
                user.addXP(xpReward);
                user.addCoins(coinReward);
                user.incrementCompletedTasksCounter();

                // Update UI and save
                taskList.repaint();
                DataManager.saveUser(user);

                // Upload stats to Firebase leaderboard whenever a task is completed
                FirebaseManager.uploadUserStats(user);
            }
        });

        // New event handler for delete button
        delete.addActionListener(e -> {
            Task task = taskList.getSelectedValue();
            if (task != null) {
                user.getTasks().remove(task);
                model.removeElement(task);
                DataManager.saveUser(user);
            }
        });

        return panel;
    }

    private JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFocusPainted(false);
        // Use theme-aware colors
        button.setBackground(themeManager.getColor("buttonBackground"));
        button.setForeground(themeManager.getColor("buttonText"));
        button.setFont(new Font("Monospaced", Font.BOLD, 14));
        // Use different border color for dark mode
        button.setBorder(BorderFactory.createLineBorder(
                themeManager.isDarkTheme() ? Color.GRAY : Color.BLACK, 2));
        return button;
    }

    private void syncUsersWithMainAccounts() {
        for (User user : users) {
            // Check if this is a real user (not a guest) by verifying if they exist in storage
            if (DataManager.userExists(user.getUsername())) {
                // Skip users that don't have original data
                if (!originalUserData.containsKey(user.getUsername())) {
                    System.out.println("No original data for " + user.getUsername() + ", skipping sync");
                    continue;
                }

                System.out.println("Syncing multiplayer progress for user: " + user.getUsername());

                // Get the original user data from our stored snapshot
                User originalUser = originalUserData.get(user.getUsername());

                // Calculate what was gained during this multiplayer session
                int currentXP = user.getXp();
                int originalXP = originalUser.getXp();
                int xpGained = currentXP - originalXP;

                int currentCoins = user.getCoins();
                int originalCoins = originalUser.getCoins();
                int coinsGained = currentCoins - originalCoins;

                // Count how many tasks were completed in this multiplayer session
                int completedTasksInSession = 0;
                for (Task task : user.getTasks()) {
                    if (task.isCompleted()) {
                        completedTasksInSession++;
                    }
                }
                System.out.println("Tasks completed in this session: " + completedTasksInSession);

                System.out.println("Original state - XP: " + originalXP + ", Coins: " + originalCoins);
                System.out.println("Current state - XP: " + currentXP + ", Coins: " + currentCoins);
                System.out.println("Session gains - XP: " + xpGained + ", Coins: " + coinsGained);

                // Only proceed with sync if there were actual gains or completed tasks
                if (xpGained <= 0 && coinsGained <= 0 && completedTasksInSession == 0) {
                    System.out.println("No gains to sync for " + user.getUsername());
                    continue;
                }

                // Check if this user is the currently logged-in user from the main menu
                if (mainMenu != null && mainMenu.getUser().getUsername().equals(user.getUsername())) {
                    System.out.println("This is the main menu user - will update UI directly");

                    // Update the main menu user directly (this will update the UI immediately)
                    // Note: We don't need to add XP and coins again because they were already added
                    // when the user completed the tasks during the multiplayer session
                    // The multiplayer user object already has the updated values
                    // mainMenu.updateUserFromMultiplayer(xpGained, coinsGained);

                    // Instead, we'll directly set the values from the multiplayer session
                    User mainUser = mainMenu.getUser();
                    mainUser.setXp(user.getXp());
                    mainUser.setLevel(user.getLevel());
                    mainUser.setCoins(user.getCoins());

                    // Refresh the main menu UI to show updated stats immediately
                    mainMenu.refreshStats();

                    // Update the total completed tasks counter for each completed task in this session
                    // We need to do this because we previously cleared the tasks when starting the session
                    for (int i = 0; i < completedTasksInSession; i++) {
                        mainUser.incrementCompletedTasksCounter();
                    }

                    // Transfer newly completed tasks from multiplayer session to main account
                    for (Task task : user.getTasks()) {
                        if (task.isCompleted()) {
                            // Skip tasks that were already completed in the original state
                            boolean wasCompletedBefore = false;
                            for (Task originalTask : originalUser.getTasks()) {
                                if (originalTask.getDescription().equals(task.getDescription()) &&
                                        originalTask.isCompleted()) {
                                    wasCompletedBefore = true;
                                    break;
                                }
                            }

                            if (wasCompletedBefore) {
                                continue;
                            }

                            // Add completed task to main user if it doesn't exist
                            boolean taskExistsInMain = false;
                            for (Task mainTask : mainUser.getTasks()) {
                                if (mainTask.getDescription().equals(task.getDescription())) {
                                    taskExistsInMain = true;
                                    // Mark as completed if not already
                                    if (!mainTask.isCompleted()) {
                                        mainTask.setCompleted(true);
                                    }
                                    break;
                                }
                            }

                            if (!taskExistsInMain) {
                                Task newTask = new Task(
                                        task.getDescription(),
                                        task.getXpReward(),
                                        task.getCoinReward(),
                                        task.getDifficulty()
                                );
                                newTask.setCompleted(true);
                                mainUser.getTasks().add(newTask);
                            }
                        }
                    }

                    // Upload stats to Firebase to update the global leaderboard
                    FirebaseManager.uploadUserStats(mainUser);

                    // Show message about progress saved
                    String progressMessage = "Progress for " + user.getUsername() + " has been saved to main account!";
                    if (xpGained > 0) {
                        progressMessage += "\nXP gained: " + xpGained;
                    }
                    if (coinsGained > 0) {
                        progressMessage += "\nCoins gained: " + coinsGained;
                    }

                    JOptionPane.showMessageDialog(this,
                            progressMessage,
                            "Progress Saved", JOptionPane.INFORMATION_MESSAGE);

                    continue; // Skip the standard sync process for this user
                }

                // Standard sync process for non-main menu users
                User mainUser = DataManager.loadUser(user.getUsername());
                if (mainUser != null) {
                    // Store state before applying changes for confirmation message
                    int beforeXP = mainUser.getXp();
                    int beforeLevel = mainUser.getLevel();
                    int beforeCoins = mainUser.getCoins();

                    System.out.println("Main account before sync - XP: " + beforeXP + ", Coins: " + beforeCoins);

                    // Apply the gains directly to the main account
                    if (xpGained > 0) {
                        mainUser.addXP(xpGained);
                    }

                    if (coinsGained > 0) {
                        mainUser.addCoins(coinsGained);
                    }

                    System.out.println("Main account after sync - XP: " + mainUser.getXp() + ", Coins: " + mainUser.getCoins());

                    // Update the total completed tasks counter for each completed task in this session
                    // We need to do this because we previously cleared the tasks when starting the session
                    for (int i = 0; i < completedTasksInSession; i++) {
                        mainUser.incrementCompletedTasksCounter();
                    }

                    // Transfer newly completed tasks from multiplayer session to main account
                    for (Task task : user.getTasks()) {
                        if (task.isCompleted()) {
                            // Skip tasks that were already completed in the original state
                            boolean wasCompletedBefore = false;
                            for (Task originalTask : originalUser.getTasks()) {
                                if (originalTask.getDescription().equals(task.getDescription()) &&
                                        originalTask.isCompleted()) {
                                    wasCompletedBefore = true;
                                    break;
                                }
                            }

                            if (wasCompletedBefore) {
                                System.out.println("Task was already completed before: " + task.getDescription());
                                continue;
                            }

                            // Now check if task exists in main account and update it
                            boolean taskExistsInMain = false;
                            for (Task mainTask : mainUser.getTasks()) {
                                if (mainTask.getDescription().equals(task.getDescription())) {
                                    taskExistsInMain = true;
                                    // Mark as completed if not already
                                    if (!mainTask.isCompleted()) {
                                        mainTask.setCompleted(true);
                                    }
                                    break;
                                }
                            }

                            // Add task to main account if it doesn't exist
                            if (!taskExistsInMain) {
                                Task newTask = new Task(
                                        task.getDescription(),
                                        task.getXpReward(),
                                        task.getCoinReward(),
                                        task.getDifficulty()
                                );
                                newTask.setCompleted(true);
                                mainUser.getTasks().add(newTask);
                                System.out.println("Added new completed task to main account: " + task.getDescription());
                            }
                        }
                    }

                    // Save the updated main user data
                    DataManager.saveUser(mainUser);

                    // Upload stats to Firebase to update the global leaderboard
                    FirebaseManager.uploadUserStats(mainUser);

                    // Calculate actual gains for display
                    int actualXPGained = mainUser.getXp() - beforeXP;
                    int levelsGained = mainUser.getLevel() - beforeLevel;
                    int actualCoinsGained = mainUser.getCoins() - beforeCoins;

                    // Show message about progress saved
                    String progressMessage = "Progress for " + user.getUsername() + " has been saved to main account!";
                    if (actualXPGained > 0) {
                        progressMessage += "\nXP gained: " + actualXPGained;
                    }
                    if (levelsGained > 0) {
                        progressMessage += "\nLevels gained: " + levelsGained;
                    }
                    if (actualCoinsGained > 0) {
                        progressMessage += "\nCoins gained: " + actualCoinsGained;
                    }
                    if (completedTasksInSession > 0) {
                        progressMessage += "\nTasks completed: " + completedTasksInSession;
                    }

                    JOptionPane.showMessageDialog(this,
                            progressMessage,
                            "Progress Saved", JOptionPane.INFORMATION_MESSAGE);
                }
            } else {
                // This is a guest user, just save their current state
                DataManager.saveUser(user);
            }
        }
    }

    /**
     * Update the room info label with current user count
     *
     * @param userCount number of users in the room
     */
    public void updateRoomInfo(int userCount) {
        if (roomInfoLabel != null && isAwayMode && roomId != null) {
            roomInfoLabel.setText("<html><div style='text-align: center;'>" +
                    "🌐 <b>Online Room:</b> " + roomId +
                    " | <b>" + userCount + "</b> user" + (userCount > 1 ? "s" : "") + " connected" +
                    "</div></html>");
        }
    }

    /**
     * Refresh the list of participants in the room
     * @param showNotifications whether to show notification popups (true for manual refresh, false for automatic)
     */
    private void refreshRoomParticipants(boolean showNotifications) {
        if (!isAwayMode || roomId == null) return;

        // Get users from Firebase
        List<String> roomUsers = FirebaseRoomManager.getUsersInRoom(roomId);

        // If there are new users that we don't have in our local list, load them
        List<User> newUsers = new ArrayList<>();
        for (String username : roomUsers) {
            // Skip users we already have
            boolean alreadyHave = false;
            for (User existingUser : users) {
                if (existingUser.getUsername().equals(username)) {
                    alreadyHave = true;
                    break;
                }
            }

            if (!alreadyHave) {
                User user = DataManager.loadUser(username);
                if (user != null) {
                    newUsers.add(user);
                }
            }
        }

        // If we found new users, add them to our local list and update the UI
        if (!newUsers.isEmpty()) {
            for (User newUser : newUsers) {
                users.add(newUser);
                JPanel panel = createUserPanel(newUser);
                ((JTabbedPane) getContentPane().getComponent(1)).addTab("👤 " + newUser.getUsername(), panel);
            }

            updateRoomInfo(users.size());

            if (showNotifications) {
                JOptionPane.showMessageDialog(this,
                        newUsers.size() + " new user(s) joined the room!",
                        "Users Joined",
                        JOptionPane.INFORMATION_MESSAGE);
            }
        } else if (showNotifications) {
            JOptionPane.showMessageDialog(this,
                    "No new users found in the room.",
                    "Room Refresh",
                    JOptionPane.INFORMATION_MESSAGE);
        }
    }

    /**
     * Refresh the list of participants in the room with notifications
     * This is called when the refresh button is clicked
     */
    public void refreshRoomParticipants() {
        refreshRoomParticipants(true);
    }

    /**
     * Update the theme for all components
     */
    private void refreshTheme() {
        // Update frame and components to use the new theme colors
        getContentPane().setBackground(themeManager.getColor("background"));

        // Update the tabbed pane and all panels
        for (Component comp : getContentPane().getComponents()) {
            if (comp instanceof JTabbedPane) {
                JTabbedPane tabbedPane = (JTabbedPane) comp;
                tabbedPane.setBackground(themeManager.getColor("background"));
                tabbedPane.setForeground(themeManager.getColor("text"));

                // Update each tab's panel
                for (int i = 0; i < tabbedPane.getTabCount(); i++) {
                    Component tabComp = tabbedPane.getComponentAt(i);
                    if (tabComp instanceof JPanel) {
                        updatePanelColors((JPanel) tabComp);
                    }
                }
            } else if (comp instanceof JPanel) {
                updatePanelColors((JPanel) comp);
            }
        }

        // Force the UI to refresh
        SwingUtilities.updateComponentTreeUI(this);
    }

    private void updatePanelColors(JPanel panel) {
        panel.setBackground(themeManager.getColor("panelBackground"));

        // Recursively update all components in the panel
        for (Component comp : panel.getComponents()) {
            if (comp instanceof JLabel) {
                JLabel label = (JLabel) comp;
                label.setForeground(themeManager.getColor("text"));
            } else if (comp instanceof JButton) {
                JButton button = (JButton) comp;
                button.setBackground(themeManager.getColor("buttonBackground"));
                button.setForeground(themeManager.getColor("buttonText"));
                button.setBorder(BorderFactory.createLineBorder(
                        themeManager.isDarkTheme() ? Color.GRAY : Color.BLACK, 2));
            } else if (comp instanceof JList) {
                JList<?> list = (JList<?>) comp;
                list.setBackground(themeManager.getColor("cardBackground"));
                list.setForeground(themeManager.getColor("text"));
            } else if (comp instanceof JScrollPane) {
                JScrollPane scrollPane = (JScrollPane) comp;
                scrollPane.getViewport().setBackground(themeManager.getColor("cardBackground"));
                if (scrollPane.getBorder() instanceof javax.swing.border.TitledBorder) {
                    javax.swing.border.TitledBorder titledBorder = (javax.swing.border.TitledBorder) scrollPane.getBorder();
                    titledBorder.setTitleColor(themeManager.getColor("accent"));
                }

                // Update the viewport's view
                Component view = scrollPane.getViewport().getView();
                if (view instanceof JList) {
                    JList<?> list = (JList<?>) view;
                    list.setBackground(themeManager.getColor("cardBackground"));
                    list.setForeground(themeManager.getColor("text"));
                }
            } else if (comp instanceof JPanel) {
                updatePanelColors((JPanel) comp);
            }
        }
    }

    /**
     * Handles what happens when the competitive timer ends
     */
    private void handleTimerEnd() {
        // Show a summary of who completed tasks and their rewards
        StringBuilder summaryMessage = new StringBuilder();
        summaryMessage.append("Time's up! Competition results:\n\n");

        boolean anyCompleted = false;

        for (User user : users) {
            int completedTasks = 0;
            for (Task task : user.getTasks()) {
                if (task.isCompleted()) {
                    completedTasks++;
                    anyCompleted = true;
                }
            }

            if (completedTasks > 0) {
                summaryMessage.append(user.getUsername())
                        .append(": ")
                        .append(completedTasks)
                        .append(" task(s) completed\n");
            } else {
                summaryMessage.append(user.getUsername())
                        .append(": No tasks completed\n");
            }
        }

        if (!anyCompleted) {
            summaryMessage.append("\nNo one completed any tasks within the time limit!");
        }

        // Show completion summary
        JOptionPane.showMessageDialog(
                this,
                summaryMessage.toString(),
                "Competition Results",
                JOptionPane.INFORMATION_MESSAGE
        );
    }

    /**
     * Records task completion for a user in competitive mode and adjusts XP rewards
     * based on completion order.
     *
     * @param user The user completing the task
     * @param task The task being completed
     * @return The adjusted XP reward
     */
    private int recordCompetitiveTaskCompletion(User user, Task task) {
        // Record completion time
        long currentTime = System.currentTimeMillis();
        completionTimes.put(user.getUsername(), currentTime);

        // If this is the first completion, record it
        if (firstCompletionTime == null) {
            firstCompletionTime = currentTime;
            return task.getXpReward(); // First user gets full XP
        }

        // Calculate time difference in seconds
        long timeDifferenceSeconds = (currentTime - firstCompletionTime) / 1000;

        // Calculate XP reduction factor based on delay
        // Formula: reduction = min(0.75, timeDiff / (timerMinutes * 60) * 0.75)
        // This means a maximum reduction of 75% of XP, scaling with how much of the total time has passed
        double reductionFactor = Math.min(0.75, (double) timeDifferenceSeconds / (timerMinutes * 60) * 0.75);
        int adjustedXP = (int) Math.round(task.getXpReward() * (1 - reductionFactor));

        return Math.max(adjustedXP, task.getXpReward() / 4); // Ensure at least 25% of original XP
    }
}

