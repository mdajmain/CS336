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
    <title>My Bids - BuyMe</title>
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
        
        .bids-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        
        
        h1 {
            color: #333;
            margin-bottom: 30px;
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
        
        .status-winning {
            background: #d4edda;
            color: #155724;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .status-lost {
		    background: #e2e3e5;
		    color: #383d41;
		    padding: 4px 8px;
		    border-radius: 4px;
		    font-size: 12px;
		}
		
        .status-outbid {
            background: #f8d7da;
            color: #721c24;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .status-won {
            background: #cce5ff;
            color: #004085;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .view-btn {
            background: #007bff;
            color: white;
            padding: 5px 10px;
            border-radius: 4px;
            text-decoration: none;
            font-size: 14px;
        }
        
        .no-bids {
            text-align: center;
            padding: 60px;
            color: #999;
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
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="bids-section">
            <h1>My Bids</h1>
            
            <div class="tabs">
                <button class="tab active" onclick="showTab('active')">Active Bids</button>
                <button class="tab" onclick="showTab('won')">Won Auctions</button>
                <button class="tab" onclick="showTab('lost')">Lost Auctions</button>
            </div>
            
            <div id="active-bids">
                <h3 style="margin-bottom: 20px;">Active Bids</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Item</th>
                            <th>Current Price</th>
                            <th>Your Bid</th>
                            <th>Max Bid</th>
                            <th>Status</th>
                            <th>Ends</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                String sql = "SELECT b.*, a.currentPrice, a.closeDateTime, i.itemName, " +
                                           "(b.isWinning) as winning " +
                                           "FROM bid b " +
                                           "JOIN auction a ON b.auctionID = a.auctionID " +
                                           "JOIN item i ON a.itemID = i.itemID " +
                                           "WHERE b.buyerID = ? AND a.status = 'active' " +
                                           "ORDER BY a.closeDateTime ASC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                pstmt.setInt(1, user.getUserID());
                                ResultSet rs = pstmt.executeQuery();
                                
                                boolean hasActiveBids = false;
                                while(rs.next()) {
                                    hasActiveBids = true;
                                    boolean isWinning = rs.getBoolean("winning");
                        %>
                        <tr>
                            <td><strong><%= rs.getString("itemName") %></strong></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("bidAmount")) %></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("maxBidLimit")) %></td>
                            <td>
                                <% if (isWinning) { %>
                                    <span class="status-winning">WINNING</span>
                                <% } else { %>
                                    <span class="status-outbid">OUTBID</span>
                                <% } %>
                            </td>
                            <td><%= rs.getTimestamp("closeDateTime") %></td>
                            <td><a href="auction-details.jsp?id=<%= rs.getInt("auctionID") %>" class="view-btn">View</a></td>
                        </tr>
                        <%
                                }
                                
                                if (!hasActiveBids) {
                                    out.println("<tr><td colspan='7' class='no-bids'>You have no active bids</td></tr>");
                                }
                                
                                conn.close();
                            } catch(Exception e) {
                                e.printStackTrace();
                                out.println("<tr><td colspan='7'>Error loading bids</td></tr>");
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
            <div id="won-bids" style="display: none;">
                <h3 style="margin-bottom: 20px;">Won Auctions</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Item</th>
                            <th>Final Price</th>
                            <th>Won Date</th>
                            <th>Seller</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                String sql = "SELECT a.*, i.itemName, u.username as sellerName " +
                                           "FROM auction a " +
                                           "JOIN item i ON a.itemID = i.itemID " +
                                           "JOIN user u ON a.sellerID = u.userID " +
                                           "WHERE a.winnerID = ? AND a.status = 'closed' " +
                                           "ORDER BY a.closeDateTime DESC";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                pstmt.setInt(1, user.getUserID());
                                ResultSet rs = pstmt.executeQuery();
                                
                                boolean hasWonAuctions = false;
                                while(rs.next()) {
                                    hasWonAuctions = true;
                        %>
                        <tr>
                            <td><strong><%= rs.getString("itemName") %></strong></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
                            <td><%= rs.getTimestamp("closeDateTime") %></td>
                            <td><%= rs.getString("sellerName") %></td>
                            <td><span class="status-won">WON</span></td>
                        </tr>
                        <%
                                }
                                
                                if (!hasWonAuctions) {
                                    out.println("<tr><td colspan='5' class='no-bids'>You haven't won any auctions yet</td></tr>");
                                }
                                
                                conn.close();
                            } catch(Exception e) {
                                e.printStackTrace();
                            }
                        %>
                    </tbody>
                </table>
            </div>
                        <div id="lost-bids" style="display: none;">
                <h3 style="margin-bottom: 20px;">Lost Auctions</h3>
                <table>
                    <thead>
                        <tr>
                            <th>Item</th>
                            <th>Final Price</th>
                            <th>Ended</th>
                            <th>Seller</th>
                            <th>Status</th>
                            <th>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        <%
                            try {
                                Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                String sql =
                                    "SELECT a.*, i.itemName, u.username AS sellerName " +
                                    "FROM auction a " +
                                    "JOIN item i ON a.itemID = i.itemID " +
                                    "JOIN user u ON a.sellerID = u.userID " +
                                    "WHERE a.status = 'closed' " +
                                    "  AND a.auctionID IN (SELECT DISTINCT auctionID FROM bid_history WHERE buyerID = ?) " +
                                    "  AND (a.winnerID IS NULL OR a.winnerID <> ?) " +
                                    "ORDER BY a.closeDateTime DESC";

                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                pstmt.setInt(1, user.getUserID());
                                pstmt.setInt(2, user.getUserID());
                                ResultSet rs = pstmt.executeQuery();

                                boolean hasLost = false;
                                while (rs.next()) {
                                    hasLost = true;
                        %>
                        <tr>
                            <td><strong><%= rs.getString("itemName") %></strong></td>
                            <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
                            <td><%= rs.getTimestamp("closeDateTime") %></td>
                            <td><%= rs.getString("sellerName") %></td>
                            <td><span class="status-lost">LOST</span></td>
                            <td><a href="auction-details.jsp?id=<%= rs.getInt("auctionID") %>" class="view-btn">View</a></td>
                        </tr>
                        <%
                                }

                                if (!hasLost) {
                                    out.println("<tr><td colspan='6' class='no-bids'>You have no lost auctions</td></tr>");
                                }

                                conn.close();
                            } catch (Exception e) {
                                e.printStackTrace();
                                out.println("<tr><td colspan='6'>Error loading lost auctions</td></tr>");
                            }
                        %>
                    </tbody>
                </table>
            </div>
            
        </div>
    </div>
    
    
    <script>
        function showTab(tab) {
            document.getElementById('active-bids').style.display = tab === 'active' ? 'block' : 'none';
            document.getElementById('won-bids').style.display = tab === 'won' ? 'block' : 'none';
            document.getElementById('lost-bids').style.display   = (tab === 'lost')   ? 'block' : 'none';
            
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
        }
    </script>
</body>
</html>
