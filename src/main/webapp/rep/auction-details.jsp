<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");

    String auctionIdStr = request.getParameter("id");
    if (auctionIdStr == null) {
        response.sendRedirect("manage-auctions.jsp");
        return;
    }

    int auctionID = Integer.parseInt(auctionIdStr);
    String message = null;
    String error = null;

    // Handle delete bid
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        if ("deleteBid".equals(action)) {
            String bidIdStr = request.getParameter("bidID");
            try {
                int bidID = Integer.parseInt(bidIdStr);
                
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    conn.setAutoCommit(false);
                    
                    // Get bidder info
                    int bidderID = 0;
                    double bidAmount = 0;
                    String itemName = "";
                    
                    try (PreparedStatement getBidInfo = conn.prepareStatement(
                        "SELECT b.buyerID, b.bidAmount, i.itemName FROM bid b " +
                        "JOIN auction a ON b.auctionID = a.auctionID " +
                        "JOIN item i ON a.itemID = i.itemID WHERE b.bidID = ?")) {
                        getBidInfo.setInt(1, bidID);
                        try (ResultSet bidRs = getBidInfo.executeQuery()) {
                            if (bidRs.next()) {
                                bidderID = bidRs.getInt("buyerID");
                                bidAmount = bidRs.getDouble("bidAmount");
                                itemName = bidRs.getString("itemName");
                            }
                        }
                    }
                    
                    // Delete bid
                    try (PreparedStatement delBid = conn.prepareStatement("DELETE FROM bid WHERE bidID = ?")) {
                        delBid.setInt(1, bidID);
                        delBid.executeUpdate();
                    }
                    
                    // Recalculate top bid
                    try (PreparedStatement topBidStmt = conn.prepareStatement(
                        "SELECT buyerID, bidAmount FROM bid WHERE auctionID = ? ORDER BY bidAmount DESC LIMIT 1")) {
                        topBidStmt.setInt(1, auctionID);
                        try (ResultSet topRs = topBidStmt.executeQuery()) {
                            if (topRs.next()) {
                                int winnerID = topRs.getInt("buyerID");
                                double price = topRs.getDouble("bidAmount");
                                
                                try (PreparedStatement updAuction = conn.prepareStatement(
                                    "UPDATE auction SET winnerID = ?, currentPrice = ? WHERE auctionID = ?")) {
                                    updAuction.setInt(1, winnerID);
                                    updAuction.setDouble(2, price);
                                    updAuction.setInt(3, auctionID);
                                    updAuction.executeUpdate();
                                }
                                
                                // Update isWinning flags
                                try (PreparedStatement resetWinning = conn.prepareStatement(
                                    "UPDATE bid SET isWinning = FALSE WHERE auctionID = ?")) {
                                    resetWinning.setInt(1, auctionID);
                                    resetWinning.executeUpdate();
                                }
                                try (PreparedStatement setWinning = conn.prepareStatement(
                                    "UPDATE bid SET isWinning = TRUE WHERE auctionID = ? AND buyerID = ?")) {
                                    setWinning.setInt(1, auctionID);
                                    setWinning.setInt(2, winnerID);
                                    setWinning.executeUpdate();
                                }
                            } else {
                                // No bids left
                                try (PreparedStatement resetAuction = conn.prepareStatement(
                                    "UPDATE auction SET winnerID = NULL, currentPrice = initialPrice WHERE auctionID = ?")) {
                                    resetAuction.setInt(1, auctionID);
                                    resetAuction.executeUpdate();
                                }
                            }
                        }
                    }
                    
                    // Notify bidder
                    if (bidderID > 0) {
                        try (PreparedStatement notifyBidder = conn.prepareStatement(
                            "INSERT INTO notification (userID, message, type, relatedAuctionID, isRead, createdTime) VALUES (?, ?, 'outbid', ?, FALSE, NOW())")) {
                            notifyBidder.setInt(1, bidderID);
                            notifyBidder.setString(2, "Your bid of $" + String.format("%.2f", bidAmount) + " on '" + itemName + "' has been removed by customer support.");
                            notifyBidder.setInt(3, auctionID);
                            notifyBidder.executeUpdate();
                        }
                    }
                    
                    conn.commit();
                    message = "Bid #" + bidID + " removed successfully.";
                } catch (Exception e) {
                    error = "Error removing bid: " + e.getMessage();
                    e.printStackTrace();
                }
            } catch (NumberFormatException nfe) {
                error = "Invalid bid ID.";
            }
        } else if ("deleteAuction".equals(action)) {
            try {
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    conn.setAutoCommit(false);
                    
                    // Delete all bids first
                    try (PreparedStatement delBids = conn.prepareStatement("DELETE FROM bid WHERE auctionID = ?")) {
                        delBids.setInt(1, auctionID);
                        delBids.executeUpdate();
                    }
                    
                    // Delete auction
                    try (PreparedStatement delAuction = conn.prepareStatement("DELETE FROM auction WHERE auctionID = ?")) {
                        delAuction.setInt(1, auctionID);
                        delAuction.executeUpdate();
                    }
                    
                    conn.commit();
                    response.sendRedirect("manage-auctions.jsp?message=Auction deleted successfully");
                    return;
                }
            } catch (Exception e) {
                error = "Error deleting auction: " + e.getMessage();
                e.printStackTrace();
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Auction Details - Customer Rep</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px 0; color: white; }
        .nav-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .back-link { text-decoration: none; color: #667eea; display: inline-block; margin-bottom: 15px; }
        .section { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; }
        
        .alert { padding: 10px; border-radius: 5px; margin-bottom: 10px; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        
        .auction-header { border-bottom: 2px solid #e1e1e1; padding-bottom: 15px; margin-bottom: 20px; }
        .auction-title { font-size: 24px; font-weight: 600; color: #333; margin-bottom: 5px; }
        .auction-id { color: #666; font-size: 14px; }
        
        .detail-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; margin-bottom: 20px; }
        .detail-item { padding: 12px; background: #f8f9fa; border-radius: 6px; }
        .detail-label { font-size: 12px; color: #666; margin-bottom: 4px; }
        .detail-value { font-size: 16px; font-weight: 500; color: #333; }
        
        .status-badge { padding: 4px 12px; border-radius: 12px; font-size: 13px; font-weight: 500; }
        .status-active { background: #d4edda; color: #155724; }
        .status-closed { background: #f8d7da; color: #721c24; }
        
        .action-buttons { display: flex; gap: 10px; margin-top: 15px; }
        .btn { padding: 10px 20px; border-radius: 5px; border: none; cursor: pointer; font-size: 14px; text-decoration: none; display: inline-block; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-danger:hover { background: #c82333; }
        .btn-secondary { background: #6c757d; color: white; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px; border-bottom: 1px solid #e1e1e1; text-align: left; }
        th { background: #f8f9fa; font-weight: 600; }
        tr:hover { background: #f8f9fa; }
        
        .winning-badge { background: #28a745; color: white; padding: 3px 10px; border-radius: 10px; font-size: 11px; font-weight: 500; }
        .price { color: #27ae60; font-weight: 600; }
    </style>
</head>
<body>
<nav class="navbar">
    <div class="nav-container">
        <h2>Customer Representative Panel</h2>
        <div>
            <span>Rep: <%= user.getUsername() %></span>
            <a href="<%= request.getContextPath() %>/logout" style="color:white; margin-left:15px;">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="manage-auctions.jsp" class="back-link">← Back to Manage Auctions</a>

    <% if (message != null) { %>
        <div class="alert alert-success"><%= message %></div>
    <% } %>
    <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } %>

    <%
        try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
            String sql = "SELECT a.*, i.itemName, i.category, i.subcategory, i.description, u.username as sellerName, " +
                        "CASE WHEN a.closingTime < NOW() THEN 'closed' ELSE 'active' END as status " +
                        "FROM auction a " +
                        "JOIN item i ON a.itemID = i.itemID " +
                        "JOIN user u ON a.sellerID = u.userID " +
                        "WHERE a.auctionID = ?";
            
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, auctionID);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        String itemName = rs.getString("itemName");
                        String category = rs.getString("category");
                        String subcategory = rs.getString("subcategory");
                        String description = rs.getString("description");
                        String sellerName = rs.getString("sellerName");
                        double initialPrice = rs.getDouble("initialPrice");
                        double currentPrice = rs.getDouble("currentPrice");
                        double reservePrice = rs.getDouble("reservePrice");
                        Timestamp closingTime = rs.getTimestamp("closingTime");
                        String status = rs.getString("status");
    %>
    
    <div class="section">
        <div class="auction-header">
            <div class="auction-title"><%= itemName %></div>
            <div class="auction-id">Auction ID: #<%= auctionID %> | Category: <%= category %> - <%= subcategory %></div>
        </div>
        
        <div class="detail-grid">
            <div class="detail-item">
                <div class="detail-label">Seller</div>
                <div class="detail-value"><%= sellerName %></div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Status</div>
                <div class="detail-value">
                    <span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span>
                </div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Initial Price</div>
                <div class="detail-value">$<%= String.format("%.2f", initialPrice) %></div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Current Price</div>
                <div class="detail-value">$<%= String.format("%.2f", currentPrice) %></div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Reserve Price</div>
                <div class="detail-value">$<%= String.format("%.2f", reservePrice) %></div>
            </div>
            <div class="detail-item">
                <div class="detail-label">Closing Time</div>
                <div class="detail-value"><%= closingTime %></div>
            </div>
        </div>
        
        <div class="detail-item" style="margin-top: 15px;">
            <div class="detail-label">Description</div>
            <div class="detail-value" style="white-space: pre-wrap;"><%= description %></div>
        </div>
        
        <div class="action-buttons">
            <form method="post" style="display: inline;" 
                  onsubmit="return confirm('Delete this entire auction? This will remove all bids and cannot be undone.');">
                <input type="hidden" name="action" value="deleteAuction">
                <button type="submit" class="btn btn-danger">Delete Auction</button>
            </form>
            <a href="<%= request.getContextPath() %>/auction/view.jsp?id=<%= auctionID %>" target="_blank" class="btn btn-secondary">View Public Page</a>
        </div>
    </div>

    <%
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
    %>
        <div class="alert alert-error">Error loading auction details: <%= e.getMessage() %></div>
    <%
        }
    %>

    <!-- BIDS SECTION -->
    <div class="section">
        <h3>Bids on This Auction</h3>
        
        <table>
            <thead>
            <tr>
                <th>Bid ID</th>
                <th>Bidder</th>
                <th>Bid Amount</th>
                <th>Max Limit</th>
                <th>Time</th>
                <th>Status</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody>
            <%
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    String bidSql = "SELECT b.*, u.username FROM bid b " +
                                   "JOIN user u ON b.buyerID = u.userID " +
                                   "WHERE b.auctionID = ? ORDER BY b.bidAmount DESC";
                    
                    try (PreparedStatement ps = conn.prepareStatement(bidSql)) {
                        ps.setInt(1, auctionID);
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean hasBids = false;
                            while (rs.next()) {
                                hasBids = true;
                                int bidID = rs.getInt("bidID");
                                String bidderName = rs.getString("username");
                                int buyerID = rs.getInt("buyerID");
                                double bidAmount = rs.getDouble("bidAmount");
                                double maxBidLimit = rs.getDouble("maxBidLimit");
                                Timestamp bidTime = rs.getTimestamp("bidTime");
                                boolean isWinning = rs.getBoolean("isWinning");
            %>
            <tr>
                <td>#<%= bidID %></td>
                <td><%= bidderName %> (ID: <%= buyerID %>)</td>
                <td class="price">$<%= String.format("%.2f", bidAmount) %> 
                    <% if (isWinning) { %><span class="winning-badge">WINNING</span><% } %>
                </td>
                <td>$<%= String.format("%.2f", maxBidLimit) %></td>
                <td><%= bidTime %></td>
                <td><%= isWinning ? "Winning" : "Outbid" %></td>
                <td>
                    <form method="post" style="display: inline;"
                          onsubmit="return confirm('Delete bid #<%= bidID %>? This will recalculate the auction.');">
                        <input type="hidden" name="action" value="deleteBid">
                        <input type="hidden" name="bidID" value="<%= bidID %>">
                        <button type="submit" class="btn btn-danger">Delete</button>
                    </form>
                </td>
            </tr>
            <%
                            }
                            
                            if (!hasBids) {
            %>
            <tr>
                <td colspan="7" style="text-align: center; color: #999; padding: 20px;">No bids placed on this auction yet.</td>
            </tr>
            <%
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
            %>
            <tr>
                <td colspan="7" style="color: red;">Error loading bids: <%= e.getMessage() %></td>
            </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>
