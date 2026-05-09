package com.mdjunayet.studyleveling.util;

import java.awt.*;
import java.util.HashMap;
import java.util.Map;

public class ColorPalette {
    // Arcane Midnight palette, matched to the Flutter app.
    public static final Color SL_BACKGROUND = new Color(8, 10, 22);
    public static final Color SL_BACKGROUND_ALT = new Color(15, 16, 32);
    public static final Color SL_PRIMARY = new Color(139, 92, 246);
    public static final Color SL_PRIMARY_DARK = new Color(21, 17, 41);
    public static final Color SL_PRIMARY_LIGHT = new Color(167, 139, 250);
    public static final Color SL_ACCENT = new Color(34, 211, 238);
    public static final Color SL_ACCENT_BRIGHT = new Color(103, 232, 249);
    public static final Color SL_CARD = new Color(23, 24, 43);
    public static final Color SL_CARD_ELEVATED = new Color(31, 32, 56);
    public static final Color SL_TEXT_PRIMARY = new Color(248, 250, 252);
    public static final Color SL_TEXT_SECONDARY = new Color(203, 213, 225);
    public static final Color SL_DIVIDER = new Color(52, 48, 79);

    public static final Color SL_SUCCESS = new Color(52, 211, 153);
    public static final Color SL_ERROR = new Color(251, 113, 133);
    public static final Color SL_WARNING = new Color(250, 204, 21);
    public static final Color SL_INFO = new Color(96, 165, 250);

    public static final Color SL_XP = new Color(250, 204, 21);
    public static final Color SL_COIN = new Color(255, 181, 71);
    public static final Color SL_LEVEL = new Color(103, 232, 249);
    public static final Color SL_MANA = new Color(167, 139, 250);

    public static final Color SL_EASY = SL_SUCCESS;
    public static final Color SL_MEDIUM = SL_WARNING;
    public static final Color SL_HARD = SL_ERROR;

    public static final Color SL_GOLD = new Color(255, 209, 102);
    public static final Color SL_SILVER = new Color(215, 222, 232);
    public static final Color SL_BRONZE = new Color(208, 138, 78);

    public static final Color SL_STUDY = SL_SUCCESS;
    public static final Color SL_BREAK = SL_INFO;

    // Regular colors (Light theme)
    public static final Color LIGHT_PRIMARY = new Color(63, 81, 181);
    public static final Color LIGHT_PRIMARY_DARK = new Color(48, 63, 159);
    public static final Color LIGHT_PRIMARY_LIGHT = new Color(121, 134, 203);
    public static final Color LIGHT_ACCENT = new Color(255, 64, 129);
    public static final Color LIGHT_BACKGROUND = new Color(245, 245, 245);
    public static final Color LIGHT_CARD = new Color(255, 255, 255);
    public static final Color LIGHT_TEXT_PRIMARY = new Color(33, 33, 33);
    public static final Color LIGHT_TEXT_SECONDARY = new Color(117, 117, 117);
    public static final Color LIGHT_DIVIDER = new Color(189, 189, 189);

    public static final Color LIGHT_SUCCESS = new Color(76, 175, 80);
    public static final Color LIGHT_ERROR = new Color(244, 67, 54);
    public static final Color LIGHT_WARNING = new Color(255, 152, 0);
    public static final Color LIGHT_INFO = new Color(33, 150, 243);

    private static final Map<String, Color> slColorMap = new HashMap<>();
    private static final Map<String, Color> lightColorMap = new HashMap<>();

    static {
        slColorMap.put("primary", SL_PRIMARY);
        slColorMap.put("primaryDark", SL_PRIMARY_DARK);
        slColorMap.put("primaryLight", SL_PRIMARY_LIGHT);
        slColorMap.put("accent", SL_ACCENT);
        slColorMap.put("accentBright", SL_ACCENT_BRIGHT);
        slColorMap.put("background", SL_BACKGROUND);
        slColorMap.put("panelBackground", SL_BACKGROUND);
        slColorMap.put("cardBackground", SL_CARD);
        slColorMap.put("cardElevated", SL_CARD_ELEVATED);
        slColorMap.put("text", SL_TEXT_PRIMARY);
        slColorMap.put("textSecondary", SL_TEXT_SECONDARY);
        slColorMap.put("divider", SL_DIVIDER);
        slColorMap.put("success", SL_SUCCESS);
        slColorMap.put("error", SL_ERROR);
        slColorMap.put("warning", SL_WARNING);
        slColorMap.put("info", SL_INFO);
        slColorMap.put("buttonBackground", SL_PRIMARY);
        slColorMap.put("buttonText", SL_TEXT_PRIMARY);
        slColorMap.put("xp", SL_XP);
        slColorMap.put("coin", SL_COIN);
        slColorMap.put("level", SL_LEVEL);
        slColorMap.put("mana", SL_MANA);

        // Initialize light theme map (fallback, not used in Solo Leveling theme)
        lightColorMap.put("primary", LIGHT_PRIMARY);
        lightColorMap.put("primaryDark", LIGHT_PRIMARY_DARK);
        lightColorMap.put("primaryLight", LIGHT_PRIMARY_LIGHT);
        lightColorMap.put("accent", LIGHT_ACCENT);
        lightColorMap.put("background", LIGHT_BACKGROUND);
        lightColorMap.put("panelBackground", LIGHT_BACKGROUND);
        lightColorMap.put("cardBackground", LIGHT_CARD);
        lightColorMap.put("text", LIGHT_TEXT_PRIMARY);
        lightColorMap.put("textSecondary", LIGHT_TEXT_SECONDARY);
        lightColorMap.put("divider", LIGHT_DIVIDER);
        lightColorMap.put("success", LIGHT_SUCCESS);
        lightColorMap.put("error", LIGHT_ERROR);
        lightColorMap.put("warning", LIGHT_WARNING);
        lightColorMap.put("info", LIGHT_INFO);
        lightColorMap.put("buttonBackground", LIGHT_PRIMARY);
        lightColorMap.put("buttonText", Color.WHITE);
    }

    /**
     * Get the color map for the specified theme
     */
    public static Map<String, Color> getColorMap(boolean isDarkTheme) {
        // Always return Solo Leveling theme regardless of dark/light setting
        return slColorMap;
    }

    /**
     * Get a specific color for the current theme
     */
    public static Color getColor(String colorName, boolean isDarkTheme) {
        Map<String, Color> colorMap = getColorMap(isDarkTheme);
        return colorMap.getOrDefault(colorName, slColorMap.get("text"));
    }
}
