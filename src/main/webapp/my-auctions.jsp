<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");

    String success = (String) request.getAttribute("success");
    String error = (String) request.getAttribute("error");

    String filterStatus = request.getParameter("status");
    if (filterStatus == null || filterStatus.isEmpty()) {
        filterStatus = "all";
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>My Auctions - BuyMe</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

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
            margin-bottom: 10px;
        }

        .page-subtitle {
            color: #666;
            margin-bottom: 20px;
        }

        .alert {
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
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

        .filters {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .filters a {
            padding: 8px 15px;
            border-radius: 20px;
            border: 1px solid #ddd;
            text-decoration: none;
            color: #555;
            font-size: 14px;
        }

        .filters a.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 2px 10px rgba(0,0,0,0.05);
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
            font-size: 14px;
        }

        tr:hover {
            background: #f8f9fa;
        }

        .status-badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }

        .status-active {
            background: #d4edda;
            color: #155724;
        }

        .status-pending {
            background: #fff3cd;
            color: #856404;
        }

        .status-closed {
            background: #cce5ff;
            color: #004085;
        }

        .status-cancelled {
            background: #f8d7da;
            color: #721c24;
        }

        .action-btn {
            display: inline-block;
            padding: 5px 10px;
            border-radius: 4px;
            font-size: 13px;
            text-decoration: none;
            margin-right: 5px;
        }

        .btn-view {
            background: #007bff;
            color: white;
        }

        .btn-edit {
            background: #17a2b8;
            color: white;
        }

        .btn-end {
            background: #dc3545;
            color: white;
        }

        .no-auctions {
            text-align: center;
            padding: 40px;
            color: #777;
            background: white;
            border-radius: 10px;
            margin-top: 10px;
        }

        .no-auctions a {
            color: #667eea;
            text-decoration: none;
        }

        .summary-bar {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 20px;
        }

        .summary-item {
            background: white;
            padding: 10px 15px;
            border-radius: 8px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.05);
            font-size: 14px;
        }

        .summary-item strong {
            font-size: 16px;
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
    <p class="page-subtitle">See and manage all items you are selling</p>

    <% if (success != null) { %>
        <div class="alert alert-success"><%= success %></div>
    <% } %>
    <% if (error != null) { %>
        <div class="alert alert-error"><%= error %></div>
    <% } %>

    <%
        // Summary counts
        int total = 0, active = 0, pending = 0, closed = 0, cancelled = 0;
        Connection summaryConn = null;
        try {
            summaryConn = com.buyme.util.DatabaseConnection.getConnection();
            PreparedStatement psSum = summaryConn.prepareStatement(
                "SELECT status, COUNT(*) AS cnt " +
                "FROM auction WHERE sellerID = ? GROUP BY status"
            );
            psSum.setInt(1, user.getUserID());
            ResultSet rsSum = psSum.executeQuery();
            while (rsSum.next()) {
                String st = rsSum.getString("status");
                int c = rsSum.getInt("cnt");
                total += c;
                if ("active".equals(st)) active = c;
                else if ("pending".equals(st)) pending = c;
                else if ("closed".equals(st)) closed = c;
                else if ("cancelled".equals(st)) cancelled = c;
            }
            summaryConn.close();
        } catch (Exception e) {
            if (summaryConn != null) summaryConn.close();
        }
    %>

    <div class="summary-bar">
        <div class="summary-item">
            <strong><%= total %></strong> total auctions
        </div>
        <div class="summary-item">
            <strong><%= active %></strong> active
        </div>
        <div class="summary-item">
            <strong><%= pending %></strong> pending
        </div>
        <div class="summary-item">
            <strong><%= closed %></strong> closed
        </div>
        <div class="summary-item">
            <strong><%= cancelled %></strong> cancelled
        </div>
    </div>

    <!-- Filters -->
    <div class="filters">
        <a href="my-auctions.jsp?status=all" class="<%= "all".equals(filterStatus) ? "active" : "" %>">All</a>
        <a href="my-auctions.jsp?status=active" class="<%= "active".equals(filterStatus) ? "active" : "" %>">Active</a>
        <a href="my-auctions.jsp?status=pending" class="<%= "pending".equals(filterStatus) ? "active" : "" %>">Pending</a>
        <a href="my-auctions.jsp?status=closed" class="<%= "closed".equals(filterStatus) ? "active" : "" %>">Closed</a>
        <a href="my-auctions.jsp?status=cancelled" class="<%= "cancelled".equals(filterStatus) ? "active" : "" %>">Cancelled</a>
    </div>

    <table>
        <thead>
        <tr>
            <th>Item</th>
            <th>Current Price</th>
            <th>Bids</th>
            <th>Status</th>
            <th>Ends</th>
            <th>Winner</th>
            <th>Actions</th>
        </tr>
        </thead>
        <tbody>
        <%
            Connection conn = null;
            try {
                conn = com.buyme.util.DatabaseConnection.getConnection();

                StringBuilder sql = new StringBuilder(
                    "SELECT a.auctionID, a.currentPrice, a.status, a.closeDateTime, a.winnerID, " +
                    "       i.itemName, " +
                    "       (SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) AS bidCount, " +
                    "       u2.username AS winnerName " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "LEFT JOIN user u2 ON a.winnerID = u2.userID " +
                    "WHERE a.sellerID = ? "
                );

                if (!"all".equals(filterStatus)) {
                    sql.append("AND a.status = ? ");
                }

                sql.append("ORDER BY a.closeDateTime DESC");

                PreparedStatement pstmt = conn.prepareStatement(sql.toString());
                pstmt.setInt(1, user.getUserID());
                if (!"all".equals(filterStatus)) {
                    pstmt.setString(2, filterStatus);
                }

                ResultSet rs = pstmt.executeQuery();
                boolean hasRows = false;

                while (rs.next()) {
                    hasRows = true;
                    String status = rs.getString("status");
                    String statusClass = "status-badge ";
                    if ("active".equals(status)) statusClass += "status-active";
                    else if ("pending".equals(status)) statusClass += "status-pending";
                    else if ("closed".equals(status)) statusClass += "status-closed";
                    else if ("cancelled".equals(status)) statusClass += "status-cancelled";
        %>
        <tr>
            <td><strong><%= rs.getString("itemName") %></strong></td>
            <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
            <td><%= rs.getInt("bidCount") %></td>
            <td><span class="<%= statusClass %>"><%= status.toUpperCase() %></span></td>
            <td><%= rs.getTimestamp("closeDateTime") %></td>
            <td><%= rs.getString("winnerName") != null ? rs.getString("winnerName") : "-" %></td>
            <td>
                <a href="auction-details.jsp?id=<%= rs.getInt("auctionID") %>" class="action-btn btn-view">View</a>

                <% if ("pending".equals(status)) { %>
                    <a href="edit-auction.jsp?id=<%= rs.getInt("auctionID") %>" class="action-btn btn-edit">Edit</a>
                <% } %>

                <% if ("active".equals(status)) { %>
                    <a href="seller-close-auction.jsp?id=<%= rs.getInt("auctionID") %>"
                       class="action-btn btn-end"
                       onclick="return confirm('End this auction now and sell at the current highest bid?');">
                        End now
                    </a>
                <% } %>
            </td>
        </tr>
        <%
                }

                if (!hasRows) {
        %>
        <tr>
            <td colspan="7">
                <div class="no-auctions">
                    <h3>No auctions found</h3>
                    <p>You are not selling anything right now.  
                       <a href="create-auction.jsp">Create a new auction</a></p>
                </div>
            </td>
        </tr>
        <%
                }

                conn.close();
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <tr>
            <td colspan="7" style="color: red; padding: 20px;">
                Error loading your auctions: <%= e.getMessage() %>
            </td>
        </tr>
        <%
            } finally {
                if (conn != null) try { conn.close(); } catch (SQLException ignore) {}
            }
        %>
        </tbody>
    </table>
</div>
</body>
</html>
