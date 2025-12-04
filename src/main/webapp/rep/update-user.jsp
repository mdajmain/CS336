<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    if (user == null || !"customer_rep".equalsIgnoreCase(userType)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String userIDStr = request.getParameter("userID");
    String action = request.getParameter("action");
    
    if (userIDStr == null || action == null) {
        response.sendRedirect("manage-users.jsp?error=Invalid request");
        return;
    }
    
    int targetUserID;
    try {
        targetUserID = Integer.parseInt(userIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("manage-users.jsp?error=Invalid user ID");
        return;
    }
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        String message = "";
        
        if ("edit".equals(action)) {
            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String firstName = request.getParameter("firstName");
            String lastName = request.getParameter("lastName");
            
            if (username == null || username.trim().isEmpty() || email == null || email.trim().isEmpty()) {
                response.sendRedirect("manage-users.jsp?error=Username and email are required");
                return;
            }
            
            // Check if username is taken by another user
            try (PreparedStatement checkUsername = conn.prepareStatement(
                "SELECT userID FROM user WHERE username = ? AND userID != ?")) {
                checkUsername.setString(1, username.trim());
                checkUsername.setInt(2, targetUserID);
                try (ResultSet checkRs = checkUsername.executeQuery()) {
                    if (checkRs.next()) {
                        response.sendRedirect("manage-users.jsp?error=Username is already taken");
                        return;
                    }
                }
            }
            
            // Check if email is taken by another user
            try (PreparedStatement checkEmail = conn.prepareStatement(
                "SELECT userID FROM user WHERE email = ? AND userID != ?")) {
                checkEmail.setString(1, email.trim());
                checkEmail.setInt(2, targetUserID);
                try (ResultSet checkEmailRs = checkEmail.executeQuery()) {
                    if (checkEmailRs.next()) {
                        response.sendRedirect("manage-users.jsp?error=Email is already taken");
                        return;
                    }
                }
            }
            
            // Update user table
            try (PreparedStatement updateUser = conn.prepareStatement(
                "UPDATE user SET username = ?, email = ? WHERE userID = ?")) {
                updateUser.setString(1, username.trim());
                updateUser.setString(2, email.trim());
                updateUser.setInt(3, targetUserID);
                updateUser.executeUpdate();
            }
            
            // Update end_user table
            try (PreparedStatement updateEndUser = conn.prepareStatement(
                "UPDATE end_user SET firstName = ?, lastName = ? WHERE userID = ?")) {
                updateEndUser.setString(1, firstName != null ? firstName.trim() : null);
                updateEndUser.setString(2, lastName != null ? lastName.trim() : null);
                updateEndUser.setInt(3, targetUserID);
                updateEndUser.executeUpdate();
            }
            
            message = "User information updated successfully.";
            
        } else if ("suspend".equals(action)) {
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE user SET isSuspended = TRUE WHERE userID = ?")) {
                ps.setInt(1, targetUserID);
                ps.executeUpdate();
            }
            
            // Log the suspension (if table exists)
            try (PreparedStatement logPs = conn.prepareStatement(
                "INSERT INTO user_suspension_log (userID, suspendedBy, action, reason, actionDate) VALUES (?, ?, 'suspended', 'Suspended by customer rep', NOW())")) {
                logPs.setInt(1, targetUserID);
                logPs.setInt(2, user.getUserID());
                logPs.executeUpdate();
            } catch (Exception logEx) {
                // Table might not exist, ignore
            }
            
            // Notify the user
            try (PreparedStatement notifyPs = conn.prepareStatement(
                "INSERT INTO notification (userID, message, type, isRead, createdTime) VALUES (?, 'Your account has been suspended. Please contact customer support for more information.', 'alert_item', FALSE, NOW())")) {
                notifyPs.setInt(1, targetUserID);
                notifyPs.executeUpdate();
            }
            
            message = "User has been suspended.";
            
        } else if ("unsuspend".equals(action)) {
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE user SET isSuspended = FALSE WHERE userID = ?")) {
                ps.setInt(1, targetUserID);
                ps.executeUpdate();
            }
            
            // Log the unsuspension (if table exists)
            try (PreparedStatement logPs = conn.prepareStatement(
                "INSERT INTO user_suspension_log (userID, suspendedBy, action, reason, actionDate) VALUES (?, ?, 'unsuspended', 'Unsuspended by customer rep', NOW())")) {
                logPs.setInt(1, targetUserID);
                logPs.setInt(2, user.getUserID());
                logPs.executeUpdate();
            } catch (Exception logEx) {
                // Table might not exist, ignore
            }
            
            // Notify the user
            try (PreparedStatement notifyPs = conn.prepareStatement(
                "INSERT INTO notification (userID, message, type, isRead, createdTime) VALUES (?, 'Your account has been reactivated. Welcome back!', 'alert_item', FALSE, NOW())")) {
                notifyPs.setInt(1, targetUserID);
                notifyPs.executeUpdate();
            }
            
            message = "User has been unsuspended.";
            
        } else if ("delete".equals(action)) {
            // First, check if user has any active auctions
            try (PreparedStatement checkAuctions = conn.prepareStatement(
                "SELECT COUNT(*) FROM auction WHERE sellerID = ? AND status = 'active'")) {
                checkAuctions.setInt(1, targetUserID);
                try (ResultSet auctionRs = checkAuctions.executeQuery()) {
                    auctionRs.next();
                    if (auctionRs.getInt(1) > 0) {
                        response.sendRedirect("manage-users.jsp?error=Cannot delete user with active auctions. Cancel their auctions first.");
                        return;
                    }
                }
            }
            
            // Delete user (cascade will handle related records)
            try (PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM user WHERE userID = ?")) {
                ps.setInt(1, targetUserID);
                int deleted = ps.executeUpdate();
                
                if (deleted > 0) {
                    message = "User has been deleted.";
                } else {
                    response.sendRedirect("manage-users.jsp?error=Failed to delete user");
                    return;
                }
            }
        }
        
        response.sendRedirect("manage-users.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8"));
        
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("manage-users.jsp?error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
