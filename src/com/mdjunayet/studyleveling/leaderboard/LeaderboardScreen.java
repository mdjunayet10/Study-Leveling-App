package com.mdjunayet.studyleveling.leaderboard;

import com.mdjunayet.studyleveling.model.User;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.awt.*;
import java.util.Comparator;
import java.util.List;

public class LeaderboardScreen extends JFrame {

    public LeaderboardScreen(List<User> users) {
        setTitle("Leaderboard");
        setSize(500, 400);
        setLocationRelativeTo(null);
        setDefaultCloseOperation(DISPOSE_ON_CLOSE);
        setLayout(new BorderLayout());

        String[] columns = {"Username", "Level", "XP", "Coins"};
        DefaultTableModel model = new DefaultTableModel(columns, 0);

        // Sort by Level, then XP, then Coins (all descending)
        users.stream()
                .sorted(Comparator
                        .comparingInt((User u) -> u.getLevel()).reversed()
                        .thenComparingInt(u -> -u.getXp())
                        .thenComparingInt(u -> -u.getCoins()))
                .forEach(user -> model.addRow(new Object[]{
                        user.getUsername(), user.getLevel(), user.getXp(), user.getCoins()
                }));

        JTable table = new JTable(model);
        table.setFont(new Font("Monospaced", Font.PLAIN, 13));
        table.setRowHeight(24);
        table.setEnabled(false);
        table.getTableHeader().setFont(new Font("Monospaced", Font.BOLD, 14));

        JLabel title = new JLabel("\uD83C\uDFC6 Leaderboard", SwingConstants.CENTER);
        title.setFont(new Font("Monospaced", Font.BOLD, 18));
        title.setBorder(BorderFactory.createEmptyBorder(10, 0, 10, 0));

        add(title, BorderLayout.NORTH);
        add(new JScrollPane(table), BorderLayout.CENTER);

        setVisible(true);
    }
}