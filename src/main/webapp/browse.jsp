<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Browse Auctions - BuyMe</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 20px;
        }
        
        .logo {
            color: white;
            font-size: 24px;
            font-weight: bold;
            text-decoration: none;
        }
        
        .nav-menu {
            display: flex;
            list-style: none;
            gap: 30px;
        }
        
        .nav-menu a {
            color: white;
            text-decoration: none;
            padding: 8px 15px;
            border-radius: 5px;
        }
        
        .nav-menu a:hover {
            background: rgba(255,255,255,0.2);
        }
        
        .user-info {
            color: white;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .logout-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid white;
            padding: 8px 20px;
            border-radius: 5px;
            text-decoration: none;
        }
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .search-section {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .search-form {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .search-form input, .search-form select {
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            flex: 1;
            min-width: 200px;
        }
        
        .search-btn {
            padding: 10px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        
        .auctions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 20px;
        }
        
        .auction-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: transform 0.3s;
        }
        
        .auction-card:hover {
            transform: translateY(-5px);
        }
        
        .auction-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
        }
        
        .auction-body {
            padding: 20px;
        }
        
        .auction-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #333;
        }
        
        .auction-info {
            color: #666;
            margin-bottom: 10px;
        }
        
        .current-price {
            font-size: 24px;
            color: #28a745;
            font-weight: bold;
            margin: 10px 0;
        }
        
        .bid-count {
            color: #666;
            font-size: 14px;
        }
        
        .time-left {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            text-align: center;
            margin: 10px 0;
        }
        
        .bid-btn {
            width: 100%;
            padding: 10px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: block;
            text-align: center;
        }
        
        .no-auctions {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 10px;
            color: #999;
        }
        
        .status-active {
            color: #28a745;
        }
        
        .status-closed {
            color: #dc3545;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="logo">BuyMe</a>
            
            <ul class="nav-menu">
                <li><a href="dashboard.jsp">Home</a></li>
                <li><a href="browse.jsp">Browse Auctions</a></li>
                <li><a href="create-auction.jsp">Sell Item</a></li>
                <li><a href="my-bids.jsp">My Bids</a></li>
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <h1 style="margin-bottom: 20px;">Browse Auctions</h1>
        
        <div class="search-section">
            <form method="get" class="search-form">
                <input type="text" name="search" placeholder="Search items..." value="<%= request.getParameter("search") != null ? request.getParameter("search") : "" %>">
                <select name="category">
                    <option value="">All Categories</option>
                    <%
                        try {
                            Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                            Statement stmt = conn.createStatement();
                            ResultSet rs = stmt.executeQuery("SELECT * FROM category WHERE level = 1");
                            while(rs.next()) {
                    %>
                        <option value="<%= rs.getInt("categoryID") %>"><%= rs.getString("categoryName") %></option>
                    <%
                            }
                            conn.close();
                        } catch(Exception e) {
                            e.printStackTrace();
                        }
                    %>
                </select>
                <input type="number" name="minPrice" placeholder="Min Price" step="0.01">
                <input type="number" name="maxPrice" placeholder="Max Price" step="0.01">
                <button type="submit" class="search-btn">Search</button>
            </form>
        </div>
        
        <div class="auctions-grid">
            <%
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    // Build query based on search parameters
                    StringBuilder sql = new StringBuilder();
                    sql.append("SELECT a.*, i.itemName, i.description, i.itemCondition, ");
                    sql.append("u.username as sellerName, ");
                    sql.append("(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount ");
                    sql.append("FROM auction a ");
                    sql.append("JOIN item i ON a.itemID = i.itemID ");
                    sql.append("JOIN user u ON a.sellerID = u.userID ");
                    sql.append("WHERE a.status = 'active' AND a.closeDateTime > NOW() ");
                    
                    String search = request.getParameter("search");
                    if (search != null && !search.trim().isEmpty()) {
                        sql.append("AND (i.itemName LIKE ? OR i.description LIKE ?) ");
                    }
                    
                    sql.append("ORDER BY a.closeDateTime ASC");
                    
                    PreparedStatement pstmt = conn.prepareStatement(sql.toString());
                    int paramIndex = 1;
                    
                    if (search != null && !search.trim().isEmpty()) {
                        pstmt.setString(paramIndex++, "%" + search + "%");
                        pstmt.setString(paramIndex++, "%" + search + "%");
                    }
                    
                    ResultSet rs = pstmt.executeQuery();
                    boolean hasAuctions = false;
                    
                    while(rs.next()) {
                        hasAuctions = true;
                        int auctionID = rs.getInt("auctionID");
                        String itemName = rs.getString("itemName");
                        String description = rs.getString("description");
                        double currentPrice = rs.getDouble("currentPrice");
                        int bidCount = rs.getInt("bidCount");
                        Timestamp closeTime = rs.getTimestamp("closeDateTime");
                        String sellerName = rs.getString("sellerName");
                        
                        // Calculate time left
                        long timeLeft = closeTime.getTime() - System.currentTimeMillis();
                        long hoursLeft = timeLeft / (1000 * 60 * 60);
                        long daysLeft = hoursLeft / 24;
                        String timeLeftStr = daysLeft > 0 ? daysLeft + " days" : hoursLeft + " hours";
            %>
                <div class="auction-card">
                    <div class="auction-header">
                        <div style="font-size: 12px;">Seller: <%= sellerName %></div>
                        <div style="font-size: 12px;">Closes: <%= closeTime %></div>
                    </div>
                    <div class="auction-body">
                        <div class="auction-title"><%= itemName %></div>
                        <div class="auction-info">
                            <%= description != null && description.length() > 100 ? 
                                description.substring(0, 100) + "..." : description %>
                        </div>
                        <div class="current-price">$<%= String.format("%.2f", currentPrice) %></div>
                        <div class="bid-count"><%= bidCount %> bid<%= bidCount != 1 ? "s" : "" %></div>
                        <div class="time-left">
                            <strong><%= timeLeftStr %></strong> left
                        </div>
                        <a href="auction-details.jsp?id=<%= auctionID %>" class="bid-btn">View & Bid</a>
                    </div>
                </div>
            <%
                    }
                    
                    if (!hasAuctions) {
            %>
                <div class="no-auctions">
                    <h2>No Active Auctions Found</h2>
                    <p>Try adjusting your search criteria or check back later.</p>
                </div>
            <%
                    }
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    out.println("<div class='no-auctions'>Error loading auctions. Please try again later.</div>");
                }
            %>
        </div>
    </div>
</body>
</html>
