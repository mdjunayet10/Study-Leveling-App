package com.mdjunayet.studyleveling.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;

public class FirebaseConfig {
    private static final String CREDENTIALS_FILE_NAME = "serviceAccountKey.json";
    private static FirebaseAuth firebaseAuth;
    private static final AtomicBoolean isInitialized = new AtomicBoolean(false);
    private static final CompletableFuture<Boolean> initializationFuture = new CompletableFuture<>();
    private static final int CONNECTION_TIMEOUT_MS = 5000; // 5 seconds timeout

    public static void initialize() {
        if (isInitialized.get()) {
            return; // Already initialized
        }

        try {
            try (InputStream serviceAccount = openServiceAccountStream()) {
                if (serviceAccount == null) {
                    System.out.println("⚠ Firebase credentials not found. Running offline mode. Place serviceAccountKey.json in the project root, src/, src/com/mdjunayet/studyleveling/, or the runtime classpath to enable Firebase.");
                    initializationFuture.complete(false);
                    return;
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .setDatabaseUrl("https://study-leveling-default-rtdb.asia-southeast1.firebasedatabase.app/")  // replace with your DB URL
                        .setConnectTimeout(CONNECTION_TIMEOUT_MS) // Add timeout to prevent hanging
                        .build();

                FirebaseApp.initializeApp(options);
                firebaseAuth = FirebaseAuth.getInstance();
                isInitialized.set(true);
                initializationFuture.complete(true);
                System.out.println("✅ Firebase initialized successfully.");
            }
        } catch (Exception e) {
            System.err.println("❌ Failed to initialize Firebase.");
            e.printStackTrace();
            initializationFuture.complete(false);
        }
    }

    private static InputStream openServiceAccountStream() throws IOException {
        InputStream classpathStream = FirebaseConfig.class.getClassLoader().getResourceAsStream(CREDENTIALS_FILE_NAME);
        if (classpathStream != null) {
            return classpathStream;
        }

        for (Path candidate : credentialCandidates()) {
            if (Files.isRegularFile(candidate)) {
                return Files.newInputStream(candidate);
            }
        }

        return null;
    }

    private static List<Path> credentialCandidates() {
        Path workingDirectory = Paths.get(System.getProperty("user.dir"));
        List<Path> candidates = new ArrayList<>();
        candidates.add(workingDirectory.resolve(CREDENTIALS_FILE_NAME));
        candidates.add(workingDirectory.resolve("resources").resolve(CREDENTIALS_FILE_NAME));
        candidates.add(workingDirectory.resolve("src").resolve(CREDENTIALS_FILE_NAME));
        candidates.add(workingDirectory.resolve("src").resolve("com").resolve("mdjunayet").resolve("studyleveling").resolve(CREDENTIALS_FILE_NAME));
        candidates.add(workingDirectory.resolve("src").resolve("com").resolve("mdjunayet").resolve("studyleveling").resolve("service").resolve(CREDENTIALS_FILE_NAME));
        candidates.add(workingDirectory.resolve("src").resolve("main").resolve("resources").resolve(CREDENTIALS_FILE_NAME));
        return candidates;
    }

    public static FirebaseAuth getFirebaseAuth() {
        return firebaseAuth;
    }

    public static boolean isInitialized() {
        return isInitialized.get();
    }

    public static CompletableFuture<Boolean> getInitializationFuture() {
        return initializationFuture;
    }
}