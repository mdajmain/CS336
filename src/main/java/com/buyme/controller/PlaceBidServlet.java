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
        String maxBidAmount = request.getParameter("maxBidAmount");
        
        if (auctionID == null || maxBidAmount == null) {
            response.sendRedirect("browse.jsp");
            return;
        }
        
        Connection conn = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);
            
            // Call the stored procedure for placing bid with automatic bidding
            CallableStatement cstmt = conn.prepareCall("{CALL place_bid(?, ?, ?)}");
            cstmt.setInt(1, Integer.parseInt(auctionID));
            cstmt.setInt(2, user.getUserID());
            cstmt.setBigDecimal(3, new BigDecimal(maxBidAmount));
            
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
            
            String errorMessage = e.getMessage();
            if (errorMessage.contains("must be at least")) {
                request.setAttribute("error", "Your bid must be higher than the current price plus increment");
            } else if (errorMessage.contains("cannot bid on their own")) {
                request.setAttribute("error", "You cannot bid on your own items");
            } else {
                request.setAttribute("error", "Error placing bid: " + errorMessage);
            }
            
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    DatabaseConnection.closeConnection(conn);
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
        
        // Forward back to auction details page
        request.getRequestDispatcher("/auction-details.jsp?id=" + auctionID).forward(request, response);
    }
}
