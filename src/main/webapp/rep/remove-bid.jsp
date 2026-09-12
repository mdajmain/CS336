<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>
<%
    User user = (User) session.getAttribute("user");
    
    String bidIDStr = request.getParameter("bidID");
    String auctionIDStr = request.getParameter("auctionID");
    String reason = request.getParameter("reason");
    
    if (bidIDStr == null || auctionIDStr == null || reason == null || reason.trim().isEmpty()) {
        response.sendRedirect("manage-bids.jsp?error=Invalid request. All fields are required.");
        return;
    }
    
    int bidID, auctionID;
    try {
        bidID = Integer.parseInt(bidIDStr);
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("manage-bids.jsp?error=Invalid ID format");
        return;
    }
    
    Connection conn = null;
    try {
        conn = DatabaseConnection.getConnection();
        conn.setAutoCommit(false);
        
        // Get bid details
        PreparedStatement getBid = conn.prepareStatement(
            "SELECT b.buyerID, b.bidAmount, b.isWinning, a.currentPrice, a.bidIncrement, i.itemName " +
            "FROM bid b JOIN auction a ON b.auctionID = a.auctionID JOIN item i ON a.itemID = i.itemID " +
            "WHERE b.bidID = ?");
        getBid.setInt(1, bidID);
        ResultSet rs = getBid.executeQuery();
        
        if (!rs.next()) {
            response.sendRedirect("manage-bids.jsp?error=Bid not found");
            return;
        }
        
        int buyerID = rs.getInt("buyerID");
        double bidAmount = rs.getDouble("bidAmount");
        boolean wasWinning = rs.getBoolean("isWinning");
        double currentPrice = rs.getDouble("currentPrice");
        double bidIncrement = rs.getDouble("bidIncrement");
        String itemName = rs.getString("itemName");
        
        // Delete the bid
        PreparedStatement deleteBid = conn.prepareStatement("DELETE FROM bid WHERE bidID = ?");
        deleteBid.setInt(1, bidID);
        deleteBid.executeUpdate();
        
        // If this was the winning bid, we need to update the auction
        if (wasWinning) {
            // Find the next highest bid
            PreparedStatement getNextBid = conn.prepareStatement(
                "SELECT bidID, buyerID, maxBidLimit FROM bid WHERE auctionID = ? ORDER BY maxBidLimit DESC LIMIT 1");
            getNextBid.setInt(1, auctionID);
            ResultSet nextBidRs = getNextBid.executeQuery();
            
            if (nextBidRs.next()) {
                // Make the next bid the winning one
                int nextBidID = nextBidRs.getInt("bidID");
                int nextBuyerID = nextBidRs.getInt("buyerID");
                double nextMaxLimit = nextBidRs.getDouble("maxBidLimit");
                
                // Recalculate what the price should be
                // It should be the initial price + increment or the second highest max bid + increment
                PreparedStatement getSecondBid = conn.prepareStatement(
                    "SELECT maxBidLimit FROM bid WHERE auctionID = ? ORDER BY maxBidLimit DESC LIMIT 1 OFFSET 1");
                getSecondBid.setInt(1, auctionID);
                ResultSet secondBidRs = getSecondBid.executeQuery();
                
                double newPrice;
                if (secondBidRs.next()) {
                    double secondMax = secondBidRs.getDouble("maxBidLimit");
                    newPrice = Math.min(secondMax + bidIncrement, nextMaxLimit);
                } else {
                    // Only one bid left, set to their bidAmount or a reasonable starting point
                    PreparedStatement getInitial = conn.prepareStatement(
                        "SELECT initialPrice FROM auction WHERE auctionID = ?");
                    getInitial.setInt(1, auctionID);
                    ResultSet initRs = getInitial.executeQuery();
                    initRs.next();
                    newPrice = initRs.getDouble("initialPrice") + bidIncrement;
                }
                
                // Update the next bid to be winning
                PreparedStatement updateNextBid = conn.prepareStatement(
                    "UPDATE bid SET isWinning = TRUE, bidAmount = ? WHERE bidID = ?");
                updateNextBid.setDouble(1, newPrice);
                updateNextBid.setInt(2, nextBidID);
                updateNextBid.executeUpdate();
                
                // Update auction
                PreparedStatement updateAuction = conn.prepareStatement(
                    "UPDATE auction SET currentPrice = ?, winnerID = ? WHERE auctionID = ?");
                updateAuction.setDouble(1, newPrice);
                updateAuction.setInt(2, nextBuyerID);
                updateAuction.setInt(3, auctionID);
                updateAuction.executeUpdate();
                
            } else {
                // No more bids, reset auction to initial state
                PreparedStatement resetAuction = conn.prepareStatement(
                    "UPDATE auction SET currentPrice = initialPrice, winnerID = NULL WHERE auctionID = ?");
                resetAuction.setInt(1, auctionID);
                resetAuction.executeUpdate();
            }
        }
        
        // Notify the bidder
        PreparedStatement notifyBidder = conn.prepareStatement(
            "INSERT INTO notification (userID, message, type, relatedAuctionID, isRead, createdTime) VALUES (?, ?, 'outbid', ?, FALSE, NOW())");
        notifyBidder.setInt(1, buyerID);
        notifyBidder.setString(2, "Your bid of $" + String.format("%.2f", bidAmount) + " on '" + itemName + "' has been removed by customer support. Reason: " + reason);
        notifyBidder.setInt(3, auctionID);
        notifyBidder.executeUpdate();
        
        conn.commit();
        
        response.sendRedirect("manage-bids.jsp?message=" + java.net.URLEncoder.encode("Bid #" + bidID + " has been removed successfully.", "UTF-8"));
        
    } catch (Exception e) {
        if (conn != null) {
            try { conn.rollback(); } catch (SQLException ex) {}
        }
        e.printStackTrace();
        response.sendRedirect("manage-bids.jsp?error=" + java.net.URLEncoder.encode("Error: " + e.getMessage(), "UTF-8"));
    } finally {
        if (conn != null) {
            try { 
                conn.setAutoCommit(true);
                conn.close(); 
            } catch (SQLException e) {}
        }
    }
%>
