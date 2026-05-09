package com.mdjunayet.studyleveling.session;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.function.Consumer;

/**
 * A simple, highly visible timer display for competitive mode
 */
public class CountdownTimerPanel extends JPanel {
    private final Timer timer;
    private final JLabel timeLabel;
    private int remainingSeconds;
    private final int totalSeconds;
    private boolean timerRunning = false;
    private Consumer<Void> onTimerEndCallback;

    /**
     * Creates a countdown timer panel with the specified duration in minutes
     */
    public CountdownTimerPanel(int minutes) {
        this.totalSeconds = minutes * 60;
        this.remainingSeconds = totalSeconds;

        // Set up the panel with a gradient background
        setLayout(new BorderLayout());
        setBorder(BorderFactory.createEmptyBorder(15, 15, 15, 15));
        setBackground(new Color(40, 20, 80)); // Dark purple background

        // Create the time display with a very large font
        timeLabel = new JLabel(formatTime(remainingSeconds));
        timeLabel.setFont(new Font("Monospaced", Font.BOLD, 48));
        timeLabel.setForeground(Color.WHITE);
        timeLabel.setHorizontalAlignment(SwingConstants.CENTER);

        // Add drop shadow effect for better visibility
        timeLabel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // Add a pulsing animation to draw attention
        Timer pulseTimer = new Timer(1000, e -> {
            if (timerRunning && remainingSeconds < 60) { // Pulse when less than 1 minute left
                Color pulseColor = Color.getHSBColor(0.0f, 0.0f, (remainingSeconds % 2 == 0) ? 1.0f : 0.8f);
                timeLabel.setForeground(pulseColor);
            }
        });
        pulseTimer.start();

        // Center the time display
        add(timeLabel, BorderLayout.CENTER);

        // Create the timer that updates once per second
        timer = new Timer(1000, new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                if (remainingSeconds > 0) {
                    remainingSeconds--;
                    timeLabel.setText(formatTime(remainingSeconds));

                    // Change color based on remaining time
                    if (remainingSeconds < totalSeconds * 0.25) { // Less than 25% time remaining
                        timeLabel.setForeground(Color.RED);
                    } else if (remainingSeconds < totalSeconds * 0.5) { // Less than 50% time remaining
                        timeLabel.setForeground(Color.ORANGE);
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
                }
            }
        });
    }

    /**
     * Formats the time in seconds to a MM:SS format
     */
    private String formatTime(int seconds) {
        int minutes = seconds / 60;
        int secs = seconds % 60;
        return String.format("%02d:%02d", minutes, secs);
    }

    /**
     * Starts the timer countdown
     */
    public void startTimer() {
        if (!timerRunning) {
            timer.start();
            timerRunning = true;
        }
    }

    /**
     * Stops the timer countdown
     */
    public void stopTimer() {
        if (timerRunning) {
            timer.stop();
            timerRunning = false;
        }
    }

    /**
     * Checks if the timer is running
     */
    public boolean isTimerRunning() {
        return timerRunning;
    }

    /**
     * Sets a callback to be called when the timer reaches zero
     */
    public void setOnTimerEndCallback(Consumer<Void> callback) {
        this.onTimerEndCallback = callback;
    }
}