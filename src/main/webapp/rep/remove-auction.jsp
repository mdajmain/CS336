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
    
    String auctionIDStr = request.getParameter("auctionID");
    String reason = request.getParameter("reason");
    
    if (auctionIDStr == null || reason == null || reason.trim().isEmpty()) {
        response.sendRedirect("manage-auctions.jsp?error=Invalid request. Auction ID and reason are required.");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("manage-auctions.jsp?error=Invalid auction ID");
        return;
    }
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        // Get auction details first
        int sellerID = 0;
        Integer winnerID = null;
        String itemName = "";
        
        try (PreparedStatement getAuction = conn.prepareStatement(
            "SELECT a.sellerID, a.winnerID, i.itemName FROM auction a JOIN item i ON a.itemID = i.itemID WHERE a.auctionID = ?")) {
            getAuction.setInt(1, auctionID);
            try (ResultSet rs = getAuction.executeQuery()) {
                if (!rs.next()) {
                    response.sendRedirect("manage-auctions.jsp?error=Auction not found");
                    return;
                }
                
                sellerID = rs.getInt("sellerID");
                winnerID = rs.getObject("winnerID") != null ? rs.getInt("winnerID") : null;
                itemName = rs.getString("itemName");
            }
        }
        
        // Cancel the auction
        try (PreparedStatement ps = conn.prepareStatement(
            "UPDATE auction SET status = 'cancelled', winnerID = NULL WHERE auctionID = ?")) {
            ps.setInt(1, auctionID);
            int updated = ps.executeUpdate();
            
            if (updated > 0) {
                // Notify the seller
                try (PreparedStatement notifySeller = conn.prepareStatement(
                    "INSERT INTO notification (userID, message, type, relatedAuctionID, isRead, createdTime) VALUES (?, ?, 'auction_ended', ?, FALSE, NOW())")) {
                    notifySeller.setInt(1, sellerID);
                    notifySeller.setString(2, "Your auction for '" + itemName + "' has been removed by a customer representative. Reason: " + reason);
                    notifySeller.setInt(3, auctionID);
                    notifySeller.executeUpdate();
                }
                
                // Notify all bidders
                try (PreparedStatement getBidders = conn.prepareStatement(
                    "SELECT DISTINCT buyerID FROM bid WHERE auctionID = ?")) {
                    getBidders.setInt(1, auctionID);
                    try (ResultSet bidders = getBidders.executeQuery()) {
                        while (bidders.next()) {
                            int bidderID = bidders.getInt("buyerID");
                            try (PreparedStatement notifyBidder = conn.prepareStatement(
                                "INSERT INTO notification (userID, message, type, relatedAuctionID, isRead, createdTime) VALUES (?, ?, 'auction_ended', ?, FALSE, NOW())")) {
                                notifyBidder.setInt(1, bidderID);
                                notifyBidder.setString(2, "An auction you were bidding on ('" + itemName + "') has been removed. Reason: " + reason);
                                notifyBidder.setInt(3, auctionID);
                                notifyBidder.executeUpdate();
                            }
                        }
                    }
                }
                
                response.sendRedirect("manage-auctions.jsp?message=" + java.net.URLEncoder.encode("Auction #" + auctionID + " has been removed successfully.", "UTF-8"));
            } else {
                response.sendRedirect("manage-auctions.jsp?error=Failed to remove auction");
            }
        }
        
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("manage-auctions.jsp?error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    }
%>
