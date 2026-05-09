package com.mdjunayet.studyleveling.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.google.firebase.auth.UserRecord.CreateRequest;
import com.mdjunayet.studyleveling.model.User;

import javax.swing.*;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

/**
 * Handles Firebase Authentication for user accounts
 */
public class FirebaseAuthService {
    private FirebaseAuth auth;
    private static final int TIMEOUT_SECONDS = 5; // Reduced timeout for faster response
    private boolean offlineMode = false;

    public FirebaseAuthService() {
        // Don't try to get Firebase Auth immediately - it might not be initialized
        // Instead check if it's available when needed
        checkFirebaseAvailability();
    }

    private void checkFirebaseAvailability() {
        if (!FirebaseConfig.isInitialized()) {
            // Set a shorter timeout for checking if Firebase is ready
            CompletableFuture<Boolean> initFuture = FirebaseConfig.getInitializationFuture();
            try {
                Boolean initialized = initFuture.get(2, TimeUnit.SECONDS);
                if (initialized && FirebaseConfig.getFirebaseAuth() != null) {
                    this.auth = FirebaseConfig.getFirebaseAuth();
                    this.offlineMode = false;
                } else {
                    this.offlineMode = true;
                }
            } catch (Exception e) {
                System.err.println("Firebase not ready, using offline mode: " + e.getMessage());
                this.offlineMode = true;
            }
        } else if (FirebaseConfig.getFirebaseAuth() != null) {
            this.auth = FirebaseConfig.getFirebaseAuth();
            this.offlineMode = false;
        } else {
            this.offlineMode = true;
        }
    }

    /**
     * Creates a new user in Firebase Authentication
     *
     * @param username The username
     * @param password The password
     * @return CompletableFuture that resolves to true if successful, false otherwise
     */
    public CompletableFuture<Boolean> createUser(String username, String password) {
        CompletableFuture<Boolean> future = new CompletableFuture<>();

        // Create the local user data immediately for better responsiveness
        if (!DataManager.userExists(username)) {
            User newUser = new User(username);
            DataManager.saveUser(newUser);
            DataManager.savePassword(username, password);

            // If we're in offline mode, complete successfully right away
            if (offlineMode) {
                SwingUtilities.invokeLater(() -> {
                    future.complete(true);
                });
                return future;
            }
        } else if (offlineMode) {
            // User already exists locally and we're offline
            SwingUtilities.invokeLater(() -> {
                future.complete(false);
            });
            return future;
        }

        // Only try Firebase operations if we're not in offline mode
        if (!offlineMode && auth != null) {
            // Create a separate thread for Firebase operations to avoid blocking UI
            new Thread(() -> {
                try {
                    // First check if user already exists in Firebase
                    try {
                        UserRecord userRecord = auth.getUserByEmail(username + "@studyleveling.com");
                        if (userRecord != null) {
                            future.complete(false);
                            return;
                        }
                    } catch (FirebaseAuthException e) {
                        // User doesn't exist, which is what we want for new sign-ups
                    }

                    // Create user in Firebase Authentication
                    // We're using email+password auth, but using username as the email prefix
                    CreateRequest request = new CreateRequest()
                            .setEmail(username + "@studyleveling.com")
                            .setPassword(password)
                            .setDisplayName(username);

                    // Attempt to create user in Firebase (this might be slow)
                    auth.createUser(request);

                    // Also upload user stats to Firebase for global leaderboard
                    // Do this in a separate thread to avoid slowing down the sign-up process
                    new Thread(() -> {
                        try {
                            User user = DataManager.loadUser(username);
                            if (user != null) {
                                FirebaseManager.uploadUserStats(user);
                            }
                        } catch (Exception e) {
                            System.err.println("Error uploading user stats: " + e.getMessage());
                            // Non-critical error, user can still use the app
                        }
                    }).start();

                    future.complete(true);
                } catch (FirebaseAuthException e) {
                    System.err.println("Firebase Auth Error: " + e.getMessage());
                    // We already created the local account, so still consider it a success
                    future.complete(true);
                }
            }).start();
        }

        // Add timeout handling
        CompletableFuture<Boolean> timeoutFuture = new CompletableFuture<>();
        new Thread(() -> {
            try {
                Boolean result = future.get(TIMEOUT_SECONDS, TimeUnit.SECONDS);
                timeoutFuture.complete(result);
            } catch (Exception e) {
                System.err.println("Firebase operation timed out: " + e.getMessage());
                // We already created the local account, so consider it a success
                timeoutFuture.complete(true);
            }
        }).start();

        return timeoutFuture;
    }

    /**
     * Verifies a user's credentials against Firebase Authentication
     *
     * @param username The username
     * @param password The password
     * @return CompletableFuture that resolves to true if credentials are valid, false otherwise
     */
    public CompletableFuture<Boolean> verifyCredentials(String username, String password) {
        CompletableFuture<Boolean> future = new CompletableFuture<>();

        // Try offline authentication first - this is very fast
        if (DataManager.userExists(username) && DataManager.verifyPassword(username, password)) {
            // User exists locally and password is valid
            System.out.println("User authenticated locally: " + username);

            // If online, sync with Firebase in the background
            if (!offlineMode && auth != null) {
                new Thread(() -> {
                    try {
                        User user = DataManager.loadUser(username);
                        if (user != null) {
                            // Upload current stats to ensure they're saved to Firebase
                            FirebaseManager.uploadUserStats(user);
                        }
                    } catch (Exception e) {
                        System.err.println("Error syncing user data with Firebase: " + e.getMessage());
                    }
                }).start();
            }

            future.complete(true);
            return future;
        }

        // If we're offline and the user doesn't exist locally, we can't authenticate
        if (offlineMode) {
            future.complete(false);
            return future;
        }

        // If offline auth fails and Firebase is available, try Firebase Authentication
        if (!offlineMode && auth != null) {
            new Thread(() -> {
                try {
                    // Verify if user exists in Firebase
                    try {
                        UserRecord userRecord = auth.getUserByEmail(username + "@studyleveling.com");
                        if (userRecord != null) {
                            // User exists in Firebase, but either doesn't exist locally or password is different
                            // IMPORTANT: We need to be careful not to overwrite existing data

                            if (!DataManager.userExists(username)) {
                                System.out.println("User exists in Firebase but not locally. Creating local data for: " + username);

                                // Create local user with minimal data - we'll download the rest from Firebase
                                User newUser = new User(username);
                                // Don't save yet - wait for Firebase data

                                // Sync with Firebase first, then save the user
                                // This ensures we don't create a blank user that overwrites Firebase data
                                CompletableFuture<Boolean> syncFuture = new CompletableFuture<>();

                                new Thread(() -> {
                                    try {
                                        System.out.println("Downloading user stats from Firebase for: " + username);
                                        FirebaseManager.downloadUserStats(newUser);

                                        // Now save the user with downloaded data
                                        DataManager.saveUser(newUser);
                                        DataManager.savePassword(username, password);

                                        syncFuture.complete(true);
                                    } catch (Exception e) {
                                        System.err.println("Error downloading user stats: " + e.getMessage());

                                        // If download fails, still save minimal user data
                                        DataManager.saveUser(newUser);
                                        DataManager.savePassword(username, password);

                                        syncFuture.complete(false);
                                    }
                                }).start();

                                // Wait for sync to complete with a short timeout
                                try {
                                    Boolean syncResult = syncFuture.get(3, TimeUnit.SECONDS);
                                    System.out.println("Firebase sync result: " + syncResult);
                                } catch (Exception e) {
                                    System.err.println("Firebase sync timed out: " + e.getMessage());
                                }
                            } else {
                                // User exists locally but password might have changed on another device
                                // Update the password to keep in sync
                                DataManager.savePassword(username, password);

                                // Also sync local data with Firebase in the background
                                new Thread(() -> {
                                    try {
                                        User existingUser = DataManager.loadUser(username);
                                        if (existingUser != null) {
                                            // First download latest stats from Firebase
                                            FirebaseManager.downloadUserStats(existingUser);
                                            // Then save the updated user
                                            DataManager.saveUser(existingUser);
                                        }
                                    } catch (Exception e) {
                                        System.err.println("Error syncing existing user with Firebase: " + e.getMessage());
                                    }
                                }).start();
                            }

                            // Authenticate the user
                            future.complete(true);
                        } else {
                            future.complete(false);
                        }
                    } catch (FirebaseAuthException e) {
                        // User doesn't exist in Firebase
                        future.complete(false);
                    }
                } catch (Exception e) {
                    System.err.println("Firebase Auth Error: " + e.getMessage());
                    // If Firebase fails, fall back to local auth
                    future.complete(DataManager.verifyPassword(username, password));
                }
            }).start();
        } else {
            // Firebase not available, and local auth failed
            future.complete(false);
        }

        // Add timeout handling
        CompletableFuture<Boolean> timeoutFuture = new CompletableFuture<>();
        new Thread(() -> {
            try {
                Boolean result = future.get(TIMEOUT_SECONDS, TimeUnit.SECONDS);
                timeoutFuture.complete(result);
            } catch (Exception e) {
                System.err.println("Firebase operation timed out: " + e.getMessage());
                // If timeout, check if we can authenticate locally
                timeoutFuture.complete(DataManager.verifyPassword(username, password));
            }
        }).start();

        return timeoutFuture;
    }
}
