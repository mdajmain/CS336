<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%
    // Check if user is logged in
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BuyMe - Dashboard</title>
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
            transition: background 0.3s;
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
            cursor: pointer;
            text-decoration: none;
        }
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .welcome-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .action-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .action-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            text-align: center;
        }
        
        .action-card h3 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .action-card p {
            color: #666;
            margin-bottom: 15px;
        }
        
        .action-card a {
            display: inline-block;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 10px 25px;
            border-radius: 5px;
            text-decoration: none;
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
			    <li><a href="questions.jsp">Support</a></li>
                
                
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
                <a href="notifications.jsp" class="logout-btn" style="margin-left: 15px;">Notifications</a>
                
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="welcome-section">
            <h1>Welcome to BuyMe!</h1>
            <p>Start buying and selling in our online auction marketplace</p>
        </div>
        
        <div class="action-cards">
            <div class="action-card">
                <h3>Browse Auctions</h3>
                <p>Find great deals on items</p>
                <a href="browse.jsp">Start Browsing</a>
            </div>
            
            <div class="action-card">
                <h3>Sell an Item</h3>
                <p>Create your own auction</p>
                <a href="create-auction.jsp">Create Auction</a>
            </div>
            
            <div class="action-card">
                <h3>My Bids</h3>
                <p>Track your bidding activity</p>
                <a href="my-bids.jsp">View Bids</a>
            </div>
            
            <div class="action-card">
                <h3>My Account</h3>
                <p>Manage your profile</p>
                <a href="account.jsp">View Account</a>
            </div>
            <div class="action-card">
			    <h3>Support & Q&A</h3>
			    <p>Ask questions and get help</p>
			    <a href="questions.jsp">Get Support</a>
			</div>
        </div>
    </div>
</body>
</html>