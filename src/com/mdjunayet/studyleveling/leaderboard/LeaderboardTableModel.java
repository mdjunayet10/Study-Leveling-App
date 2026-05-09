package com.mdjunayet.studyleveling.leaderboard;

import com.mdjunayet.studyleveling.model.User;

import javax.swing.table.AbstractTableModel;
import java.util.ArrayList;
import java.util.List;

public class LeaderboardTableModel extends AbstractTableModel {
    private final String[] columns = {"Rank", "Username", "XP", "Level"};
    private List<User> users = new ArrayList<>();

    public void setUsers(List<User> users) {
        this.users = users;
        fireTableDataChanged();
    }

    @Override
    public int getRowCount() {
        return users.size();
    }

    @Override
    public int getColumnCount() {
        return columns.length;
    }

    @Override
    public String getColumnName(int col) {
        return columns[col];
    }

    @Override
    public Object getValueAt(int rowIndex, int columnIndex) {
        User user = users.get(rowIndex);
        return switch (columnIndex) {
            case 0 -> rowIndex + 1; // Rank
            case 1 -> user.getUsername();
            case 2 -> user.getXp();
            case 3 -> user.getLevel();
            default -> null;
        };
    }
}