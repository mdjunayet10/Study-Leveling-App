package com.mdjunayet.studyleveling.task;

import java.time.LocalDate;

public class Task {
    private String description;
    private int xpReward;
    private int coinReward;
    private Difficulty difficulty;
    private boolean completed;
    private LocalDate completionDate;
    private int timeLimit; // Time limit in minutes

    public enum Difficulty {
        EASY(50, 20), MEDIUM(100, 40), HARD(200, 80);

        private final int xpValue;
        private final int coinValue;

        Difficulty(int xpValue, int coinValue) {
            this.xpValue = xpValue;
            this.coinValue = coinValue;
        }

        public int getXpValue() {
            return xpValue;
        }

        public int getCoinValue() {
            return coinValue;
        }
    }

    // No-arg constructor for Gson
    public Task() {
        this.description = "";
        this.xpReward = 0;
        this.coinReward = 0;
        this.difficulty = Difficulty.EASY;
        this.completed = false;
        this.completionDate = null;
        this.timeLimit = 0;
    }

    public Task(String description, Difficulty difficulty) {
        this.description = description;
        this.difficulty = (difficulty != null) ? difficulty : Difficulty.EASY;
        this.xpReward = this.difficulty.getXpValue();
        this.coinReward = this.difficulty.getCoinValue();
        this.completed = false;
        this.completionDate = null;
        this.timeLimit = 0;
    }

    public Task(String description, Difficulty difficulty, int timeLimit) {
        this.description = description;
        this.difficulty = (difficulty != null) ? difficulty : Difficulty.EASY;
        this.xpReward = this.difficulty.getXpValue();
        this.coinReward = this.difficulty.getCoinValue();
        this.completed = false;
        this.completionDate = null;
        this.timeLimit = timeLimit;
    }

    // Keeping the original constructors for backward compatibility
    public Task(String description, int xp, int coins, Difficulty difficulty) {
        this.description = description;
        this.difficulty = (difficulty != null) ? difficulty : Difficulty.EASY;
        this.xpReward = xp;
        this.coinReward = coins;
        this.completed = false;
        this.completionDate = null;
        this.timeLimit = 0;
    }

    public Task(String description, int xp, int coins, Difficulty difficulty, int timeLimit) {
        this.description = description;
        this.difficulty = (difficulty != null) ? difficulty : Difficulty.EASY;
        this.xpReward = xp;
        this.coinReward = coins;
        this.completed = false;
        this.completionDate = null;
        this.timeLimit = timeLimit;
    }

    public String getDescription() {
        return description;
    }

    public int getXpReward() {
        return xpReward;
    }

    public int getCoinReward() {
        return coinReward;
    }

    public Difficulty getDifficulty() {
        return (difficulty != null) ? difficulty : Difficulty.EASY;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;

        // Only set completion date if it's being marked as completed and doesn't already have a date
        if (completed && this.completionDate == null) {
            this.completionDate = LocalDate.now();
        }
    }

    public LocalDate getCompletionDate() {
        return completionDate;
    }

    public void setCompletionDate(LocalDate completionDate) {
        this.completionDate = completionDate;
    }

    public int getTimeLimit() {
        return timeLimit;
    }

    public void setTimeLimit(int timeLimit) {
        this.timeLimit = timeLimit;
    }

    public void setDifficulty(Difficulty difficulty) {
        this.difficulty = difficulty;
        // Automatically update XP and coin rewards based on new difficulty
        this.xpReward = difficulty.getXpValue();
        this.coinReward = difficulty.getCoinValue();
    }

    @Override
    public String toString() {
        String status = completed ? "✓" : "○";
        String prioritySymbol = "";
        return status + prioritySymbol + " " + description + " [" + difficulty + "] ⭐" + xpReward + " 💰" + coinReward + (timeLimit > 0 ? " ⏱️" + timeLimit + "min" : "");
    }
}