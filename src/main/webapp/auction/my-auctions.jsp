<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String filter = request.getParameter("filter");
    if (filter == null) filter = "all";
    
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Auctions - BuyMe</title>
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
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .page-header h1 { color: #333; }
        .btn-create {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 25px;
            border-radius: 5px;
            text-decoration: none;
            font-weight: 600;
        }
        
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
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        
        .auctions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        
        .auction-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: transform 0.3s;
        }
        .auction-card:hover { transform: translateY(-5px); }
        
        .auction-card .header {
            padding: 20px;
            border-bottom: 1px solid #eee;
        }
        .auction-card .header h3 {
            color: #333;
            margin-bottom: 5px;
            font-size: 18px;
        }
        .auction-card .category {
            color: #666;
            font-size: 13px;
        }
        
        .auction-card .body {
            padding: 20px;
        }
        .auction-card .price-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .auction-card .price-row label {
            color: #666;
            font-size: 14px;
        }
        .auction-card .price-row span {
            font-weight: 600;
            color: #333;
        }
        .auction-card .current-price {
            font-size: 24px;
            color: #27ae60;
            font-weight: bold;
            margin-bottom: 15px;
        }
        
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-pending { background: #fff3cd; color: #856404; }
        .status-closed { background: #e2e3e5; color: #383d41; }
        .status-cancelled { background: #f8d7da; color: #721c24; }
        
        .auction-card .footer {
            padding: 15px 20px;
            background: #f8f9fa;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .auction-card .time-left {
            font-size: 13px;
            color: #666;
        }
        .auction-card .actions {
            display: flex;
            gap: 10px;
        }
        .action-btn {
            padding: 6px 12px;
            border-radius: 4px;
            text-decoration: none;
            font-size: 13px;
        }
        .btn-view { background: #17a2b8; color: white; }
        .btn-edit { background: #ffc107; color: #333; }
        .btn-cancel { background: #dc3545; color: white; }
        
        .no-auctions {
            background: white;
            padding: 50px;
            text-align: center;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .no-auctions h3 { color: #333; margin-bottom: 10px; }
        .no-auctions p { color: #666; margin-bottom: 20px; }
        
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
            <h1>My Auctions</h1>
            <a href="create.jsp" class="btn-create">+ Create New Auction</a>
        </div>
        
        <%
            // Get stats
            int totalAuctions = 0, activeAuctions = 0, soldItems = 0;
            double totalEarnings = 0;
            
            com.buyme.dao.AuctionDAO statsDAO = new com.buyme.dao.AuctionDAO();
            totalAuctions = statsDAO.countAuctionsBySeller(user.getUserID());
            activeAuctions = statsDAO.countActiveAuctionsBySeller(user.getUserID());

            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Sold items and earnings
                try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*), COALESCE(SUM(finalPrice), 0) FROM sales_report WHERE sellerID = ?")) {
                    ps.setInt(1, user.getUserID());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            soldItems = rs.getInt(1);
                            totalEarnings = rs.getDouble(2);
                        }
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
        
        <div class="stats-row">
            <div class="stat-card">
                <div class="number"><%= totalAuctions %></div>
                <div class="label">Total Auctions</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= activeAuctions %></div>
                <div class="label">Active</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= soldItems %></div>
                <div class="label">Items Sold</div>
            </div>
            <div class="stat-card">
                <div class="number">$<%= String.format("%.2f", totalEarnings) %></div>
                <div class="label">Total Earnings</div>
            </div>
        </div>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <div class="filters">
            <a href="my-auctions.jsp?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All</a>
            <a href="my-auctions.jsp?filter=active" class="filter-btn <%= "active".equals(filter) ? "active" : "" %>">Active</a>
            <a href="my-auctions.jsp?filter=pending" class="filter-btn <%= "pending".equals(filter) ? "active" : "" %>">Pending</a>
            <a href="my-auctions.jsp?filter=closed" class="filter-btn <%= "closed".equals(filter) ? "active" : "" %>">Closed</a>
            <a href="my-auctions.jsp?filter=cancelled" class="filter-btn <%= "cancelled".equals(filter) ? "active" : "" %>">Cancelled</a>
        </div>
        
        <div class="auctions-grid">
            <%
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    StringBuilder sql = new StringBuilder();
                    sql.append("SELECT a.*, i.itemName, c.categoryName, ");
                    sql.append("(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount ");
                    sql.append("FROM auction a ");
                    sql.append("JOIN item i ON a.itemID = i.itemID ");
                    sql.append("JOIN category c ON i.categoryID = c.categoryID ");
                    sql.append("WHERE a.sellerID = ? ");
                    
                    if (!"all".equals(filter)) {
                        sql.append("AND a.status = ? ");
                    }
                    sql.append("ORDER BY a.startDateTime DESC");
                    
                    try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                        ps.setInt(1, user.getUserID());
                        if (!"all".equals(filter)) {
                            ps.setString(2, filter);
                        }
                        
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean hasAuctions = false;
                            
                            while (rs.next()) {
                                hasAuctions = true;
                                int auctionID = rs.getInt("auctionID");
                                String itemName = rs.getString("itemName");
                                String categoryName = rs.getString("categoryName");
                                double initialPrice = rs.getDouble("initialPrice");
                                double currentPrice = rs.getDouble("currentPrice");
                                double bidIncrement = rs.getDouble("bidIncrement");
                                Double reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
                                Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                                String status = rs.getString("status");
                                int bidCount = rs.getInt("bidCount");
                                
                                long timeLeft = closeDateTime.getTime() - System.currentTimeMillis();
                                String timeLeftStr;
                                if (timeLeft <= 0) {
                                    timeLeftStr = "Ended";
                                } else {
                                    long days = timeLeft / (1000 * 60 * 60 * 24);
                                    long hours = (timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60);
                                    if (days > 0) {
                                        timeLeftStr = days + "d " + hours + "h left";
                                    } else {
                                        long minutes = (timeLeft % (1000 * 60 * 60)) / (1000 * 60);
                                        timeLeftStr = hours + "h " + minutes + "m left";
                                    }
                                }
            %>
                <div class="auction-card">
                    <div class="header">
                        <h3><%= itemName %></h3>
                        <span class="category"><%= categoryName %></span>
                    </div>
                    <div class="body">
                        <div class="current-price">$<%= String.format("%.2f", currentPrice) %></div>
                        <div class="price-row">
                            <label>Starting Price:</label>
                            <span>$<%= String.format("%.2f", initialPrice) %></span>
                        </div>
                        <div class="price-row">
                            <label>Bid Increment:</label>
                            <span>$<%= String.format("%.2f", bidIncrement) %></span>
                        </div>
                        <% if (reservePrice != null) { %>
                        <div class="price-row">
                            <label>Reserve:</label>
                            <span>$<%= String.format("%.2f", reservePrice) %> <%= currentPrice >= reservePrice ? "(Met)" : "(Not Met)" %></span>
                        </div>
                        <% } %>
                        <div class="price-row">
                            <label>Bids:</label>
                            <span><%= bidCount %></span>
                        </div>
                        <span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span>
                    </div>
                    <div class="footer">
                        <span class="time-left"><%= timeLeftStr %></span>
                        <div class="actions">
                            <a href="view.jsp?id=<%= auctionID %>" class="action-btn btn-view">View</a>
                            <% if ("pending".equals(status) || "active".equals(status)) { %>
                                <a href="edit.jsp?id=<%= auctionID %>" class="action-btn btn-edit">Edit</a>
                            <% } %>
                            <% if ("pending".equals(status) || ("active".equals(status) && bidCount == 0)) { %>
                                <a href="cancel.jsp?id=<%= auctionID %>" class="action-btn btn-cancel" onclick="return confirm('Are you sure you want to cancel this auction?')">Cancel</a>
                            <% } %>
                        </div>
                    </div>
                </div>
            <%
                            }
                            
                            if (!hasAuctions) {
            %>
                <div class="no-auctions" style="grid-column: 1 / -1;">
                    <h3>No Auctions Found</h3>
                    <p>
                        <% if (!"all".equals(filter)) { %>
                            You don't have any <%= filter %> auctions.
                        <% } else { %>
                            You haven't created any auctions yet.
                        <% } %>
                    </p>
                    <a href="create.jsp" class="btn-create">Create Your First Auction</a>
                </div>
            <%
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
            %>
                <div class="alert alert-error" style="grid-column: 1 / -1;">Error loading auctions: <%= e.getMessage() %></div>
            <%
                }
            %>
        </div>
    </div>
</body>
</html>
