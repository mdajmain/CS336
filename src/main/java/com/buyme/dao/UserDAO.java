// File: src/main/java/com/buyme/dao/UserDAO.java
package com.buyme.dao;

import com.buyme.model.User;
import com.buyme.util.DatabaseConnection;
import org.mindrot.jbcrypt.BCrypt;
import java.sql.*;

public class UserDAO {

    public User login(String username, String password) {
        User user = null;
        String sql = "SELECT * FROM user WHERE username = ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, username);

            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                String storedHash = rs.getString("password");
                if (!BCrypt.checkpw(password, storedHash)) {
                    return null;
                }

                user = new User();
                user.setUserID(rs.getInt("userID"));
                user.setUsername(rs.getString("username"));
                user.setEmail(rs.getString("email"));
                user.setUserType(rs.getString("userType"));
                user.setCreatedDate(rs.getTimestamp("createdDate"));

                // If end user, get additional details
                if ("end_user".equals(user.getUserType())) {
                    loadEndUserDetails(user, conn);
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return user;
    }
    
    public boolean register(User user) {
        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // Insert into user table
            String userSql = "INSERT INTO user (username, password, email, userType) VALUES (?, ?, ?, ?)";
            PreparedStatement userStmt = conn.prepareStatement(userSql, Statement.RETURN_GENERATED_KEYS);
            userStmt.setString(1, user.getUsername());
            userStmt.setString(2, BCrypt.hashpw(user.getPassword(), BCrypt.gensalt()));
            userStmt.setString(3, user.getEmail());
            userStmt.setString(4, "end_user");
            
            int affectedRows = userStmt.executeUpdate();
            if (affectedRows == 0) {
                conn.rollback();
                return false;
            }
            
            ResultSet generatedKeys = userStmt.getGeneratedKeys();
            if (generatedKeys.next()) {
                int userID = generatedKeys.getInt(1);
                
                // Insert into end_user table
                String endUserSql = "INSERT INTO end_user (userID, firstName, lastName, address, phone, isAnonymous) VALUES (?, ?, ?, ?, ?, ?)";
                PreparedStatement endUserStmt = conn.prepareStatement(endUserSql);
                endUserStmt.setInt(1, userID);
                endUserStmt.setString(2, user.getFirstName());
                endUserStmt.setString(3, user.getLastName());
                endUserStmt.setString(4, user.getAddress());
                endUserStmt.setString(5, user.getPhone());
                endUserStmt.setBoolean(6, false);
                
                endUserStmt.executeUpdate();
                conn.commit();
                return true;
            }
            
            conn.rollback();
            return false;
            
        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            return false;
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    DatabaseConnection.closeConnection(conn);
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    public boolean checkUsernameExists(String username) {
        String sql = "SELECT COUNT(*) FROM user WHERE username = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, username);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    public boolean checkEmailExists(String email) {
        String sql = "SELECT COUNT(*) FROM user WHERE email = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, email);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
    
    private void loadEndUserDetails(User user, Connection conn) throws SQLException {
        String sql = "SELECT * FROM end_user WHERE userID = ?";
        PreparedStatement pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, user.getUserID());
        
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            user.setFirstName(rs.getString("firstName"));
            user.setLastName(rs.getString("lastName"));
            user.setAddress(rs.getString("address"));
            user.setPhone(rs.getString("phone"));
            user.setAnonymous(rs.getBoolean("isAnonymous"));
        }
    }
}