package com.mdjunayet.studyleveling.task;

import com.mdjunayet.studyleveling.model.User;
import java.util.*;

public class TaskSelector {

    public static int getEffort(Task.Difficulty difficulty) {
        if (difficulty == null) return 0; // Prevent crash
        switch (difficulty) {
            case EASY: return 2;
            case MEDIUM: return 5;
            case HARD: return 8;
            default: return 0;
        }
    }

    public static int getMaxEffortForLevel(int level) {
        return 10 + (level - 1) * 5;
    }

    // Original method for selecting optimal tasks based on effort
    public static List<Task> selectOptimalTasks(List<Task> tasks, int level) {
        int maxEffort = getMaxEffortForLevel(level);
        int n = tasks.size();

        int[] effort = new int[n];
        int[] value = new int[n];
        for (int i = 0; i < n; i++) {
            Task task = tasks.get(i);
            effort[i] = getEffort(task.getDifficulty());
            value[i] = task.getXpReward() + task.getCoinReward();
        }

        boolean[][] dp = new boolean[n + 1][maxEffort + 1];
        dp[0][0] = true;
        for (int i = 1; i <= n; i++) {
            for (int j = 0; j <= maxEffort; j++) {
                if (j >= effort[i - 1]) {
                    dp[i][j] = dp[i - 1][j] || dp[i - 1][j - effort[i - 1]];
                } else {
                    dp[i][j] = dp[i - 1][j];
                }
            }
        }

        int bestValue = -1;
        List<Task> bestSet = new ArrayList<>();

        for (int j = maxEffort; j >= 0; j--) {
            if (dp[n][j]) {
                List<Task> chosen = new ArrayList<>();
                int w = j;
                for (int i = n; i >= 1; i--) {
                    if (w >= effort[i - 1] && dp[i - 1][w - effort[i - 1]]) {
                        chosen.add(tasks.get(i - 1));
                        w -= effort[i - 1];
                    }
                }

                int totalValue = chosen.stream()
                        .mapToInt(t -> t.getXpReward() + t.getCoinReward())
                        .sum();
                long hardCount = chosen.stream()
                        .filter(t -> t.getDifficulty() == Task.Difficulty.HARD)
                        .count();

                if (totalValue > bestValue ||
                        (totalValue == bestValue &&
                                hardCount > bestSet.stream().filter(t -> t.getDifficulty() == Task.Difficulty.HARD).count())) {
                    bestValue = totalValue;
                    bestSet = chosen;
                }
            }
        }

        return bestSet;
    }

    /**
     * Prioritizes tasks based on XP, Coins, and Time Limit using 0/1 Knapsack algorithm.
     * Higher priority will be assigned to tasks with better value/time ratio.
     * Completed tasks will be shown at the bottom of the list.
     * @param tasks List of tasks to prioritize
     * @return List of tasks sorted by priority (highest priority first, completed tasks last)
     */
    public static List<Task> prioritizeTasks(List<Task> tasks) {
        // Split tasks into completed and incomplete
        List<Task> incompleteTasks = new ArrayList<>();
        List<Task> completedTasks = new ArrayList<>();

        for (Task task : tasks) {
            if (task.isCompleted()) {
                completedTasks.add(task);
            } else {
                incompleteTasks.add(task);
            }
        }

        // If no incomplete tasks, return only completed tasks
        if (incompleteTasks.isEmpty()) {
            return completedTasks;
        }

        // Apply Knapsack algorithm to calculate priorities for incomplete tasks
        List<TaskPriority> taskPriorities = applyKnapsackPrioritization(incompleteTasks);

        // Sort tasks by priority (highest first)
        Collections.sort(taskPriorities, (a, b) -> Double.compare(b.priority, a.priority));

        // Extract tasks in priority order and assign priority symbols
        List<Task> prioritizedTasks = new ArrayList<>();

        // Mark top 1/3 tasks with high priority
        int highPriorityCount = Math.max(1, taskPriorities.size() / 3);

        for (int i = 0; i < taskPriorities.size(); i++) {
            TaskPriority tp = taskPriorities.get(i);
            Task task = tp.task;

            // Update task toString to show priority symbol
            if (i < highPriorityCount) {
                task = addPrioritySymbol(task, "🔥 "); // High priority
            } else if (i < highPriorityCount * 2) {
                task = addPrioritySymbol(task, "⚡ "); // Medium priority
            } else {
                task = addPrioritySymbol(task, "📌 "); // Low priority
            }

            prioritizedTasks.add(task);
        }

        // Add completed tasks at the end without priority symbols
        for (Task task : completedTasks) {
            prioritizedTasks.add(task);
        }

        return prioritizedTasks;
    }

    /**
     * Creates a copy of the task with the priority symbol added to its description
     */
    private static Task addPrioritySymbol(Task task, String symbol) {
        String description = task.getDescription();

        // Remove any existing priority symbols
        if (description.startsWith("🔥 ") || description.startsWith("⚡ ") || description.startsWith("📌 ")) {
            description = description.substring(2);
        }

        // Create a new task with the priority symbol
        Task newTask = new Task(
                symbol + description,
                task.getXpReward(),
                task.getCoinReward(),
                task.getDifficulty(),
                task.getTimeLimit()
        );

        newTask.setCompleted(task.isCompleted());
        newTask.setCompletionDate(task.getCompletionDate());

        return newTask;
    }

    /**
     * Apply 0/1 Knapsack algorithm to calculate task priorities based on XP, coins, and time limits
     */
    private static List<TaskPriority> applyKnapsackPrioritization(List<Task> tasks) {
        List<TaskPriority> taskPriorities = new ArrayList<>();

        for (Task task : tasks) {
            // Calculate base value from XP and coins
            double value = task.getXpReward() + task.getCoinReward();

            // Calculate priority based on value to time ratio
            double priority;

            if (task.getTimeLimit() <= 0) {
                // If no time limit specified, use difficulty as a proxy for time
                int estimatedTime = getEffort(task.getDifficulty()) * 15; // 15 minutes per effort point
                priority = value / estimatedTime;
            } else {
                // Calculate value per minute
                priority = value / task.getTimeLimit();
            }

            // Apply urgency factor - shorter deadlines get higher priority
            // (this is just a placeholder - actual deadline functionality would need to be implemented)
            if (task.getTimeLimit() > 0 && task.getTimeLimit() < 60) { // Less than 1 hour
                priority *= 1.5;  // 50% priority boost for urgent tasks
            }

            taskPriorities.add(new TaskPriority(task, priority));
        }

        return taskPriorities;
    }

    /**
     * Recommend tasks based on user's level and current tasks
     * @param user The user to generate recommendations for
     * @return List of recommended tasks
     */
    public static List<Task> getRecommendedTasks(User user) {
        // Create sample recommended tasks based on user's level
        List<Task> recommendedTasks = new ArrayList<>();

        // Get user's level to tailor the recommendations
        int userLevel = user.getLevel();

        // Check if user already has tasks
        Set<String> existingTaskDescriptions = new HashSet<>();
        for (Task task : user.getTasks()) {
            String desc = task.getDescription();
            // Remove priority symbols if present
            if (desc.startsWith("🔥 ") || desc.startsWith("⚡ ") || desc.startsWith("📌 ")) {
                desc = desc.substring(2);
            }
            existingTaskDescriptions.add(desc.toLowerCase());
        }

        // Add level-appropriate task recommendations that the user doesn't already have
        addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                "Read a chapter", Task.Difficulty.EASY, 50, 20, 30);

        addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                "Create study notes", Task.Difficulty.MEDIUM, 80, 30, 45);

        addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                "Practice problems", Task.Difficulty.MEDIUM, 100, 40, 60);

        // Add more challenging tasks for higher levels
        if (userLevel >= 2) {
            addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                    "Create flashcards", Task.Difficulty.MEDIUM, 120, 50, 45);

            addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                    "Teach a concept to someone", Task.Difficulty.HARD, 150, 70, 60);
        }

        if (userLevel >= 3) {
            addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                    "Complete a practice exam", Task.Difficulty.HARD, 200, 100, 120);

            addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                    "Create a study group", Task.Difficulty.HARD, 250, 120, 60);
        }

        if (userLevel >= 5) {
            addTaskIfNotExists(recommendedTasks, existingTaskDescriptions,
                    "Write a research summary", Task.Difficulty.HARD, 300, 150, 180);
        }

        return recommendedTasks;
    }

    /**
     * Helper method to add a task to recommendations if it doesn't already exist in user's tasks
     */
    private static void addTaskIfNotExists(List<Task> recommendedTasks, Set<String> existingTaskDescriptions,
                                           String description, Task.Difficulty difficulty, int xp, int coins, int timeLimit) {
        if (!existingTaskDescriptions.contains(description.toLowerCase())) {
            recommendedTasks.add(new Task(description, xp, coins, difficulty, timeLimit));
        }
    }

    /**
     * Helper method to add a task to recommendations without time limit
     */
    // Helper class to store task with its priority
    private static class TaskPriority {
        Task task;
        double priority;

        TaskPriority(Task task, double priority) {
            this.task = task;
            this.priority = priority;
        }
    }
}