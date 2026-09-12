<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    User admin = (User) session.getAttribute("user");

    String userIdStr = request.getParameter("userID");
    if (userIdStr == null) {
        response.sendRedirect("manageUsers.jsp");
        return;
    }

    int targetUserID = Integer.parseInt(userIdStr);
    String message = null;
    String error = null;

    // Handle POST actions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        
        Connection conn = null;
        try {
            conn = com.buyme.util.DatabaseConnection.getConnection();
            
            if ("cancelBid".equals(action)) {
                int bidID = Integer.parseInt(request.getParameter("bidID"));
                int auctionID = Integer.parseInt(request.getParameter("auctionID"));
                
                // Get current bid info
                PreparedStatement getBidStmt = conn.prepareStatement(
                    "SELECT buyerID, isWinning FROM bid WHERE bidID = ? AND buyerID = ?"
                );
                getBidStmt.setInt(1, bidID);
                getBidStmt.setInt(2, targetUserID);
                ResultSet bidRs = getBidStmt.executeQuery();
                
                if (bidRs.next()) {
                    boolean wasWinning = bidRs.getBoolean("isWinning");
                    
                    // Delete the bid
                    PreparedStatement delBidStmt = conn.prepareStatement(
                        "DELETE FROM bid WHERE bidID = ?"
                    );
                    delBidStmt.setInt(1, bidID);
                    delBidStmt.executeUpdate();
                    
                    // If user was winning, need to find next highest bidder
                    if (wasWinning) {
                        PreparedStatement nextBidStmt = conn.prepareStatement(
                            "SELECT bidID, buyerID, maxBidLimit FROM bid " +
                            "WHERE auctionID = ? ORDER BY maxBidLimit DESC LIMIT 1"
                        );
                        nextBidStmt.setInt(1, auctionID);
                        ResultSet nextRs = nextBidStmt.executeQuery();
                        
                        if (nextRs.next()) {
                            int newWinnerID = nextRs.getInt("buyerID");
                            double newMaxBid = nextRs.getDouble("maxBidLimit");
                            
                            // Get auction details
                            PreparedStatement auctionStmt = conn.prepareStatement(
                                "SELECT bidIncrement, initialPrice FROM auction WHERE auctionID = ?"
                            );
                            auctionStmt.setInt(1, auctionID);
                            ResultSet auctionRs = auctionStmt.executeQuery();
                            
                            if (auctionRs.next()) {
                                double bidIncrement = auctionRs.getDouble("bidIncrement");
                                double initialPrice = auctionRs.getDouble("initialPrice");
                                
                                // Check for second highest bid
                                PreparedStatement secondBidStmt = conn.prepareStatement(
                                    "SELECT maxBidLimit FROM bid " +
                                    "WHERE auctionID = ? AND buyerID != ? " +
                                    "ORDER BY maxBidLimit DESC LIMIT 1"
                                );
                                secondBidStmt.setInt(1, auctionID);
                                secondBidStmt.setInt(2, newWinnerID);
                                ResultSet secondRs = secondBidStmt.executeQuery();
                                
                                double newPrice;
                                if (secondRs.next()) {
                                    double secondMax = secondRs.getDouble("maxBidLimit");
                                    newPrice = Math.min(secondMax + bidIncrement, newMaxBid);
                                } else {
                                    newPrice = initialPrice + bidIncrement;
                                }
                                
                                // Update new winner
                                PreparedStatement updateWinnerStmt = conn.prepareStatement(
                                    "UPDATE bid SET bidAmount = ?, isWinning = TRUE WHERE buyerID = ? AND auctionID = ?"
                                );
                                updateWinnerStmt.setDouble(1, newPrice);
                                updateWinnerStmt.setInt(2, newWinnerID);
                                updateWinnerStmt.setInt(3, auctionID);
                                updateWinnerStmt.executeUpdate();
                                
                                // Update auction
                                PreparedStatement updateAuctionStmt = conn.prepareStatement(
                                    "UPDATE auction SET currentPrice = ?, winnerID = ? WHERE auctionID = ?"
                                );
                                updateAuctionStmt.setDouble(1, newPrice);
                                updateAuctionStmt.setInt(2, newWinnerID);
                                updateAuctionStmt.setInt(3, auctionID);
                                updateAuctionStmt.executeUpdate();
                            }
                        } else {
                            // No other bids, reset to initial price
                            PreparedStatement resetStmt = conn.prepareStatement(
                                "UPDATE auction SET currentPrice = initialPrice, winnerID = NULL WHERE auctionID = ?"
                            );
                            resetStmt.setInt(1, auctionID);
                            resetStmt.executeUpdate();
                        }
                    }
                    
                    message = "Bid cancelled successfully.";
                } else {
                    error = "Bid not found.";
                }
                
            } else if ("cancelAuction".equals(action)) {
                int auctionID = Integer.parseInt(request.getParameter("auctionID"));
                
                // Update auction status
                PreparedStatement cancelStmt = conn.prepareStatement(
                    "UPDATE auction SET status = 'cancelled' WHERE auctionID = ? AND sellerID = ?"
                );
                cancelStmt.setInt(1, auctionID);
                cancelStmt.setInt(2, targetUserID);
                int rows = cancelStmt.executeUpdate();
                
                if (rows > 0) {
                    message = "Auction cancelled successfully.";
                } else {
                    error = "Auction not found.";
                }
            }
            
            conn.close();
        } catch (Exception ex) {
            ex.printStackTrace();
            error = "Error: " + ex.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>User Details - Admin Panel</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-right a {
            color: white;
            text-decoration: none;
            margin-left: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 15px;
            text-decoration: none;
            color: #667eea;
            font-weight: 500;
        }
        
        /* Profile Header */
        .profile-header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 20px;
            display: flex;
            gap: 30px;
            align-items: flex-start;
        }
        .profile-avatar {
            width: 100px;
            height: 100px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 36px;
            flex-shrink: 0;
        }
        .profile-info {
            flex-grow: 1;
        }
        .profile-info h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .profile-meta {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .meta-item {
            font-size: 14px;
        }
        .meta-label {
            color: #666;
            font-weight: 600;
            text-transform: uppercase;
            font-size: 11px;
            margin-bottom: 5px;
        }
        .meta-value {
            color: #333;
            font-size: 14px;
        }
        
        /* Badges */
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: white;
            margin-right: 5px;
        }
        .badge-end_user { background: #17a2b8; }
        .badge-customer_rep { background: #ffc107; color: #333; }
        .badge-admin { background: #dc3545; }
        .badge-suspended { background: #6c757d; }
        .badge-active { background: #28a745; }
        
        /* Stats Grid */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            text-align: center;
        }
        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #666;
            margin-top: 5px;
            font-size: 14px;
        }
        
        /* Sections */
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            margin-bottom: 20px;
        }
        .section-title {
            font-size: 20px;
            font-weight: 600;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #f0f0f0;
        }
        
        /* Tables */
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e1e1e1;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        tr:hover {
            background: #f9f9f9;
        }
        
        /* Buttons */
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 500;
            text-decoration: none;
            display: inline-block;
            transition: opacity 0.3s;
        }
        .btn:hover {
            opacity: 0.8;
        }
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        .btn-warning {
            background: #ffc107;
            color: #333;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        /* Status badges in table */
        .status-active { color: #28a745; font-weight: 600; }
        .status-closed { color: #6c757d; font-weight: 600; }
        .status-cancelled { color: #dc3545; font-weight: 600; }
        .status-winning { color: #28a745; font-weight: 600; }
        .status-outbid { color: #dc3545; font-weight: 600; }
        
        /* Alerts */
        .alert {
            padding: 12px 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
        }
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .empty-message {
            text-align: center;
            padding: 40px;
            color: #999;
        }
    </style>
</head>
<body>

<nav class="navbar">
    <div class="nav-container">
        <h2>BuyMe Admin Panel</h2>
        <div class="nav-right">
            <span>Admin: <%= admin.getUsername() %></span>
            <a href="dashboard.jsp">Dashboard</a>
            <a href="../logout">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="manageUsers.jsp" class="back-link">← Back to User Management</a>

    <% if (message != null) { %>
        <div class="alert alert-success"><%= message %></div>
    <% } %>

    <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } %>

    <%
        Connection conn = null;
        try {
            conn = com.buyme.util.DatabaseConnection.getConnection();

            // Get user details
            PreparedStatement userStmt = conn.prepareStatement(
                "SELECT u.userID, u.username, u.email, u.userType, u.createdDate, u.isSuspended, " +
                "       eu.firstName, eu.lastName, eu.address, eu.phone, eu.isAnonymous, " +
                "       cr.department, cr.repID " +
                "FROM user u " +
                "LEFT JOIN end_user eu ON u.userID = eu.userID " +
                "LEFT JOIN customer_rep cr ON u.userID = cr.userID " +
                "WHERE u.userID = ?"
            );
            userStmt.setInt(1, targetUserID);
            ResultSet userRs = userStmt.executeQuery();

            if (userRs.next()) {
                String username = userRs.getString("username");
                String email = userRs.getString("email");
                String userType = userRs.getString("userType");
                Timestamp createdDate = userRs.getTimestamp("createdDate");
                boolean isSuspended = userRs.getBoolean("isSuspended");
                String firstName = userRs.getString("firstName");
                String lastName = userRs.getString("lastName");
                String address = userRs.getString("address");
                String phone = userRs.getString("phone");
                String department = userRs.getString("department");
                
                String initials = username.substring(0, Math.min(2, username.length())).toUpperCase();
    %>

    <!-- Profile Header -->
    <div class="profile-header">
        <div class="profile-avatar"><%= initials %></div>
        <div class="profile-info">
            <h1>
                <%= username %>
                <span class="badge badge-<%= userType %>"><%= userType.replace("_", " ") %></span>
                <% if (isSuspended) { %>
                    <span class="badge badge-suspended">SUSPENDED</span>
                <% } else { %>
                    <span class="badge badge-active">ACTIVE</span>
                <% } %>
            </h1>
            <p style="color: #666; margin-bottom: 20px;"><%= email %></p>
            
            <div class="profile-meta">
                <div class="meta-item">
                    <div class="meta-label">User ID</div>
                    <div class="meta-value">#<%= targetUserID %></div>
                </div>
                <div class="meta-item">
                    <div class="meta-label">Joined</div>
                    <div class="meta-value"><%= new SimpleDateFormat("MMM dd, yyyy").format(createdDate) %></div>
                </div>
                
                <% if ("end_user".equals(userType)) { %>
                    <% if (firstName != null) { %>
                    <div class="meta-item">
                        <div class="meta-label">Full Name</div>
                        <div class="meta-value"><%= firstName %> <%= lastName != null ? lastName : "" %></div>
                    </div>
                    <% } %>
                    <% if (phone != null) { %>
                    <div class="meta-item">
                        <div class="meta-label">Phone</div>
                        <div class="meta-value"><%= phone %></div>
                    </div>
                    <% } %>
                    <% if (address != null) { %>
                    <div class="meta-item">
                        <div class="meta-label">Address</div>
                        <div class="meta-value"><%= address %></div>
                    </div>
                    <% } %>
                <% } else if ("customer_rep".equals(userType)) { %>
                    <div class="meta-item">
                        <div class="meta-label">Department</div>
                        <div class="meta-value"><%= department != null ? department : "N/A" %></div>
                    </div>
                <% } %>
            </div>
        </div>
    </div>

    <% if ("end_user".equals(userType)) { %>
        <%
            // Get statistics for end users
            PreparedStatement statsStmt = conn.prepareStatement(
                "SELECT " +
                "    (SELECT COUNT(*) FROM bid WHERE buyerID = ?) as totalBids, " +
                "    (SELECT COUNT(DISTINCT auctionID) FROM bid WHERE buyerID = ?) as auctionsParticipated, " +
                "    (SELECT COUNT(*) FROM auction WHERE sellerID = ?) as auctionsCreated, " +
                "    (SELECT COUNT(*) FROM auction WHERE winnerID = ? AND status = 'closed') as auctionsWon, " +
                "    (SELECT COUNT(*) FROM bid WHERE buyerID = ? AND isWinning = TRUE) as currentlyWinning"
            );
            statsStmt.setInt(1, targetUserID);
            statsStmt.setInt(2, targetUserID);
            statsStmt.setInt(3, targetUserID);
            statsStmt.setInt(4, targetUserID);
            statsStmt.setInt(5, targetUserID);
            ResultSet statsRs = statsStmt.executeQuery();
            
            int totalBids = 0, auctionsParticipated = 0, auctionsCreated = 0, auctionsWon = 0, currentlyWinning = 0;
            if (statsRs.next()) {
                totalBids = statsRs.getInt("totalBids");
                auctionsParticipated = statsRs.getInt("auctionsParticipated");
                auctionsCreated = statsRs.getInt("auctionsCreated");
                auctionsWon = statsRs.getInt("auctionsWon");
                currentlyWinning = statsRs.getInt("currentlyWinning");
            }
        %>
        
        <!-- Statistics -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number"><%= totalBids %></div>
                <div class="stat-label">Total Bids Placed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= auctionsParticipated %></div>
                <div class="stat-label">Auctions Participated</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= currentlyWinning %></div>
                <div class="stat-label">Currently Winning</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= auctionsWon %></div>
                <div class="stat-label">Auctions Won</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= auctionsCreated %></div>
                <div class="stat-label">Auctions Created</div>
            </div>
        </div>

        <!-- Active Bids -->
        <div class="section">
            <h2 class="section-title">Active Bids</h2>
            <table>
                <thead>
                    <tr>
                        <th>Auction</th>
                        <th>Item</th>
                        <th>Your Bid</th>
                        <th>Max Bid</th>
                        <th>Current Price</th>
                        <th>Status</th>
                        <th>Closes</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    PreparedStatement activeBidsStmt = conn.prepareStatement(
                        "SELECT b.bidID, b.auctionID, b.bidAmount, b.maxBidLimit, b.isWinning, b.bidTime, " +
                        "       a.currentPrice, a.closeDateTime, a.status, " +
                        "       i.itemName " +
                        "FROM bid b " +
                        "JOIN auction a ON b.auctionID = a.auctionID " +
                        "JOIN item i ON a.itemID = i.itemID " +
                        "WHERE b.buyerID = ? AND a.status IN ('active', 'pending') " +
                        "ORDER BY b.bidTime DESC"
                    );
                    activeBidsStmt.setInt(1, targetUserID);
                    ResultSet activeBidsRs = activeBidsStmt.executeQuery();
                    
                    boolean hasActiveBids = false;
                    while (activeBidsRs.next()) {
                        hasActiveBids = true;
                        int bidID = activeBidsRs.getInt("bidID");
                        int auctionID = activeBidsRs.getInt("auctionID");
                        double bidAmount = activeBidsRs.getDouble("bidAmount");
                        double maxBidLimit = activeBidsRs.getDouble("maxBidLimit");
                        boolean isWinning = activeBidsRs.getBoolean("isWinning");
                        double currentPrice = activeBidsRs.getDouble("currentPrice");
                        Timestamp closeDateTime = activeBidsRs.getTimestamp("closeDateTime");
                        String itemName = activeBidsRs.getString("itemName");
                %>
                <tr>
                    <td>#<%= auctionID %></td>
                    <td><strong><%= itemName %></strong></td>
                    <td>$<%= String.format("%.2f", bidAmount) %></td>
                    <td>$<%= String.format("%.2f", maxBidLimit) %></td>
                    <td>$<%= String.format("%.2f", currentPrice) %></td>
                    <td>
                        <% if (isWinning) { %>
                            <span class="status-winning">✓ WINNING</span>
                        <% } else { %>
                            <span class="status-outbid">✗ OUTBID</span>
                        <% } %>
                    </td>
                    <td><%= new SimpleDateFormat("MMM dd, HH:mm").format(closeDateTime) %></td>
                    <td>
                        <form method="post" style="display: inline;" 
                              onsubmit="return confirm('Cancel this bid? This action cannot be undone.');">
                            <input type="hidden" name="action" value="cancelBid">
                            <input type="hidden" name="bidID" value="<%= bidID %>">
                            <input type="hidden" name="auctionID" value="<%= auctionID %>">
                            <button type="submit" class="btn btn-danger">Cancel Bid</button>
                        </form>
                    </td>
                </tr>
                <%
                    }
                    if (!hasActiveBids) {
                %>
                <tr>
                    <td colspan="8" class="empty-message">No active bids</td>
                </tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>

        <!-- Bid History -->
        <div class="section">
            <h2 class="section-title">Bid History</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Auction</th>
                        <th>Item</th>
                        <th>Bid Amount</th>
                        <th>Auction Status</th>
                        <th>Result</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    PreparedStatement historyStmt = conn.prepareStatement(
                        "SELECT bh.bidTime, bh.bidAmount, bh.auctionID, " +
                        "       i.itemName, a.status, a.winnerID " +
                        "FROM bid_history bh " +
                        "JOIN auction a ON bh.auctionID = a.auctionID " +
                        "JOIN item i ON a.itemID = i.itemID " +
                        "WHERE bh.buyerID = ? " +
                        "ORDER BY bh.bidTime DESC " +
                        "LIMIT 50"
                    );
                    historyStmt.setInt(1, targetUserID);
                    ResultSet historyRs = historyStmt.executeQuery();
                    
                    boolean hasHistory = false;
                    while (historyRs.next()) {
                        hasHistory = true;
                        Timestamp bidTime = historyRs.getTimestamp("bidTime");
                        double bidAmount = historyRs.getDouble("bidAmount");
                        int auctionID = historyRs.getInt("auctionID");
                        String itemName = historyRs.getString("itemName");
                        String auctionStatus = historyRs.getString("status");
                        Integer winnerID = historyRs.getInt("winnerID");
                        
                        String result = "Active";
                        String resultClass = "status-active";
                        if ("closed".equals(auctionStatus)) {
                            if (winnerID != null && winnerID == targetUserID) {
                                result = "WON";
                                resultClass = "status-winning";
                            } else {
                                result = "LOST";
                                resultClass = "status-outbid";
                            }
                        }
                %>
                <tr>
                    <td><%= new SimpleDateFormat("MMM dd, yyyy HH:mm").format(bidTime) %></td>
                    <td>#<%= auctionID %></td>
                    <td><%= itemName %></td>
                    <td>$<%= String.format("%.2f", bidAmount) %></td>
                    <td class="status-<%= auctionStatus %>"><%= auctionStatus.toUpperCase() %></td>
                    <td class="<%= resultClass %>"><%= result %></td>
                </tr>
                <%
                    }
                    if (!hasHistory) {
                %>
                <tr>
                    <td colspan="6" class="empty-message">No bid history</td>
                </tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>

        <!-- Auctions Created by User -->
        <div class="section">
            <h2 class="section-title">Auctions Created</h2>
            <table>
                <thead>
                    <tr>
                        <th>Auction ID</th>
                        <th>Item</th>
                        <th>Current Price</th>
                        <th>Status</th>
                        <th>Closes</th>
                        <th>Bids</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    PreparedStatement auctionsStmt = conn.prepareStatement(
                        "SELECT a.auctionID, i.itemName, a.currentPrice, a.status, a.closeDateTime, " +
                        "       (SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                        "FROM auction a " +
                        "JOIN item i ON a.itemID = i.itemID " +
                        "WHERE a.sellerID = ? " +
                        "ORDER BY a.startDateTime DESC " +
                        "LIMIT 50"
                    );
                    auctionsStmt.setInt(1, targetUserID);
                    ResultSet auctionsRs = auctionsStmt.executeQuery();
                    
                    boolean hasAuctions = false;
                    while (auctionsRs.next()) {
                        hasAuctions = true;
                        int auctionID = auctionsRs.getInt("auctionID");
                        String itemName = auctionsRs.getString("itemName");
                        double currentPrice = auctionsRs.getDouble("currentPrice");
                        String auctionStatus = auctionsRs.getString("status");
                        Timestamp closeDateTime = auctionsRs.getTimestamp("closeDateTime");
                        int bidCount = auctionsRs.getInt("bidCount");
                %>
                <tr>
                    <td>#<%= auctionID %></td>
                    <td><strong><%= itemName %></strong></td>
                    <td>$<%= String.format("%.2f", currentPrice) %></td>
                    <td class="status-<%= auctionStatus %>"><%= auctionStatus.toUpperCase() %></td>
                    <td><%= new SimpleDateFormat("MMM dd, yyyy HH:mm").format(closeDateTime) %></td>
                    <td><%= bidCount %> bids</td>
                    <td>
                        <% if ("active".equals(auctionStatus) || "pending".equals(auctionStatus)) { %>
                            <form method="post" style="display: inline;" 
                                  onsubmit="return confirm('Cancel this auction? All bids will be removed.');">
                                <input type="hidden" name="action" value="cancelAuction">
                                <input type="hidden" name="auctionID" value="<%= auctionID %>">
                                <button type="submit" class="btn btn-warning">Cancel Auction</button>
                            </form>
                        <% } else { %>
                            <span style="color: #999;">-</span>
                        <% } %>
                    </td>
                </tr>
                <%
                    }
                    if (!hasAuctions) {
                %>
                <tr>
                    <td colspan="7" class="empty-message">No auctions created</td>
                </tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>

    <% } else if ("customer_rep".equals(userType)) { %>
        <%
            // Get rep statistics
            int repID = userRs.getInt("repID");
            PreparedStatement repStatsStmt = conn.prepareStatement(
                "SELECT " +
                "    COUNT(*) as totalQuestions, " +
                "    SUM(CASE WHEN status = 'answered' THEN 1 ELSE 0 END) as answered, " +
                "    SUM(CASE WHEN status = 'open' THEN 1 ELSE 0 END) as open " +
                "FROM question " +
                "WHERE repID = ?"
            );
            repStatsStmt.setInt(1, repID);
            ResultSet repStatsRs = repStatsStmt.executeQuery();
            
            int totalQuestions = 0, answered = 0, open = 0;
            if (repStatsRs.next()) {
                totalQuestions = repStatsRs.getInt("totalQuestions");
                answered = repStatsRs.getInt("answered");
                open = repStatsRs.getInt("open");
            }
        %>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number"><%= totalQuestions %></div>
                <div class="stat-label">Total Questions Handled</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= answered %></div>
                <div class="stat-label">Answered</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= open %></div>
                <div class="stat-label">Open</div>
            </div>
        </div>

        <!-- Recent Questions -->
        <div class="section">
            <h2 class="section-title">Recent Questions Handled</h2>
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>User</th>
                        <th>Subject</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    PreparedStatement questionsStmt = conn.prepareStatement(
                        "SELECT q.createdTime, u.username, q.subject, q.status " +
                        "FROM question q " +
                        "JOIN user u ON q.userID = u.userID " +
                        "WHERE q.repID = ? " +
                        "ORDER BY q.createdTime DESC " +
                        "LIMIT 20"
                    );
                    questionsStmt.setInt(1, repID);
                    ResultSet questionsRs = questionsStmt.executeQuery();
                    
                    boolean hasQuestions = false;
                    while (questionsRs.next()) {
                        hasQuestions = true;
                %>
                <tr>
                    <td><%= new SimpleDateFormat("MMM dd, yyyy").format(questionsRs.getTimestamp("createdTime")) %></td>
                    <td><%= questionsRs.getString("username") %></td>
                    <td><%= questionsRs.getString("subject") != null ? questionsRs.getString("subject") : "N/A" %></td>
                    <td class="status-<%= questionsRs.getString("status") %>"><%= questionsRs.getString("status").toUpperCase() %></td>
                </tr>
                <%
                    }
                    if (!hasQuestions) {
                %>
                <tr>
                    <td colspan="4" class="empty-message">No questions handled yet</td>
                </tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    <% } %>

    <%
            } else {
    %>
        <div class="section">
            <p style="text-align: center; padding: 40px; color: #999;">User not found.</p>
        </div>
    <%
            }
            
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
    %>
        <div class="section">
            <p style="color: red;">Error loading user details: <%= e.getMessage() %></p>
        </div>
    <%
        }
    %>
</div>

</body>
</html>
