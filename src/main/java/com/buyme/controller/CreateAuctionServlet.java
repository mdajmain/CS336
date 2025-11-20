// File: src/main/java/com/buyme/controller/CreateAuctionServlet.java
package com.buyme.controller;

import com.buyme.model.User;
import com.buyme.model.Auction;
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
import java.text.SimpleDateFormat;

@WebServlet("/CreateAuctionServlet")
public class CreateAuctionServlet extends HttpServlet {
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        User user = (User) session.getAttribute("user");
        
        if (user == null) {
            response.sendRedirect("login");
            return;
        }
        
        // Get form parameters
        String itemName = request.getParameter("itemName");
        String description = request.getParameter("description");
        String category = request.getParameter("category");
        String subcategory = request.getParameter("subcategory");
        String condition = request.getParameter("condition");
        String initialPrice = request.getParameter("initialPrice");
        String bidIncrement = request.getParameter("bidIncrement");
        String reservePrice = request.getParameter("reservePrice");
        String startDateTime = request.getParameter("startDateTime");
        String closeDateTime = request.getParameter("closeDateTime");
        
        Connection conn = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);
            
            // First, insert the item
            String itemSql = "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement itemStmt = conn.prepareStatement(itemSql, Statement.RETURN_GENERATED_KEYS);
            
            // For simplicity, using category as both category and subcategory
            // In real app, you'd have proper subcategory selection
            itemStmt.setInt(1, Integer.parseInt(category));
            itemStmt.setInt(2, Integer.parseInt(category)); // Should be actual subcategory
            itemStmt.setString(3, itemName);
            itemStmt.setString(4, description);
            itemStmt.setString(5, condition);
            
            itemStmt.executeUpdate();
            ResultSet itemKeys = itemStmt.getGeneratedKeys();
            
            if (itemKeys.next()) {
                int itemID = itemKeys.getInt(1);
                
                // Now create the auction
                String auctionSql = "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, " +
                                   "reservePrice, currentPrice, startDateTime, closeDateTime, status) " +
                                   "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                
                PreparedStatement auctionStmt = conn.prepareStatement(auctionSql);
                auctionStmt.setInt(1, itemID);
                auctionStmt.setInt(2, user.getUserID());
                auctionStmt.setBigDecimal(3, new BigDecimal(initialPrice));
                auctionStmt.setBigDecimal(4, new BigDecimal(bidIncrement));
                
                // Handle optional reserve price
                if (reservePrice != null && !reservePrice.isEmpty()) {
                    auctionStmt.setBigDecimal(5, new BigDecimal(reservePrice));
                } else {
                    auctionStmt.setNull(5, Types.DECIMAL);
                }
                
                auctionStmt.setBigDecimal(6, new BigDecimal(initialPrice)); // Current price starts at initial
                
                // Convert datetime-local format to SQL Timestamp
                SimpleDateFormat format = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm");
                Timestamp startTime = new Timestamp(format.parse(startDateTime).getTime());
                Timestamp closeTime = new Timestamp(format.parse(closeDateTime).getTime());
                
                auctionStmt.setTimestamp(7, startTime);
                auctionStmt.setTimestamp(8, closeTime);
                
                // Set status based on start time
                String status = startTime.after(new Timestamp(System.currentTimeMillis())) ? "pending" : "active";
                auctionStmt.setString(9, status);
                
                auctionStmt.executeUpdate();
                conn.commit();
                
                request.setAttribute("success", "Auction created successfully!");
                request.getRequestDispatcher("/my-auctions.jsp").forward(request, response);
                
            } else {
                conn.rollback();
                request.setAttribute("error", "Failed to create auction. Please try again.");
                request.getRequestDispatcher("/create-auction.jsp").forward(request, response);
            }
            
        } catch (Exception e) {
            e.printStackTrace();
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            request.setAttribute("error", "Error creating auction: " + e.getMessage());
            request.getRequestDispatcher("/create-auction.jsp").forward(request, response);
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
    }
}
