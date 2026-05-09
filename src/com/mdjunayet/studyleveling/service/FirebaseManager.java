package com.mdjunayet.studyleveling.service;

import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.ValueEventListener;
import com.mdjunayet.studyleveling.model.User;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

public class FirebaseManager {

    private static boolean isFirebaseAvailable() {
        return FirebaseConfig.isInitialized() && FirebaseConfig.getFirebaseAuth() != null;
    }

    public static void uploadUserStats(User user) {
        try {
            if (!isFirebaseAvailable()) {
                System.out.println("ℹ Firebase unavailable; skipping leaderboard upload for " + user.getUsername() + ".");
                return;
            }

            // Use the totalCompletedTasks counter instead of counting current tasks
            int completedTasks = user.getTotalCompletedTasks();

            DatabaseReference dbRef = FirebaseDatabase.getInstance()
                    .getReference("leaderboard")
                    .child(user.getUsername());  // Use username as unique key

            dbRef.child("level").setValueAsync(user.getLevel());
            dbRef.child("xp").setValueAsync(user.getXp());
            dbRef.child("completedTasks").setValueAsync(completedTasks);

            System.out.println("✅ Successfully uploaded user stats to Firebase.");
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("❌ Failed to upload stats.");
        }
    }

    /**
     * Downloads user statistics from Firebase and updates the local user object
     * @param user The user to update with data from Firebase
     */
    public static void downloadUserStats(User user) {
        try {
            if (!isFirebaseAvailable()) {
                System.out.println("ℹ Firebase unavailable; skipping leaderboard download for " + user.getUsername() + ".");
                return;
            }

            DatabaseReference dbRef = FirebaseDatabase.getInstance()
                    .getReference("leaderboard")
                    .child(user.getUsername());

            dbRef.addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot dataSnapshot) {
                    if (dataSnapshot.exists()) {
                        // Get values from Firebase
                        Long level = dataSnapshot.child("level").getValue(Long.class);
                        Long xp = dataSnapshot.child("xp").getValue(Long.class);
                        Long completedTasks = dataSnapshot.child("completedTasks").getValue(Long.class);

                        // Update local user if data exists
                        if (level != null) {
                            user.setLevel(level.intValue());
                        }
                        if (xp != null) {
                            user.setXp(xp.intValue());
                        }
                        if (completedTasks != null) {
                            // Set the total completed tasks counter
                            user.setTotalCompletedTasks(completedTasks.intValue());
                        }

                        // Save the updated user locally
                        DataManager.saveUser(user);
                        System.out.println("✅ Successfully downloaded and updated user stats from Firebase.");
                    } else {
                        System.out.println("ℹ️ No data found in Firebase for user: " + user.getUsername());
                    }
                }

                @Override
                public void onCancelled(DatabaseError databaseError) {
                    System.out.println("❌ Failed to download stats: " + databaseError.getMessage());
                }
            });
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("❌ Failed to download stats.");
        }
    }

    private static DatabaseReference roomsRef() {
        return FirebaseDatabase.getInstance().getReference("multiplayer_rooms");
    }

    public static boolean createRoom(String roomId, int maxPlayers, User creator) {
        try {
            if (!isFirebaseAvailable()) {
                System.out.println("ℹ Firebase unavailable; skipping room creation for " + roomId + ".");
                return false;
            }

            CountDownLatch latch = new CountDownLatch(1);
            final boolean[] roomExists = {false};

            roomsRef().child(roomId).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    roomExists[0] = snapshot.exists();
                    latch.countDown();
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    latch.countDown();
                }
            });

            if (!latch.await(5, TimeUnit.SECONDS)) {
                System.err.println("Timeout checking if room exists");
                return false;
            }

            if (roomExists[0]) {
                System.out.println("Room " + roomId + " already exists, cannot create");
                return false;
            }

            Map<String, Object> roomData = new HashMap<>();
            roomData.put("maxPlayers", maxPlayers);
            roomData.put("createdAt", System.currentTimeMillis());
            roomData.put("creator", creator.getUsername());

            CountDownLatch roomCreationLatch = new CountDownLatch(1);
            final boolean[] roomCreationSuccessful = {false};

            roomsRef().child(roomId).setValue(roomData, (error, ref) -> {
                if (error != null) {
                    System.err.println("Error creating room: " + error.getMessage());
                    roomCreationSuccessful[0] = false;
                } else {
                    System.out.println("Successfully created room base data: " + roomId);
                    roomCreationSuccessful[0] = true;
                }
                roomCreationLatch.countDown();
            });

            if (!roomCreationLatch.await(5, TimeUnit.SECONDS)) {
                System.err.println("Timeout creating room");
                return false;
            }

            if (!roomCreationSuccessful[0]) {
                return false;
            }

            Map<String, Object> userData = new HashMap<>();
            userData.put("username", creator.getUsername());
            userData.put("level", creator.getLevel());
            userData.put("joinedAt", System.currentTimeMillis());

            CountDownLatch userAddLatch = new CountDownLatch(1);
            final boolean[] userAddSuccessful = {false};

            roomsRef().child(roomId).child("users").child(creator.getUsername()).setValue(userData, (error, ref) -> {
                if (error != null) {
                    System.err.println("Error adding user to room: " + error.getMessage());
                    userAddSuccessful[0] = false;
                } else {
                    System.out.println("Successfully added user to room: " + roomId);
                    userAddSuccessful[0] = true;
                }
                userAddLatch.countDown();
            });

            if (!userAddLatch.await(5, TimeUnit.SECONDS)) {
                System.err.println("Timeout adding user to room");
                return false;
            }

            return userAddSuccessful[0];
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public static int joinRoom(String roomId, User user, boolean forceJoin) {
        try {
            if (!isFirebaseAvailable()) {
                System.out.println("ℹ Firebase unavailable; skipping room join for " + roomId + ".");
                return -1;
            }

            CountDownLatch latch = new CountDownLatch(1);
            final int[] joinResult = {0};

            roomsRef().child(roomId).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    if (!snapshot.exists()) {
                        joinResult[0] = 1;
                        latch.countDown();
                        return;
                    }

                    if (snapshot.child("users").child(user.getUsername()).exists()) {
                        joinResult[0] = 0;
                        latch.countDown();
                        return;
                    }

                    Long maxPlayers = snapshot.child("maxPlayers").getValue(Long.class);
                    long currentPlayers = snapshot.child("users").getChildrenCount();

                    if (maxPlayers != null && currentPlayers >= maxPlayers) {
                        joinResult[0] = 2;
                        latch.countDown();
                        return;
                    }

                    if (!forceJoin && currentPlayers > 0) {
                        List<String> userNames = new ArrayList<>();
                        for (DataSnapshot userSnapshot : snapshot.child("users").getChildren()) {
                            String username = userSnapshot.child("username").getValue(String.class);
                            if (username != null) {
                                userNames.add(username);
                            }
                        }

                        if (!userNames.isEmpty()) {
                            System.out.println("Room " + roomId + " is in use by: " + String.join(", ", userNames));
                            joinResult[0] = 3;
                            latch.countDown();
                            return;
                        }
                    }

                    joinResult[0] = 0;
                    latch.countDown();
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    joinResult[0] = -1;
                    latch.countDown();
                }
            });

            latch.await();

            if (joinResult[0] != 0) {
                return joinResult[0];
            }

            Map<String, Object> userData = new HashMap<>();
            userData.put("username", user.getUsername());
            userData.put("level", user.getLevel());
            userData.put("joinedAt", System.currentTimeMillis());

            CountDownLatch joinLatch = new CountDownLatch(1);
            final boolean[] joinSuccessful = {false};

            roomsRef().child(roomId).child("users").child(user.getUsername()).setValue(userData, (error, ref) -> {
                if (error != null) {
                    System.err.println("Error joining room: " + error.getMessage());
                    joinSuccessful[0] = false;
                } else {
                    System.out.println("Successfully joined room: " + roomId);
                    joinSuccessful[0] = true;
                }
                joinLatch.countDown();
            });

            joinLatch.await(5, TimeUnit.SECONDS);
            return joinSuccessful[0] ? 0 : -1;
        } catch (Exception e) {
            e.printStackTrace();
            return -1;
        }
    }

    public static boolean joinRoom(String roomId, User user) {
        return joinRoom(roomId, user, false) == 0;
    }

    public static void leaveRoom(String roomId, String username) {
        if (!isFirebaseAvailable()) {
            return;
        }

        roomsRef().child(roomId).child("users").child(username).removeValue((error, ref) -> {
            if (error != null) {
                System.err.println("Error leaving room: " + error.getMessage());
            }
        });
    }

    public static List<String> getUsersInRoom(String roomId) {
        if (!isFirebaseAvailable()) {
            return new ArrayList<>();
        }

        List<String> users = new ArrayList<>();
        try {
            CountDownLatch latch = new CountDownLatch(1);

            roomsRef().child(roomId).child("users").addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    for (DataSnapshot userSnapshot : snapshot.getChildren()) {
                        String username = userSnapshot.child("username").getValue(String.class);
                        if (username != null) {
                            users.add(username);
                        }
                    }
                    latch.countDown();
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    latch.countDown();
                }
            });

            latch.await();
        } catch (Exception e) {
            e.printStackTrace();
        }

        return users;
    }

    public static boolean deleteUserRooms(String username) {
        try {
            if (!isFirebaseAvailable()) {
                System.out.println("ℹ Firebase unavailable; skipping room cleanup for " + username + ".");
                return true;
            }

            CountDownLatch latch = new CountDownLatch(1);
            final boolean[] deletionSuccessful = {true};

            roomsRef().addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    if (!snapshot.exists() || !snapshot.hasChildren()) {
                        System.out.println("No rooms found to delete for user: " + username);
                        latch.countDown();
                        return;
                    }

                    final CountDownLatch deletionLatch = new CountDownLatch(1);
                    final AtomicInteger pendingDeletions = new AtomicInteger(0);

                    List<String> roomsToDelete = new ArrayList<>();

                    for (DataSnapshot roomSnapshot : snapshot.getChildren()) {
                        if (roomSnapshot.child("users").child(username).exists()) {
                            roomsToDelete.add(roomSnapshot.getKey());
                        }
                    }

                    if (roomsToDelete.isEmpty()) {
                        deletionLatch.countDown();
                    } else {
                        pendingDeletions.set(roomsToDelete.size());

                        for (String roomId : roomsToDelete) {
                            roomsRef().child(roomId).removeValue((error, ref) -> {
                                if (error != null) {
                                    System.err.println("Error deleting room: " + error.getMessage());
                                    deletionSuccessful[0] = false;
                                } else {
                                    System.out.println("Successfully deleted room: " + roomId + " for user: " + username);
                                }

                                if (pendingDeletions.decrementAndGet() == 0) {
                                    deletionLatch.countDown();
                                }
                            });
                        }
                    }

                    try {
                        deletionLatch.await(5, TimeUnit.SECONDS);
                    } catch (InterruptedException e) {
                        System.err.println("Deletion wait interrupted: " + e.getMessage());
                        deletionSuccessful[0] = false;
                    }

                    latch.countDown();
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    System.err.println("Error cleaning up rooms: " + error.getMessage());
                    deletionSuccessful[0] = false;
                    latch.countDown();
                }
            });

            if (!latch.await(10, TimeUnit.SECONDS)) {
                System.err.println("Timeout waiting for room deletion to complete");
                return false;
            }

            Thread.sleep(500);

            return deletionSuccessful[0];
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public static boolean roomExists(String roomId) {
        try {
            if (!isFirebaseAvailable()) {
                return false;
            }

            CountDownLatch latch = new CountDownLatch(1);
            final boolean[] exists = {false};

            roomsRef().child(roomId).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    exists[0] = snapshot.exists();
                    latch.countDown();
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    System.err.println("Error checking if room exists: " + error.getMessage());
                    latch.countDown();
                }
            });

            if (!latch.await(3, TimeUnit.SECONDS)) {
                System.err.println("Timeout checking if room exists");
                return false;
            }

            return exists[0];
        } catch (Exception e) {
            System.err.println("Error checking if room exists: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
}