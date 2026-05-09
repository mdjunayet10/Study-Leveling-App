package com.mdjunayet.studyleveling.task;

import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.service.FirebaseLeaderboard;
import com.mdjunayet.studyleveling.session.StudyTimerPanel;
import com.mdjunayet.studyleveling.ui.MainMenu;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;

public class StudyScreen extends JFrame {
    private final DefaultListModel<Task> taskListModel = new DefaultListModel<>();
    private final DefaultListModel<Task> recommendedListModel = new DefaultListModel<>();
    private final JList<Task> taskList = new JList<>(taskListModel);
    private final JList<Task> recommendedList = new JList<>(recommendedListModel);
    private final MainMenu mainMenu;
    private final User user;
    private StudyTimerPanel timerPanel;
    private final FontManager fontManager = FontManager.getInstance();

    public StudyScreen(MainMenu mainMenu) {
        this.mainMenu = mainMenu;
        this.user = mainMenu.getUser();

        setTitle("Study Leveling");
        setSize(900, 700);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout());

        // Apply Solo Leveling theme
        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Add window listener to stop timer when closing
        addWindowListener(new java.awt.event.WindowAdapter() {
            @Override
            public void windowClosing(java.awt.event.WindowEvent windowEvent) {
                if (timerPanel != null) {
                    timerPanel.stopTimer();
                }
                dispose();
                mainMenu.refreshStats();
            }
        });

        // Create header panel
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);

        // Main content panel
        JPanel contentPanel = new JPanel(new BorderLayout(15, 15));
        contentPanel.setBackground(ColorPalette.SL_BACKGROUND);
        contentPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 20, 20));

        // Left panel with timer and tasks
        JPanel leftPanel = new JPanel(new BorderLayout(0, 15));
        leftPanel.setOpaque(false);

        // Timer panel with Solo Leveling style
        timerPanel = new StudyTimerPanel();
        leftPanel.add(timerPanel, BorderLayout.NORTH);

        // Tasks panel
        JPanel tasksPanel = createTasksPanel();
        leftPanel.add(tasksPanel, BorderLayout.CENTER);

        // Right panel with recommended tasks
        JPanel rightPanel = createRecommendedPanel();

        // Add panels to content panel
        contentPanel.add(leftPanel, BorderLayout.CENTER);
        contentPanel.add(rightPanel, BorderLayout.EAST);

        add(contentPanel, BorderLayout.CENTER);

        // Bottom panel with action buttons
        JPanel actionPanel = createActionPanel();
        add(actionPanel, BorderLayout.SOUTH);

        loadUserTasks();
        loadRecommendedTasks();

        setVisible(true);
    }

    private JPanel createHeaderPanel() {
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        headerPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        JLabel titleLabel = new JLabel("STUDY MISSIONS");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JLabel userLabel = new JLabel(user.getUsername() + " | LVL " + user.getLevel());
        userLabel.setFont(fontManager.getSubheaderFont());
        userLabel.setForeground(ColorPalette.SL_ACCENT);

        headerPanel.add(titleLabel, BorderLayout.WEST);
        headerPanel.add(userLabel, BorderLayout.EAST);

        return headerPanel;
    }

    private JPanel createTasksPanel() {
        JPanel panel = new JPanel(new BorderLayout(0, 10));
        panel.setOpaque(false);

        // Title with improved styling
        JLabel titleLabel = new JLabel("YOUR TASKS");
        titleLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
        titleLabel.setForeground(ColorPalette.SL_ACCENT_BRIGHT);
        titleLabel.setBorder(BorderFactory.createEmptyBorder(0, 5, 5, 0));

        // Task list with enhanced Solo Leveling style
        taskList.setBackground(ColorPalette.SL_CARD);
        taskList.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        taskList.setFont(fontManager.getBodyFont());
        taskList.setSelectionBackground(new Color(80, 40, 120)); // Richer purple selection
        taskList.setSelectionForeground(new Color(240, 240, 255)); // Brighter text on selection
        taskList.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));
        taskList.setFixedCellHeight(40); // Taller cells for better readability

        // Custom renderer for tasks with enhanced styling
        taskList.setCellRenderer(new DefaultListCellRenderer() {
            @Override
            public Component getListCellRendererComponent(JList<?> list, Object value,
                                                          int index, boolean isSelected, boolean cellHasFocus) {
                JPanel panel = new JPanel(new BorderLayout(10, 0));
                panel.setBorder(BorderFactory.createEmptyBorder(5, 8, 5, 8));

                if (isSelected) {
                    panel.setBackground(new Color(80, 40, 120)); // Richer purple selection
                    // Add a left accent border to show it's selected
                    panel.setBorder(BorderFactory.createCompoundBorder(
                            BorderFactory.createMatteBorder(0, 3, 0, 0, ColorPalette.SL_ACCENT_BRIGHT),
                            BorderFactory.createEmptyBorder(5, 8, 5, 8)
                    ));
                } else {
                    panel.setBackground(ColorPalette.SL_CARD);
                }

                if (value instanceof Task) {
                    Task task = (Task) value;

                    // Create the main content panel with status and description
                    JPanel contentPanel = new JPanel(new BorderLayout(5, 0));
                    contentPanel.setOpaque(false);

                    // Status icon with proper styling
                    String statusIcon = task.isCompleted() ? "✓" : "•";
                    JLabel statusLabel = new JLabel(statusIcon);
                    statusLabel.setFont(new Font("Dialog", Font.BOLD, 16));

                    // Extract priority symbols if present in the description
                    String description = task.getDescription();
                    String prioritySymbol = "";

                    if (description.startsWith("🔥 ")) {
                        prioritySymbol = "🔥 ";
                        description = description.substring(2);
                    } else if (description.startsWith("⚡ ")) {
                        prioritySymbol = "⚡ ";
                        description = description.substring(2);
                    } else if (description.startsWith("📌 ")) {
                        prioritySymbol = "📌 ";
                        description = description.substring(2);
                    }

                    // Set status icon color based on completion and priority
                    if (task.isCompleted()) {
                        statusLabel.setForeground(isSelected ? new Color(150, 255, 150) : ColorPalette.SL_TEXT_SECONDARY);
                    } else if (prioritySymbol.equals("🔥 ")) {
                        statusLabel.setForeground(isSelected ? new Color(255, 180, 180) : new Color(255, 100, 100));
                    } else if (prioritySymbol.equals("⚡ ")) {
                        statusLabel.setForeground(isSelected ? new Color(255, 255, 180) : new Color(255, 200, 50));
                    } else {
                        statusLabel.setForeground(isSelected ? new Color(240, 240, 255) : ColorPalette.SL_TEXT_PRIMARY);
                    }

                    // Description with priority symbol
                    JLabel descLabel = new JLabel(prioritySymbol + description);
                    descLabel.setFont(fontManager.getBodyFont().deriveFont(task.isCompleted() ? Font.PLAIN : Font.BOLD));

                    // Set description color based on completion and priority
                    if (task.isCompleted()) {
                        descLabel.setForeground(isSelected ? new Color(200, 200, 255) : ColorPalette.SL_TEXT_SECONDARY);
                    } else if (prioritySymbol.equals("🔥 ")) {
                        descLabel.setForeground(isSelected ? new Color(255, 180, 180) : new Color(255, 100, 100));
                    } else if (prioritySymbol.equals("⚡ ")) {
                        descLabel.setForeground(isSelected ? new Color(255, 255, 180) : new Color(255, 200, 50));
                    } else {
                        descLabel.setForeground(isSelected ? new Color(240, 240, 255) : ColorPalette.SL_TEXT_PRIMARY);
                    }

                    contentPanel.add(statusLabel, BorderLayout.WEST);
                    contentPanel.add(descLabel, BorderLayout.CENTER);

                    // Create info panel for task details (difficulty, rewards, time)
                    JPanel infoPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT, 5, 0));
                    infoPanel.setOpaque(false);

                    // Difficulty icon
                    JLabel diffLabel = new JLabel(getDifficultyIcon(task.getDifficulty()));
                    diffLabel.setFont(new Font("Dialog", Font.PLAIN, 14));

                    // Rewards
                    JLabel rewardsLabel = new JLabel(task.getXpReward() + "⭐ | " + task.getCoinReward() + "💰");
                    rewardsLabel.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 12));
                    rewardsLabel.setForeground(isSelected ? new Color(240, 240, 255) : new Color(180, 180, 220));

                    // Time info
                    if (task.getTimeLimit() > 0) {
                        int hours = task.getTimeLimit() / 60;
                        int minutes = task.getTimeLimit() % 60;
                        String timeText = "⏱️";
                        if (hours > 0) {
                            timeText += hours + "h ";
                        }
                        if (minutes > 0 || hours == 0) {
                            timeText += minutes + "m";
                        }

                        JLabel timeLabel = new JLabel(timeText);
                        timeLabel.setFont(fontManager.getBodyFont().deriveFont(Font.PLAIN, 12));
                        timeLabel.setForeground(isSelected ? new Color(240, 240, 255) : new Color(180, 180, 220));
                        infoPanel.add(timeLabel);
                    }

                    infoPanel.add(diffLabel);
                    infoPanel.add(rewardsLabel);

                    // Add components to the main panel
                    panel.add(contentPanel, BorderLayout.CENTER);
                    panel.add(infoPanel, BorderLayout.EAST);
                }

                return panel;
            }

            private String getDifficultyIcon(Task.Difficulty difficulty) {
                switch (difficulty) {
                    case EASY: return "🟢";
                    case MEDIUM: return "🟡";
                    case HARD: return "🔴";
                    default: return "";
                }
            }
        });

        // Create a styled scroll pane
        JScrollPane scrollPane = new JScrollPane(taskList);
        scrollPane.setBackground(ColorPalette.SL_CARD);
        scrollPane.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 2),
                BorderFactory.createEmptyBorder(0, 0, 0, 0)
        ));
        scrollPane.getVerticalScrollBar().setUnitIncrement(16);

        // Create a button panel with improved layout
        JPanel buttonPanel = new JPanel(new GridLayout(1, 3, 10, 0));
        buttonPanel.setOpaque(false);
        buttonPanel.setBorder(BorderFactory.createEmptyBorder(10, 0, 0, 0));

        // Enhanced buttons with appropriate colors for their functions
        JButton addButton = createStyledButton("ADD NEW TASK");
        addButton.setBackground(new Color(60, 100, 160)); // Blue for creating
        addButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        addButton.addActionListener(e -> showAddTaskDialog());

        JButton completeButton = createStyledButton("COMPLETE TASK");
        completeButton.setBackground(new Color(60, 140, 60)); // Green for completing
        completeButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        completeButton.addActionListener(e -> completeTask());

        JButton deleteButton = createStyledButton("DELETE TASK");
        deleteButton.setBackground(new Color(140, 60, 60)); // Red for deleting
        deleteButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        deleteButton.addActionListener(e -> deleteTask());

        buttonPanel.add(addButton);
        buttonPanel.add(completeButton);
        buttonPanel.add(deleteButton);

        panel.add(titleLabel, BorderLayout.NORTH);
        panel.add(scrollPane, BorderLayout.CENTER);
        panel.add(buttonPanel, BorderLayout.SOUTH);

        return panel;
    }

    private JPanel createRecommendedPanel() {
        JPanel panel = new JPanel(new BorderLayout(0, 10));
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1),
                BorderFactory.createEmptyBorder(10, 10, 10, 10)
        ));
        panel.setPreferredSize(new Dimension(300, 0));

        // Title
        JLabel titleLabel = new JLabel("RECOMMENDED");
        titleLabel.setFont(fontManager.getSubheaderFont());
        titleLabel.setForeground(ColorPalette.SL_ACCENT);
        titleLabel.setBorder(BorderFactory.createEmptyBorder(0, 5, 10, 0));

        // Recommended list with Solo Leveling style
        recommendedList.setBackground(ColorPalette.SL_CARD);
        recommendedList.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        recommendedList.setFont(fontManager.getBodyFont());
        recommendedList.setSelectionBackground(ColorPalette.SL_PRIMARY_LIGHT);
        recommendedList.setSelectionForeground(ColorPalette.SL_TEXT_PRIMARY);
        recommendedList.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

        // Custom renderer for recommended tasks
        recommendedList.setCellRenderer(taskList.getCellRenderer());

        JScrollPane scrollPane = new JScrollPane(recommendedList);
        scrollPane.setBackground(ColorPalette.SL_CARD);
        scrollPane.setBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1));

        // Add recommended task button
        JButton addRecButton = createStyledButton("ADD TO TASKS");
        addRecButton.addActionListener(e -> addRecommendedTask());

        panel.add(titleLabel, BorderLayout.NORTH);
        panel.add(scrollPane, BorderLayout.CENTER);
        panel.add(addRecButton, BorderLayout.SOUTH);

        return panel;
    }

    private JPanel createActionPanel() {
        JPanel panel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        panel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        JButton backButton = createStyledButton("RETURN TO HUB");
        backButton.addActionListener(e -> {
            if (timerPanel != null) {
                timerPanel.stopTimer();
            }
            dispose();
            mainMenu.refreshStats();
        });

        panel.add(backButton);

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

    private void loadUserTasks() {
        taskListModel.clear();

        // Get prioritized tasks using the 0/1 Knapsack algorithm
        List<Task> prioritizedTasks = TaskSelector.prioritizeTasks(user.getTasks());

        // Add tasks to the list model in prioritized order
        for (Task task : prioritizedTasks) {
            taskListModel.addElement(task);
        }
    }

    private void loadRecommendedTasks() {
        recommendedListModel.clear();

        // Get recommended tasks based on user's current tasks and progress
        List<Task> recommendedTasks = TaskSelector.getRecommendedTasks(user);
        for (Task task : recommendedTasks) {
            recommendedListModel.addElement(task);
        }
    }

    private void showAddTaskDialog() {
        JPanel panel = new JPanel(new GridLayout(0, 1));
        panel.setBackground(ColorPalette.SL_CARD);

        JLabel descLabel = new JLabel("Task Description:");
        descLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JTextField descField = new JTextField(20);

        JLabel diffLabel = new JLabel("Difficulty:");
        diffLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        JComboBox<Task.Difficulty> diffBox = new JComboBox<>(Task.Difficulty.values());

        // Add a note about automatic rewards
        JLabel rewardsNoteLabel = new JLabel("<html>Rewards are set automatically based on difficulty:<br>" +
                "Easy: 50 XP, 20 Coins | Medium: 100 XP, 40 Coins | Hard: 200 XP, 80 Coins</html>");
        rewardsNoteLabel.setForeground(ColorPalette.SL_ACCENT);
        rewardsNoteLabel.setFont(rewardsNoteLabel.getFont().deriveFont(Font.ITALIC, rewardsNoteLabel.getFont().getSize() - 1f));

        // Split time input into hours and minutes
        JLabel timeLabel = new JLabel("Time Limit:");
        timeLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JPanel timePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
        timePanel.setBackground(ColorPalette.SL_CARD);

        JTextField hoursField = new JTextField(3);
        hoursField.setText("0");
        JLabel hoursLabel = new JLabel("hours");
        hoursLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JTextField minutesField = new JTextField(3);
        minutesField.setText("30");
        JLabel minutesLabel = new JLabel("minutes");
        minutesLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        timePanel.add(hoursField);
        timePanel.add(hoursLabel);
        timePanel.add(minutesField);
        timePanel.add(minutesLabel);

        panel.add(descLabel);
        panel.add(descField);
        panel.add(diffLabel);
        panel.add(diffBox);
        panel.add(rewardsNoteLabel);
        panel.add(timeLabel);
        panel.add(timePanel);

        UIManager.put("OptionPane.background", ColorPalette.SL_CARD);
        UIManager.put("Panel.background", ColorPalette.SL_CARD);

        int result = JOptionPane.showConfirmDialog(this, panel, "Add New Task",
                JOptionPane.OK_CANCEL_OPTION, JOptionPane.PLAIN_MESSAGE);

        if (result == JOptionPane.OK_OPTION) {
            try {
                String desc = descField.getText().trim();

                // Calculate total time in minutes from hours and minutes
                int hours = Integer.parseInt(hoursField.getText().trim());
                int minutes = Integer.parseInt(minutesField.getText().trim());
                int timeLimit = (hours * 60) + minutes;

                Task.Difficulty diff = (Task.Difficulty) diffBox.getSelectedItem();

                if (!desc.isEmpty() && timeLimit >= 0) {
                    // Create task with automatic XP and coin rewards based on difficulty
                    Task newTask = new Task(desc, diff, timeLimit);
                    user.getTasks().add(newTask);

                    // Update task list with prioritized tasks
                    loadUserTasks();

                    // Save the user's data
                    DataManager.saveUser(user);
                } else {
                    JOptionPane.showMessageDialog(this,
                            "Please provide a description and a valid time limit.",
                            "Invalid Input", JOptionPane.WARNING_MESSAGE);
                }
            } catch (NumberFormatException e) {
                JOptionPane.showMessageDialog(this,
                        "Hours and Minutes must be valid numbers.",
                        "Invalid Input", JOptionPane.WARNING_MESSAGE);
            }
        }
    }

    private void completeTask() {
        Task selectedTask = taskList.getSelectedValue();
        if (selectedTask == null) {
            JOptionPane.showMessageDialog(this,
                    "Please select a task to complete.",
                    "No Task Selected", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        if (selectedTask.isCompleted()) {
            JOptionPane.showMessageDialog(this,
                    "This task is already completed.",
                    "Task Already Completed", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        // Get the actual task from the user's task list (not the UI element)
        Task actualTask = null;
        String selectedDescription = selectedTask.getDescription();

        // Remove priority symbols if present
        if (selectedDescription.startsWith("🔥 ") ||
                selectedDescription.startsWith("⚡ ") ||
                selectedDescription.startsWith("📌 ")) {
            selectedDescription = selectedDescription.substring(2);
        }

        int taskIndex = -1;
        for (int i = 0; i < user.getTasks().size(); i++) {
            Task task = user.getTasks().get(i);
            String taskDesc = task.getDescription();

            // Remove priority symbols if present
            if (taskDesc.startsWith("🔥 ") ||
                    taskDesc.startsWith("⚡ ") ||
                    taskDesc.startsWith("📌 ")) {
                taskDesc = taskDesc.substring(2);
            }

            if (taskDesc.equals(selectedDescription) &&
                    task.getXpReward() == selectedTask.getXpReward() &&
                    task.getCoinReward() == selectedTask.getCoinReward()) {
                actualTask = task;
                taskIndex = i;
                break;
            }
        }

        // If no exact match found, just use the selected task
        if (actualTask == null) {
            actualTask = selectedTask;
            // Ensure the task is in the user's task list
            user.getTasks().remove(selectedTask);  // Remove it if it exists
            user.getTasks().add(actualTask);       // And add it back to ensure it's in the list
        } else {
            // If we found the task, remove it from its current position
            user.getTasks().remove(taskIndex);
            // And add it back at the end of the list
            user.getTasks().add(actualTask);
        }

        // Mark the actual task in the user's task list as completed
        actualTask.setCompleted(true);

        // Increment the user's completed tasks counter (for leaderboard)
        user.incrementCompletedTasksCounter();

        // Add XP and coins to the user
        user.addXP(actualTask.getXpReward());
        user.addCoins(actualTask.getCoinReward());

        // Save the user's updated data
        DataManager.saveUser(user);

        // Update the leaderboard with the new stats
        FirebaseLeaderboard.uploadUserStats(user);

        // Update UI with prioritized tasks
        loadUserTasks();

        // Show completion message
        JOptionPane.showMessageDialog(this,
                "Task completed! You earned:\n" +
                        "⭐ " + actualTask.getXpReward() + " XP\n" +
                        "💰 " + actualTask.getCoinReward() + " Coins",
                "Task Completed", JOptionPane.INFORMATION_MESSAGE);

        // Update main menu if it exists
        if (mainMenu != null) {
            mainMenu.refreshStats();
        }
    }

    private void deleteTask() {
        Task selectedTask = taskList.getSelectedValue();
        if (selectedTask == null) {
            JOptionPane.showMessageDialog(this,
                    "Please select a task to delete.",
                    "No Task Selected", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        int confirm = JOptionPane.showConfirmDialog(this,
                "Are you sure you want to delete this task?\n" + selectedTask.getDescription(),
                "Confirm Deletion", JOptionPane.YES_NO_OPTION);

        if (confirm == JOptionPane.YES_OPTION) {
            // Force delete the task directly from the task list model
            taskListModel.removeElement(selectedTask);

            // Create a new clean list without the problematic task
            List<Task> cleanTaskList = new ArrayList<>();
            String selectedDesc = selectedTask.getDescription();

            // Remove priority symbols if present
            if (selectedDesc.startsWith("🔥 ") ||
                    selectedDesc.startsWith("⚡ ") ||
                    selectedDesc.startsWith("📌 ")) {
                selectedDesc = selectedDesc.substring(2);
            }

            // Copy all tasks except the one to be deleted to the new list
            for (Task task : user.getTasks()) {
                String taskDesc = task.getDescription();

                // Remove priority symbols if present
                if (taskDesc.startsWith("🔥 ") ||
                        taskDesc.startsWith("⚡ ") ||
                        taskDesc.startsWith("📌 ")) {
                    taskDesc = taskDesc.substring(2);
                }

                // Skip the task we want to delete
                if (taskDesc.equals(selectedDesc) &&
                        task.getXpReward() == selectedTask.getXpReward() &&
                        task.getCoinReward() == selectedTask.getCoinReward()) {
                    continue;
                }

                cleanTaskList.add(task);
            }

            // Replace the user's task list with our clean one
            user.getTasks().clear();
            user.getTasks().addAll(cleanTaskList);

            // Save the user's updated data
            DataManager.saveUser(user);

            // Reload the task list to ensure it's properly updated
            loadUserTasks();

            JOptionPane.showMessageDialog(this,
                    "Task deleted successfully.",
                    "Task Deleted", JOptionPane.INFORMATION_MESSAGE);
        }
    }

    private void addRecommendedTask() {
        Task selectedTask = recommendedList.getSelectedValue();
        if (selectedTask == null) {
            JOptionPane.showMessageDialog(this,
                    "Please select a recommended task to add.",
                    "No Task Selected", JOptionPane.INFORMATION_MESSAGE);
            return;
        }

        // Check if task already exists
        for (Task task : user.getTasks()) {
            if (task.getDescription().equals(selectedTask.getDescription())) {
                JOptionPane.showMessageDialog(this,
                        "This task is already in your task list.",
                        "Task Already Exists", JOptionPane.INFORMATION_MESSAGE);
                return;
            }
        }

        // Add the task to the user's tasks
        user.getTasks().add(selectedTask);
        taskListModel.addElement(selectedTask);

        // Save the user's updated data
        DataManager.saveUser(user);

        JOptionPane.showMessageDialog(this,
                "Recommended task added to your task list.",
                "Task Added", JOptionPane.INFORMATION_MESSAGE);
    }
}
