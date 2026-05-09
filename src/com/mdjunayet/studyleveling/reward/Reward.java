package com.mdjunayet.studyleveling.reward;

public class Reward {
    private String name;
    private int cost;

    public Reward(String name, int cost) {
        this.name = name;
        this.cost = cost;
    }

    public String getName() {
        return name;
    }

    public int getCost() {
        return cost;
    }

    @Override
    public String toString() {
        return name + " - " + cost + " POINTS";
    }
}