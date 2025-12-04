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

    String message = null;
    String error = null;

    // HANDLE DELETE BID (POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String bidIdStr = request.getParameter("bidID");
        String auctionIdStr = request.getParameter("auctionID");

        if ("delete".equalsIgnoreCase(action) && bidIdStr != null && auctionIdStr != null) {
            try {
                int bidID = Integer.parseInt(bidIdStr);
                int auctionID = Integer.parseInt(auctionIdStr);

                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    conn.setAutoCommit(false);

                    try {
                        // Get bidder info before deleting
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
                        try (PreparedStatement delBid = conn.prepareStatement(
                            "DELETE FROM bid WHERE bidID = ?")) {
                            delBid.setInt(1, bidID);
                            delBid.executeUpdate();
                        }

                        // Recalc top bid
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
                                    
                                    // Update isWinning flag
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
                        
                        // Notify the bidder
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
                    } catch (Exception inner) {
                        conn.rollback();
                        throw inner;
                    } finally {
                        conn.setAutoCommit(true);
                    }
                }

            } catch (NumberFormatException nfe) {
                error = "Invalid bid or auction ID.";
            } catch (Exception e) {
                e.printStackTrace();
                error = "Error removing bid: " + e.getMessage();
            }
        }
    }

    // FILTER AUCTION ID (GET)
    String filterAuction = request.getParameter("auctionID");
    if (filterAuction == null) filterAuction = "";
    
    String filterUser = request.getParameter("userID");
    if (filterUser == null) filterUser = "";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Bids - Customer Rep</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px 0; color: white; }
        .nav-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .back-link { text-decoration: none; color: #667eea; display: inline-block; margin-bottom: 15px; }
        .section { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .alert { padding: 10px; border-radius: 5px; margin-bottom: 10px; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px; border-bottom: 1px solid #e1e1e1; text-align: left; }
        th { background: #f8f9fa; }
        .filter-form { margin-bottom: 15px; display: flex; gap: 10px; align-items: center; flex-wrap: wrap; }
        .filter-form input { padding: 8px 12px; border: 2px solid #ddd; border-radius: 5px; }
        .filter-form input:focus { border-color: #667eea; outline: none; }
        .btn { padding: 8px 16px; border-radius: 5px; border: none; cursor: pointer; font-size: 13px; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-danger:hover { background: #c82333; }
        .btn-filter { background: #667eea; color: white; }
        .btn-filter:hover { background: #5a6fd6; }
        .clear-link { color: #667eea; text-decoration: none; font-size: 13px; }
        .winning-badge { background: #28a745; color: white; padding: 2px 8px; border-radius: 10px; font-size: 11px; }
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
    <a href="dashboard.jsp" class="back-link">← Back to Dashboard</a>

    <div class="section">
        <h2>Manage Bids</h2>
        <p>Search bids by auction ID or user ID and remove inappropriate ones.</p>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <form method="get" class="filter-form">
            <label for="auctionID">Auction ID:</label>
            <input type="number" id="auctionID" name="auctionID" value="<%= filterAuction %>" placeholder="Enter auction ID">
            <label for="userID">User ID:</label>
            <input type="number" id="userID" name="userID" value="<%= filterUser %>" placeholder="Enter user ID">
            <button type="submit" class="btn btn-filter">Filter</button>
            <a href="manage-bids.jsp" class="clear-link">Clear</a>
        </form>

        <table>
            <thead>
            <tr>
                <th>Bid ID</th>
                <th>Auction</th>
                <th>Item</th>
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
                boolean hasFilter = !filterAuction.isEmpty() || !filterUser.isEmpty();
                
                if (hasFilter) {
                    try {
                        StringBuilder sql = new StringBuilder();
                        sql.append("SELECT b.*, u.username, i.itemName, a.status as auctionStatus ");
                        sql.append("FROM bid b ");
                        sql.append("JOIN user u ON b.buyerID = u.userID ");
                        sql.append("JOIN auction a ON b.auctionID = a.auctionID ");
                        sql.append("JOIN item i ON a.itemID = i.itemID ");
                        sql.append("WHERE 1=1 ");
                        
                        if (!filterAuction.isEmpty()) {
                            sql.append("AND b.auctionID = ? ");
                        }
                        if (!filterUser.isEmpty()) {
                            sql.append("AND b.buyerID = ? ");
                        }
                        sql.append("ORDER BY b.bidTime DESC");

                        try (
                            Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                            PreparedStatement ps = conn.prepareStatement(sql.toString())
                        ) {
                            int paramIndex = 1;
                            if (!filterAuction.isEmpty()) {
                                ps.setInt(paramIndex++, Integer.parseInt(filterAuction));
                            }
                            if (!filterUser.isEmpty()) {
                                ps.setInt(paramIndex++, Integer.parseInt(filterUser));
                            }

                            try (ResultSet rs = ps.executeQuery()) {
                                boolean any = false;

                                while (rs.next()) {
                                    any = true;
                                    int bidID = rs.getInt("bidID");
                                    int auctionID = rs.getInt("auctionID");
                                    String itemName = rs.getString("itemName");
                                    String username = rs.getString("username");
                                    double bidAmount = rs.getDouble("bidAmount");
                                    double maxBidLimit = rs.getDouble("maxBidLimit");
                                    Timestamp bidTime = rs.getTimestamp("bidTime");
                                    boolean isWinning = rs.getBoolean("isWinning");
                                    String auctionStatus = rs.getString("auctionStatus");
            %>
            <tr>
                <td>#<%= bidID %></td>
                <td><a href="<%= request.getContextPath() %>/auction/view.jsp?id=<%= auctionID %>" target="_blank">#<%= auctionID %></a></td>
                <td><%= itemName %></td>
                <td><%= username %> (ID: <%= rs.getInt("buyerID") %>)</td>
                <td class="price">$<%= String.format("%.2f", bidAmount) %> <% if (isWinning) { %><span class="winning-badge">WINNING</span><% } %></td>
                <td>$<%= String.format("%.2f", maxBidLimit) %></td>
                <td><%= bidTime %></td>
                <td><%= auctionStatus %></td>
                <td>
                    <% if ("active".equals(auctionStatus)) { %>
                    <form method="post" style="display: inline;"
                          onsubmit="return confirm('Delete bid #<%= bidID %>? This will recalculate the auction price.');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="bidID" value="<%= bidID %>">
                        <input type="hidden" name="auctionID" value="<%= auctionID %>">
                        <button type="submit" class="btn btn-danger">Delete</button>
                    </form>
                    <% } else { %>
                    <span style="color: #999;">Auction <%= auctionStatus %></span>
                    <% } %>
                </td>
            </tr>
            <%
                                }

                                if (!any) {
            %>
            <tr>
                <td colspan="9" style="text-align:center; color:#999; padding: 20px;">
                    No bids found matching your criteria.
                </td>
            </tr>
            <%
                                }
                            }
                        }

                    } catch (NumberFormatException nfe) {
            %>
            <tr>
                <td colspan="9" style="color:red; text-align:center; padding: 20px;">
                    Invalid ID format.
                </td>
            </tr>
            <%
                    } catch (Exception e) {
                        e.printStackTrace();
            %>
            <tr>
                <td colspan="9" style="color:red;">Error loading bids: <%= e.getMessage() %></td>
            </tr>
            <%
                    }

                } else {
            %>
            <tr>
                <td colspan="9" style="text-align:center; color:#999; padding: 20px;">
                    Enter an auction ID or user ID above to see bids.
                </td>
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
