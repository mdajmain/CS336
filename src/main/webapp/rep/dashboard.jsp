<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"customer_rep".equals(user.getUserType())) {
        response.sendRedirect("../login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Rep Dashboard - BuyMe</title>
    <style>
        /* Same styles as admin dashboard */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px 0; color: white; }
        .nav-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .dashboard-card { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); margin-bottom: 20px; }
        h1 { color: #333; margin-bottom: 10px; }
        .logout-btn { background: rgba(255,255,255,0.2); color: white; border: 1px solid white; padding: 8px 20px; border-radius: 5px; text-decoration: none; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>Customer Representative Panel</h2>
            <div>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="../logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <h1>Customer Representative Dashboard</h1>
        
        <div class="dashboard-card">
            <h3>Pending Questions</h3>
            <p>View and answer customer questions</p>
            <a href="questions.jsp">View Questions</a>
        </div>
        
        <div class="dashboard-card">
            <h3>Manage Auctions</h3>
            <p>Remove inappropriate auctions</p>
            <a href="manage-auctions.jsp">View Auctions</a>
        </div>
        
        <div class="dashboard-card">
            <h3>Reset Passwords</h3>
            <p>Help users with account issues</p>
            <a href="reset-password.jsp">User Management</a>
        </div>
    </div>
</body>
</html>