package com.mdjunayet.studyleveling.session;

import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;
import com.mdjunayet.studyleveling.util.ThemeManager;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.text.DecimalFormat;

/**
 * A Pomodoro timer panel that can be added to study screens
 * Redesigned with Solo Leveling aesthetic
 */
public class StudyTimerPanel extends JPanel {
    private static final int DEFAULT_STUDY_MINUTES = 25;
    private static final int DEFAULT_BREAK_MINUTES = 5;
    private static final int DEFAULT_LONG_BREAK_MINUTES = 15;

    private final Timer timer;
    private final JLabel timeLabel;
    private final JButton startPauseButton;
    private final JButton resetButton;
    private final JButton skipButton;
    private final JButton settingsButton; // New settings button
    private final JLabel statusLabel;
    private final JLabel cycleCountLabel;
    private final FontManager fontManager = FontManager.getInstance();
    // Add ThemeManager instance
    private final ThemeManager themeManager = ThemeManager.getInstance();

    private int secondsLeft;
    private boolean isRunning = false;
    private boolean isStudySession = true;
    private int studyMinutes;
    private int breakMinutes;
    private int longBreakMinutes;
    private int pomodoroCount = 0;

    public StudyTimerPanel() {
        this(DEFAULT_STUDY_MINUTES, DEFAULT_BREAK_MINUTES, DEFAULT_LONG_BREAK_MINUTES);
    }

    public StudyTimerPanel(int studyMinutes, int breakMinutes, int longBreakMinutes) {
        this.studyMinutes = studyMinutes;
        this.breakMinutes = breakMinutes;
        this.longBreakMinutes = longBreakMinutes;

        // Initialize timer with Solo Leveling style
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1),
                BorderFactory.createEmptyBorder(15, 15, 15, 15)
        ));
        setBackground(ColorPalette.SL_CARD);

        // Header panel
        JPanel headerPanel = new JPanel(new BorderLayout());
        headerPanel.setOpaque(false);

        JLabel titleLabel = new JLabel("POMODORO TIMER");
        titleLabel.setFont(fontManager.getSubheaderFont());
        titleLabel.setForeground(ColorPalette.SL_ACCENT);

        // Create settings button with gear icon
        settingsButton = new JButton("⚙");
        settingsButton.setFont(new Font("Dialog", Font.PLAIN, 18));
        settingsButton.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        settingsButton.setBackground(ColorPalette.SL_CARD);
        settingsButton.setBorder(BorderFactory.createEmptyBorder(5, 10, 5, 10));
        settingsButton.setFocusPainted(false);
        settingsButton.setToolTipText("Customize Timer Settings");
        settingsButton.setCursor(new Cursor(Cursor.HAND_CURSOR));

        // Add hover effect to settings button
        settingsButton.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                settingsButton.setForeground(ColorPalette.SL_ACCENT);
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                settingsButton.setForeground(ColorPalette.SL_TEXT_SECONDARY);
            }
        });

        // Add action listener to open settings dialog
        settingsButton.addActionListener(e -> openTimerSettings());

        // Add title and settings button
        JPanel titlePanel = new JPanel(new FlowLayout(FlowLayout.LEFT, 5, 0));
        titlePanel.setOpaque(false);
        titlePanel.add(titleLabel);
        titlePanel.add(settingsButton);

        headerPanel.add(titlePanel, BorderLayout.WEST);

        cycleCountLabel = new JLabel("CYCLE: 0");
        cycleCountLabel.setFont(fontManager.getBodyFont());
        cycleCountLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        headerPanel.add(cycleCountLabel, BorderLayout.EAST);

        // Time display panel
        JPanel timePanel = new JPanel(new BorderLayout(0, 5));
        timePanel.setOpaque(false);

        timeLabel = new JLabel(formatTime(studyMinutes * 60), SwingConstants.CENTER);
        timeLabel.setFont(new Font("Monospaced", Font.BOLD, 36));
        timeLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        statusLabel = new JLabel("READY", SwingConstants.CENTER);
        statusLabel.setFont(fontManager.getBodyFont());
        statusLabel.setForeground(ColorPalette.SL_ACCENT);

        timePanel.add(timeLabel, BorderLayout.CENTER);
        timePanel.add(statusLabel, BorderLayout.SOUTH);

        // Button panel
        JPanel buttonPanel = new JPanel(new GridLayout(1, 3, 10, 0));
        buttonPanel.setOpaque(false);

        startPauseButton = createStyledButton("START");
        resetButton = createStyledButton("RESET");
        skipButton = createStyledButton("SKIP");

        startPauseButton.setBackground(ColorPalette.SL_SUCCESS);
        resetButton.setBackground(ColorPalette.SL_PRIMARY);
        skipButton.setBackground(ColorPalette.SL_WARNING);

        buttonPanel.add(startPauseButton);
        buttonPanel.add(resetButton);
        buttonPanel.add(skipButton);

        // Add all components to the panel
        add(headerPanel, BorderLayout.NORTH);
        add(timePanel, BorderLayout.CENTER);
        add(buttonPanel, BorderLayout.SOUTH);

        // Initialize the timer
        secondsLeft = studyMinutes * 60;
        timer = new Timer(1000, new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                timerTick();
            }
        });

        // Add action listeners
        startPauseButton.addActionListener(e -> toggleTimer());
        resetButton.addActionListener(e -> resetTimer());
        skipButton.addActionListener(e -> skipSession());

        // Set initial state
        updateDisplay();
    }

    /**
     * Opens a dialog to customize timer settings
     */
    private void openTimerSettings() {
        // Pause the timer if it's running
        boolean wasRunning = isRunning;
        if (isRunning) {
            timer.stop();
            isRunning = false;
        }

        // Create settings dialog
        JDialog settingsDialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(this), "Pomodoro Settings", true);
        settingsDialog.setLayout(new BorderLayout());
        settingsDialog.getContentPane().setBackground(ColorPalette.SL_BACKGROUND);

        // Settings panel
        JPanel settingsPanel = new JPanel(new GridBagLayout());
        settingsPanel.setBackground(ColorPalette.SL_BACKGROUND);
        settingsPanel.setBorder(BorderFactory.createEmptyBorder(20, 20, 20, 20));

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.gridx = 0;
        gbc.gridy = 0;
        gbc.anchor = GridBagConstraints.WEST;
        gbc.insets = new Insets(5, 5, 5, 5);

        // Study time setting
        JLabel studyLabel = new JLabel("Study Time (minutes):");
        studyLabel.setFont(fontManager.getBodyFont());
        studyLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        settingsPanel.add(studyLabel, gbc);

        gbc.gridx = 1;
        SpinnerNumberModel studyModel = new SpinnerNumberModel(studyMinutes, 1, 120, 1);
        JSpinner studySpinner = new JSpinner(studyModel);
        studySpinner.setFont(fontManager.getBodyFont());
        studySpinner.setPreferredSize(new Dimension(80, 30));
        settingsPanel.add(studySpinner, gbc);

        // Break time setting
        gbc.gridx = 0;
        gbc.gridy = 1;
        JLabel breakLabel = new JLabel("Break Time (minutes):");
        breakLabel.setFont(fontManager.getBodyFont());
        breakLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        settingsPanel.add(breakLabel, gbc);

        gbc.gridx = 1;
        SpinnerNumberModel breakModel = new SpinnerNumberModel(breakMinutes, 1, 60, 1);
        JSpinner breakSpinner = new JSpinner(breakModel);
        breakSpinner.setFont(fontManager.getBodyFont());
        breakSpinner.setPreferredSize(new Dimension(80, 30));
        settingsPanel.add(breakSpinner, gbc);

        // Long break time setting
        gbc.gridx = 0;
        gbc.gridy = 2;
        JLabel longBreakLabel = new JLabel("Long Break Time (minutes):");
        longBreakLabel.setFont(fontManager.getBodyFont());
        longBreakLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        settingsPanel.add(longBreakLabel, gbc);

        gbc.gridx = 1;
        SpinnerNumberModel longBreakModel = new SpinnerNumberModel(longBreakMinutes, 1, 120, 1);
        JSpinner longBreakSpinner = new JSpinner(longBreakModel);
        longBreakSpinner.setFont(fontManager.getBodyFont());
        longBreakSpinner.setPreferredSize(new Dimension(80, 30));
        settingsPanel.add(longBreakSpinner, gbc);

        // Button panel
        JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.RIGHT));
        buttonPanel.setOpaque(false);

        JButton cancelButton = createStyledButton("CANCEL");
        cancelButton.setBackground(ColorPalette.SL_PRIMARY);

        JButton saveButton = createStyledButton("SAVE");
        saveButton.setBackground(ColorPalette.SL_SUCCESS);

        buttonPanel.add(cancelButton);
        buttonPanel.add(saveButton);

        // Add panels to dialog
        settingsDialog.add(settingsPanel, BorderLayout.CENTER);
        settingsDialog.add(buttonPanel, BorderLayout.SOUTH);

        // Add action listeners
        cancelButton.addActionListener(e -> {
            settingsDialog.dispose();
            if (wasRunning) {
                timer.start();
                isRunning = true;
            }
        });

        saveButton.addActionListener(e -> {
            // Update timer settings
            int newStudyMinutes = (Integer) studySpinner.getValue();
            int newBreakMinutes = (Integer) breakSpinner.getValue();
            int newLongBreakMinutes = (Integer) longBreakSpinner.getValue();

            // Apply new settings
            updateTimerSettings(newStudyMinutes, newBreakMinutes, newLongBreakMinutes);

            // Close dialog
            settingsDialog.dispose();

            // Resume timer if it was running
            if (wasRunning) {
                timer.start();
                isRunning = true;
            }
        });

        // Show dialog
        settingsDialog.pack();
        settingsDialog.setLocationRelativeTo(this);
        settingsDialog.setResizable(false);
        settingsDialog.setVisible(true);
    }

    /**
     * Updates the timer settings and resets the current timer if needed
     */
    private void updateTimerSettings(int newStudyMinutes, int newBreakMinutes, int newLongBreakMinutes) {
        // Only update if values have changed
        if (studyMinutes != newStudyMinutes ||
                breakMinutes != newBreakMinutes ||
                longBreakMinutes != newLongBreakMinutes) {

            // Store new settings
            studyMinutes = newStudyMinutes;
            breakMinutes = newBreakMinutes;
            longBreakMinutes = newLongBreakMinutes;

            // Reset current timer session
            resetTimer();

            // Show confirmation
            String message = "Timer settings updated:\n";
            message += "- Study: " + studyMinutes + " minutes\n";
            message += "- Break: " + breakMinutes + " minutes\n";
            message += "- Long Break: " + longBreakMinutes + " minutes";

            JOptionPane.showMessageDialog(
                    this,
                    message,
                    "Settings Updated",
                    JOptionPane.INFORMATION_MESSAGE
            );
        }
    }

    private JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFont(fontManager.getBodyFont());
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBorder(BorderFactory.createEmptyBorder(8, 10, 8, 10));
        button.setFocusPainted(false);

        // Add hover effect
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBorder(BorderFactory.createCompoundBorder(
                        BorderFactory.createLineBorder(ColorPalette.SL_ACCENT_BRIGHT, 1),
                        BorderFactory.createEmptyBorder(7, 9, 7, 9)
                ));
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBorder(BorderFactory.createEmptyBorder(8, 10, 8, 10));
            }
        });

        return button;
    }

    private void timerTick() {
        secondsLeft--;
        timeLabel.setText(formatTime(secondsLeft));

        if (secondsLeft <= 0) {
            timer.stop();
            isRunning = false;
            playSound();

            if (isStudySession) {
                pomodoroCount++;
                cycleCountLabel.setText("CYCLE: " + pomodoroCount);

                // After 4 pomodoros, take a long break
                if (pomodoroCount % 4 == 0) {
                    isStudySession = false;
                    secondsLeft = longBreakMinutes * 60;
                    statusLabel.setText("LONG BREAK - RELAX!");
                    statusLabel.setForeground(ColorPalette.SL_BREAK);
                    timeLabel.setForeground(ColorPalette.SL_BREAK);
                    JOptionPane.showMessageDialog(
                            StudyTimerPanel.this,
                            "Study session complete! Take a " + longBreakMinutes + " minute long break.",
                            "Long Break Time",
                            JOptionPane.INFORMATION_MESSAGE
                    );
                } else {
                    isStudySession = false;
                    secondsLeft = breakMinutes * 60;
                    statusLabel.setText("BREAK TIME - RELAX!");
                    statusLabel.setForeground(ColorPalette.SL_BREAK);
                    timeLabel.setForeground(ColorPalette.SL_BREAK);
                    JOptionPane.showMessageDialog(
                            StudyTimerPanel.this,
                            "Study session complete! Take a " + breakMinutes + " minute break.",
                            "Break Time",
                            JOptionPane.INFORMATION_MESSAGE
                    );
                }
            } else {
                isStudySession = true;
                secondsLeft = studyMinutes * 60;
                statusLabel.setText("STUDY SESSION");
                statusLabel.setForeground(ColorPalette.SL_STUDY);
                timeLabel.setForeground(ColorPalette.SL_STUDY);
                JOptionPane.showMessageDialog(
                        StudyTimerPanel.this,
                        "Break time is over! Ready for another " + studyMinutes + " minute study session?",
                        "Back to Study",
                        JOptionPane.INFORMATION_MESSAGE
                );
            }

            timeLabel.setText(formatTime(secondsLeft));
            startPauseButton.setText("▶ START");
        }
    }

    private void toggleTimer() {
        if (isRunning) {
            timer.stop();
            isRunning = false;
            startPauseButton.setText("▶ START");
        } else {
            timer.start();
            isRunning = true;
            startPauseButton.setText("⏸ PAUSE");
        }
    }

    private void resetTimer() {
        timer.stop();
        isRunning = false;
        if (isStudySession) {
            secondsLeft = studyMinutes * 60;
        } else {
            secondsLeft = breakMinutes * 60;
        }
        timeLabel.setText(formatTime(secondsLeft));
        startPauseButton.setText("▶ START");
    }

    private void skipSession() {
        timer.stop();
        isRunning = false;

        if (isStudySession) {
            // Skip to break
            pomodoroCount++;
            cycleCountLabel.setText("CYCLE: " + pomodoroCount);

            if (pomodoroCount % 4 == 0) {
                secondsLeft = longBreakMinutes * 60;
                statusLabel.setText("LONG BREAK - RELAX!");
            } else {
                secondsLeft = breakMinutes * 60;
                statusLabel.setText("BREAK TIME - RELAX!");
            }
            statusLabel.setForeground(ColorPalette.SL_BREAK);
            timeLabel.setForeground(ColorPalette.SL_BREAK);
            isStudySession = false;
        } else {
            // Skip to study
            secondsLeft = studyMinutes * 60;
            statusLabel.setText("STUDY SESSION");
            statusLabel.setForeground(ColorPalette.SL_STUDY);
            timeLabel.setForeground(ColorPalette.SL_STUDY);
            isStudySession = true;
        }

        timeLabel.setText(formatTime(secondsLeft));
        startPauseButton.setText("▶ START");
    }

    private void updateDisplay() {
        timeLabel.setText(formatTime(secondsLeft));
        statusLabel.setText(isStudySession ? "STUDY SESSION" : "BREAK TIME");
        statusLabel.setForeground(isStudySession ? ColorPalette.SL_STUDY : ColorPalette.SL_BREAK);
        timeLabel.setForeground(isStudySession ? ColorPalette.SL_STUDY : ColorPalette.SL_BREAK);
    }

    private String formatTime(int totalSeconds) {
        int minutes = totalSeconds / 60;
        int seconds = totalSeconds % 60;
        DecimalFormat format = new DecimalFormat("00");
        return format.format(minutes) + ":" + format.format(seconds);
    }

    private void playSound() {
        Toolkit.getDefaultToolkit().beep();
    }

    /**
     * Stops the timer when the containing window is closed
     */
    public void stopTimer() {
        if (timer.isRunning()) {
            timer.stop();
            isRunning = false;
        }
    }

    /**
     * Updates colors based on the current theme
     */
    private void updateColors() {
        // Get theme-specific colors with better contrast
        Color accentColor = themeManager.isDarkTheme() ?
                new Color(255, 105, 180) : // Hot pink for dark mode
                new Color(199, 21, 133);   // Deep pink for light mode

        Color studyColor = themeManager.isDarkTheme() ?
                new Color(50, 205, 50) :   // Bright lime green for dark mode
                new Color(46, 139, 87);    // Sea green for light mode

        Color breakColor = themeManager.isDarkTheme() ?
                new Color(135, 206, 250) : // Light sky blue for dark mode
                new Color(70, 130, 180);   // Steel blue for light mode

        Color textColor = themeManager.getColor("text");
        Color backgroundColor = themeManager.getColor("panelBackground");

        // Apply colors to components if they exist
        if (isDisplayable()) {
            setBackground(backgroundColor);

            if (timeLabel != null) {
                timeLabel.setForeground(isStudySession ? studyColor : breakColor);
            }

            if (statusLabel != null) {
                statusLabel.setForeground(isStudySession ? studyColor : breakColor);
            }

            if (cycleCountLabel != null) {
                cycleCountLabel.setForeground(textColor);
            }

            // Update border with new accent color
            setBorder(BorderFactory.createCompoundBorder(
                    BorderFactory.createTitledBorder(
                            BorderFactory.createLineBorder(accentColor, 2),
                            "⏱️ Pomodoro Timer",
                            TitledBorder.LEFT,
                            TitledBorder.TOP,
                            new Font("Monospaced", Font.BOLD, 14),
                            accentColor
                    ),
                    BorderFactory.createEmptyBorder(10, 10, 10, 10)
            ));

            // Update buttons
            if (startPauseButton != null && resetButton != null && skipButton != null) {
                updateButtonColors(startPauseButton);
                updateButtonColors(resetButton);
                updateButtonColors(skipButton);
            }

            repaint();
        }
    }

    private void updateButtonColors(JButton button) {
        Color buttonBg = themeManager.getColor("buttonBackground");
        Color buttonText = themeManager.getColor("buttonText");
        Color borderColor = themeManager.isDarkTheme() ? Color.GRAY : Color.BLACK;

        button.setBackground(buttonBg);
        button.setForeground(buttonText);
        button.setBorder(BorderFactory.createLineBorder(borderColor, 1));
    }

    /**
     * Override to update colors when added to container
     */
    @Override
    public void addNotify() {
        super.addNotify();
        updateColors();
    }

    /**
     * Update the panel when theme changes
     * Call this method from parent components when theme changes
     */
    public void refreshTheme() {
        updateColors();
    }
}
