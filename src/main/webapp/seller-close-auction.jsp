<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.model.User" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }

    String auctionIdParam = request.getParameter("id");
    if (auctionIdParam == null) {
        response.sendRedirect("my-auctions.jsp");
        return;
    }

    int auctionID = Integer.parseInt(auctionIdParam);

    Connection conn = null;

    try {
        conn = DatabaseConnection.getConnection();

        // Check that this auction belongs to the logged in user and is active
        PreparedStatement checkStmt = conn.prepareStatement(
            "SELECT sellerID, status FROM auction WHERE auctionID = ?"
        );
        checkStmt.setInt(1, auctionID);
        ResultSet rs = checkStmt.executeQuery();

        if (!rs.next()) {
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        int sellerID = rs.getInt("sellerID");
        String status = rs.getString("status");

        if (sellerID != user.getUserID() || !"active".equals(status)) {
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        // Mark this auction as expired right now
        PreparedStatement updateTime = conn.prepareStatement(
            "UPDATE auction SET closeDateTime = NOW() WHERE auctionID = ?"
        );
        updateTime.setInt(1, auctionID);
        updateTime.executeUpdate();

        // Call stored procedure that closes expired auctions
        CallableStatement cs = conn.prepareCall("{CALL close_expired_auctions()}");
        cs.execute();

    } catch (Exception e) {
        e.printStackTrace();
        // You could set a session message here if you want
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException ignored) {}
    }

    response.sendRedirect("my-auctions.jsp");
%>
