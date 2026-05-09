package com.mdjunayet.studyleveling.util;

import javax.swing.*;
import javax.swing.border.Border;
import java.awt.*;
import java.util.HashMap;
import java.util.Map;

/**
 * FontManager handles the loading and management of fonts throughout the application.
 * Styled to match Solo Leveling's modern, sleek typography.
 */
public class FontManager {
    private static FontManager instance;

    // Font family names
    public static final String PRIMARY_FONT = "Rajdhani";  // Modern, geometric sans-serif similar to Solo Leveling
    public static final String SECONDARY_FONT = "Titillium Web";
    public static final String FALLBACK_FONT = "SansSerif";

    // Font sizes
    public static final float TITLE_SIZE = 32f;
    public static final float HEADER_SIZE = 24f;
    public static final float SUBHEADER_SIZE = 18f;
    public static final float BODY_SIZE = 14f;
    public static final float SMALL_SIZE = 12f;

    // Font styles
    public static final int REGULAR = Font.PLAIN;
    public static final int BOLD = Font.BOLD;
    public static final int ITALIC = Font.ITALIC;

    // Cache loaded fonts
    private final Map<String, Font> fontCache = new HashMap<>();

    private FontManager() {
        loadFonts();
    }

    public static FontManager getInstance() {
        if (instance == null) {
            instance = new FontManager();
        }
        return instance;
    }

    /**
     * Load custom fonts from resources
     */
    private void loadFonts() {
        try {
            // Load fonts from resources folder (if available)
            // If font files aren't available, fall back to system fonts
            // If fonts aren't available, use fallback system fonts
            System.out.println("Custom fonts not loaded - using system fonts");
        } catch (Exception e) {
            System.err.println("Failed to load custom fonts: " + e.getMessage());
        }
    }

    /**
     * Get a font with specified family, style and size
     */
    public Font getFont(String fontFamily, int style, float size) {
        String key = fontFamily + "-" + style + "-" + size;

        if (fontCache.containsKey(key)) {
            return fontCache.get(key);
        }

        // Try to get the specified font, fall back to system fonts if unavailable
        Font font = new Font(fontFamily, style, (int)size);
        if (!font.getFamily().equalsIgnoreCase(fontFamily)) {
            font = new Font(FALLBACK_FONT, style, (int)size);
        }

        fontCache.put(key, font);
        return font;
    }

    /**
     * Get title font (for main app title)
     */
    public Font getTitleFont() {
        return getFont(PRIMARY_FONT, BOLD, TITLE_SIZE);
    }

    /**
     * Get header font
     */
    public Font getHeaderFont() {
        return getFont(PRIMARY_FONT, BOLD, HEADER_SIZE);
    }

    /**
     * Get subheader font
     */
    public Font getSubheaderFont() {
        return getFont(PRIMARY_FONT, BOLD, SUBHEADER_SIZE);
    }

    /**
     * Get body text font
     */
    public Font getBodyFont() {
        return getFont(PRIMARY_FONT, REGULAR, BODY_SIZE);
    }

    /**
     * Get small text font
     */
    public Font getSmallFont() {
        return getFont(PRIMARY_FONT, REGULAR, SMALL_SIZE);
    }

    /**
     * Apply fonts to common Swing components in a container
     */
    public void applyFontsToContainer(Container container) {
        for (Component comp : container.getComponents()) {
            if (comp instanceof JLabel) {
                JLabel label = (JLabel) comp;
                if (label.getFont().getSize() >= HEADER_SIZE) {
                    label.setFont(getHeaderFont());
                } else if (label.getFont().getSize() >= SUBHEADER_SIZE) {
                    label.setFont(getSubheaderFont());
                } else {
                    label.setFont(getBodyFont());
                }
            } else if (comp instanceof JButton) {
                ((JButton) comp).setFont(getBodyFont());
            } else if (comp instanceof JTextField || comp instanceof JPasswordField) {
                ((JComponent) comp).setFont(getBodyFont());
            } else if (comp instanceof JTextArea) {
                ((JTextArea) comp).setFont(getBodyFont());
            } else if (comp instanceof Container) {
                applyFontsToContainer((Container) comp);
            }
        }
    }

    /**
     * Create a Solo Leveling styled button
     */
    public JButton createStyledButton(String text) {
        JButton button = new JButton(text);
        button.setFont(getFont(PRIMARY_FONT, BOLD, BODY_SIZE));
        button.setForeground(ColorPalette.SL_TEXT_PRIMARY);
        button.setBackground(ColorPalette.SL_PRIMARY);
        button.setFocusPainted(false);
        button.setBorderPainted(false);
        button.setOpaque(true);

        // Add hover effect with brighter border
        button.addMouseListener(new java.awt.event.MouseAdapter() {
            public void mouseEntered(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY_LIGHT);
                button.setBorder(BorderFactory.createLineBorder(ColorPalette.SL_ACCENT, 1));
                button.setBorderPainted(true);
            }

            public void mouseExited(java.awt.event.MouseEvent evt) {
                button.setBackground(ColorPalette.SL_PRIMARY);
                button.setBorderPainted(false);
            }
        });

        return button;
    }

    /**
     * Create a Solo Leveling styled header
     */
    public JLabel createStyledHeader(String text) {
        JLabel header = new JLabel(text);
        header.setFont(getHeaderFont());
        header.setForeground(ColorPalette.SL_TEXT_PRIMARY);

        // Add a subtle bottom border with the accent color
        Border paddingBorder = BorderFactory.createEmptyBorder(5, 10, 5, 10);
        Border lineBorder = BorderFactory.createMatteBorder(0, 0, 2, 0, ColorPalette.SL_ACCENT);
        header.setBorder(BorderFactory.createCompoundBorder(lineBorder, paddingBorder));

        return header;
    }

    /**
     * Create a Solo Leveling styled panel
     */
    public JPanel createStyledPanel() {
        JPanel panel = new JPanel();
        panel.setBackground(ColorPalette.SL_CARD);
        panel.setBorder(BorderFactory.createLineBorder(ColorPalette.SL_PRIMARY_LIGHT, 1));
        return panel;
    }
}
