<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    // Get statistics for dashboard
    int openQuestions = 0;
    int activeAuctions = 0;
    int totalUsers = 0;
    int pendingIssues = 0;
    
    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
        // Count open questions
        try (PreparedStatement ps1 = conn.prepareStatement(
            "SELECT COUNT(*) FROM question WHERE status = 'open'");
             ResultSet rs1 = ps1.executeQuery()) {
            if (rs1.next()) openQuestions = rs1.getInt(1);
        }
        
        // Count active auctions
        activeAuctions = new com.buyme.dao.AuctionDAO().countActiveAuctions();
        
        // Count total end users
        try (PreparedStatement ps3 = conn.prepareStatement(
            "SELECT COUNT(*) FROM user WHERE userType = 'end_user'");
             ResultSet rs3 = ps3.executeQuery()) {
            if (rs3.next()) totalUsers = rs3.getInt(1);
        }
        
        // Count questions that need attention
        try (PreparedStatement ps4 = conn.prepareStatement(
            "SELECT COUNT(*) FROM question WHERE status = 'open' OR status = 'answered'");
             ResultSet rs4 = ps4.executeQuery()) {
            if (rs4.next()) pendingIssues = rs4.getInt(1);
        }
        
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Rep Dashboard - BuyMe</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; min-height: 100vh; }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-container h2 { font-weight: 600; }
        .nav-right { display: flex; align-items: center; gap: 20px; }
        .nav-right span { opacity: 0.9; }
        .logout-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid rgba(255,255,255,0.5);
            padding: 8px 20px;
            border-radius: 5px;
            text-decoration: none;
            transition: all 0.3s;
        }
        .logout-btn:hover { background: rgba(255,255,255,0.3); }
        
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        
        .welcome-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        .welcome-section h1 { color: #333; margin-bottom: 10px; }
        .welcome-section p { color: #666; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
        .stat-card .number {
            font-size: 36px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-card .label {
            color: #666;
            margin-top: 5px;
        }
        .stat-card.urgent .number { color: #e74c3c; }
        .stat-card.success .number { color: #27ae60; }
        
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .dashboard-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            transition: transform 0.3s, box-shadow 0.3s;
        }
        .dashboard-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 20px rgba(0,0,0,0.15);
        }
        .dashboard-card h3 {
            color: #333;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .dashboard-card h3 .icon {
            width: 40px;
            height: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 18px;
        }
        .dashboard-card p {
            color: #666;
            margin-bottom: 15px;
            line-height: 1.5;
        }
        .dashboard-card .btn {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 20px;
            border-radius: 5px;
            text-decoration: none;
            transition: opacity 0.3s;
        }
        .dashboard-card .btn:hover { opacity: 0.9; }
        .dashboard-card .badge {
            background: #e74c3c;
            color: white;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 12px;
            margin-left: 10px;
        }
        
        .quick-actions {
            margin-top: 30px;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .quick-actions h3 { margin-bottom: 15px; color: #333; }
        .action-buttons { display: flex; gap: 10px; flex-wrap: wrap; }
        .action-btn {
            padding: 10px 20px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 5px;
            text-decoration: none;
            transition: all 0.3s;
        }
        .action-btn:hover {
            background: #667eea;
            color: white;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>Customer Representative Panel</h2>
            <div class="nav-right">
                <span>Welcome, <strong><%= user.getUsername() %></strong></span>
                <a href="<%= request.getContextPath() %>/logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="welcome-section">
            <h1>Customer Representative Dashboard</h1>
            <p>Manage customer inquiries, auctions, and user accounts from this central hub.</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card urgent">
                <div class="number"><%= openQuestions %></div>
                <div class="label">Open Questions</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= activeAuctions %></div>
                <div class="label">Active Auctions</div>
            </div>
            <div class="stat-card success">
                <div class="number"><%= totalUsers %></div>
                <div class="label">Total Users</div>
            </div>
            <div class="stat-card">
                <div class="number"><%= pendingIssues %></div>
                <div class="label">Pending Issues</div>
            </div>
        </div>
        
        <div class="dashboard-grid">
            <div class="dashboard-card">
                <h3>
                    <span class="icon">?</span>
                    Customer Questions
                    <% if (openQuestions > 0) { %><span class="badge"><%= openQuestions %></span><% } %>
                </h3>
                <p>View and respond to customer inquiries. Help users with their questions about auctions, bidding, and account issues.</p>
                <a href="questions.jsp" class="btn">View Questions</a>
            </div>
            
            <div class="dashboard-card">
                <h3>
                    <span class="icon">A</span>
                    Manage Auctions
                </h3>
                <p>Monitor active auctions, remove inappropriate listings, and manage bids. Ensure all auctions comply with platform rules.</p>
                <a href="manage-auctions.jsp" class="btn">View Auctions</a>
            </div>
            
           
            
            <div class="dashboard-card">
                <h3>
                    <span class="icon">U</span>
                    User Management
                </h3>
                <p>Edit user accounts, reset passwords, and manage user information. Help users with account-related issues.</p>
                <a href="manage-users.jsp" class="btn">Manage Users</a>
            </div>
            
            <div class="dashboard-card">
                <h3>
                    <span class="icon">P</span>
                    Reset Passwords
                </h3>
                <p>Quick access to reset user passwords. Help users who are locked out of their accounts.</p>
                <a href="reset-password.jsp" class="btn">Reset Password</a>
            </div>
            
            <div class="dashboard-card">
                <h3>
                    <span class="icon">S</span>
                    Search Users
                </h3>
                <p>Search for users by username, email, or other criteria. Quickly find user accounts to assist with issues.</p>
                <a href="search-users.jsp" class="btn">Search Users</a>
            </div>
        </div>
        
        <div class="quick-actions">
            <h3>Quick Actions</h3>
            <div class="action-buttons">
                <a href="questions.jsp?filter=open" class="action-btn">View Open Questions</a>
                <a href="manage-auctions.jsp?filter=active" class="action-btn">Active Auctions</a>
                <a href="manage-users.jsp?filter=suspended" class="action-btn">Suspended Users</a>
                <a href="<%= request.getContextPath() %>/index.jsp" class="action-btn">View Main Site</a>
            </div>
        </div>
    </div>
</body>
</html>
