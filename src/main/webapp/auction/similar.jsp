<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");
    
    String auctionIDStr = request.getParameter("id");
    if (auctionIDStr == null) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=No auction specified");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=Invalid auction ID");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Similar Items - BuyMe</title>
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
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
        }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .page-header h1 { color: #333; margin-bottom: 5px; }
        .page-header p { color: #666; }
        
        .similar-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
            gap: 20px;
        }
        
        .item-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: transform 0.3s;
        }
        .item-card:hover { transform: translateY(-5px); }
        
        .item-card .header {
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        .item-card h3 {
            color: #333;
            margin-bottom: 5px;
            font-size: 16px;
        }
        .item-card .category {
            color: #666;
            font-size: 12px;
        }
        
        .item-card .body {
            padding: 20px;
        }
        .item-card .price {
            font-size: 24px;
            font-weight: bold;
            color: #27ae60;
            margin-bottom: 10px;
        }
        .item-card .info-row {
            display: flex;
            justify-content: space-between;
            font-size: 13px;
            margin-bottom: 5px;
        }
        .item-card .info-row label { color: #666; }
        .item-card .info-row span { color: #333; }
        
        .item-card .footer {
            padding: 15px 20px;
            background: #f8f9fa;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .item-card .time-left {
            font-size: 12px;
            color: #666;
        }
        .item-card .btn-view {
            background: #667eea;
            color: white;
            padding: 8px 15px;
            border-radius: 5px;
            text-decoration: none;
            font-size: 13px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 3px 10px;
            border-radius: 10px;
            font-size: 11px;
            font-weight: 600;
            margin-top: 10px;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-closed { background: #e2e3e5; color: #383d41; }
        
        .no-results {
            background: white;
            padding: 50px;
            text-align: center;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .no-results h3 { color: #333; margin-bottom: 10px; }
        .no-results p { color: #666; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div>
                <% if (user != null) { %>
                    <span>Welcome, <%= user.getUsername() %></span>
                    <a href="<%= request.getContextPath() %>/logout" style="margin-left: 20px;">Logout</a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/login">Login</a>
                <% } %>
            </div>
        </div>
    </nav>

    <div class="container">
        <a href="view.jsp?id=<%= auctionID %>" class="back-link">← Back to Auction</a>
        
        <%
            String originalItemName = "";
            int subcategoryID = 0;
            double originalPrice = 0;
            
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Get original auction info
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT i.itemName, i.subcategoryID, a.currentPrice FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID WHERE a.auctionID = ?")) {
                    ps.setInt(1, auctionID);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            originalItemName = rs.getString("itemName");
                            subcategoryID = rs.getInt("subcategoryID");
                            originalPrice = rs.getDouble("currentPrice");
                        }
                    }
                }
        %>
        
        <div class="page-header">
            <h1>Similar Items</h1>
            <p>Items similar to "<%= originalItemName %>" from the past 30 days</p>
        </div>
        
        <div class="similar-grid">
            <%
                // Find similar items (same subcategory, within 30 days, price within 50%)
                String sql = "SELECT a.*, i.itemName, c.categoryName, " +
                            "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                            "FROM auction a " +
                            "JOIN item i ON a.itemID = i.itemID " +
                            "JOIN category c ON i.subcategoryID = c.categoryID " +
                            "WHERE i.subcategoryID = ? " +
                            "AND a.auctionID != ? " +
                            "AND a.startDateTime >= DATE_SUB(NOW(), INTERVAL 30 DAY) " +
                            "AND a.currentPrice BETWEEN ? AND ? " +
                            "ORDER BY a.closeDateTime DESC " +
                            "LIMIT 20";
                
                double minPrice = originalPrice * 0.5;
                double maxPrice = originalPrice * 1.5;
                
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, subcategoryID);
                    ps.setInt(2, auctionID);
                    ps.setDouble(3, minPrice);
                    ps.setDouble(4, maxPrice);
                    
                    try (ResultSet rs = ps.executeQuery()) {
                        boolean hasResults = false;
                        
                        while (rs.next()) {
                            hasResults = true;
                            int simAuctionID = rs.getInt("auctionID");
                            String itemName = rs.getString("itemName");
                            String categoryName = rs.getString("categoryName");
                            double currentPrice = rs.getDouble("currentPrice");
                            Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                            String status = rs.getString("status");
                            int bidCount = rs.getInt("bidCount");
                            
                            long timeLeft = closeDateTime.getTime() - System.currentTimeMillis();
                            String timeLeftStr;
                            if (timeLeft <= 0 || "closed".equals(status)) {
                                timeLeftStr = "Ended";
                            } else {
                                long days = timeLeft / (1000 * 60 * 60 * 24);
                                long hours = (timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60);
                                timeLeftStr = days > 0 ? days + "d " + hours + "h left" : hours + "h left";
                            }
            %>
                <div class="item-card">
                    <div class="header">
                        <h3><%= itemName %></h3>
                        <span class="category"><%= categoryName %></span>
                    </div>
                    <div class="body">
                        <div class="price">$<%= String.format("%.2f", currentPrice) %></div>
                        <div class="info-row">
                            <label>Bids:</label>
                            <span><%= bidCount %></span>
                        </div>
                        <div class="info-row">
                            <label>Ends:</label>
                            <span><%= closeDateTime.toString().substring(0, 16) %></span>
                        </div>
                        <span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span>
                    </div>
                    <div class="footer">
                        <span class="time-left"><%= timeLeftStr %></span>
                        <a href="view.jsp?id=<%= simAuctionID %>" class="btn-view">View</a>
                    </div>
                </div>
            <%
                        }
                        
                        if (!hasResults) {
            %>
                <div class="no-results" style="grid-column: 1 / -1;">
                    <h3>No Similar Items Found</h3>
                    <p>We couldn't find any similar items from the past 30 days in the same category and price range.</p>
                    <a href="<%= request.getContextPath() %>/browse.jsp" class="btn-view" style="display: inline-block; margin-top: 15px;">Browse All Auctions</a>
                </div>
            <%
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            %>
                <div class="no-results" style="grid-column: 1 / -1;">
                    <h3>Error</h3>
                    <p>Error loading similar items: <%= e.getMessage() %></p>
                </div>
            <%
            }
            %>
        </div>
    </div>
</body>
</html>
