<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.model.User" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String auctionIdParam = request.getParameter("id");
    if (auctionIdParam == null || auctionIdParam.trim().isEmpty()) {
        session.setAttribute("error", "No auction specified.");
        response.sendRedirect("my-auctions.jsp");
        return;
    }

    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIdParam);
    } catch (NumberFormatException e) {
        session.setAttribute("error", "Invalid auction ID.");
        response.sendRedirect("my-auctions.jsp");
        return;
    }

    Connection conn = null;

    try {
        conn = DatabaseConnection.getConnection();

        // Get auction details
        PreparedStatement checkStmt = conn.prepareStatement(
            "SELECT a.sellerID, a.status, a.currentPrice, a.reservePrice, a.winnerID, " +
            "a.itemID, a.startDateTime, i.itemName, i.categoryID " +
            "FROM auction a " +
            "JOIN item i ON a.itemID = i.itemID " +
            "WHERE a.auctionID = ?"
        );
        checkStmt.setInt(1, auctionID);
        ResultSet rs = checkStmt.executeQuery();

        if (!rs.next()) {
            session.setAttribute("error", "Auction not found.");
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        int sellerID = rs.getInt("sellerID");
        String status = rs.getString("status");
        double currentPrice = rs.getDouble("currentPrice");
        Double reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
        Integer winnerID = rs.getObject("winnerID") != null ? rs.getInt("winnerID") : null;
        int itemID = rs.getInt("itemID");
        String itemName = rs.getString("itemName");
        int categoryID = rs.getInt("categoryID");
        Timestamp startDateTime = rs.getTimestamp("startDateTime");

        // Verify ownership
        if (sellerID != user.getUserID()) {
            session.setAttribute("error", "You can only close your own auctions.");
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        // Verify status
        if (!"active".equals(status)) {
            session.setAttribute("error", "Only active auctions can be closed. Current status: " + status);
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        // Calculate a valid closeDateTime that satisfies the constraint (closeDateTime > startDateTime)
        // Use startDateTime + 1 second if NOW() would violate the constraint
        Timestamp now = new Timestamp(System.currentTimeMillis());
        Timestamp newCloseDateTime;
        
        if (now.after(startDateTime)) {
            newCloseDateTime = now;
        } else {
            // If somehow NOW is not after startDateTime, set close to 1 second after start
            newCloseDateTime = new Timestamp(startDateTime.getTime() + 1000);
        }

        // Close the auction - only update status, keep closeDateTime valid
        PreparedStatement closeStmt = conn.prepareStatement(
            "UPDATE auction SET status = 'closed', closeDateTime = ? WHERE auctionID = ?"
        );
        closeStmt.setTimestamp(1, newCloseDateTime);
        closeStmt.setInt(2, auctionID);
        int rowsUpdated = closeStmt.executeUpdate();

        if (rowsUpdated == 0) {
            session.setAttribute("error", "Failed to close auction. Please try again.");
            response.sendRedirect("my-auctions.jsp");
            return;
        }

        // Check if reserve was met
        boolean reserveMet = (reservePrice == null || currentPrice >= reservePrice);

        if (winnerID != null && reserveMet) {
            // Create sales report
            try {
                PreparedStatement salesStmt = conn.prepareStatement(
                    "INSERT INTO sales_report (auctionID, itemID, itemName, categoryID, buyerID, sellerID, finalPrice, reserveMet) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, TRUE) " +
                    "ON DUPLICATE KEY UPDATE finalPrice = VALUES(finalPrice)"
                );
                salesStmt.setInt(1, auctionID);
                salesStmt.setInt(2, itemID);
                salesStmt.setString(3, itemName);
                salesStmt.setInt(4, categoryID);
                salesStmt.setInt(5, winnerID);
                salesStmt.setInt(6, sellerID);
                salesStmt.setDouble(7, currentPrice);
                salesStmt.executeUpdate();
            } catch (SQLException e) {
                // Sales report might already exist, continue
            }

            // Notify the winner
            try {
                PreparedStatement notifyWinner = conn.prepareStatement(
                    "INSERT INTO notification (userID, message, type, relatedAuctionID) " +
                    "VALUES (?, ?, 'auction_won', ?)"
                );
                notifyWinner.setInt(1, winnerID);
                notifyWinner.setString(2, "Congratulations! You won the auction for '" + itemName + "' at $" + String.format("%.2f", currentPrice));
                notifyWinner.setInt(3, auctionID);
                notifyWinner.executeUpdate();
            } catch (SQLException e) {
                // Notification error, continue
            }

            // Notify seller
            try {
                PreparedStatement notifySeller = conn.prepareStatement(
                    "INSERT INTO notification (userID, message, type, relatedAuctionID) " +
                    "VALUES (?, ?, 'auction_ended', ?)"
                );
                notifySeller.setInt(1, sellerID);
                notifySeller.setString(2, "Your item '" + itemName + "' has been sold for $" + String.format("%.2f", currentPrice) + "!");
                notifySeller.setInt(3, auctionID);
                notifySeller.executeUpdate();
            } catch (SQLException e) {
                // Notification error, continue
            }

            session.setAttribute("success", "Auction closed successfully! '" + itemName + "' sold for $" + String.format("%.2f", currentPrice));

        } else if (winnerID != null && !reserveMet) {
            // Notify seller - reserve not met
            try {
                PreparedStatement notifySeller = conn.prepareStatement(
                    "INSERT INTO notification (userID, message, type, relatedAuctionID) " +
                    "VALUES (?, ?, 'auction_ended', ?)"
                );
                notifySeller.setInt(1, sellerID);
                notifySeller.setString(2, "Your auction for '" + itemName + "' ended but the reserve price was not met.");
                notifySeller.setInt(3, auctionID);
                notifySeller.executeUpdate();
            } catch (SQLException e) {
                // Continue
            }

            session.setAttribute("success", "Auction closed. Reserve price was not met - no sale.");

        } else {
            // No bids
            session.setAttribute("success", "Auction closed. There were no bids on '" + itemName + "'.");
        }

    } catch (Exception e) {
        e.printStackTrace();
        session.setAttribute("error", "Error closing auction: " + e.getMessage());
    } finally {
        if (conn != null) {
            try { conn.close(); } catch (SQLException ignored) {}
        }
    }

    response.sendRedirect("my-auctions.jsp");
%>


