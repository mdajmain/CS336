<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    
    // Get search/filter parameters
    String search = request.getParameter("search");
    String categoryParam = request.getParameter("category");
    String minPriceParam = request.getParameter("minPrice");
    String maxPriceParam = request.getParameter("maxPrice");
    String sortBy = request.getParameter("sortBy");
    String conditionParam = request.getParameter("condition");
    String statusParam = request.getParameter("status");
    
    if (search == null) search = "";
    if (sortBy == null) sortBy = "endingSoon";
    if (statusParam == null) statusParam = "active";
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
            max-width: 1400px;
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
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .page-header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .page-header p {
            color: #666;
        }
        
        /* Search and Filter Section */
        .search-section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .search-section h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        .search-form {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 20px;
        }
        
        .form-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        
        .form-group label {
            font-size: 13px;
            color: #666;
            font-weight: 600;
        }
        
        .form-group input,
        .form-group select {
            padding: 10px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .search-full-width {
            grid-column: 1 / -1;
        }
        
        .filter-buttons {
            display: flex;
            gap: 10px;
            grid-column: 1 / -1;
        }
        
        .btn {
            padding: 10px 25px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        /* Sort Bar */
        .sort-bar {
            background: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .results-count {
            color: #666;
            font-size: 14px;
        }
        
        .sort-options {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .sort-options label {
            font-size: 14px;
            color: #666;
            font-weight: 600;
        }
        
        .sort-options select {
            padding: 8px 12px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 14px;
        }
        
        /* Auctions Grid */
        .auctions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .auction-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: transform 0.3s, box-shadow 0.3s;
        }
        
        .auction-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
        }
        
        .auction-header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
        }
        
        .auction-header-top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 8px;
        }
        
        .auction-id {
            font-size: 12px;
            opacity: 0.9;
        }
        
        .auction-status {
            background: rgba(255,255,255,0.2);
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 11px;
            font-weight: 600;
        }
        
        .seller-info {
            font-size: 13px;
            opacity: 0.9;
        }
        
        .auction-body {
            padding: 20px;
        }
        
        .auction-title {
            font-size: 18px;
            font-weight: bold;
            margin-bottom: 10px;
            color: #333;
            min-height: 50px;
        }
        
        .auction-description {
            color: #666;
            font-size: 14px;
            margin-bottom: 15px;
            min-height: 60px;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        
        .auction-meta {
            display: flex;
            justify-content: space-between;
            margin-bottom: 15px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        
        .meta-item {
            text-align: center;
        }
        
        .meta-label {
            font-size: 11px;
            color: #666;
            text-transform: uppercase;
            margin-bottom: 3px;
        }
        
        .meta-value {
            font-size: 14px;
            color: #333;
            font-weight: 600;
        }
        
        .current-price {
            font-size: 28px;
            color: #28a745;
            font-weight: bold;
            margin: 15px 0;
            text-align: center;
        }
        
        .bid-info {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            font-size: 14px;
            color: #666;
        }
        
        .bid-count {
            font-weight: 600;
        }
        
        .time-left {
            background: #fff3cd;
            padding: 10px;
            border-radius: 5px;
            text-align: center;
            margin-bottom: 15px;
            border: 1px solid #ffc107;
        }
        
        .time-left.urgent {
            background: #f8d7da;
            border-color: #dc3545;
            color: #721c24;
        }
        
        .time-left strong {
            font-size: 16px;
        }
        
        .action-buttons {
            display: flex;
            gap: 10px;
        }
        
        .bid-btn {
            flex: 1;
            padding: 12px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
            display: block;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .bid-btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        
        .details-btn {
            padding: 12px 20px;
            background: white;
            color: #667eea;
            border: 2px solid #667eea;
            border-radius: 5px;
            text-decoration: none;
            display: block;
            text-align: center;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .details-btn:hover {
            background: #667eea;
            color: white;
        }
        
        .no-auctions {
            text-align: center;
            padding: 60px 20px;
            background: white;
            border-radius: 10px;
            color: #999;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .no-auctions h2 {
            margin-bottom: 10px;
            color: #666;
        }
        
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .badge-new { background: #28a745; color: white; }
        .badge-good { background: #17a2b8; color: white; }
        .badge-like-new { background: #007bff; color: white; }
        
        .quick-links {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .quick-links h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 16px;
        }
        
        .quick-links-grid {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .quick-link {
            padding: 8px 15px;
            background: #f8f9fa;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            text-decoration: none;
            color: #667eea;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s;
        }
        
        .quick-link:hover {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
        
        @media (max-width: 768px) {
            .search-form {
                grid-template-columns: 1fr;
            }
            
            .auctions-grid {
                grid-template-columns: 1fr;
            }
            
            .sort-bar {
                flex-direction: column;
                align-items: flex-start;
            }
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
                <li><a href="my-alerts.jsp">My Alerts</a></li>
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="notifications.jsp" class="logout-btn">Notifications</a>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="page-header">
            <h1>Browse Auctions</h1>
            <p>Find great deals on items you love</p>
        </div>
        
        <!-- Quick Links -->
        <div class="quick-links">
            <h3>Quick Access</h3>
            <div class="quick-links-grid">
                <a href="browse.jsp?status=active" class="quick-link">Active Auctions</a>
                <a href="browse.jsp?sortBy=newest" class="quick-link">Newest Listings</a>
                <a href="browse.jsp?sortBy=endingSoon" class="quick-link">Ending Soon</a>
                <a href="browse.jsp?sortBy=priceAsc" class="quick-link">Lowest Price</a>
                <a href="browse.jsp?sortBy=mostBids" class="quick-link">Most Popular</a>
                <a href="my-alerts.jsp" class="quick-link">Set Alert</a>
                <a href="questions.jsp" class="quick-link">Browse Q&A</a>
            </div>
        </div>
        
        <!-- Advanced Search & Filters -->
        <div class="search-section">
            <h3>🔍 Advanced Search & Filters</h3>
            <form method="get" action="browse.jsp">
                <div class="search-form">
                    <div class="form-group search-full-width">
                        <label>Search Keywords</label>
                        <input type="text" 
                               name="search" 
                               placeholder="Search by item name, description, or keywords..." 
                               value="<%= search %>">
                    </div>
                    
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category">
                            <option value="">All Categories</option>
                            <%
                                try {
                                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                    Statement stmt = conn.createStatement();
                                    ResultSet rsCategories = stmt.executeQuery("SELECT * FROM category WHERE level = 1 ORDER BY categoryName");
                                    while(rsCategories.next()) {
                                        int catID = rsCategories.getInt("categoryID");
                                        String selected = categoryParam != null && categoryParam.equals(String.valueOf(catID)) ? "selected" : "";
                            %>
                                <option value="<%= catID %>" <%= selected %>><%= rsCategories.getString("categoryName") %></option>
                            <%
                                    }
                                    conn.close();
                                } catch(Exception e) {
                                    e.printStackTrace();
                                }
                            %>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Item Condition</label>
                        <select name="condition">
                            <option value="">Any Condition</option>
                            <option value="New" <%= "New".equals(conditionParam) ? "selected" : "" %>>New</option>
                            <option value="Like New" <%= "Like New".equals(conditionParam) ? "selected" : "" %>>Like New</option>
                            <option value="Very Good" <%= "Very Good".equals(conditionParam) ? "selected" : "" %>>Very Good</option>
                            <option value="Good" <%= "Good".equals(conditionParam) ? "selected" : "" %>>Good</option>
                            <option value="Acceptable" <%= "Acceptable".equals(conditionParam) ? "selected" : "" %>>Acceptable</option>
                        </select>
                    </div>
                    
                    <div class="form-group">
                        <label>Min Price ($)</label>
                        <input type="number" 
                               name="minPrice" 
                               placeholder="0.00" 
                               step="0.01" 
                               value="<%= minPriceParam != null ? minPriceParam : "" %>">
                    </div>
                    
                    <div class="form-group">
                        <label>Max Price ($)</label>
                        <input type="number" 
                               name="maxPrice" 
                               placeholder="10000.00" 
                               step="0.01" 
                               value="<%= maxPriceParam != null ? maxPriceParam : "" %>">
                    </div>
                    
                    <div class="form-group">
                        <label>Status</label>
                        <select name="status">
                            <option value="active" <%= "active".equals(statusParam) ? "selected" : "" %>>Active Only</option>
                            <option value="all" <%= "all".equals(statusParam) ? "selected" : "" %>>All Auctions</option>
                            <option value="closed" <%= "closed".equals(statusParam) ? "selected" : "" %>>Closed</option>
                        </select>
                    </div>
                    
                    <div class="filter-buttons">
                        <button type="submit" class="btn btn-primary">🔍 Search</button>
                        <a href="browse.jsp" class="btn btn-secondary">Clear Filters</a>
                    </div>
                </div>
            </form>
        </div>
        
        <%
            // Build SQL query based on filters
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            int totalResults = 0;
            
            try {
                conn = com.buyme.util.DatabaseConnection.getConnection();
                
                StringBuilder sql = new StringBuilder();
                sql.append("SELECT a.auctionID, a.currentPrice, a.closeDateTime, a.status, a.startDateTime, a.bidIncrement, ");
                sql.append("i.itemID, i.itemName, i.description, i.itemCondition, ");
                sql.append("u.username as sellerName, u.userID as sellerID, ");
                sql.append("(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount, ");
                sql.append("(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as totalBids ");
                sql.append("FROM auction a ");
                sql.append("JOIN item i ON a.itemID = i.itemID ");
                sql.append("JOIN user u ON a.sellerID = u.userID ");
                sql.append("WHERE 1=1 ");
                
                List<Object> params = new ArrayList<>();
                
                // Status filter
                if ("active".equals(statusParam)) {
                    sql.append("AND a.status = 'active' AND a.closeDateTime > NOW() ");
                } else if ("closed".equals(statusParam)) {
                    sql.append("AND a.status = 'closed' ");
                } else {
                    sql.append("AND a.status IN ('active', 'closed') ");
                }
                
                // Search filter
                if (search != null && !search.trim().isEmpty()) {
                    sql.append("AND (i.itemName LIKE ? OR i.description LIKE ?) ");
                    params.add("%" + search + "%");
                    params.add("%" + search + "%");
                }
                
                // Category filter
                if (categoryParam != null && !categoryParam.isEmpty()) {
                    sql.append("AND i.categoryID = ? ");
                    params.add(Integer.parseInt(categoryParam));
                }
                
                // Condition filter
                if (conditionParam != null && !conditionParam.isEmpty()) {
                    sql.append("AND i.itemCondition = ? ");
                    params.add(conditionParam);
                }
                
                // Price filters
                if (minPriceParam != null && !minPriceParam.isEmpty()) {
                    sql.append("AND a.currentPrice >= ? ");
                    params.add(Double.parseDouble(minPriceParam));
                }
                
                if (maxPriceParam != null && !maxPriceParam.isEmpty()) {
                    sql.append("AND a.currentPrice <= ? ");
                    params.add(Double.parseDouble(maxPriceParam));
                }
                
                // Sorting
                sql.append("ORDER BY ");
                switch(sortBy) {
                    case "priceAsc":
                        sql.append("a.currentPrice ASC");
                        break;
                    case "priceDesc":
                        sql.append("a.currentPrice DESC");
                        break;
                    case "newest":
                        sql.append("a.startDateTime DESC");
                        break;
                    case "mostBids":
                        sql.append("totalBids DESC");
                        break;
                    case "endingSoon":
                    default:
                        sql.append("a.closeDateTime ASC");
                        break;
                }
                
                pstmt = conn.prepareStatement(sql.toString());
                
                // Set parameters
                for (int i = 0; i < params.size(); i++) {
                    Object param = params.get(i);
                    if (param instanceof String) {
                        pstmt.setString(i + 1, (String) param);
                    } else if (param instanceof Integer) {
                        pstmt.setInt(i + 1, (Integer) param);
                    } else if (param instanceof Double) {
                        pstmt.setDouble(i + 1, (Double) param);
                    }
                }
                
                rs = pstmt.executeQuery();
                
                // Count results first
                List<Map<String, Object>> auctions = new ArrayList<>();
                while(rs.next()) {
                    Map<String, Object> auction = new HashMap<>();
                    auction.put("auctionID", rs.getInt("auctionID"));
                    auction.put("itemName", rs.getString("itemName"));
                    auction.put("description", rs.getString("description"));
                    auction.put("itemCondition", rs.getString("itemCondition"));
                    auction.put("currentPrice", rs.getDouble("currentPrice"));
                    auction.put("bidCount", rs.getInt("bidCount"));
                    auction.put("totalBids", rs.getInt("totalBids"));
                    auction.put("closeDateTime", rs.getTimestamp("closeDateTime"));
                    auction.put("startDateTime", rs.getTimestamp("startDateTime"));
                    auction.put("sellerName", rs.getString("sellerName"));
                    auction.put("sellerID", rs.getInt("sellerID"));
                    auction.put("status", rs.getString("status"));
                    auction.put("bidIncrement", rs.getDouble("bidIncrement"));
                    auctions.add(auction);
                    totalResults++;
                }
        %>
        
        <!-- Sort Bar -->
        <div class="sort-bar">
            <div class="results-count">
                <strong><%= totalResults %></strong> auction<%= totalResults != 1 ? "s" : "" %> found
            </div>
            <div class="sort-options">
                <label>Sort by:</label>
                <select onchange="window.location.href='browse.jsp?sortBy=' + this.value + 
                        '<%= search.isEmpty() ? "" : "&search=" + search %>' +
                        '<%= categoryParam == null ? "" : "&category=" + categoryParam %>' +
                        '<%= minPriceParam == null ? "" : "&minPrice=" + minPriceParam %>' +
                        '<%= maxPriceParam == null ? "" : "&maxPrice=" + maxPriceParam %>' +
                        '<%= conditionParam == null ? "" : "&condition=" + conditionParam %>' +
                        '&status=<%= statusParam %>'">
                    <option value="endingSoon" <%= "endingSoon".equals(sortBy) ? "selected" : "" %>>Ending Soon</option>
                    <option value="newest" <%= "newest".equals(sortBy) ? "selected" : "" %>>Newest First</option>
                    <option value="priceAsc" <%= "priceAsc".equals(sortBy) ? "selected" : "" %>>Price: Low to High</option>
                    <option value="priceDesc" <%= "priceDesc".equals(sortBy) ? "selected" : "" %>>Price: High to Low</option>
                    <option value="mostBids" <%= "mostBids".equals(sortBy) ? "selected" : "" %>>Most Popular</option>
                </select>
            </div>
        </div>
        
        <!-- Auctions Grid -->
        <div class="auctions-grid">
            <%
                SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy HH:mm");
                
                if (auctions.isEmpty()) {
            %>
                <div class="no-auctions" style="grid-column: 1/-1;">
                    <h2>No Auctions Found</h2>
                    <p>Try adjusting your search criteria or check back later for new listings.</p>
                    <a href="browse.jsp" class="btn btn-primary" style="display: inline-block; margin-top: 20px;">View All Auctions</a>
                </div>
            <%
                } else {
                    for (Map<String, Object> auction : auctions) {
                        int auctionID = (Integer) auction.get("auctionID");
                        String itemName = (String) auction.get("itemName");
                        String description = (String) auction.get("description");
                        String itemCondition = (String) auction.get("itemCondition");
                        double currentPrice = (Double) auction.get("currentPrice");
                        int bidCount = (Integer) auction.get("bidCount");
                        int totalBids = (Integer) auction.get("totalBids");
                        Timestamp closeTime = (Timestamp) auction.get("closeDateTime");
                        Timestamp startTime = (Timestamp) auction.get("startDateTime");
                        String sellerName = (String) auction.get("sellerName");
                        int sellerID = (Integer) auction.get("sellerID");
                        String status = (String) auction.get("status");
                        double bidIncrement = (Double) auction.get("bidIncrement");
                        
                        // Calculate time left
                        long timeLeft = closeTime.getTime() - System.currentTimeMillis();
                        long hoursLeft = timeLeft / (1000 * 60 * 60);
                        long daysLeft = hoursLeft / 24;
                        String timeLeftStr;
                        boolean isUrgent = false;
                        
                        if ("closed".equals(status)) {
                            timeLeftStr = "ENDED";
                            isUrgent = false;
                        } else if (daysLeft > 1) {
                            timeLeftStr = daysLeft + " days left";
                        } else if (hoursLeft > 0) {
                            timeLeftStr = hoursLeft + " hours left";
                            isUrgent = hoursLeft < 24;
                        } else {
                            timeLeftStr = "Ending soon!";
                            isUrgent = true;
                        }
                        
                        // Truncate description
                        String shortDesc = description != null && description.length() > 120 ? 
                                         description.substring(0, 120) + "..." : description;
            %>
            <div class="auction-card">
                <div class="auction-header">
                    <div class="auction-header-top">
                        <span class="auction-id">Auction #<%= auctionID %></span>
                        <span class="auction-status"><%= status.toUpperCase() %></span>
                    </div>
                    <div class="seller-info">
                        👤 Seller: <a href="user-auctions.jsp?userID=<%= sellerID %>" 
                                      style="color: white; text-decoration: underline;"><%= sellerName %></a>
                    </div>
                </div>
                
                <div class="auction-body">
                    <div class="auction-title"><%= itemName %></div>
                    
                    <div class="auction-meta">
                        <div class="meta-item">
                            <div class="meta-label">Condition</div>
                            <div class="meta-value"><%= itemCondition %></div>
                        </div>
                        <div class="meta-item">
                            <div class="meta-label">Increment</div>
                            <div class="meta-value">$<%= String.format("%.2f", bidIncrement) %></div>
                        </div>
                    </div>
                    
                    <div class="auction-description"><%= shortDesc != null ? shortDesc : "No description" %></div>
                    
                    <div class="current-price">$<%= String.format("%.2f", currentPrice) %></div>
                    
                    <div class="bid-info">
                        <span class="bid-count">📊 <%= totalBids %> bid<%= totalBids != 1 ? "s" : "" %> (<%= bidCount %> bidder<%= bidCount != 1 ? "s" : "" %>)</span>
                    </div>
                    
                    <div class="time-left <%= isUrgent ? "urgent" : "" %>">
                        ⏰ <strong><%= timeLeftStr %></strong>
                    </div>
                    
                    <div class="action-buttons">
                        <a href="auction-details.jsp?id=<%= auctionID %>" class="bid-btn">
                            <%= "closed".equals(status) ? "View Details" : "View & Place Bid" %>
                        </a>
                        <a href="auction-details.jsp?id=<%= auctionID %>#history" class="details-btn" title="View bid history">
                            📜
                        </a>
                    </div>
                </div>
            </div>
            <%
                    }
                }
            %>
        </div>
        
        <%
            } catch(Exception e) {
                e.printStackTrace();
                out.println("<div class='no-auctions' style='color: red;'>Error loading auctions: " + e.getMessage() + "</div>");
            } finally {
                if (rs != null) try { rs.close(); } catch(Exception e) {}
                if (pstmt != null) try { pstmt.close(); } catch(Exception e) {}
                if (conn != null) try { conn.close(); } catch(Exception e) {}
            }
        %>
    </div>
</body>
</html>

