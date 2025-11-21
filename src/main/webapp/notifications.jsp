<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }

    Connection conn = null;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Notifications - BuyMe</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f5f5f5; }
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
        }
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .container {
            max-width: 900px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        h1 { margin-bottom: 20px; color: #333; }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            border-bottom: 1px solid #e1e1e1;
        }
        th {
            background: #f8f9fa;
            text-align: left;
        }
        .type-badge {
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 12px;
            color: white;
        }
        .outbid { background: #dc3545; }
        .auction_won { background: #28a745; }
        .auction_ended { background: #6c757d; }
        .alert_item { background: #17a2b8; }
        .bid_exceeded { background: #fd7e14; }
        .unread-row { background: #fffdf2; }
        .small { font-size: 12px; color: #666; }
        .link {
            color: #007bff;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <div>
                <a href="dashboard.jsp" style="color: white; text-decoration: none; font-weight: bold;">BuyMe</a>
            </div>
            <div>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" style="color: white; margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <div class="card">
            <h1>Your Notifications</h1>

            <%
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();

                    // Mark all as read
                    PreparedStatement markRead = conn.prepareStatement(
                        "UPDATE notification SET isRead = TRUE WHERE userID = ? AND isRead = FALSE"
                    );
                    markRead.setInt(1, user.getUserID());
                    markRead.executeUpdate();

                    // Load notifications
                    String sql = "SELECT notificationID, message, type, relatedAuctionID, isRead, createdTime " +
                                 "FROM notification " +
                                 "WHERE userID = ? " +
                                 "ORDER BY createdTime DESC " +
                                 "LIMIT 50";

                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, user.getUserID());
                    ResultSet rs = ps.executeQuery();

                    boolean hasAny = false;
            %>

            <table>
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Message</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        while (rs.next()) {
                            hasAny = true;
                            String type = rs.getString("type");
                            boolean isRead = rs.getBoolean("isRead");
                            Integer relatedAuctionID = (Integer) rs.getObject("relatedAuctionID");
                    %>
                    <tr class="<%= isRead ? "" : "unread-row" %>">
                        <td>
                            <span class="type-badge <%= type %>">
                                <%= type %>
                            </span>
                        </td>
                        <td>
                            <%= rs.getString("message") %>
                            <%
                                if (relatedAuctionID != null) {
                            %>
                                <br>
                                <a class="link small" href="auction-details.jsp?id=<%= relatedAuctionID %>">
                                    View auction
                                </a>
                            <%
                                }
                            %>
                        </td>
                        <td class="small"><%= rs.getTimestamp("createdTime") %></td>
                    </tr>
                    <%
                        }

                        if (!hasAny) {
                    %>
                    <tr>
                        <td colspan="3" style="text-align:center; color:#999; padding: 30px;">
                            You have no notifications yet.
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
            %>
                <p style="color: red;">Error loading notifications: <%= e.getMessage() %></p>
            <%
                } finally {
                    if (conn != null) conn.close();
                }
            %>
        </div>
    </div>
</body>
</html>

