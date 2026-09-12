<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Sales Reports - Admin</title>
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
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .stat-card h3 {
            color: #666;
            font-size: 14px;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .stat-number {
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        h1, h2 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .filter-form {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            padding: 15px;
            background: #f8f9fa;
            border-radius: 5px;
        }
        
        .filter-form input, .filter-form select {
            padding: 8px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
        
        .filter-form button {
            padding: 8px 20px;
            background: #007bff;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            border-bottom: 2px solid #dee2e6;
            color: #495057;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .back-btn {
            display: inline-block;
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .export-btn {
            float: right;
            padding: 10px 20px;
            background: #28a745;
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        
        .chart-container {
            height: 300px;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>Admin Panel - Sales Reports</h2>
            <div>
                <span>Admin: <%= user.getUsername() %></span>
                <a href="../logout" style="color: white; margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
        
        <!-- Summary Statistics -->
        <div class="stats-grid">
            <%
                Connection conn = null;
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    // Total earnings
                    PreparedStatement totalStmt = conn.prepareStatement(
                        "SELECT COALESCE(SUM(finalPrice), 0) as total FROM sales_report"
                    );
                    ResultSet totalRs = totalStmt.executeQuery();
                    double totalEarnings = 0;
                    if (totalRs.next()) {
                        totalEarnings = totalRs.getDouble("total");
                    }
                    
                    // This month's earnings
                    PreparedStatement monthStmt = conn.prepareStatement(
                        "SELECT COALESCE(SUM(finalPrice), 0) as total FROM sales_report " +
                        "WHERE MONTH(transactionDate) = MONTH(CURRENT_DATE()) " +
                        "AND YEAR(transactionDate) = YEAR(CURRENT_DATE())"
                    );
                    ResultSet monthRs = monthStmt.executeQuery();
                    double monthEarnings = 0;
                    if (monthRs.next()) {
                        monthEarnings = monthRs.getDouble("total");
                    }
                    
                    // Total transactions
                    PreparedStatement countStmt = conn.prepareStatement(
                        "SELECT COUNT(*) as count FROM sales_report"
                    );
                    ResultSet countRs = countStmt.executeQuery();
                    int totalTransactions = 0;
                    if (countRs.next()) {
                        totalTransactions = countRs.getInt("count");
                    }
                    
                    // Active users
                    PreparedStatement userStmt = conn.prepareStatement(
                        "SELECT COUNT(DISTINCT buyerID) + COUNT(DISTINCT sellerID) as users FROM sales_report"
                    );
                    ResultSet userRs = userStmt.executeQuery();
                    int activeUsers = 0;
                    if (userRs.next()) {
                        activeUsers = userRs.getInt("users");
                    }
            %>
            <div class="stat-card">
                <h3>Total Earnings</h3>
                <div class="stat-number">$<%= String.format("%.2f", totalEarnings) %></div>
            </div>
            
            <div class="stat-card">
                <h3>This Month</h3>
                <div class="stat-number">$<%= String.format("%.2f", monthEarnings) %></div>
            </div>
            
            <div class="stat-card">
                <h3>Total Sales</h3>
                <div class="stat-number"><%= totalTransactions %></div>
            </div>
            
            <div class="stat-card">
                <h3>Active Users</h3>
                <div class="stat-number"><%= activeUsers %></div>
            </div>
        </div>
        
        <!-- Sales by Category -->
        <div class="section">
            <h2>Sales by Category</h2>
            <table>
                <thead>
                    <tr>
                        <th>Category</th>
                        <th>Items Sold</th>
                        <th>Total Revenue</th>
                        <th>Average Price</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        PreparedStatement catStmt = conn.prepareStatement(
                            "SELECT c.categoryName, COUNT(*) as itemCount, " +
                            "SUM(sr.finalPrice) as total, AVG(sr.finalPrice) as avgPrice " +
                            "FROM sales_report sr " +
                            "JOIN category c ON sr.categoryID = c.categoryID " +
                            "GROUP BY c.categoryID, c.categoryName " +
                            "ORDER BY total DESC"
                        );
                        ResultSet catRs = catStmt.executeQuery();
                        
                        while(catRs.next()) {
                    %>
                    <tr>
                        <td><%= catRs.getString("categoryName") %></td>
                        <td><%= catRs.getInt("itemCount") %></td>
                        <td>$<%= String.format("%.2f", catRs.getDouble("total")) %></td>
                        <td>$<%= String.format("%.2f", catRs.getDouble("avgPrice")) %></td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
        
        <!-- Top Sellers -->
        <div class="section">
            <h2>Top Sellers</h2>
            <table>
                <thead>
                    <tr>
                        <th>Seller</th>
                        <th>Items Sold</th>
                        <th>Total Revenue</th>
                        <th>Average Sale Price</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        PreparedStatement sellerStmt = conn.prepareStatement(
                            "SELECT u.username, COUNT(*) as salesCount, " +
                            "SUM(sr.finalPrice) as total, AVG(sr.finalPrice) as avgPrice " +
                            "FROM sales_report sr " +
                            "JOIN user u ON sr.sellerID = u.userID " +
                            "GROUP BY sr.sellerID, u.username " +
                            "ORDER BY total DESC " +
                            "LIMIT 10"
                        );
                        ResultSet sellerRs = sellerStmt.executeQuery();
                        
                        while(sellerRs.next()) {
                    %>
                    <tr>
                        <td><%= sellerRs.getString("username") %></td>
                        <td><%= sellerRs.getInt("salesCount") %></td>
                        <td>$<%= String.format("%.2f", sellerRs.getDouble("total")) %></td>
                        <td>$<%= String.format("%.2f", sellerRs.getDouble("avgPrice")) %></td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
        
        <!-- Best Selling Items -->
        <div class="section">
            <h2>Best Selling Items</h2>
            <table>
                <thead>
                    <tr>
                        <th>Item</th>
                        <th>Category</th>
                        <th>Sale Price</th>
                        <th>Seller</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        PreparedStatement itemStmt = conn.prepareStatement(
                            "SELECT sr.itemName, c.categoryName, sr.finalPrice, " +
                            "u.username as seller, sr.transactionDate " +
                            "FROM sales_report sr " +
                            "JOIN category c ON sr.categoryID = c.categoryID " +
                            "JOIN user u ON sr.sellerID = u.userID " +
                            "ORDER BY sr.finalPrice DESC " +
                            "LIMIT 20"
                        );
                        ResultSet itemRs = itemStmt.executeQuery();
                        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy");
                        
                        while(itemRs.next()) {
                    %>
                    <tr>
                        <td><%= itemRs.getString("itemName") %></td>
                        <td><%= itemRs.getString("categoryName") %></td>
                        <td>$<%= String.format("%.2f", itemRs.getDouble("finalPrice")) %></td>
                        <td><%= itemRs.getString("seller") %></td>
                        <td><%= sdf.format(itemRs.getTimestamp("transactionDate")) %></td>
                    </tr>
                    <%
                        }
                        
                        conn.close();
                    } catch(Exception e) {
                        e.printStackTrace();
                    }
                    %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
