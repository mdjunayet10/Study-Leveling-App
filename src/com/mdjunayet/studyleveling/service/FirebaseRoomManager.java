package com.mdjunayet.studyleveling.service;

import com.mdjunayet.studyleveling.model.User;

import java.util.List;

public class FirebaseRoomManager {
    public static boolean createRoom(String roomId, int maxPlayers, User creator) {
        return FirebaseManager.createRoom(roomId, maxPlayers, creator);
    }

    public static int joinRoom(String roomId, User user, boolean forceJoin) {
        return FirebaseManager.joinRoom(roomId, user, forceJoin);
    }

    public static boolean joinRoom(String roomId, User user) {
        return FirebaseManager.joinRoom(roomId, user);
    }

    public static void leaveRoom(String roomId, String username) {
        FirebaseManager.leaveRoom(roomId, username);
    }

    public static List<String> getUsersInRoom(String roomId) {
        return FirebaseManager.getUsersInRoom(roomId);
    }

    public static boolean deleteUserRooms(String username) {
        return FirebaseManager.deleteUserRooms(username);
    }

    public static boolean roomExists(String roomId) {
        return FirebaseManager.roomExists(roomId);
    }
}