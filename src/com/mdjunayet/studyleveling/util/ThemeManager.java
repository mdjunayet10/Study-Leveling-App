package com.mdjunayet.studyleveling.util;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionListener;
import java.util.ArrayList;
import java.util.List;
import java.util.prefs.Preferences;

/**
 * Manages application-wide theme settings and color schemes
 */
public class ThemeManager {

    // Theme types
    public enum Theme {
        LIGHT, DARK
    }

    // Preference keys
    private static final String PREF_THEME = "theme";

    // Singleton instance
    private static ThemeManager instance;

    // Current theme
    private Theme currentTheme = Theme.LIGHT;

    // Preferences storage
    private final Preferences prefs = Preferences.userNodeForPackage(ThemeManager.class);

    // Theme change listeners
    private final List<ActionListener> themeChangeListeners = new ArrayList<>();

    // Font manager instance
    private final FontManager fontManager = FontManager.getInstance();

    private ThemeManager() {
        // Load saved theme preference
        String savedTheme = prefs.get(PREF_THEME, Theme.LIGHT.name());
        try {
            currentTheme = Theme.valueOf(savedTheme);
        } catch (IllegalArgumentException e) {
            currentTheme = Theme.LIGHT;
        }
    }

    public static synchronized ThemeManager getInstance() {
        if (instance == null) {
            instance = new ThemeManager();
        }
        return instance;
    }

    public void setTheme(Theme theme) {
        this.currentTheme = theme;
        prefs.put(PREF_THEME, theme.name());

        // Update UI manager defaults for standard Swing components
        updateUIManagerDefaults();

        // Notify listeners about the theme change
        notifyThemeChanged();
    }

    public Theme getCurrentTheme() {
        return currentTheme;
    }

    public boolean isDarkTheme() {
        return currentTheme == Theme.DARK;
    }

    private void updateUIManagerDefaults() {
        // Set theme defaults
        UIManager.put("Panel.background", getColor("background"));
        UIManager.put("OptionPane.background", getColor("panelBackground"));
        UIManager.put("TextField.background", getColor("cardBackground"));
        UIManager.put("ComboBox.background", getColor("cardBackground"));
        UIManager.put("TextArea.background", getColor("cardBackground"));
        UIManager.put("Button.background", getColor("buttonBackground"));

        UIManager.put("Label.foreground", getColor("text"));
        UIManager.put("TextField.foreground", getColor("text"));
        UIManager.put("TextArea.foreground", getColor("text"));
        UIManager.put("ComboBox.foreground", getColor("text"));
        UIManager.put("Button.foreground", getColor("buttonText"));

        UIManager.put("TabbedPane.background", getColor("background"));
        UIManager.put("TabbedPane.foreground", getColor("text"));
        UIManager.put("TabbedPane.selected", getColor("cardBackground"));

        // Set font defaults
        UIManager.put("Label.font", fontManager.getBodyFont());
        UIManager.put("TextField.font", fontManager.getBodyFont());
        UIManager.put("TextArea.font", fontManager.getBodyFont());
        UIManager.put("Button.font", fontManager.getBodyFont());
        UIManager.put("ComboBox.font", fontManager.getBodyFont());
        UIManager.put("TabbedPane.font", fontManager.getBodyFont());
        UIManager.put("Table.font", fontManager.getBodyFont());
        UIManager.put("TableHeader.font", fontManager.getSubheaderFont());
    }

    /**
     * Get a color from the current theme's palette
     */
    public Color getColor(String colorName) {
        return ColorPalette.getColor(colorName, isDarkTheme());
    }

    /**
     * Apply the current theme to a JFrame
     */
    public void applyTheme(JFrame frame) {
        frame.getContentPane().setBackground(getColor("background"));
        fontManager.applyFontsToContainer(frame);
        SwingUtilities.updateComponentTreeUI(frame);
    }

    /**
     * Add a listener that will be notified when the theme changes
     */
    public void addThemeChangeListener(ActionListener listener) {
        themeChangeListeners.add(listener);
    }

    /**
     * Remove a theme change listener
     */
    public void removeThemeChangeListener(ActionListener listener) {
        themeChangeListeners.remove(listener);
    }

    /**
     * Notify all registered listeners about a theme change
     */
    private void notifyThemeChanged() {
        for (ActionListener listener : themeChangeListeners) {
            listener.actionPerformed(new java.awt.event.ActionEvent(this, 0, "themeChanged"));
        }
    }
}
