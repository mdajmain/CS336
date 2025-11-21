<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>

<%
    // Simple admin session check
    if (session.getAttribute("user") == null) {
        response.sendRedirect("../login.jsp");
        return;
    }

    com.buyme.model.User u = (com.buyme.model.User) session.getAttribute("user");
    if (!"admin".equals(u.getUserType())) {
        response.sendRedirect("../dashboard.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Auctions - Admin</title>
    <style>
        body { background: #f5f5f5; font-family: Arial; }
        .container { max-width: 1100px; margin: 30px auto; background: white; padding: 20px; border-radius: 8px; }
        h1 { margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 10px; border-bottom: 1px solid #ddd; }
        th { background: #eee; }
        .btn { padding: 6px 12px; border-radius: 4px; text-decoration: none; color: white; font-size: 14px; }
        .btn-activate { background: #28a745; }
        .btn-close { background: #dc3545; }
        .btn-cancel { background: #6c757d; }
    </style>
</head>

<body>
    <div class="container">
        <h1>Manage Auctions</h1>

        <table>
            <thead>
                <tr>
                    <th>Auction ID</th>
                    <th>Item</th>
                    <th>Seller</th>
                    <th>Status</th>
                    <th>Current Price</th>
                    <th>Ends</th>
                    <th>Actions</th>
                </tr>
            </thead>

            <tbody>
                <%
                    try {
                        Connection conn = DatabaseConnection.getConnection();

                        String sql = 
                            "SELECT a.*, i.itemName, u.username " +
                            "FROM auction a " +
                            "JOIN item i ON a.itemID = i.itemID " +
                            "JOIN user u ON a.sellerID = u.userID " +
                            "ORDER BY a.closeDateTime DESC";

                        PreparedStatement ps = conn.prepareStatement(sql);
                        ResultSet rs = ps.executeQuery();

                        while (rs.next()) {
                %>
                <tr>
                    <td><%= rs.getInt("auctionID") %></td>
                    <td><%= rs.getString("itemName") %></td>
                    <td><%= rs.getString("username") %></td>
                    <td><%= rs.getString("status") %></td>
                    <td>$<%= rs.getDouble("currentPrice") %></td>
                    <td><%= rs.getTimestamp("closeDateTime") %></td>

                    <td>
                        <% String status = rs.getString("status"); %>

                        <% if ("pending".equals(status)) { %>
                            <a href="update-auction-status.jsp?action=activate&id=<%= rs.getInt("auctionID") %>" class="btn btn-activate">Activate</a>
                        <% } %>

                        <% if ("active".equals(status)) { %>
                            <a href="update-auction-status.jsp?action=close&id=<%= rs.getInt("auctionID") %>" class="btn btn-close">Force Close</a>
                        <% } %>

                        <% if (!"cancelled".equals(status)) { %>
                            <a href="update-auction-status.jsp?action=cancel&id=<%= rs.getInt("auctionID") %>" class="btn btn-cancel">Cancel</a>
                        <% } %>
                    </td>
                </tr>
                <%
                        }

                        conn.close();
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                %>
            </tbody>
        </table>
    </div>
</body>
</html>
