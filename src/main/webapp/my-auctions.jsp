<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
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
    <title>My Auctions - BuyMe</title>
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
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
        }
        
        .create-btn {
            display: inline-block;
            padding: 10px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 30px;
        }
        
        .auctions-table {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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
        
        .status-active {
            background: #d4edda;
            color: #155724;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .status-closed {
            background: #f8d7da;
            color: #721c24;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .action-btn {
            background: #007bff;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            text-decoration: none;
            font-size: 14px;
            margin-right: 5px;
        }
        
        .delete-btn {
            background: #dc3545;
        }
        
        .no-auctions {
            text-align: center;
            padding: 60px;
            color: #999;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .tab {
            padding: 10px 20px;
            background: none;
            border: none;
            color: #666;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
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
                <li><a href="my-auctions.jsp">My Auctions</a></li>
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <h1>My Auctions</h1>
        
        <% if (request.getAttribute("success") != null) { %>
            <div class="success"><%= request.getAttribute("success") %></div>
        <% } %>
        
        <a href="create-auction.jsp" class="create-btn">Create New Auction</a>
        
        <div class="auctions-table">
            <div class="tabs">
                <button class="tab active" onclick="showTab('all')">All Auctions</button>
                <button class="tab" onclick="showTab('active')">Active</button>
                <button class="tab" onclick="showTab('closed')">Closed</button>
            </div>
            
            <table id="all-auctions">
                <thead>
                    <tr>
                        <th>Item Name</th>
                        <th>Current Price</th>
                        <th>Bids</th>
                        <th>Status</th>
                        <th>Ends/Ended</th>
                        <th>Winner</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                            String sql = "SELECT a.*, i.itemName, " +
                                       "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount, " +
                                       "(SELECT username FROM user WHERE userID = a.winnerID) as winnerName " +
                                       "FROM auction a " +
                                       "JOIN item i ON a.itemID = i.itemID " +
                                       "WHERE a.sellerID = ? " +
                                       "ORDER BY a.startDateTime DESC";
                            
                            PreparedStatement pstmt = conn.prepareStatement(sql);
                            pstmt.setInt(1, user.getUserID());
                            ResultSet rs = pstmt.executeQuery();
                            
                            boolean hasAuctions = false;
                            while(rs.next()) {
                                hasAuctions = true;
                                String status = rs.getString("status");
                                String statusClass = "status-" + status;
                                String winnerName = rs.getString("winnerName");
                    %>
                    <tr class="auction-row" data-status="<%= status %>">
                        <td><strong><%= rs.getString("itemName") %></strong></td>
                        <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
                        <td><%= rs.getInt("bidCount") %></td>
                        <td><span class="<%= statusClass %>"><%= status.toUpperCase() %></span></td>
                        <td><%= rs.getTimestamp("closeDateTime") %></td>
                        <td><%= winnerName != null ? winnerName : "-" %></td>
                        <td>
                            <a href="auction-details.jsp?id=<%= rs.getInt("auctionID") %>" class="action-btn">View</a>
                            <% if ("pending".equals(status)) { %>
                                <a href="edit-auction.jsp?id=<%= rs.getInt("auctionID") %>" class="action-btn">Edit</a>
                            <% } %>
                        </td>
                    </tr>
                    <%
                            }
                            
                            if (!hasAuctions) {
                                out.println("<tr><td colspan='7' class='no-auctions'>You haven't created any auctions yet</td></tr>");
                            }
                            
                            conn.close();
                        } catch(Exception e) {
                            e.printStackTrace();
                            out.println("<tr><td colspan='7'>Error loading auctions</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        function showTab(tab) {
            const rows = document.querySelectorAll('.auction-row');
            
            rows.forEach(row => {
                const status = row.dataset.status;
                
                if (tab === 'all') {
                    row.style.display = '';
                } else if (tab === 'active' && (status === 'active' || status === 'pending')) {
                    row.style.display = '';
                } else if (tab === 'closed' && status === 'closed') {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
            
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
        }
    </script>
</body>
</html>
