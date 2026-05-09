package com.mdjunayet.studyleveling.multiplayer;

import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.ui.MainMenu;
import com.mdjunayet.studyleveling.util.ThemeManager;

import javax.swing.*;
import java.awt.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class MultiplayerLoginScreen extends JFrame {
    private final int maxPlayers;
    private int currentPlayer = 1;
    private final List<User> loggedInUsers = new ArrayList<>();
    private final boolean isAwayMode;
    private final String roomId;
    private final ThemeManager themeManager = ThemeManager.getInstance();

    // Competitive timer properties
    private final boolean competitiveTimerMode;
    private final int timerMinutes;

    private final JTextField usernameField = new JTextField(15);
    private final JPasswordField passwordField = new JPasswordField(15);
    private final JLabel messageLabel = new JLabel(" ");
    private JLabel roomInfoLabel;
    private JLabel timerInfoLabel;

    // Constructor for Home mode and creating Away mode
    public MultiplayerLoginScreen(int maxPlayers, boolean isAwayMode) {
        this(maxPlayers, isAwayMode, false, 30);
    }

    // Constructor for joining an existing room in Away mode
    public MultiplayerLoginScreen(String roomId) {
        this.roomId = roomId;
        this.isAwayMode = true;
        this.maxPlayers = 1; // Only need the current user to log in
        this.competitiveTimerMode = false;
        this.timerMinutes = 30;

        setupUI();
        promptNextPlayer();
    }

    // New constructor with competitive timer parameters
    public MultiplayerLoginScreen(int maxPlayers, boolean isAwayMode, boolean competitiveTimerMode, int timerMinutes) {
        this.maxPlayers = maxPlayers;
        this.isAwayMode = isAwayMode;
        this.competitiveTimerMode = competitiveTimerMode;
        this.timerMinutes = timerMinutes;

        // Generate a random room ID for Away mode
        if (isAwayMode) {
            this.roomId = generateRoomId();
        } else {
            this.roomId = null;
        }

        setupUI();
        promptNextPlayer();
    }

    private void setupUI() {
        setTitle("🤝 Multiplayer Login - Study Leveling");
        setSize(500, 380);  // Further increased width and height
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLocationRelativeTo(null);
        getContentPane().setBackground(themeManager.getColor("background"));
        setLayout(new GridBagLayout());

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(10, 15, 10, 15);
        gbc.anchor = GridBagConstraints.WEST;

        // Set title based on mode
        String titleText = isAwayMode ?
                (roomId != null && maxPlayers > 1 ? "🌐 Create Online Room" : "🌐 Join Online Room") :
                "🎮 Local Multiplayer";
        JLabel titleLabel = new JLabel(titleText);
        titleLabel.setFont(new Font("Arial", Font.BOLD, 24));
        titleLabel.setForeground(themeManager.getColor("text"));
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Create a panel just for the title to ensure it's centered
        JPanel titlePanel = new JPanel(new BorderLayout());
        titlePanel.setOpaque(false);
        titlePanel.add(titleLabel, BorderLayout.CENTER);

        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.gridwidth = 2;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.anchor = GridBagConstraints.CENTER;
        add(titlePanel, gbc);

        // Add room info for Away mode
        if (isAwayMode && roomId != null) {
            roomInfoLabel = new JLabel("<html>Room ID: <b>" + roomId + "</b>" +
                    (maxPlayers > 1 ? " (Max Players: " + maxPlayers + ")" : "") +
                    "<br>Share this ID with friends to join!</html>");
            roomInfoLabel.setForeground(new Color(0, 100, 0));
            roomInfoLabel.setFont(new Font("Monospaced", Font.PLAIN, 14));
            roomInfoLabel.setHorizontalAlignment(SwingConstants.CENTER);

            gbc.gridy = 1;
            gbc.insets = new Insets(5, 15, 15, 15);
            add(roomInfoLabel, gbc);
            gbc.gridy = 2;
            gbc.insets = new Insets(10, 15, 10, 15);
        }

        gbc.anchor = GridBagConstraints.EAST;
        gbc.gridwidth = 1;

        // Username
        gbc.gridy = 1;
        gbc.gridx = 0;
        add(new JLabel("👤 Username:"), gbc);

        gbc.gridx = 1;
        gbc.anchor = GridBagConstraints.WEST;
        add(usernameField, gbc);

        // Password
        gbc.gridy = 2;
        gbc.gridx = 0;
        gbc.anchor = GridBagConstraints.EAST;
        add(new JLabel("🔑 Password:"), gbc);

        gbc.gridx = 1;
        gbc.anchor = GridBagConstraints.WEST;
        add(passwordField, gbc);

        // Buttons
        JButton signInButton = createStyledButton("🔓 Sign In");
        JButton guestButton = createStyledButton("🎭 Continue as Guest");

        signInButton.addActionListener(e -> signIn());
        guestButton.addActionListener(e -> promptGuestUsername());

        JPanel buttonPanel = new JPanel();
        buttonPanel.setOpaque(false);
        buttonPanel.add(signInButton);
        buttonPanel.add(guestButton);

        gbc.gridy = 3;
        gbc.gridx = 0;
        gbc.gridwidth = 2;
        gbc.anchor = GridBagConstraints.CENTER;
        add(buttonPanel, gbc);

        // Message label
        messageLabel.setFont(new Font("Monospaced", Font.PLAIN, 13));
        messageLabel.setForeground(Color.RED);
        gbc.gridy = 4;
        gbc.insets = new Insets(10, 10, 0, 10);
        add(messageLabel, gbc);

        // Timer info label for competitive mode
        if (competitiveTimerMode) {
            timerInfoLabel = new JLabel("⏱️ Timer: " + timerMinutes + " minutes");
            timerInfoLabel.setFont(new Font("Monospaced", Font.PLAIN, 14));
            timerInfoLabel.setForeground(themeManager.getColor("text"));
            timerInfoLabel.setHorizontalAlignment(SwingConstants.CENTER);

            gbc.gridy = 5;
            gbc.insets = new Insets(5, 15, 10, 15);
            add(timerInfoLabel, gbc);
        }

        setVisible(true);
    }

    private void promptNextPlayer() {
        usernameField.setText("");
        passwordField.setText("");
        messageLabel.setText("🎯 Player " + currentPlayer + ": Sign in or join as guest");
    }

    private void signIn() {
        String username = usernameField.getText().trim();
        String password = new String(passwordField.getPassword());

        if (username.isEmpty() || password.isEmpty()) {
            messageLabel.setText("⚠ Please enter both username and password.");
            return;
        }

        if (!DataManager.userExists(username)) {
            messageLabel.setText("❌ User not found. Sign up first.");
            return;
        }

        if (!DataManager.verifyPassword(username, password)) {
            messageLabel.setText("❌ Incorrect password.");
            return;
        }

        User user = DataManager.loadUser(username);
        if (user == null) {
            messageLabel.setText("⚠ Failed to load user data.");
            return;
        }

        loggedInUsers.add(user);
        nextOrLaunch();
    }

    private void promptGuestUsername() {
        String guestName = JOptionPane.showInputDialog(
                this,
                "Enter a name for Guest Player " + currentPlayer + ":",
                "Guest Login",
                JOptionPane.PLAIN_MESSAGE
        );

        if (guestName != null && !guestName.trim().isEmpty()) {
            continueAsGuest(guestName.trim());
        } else {
            messageLabel.setText("⚠ Guest name cannot be empty.");
        }
    }

    private void continueAsGuest(String name) {
        User guest = new User(name);
        loggedInUsers.add(guest);
        nextOrLaunch();
    }

    private void nextOrLaunch() {
        if (currentPlayer < maxPlayers) {
            currentPlayer++;
            promptNextPlayer();
        } else {
            dispose();
            // Pass the parent MainMenu instance to MultiplayerStudyScreen if the first user is from MainMenu
            MainMenu mainMenu = null;
            for (User user : loggedInUsers) {
                if (user.getUsername().equals(MainMenu.getCurrentUser().getUsername())) {
                    mainMenu = MainMenu.getCurrentInstance();
                    break;
                }
            }

            // Launch the study screen with the appropriate mode
            new MultiplayerStudyScreen(
                loggedInUsers,
                mainMenu,
                isAwayMode,
                roomId,
                maxPlayers,
                competitiveTimerMode,
                timerMinutes
            );
        }
    }

    private JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFocusPainted(false);
        button.setBackground(new Color(147, 112, 219));
        button.setForeground(Color.WHITE);
        button.setFont(new Font("Monospaced", Font.BOLD, 13));
        button.setBorder(BorderFactory.createLineBorder(Color.BLACK, 2));
        return button;
    }

    private String generateRoomId() {
        // Generate a random alphanumeric string as the room ID
        String characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
        StringBuilder roomId = new StringBuilder();
        Random random = new Random();
        for (int i = 0; i < 8; i++) {
            int index = random.nextInt(characters.length());
            roomId.append(characters.charAt(index));
        }
        return roomId.toString();
    }
}