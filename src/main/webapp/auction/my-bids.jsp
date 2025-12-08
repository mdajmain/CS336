<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    if (user == null || !"end_user".equalsIgnoreCase(userType)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String filter = request.getParameter("filter");
    if (filter == null) filter = "all";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Bids - BuyMe</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; min-height: 100vh; }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
        }
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-container a { color: white; text-decoration: none; }
        
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        
        .page-header {
            margin-bottom: 20px;
        }
        .page-header h1 { color: #333; }
        
        .filters {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .filter-btn {
            padding: 8px 16px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 20px;
            text-decoration: none;
            transition: all 0.3s;
        }
        .filter-btn:hover, .filter-btn.active {
            background: #667eea;
            color: white;
        }
        
        .stats-row {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .stat-card .number {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-card .label {
            color: #666;
            font-size: 13px;
        }
        .stat-card.winning .number { color: #27ae60; }
        .stat-card.lost .number { color: #e74c3c; }
        
        .bids-list {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }
        
        .bid-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            display: flex;
        }
        
        .bid-card .status-bar {
            width: 5px;
        }
        .status-bar.winning { background: #27ae60; }
        .status-bar.outbid { background: #e74c3c; }
        .status-bar.won { background: #17a2b8; }
        .status-bar.lost { background: #6c757d; }
        
        .bid-card .content {
            flex: 1;
            padding: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .bid-card .item-info h3 {
            color: #333;
            margin-bottom: 5px;
        }
        .bid-card .item-info p {
            color: #666;
            font-size: 13px;
        }
        
        .bid-card .bid-info {
            text-align: right;
        }
        .bid-card .your-bid {
            font-size: 12px;
            color: #666;
        }
        .bid-card .bid-amount {
            font-size: 24px;
            font-weight: bold;
            color: #333;
        }
        .bid-card .max-bid {
            font-size: 12px;
            color: #999;
        }
        
        .bid-card .current-price {
            text-align: center;
            padding: 10px 20px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        .bid-card .current-price label {
            display: block;
            font-size: 11px;
            color: #666;
        }
        .bid-card .current-price span {
            font-size: 18px;
            font-weight: bold;
            color: #27ae60;
        }
        
        .bid-card .status-info {
            text-align: center;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge-winning { background: #d4edda; color: #155724; }
        .badge-outbid { background: #f8d7da; color: #721c24; }
        .badge-won { background: #cce5ff; color: #004085; }
        .badge-lost { background: #e2e3e5; color: #383d41; }
        
        .bid-card .time-info {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        
        .bid-card .actions {
            display: flex;
            gap: 10px;
        }
        .action-btn {
            padding: 8px 15px;
            border-radius: 5px;
            text-decoration: none;
            font-size: 13px;
        }
        .btn-view { background: #667eea; color: white; }
        .btn-bid { background: #27ae60; color: white; }
        
        .no-bids {
            background: white;
            padding: 50px;
            text-align: center;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .no-bids h3 { color: #333; margin-bottom: 10px; }
        .no-bids p { color: #666; margin-bottom: 20px; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div>
                <a href="<%= request.getContextPath() %>/dashboard.jsp" style="margin-right: 20px;">Dashboard</a>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="<%= request.getContextPath() %>/logout" style="margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="page-header">
            <h1>My Bids</h1>
        </div>
        
        <%
            // Get stats
            int totalBids = 0, winningBids = 0, wonAuctions = 0, lostAuctions = 0;
            
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Total active bids
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bid WHERE buyerID = ?")) {
                    ps.setInt(1, user.getUserID());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) totalBids = rs.getInt(1);
                    }
                }
                
                // Currently winning
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bid b JOIN auction a ON b.auctionID = a.auctionID " +
                    "WHERE b.buyerID = ? AND b.isWinning = TRUE AND a.status = 'active'")) {
                    ps.setInt(1, user.getUserID());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) winningBids = rs.getInt(1);
                    }
                }
                
                // Won auctions
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM auction WHERE winnerID = ? AND status = 'closed'")) {
                    ps.setInt(1, user.getUserID());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) wonAuctions = rs.getInt(1);
                    }
                }
                
                // Lost auctions (participated but didn't win)
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(DISTINCT b.auctionID) FROM bid b " +
                    "JOIN auction a ON b.auctionID = a.auctionID " +
                    "WHERE b.buyerID = ? AND a.status = 'closed' AND (a.winnerID IS NULL OR a.winnerID != ?)")) {
                    ps.setInt(1, user.getUserID());
                    ps.setInt(2, user.getUserID());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) lostAuctions = rs.getInt(1);
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
        
        <div class="stats-row">
            <div class="stat-card">
                <div class="number"><%= totalBids %></div>
                <div class="label">Active Bids</div>
            </div>
            <div class="stat-card winning">
                <div class="number"><%= winningBids %></div>
                <div class="label">Currently Winning</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= wonAuctions %></div>
                <div class="label">Auctions Won</div>
            </div>
            <div class="stat-card lost">
                <div class="number"><%= lostAuctions %></div>
                <div class="label">Auctions Lost</div>
            </div>
        </div>
        
        <div class="filters">
            <a href="my-bids.jsp?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All Bids</a>
            <a href="my-bids.jsp?filter=winning" class="filter-btn <%= "winning".equals(filter) ? "active" : "" %>">Winning</a>
            <a href="my-bids.jsp?filter=outbid" class="filter-btn <%= "outbid".equals(filter) ? "active" : "" %>">Outbid</a>
            <a href="my-bids.jsp?filter=won" class="filter-btn <%= "won".equals(filter) ? "active" : "" %>">Won</a>
            <a href="my-bids.jsp?filter=lost" class="filter-btn <%= "lost".equals(filter) ? "active" : "" %>">Lost</a>
        </div>
        
        <div class="bids-list">
            <%
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    StringBuilder sql = new StringBuilder();
                    sql.append("SELECT b.*, a.currentPrice, a.closeDateTime, a.status as auctionStatus, ");
                    sql.append("a.winnerID, i.itemName, c.categoryName ");
                    sql.append("FROM bid b ");
                    sql.append("JOIN auction a ON b.auctionID = a.auctionID ");
                    sql.append("JOIN item i ON a.itemID = i.itemID ");
                    sql.append("JOIN category c ON i.categoryID = c.categoryID ");
                    sql.append("WHERE b.buyerID = ? ");
                    
                    if ("winning".equals(filter)) {
                        sql.append("AND b.isWinning = TRUE AND a.status = 'active' ");
                    } else if ("outbid".equals(filter)) {
                        sql.append("AND b.isWinning = FALSE AND a.status = 'active' ");
                    } else if ("won".equals(filter)) {
                        sql.append("AND a.status = 'closed' AND a.winnerID = ? ");
                    } else if ("lost".equals(filter)) {
                        sql.append("AND a.status = 'closed' AND (a.winnerID IS NULL OR a.winnerID != ?) ");
                    }
                    
                    sql.append("ORDER BY b.bidTime DESC");
                    
                    try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                        int paramIdx = 1;
                        ps.setInt(paramIdx++, user.getUserID());
                        
                        if ("won".equals(filter) || "lost".equals(filter)) {
                            ps.setInt(paramIdx++, user.getUserID());
                        }
                        
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean hasBids = false;
                            
                            while (rs.next()) {
                                hasBids = true;
                                int auctionID = rs.getInt("auctionID");
                                String itemName = rs.getString("itemName");
                                String categoryName = rs.getString("categoryName");
                                double bidAmount = rs.getDouble("bidAmount");
                                double maxBidLimit = rs.getDouble("maxBidLimit");
                                double currentPrice = rs.getDouble("currentPrice");
                                Timestamp bidTime = rs.getTimestamp("bidTime");
                                Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                                String auctionStatus = rs.getString("auctionStatus");
                                boolean isWinning = rs.getBoolean("isWinning");
                                Integer winnerID = rs.getObject("winnerID") != null ? rs.getInt("winnerID") : null;
                                
                                String bidStatus;
                                String statusClass;
                                String badgeClass;
                                
                                if ("closed".equals(auctionStatus)) {
                                    if (winnerID != null && winnerID == user.getUserID()) {
                                        bidStatus = "WON";
                                        statusClass = "won";
                                        badgeClass = "badge-won";
                                    } else {
                                        bidStatus = "LOST";
                                        statusClass = "lost";
                                        badgeClass = "badge-lost";
                                    }
                                } else if (isWinning) {
                                    bidStatus = "WINNING";
                                    statusClass = "winning";
                                    badgeClass = "badge-winning";
                                } else {
                                    bidStatus = "OUTBID";
                                    statusClass = "outbid";
                                    badgeClass = "badge-outbid";
                                }
                                
                                long timeLeft = closeDateTime.getTime() - System.currentTimeMillis();
                                String timeLeftStr;
                                if (timeLeft <= 0 || "closed".equals(auctionStatus)) {
                                    timeLeftStr = "Ended";
                                } else {
                                    long days = timeLeft / (1000 * 60 * 60 * 24);
                                    long hours = (timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60);
                                    timeLeftStr = days > 0 ? days + "d " + hours + "h left" : hours + "h left";
                                }
            %>
                <div class="bid-card">
                    <div class="status-bar <%= statusClass %>"></div>
                    <div class="content">
                        <div class="item-info">
                            <h3><%= itemName %></h3>
                            <p><%= categoryName %> | Auction #<%= auctionID %></p>
                        </div>
                        
                        <div class="bid-info">
                            <div class="your-bid">Your Bid</div>
                            <div class="bid-amount">$<%= String.format("%.2f", bidAmount) %></div>
                            <div class="max-bid">Max: $<%= String.format("%.2f", maxBidLimit) %></div>
                        </div>
                        
                        <div class="current-price">
                            <label>Current Price</label>
                            <span>$<%= String.format("%.2f", currentPrice) %></span>
                        </div>
                        
                        <div class="status-info">
                            <span class="status-badge <%= badgeClass %>"><%= bidStatus %></span>
                            <div class="time-info"><%= timeLeftStr %></div>
                        </div>
                        
                        <div class="actions">
                            <a href="view.jsp?id=<%= auctionID %>" class="action-btn btn-view">View</a>
                            <% if ("active".equals(auctionStatus) && !isWinning) { %>
                                <a href="view.jsp?id=<%= auctionID %>#bid" class="action-btn btn-bid">Bid Again</a>
                            <% } %>
                        </div>
                    </div>
                </div>
            <%
                            }
                            
                            if (!hasBids) {
            %>
                <div class="no-bids">
                    <h3>No Bids Found</h3>
                    <p>
                        <% if (!"all".equals(filter)) { %>
                            You don't have any <%= filter %> bids.
                        <% } else { %>
                            You haven't placed any bids yet.
                        <% } %>
                    </p>
                    <a href="<%= request.getContextPath() %>/browse.jsp" class="action-btn btn-view">Browse Auctions</a>
                </div>
            <%
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
            %>
                <div class="no-bids">
                    <h3>Error</h3>
                    <p>Error loading bids: <%= e.getMessage() %></p>
                </div>
            <%
                }
            %>
        </div>
    </div>
</body>
</html>
