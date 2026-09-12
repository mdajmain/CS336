<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
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
            // ============================================
            // CASCADE DELETE - Delete all related records
            // ============================================
            
            // Use transaction to ensure all-or-nothing deletion
            conn.setAutoCommit(false);
            
            try {
                // 1. Get all auction IDs owned by this user
                java.util.List<Integer> userAuctionIDs = new java.util.ArrayList<>();
                try (PreparedStatement getAuctions = conn.prepareStatement(
                    "SELECT auctionID FROM auction WHERE sellerID = ?")) {
                    getAuctions.setInt(1, targetUserID);
                    try (ResultSet rs = getAuctions.executeQuery()) {
                        while (rs.next()) {
                            userAuctionIDs.add(rs.getInt("auctionID"));
                        }
                    }
                }
                
                // 2. Delete notifications that reference user's auctions (BEFORE deleting auctions)
                for (Integer auctionID : userAuctionIDs) {
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM notification WHERE relatedAuctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                }
                
                // 3. Delete notifications for this user (by userID)
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM notification WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 4. Delete questions that reference user's auctions
                for (Integer auctionID : userAuctionIDs) {
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM question WHERE auctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                }
                
                // 5. Delete questions by this user
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM question WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 6. Delete bid_history for user's auctions
                for (Integer auctionID : userAuctionIDs) {
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM bid_history WHERE auctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                }
                
                // 7. Delete bid_history BY this user
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM bid_history WHERE buyerID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 8. Delete bids ON user's auctions
                for (Integer auctionID : userAuctionIDs) {
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM bid WHERE auctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                }
                
                // 9. Delete bids BY this user
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM bid WHERE buyerID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 10. Delete sales_report entries (as buyer or seller, or for user's auctions)
                for (Integer auctionID : userAuctionIDs) {
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM sales_report WHERE auctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM sales_report WHERE buyerID = ? OR sellerID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.setInt(2, targetUserID);
                    ps.executeUpdate();
                }
                
                // 11. Delete alerts for this user
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM alert WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 12. Delete suspension log entries (if table exists)
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM user_suspension_log WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                } catch (SQLException e) {
                    // Table might not exist, ignore
                }
                
                // 13. Clear winner references in ALL auctions where this user won
                try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE auction SET winnerID = NULL WHERE winnerID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 14. Delete user's auctions and their items
                for (Integer auctionID : userAuctionIDs) {
                    // Get itemID first
                    int itemID = 0;
                    try (PreparedStatement getItem = conn.prepareStatement(
                        "SELECT itemID FROM auction WHERE auctionID = ?")) {
                        getItem.setInt(1, auctionID);
                        try (ResultSet rs = getItem.executeQuery()) {
                            if (rs.next()) {
                                itemID = rs.getInt("itemID");
                            }
                        }
                    }
                    
                    // Delete the auction
                    try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM auction WHERE auctionID = ?")) {
                        ps.setInt(1, auctionID);
                        ps.executeUpdate();
                    }
                    
                    // Delete item_field and item
                    if (itemID > 0) {
                        try (PreparedStatement ps = conn.prepareStatement(
                            "DELETE FROM item_field WHERE itemID = ?")) {
                            ps.setInt(1, itemID);
                            ps.executeUpdate();
                        }
                        
                        try (PreparedStatement ps = conn.prepareStatement(
                            "DELETE FROM item WHERE itemID = ?")) {
                            ps.setInt(1, itemID);
                            ps.executeUpdate();
                        }
                    }
                }
                
                // 15. Delete from end_user table
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM end_user WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    ps.executeUpdate();
                }
                
                // 16. Finally, delete the user
                try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM user WHERE userID = ?")) {
                    ps.setInt(1, targetUserID);
                    int deleted = ps.executeUpdate();
                    
                    if (deleted > 0) {
                        conn.commit();
                        message = "User and all associated data have been permanently deleted.";
                    } else {
                        conn.rollback();
                        response.sendRedirect("manage-users.jsp?error=Failed to delete user");
                        return;
                    }
                }
                
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        }
        
        response.sendRedirect("manage-users.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8"));
        
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("manage-users.jsp?error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>

