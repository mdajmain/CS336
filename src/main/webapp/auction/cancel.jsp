<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String auctionIDStr = request.getParameter("id");
    if (auctionIDStr == null) {
        response.sendRedirect("my-auctions.jsp?error=No auction specified");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("my-auctions.jsp?error=Invalid auction ID");
        return;
    }
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        // Verify ownership and check if can be cancelled
        String checkSql = "SELECT a.sellerID, a.status, i.itemName, " +
                         "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                         "FROM auction a JOIN item i ON a.itemID = i.itemID WHERE a.auctionID = ?";
        
        try (PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
            checkPs.setInt(1, auctionID);
            try (ResultSet rs = checkPs.executeQuery()) {
                if (!rs.next()) {
                    response.sendRedirect("my-auctions.jsp?error=Auction not found");
                    return;
                }
                
                int sellerID = rs.getInt("sellerID");
                String status = rs.getString("status");
                String itemName = rs.getString("itemName");
                int bidCount = rs.getInt("bidCount");
                
                // Verify ownership
                if (sellerID != user.getUserID()) {
                    response.sendRedirect("my-auctions.jsp?error=You don't have permission to cancel this auction");
                    return;
                }
                
                // Check if can be cancelled
                if ("closed".equals(status) || "cancelled".equals(status)) {
                    response.sendRedirect("my-auctions.jsp?error=This auction is already " + status);
                    return;
                }
                
                // Can only cancel if no bids (for active auctions)
                if ("active".equals(status) && bidCount > 0) {
                    response.sendRedirect("my-auctions.jsp?error=Cannot cancel an active auction with bids");
                    return;
                }
                
                // Cancel the auction
                try (PreparedStatement updatePs = conn.prepareStatement(
                    "UPDATE auction SET status = 'cancelled' WHERE auctionID = ?")) {
                    updatePs.setInt(1, auctionID);
                    updatePs.executeUpdate();
                }
                
                response.sendRedirect("my-auctions.jsp?message=" + 
                    java.net.URLEncoder.encode("Auction '" + itemName + "' has been cancelled.", "UTF-8"));
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
        response.sendRedirect("my-auctions.jsp?error=" + 
            java.net.URLEncoder.encode("Error cancelling auction: " + e.getMessage(), "UTF-8"));
    }
%>
