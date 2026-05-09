package com.mdjunayet.studyleveling.service;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonDeserializationContext;
import com.google.gson.JsonDeserializer;
import com.google.gson.JsonElement;
import com.google.gson.JsonParseException;
import com.google.gson.JsonPrimitive;
import com.google.gson.JsonSerializationContext;
import com.google.gson.JsonSerializer;
import com.google.gson.reflect.TypeToken;
import com.mdjunayet.studyleveling.model.User;

import java.io.*;
import java.lang.reflect.Type;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DataManager {
    private static final String USER_DIR = "data/";
    private static final String PASSWORD_FILE = USER_DIR + "users.json";

    // Add custom serializer/deserializer for LocalDate
    private static final Gson gson = new GsonBuilder()
        .setPrettyPrinting()
        .registerTypeAdapter(LocalDate.class, new LocalDateAdapter())
        .create();

    private static Map<String, String> userPasswords = loadPasswordMap();

    static {
        File dir = new File(USER_DIR);
        if (!dir.exists()) dir.mkdirs();
    }

    // Custom adapter for LocalDate serialization/deserialization
    private static class LocalDateAdapter implements JsonSerializer<LocalDate>, JsonDeserializer<LocalDate> {
        private final DateTimeFormatter formatter = DateTimeFormatter.ISO_LOCAL_DATE;

        @Override
        public JsonElement serialize(LocalDate src, Type typeOfSrc, JsonSerializationContext context) {
            return src == null ? null : new JsonPrimitive(formatter.format(src));
        }

        @Override
        public LocalDate deserialize(JsonElement json, Type typeOfT, JsonDeserializationContext context)
                throws JsonParseException {
            return json == null || json.isJsonNull() ? null : LocalDate.parse(json.getAsString(), formatter);
        }
    }

    public static User loadUser(String username) {
        File file = new File(USER_DIR + username + ".json");
        if (!file.exists()) return null;

        try (FileReader reader = new FileReader(file)) {
            User user = gson.fromJson(reader, User.class);
            System.out.println("Loaded user: " + username + " (XP: " + user.getXp() + ", Level: " + user.getLevel() + ", Coins: " + user.getCoins() + ")");
            return user;
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
    }

    public static void saveUser(User user) {
        try (FileWriter writer = new FileWriter(USER_DIR + user.getUsername() + ".json")) {
            gson.toJson(user, writer);
            System.out.println("Saved user: " + user.getUsername() + " (XP: " + user.getXp() + ", Level: " + user.getLevel() + ", Coins: " + user.getCoins() + ")");
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static List<User> loadAllUsers() {
        List<User> users = new ArrayList<>();
        File dir = new File(USER_DIR);
        File[] files = dir.listFiles((directory, name) -> name.endsWith(".json") && !name.equals("users.json"));

        if (files == null) {
            return users;
        }

        for (File file : files) {
            String fileName = file.getName();
            if (!fileName.endsWith(".json")) {
                continue;
            }

            String username = fileName.substring(0, fileName.length() - 5);
            User user = loadUser(username);
            if (user != null) {
                users.add(user);
            }
        }

        return users;
    }

    public static void savePassword(String username, String password) {
        userPasswords.put(username, password);
        savePasswordMap();
    }

    public static boolean userExists(String username) {
        return loadPasswordMap().containsKey(username);
    }

    public static boolean verifyPassword(String username, String input) {
        String savedPassword = loadPasswordMap().get(username);
        return input.equals(savedPassword);
    }

    private static Map<String, String> loadPasswordMap() {
        File file = new File(PASSWORD_FILE);
        if (!file.exists()) return new HashMap<>();
        try (FileReader reader = new FileReader(file)) {
            Type type = new TypeToken<Map<String, String>>() {}.getType();
            return gson.fromJson(reader, type);
        } catch (IOException e) {
            e.printStackTrace();
            return new HashMap<>();
        }
    }

    private static void savePasswordMap() {
        try (FileWriter writer = new FileWriter(PASSWORD_FILE)) {
            gson.toJson(userPasswords, writer);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}