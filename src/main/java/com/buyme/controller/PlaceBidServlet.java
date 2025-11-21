// File: src/main/java/com/buyme/controller/PlaceBidServlet.java
package com.buyme.controller;

import com.buyme.model.User;
import com.buyme.util.DatabaseConnection;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.math.BigDecimal;
import java.sql.*;

@WebServlet("/PlaceBidServlet")
public class PlaceBidServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");

        if (user == null) {
            response.sendRedirect("login");
            return;
        }

        String auctionID = request.getParameter("auctionID");
        String bidAmountStr = request.getParameter("bidAmount");
        String maxBidAmountStr = request.getParameter("maxBidAmount");
        String useAuto = request.getParameter("useAuto");   // checkbox: "true" or null

        if (auctionID == null || bidAmountStr == null) {
            response.sendRedirect("browse.jsp");
            return;
        }

        // Parse bidAmount safely
        BigDecimal bidAmount;
        try {
            bidAmount = new BigDecimal(bidAmountStr);
        } catch (NumberFormatException e) {
            request.setAttribute("error", "Invalid bid amount");
            request.getRequestDispatcher("/auction-details.jsp?id=" + auctionID).forward(request, response);
            return;
        }

        // Decide maxBidLimit
        BigDecimal maxBidLimit;

        // User checked autobid and entered something
        if ("true".equals(useAuto) &&
                maxBidAmountStr != null &&
                !maxBidAmountStr.isEmpty()) {

            try {
                maxBidLimit = new BigDecimal(maxBidAmountStr);
            } catch (NumberFormatException e) {
                request.setAttribute("error", "Invalid maximum bid amount");
                request.getRequestDispatcher("/auction-details.jsp?id=" + auctionID).forward(request, response);
                return;
            }

        } else {
            // No auto → maxBidLimit = immediate bid
            maxBidLimit = bidAmount;
        }

        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // Stored procedure takes p_auctionID, p_buyerID, p_maxBidLimit
            CallableStatement cstmt = conn.prepareCall("{CALL place_bid(?, ?, ?)}");
            cstmt.setInt(1, Integer.parseInt(auctionID));
            cstmt.setInt(2, user.getUserID());
            cstmt.setBigDecimal(3, maxBidLimit);

            cstmt.execute();
            conn.commit();

            request.setAttribute("success", "Bid placed successfully!");

        } catch (SQLException e) {

            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }

            String msg = e.getMessage();

            if (msg.contains("must be at least")) {
                request.setAttribute("error", "Your bid must be higher than the current minimum required.");
            } else if (msg.contains("cannot bid on their own")) {
                request.setAttribute("error", "You cannot bid on your own auction.");
            } else {
                request.setAttribute("error", "Error placing bid: " + msg);
            }

        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    DatabaseConnection.closeConnection(conn);
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
        }

        // Forward back to auction page
        request.getRequestDispatcher("/auction-details.jsp?id=" + auctionID).forward(request, response);
    }
}

