<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>
<%@ page import="com.buyme.model.User" %>

<%
    User user = (User) session.getAttribute("user");

    String action = request.getParameter("action");
    String id = request.getParameter("id");

    if (action == null || id == null) {
        response.sendRedirect("manage-auctions.jsp");
        return;
    }

    Connection conn = null;

    try {
        conn = DatabaseConnection.getConnection();
        PreparedStatement ps = null;

        if ("activate".equals(action)) {
            ps = conn.prepareStatement("UPDATE auction SET status='active' WHERE auctionID=?");
        } else if ("close".equals(action)) {
            ps = conn.prepareStatement("UPDATE auction SET status='closed' WHERE auctionID=?");
        } else if ("cancel".equals(action)) {
            ps = conn.prepareStatement("UPDATE auction SET status='cancelled' WHERE auctionID=?");
        }

        ps.setInt(1, Integer.parseInt(id));
        ps.executeUpdate();
    } catch(Exception e) {
        e.printStackTrace();
    }

    response.sendRedirect("manage-auctions.jsp");
%>
