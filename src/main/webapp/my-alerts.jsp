<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
    
    String message = null;
    String error = null;
    
    // Handle POST actions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        Connection conn = null;
        
        try {
            conn = com.buyme.util.DatabaseConnection.getConnection();
            
            if ("create".equals(action)) {
                String itemName = request.getParameter("itemName");
                String categoryID = request.getParameter("categoryID");
                String minPrice = request.getParameter("minPrice");
                String maxPrice = request.getParameter("maxPrice");
                
                PreparedStatement pstmt = conn.prepareStatement(
                    "INSERT INTO alert (userID, itemName, categoryID, minPrice, maxPrice, isActive) " +
                    "VALUES (?, ?, ?, ?, ?, TRUE)"
                );
                pstmt.setInt(1, user.getUserID());
                pstmt.setString(2, itemName != null && !itemName.isEmpty() ? itemName : null);
                
                if (categoryID != null && !categoryID.isEmpty()) {
                    pstmt.setInt(3, Integer.parseInt(categoryID));
                } else {
                    pstmt.setNull(3, Types.INTEGER);
                }
                
                if (minPrice != null && !minPrice.isEmpty()) {
                    pstmt.setDouble(4, Double.parseDouble(minPrice));
                } else {
                    pstmt.setNull(4, Types.DOUBLE);
                }
                
                if (maxPrice != null && !maxPrice.isEmpty()) {
                    pstmt.setDouble(5, Double.parseDouble(maxPrice));
                } else {
                    pstmt.setNull(5, Types.DOUBLE);
                }
                
                pstmt.executeUpdate();
                message = "Alert created successfully! You'll be notified when matching items are listed.";
                
            } else if ("toggle".equals(action)) {
                int alertID = Integer.parseInt(request.getParameter("alertID"));
                
                PreparedStatement pstmt = conn.prepareStatement(
                    "UPDATE alert SET isActive = NOT isActive WHERE alertID = ? AND userID = ?"
                );
                pstmt.setInt(1, alertID);
                pstmt.setInt(2, user.getUserID());
                pstmt.executeUpdate();
                
                message = "Alert status updated.";
                
            } else if ("delete".equals(action)) {
                int alertID = Integer.parseInt(request.getParameter("alertID"));
                
                PreparedStatement pstmt = conn.prepareStatement(
                    "DELETE FROM alert WHERE alertID = ? AND userID = ?"
                );
                pstmt.setInt(1, alertID);
                pstmt.setInt(2, user.getUserID());
                pstmt.executeUpdate();
                
                message = "Alert deleted successfully.";
            }
            
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            error = "Error: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Alerts - BuyMe</title>
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
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .page-header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .page-header p {
            color: #666;
        }
        
        .grid-layout {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 30px;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .section h2 {
            color: #333;
            margin-bottom: 20px;
            font-size: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
        }
        
        .form-group input,
        .form-group select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .form-group input:focus,
        .form-group select:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-help {
            font-size: 13px;
            color: #666;
            margin-top: 5px;
        }
        
        .btn {
            padding: 12px 30px;
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
        
        .alert-card {
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 15px;
            transition: all 0.3s;
        }
        
        .alert-card.active {
            border-color: #28a745;
            background: #f8fff9;
        }
        
        .alert-card.inactive {
            border-color: #dc3545;
            background: #fff8f8;
            opacity: 0.7;
        }
        
        .alert-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 15px;
        }
        
        .alert-title {
            font-weight: 600;
            color: #333;
            font-size: 16px;
        }
        
        .alert-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .badge-active {
            background: #d4edda;
            color: #155724;
        }
        
        .badge-inactive {
            background: #f8d7da;
            color: #721c24;
        }
        
        .alert-details {
            margin-bottom: 15px;
            color: #666;
            font-size: 14px;
        }
        
        .alert-detail-item {
            margin-bottom: 5px;
        }
        
        .alert-actions {
            display: flex;
            gap: 10px;
        }
        
        .btn-sm {
            padding: 6px 12px;
            font-size: 13px;
        }
        
        .btn-toggle {
            background: #ffc107;
            color: #333;
        }
        
        .btn-delete {
            background: #dc3545;
            color: white;
        }
        
        .no-alerts {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .no-alerts h3 {
            margin-bottom: 10px;
            color: #666;
        }
        
        .info-box {
            background: #e7f3ff;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            border-left: 4px solid #667eea;
        }
        
        .info-box h3 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #555;
        }
        
        .info-box li {
            margin-bottom: 5px;
            font-size: 14px;
        }
        
        .matched-auctions {
            margin-top: 20px;
            padding-top: 20px;
            border-top: 1px solid #e1e1e1;
        }
        
        .matched-auctions h4 {
            color: #28a745;
            margin-bottom: 10px;
            font-size: 14px;
        }
        
        .matched-item {
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            margin-bottom: 8px;
            font-size: 14px;
        }
        
        .matched-item a {
            color: #667eea;
            text-decoration: none;
            font-weight: 600;
        }
        
        .matched-item a:hover {
            text-decoration: underline;
        }
        
        @media (max-width: 968px) {
            .grid-layout {
                grid-template-columns: 1fr;
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
    <a href="dashboard.jsp" class="back-link">← Back to Dashboard</a>

    <div class="page-header">
        <h1>🔔 My Alerts</h1>
        <p>Set up alerts to be notified when items you're interested in become available</p>
    </div>

    <% if (message != null) { %>
        <div class="alert alert-success"><%= message %></div>
    <% } %>

    <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } %>

    <div class="grid-layout">
        <!-- Alerts List -->
        <div class="section">
            <h2>Your Active Alerts</h2>
            
            <%
                Connection conn = null;
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    PreparedStatement alertStmt = conn.prepareStatement(
                        "SELECT a.*, c.categoryName " +
                        "FROM alert a " +
                        "LEFT JOIN category c ON a.categoryID = c.categoryID " +
                        "WHERE a.userID = ? " +
                        "ORDER BY a.createdDate DESC"
                    );
                    alertStmt.setInt(1, user.getUserID());
                    ResultSet alertRs = alertStmt.executeQuery();
                    
                    boolean hasAlerts = false;
                    SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy");
                    
                    while (alertRs.next()) {
                        hasAlerts = true;
                        int alertID = alertRs.getInt("alertID");
                        String itemName = alertRs.getString("itemName");
                        String categoryName = alertRs.getString("categoryName");
                        Double minPrice = alertRs.getDouble("minPrice");
                        if (alertRs.wasNull()) minPrice = null;
                        Double maxPrice = alertRs.getDouble("maxPrice");
                        if (alertRs.wasNull()) maxPrice = null;
                        boolean isActive = alertRs.getBoolean("isActive");
                        Timestamp created = alertRs.getTimestamp("createdDate");
            %>
            
            <div class="alert-card <%= isActive ? "active" : "inactive" %>">
                <div class="alert-header">
                    <div class="alert-title">
                        <% if (itemName != null && !itemName.isEmpty()) { %>
                            <%= itemName %>
                        <% } else if (categoryName != null) { %>
                            <%= categoryName %> Items
                        <% } else { %>
                            Any Item
                        <% } %>
                    </div>
                    <span class="alert-badge badge-<%= isActive ? "active" : "inactive" %>">
                        <%= isActive ? "ACTIVE" : "PAUSED" %>
                    </span>
                </div>
                
                <div class="alert-details">
                    <% if (itemName != null && !itemName.isEmpty()) { %>
                        <div class="alert-detail-item">
                            <strong>Keyword:</strong> "<%= itemName %>"
                        </div>
                    <% } %>
                    
                    <% if (categoryName != null) { %>
                        <div class="alert-detail-item">
                            <strong>Category:</strong> <%= categoryName %>
                        </div>
                    <% } %>
                    
                    <% if (minPrice != null || maxPrice != null) { %>
                        <div class="alert-detail-item">
                            <strong>Price Range:</strong>
                            <%= minPrice != null ? "$" + String.format("%.2f", minPrice) : "Any" %>
                            -
                            <%= maxPrice != null ? "$" + String.format("%.2f", maxPrice) : "Any" %>
                        </div>
                    <% } %>
                    
                    <div class="alert-detail-item">
                        <strong>Created:</strong> <%= sdf.format(created) %>
                    </div>
                </div>
                
                <%
                    // Check for matching auctions
                    StringBuilder matchSql = new StringBuilder();
                    matchSql.append("SELECT a.auctionID, i.itemName, a.currentPrice, a.closeDateTime ");
                    matchSql.append("FROM auction a ");
                    matchSql.append("JOIN item i ON a.itemID = i.itemID ");
                    matchSql.append("WHERE a.status = 'active' AND a.closeDateTime > NOW() ");
                    
                    if (itemName != null && !itemName.isEmpty()) {
                        matchSql.append("AND i.itemName LIKE ? ");
                    }
                    if (categoryName != null) {
                        matchSql.append("AND i.categoryID = ? ");
                    }
                    if (minPrice != null) {
                        matchSql.append("AND a.currentPrice >= ? ");
                    }
                    if (maxPrice != null) {
                        matchSql.append("AND a.currentPrice <= ? ");
                    }
                    
                    matchSql.append("ORDER BY a.startDateTime DESC LIMIT 5");
                    
                    PreparedStatement matchStmt = conn.prepareStatement(matchSql.toString());
                    int paramIndex = 1;
                    
                    if (itemName != null && !itemName.isEmpty()) {
                        matchStmt.setString(paramIndex++, "%" + itemName + "%");
                    }
                    if (categoryName != null) {
                        matchStmt.setInt(paramIndex++, alertRs.getInt("categoryID"));
                    }
                    if (minPrice != null) {
                        matchStmt.setDouble(paramIndex++, minPrice);
                    }
                    if (maxPrice != null) {
                        matchStmt.setDouble(paramIndex++, maxPrice);
                    }
                    
                    ResultSet matchRs = matchStmt.executeQuery();
                    boolean hasMatches = false;
                    int matchCount = 0;
                    
                    StringBuilder matchesHtml = new StringBuilder();
                    while (matchRs.next()) {
                        if (!hasMatches) {
                            matchesHtml.append("<div class='matched-auctions'>");
                            matchesHtml.append("<h4>✨ Current Matching Auctions:</h4>");
                            hasMatches = true;
                        }
                        matchCount++;
                        matchesHtml.append("<div class='matched-item'>");
                        matchesHtml.append("<a href='auction-details.jsp?id=").append(matchRs.getInt("auctionID")).append("'>");
                        matchesHtml.append(matchRs.getString("itemName"));
                        matchesHtml.append("</a> - $").append(String.format("%.2f", matchRs.getDouble("currentPrice")));
                        matchesHtml.append("</div>");
                    }
                    if (hasMatches) {
                        matchesHtml.append("</div>");
                        out.print(matchesHtml.toString());
                    }
                %>
                
                <div class="alert-actions">
                    <form method="post" style="display: inline;">
                        <input type="hidden" name="action" value="toggle">
                        <input type="hidden" name="alertID" value="<%= alertID %>">
                        <button type="submit" class="btn btn-toggle btn-sm">
                            <%= isActive ? "⏸ Pause" : "▶ Activate" %>
                        </button>
                    </form>
                    
                    <form method="post" style="display: inline;" 
                          onsubmit="return confirm('Delete this alert?');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="alertID" value="<%= alertID %>">
                        <button type="submit" class="btn btn-delete btn-sm">
                            🗑 Delete
                        </button>
                    </form>
                </div>
            </div>
            
            <%
                    }
                    
                    if (!hasAlerts) {
            %>
            <div class="no-alerts">
                <h3>No alerts set up yet</h3>
                <p>Create your first alert using the form on the right →</p>
            </div>
            <%
                    }
                    
                    conn.close();
                } catch (Exception e) {
                    e.printStackTrace();
                    out.println("<div style='color: red; padding: 20px;'>Error loading alerts: " + e.getMessage() + "</div>");
                }
            %>
        </div>

        <!-- Create Alert Form -->
        <div class="section">
            <h2>Create New Alert</h2>
            
            <div class="info-box">
                <h3>How Alerts Work</h3>
                <ul>
                    <li>Get notified when matching items are listed</li>
                    <li>Set keywords, categories, and price ranges</li>
                    <li>Alerts can be paused or deleted anytime</li>
                    <li>Check notifications regularly for matches</li>
                </ul>
            </div>
            
            <form method="post">
                <input type="hidden" name="action" value="create">
                
                <div class="form-group">
                    <label for="itemName">Item Keyword (Optional)</label>
                    <input type="text" 
                           id="itemName" 
                           name="itemName" 
                           placeholder="e.g., iPhone, Camera, Laptop">
                    <div class="form-help">
                        Alerts will trigger for items containing this keyword in the name or description
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="categoryID">Category (Optional)</label>
                    <select id="categoryID" name="categoryID">
                        <option value="">Any Category</option>
                        <%
                            try {
                                Connection catConn = com.buyme.util.DatabaseConnection.getConnection();
                                Statement catStmt = catConn.createStatement();
                                ResultSet catRs = catStmt.executeQuery(
                                    "SELECT * FROM category WHERE level = 1 ORDER BY categoryName"
                                );
                                
                                while (catRs.next()) {
                        %>
                        <option value="<%= catRs.getInt("categoryID") %>">
                            <%= catRs.getString("categoryName") %>
                        </option>
                        <%
                                }
                                catConn.close();
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        %>
                    </select>
                    <div class="form-help">
                        Filter alerts by category
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="minPrice">Minimum Price (Optional)</label>
                    <input type="number" 
                           id="minPrice" 
                           name="minPrice" 
                           step="0.01" 
                           placeholder="0.00">
                    <div class="form-help">
                        Only alert for items starting at or above this price
                    </div>
                </div>
                
                <div class="form-group">
                    <label for="maxPrice">Maximum Price (Optional)</label>
                    <input type="number" 
                           id="maxPrice" 
                           name="maxPrice" 
                           step="0.01" 
                           placeholder="10000.00">
                    <div class="form-help">
                        Only alert for items starting at or below this price
                    </div>
                </div>
                
                <button type="submit" class="btn btn-primary">
                    🔔 Create Alert
                </button>
            </form>
        </div>
    </div>
</div>

</body>
</html>
