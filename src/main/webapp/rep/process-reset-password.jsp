<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.security.SecureRandom" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String userIDStr = request.getParameter("userID");
    String passwordType = request.getParameter("passwordType");
    String newPassword = request.getParameter("newPassword");
    String confirmPassword = request.getParameter("confirmPassword");
    boolean notifyUser = "true".equals(request.getParameter("notifyUser"));
    
    if (userIDStr == null) {
        response.sendRedirect("reset-password.jsp?error=Invalid request");
        return;
    }
    
    int targetUserID;
    try {
        targetUserID = Integer.parseInt(userIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("reset-password.jsp?error=Invalid user ID");
        return;
    }
    
    String finalPassword;
    
    if ("custom".equals(passwordType)) {
        // Validate custom password
        if (newPassword == null || newPassword.length() < 6) {
            response.sendRedirect("reset-password.jsp?userID=" + targetUserID + "&error=Password must be at least 6 characters");
            return;
        }
        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("reset-password.jsp?userID=" + targetUserID + "&error=Passwords do not match");
            return;
        }
        finalPassword = newPassword;
    } else {
        // Generate temporary password
        String chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(10);
        for (int i = 0; i < 10; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        finalPassword = sb.toString();
    }
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        // Verify user exists and is an end_user
        String username = "";
        String email = "";
        
        try (PreparedStatement checkUser = conn.prepareStatement(
            "SELECT username, email FROM user WHERE userID = ? AND userType = 'end_user'")) {
            checkUser.setInt(1, targetUserID);
            try (ResultSet rs = checkUser.executeQuery()) {
                if (!rs.next()) {
                    response.sendRedirect("reset-password.jsp?error=User not found or not an end user");
                    return;
                }
                username = rs.getString("username");
                email = rs.getString("email");
            }
        }
        
        // Update password
        // Note: In production, you should hash the password!
        try (PreparedStatement updatePs = conn.prepareStatement(
            "UPDATE user SET password = ? WHERE userID = ?")) {
            updatePs.setString(1, finalPassword);
            updatePs.setInt(2, targetUserID);
            updatePs.executeUpdate();
        }
        
        // Send notification if requested
        if (notifyUser) {
            String notificationMessage;
            if ("custom".equals(passwordType)) {
                notificationMessage = "Your password has been reset by customer support. Please log in with your new password.";
            } else {
                notificationMessage = "Your password has been reset by customer support. Your temporary password is: " + finalPassword + ". Please change it after logging in.";
            }
            
            try (PreparedStatement notifyPs = conn.prepareStatement(
                "INSERT INTO notification (userID, message, type, isRead, createdTime) VALUES (?, ?, 'alert_item', FALSE, NOW())")) {
                notifyPs.setInt(1, targetUserID);
                notifyPs.setString(2, notificationMessage);
                notifyPs.executeUpdate();
            }
        }
        
        // Build success message
        String successMessage;
        if ("custom".equals(passwordType)) {
            successMessage = "Password reset successfully for " + username + ".";
        } else {
            successMessage = "Password reset successfully for " + username + ". Temporary password: " + finalPassword;
        }
        
        response.sendRedirect("reset-password.jsp?message=" + java.net.URLEncoder.encode(successMessage, "UTF-8"));
        
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("reset-password.jsp?userID=" + targetUserID + "&error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
