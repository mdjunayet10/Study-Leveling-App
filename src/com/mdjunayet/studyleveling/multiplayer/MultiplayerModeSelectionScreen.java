package com.mdjunayet.studyleveling.multiplayer;

import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.FirebaseRoomManager;
import com.mdjunayet.studyleveling.ui.MainMenu;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

import javax.swing.*;
import java.awt.*;
import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.util.ArrayList;
import java.util.List;

/**
 * Screen that allows users to choose between Home and Away multiplayer modes
 * Styled with Solo Leveling aesthetic
 */
public class MultiplayerModeSelectionScreen extends JFrame {
    private final FontManager fontManager = FontManager.getInstance();

    public MultiplayerModeSelectionScreen() {
        setTitle("Multiplayer Selection");
        setSize(550, 400);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());
        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Header panel
        JPanel headerPanel = createHeaderPanel();
        add(headerPanel, BorderLayout.NORTH);

        // Main content panel
        JPanel contentPanel = createContentPanel();
        add(contentPanel, BorderLayout.CENTER);

        // Footer panel with version info
        JPanel footerPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        footerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        JLabel versionLabel = new JLabel("v1.0");
        versionLabel.setFont(fontManager.getSmallFont());
        versionLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        footerPanel.add(versionLabel);
        add(footerPanel, BorderLayout.SOUTH);

        setVisible(true);
    }

    private JPanel createHeaderPanel() {
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setBackground(ColorPalette.SL_PRIMARY_DARK);
        headerPanel.setBorder(BorderFactory.createEmptyBorder(15, 20, 15, 20));

        JLabel titleLabel = new JLabel("MULTIPLAYER MODE");
        titleLabel.setFont(fontManager.getHeaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);

        headerPanel.add(titleLabel, BorderLayout.CENTER);

        return headerPanel;
    }

    private JPanel createContentPanel() {
        JPanel panel = new JPanel(new GridBagLayout());
        panel.setBackground(ColorPalette.SL_BACKGROUND);
        panel.setBorder(BorderFactory.createEmptyBorder(30, 40, 30, 40));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.insets = new Insets(10, 0, 10, 0);
        gbc.weightx = 1.0;

        // Subtitle
        JLabel subtitleLabel = new JLabel("SELECT MODE");
        subtitleLabel.setFont(fontManager.getSubheaderFont());
        subtitleLabel.setForeground(ColorPalette.SL_ACCENT);
        subtitleLabel.setHorizontalAlignment(SwingConstants.CENTER);
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 1;
        panel.add(subtitleLabel, gbc);

        // Home mode button (local)
        JPanel homePanel = createModePanel(
                "HOME MODE",
                "Study with friends on the same device",
                "LOCAL_ICON"
        );
        homePanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openHomeMode();
            }
        });
        gbc.gridy = 1;
        gbc.ipady = 40;
        panel.add(homePanel, gbc);

        // Away mode button (online)
        JPanel awayPanel = createModePanel(
                "AWAY MODE",
                "Create or join online study rooms",
                "ONLINE_ICON"
        );
        awayPanel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseClicked(java.awt.event.MouseEvent evt) {
                openAwayMode();
            }
        });
        gbc.gridy = 2;
        panel.add(awayPanel, gbc);

        // Description
        JLabel descLabel = new JLabel("<html><div style='text-align: center;'>" +
                "Select a multiplayer mode to start<br>your cooperative study session</div></html>");
        descLabel.setFont(fontManager.getBodyFont());
        descLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        descLabel.setHorizontalAlignment(SwingConstants.CENTER);
        gbc.gridy = 3;
        gbc.ipady = 0;
        gbc.insets = new Insets(25, 0, 0, 0);
        panel.add(descLabel, gbc);

        return panel;
    }

    private JPanel createModePanel(String title, String description, String iconType) {
        JPanel panel = new JPanel(new BorderLayout(15, 0));
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1),
                BorderFactory.createEmptyBorder(15, 20, 15, 20)
        ));

        // Icon label (using emoji for now)
        JLabel iconLabel = new JLabel(iconType.equals("LOCAL_ICON") ? "🏠" : "🌐");
        iconLabel.setFont(new Font("Dialog", Font.PLAIN, 36));
        iconLabel.setForeground(ColorPalette.SL_ACCENT);

        // Text panel
        JPanel textPanel = new JPanel(new BorderLayout(0, 5));
        textPanel.setOpaque(false);

        JLabel titleLabel = new JLabel(title);
        titleLabel.setFont(fontManager.getSubheaderFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        JLabel descLabel = new JLabel(description);
        descLabel.setFont(fontManager.getBodyFont());
        descLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);

        textPanel.add(titleLabel, BorderLayout.NORTH);
        textPanel.add(descLabel, BorderLayout.CENTER);

        panel.add(iconLabel, BorderLayout.WEST);
        panel.add(textPanel, BorderLayout.CENTER);

        // Add hover effect
        panel.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                panel.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                panel.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                        BorderFactory.createEmptyBorder(15, 20, 15, 20)
                ));
                titleLabel.setForeground(ColorPalette.SL_ACCENT_BRIGHT);
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                panel.setBackground(ColorPalette.SL_CARD);
                panel.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1),
                        BorderFactory.createEmptyBorder(15, 20, 15, 20)
                ));
                titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
            }
        });

        // Make it look clickable
        panel.setCursor(new Cursor(Cursor.HAND_CURSOR));

        return panel;
    }

    private void openHomeMode() {
        dispose();

        // Select number of players
        String[] playerOptions = {"2", "3", "4"};
        String playerInput = (String) JOptionPane.showInputDialog(
                null,
                "Select number of players:",
                "Home Multiplayer",
                JOptionPane.PLAIN_MESSAGE,
                null,
                playerOptions,
                "2"
        );

        if (playerInput == null) {
            return; // User canceled
        }

        // Ask if they want to use competitive timer mode
        int timerModeChoice = JOptionPane.showConfirmDialog(
                null,
                "Would you like to use competitive timer mode?\n\n" +
                        "In this mode, all players work under a shared time limit.\n" +
                        "The first player to complete gets full XP, while later players\n" +
                        "get reduced XP based on their completion time.",
                "Competitive Timer",
                JOptionPane.YES_NO_OPTION,
                JOptionPane.QUESTION_MESSAGE
        );

        boolean useCompetitiveTimer = (timerModeChoice == JOptionPane.YES_OPTION);
        int timerMinutes = 30; // Default time

        // If competitive timer mode is selected, ask for time limit
        if (useCompetitiveTimer) {
            String[] timeOptions = {"15", "30", "45", "60", "90", "120"};
            String timeInput = (String) JOptionPane.showInputDialog(
                    null,
                    "Select time limit (minutes):",
                    "Competitive Timer Setup",
                    JOptionPane.PLAIN_MESSAGE,
                    null,
                    timeOptions,
                    "30"
            );

            if (timeInput != null) {
                timerMinutes = Integer.parseInt(timeInput);
            } else {
                useCompetitiveTimer = false; // User canceled timer selection
            }
        }

        int numPlayers = Integer.parseInt(playerInput);
        new MultiplayerLoginScreen(numPlayers, false, useCompetitiveTimer, timerMinutes);
    }

    private void createRoomWithRetry(User user, int maxPlayers) {
        // Try to create a room with retry logic if the room ID already exists
        int maxRetries = 3;
        boolean roomCreated = false;

        for (int attempt = 0; attempt < maxRetries && !roomCreated; attempt++) {
            // Generate a new room ID for each attempt
            final String roomId = generateRoomId(); // Make roomId final for this iteration

            // Try to create the room with the current ID
            List<User> users = new ArrayList<>();
            users.add(user);

            // Check if room exists before trying to create it
            if (FirebaseRoomManager.roomExists(roomId)) {
                System.out.println("Room " + roomId + " already exists, trying another ID (attempt " + (attempt + 1) + ")");
                continue;
            }

            // Create the room
            MultiplayerStudyScreen studyScreen = new MultiplayerStudyScreen(
                    users,
                    MainMenu.getCurrentInstance(),
                    true,
                    roomId,
                    maxPlayers,
                    true,  // Enable competitive timer mode
                    30     // Set timer for 30 minutes
            );

            // Check if the room was created successfully (the screen is visible)
            if (studyScreen.isVisible()) {
                roomCreated = true;

                // Show the room ID in a dialog that allows easy copying
                JPanel panel = new JPanel(new BorderLayout(10, 10));
                panel.setPreferredSize(new Dimension(300, 100));

                JLabel messageLabel = new JLabel("<html><div style='text-align: center;'>" +
                        "Room created successfully!<br>Share this ID with your friends:</div></html>");
                messageLabel.setHorizontalAlignment(SwingConstants.CENTER);

                JTextField roomIdField = new JTextField(roomId);
                roomIdField.setFont(new Font("Monospaced", Font.BOLD, 16));
                roomIdField.setHorizontalAlignment(JTextField.CENTER);
                roomIdField.setEditable(false);

                JButton copyButton = new JButton("Copy to Clipboard");
                copyButton.addActionListener(e -> {
                    StringSelection selection = new StringSelection(roomId);
                    Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
                    clipboard.setContents(selection, null);
                    JOptionPane.showMessageDialog(null, "Room ID copied to clipboard!");
                });

                panel.add(messageLabel, BorderLayout.NORTH);
                panel.add(roomIdField, BorderLayout.CENTER);
                panel.add(copyButton, BorderLayout.SOUTH);

                JOptionPane.showMessageDialog(null, panel, "Room Created", JOptionPane.INFORMATION_MESSAGE);
            }
        }

        if (!roomCreated) {
            JOptionPane.showMessageDialog(null,
                    "Failed to create a room after multiple attempts.\nPlease try again later.",
                    "Room Creation Failed",
                    JOptionPane.ERROR_MESSAGE);
        }
    }

    private void openAwayMode() {
        dispose();
        String[] options = {"Create Room", "Join Room"};
        String choice = (String) JOptionPane.showInputDialog(
                null,
                "Select an option:",
                "Away Multiplayer",
                JOptionPane.PLAIN_MESSAGE,
                null,
                options,
                "Create Room"
        );

        if (choice == null) {
            return;
        }

        if (choice.equals("Create Room")) {
            String[] playerOptions = {"2", "3", "4"};
            String playerCount = (String) JOptionPane.showInputDialog(
                    null,
                    "Select maximum number of players:",
                    "Create Room",
                    JOptionPane.PLAIN_MESSAGE,
                    null,
                    playerOptions,
                    "2"
            );

            if (playerCount != null) {
                int numPlayers = Integer.parseInt(playerCount);
                // Use the currently logged-in user directly
                User currentUser = MainMenu.getCurrentUser();
                // Use the new retry mechanism
                createRoomWithRetry(currentUser, numPlayers);
            }
        } else {
            // Join Room
            String roomId = JOptionPane.showInputDialog(
                    null,
                    "Enter Room ID:",
                    "Join Room",
                    JOptionPane.PLAIN_MESSAGE
            );

            if (roomId != null && !roomId.trim().isEmpty()) {
                // Use the currently logged-in user directly
                User currentUser = MainMenu.getCurrentUser();
                List<User> users = new ArrayList<>();
                users.add(currentUser);
                // Launch the study screen directly with the current user
                new MultiplayerStudyScreen(
                    users,
                    MainMenu.getCurrentInstance(),
                    true,
                    roomId,
                    1,
                    true,  // Enable competitive timer mode
                    30     // Set timer for 30 minutes
                );
            }
        }
    }

    private String generateRoomId() {
        // Generate a unique room ID with better randomness to avoid collisions
        String username = MainMenu.getCurrentUser().getUsername();
        String timestamp = String.valueOf(System.currentTimeMillis());
        String characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder roomId = new StringBuilder();

        // Add a prefix based on the username (first 2 chars or whole username if shorter)
        String prefix = username.length() > 2 ? username.substring(0, 2) : username;
        roomId.append(prefix);

        // Add more randomness with a shortened timestamp (last 6 digits only)
        if (timestamp.length() > 6) {
            roomId.append(timestamp.substring(timestamp.length() - 6));
        } else {
            roomId.append(timestamp);
        }

        // Add more random characters (increased from 4 to 8)
        java.security.SecureRandom secureRandom = new java.security.SecureRandom();
        for (int i = 0; i < 8; i++) {
            int index = secureRandom.nextInt(characters.length());
            roomId.append(characters.charAt(index));
        }

        System.out.println("Generated unique room ID: " + roomId);
        return roomId.toString();
    }
}