package com.mdjunayet.studyleveling.service;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.mdjunayet.studyleveling.model.User;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;

public class FirebaseLeaderboard {

    private static boolean isFirebaseAvailable() {
        return FirebaseConfig.isInitialized() && FirebaseConfig.getFirebaseAuth() != null;
    }

    public static final class LeaderboardEntry {
        private final String username;
        private final int level;
        private final int xp;
        private final int completedTasks;

        public LeaderboardEntry(String username, int level, int xp, int completedTasks) {
            this.username = username;
            this.level = level;
            this.xp = xp;
            this.completedTasks = completedTasks;
        }

        public String getUsername() {
            return username;
        }

        public int getLevel() {
            return level;
        }

        public int getXp() {
            return xp;
        }

        public int getCompletedTasks() {
            return completedTasks;
        }
    }

    public static void uploadUserStats(User user) {
        if (!isFirebaseAvailable()) {
            System.out.println("ℹ Firebase unavailable; skipping leaderboard upload for " + user.getUsername() + ".");
            return;
        }

        // Use the totalCompletedTasks counter instead of counting current tasks
        // This ensures deleted tasks that were completed are still counted
        int completed = user.getTotalCompletedTasks();

        DatabaseReference ref = FirebaseDatabase.getInstance()
                .getReference("leaderboard")
                .child(user.getUsername()); // Use username as key

        ref.child("level").setValueAsync(user.getLevel());
        ref.child("xp").setValueAsync(user.getXp());
        ref.child("completedTasks").setValueAsync(completed);
    }

    public static void loadLeaderboardEntries(Consumer<List<LeaderboardEntry>> onSuccess,
                                              Consumer<String> onError) {
        if (!isFirebaseAvailable()) {
            System.out.println("ℹ Firebase unavailable; loading leaderboard from local saves.");
            List<LeaderboardEntry> entries = buildEntriesFromUsers(DataManager.loadAllUsers());
            if (onSuccess != null) {
                onSuccess.accept(entries);
            }
            return;
        }

        try {
            DatabaseReference ref = FirebaseDatabase.getInstance().getReference("leaderboard");

            ref.addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    List<LeaderboardEntry> entries = new ArrayList<>();

                    for (DataSnapshot child : snapshot.getChildren()) {
                        String username = child.getKey();
                        Integer level = child.child("level").getValue(Integer.class);
                        Integer xp = child.child("xp").getValue(Integer.class);
                        Integer completedTasks = child.child("completedTasks").getValue(Integer.class);

                        if (username != null && level != null && xp != null && completedTasks != null) {
                            entries.add(new LeaderboardEntry(username, level, xp, completedTasks));
                        }
                    }

                    entries.sort((left, right) -> {
                        if (right.getLevel() != left.getLevel()) {
                            return Integer.compare(right.getLevel(), left.getLevel());
                        }

                        if (right.getXp() != left.getXp()) {
                            return Integer.compare(right.getXp(), left.getXp());
                        }

                        return Integer.compare(right.getCompletedTasks(), left.getCompletedTasks());
                    });

                    if (onSuccess != null) {
                        onSuccess.accept(entries);
                    }
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    if (onError != null) {
                        onError.accept(error.getMessage());
                    }
                }
            });
        } catch (Exception e) {
            System.out.println("ℹ Firebase leaderboard unavailable: " + e.getMessage());
            if (onSuccess != null) {
                onSuccess.accept(new ArrayList<>());
            }
            if (onError != null) {
                onError.accept(e.getMessage());
            }
        }
    }

    private static List<LeaderboardEntry> buildEntriesFromUsers(List<User> users) {
        List<LeaderboardEntry> entries = new ArrayList<>();

        for (User user : users) {
            entries.add(new LeaderboardEntry(
                    user.getUsername(),
                    user.getLevel(),
                    user.getXp(),
                    user.getTotalCompletedTasks()
            ));
        }

        entries.sort((left, right) -> {
            if (right.getLevel() != left.getLevel()) {
                return Integer.compare(right.getLevel(), left.getLevel());
            }

            if (right.getXp() != left.getXp()) {
                return Integer.compare(right.getXp(), left.getXp());
            }

            return Integer.compare(right.getCompletedTasks(), left.getCompletedTasks());
        });

        return entries;
    }
}