package com.mdjunayet.studyleveling.multiplayer;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.function.Consumer;
import com.mdjunayet.studyleveling.util.ColorPalette;
import com.mdjunayet.studyleveling.util.FontManager;

/**
 * A panel that displays a countdown timer for competitive multiplayer mode.
 * This timer is shared by all players and shows the remaining time for the competition.
 */
public class CompetitiveTimerPanel extends JPanel {
    private final Timer timer;
    private final JLabel timeLabel;
    private final JLabel titleLabel;
    private final JProgressBar progressBar;
    private final FontManager fontManager = FontManager.getInstance();

    // Control buttons
    private JButton startButton;
    private JButton pauseButton;
    private JButton resetButton;

    private int remainingSeconds;
    private final int totalSeconds;
    private boolean timerRunning = false;
    private Consumer<Void> onTimerEndCallback;

    /**
     * Creates a competitive timer panel with the specified duration in minutes.
     *
     * @param minutes The duration of the timer in minutes
     */
    public CompetitiveTimerPanel(int minutes) {
        this.totalSeconds = minutes * 60;
        this.remainingSeconds = totalSeconds;

        // Set up panel
        setLayout(new BorderLayout(10, 10));
        setBorder(BorderFactory.createCompoundBorder(
                BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 2),
                BorderFactory.createEmptyBorder(15, 15, 15, 15)
        ));
        setBackground(ColorPalette.SL_CARD);

        // Title label
        titleLabel = new JLabel("COMPETITIVE MODE");
        titleLabel.setFont(fontManager.getSubheaderFont().deriveFont(Font.BOLD));
        titleLabel.setForeground(ColorPalette.SL_ACCENT_BRIGHT);
        titleLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Time label
        timeLabel = new JLabel(formatTime(remainingSeconds));
        timeLabel.setFont(new Font("Monospaced", Font.BOLD, 36));
        timeLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        timeLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Progress bar
        progressBar = new JProgressBar(0, totalSeconds);
        progressBar.setValue(totalSeconds);
        progressBar.setForeground(new Color(100, 50, 200)); // Purple color
        progressBar.setStringPainted(false);

        // Information label
        JLabel infoLabel = new JLabel("<html><center>First to complete gets full XP!<br>Later completions get reduced rewards.</center></html>");
        infoLabel.setFont(fontManager.getBodyFont());
        infoLabel.setForeground(ColorPalette.SL_TEXT_SECONDARY);
        infoLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Create timer control buttons
        JPanel buttonPanel = new JPanel(new GridLayout(1, 3, 5, 0));
        buttonPanel.setOpaque(false);

        // Start button
        startButton = new JButton("START");
        startButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        startButton.setBackground(new Color(60, 140, 60)); // Green
        startButton.setForeground(Color.WHITE);
        startButton.setFocusPainted(false);
        startButton.addActionListener(e -> {
            if (!timerRunning) {
                startTimer();
                startButton.setEnabled(false);
                pauseButton.setEnabled(true);
                resetButton.setEnabled(true);
            }
        });

        // Pause button
        pauseButton = new JButton("PAUSE");
        pauseButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        pauseButton.setBackground(new Color(140, 140, 60)); // Yellow
        pauseButton.setForeground(Color.WHITE);
        pauseButton.setFocusPainted(false);
        pauseButton.setEnabled(false);
        pauseButton.addActionListener(e -> {
            if (timerRunning) {
                pauseTimer();
                startButton.setText("RESUME");
                startButton.setEnabled(true);
                pauseButton.setEnabled(false);
            }
        });

        // Reset button
        resetButton = new JButton("RESET");
        resetButton.setFont(fontManager.getBodyFont().deriveFont(Font.BOLD));
        resetButton.setBackground(new Color(140, 60, 60)); // Red
        resetButton.setForeground(Color.WHITE);
        resetButton.setFocusPainted(false);
        resetButton.setEnabled(false);
        resetButton.addActionListener(e -> {
            resetTimer();
            startButton.setText("START");
            startButton.setEnabled(true);
            pauseButton.setEnabled(false);
            resetButton.setEnabled(false);
        });

        buttonPanel.add(startButton);
        buttonPanel.add(pauseButton);
        buttonPanel.add(resetButton);

        // Organize components
        JPanel topPanel = new JPanel(new BorderLayout(5, 5));
        topPanel.setOpaque(false);
        topPanel.add(titleLabel, BorderLayout.NORTH);
        topPanel.add(timeLabel, BorderLayout.CENTER);

        JPanel bottomPanel = new JPanel(new BorderLayout(5, 5));
        bottomPanel.setOpaque(false);
        bottomPanel.add(progressBar, BorderLayout.NORTH);
        bottomPanel.add(infoLabel, BorderLayout.CENTER);
        bottomPanel.add(buttonPanel, BorderLayout.SOUTH);

        add(topPanel, BorderLayout.CENTER);
        add(bottomPanel, BorderLayout.SOUTH);

        // Create the timer
        timer = new Timer(1000, new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (remainingSeconds > 0) {
                    remainingSeconds--;
                    timeLabel.setText(formatTime(remainingSeconds));
                    progressBar.setValue(remainingSeconds);

                    // Change color based on remaining time
                    if (remainingSeconds < totalSeconds * 0.25) { // Less than 25% time remaining
                        timeLabel.setForeground(Color.RED);
                        progressBar.setForeground(Color.RED);
                    } else if (remainingSeconds < totalSeconds * 0.5) { // Less than 50% time remaining
                        timeLabel.setForeground(Color.ORANGE);
                        progressBar.setForeground(Color.ORANGE);
                    }
                } else {
                    // Time's up
                    stopTimer();
                    timeLabel.setText("TIME'S UP!");
                    timeLabel.setForeground(Color.RED);

                    // Call the callback if one is set
                    if (onTimerEndCallback != null) {
                        onTimerEndCallback.accept(null);
                    }

                    // Show time's up message
                    JOptionPane.showMessageDialog(
                            SwingUtilities.getWindowAncestor(CompetitiveTimerPanel.this),
                            "Time's up! Competition has ended.",
                            "Time Expired",
                            JOptionPane.INFORMATION_MESSAGE
                    );
                }
            }
        });
    }

    /**
     * Starts the timer countdown.
     */
    public void startTimer() {
        if (!timerRunning) {
            timer.start();
            timerRunning = true;
            titleLabel.setText("COMPETITION IN PROGRESS");
        }
    }

    /**
     * Pauses the timer countdown.
     */
    public void pauseTimer() {
        if (timerRunning) {
            timer.stop();
            timerRunning = false;
            titleLabel.setText("COMPETITION PAUSED");
        }
    }

    /**
     * Stops the timer countdown.
     */
    public void stopTimer() {
        if (timerRunning) {
            timer.stop();
            timerRunning = false;
        }
    }

    /**
     * Resets the timer to its initial value.
     */
    public void resetTimer() {
        stopTimer();
        remainingSeconds = totalSeconds;
        timeLabel.setText(formatTime(remainingSeconds));
        progressBar.setValue(totalSeconds);
        timeLabel.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        progressBar.setForeground(new Color(100, 50, 200));
        titleLabel.setText("COMPETITIVE MODE");
    }

    /**
     * Formats the time in seconds to a MM:SS format.
     *
     * @param seconds The time in seconds
     * @return A formatted string representation of the time
     */
    private String formatTime(int seconds) {
        int minutes = seconds / 60;
        int secs = seconds % 60;
        return String.format("%02d:%02d", minutes, secs);
    }

    /**
     * Sets a callback to be called when the timer reaches zero.
     *
     * @param callback The callback function
     */
    public void setOnTimerEndCallback(Consumer<Void> callback) {
        this.onTimerEndCallback = callback;
    }

    /**
     * Checks if the timer is currently running.
     *
     * @return true if the timer is running, false otherwise
     */
    public boolean isTimerRunning() {
        return timerRunning;
    }

    /**
     * Gets the remaining time in seconds.
     *
     * @return the remaining time in seconds
     */
    public int getRemainingSeconds() {
        return remainingSeconds;
    }
}