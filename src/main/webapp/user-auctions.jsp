<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>

<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect("login");
        return;
    }

    String userIDParam = request.getParameter("userID");
    if (userIDParam == null) {
        response.sendRedirect("browse.jsp");
        return;
    }

    int targetUserID = Integer.parseInt(userIDParam);
    String targetUsername = "";
    
    // Get target user info
    Connection conn = null;
    try {
        conn = com.buyme.util.DatabaseConnection.getConnection();
        PreparedStatement userStmt = conn.prepareStatement(
            "SELECT username, userType FROM user WHERE userID = ?"
        );
        userStmt.setInt(1, targetUserID);
        ResultSet userRs = userStmt.executeQuery();
        
        if (userRs.next()) {
            targetUsername = userRs.getString("username");
        } else {
            response.sendRedirect("browse.jsp");
            return;
        }
    } catch (Exception e) {
        e.printStackTrace();
    }
    
    String viewType = request.getParameter("view");
    if (viewType == null) viewType = "all";
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= targetUsername %>'s Auctions - BuyMe</title>
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
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        
        .back-link:hover {
            text-decoration: underline;
        }
        
        .profile-header {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .profile-header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .profile-header p {
            color: #666;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
            font-weight: bold;
            color: #667eea;
        }
        
        .stat-label {
            color: #666;
            margin-top: 5px;
            font-size: 14px;
        }
        
        .tabs {
            background: white;
            padding: 20px 20px 0 20px;
            border-radius: 10px 10px 0 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            display: flex;
            gap: 10px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .tab {
            padding: 12px 24px;
            background: none;
            border: none;
            color: #666;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
            font-weight: 600;
            text-decoration: none;
            display: inline-block;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab:hover {
            color: #667eea;
        }
        
        .auctions-section {
            background: white;
            padding: 30px;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .section-title {
            color: #333;
            margin-bottom: 20px;
            font-size: 20px;
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
            font-weight: 600;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .badge-active { background: #d4edda; color: #155724; }
        .badge-closed { background: #f8d7da; color: #721c24; }
        .badge-pending { background: #fff3cd; color: #856404; }
        .badge-won { background: #d4edda; color: #155724; }
        .badge-lost { background: #f8d7da; color: #721c24; }
        .badge-winning { background: #d1ecf1; color: #0c5460; }
        .badge-outbid { background: #fff3cd; color: #856404; }
        
        .action-btn {
            background: #667eea;
            color: white;
            padding: 6px 12px;
            border-radius: 4px;
            text-decoration: none;
            font-size: 13px;
            display: inline-block;
        }
        
        .action-btn:hover {
            background: #5568d3;
        }
        
        .no-data {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        
        .role-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 11px;
            font-weight: 600;
            margin-left: 8px;
        }
        
        .role-seller { background: #ffc107; color: #333; }
        .role-buyer { background: #17a2b8; color: white; }
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
            <span>Welcome, <%= currentUser.getUsername() %></span>
            <a href="notifications.jsp" class="logout-btn">Notifications</a>
            <a href="logout" class="logout-btn">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="browse.jsp" class="back-link">← Back to Browse</a>

    <!-- Profile Header -->
    <div class="profile-header">
        <h1>👤 <%= targetUsername %>'s Auction Activity</h1>
        <p>View all auctions this user has participated in</p>
        
        <%
            // Get statistics
            int totalAsSeller = 0;
            int totalAsBuyer = 0;
            int totalWon = 0;
            int activeBids = 0;
            
            try {
                // Count as seller
                PreparedStatement sellerStmt = conn.prepareStatement(
                    "SELECT COUNT(*) FROM auction WHERE sellerID = ?"
                );
                sellerStmt.setInt(1, targetUserID);
                ResultSet sellerRs = sellerStmt.executeQuery();
                if (sellerRs.next()) totalAsSeller = sellerRs.getInt(1);
                
                // Count as buyer (participated auctions)
                PreparedStatement buyerStmt = conn.prepareStatement(
                    "SELECT COUNT(DISTINCT auctionID) FROM bid WHERE buyerID = ?"
                );
                buyerStmt.setInt(1, targetUserID);
                ResultSet buyerRs = buyerStmt.executeQuery();
                if (buyerRs.next()) totalAsBuyer = buyerRs.getInt(1);
                
                // Count wins
                PreparedStatement wonStmt = conn.prepareStatement(
                    "SELECT COUNT(*) FROM auction WHERE winnerID = ? AND status = 'closed'"
                );
                wonStmt.setInt(1, targetUserID);
                ResultSet wonRs = wonStmt.executeQuery();
                if (wonRs.next()) totalWon = wonRs.getInt(1);
                
                // Count active bids
                PreparedStatement activeStmt = conn.prepareStatement(
                    "SELECT COUNT(*) FROM bid b " +
                    "JOIN auction a ON b.auctionID = a.auctionID " +
                    "WHERE b.buyerID = ? AND a.status = 'active'"
                );
                activeStmt.setInt(1, targetUserID);
                ResultSet activeRs = activeStmt.executeQuery();
                if (activeRs.next()) activeBids = activeRs.getInt(1);
        %>
        
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-number"><%= totalAsSeller %></div>
                <div class="stat-label">Auctions Created</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= totalAsBuyer %></div>
                <div class="stat-label">Auctions Participated</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= totalWon %></div>
                <div class="stat-label">Auctions Won</div>
            </div>
            <div class="stat-card">
                <div class="stat-number"><%= activeBids %></div>
                <div class="stat-label">Active Bids</div>
            </div>
        </div>
        
        <%
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
    </div>

    <!-- Tabs -->
    <div class="tabs">
        <a href="user-auctions.jsp?userID=<%= targetUserID %>&view=all" 
           class="tab <%= "all".equals(viewType) ? "active" : "" %>">
            All Activity
        </a>
        <a href="user-auctions.jsp?userID=<%= targetUserID %>&view=selling" 
           class="tab <%= "selling".equals(viewType) ? "active" : "" %>">
            As Seller
        </a>
        <a href="user-auctions.jsp?userID=<%= targetUserID %>&view=buying" 
           class="tab <%= "buying".equals(viewType) ? "active" : "" %>">
            As Buyer
        </a>
        <a href="user-auctions.jsp?userID=<%= targetUserID %>&view=won" 
           class="tab <%= "won".equals(viewType) ? "active" : "" %>">
            Won Auctions
        </a>
    </div>

    <!-- Auctions Section -->
    <div class="auctions-section">
        <%
            SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy HH:mm");
            
            try {
                String sql = "";
                PreparedStatement pstmt = null;
                
                if ("all".equals(viewType)) {
                    // Show all auctions (as seller OR buyer)
                    sql = "SELECT DISTINCT a.auctionID, a.currentPrice, a.status, a.closeDateTime, " +
                          "i.itemName, " +
                          "CASE " +
                          "  WHEN a.sellerID = ? THEN 'seller' " +
                          "  ELSE 'buyer' " +
                          "END as userRole, " +
                          "CASE " +
                          "  WHEN a.winnerID = ? AND a.status = 'closed' THEN 'won' " +
                          "  WHEN b.isWinning = TRUE AND a.status = 'active' THEN 'winning' " +
                          "  WHEN b.buyerID = ? AND a.status = 'active' THEN 'outbid' " +
                          "  WHEN a.status = 'closed' THEN 'lost' " +
                          "  ELSE 'participated' " +
                          "END as bidStatus, " +
                          "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as totalBids " +
                          "FROM auction a " +
                          "JOIN item i ON a.itemID = i.itemID " +
                          "LEFT JOIN bid b ON a.auctionID = b.auctionID AND b.buyerID = ? " +
                          "WHERE (a.sellerID = ? OR b.buyerID = ?) " +
                          "ORDER BY a.closeDateTime DESC";
                    
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, targetUserID);
                    pstmt.setInt(2, targetUserID);
                    pstmt.setInt(3, targetUserID);
                    pstmt.setInt(4, targetUserID);
                    pstmt.setInt(5, targetUserID);
                    pstmt.setInt(6, targetUserID);
                    
                } else if ("selling".equals(viewType)) {
                    // Show auctions where user is seller
                    sql = "SELECT a.auctionID, a.currentPrice, a.status, a.closeDateTime, " +
                          "i.itemName, 'seller' as userRole, " +
                          "(SELECT username FROM user WHERE userID = a.winnerID) as winnerName, " +
                          "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as totalBids " +
                          "FROM auction a " +
                          "JOIN item i ON a.itemID = i.itemID " +
                          "WHERE a.sellerID = ? " +
                          "ORDER BY a.closeDateTime DESC";
                    
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, targetUserID);
                    
                } else if ("buying".equals(viewType)) {
                    // Show auctions where user placed bids
                    sql = "SELECT DISTINCT a.auctionID, a.currentPrice, a.status, a.closeDateTime, " +
                          "i.itemName, 'buyer' as userRole, " +
                          "b.bidAmount as userBid, b.isWinning, " +
                          "CASE " +
                          "  WHEN a.winnerID = ? AND a.status = 'closed' THEN 'won' " +
                          "  WHEN b.isWinning = TRUE AND a.status = 'active' THEN 'winning' " +
                          "  WHEN b.buyerID = ? AND a.status = 'active' THEN 'outbid' " +
                          "  WHEN a.status = 'closed' THEN 'lost' " +
                          "  ELSE 'participated' " +
                          "END as bidStatus, " +
                          "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID AND buyerID = ?) as userBidCount " +
                          "FROM auction a " +
                          "JOIN item i ON a.itemID = i.itemID " +
                          "JOIN bid b ON a.auctionID = b.auctionID " +
                          "WHERE b.buyerID = ? " +
                          "ORDER BY a.closeDateTime DESC";
                    
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, targetUserID);
                    pstmt.setInt(2, targetUserID);
                    pstmt.setInt(3, targetUserID);
                    pstmt.setInt(4, targetUserID);
                    
                } else if ("won".equals(viewType)) {
                    // Show auctions won by user
                    sql = "SELECT a.auctionID, a.currentPrice, a.status, a.closeDateTime, " +
                          "i.itemName, 'buyer' as userRole, " +
                          "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID AND buyerID = ?) as userBidCount " +
                          "FROM auction a " +
                          "JOIN item i ON a.itemID = i.itemID " +
                          "WHERE a.winnerID = ? AND a.status = 'closed' " +
                          "ORDER BY a.closeDateTime DESC";
                    
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, targetUserID);
                    pstmt.setInt(2, targetUserID);
                }
                
                ResultSet rs = pstmt.executeQuery();
                boolean hasResults = false;
        %>
        
        <table>
            <thead>
                <tr>
                    <th>Auction ID</th>
                    <th>Item Name</th>
                    <% if ("all".equals(viewType)) { %>
                    <th>Role</th>
                    <% } %>
                    <th>Current/Final Price</th>
                    <% if ("buying".equals(viewType) || "all".equals(viewType)) { %>
                    <th>Status</th>
                    <% } %>
                    <% if ("selling".equals(viewType)) { %>
                    <th>Total Bids</th>
                    <th>Winner</th>
                    <% } %>
                    <th>Auction Status</th>
                    <th>Closes/Closed</th>
                    <th>Action</th>
                </tr>
            </thead>
            <tbody>
                <%
                    while (rs.next()) {
                        hasResults = true;
                        int auctionID = rs.getInt("auctionID");
                        String itemName = rs.getString("itemName");
                        double currentPrice = rs.getDouble("currentPrice");
                        String status = rs.getString("status");
                        Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                        String userRole = rs.getString("userRole");
                %>
                <tr>
                    <td>#<%= auctionID %></td>
                    <td><strong><%= itemName %></strong></td>
                    
                    <% if ("all".equals(viewType)) { %>
                    <td>
                        <span class="role-badge role-<%= userRole %>">
                            <%= userRole.toUpperCase() %>
                        </span>
                    </td>
                    <% } %>
                    
                    <td>$<%= String.format("%.2f", currentPrice) %></td>
                    
                    <% if ("buying".equals(viewType) || ("all".equals(viewType) && "buyer".equals(userRole))) { %>
                    <td>
                        <%
                            String bidStatus = "participated";
                            try {
                                bidStatus = rs.getString("bidStatus");
                            } catch (Exception e) {}
                        %>
                        <span class="badge badge-<%= bidStatus %>">
                            <%= bidStatus.toUpperCase() %>
                        </span>
                    </td>
                    <% } %>
                    
                    <% if ("selling".equals(viewType)) { %>
                    <td>
                        <%
                            int totalBids = rs.getInt("totalBids");
                        %>
                        <%= totalBids %> bid<%= totalBids != 1 ? "s" : "" %>
                    </td>
                    <td>
                        <%
                            String winnerName = rs.getString("winnerName");
                        %>
                        <%= winnerName != null ? winnerName : "-" %>
                    </td>
                    <% } %>
                    
                    <td>
                        <span class="badge badge-<%= status %>">
                            <%= status.toUpperCase() %>
                        </span>
                    </td>
                    
                    <td><%= sdf.format(closeDateTime) %></td>
                    
                    <td>
                        <a href="auction-details.jsp?id=<%= auctionID %>" class="action-btn">
                            View Details
                        </a>
                    </td>
                </tr>
                <%
                    }
                    
                    if (!hasResults) {
                %>
                <tr>
                    <td colspan="10" class="no-data">
                        <h3>No auctions found</h3>
                        <p>This user hasn't participated in any auctions in this category yet.</p>
                    </td>
                </tr>
                <%
                    }
                %>
            </tbody>
        </table>
        
        <%
            } catch (Exception e) {
                e.printStackTrace();
                out.println("<div class='no-data' style='color: red;'>Error loading auctions: " + e.getMessage() + "</div>");
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        %>
    </div>
</div>

</body>
</html>
