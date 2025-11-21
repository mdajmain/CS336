<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getUserType())) {
        response.sendRedirect("../login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Dashboard - BuyMe</title>
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
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        .dashboard-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        .dashboard-card h3 {
            color: #333;
            margin-bottom: 15px;
        }
        .dashboard-card .number {
            font-size: 36px;
            color: #667eea;
            font-weight: bold;
        }
        .dashboard-card a {
            display: inline-block;
            margin-top: 15px;
            padding: 10px 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 5px;
        }
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .logout-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid white;
            padding: 8px 20px;
            border-radius: 5px;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>BuyMe Admin Panel</h2>
            <div>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="../logout" class="logout-btn">Logout</a>
                
                
            </div>
        </div>
    </nav>
    
    <div class="container">
        <h1>Admin Dashboard</h1>
        <p>Manage the BuyMe auction system</p>
        
        <div class="dashboard-grid">
            <div class="dashboard-card">
                <h3>Total Users</h3>
                <div class="number"><%
                    try {
                        java.sql.Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                        java.sql.Statement stmt = conn.createStatement();
                        java.sql.ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM user WHERE userType='end_user'");
                        if(rs.next()) out.print(rs.getInt(1));
                        conn.close();
                    } catch(Exception e) { out.print("0"); }
                %></div>
                <a href="manage-users.jsp">Manage Users</a>
            </div>
            
            <div class="dashboard-card">
                <h3>Active Auctions</h3>
                <div class="number"><%
                    try {
                        java.sql.Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                        java.sql.Statement stmt = conn.createStatement();
                        java.sql.ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM auction WHERE status='active'");
                        if(rs.next()) out.print(rs.getInt(1));
                        conn.close();
                    } catch(Exception e) { out.print("0"); }
                %></div>
                <a href="manage-auctions.jsp">View Auctions</a>
            </div>
            
            <div class="dashboard-card">
                <h3>Customer Reps</h3>
                <div class="number"><%
                    try {
                        java.sql.Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                        java.sql.Statement stmt = conn.createStatement();
                        java.sql.ResultSet rs = stmt.executeQuery("SELECT COUNT(*) FROM customer_rep");
                        if(rs.next()) out.print(rs.getInt(1));
                        conn.close();
                    } catch(Exception e) { out.print("0"); }
                %></div>
                <a href="manage-reps.jsp">Manage Reps</a>
            </div>
            
            <div class="dashboard-card">
                <h3>Total Sales</h3>
                <div class="number">$<%
                    try {
                        java.sql.Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                        java.sql.Statement stmt = conn.createStatement();
                        java.sql.ResultSet rs = stmt.executeQuery("SELECT COALESCE(SUM(finalPrice), 0) FROM sales_report");
                        if(rs.next()) out.print(String.format("%.2f", rs.getDouble(1)));
                        conn.close();
                    } catch(Exception e) { out.print("0.00"); }
                %></div>
                <a href="sales-report.jsp">View Reports</a>
            </div>
        </div>
    </div>
</body>
</html>