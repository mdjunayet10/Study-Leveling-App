package com.mdjunayet.studyleveling;

import com.mdjunayet.studyleveling.service.FirebaseConfig;
import com.mdjunayet.studyleveling.ui.LoginScreen;
import com.mdjunayet.studyleveling.util.ThemeManager;

import javax.swing.*;

public class AppMain {
    public static void main(String[] args) {
        ThemeManager.getInstance();

        Thread firebaseInitThread = new Thread(() -> {
            try {
                FirebaseConfig.initialize();
                if (FirebaseConfig.isInitialized()) {
                    System.out.println("Firebase initialized successfully");
                } else {
                    System.out.println("Firebase running in offline mode.");
                }
            } catch (Exception e) {
                System.err.println("Firebase initialization error (app will work offline): " + e.getMessage());
            }
        });
        firebaseInitThread.setDaemon(true);
        firebaseInitThread.start();

        SwingUtilities.invokeLater(LoginScreen::new);
    }
}