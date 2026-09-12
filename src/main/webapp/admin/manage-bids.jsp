<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();


    String message = null;
    String error = null;

    // HANDLE DELETE BID (POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String bidIdStr = request.getParameter("bidID");
        String auctionIdStr = request.getParameter("auctionID");

        if ("delete".equalsIgnoreCase(action) && bidIdStr != null && auctionIdStr != null) {
            try {
                int bidID = Integer.parseInt(bidIdStr);
                int auctionID = Integer.parseInt(auctionIdStr);

                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    conn.setAutoCommit(false);

                    try (
                        PreparedStatement delBid = conn.prepareStatement(
                            "DELETE FROM bid WHERE bidID = ?"
                        );
                        PreparedStatement topBidStmt = conn.prepareStatement(
                            "SELECT buyerID, bidAmount FROM bid WHERE auctionID = ? ORDER BY bidAmount DESC LIMIT 1"
                        )
                    ) {
                        // delete bid
                        delBid.setInt(1, bidID);
                        delBid.executeUpdate();

                        // recalc top bid
                        topBidStmt.setInt(1, auctionID);
                        try (ResultSet topRs = topBidStmt.executeQuery()) {
                            if (topRs.next()) {
                                int winnerID = topRs.getInt("buyerID");
                                double price = topRs.getDouble("bidAmount");

                                try (PreparedStatement updAuction = conn.prepareStatement(
                                    "UPDATE auction SET winnerID = ?, currentPrice = ? WHERE auctionID = ?"
                                )) {
                                    updAuction.setInt(1, winnerID);
                                    updAuction.setDouble(2, price);
                                    updAuction.setInt(3, auctionID);
                                    updAuction.executeUpdate();
                                }
                            } else {
                                // no bids left
                                try (PreparedStatement resetAuction = conn.prepareStatement(
                                    "UPDATE auction SET winnerID = NULL, currentPrice = initialPrice WHERE auctionID = ?"
                                )) {
                                    resetAuction.setInt(1, auctionID);
                                    resetAuction.executeUpdate();
                                }
                            }
                        }

                        conn.commit();
                        message = "Bid #" + bidID + " removed successfully.";
                    } catch (Exception inner) {
                        conn.rollback();
                        throw inner;
                    } finally {
                        conn.setAutoCommit(true);
                    }
                }

            } catch (NumberFormatException nfe) {
                error = "Invalid bid or auction ID.";
            } catch (Exception e) {
                e.printStackTrace();
                error = "Error removing bid: " + e.getMessage();
            }
        }
    }

    // FILTER AUCTION ID (GET)
    String filterAuction = request.getParameter("auctionID");
    if (filterAuction == null) filterAuction = "";
%>


<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Bids - Customer Rep</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px 0; color: white; }
        .nav-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .back-link { text-decoration: none; color: #667eea; display: inline-block; margin-bottom: 15px; }
        .section { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .alert { padding: 10px; border-radius: 5px; margin-bottom: 10px; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 8px; border-bottom: 1px solid #e1e1e1; text-align: left; }
        th { background: #f8f9fa; }
        .filter-form { margin-bottom: 15px; display: flex; gap: 10px; align-items: center; }
        .filter-form input { padding: 6px 8px; }
        .btn { padding: 6px 12px; border-radius: 4px; border: none; cursor: pointer; font-size: 13px; }
        .btn-danger { background: #dc3545; color: white; }
        .btn-filter { background: #007bff; color: white; }
    </style>
</head>
<body>
<nav class="navbar">
    <div class="nav-container">
        <h2>Customer Representative Panel</h2>
        <div>
            <span>Rep: <%= user.getUsername() %></span>
            <a href="<%= request.getContextPath() %>/logout" class="logout-btn" style="color:white; margin-left:15px;">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="dashboard.jsp" class="back-link">← Back to Dashboard</a>

    <div class="section">
        <h2>Manage Bids</h2>
        <p>Search bids by auction and remove inappropriate ones.</p>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <form method="get" class="filter-form">
            <label for="auctionID">Auction ID:</label>
            <input type="number" id="auctionID" name="auctionID" value="<%= filterAuction %>">
            <button type="submit" class="btn btn-filter">Filter</button>
            <a href="manage-bids.jsp" style="font-size: 13px;">Clear</a>
        </form>

        <table>
            <thead>
            <tr>
                <th>Bid ID</th>
                <th>Auction</th>
                <th>Bidder</th>
                <th>Bid Amount</th>
                <th>Max Limit</th>
                <th>Time</th>
                <th>Winning</th>
                <th>Actions</th>
            </tr>
            </thead>
            <tbody>
            <%
                if (!filterAuction.isEmpty()) {
                    try {
                        int auctionFilterId = Integer.parseInt(filterAuction);

                        String sql =
                            "SELECT b.*, u.username " +
                            "FROM bid b " +
                            "JOIN user u ON b.buyerID = u.userID " +
                            "WHERE b.auctionID = ? " +
                            "ORDER BY b.bidTime DESC";

                        try (
                            Connection conn2 = com.buyme.util.DatabaseConnection.getConnection();
                            PreparedStatement ps2 = conn2.prepareStatement(sql)
                        ) {
                            ps2.setInt(1, auctionFilterId);

                            try (ResultSet rs2 = ps2.executeQuery()) {
                                boolean any = false;

                                while (rs2.next()) {
                                    any = true;
            %>
            <tr>
                <td>#<%= rs2.getInt("bidID") %></td>
                <td>#<%= rs2.getInt("auctionID") %></td>
                <td><%= rs2.getString("username") %></td>
                <td>$<%= String.format("%.2f", rs2.getDouble("bidAmount")) %></td>
                <td>$<%= String.format("%.2f", rs2.getDouble("maxBidLimit")) %></td>
                <td><%= rs2.getTimestamp("bidTime") %></td>
                <td><%= rs2.getBoolean("isWinning") ? "YES" : "NO" %></td>
                <td>
                    <form method="post"
                          onsubmit="return confirm('Delete bid #<%= rs2.getInt("bidID") %>? This will recalculate the auction price.');">
                        <input type="hidden" name="action" value="delete">
                        <input type="hidden" name="bidID" value="<%= rs2.getInt("bidID") %>">
                        <input type="hidden" name="auctionID" value="<%= rs2.getInt("auctionID") %>">
                        <button type="submit" class="btn btn-danger">Delete</button>
                    </form>
                </td>
            </tr>
            <%
                                }

                                if (!any) {
            %>
            <tr>
                <td colspan="8" style="text-align:center; color:#999; padding: 15px;">
                    No bids found for this auction ID.
                </td>
            </tr>
            <%
                                }
                            }
                        }

                    } catch (NumberFormatException nfe) {
            %>
            <tr>
                <td colspan="8" style="color:red; text-align:center; padding: 15px;">
                    Invalid auction ID.
                </td>
            </tr>
            <%
                    } catch (Exception e) {
                        e.printStackTrace();
            %>
            <tr>
                <td colspan="8" style="color:red;">Error loading bids: <%= e.getMessage() %></td>
            </tr>
            <%
                    }

                } else {
            %>
            <tr>
                <td colspan="8" style="text-align:center; color:#999; padding: 15px;">
                    Enter an auction ID above to see its bids.
                </td>
            </tr>
            <%
                }
            %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>

