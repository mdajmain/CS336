package com.buyme.util;

public class TestConnection {
    public static void main(String[] args) {
        try {
            java.sql.Connection conn = DatabaseConnection.getConnection();
            System.out.println("Connected successfully!");
            conn.close();
        } catch (Exception e) {
            System.out.println("Connection failed!");
            e.printStackTrace();
        }
    }
}