package com.mdjunayet.studyleveling.ui;

import com.mdjunayet.studyleveling.model.User;
import com.mdjunayet.studyleveling.service.DataManager;
import com.mdjunayet.studyleveling.service.FirebaseAuthService;
import com.mdjunayet.studyleveling.service.FirebaseRoomManager;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

import javax.swing.*;
import javax.swing.border.Border;
import java.awt.*;
import java.awt.event.FocusAdapter;
import java.awt.event.FocusEvent;

public class LoginScreen extends JFrame {

    private final JTextField usernameField = new JTextField(15);
    private final JPasswordField passwordField = new JPasswordField(15);
    private final JLabel messageLabel = new JLabel(" ");
    private final FontManager fontManager = FontManager.getInstance();
    private final FirebaseAuthService authService = new FirebaseAuthService();
    private JButton loginButton;
    private JButton signUpButton;

    public LoginScreen() {
        setTitle("Study Leveling");
        setSize(450, 360);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        setLayout(new BorderLayout());
        getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Main panel with slightly rounded corners
        JPanel mainPanel = new JPanel(new GridBagLayout());
        mainPanel.setBackground(ColorPalette.SL_BACKGROUND);
        mainPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 12, 8, 12);
        gbc.fill = GridBagConstraints.HORIZONTAL;

        // Title with Solo Leveling style
        JLabel titleLabel = new JLabel("STUDY LEVELING");
        titleLabel.setFont(fontManager.getTitleFont());
        titleLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Add a glowing border effect underneath
        Border emptyBorder = BorderFactory.createEmptyBorder(0, 0, 5, 0);
        Border lineBorder = BorderFactory.createMatteBorder(0, 0, 2, 0, ColorPalette.SL_ACCENT);
        titleLabel.setBorder(BorderFactory.createCompoundBorder(lineBorder, emptyBorder));

        gbc.gridwidth = 2;
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.insets = new Insets(5, 12, 20, 12);
        mainPanel.add(titleLabel, gbc);

        // Subtitle
        JLabel subtitleLabel = new JLabel("LOGIN GATE");
        subtitleLabel.setFont(fontManager.getSubheaderFont());
        subtitleLabel.setForeground(ColorPalette.SL_ACCENT);
        subtitleLabel.setHorizontalAlignment(SwingConstants.CENTER);
        gbc.gridy = 1;
        gbc.insets = new Insets(0, 12, 25, 12);
        mainPanel.add(subtitleLabel, gbc);

        // Username field with Solo Leveling styling
        JPanel usernamePanel = createFieldPanel("USERNAME", usernameField);
        gbc.gridy = 2;
        gbc.insets = new Insets(8, 12, 8, 12);
        mainPanel.add(usernamePanel, gbc);

        // Password field with Solo Leveling styling
        JPanel passwordPanel = createFieldPanel("PASSWORD", passwordField);
        gbc.gridy = 3;
        mainPanel.add(passwordPanel, gbc);

        // Message label with Solo Leveling styling
        messageLabel.setFont(fontManager.getBodyFont());
        messageLabel.setForeground(ColorPalette.SL_ERROR);
        messageLabel.setHorizontalAlignment(SwingConstants.CENTER);
        gbc.gridy = 4;
        mainPanel.add(messageLabel, gbc);

        // Buttons panel
        JPanel buttonPanel = new JPanel(new GridLayout(1, 2, 10, 0));
        buttonPanel.setOpaque(false);

        // Login button
        loginButton = createStyledButton("LOGIN");
        loginButton.addActionListener(e -> login());

        // Sign Up button
        signUpButton = createStyledButton("SIGN UP");
        signUpButton.addActionListener(e -> signUp());

        buttonPanel.add(loginButton);
        buttonPanel.add(signUpButton);

        gbc.gridy = 5;
        gbc.insets = new Insets(20, 12, 8, 12);
        mainPanel.add(buttonPanel, gbc);

        add(mainPanel, BorderLayout.CENTER);

        // Bottom panel with version info
        JPanel versionPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        versionPanel.setOpaque(false);
        JLabel versionLabel = new JLabel("v1.0");
        versionLabel.setFont(fontManager.getSmallFont());
        versionLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        versionPanel.add(versionLabel);

        add(versionPanel, BorderLayout.SOUTH);

        setVisible(true);
    }

    private JPanel createFieldPanel(String labelText, JTextField field) {
        JPanel panel = new JPanel(new BorderLayout(5, 0));
        panel.setOpaque(false);

        JLabel label = new JLabel(labelText);
        label.setFont(fontManager.getBodyFont());
        label.setForeground(ColorPalette.SL_TEXT_SECONDARY);

        field.setFont(fontManager.getBodyFont());
        field.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        field.setBackground(ColorPalette.SL_CARD);
        field.setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY, 1),
                BorderFactory.createEmptyBorder(8, 10, 8, 10)
        ));
        field.setCaretColor(ColorPalette.SL_ACCENT);

        // Add focus effect
        field.addFocusListener(new FocusAdapter() {
            @Override
            public void focusGained(FocusEvent e) {
                field.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                        BorderFactory.createEmptyBorder(8, 10, 8, 10)
                ));
            }

            @Override
            public void focusLost(FocusEvent e) {
                field.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY, 1),
                        BorderFactory.createEmptyBorder(8, 10, 8, 10)
                ));
            }
        });

        panel.add(label, BorderLayout.NORTH);
        panel.add(field, BorderLayout.CENTER);

        return panel;
    }

    private JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFont(fontManager.getSubheaderFont());
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBackground(ColorPalette.SL_PRIMARY);
        button.setBorder(BorderFactory.createEmptyBorder(10, 15, 10, 15));
        button.setFocusPainted(false);

        // Add hover effect with glowing border
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1),
                        BorderFactory.createEmptyBorder(9, 14, 9, 14)
                ));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY);
                button.setBorder(BorderFactory.createEmptyBorder(10, 15, 10, 15));
            }
        });

        return button;
    }

    private void login() {
        String username = usernameField.getText().trim();
        String password = new String(passwordField.getPassword());

        if (username.isEmpty() || password.isEmpty()) {
            setMessage("❗ Enter both username and password!", Color.RED);
            return;
        }

        // Disable buttons while authenticating
        loginButton.setEnabled(false);
        signUpButton.setEnabled(false);
        setMessage("⏳ Logging in...", Color.ORANGE);

        // Verify credentials using Firebase Authentication
        authService.verifyCredentials(username, password)
            .thenAccept(isValid -> {
                SwingUtilities.invokeLater(() -> {
                    if (isValid) {
                        // User authenticated successfully
                        User user = DataManager.loadUser(username);
                        if (user == null) {
                            // Create new user data if authenticated but no local data exists
                            user = new User(username);
                            DataManager.saveUser(user);
                        }

                        // Clean up any existing rooms for this user
                        FirebaseRoomManager.deleteUserRooms(username);

                        setMessage("✅ Welcome back, " + username + "!", new Color(0, 128, 0));
                        openMainMenu(user);
                    } else {
                        setMessage("❗ Invalid username or password!", Color.RED);
                        loginButton.setEnabled(true);
                        signUpButton.setEnabled(true);
                    }
                });
            })
            .exceptionally(ex -> {
                SwingUtilities.invokeLater(() -> {
                    setMessage("⚠ Login error. Trying offline mode...", Color.RED);
                    // Fallback to offline login
                    if (DataManager.userExists(username) && DataManager.verifyPassword(username, password)) {
                        User user = DataManager.loadUser(username);
                        openMainMenu(user);
                    } else {
                        setMessage("❗ Login failed. Check connection or credentials.", Color.RED);
                    }
                    loginButton.setEnabled(true);
                    signUpButton.setEnabled(true);
                });
                return null;
            });
    }

    private void signUp() {
        String username = usernameField.getText().trim();
        String password = new String(passwordField.getPassword());

        if (username.isEmpty() || password.isEmpty()) {
            setMessage("❗ Username and password required!", Color.RED);
            return;
        }

        if (username.contains(" ") || username.contains("@")) {
            setMessage("❗ Username cannot contain spaces or @ symbols.", Color.RED);
            return;
        }

        // Disable buttons while creating account
        loginButton.setEnabled(false);
        signUpButton.setEnabled(false);
        setMessage("⏳ Creating account...", Color.ORANGE);

        // Create user in Firebase Authentication
        authService.createUser(username, password)
            .thenAccept(isCreated -> {
                SwingUtilities.invokeLater(() -> {
                    if (isCreated) {
                        // Account created successfully
                        User newUser = DataManager.loadUser(username);
                        if (newUser == null) {
                            newUser = new User(username);
                            DataManager.saveUser(newUser);
                        }

                        setMessage("🎉 Account created successfully!", new Color(0, 128, 0));
                        openMainMenu(newUser);
                    } else {
                        setMessage("❗ Username already exists or invalid.", Color.RED);
                        loginButton.setEnabled(true);
                        signUpButton.setEnabled(true);
                    }
                });
            })
            .exceptionally(ex -> {
                SwingUtilities.invokeLater(() -> {
                    setMessage("⚠ Error creating account. Creating local account only.", Color.RED);
                    // Fallback to local account creation
                    if (!DataManager.userExists(username)) {
                        User newUser = new User(username);
                        DataManager.saveUser(newUser);
                        DataManager.savePassword(username, password);
                        setMessage("✅ Local account created.", new Color(0, 128, 0));
                        openMainMenu(newUser);
                    } else {
                        setMessage("❗ Username already exists locally.", Color.RED);
                    }
                    loginButton.setEnabled(true);
                    signUpButton.setEnabled(true);
                });
                return null;
            });
    }

    private void setMessage(String msg, Color color) {
        messageLabel.setText(msg);
        messageLabel.setForeground(color);
    }

    private void openMainMenu(User user) {
        dispose();
        SwingUtilities.invokeLater(() -> new MainMenu(user));

    }
}