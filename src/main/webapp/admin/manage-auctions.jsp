<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"customer_rep".equals(user.getUserType())) {
        response.sendRedirect("../login");
        return;
    }

    String message = null;
    String error = null;

    // Handle cancel action
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String auctionIdStr = request.getParameter("auctionID");

        if ("cancel".equals(action) && auctionIdStr != null) {
            try {
                int auctionID = Integer.parseInt(auctionIdStr);
                Connection conn = null;
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();
                    conn.setAutoCommit(false);

                    // Delete bids for that auction
                    PreparedStatement delBids = conn.prepareStatement(
                        "DELETE FROM bid WHERE auctionID = ?"
                    );
                    delBids.setInt(1, auctionID);
                    delBids.executeUpdate();

                    // Mark auction as cancelled
                    PreparedStatement updAuction = conn.prepareStatement(
                        "UPDATE auction SET status = 'cancelled', winnerID = NULL WHERE auctionID = ?"
                    );
                    updAuction.setInt(1, auctionID);
                    int rows = updAuction.executeUpdate();

                    if (rows > 0) {
                        message = "Auction #" + auctionID + " has been cancelled and its bids removed.";
                        conn.commit();
                    } else {
                        error = "Auction not found or already closed.";
                        conn.rollback();
                    }
                } catch (Exception ex) {
                    if (conn != null) conn.rollback();
                    ex.printStackTrace();
                    error = "Error cancelling auction: " + ex.getMessage();
                } finally {
                    if (conn != null) {
                        conn.setAutoCommit(true);
                        conn.close();
                    }
                }
            } catch (NumberFormatException e) {
                error = "Invalid auction ID.";
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Auctions - Customer Rep</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; }
        .navbar { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 15px 0; color: white; }
        .nav-container { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        .back-link { text-decoration: none; color: #667eea; display: inline-block; margin-bottom: 15px; }
        .section { background: white; padding: 20px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { padding: 10px; border-bottom: 1px solid #e1e1e1; text-align: left; }
        th { background: #f8f9fa; }
        .alert { padding: 10px; border-radius: 5px; margin-bottom: 10px; }
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .btn { padding: 6px 12px; border-radius: 4px; border: none; cursor: pointer; font-size: 13px; }
        .btn-cancel { background: #dc3545; color: white; }
        .badge { padding: 2px 6px; border-radius: 4px; font-size: 11px; color: white; }
        .badge-active { background: #28a745; }
        .badge-pending { background: #ffc107; color: #333; }
        .badge-closed { background: #6c757d; }
        .badge-cancelled { background: #dc3545; }
    </style>
</head>
<body>
<nav class="navbar">
    <div class="nav-container">
        <h2>Customer Representative Panel</h2>
        <div>
            <span>Rep: <%= user.getUsername() %></span>
            <a href="../logout" class="logout-btn" style="color: white; margin-left: 15px;">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="dashboard.jsp" class="back-link">← Back to Dashboard</a>

    <div class="section">
        <h2>Manage Auctions</h2>
        <p>Cancel inappropriate or problematic auctions.</p>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <table>
            <thead>
            <tr>
                <th>ID</th>
                <th>Item</th>
                <th>Seller</th>
                <th>Status</th>
                <th>Current Price</th>
                <th>Ends</th>
                <th>Action</th>
            </tr>
            </thead>
            <tbody>
            <%
                Connection conn = null;
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();

                    String sql =
                        "SELECT a.auctionID, a.status, a.currentPrice, a.closeDateTime, " +
                        "       i.itemName, u.username as sellerName " +
                        "FROM auction a " +
                        "JOIN item i ON a.itemID = i.itemID " +
                        "JOIN end_user e ON a.sellerID = e.userID " +
                        "JOIN user u ON e.userID = u.userID " +
                        "ORDER BY a.status, a.closeDateTime DESC";

                    PreparedStatement ps = conn.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery();

                    boolean any = false;
                    while (rs.next()) {
                        any = true;
                        String status = rs.getString("status");
                        String badgeClass = "badge-" + status;
            %>
            <tr>
                <td>#<%= rs.getInt("auctionID") %></td>
                <td><%= rs.getString("itemName") %></td>
                <td><%= rs.getString("sellerName") %></td>
                <td><span class="badge <%= badgeClass %>"><%= status.toUpperCase() %></span></td>
                <td>$<%= String.format("%.2f", rs.getDouble("currentPrice")) %></td>
                <td><%= rs.getTimestamp("closeDateTime") %></td>
                <td>
                    <% if (!"cancelled".equals(status) && !"closed".equals(status)) { %>
                    <form method="post" onsubmit="return confirm('Cancel auction #<%= rs.getInt("auctionID") %>? This will remove all bids.');">
                        <input type="hidden" name="action" value="cancel">
                        <input type="hidden" name="auctionID" value="<%= rs.getInt("auctionID") %>">
                        <button type="submit" class="btn btn-cancel">Cancel Auction</button>
                    </form>
                    <% } else { %>
                        <span style="font-size: 12px; color: #666;">No actions</span>
                    <% } %>
                </td>
            </tr>
            <%
                    }

                    if (!any) {
            %>
            <tr>
                <td colspan="7" style="text-align:center; color:#999; padding: 20px;">
                    No auctions found.
                </td>
            </tr>
            <%
                    }
                } catch (Exception e) {
                    e.printStackTrace();
            %>
            <tr>
                <td colspan="7" style="color:red;">Error loading auctions: <%= e.getMessage() %></td>
            </tr>
            <%
                } finally {
                    if (conn != null) conn.close();
                }
            %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>

