<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
    
    // Load full user details
    Connection conn = null;
    try {
        conn = com.buyme.util.DatabaseConnection.getConnection();
        PreparedStatement pstmt = conn.prepareStatement(
            "SELECT u.*, e.* FROM user u " +
            "LEFT JOIN end_user e ON u.userID = e.userID " +
            "WHERE u.userID = ?"
        );
        pstmt.setInt(1, user.getUserID());
        ResultSet rs = pstmt.executeQuery();
        
        if (rs.next()) {
            user.setFirstName(rs.getString("firstName"));
            user.setLastName(rs.getString("lastName"));
            user.setAddress(rs.getString("address"));
            user.setPhone(rs.getString("phone"));
            user.setAnonymous(rs.getBoolean("isAnonymous"));
        }
    } catch(Exception e) {
        e.printStackTrace();
    } finally {
        if (conn != null) conn.close();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Account - BuyMe</title>
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
            max-width: 800px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .account-container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .info-section {
            margin-bottom: 30px;
        }
        
        .info-section h3 {
            color: #667eea;
            margin-bottom: 20px;
        }
        
        .info-row {
            display: flex;
            padding: 10px 0;
            border-bottom: 1px solid #f0f0f0;
        }
        
        .info-label {
            flex: 0 0 200px;
            color: #666;
            font-weight: 500;
        }
        
        .info-value {
            flex: 1;
            color: #333;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .stat-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        
        .stat-number {
            font-size: 32px;
            color: #667eea;
            font-weight: bold;
        }
        
        .stat-label {
            color: #666;
            margin-top: 5px;
        }
        
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-right: 10px;
            margin-top: 20px;
        }
        
        .btn-secondary {
            background: #6c757d;
        }
        
        .anonymous-badge {
            background: #ffc107;
            color: #333;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
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
        <div class="account-container">
            <h1>My Account</h1>
            
            <div class="info-section">
                <h3>Account Information</h3>
                
                <div class="info-row">
                    <div class="info-label">Username:</div>
                    <div class="info-value">
                        <%= user.getUsername() %>
                        <% if (user.isAnonymous()) { %>
                            <span class="anonymous-badge">Anonymous Mode</span>
                        <% } %>
                    </div>
                </div>
                
                <div class="info-row">
                    <div class="info-label">Email:</div>
                    <div class="info-value"><%= user.getEmail() %></div>
                </div>
                
                <div class="info-row">
                    <div class="info-label">Account Type:</div>
                    <div class="info-value"><%= user.getUserType().replace("_", " ").toUpperCase() %></div>
                </div>
                
                <div class="info-row">
                    <div class="info-label">Member Since:</div>
                    <div class="info-value"><%= user.getCreatedDate() %></div>
                </div>
            </div>
            
            <div class="info-section">
                <h3>Personal Information</h3>
                
                <div class="info-row">
                    <div class="info-label">Name:</div>
                    <div class="info-value">
                        <%= user.getFirstName() != null ? user.getFirstName() : "" %>
                        <%= user.getLastName() != null ? user.getLastName() : "" %>
                    </div>
                </div>
                
                <div class="info-row">
                    <div class="info-label">Address:</div>
                    <div class="info-value"><%= user.getAddress() != null ? user.getAddress() : "Not provided" %></div>
                </div>
                
                <div class="info-row">
                    <div class="info-label">Phone:</div>
                    <div class="info-value"><%= user.getPhone() != null ? user.getPhone() : "Not provided" %></div>
                </div>
            </div>
            
            <div class="info-section">
                <h3>Account Statistics</h3>
                
                <div class="stats-grid">
                    <%
                        int auctionsCreated = 0, activeBids = 0, auctionsWon = 0;
                        try {
                            conn = com.buyme.util.DatabaseConnection.getConnection();
                            
                            // Count auctions created
                            PreparedStatement pstmt = conn.prepareStatement("SELECT COUNT(*) FROM auction WHERE sellerID = ?");
                            pstmt.setInt(1, user.getUserID());
                            ResultSet rs = pstmt.executeQuery();
                            if (rs.next()) auctionsCreated = rs.getInt(1);
                            
                            // Count active bids
                            pstmt = conn.prepareStatement("SELECT COUNT(*) FROM bid b JOIN auction a ON b.auctionID = a.auctionID WHERE b.buyerID = ? AND a.status = 'active'");
                            pstmt.setInt(1, user.getUserID());
                            rs = pstmt.executeQuery();
                            if (rs.next()) activeBids = rs.getInt(1);
                            
                            // Count auctions won
                            pstmt = conn.prepareStatement("SELECT COUNT(*) FROM auction WHERE winnerID = ? AND status = 'closed'");
                            pstmt.setInt(1, user.getUserID());
                            rs = pstmt.executeQuery();
                            if (rs.next()) auctionsWon = rs.getInt(1);
                            
                            conn.close();
                        } catch(Exception e) {
                            e.printStackTrace();
                        }
                    %>
                    
                    <div class="stat-card">
                        <div class="stat-number"><%= auctionsCreated %></div>
                        <div class="stat-label">Auctions Created</div>
                    </div>
                    
                    <div class="stat-card">
                        <div class="stat-number"><%= activeBids %></div>
                        <div class="stat-label">Active Bids</div>
                    </div>
                    
                    <div class="stat-card">
                        <div class="stat-number"><%= auctionsWon %></div>
                        <div class="stat-label">Auctions Won</div>
                    </div>
                </div>
            </div>
            
            <a href="edit-account.jsp" class="btn">Edit Profile</a>
            <a href="change-password.jsp" class="btn btn-secondary">Change Password</a>
        </div>
    </div>
</body>
</html>
