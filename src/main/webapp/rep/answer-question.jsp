<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>


<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String questionIDStr = request.getParameter("questionID");
    String answer = request.getParameter("answer");
    String action = request.getParameter("action");
    
    if (questionIDStr == null || action == null) {
        response.sendRedirect("questions.jsp?error=Invalid request");
        return;
    }
    
    int questionID;
    try {
        questionID = Integer.parseInt(questionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("questions.jsp?error=Invalid question ID");
        return;
    }
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        // Get rep ID
        Integer repID = null;
        try (PreparedStatement repPs = conn.prepareStatement(
            "SELECT repID FROM customer_rep WHERE userID = ?")) {
            repPs.setInt(1, user.getUserID());
            try (ResultSet repRs = repPs.executeQuery()) {
                if (repRs.next()) {
                    repID = repRs.getInt("repID");
                }
            }
        }
        
        String message = "";
        
        if ("answer".equals(action)) {
            if (answer == null || answer.trim().isEmpty()) {
                response.sendRedirect("questions.jsp?error=Answer cannot be empty");
                return;
            }
            
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE question SET answer = ?, status = 'answered', repID = ?, answeredTime = NOW() WHERE questionID = ?")) {
                ps.setString(1, answer.trim());
                if (repID != null) {
                    ps.setInt(2, repID);
                } else {
                    ps.setNull(2, Types.INTEGER);
                }
                ps.setInt(3, questionID);
                ps.executeUpdate();
            }
            
            // Get user ID to notify them
            try (PreparedStatement notifyPs = conn.prepareStatement(
                "SELECT userID, subject FROM question WHERE questionID = ?")) {
                notifyPs.setInt(1, questionID);
                try (ResultSet notifyRs = notifyPs.executeQuery()) {
                    if (notifyRs.next()) {
                        int targetUserID = notifyRs.getInt("userID");
                        String subject = notifyRs.getString("subject");
                        
                        // Create notification for the user
                        try (PreparedStatement insertNotify = conn.prepareStatement(
                            "INSERT INTO notification (userID, message, type, isRead, createdTime) VALUES (?, ?, 'alert_item', FALSE, NOW())")) {
                            insertNotify.setInt(1, targetUserID);
                            insertNotify.setString(2, "Your question '" + (subject != null ? subject : "Question") + "' has been answered by customer support.");
                            insertNotify.executeUpdate();
                        }
                    }
                }
            }
            
            message = "Answer submitted successfully!";
            
        } else if ("close".equals(action)) {
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE question SET status = 'closed' WHERE questionID = ?")) {
                ps.setInt(1, questionID);
                ps.executeUpdate();
            }
            message = "Question marked as closed.";
            
        } else if ("reopen".equals(action)) {
            try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE question SET status = 'answered' WHERE questionID = ?")) {
                ps.setInt(1, questionID);
                ps.executeUpdate();
            }
            message = "Question reopened.";
        }
        
        response.sendRedirect("questions.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8"));
        
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("questions.jsp?error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
