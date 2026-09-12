// File: src/main/java/com/buyme/dao/AuctionDAO.java
package com.buyme.dao;

import com.buyme.model.Auction;
import com.buyme.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AuctionDAO {
    
    public List<Auction> getActiveAuctions() {
        List<Auction> auctions = new ArrayList<>();
        String sql = "SELECT a.*, i.itemName, i.description, i.itemCondition, " +
                    "u.username as sellerUsername, " +
                    "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "JOIN user u ON a.sellerID = u.userID " +
                    "WHERE a.status = 'active' AND a.closeDateTime > NOW() " +
                    "ORDER BY a.closeDateTime ASC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Auction auction = mapResultSetToAuction(rs);
                auctions.add(auction);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return auctions;
    }
    
    public Auction getAuctionById(int auctionID) {
        Auction auction = null;
        String sql = "SELECT a.*, i.itemName, i.description, i.itemCondition, " +
                    "i.categoryID, i.subcategoryID, u.username as sellerUsername, " +
                    "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "JOIN user u ON a.sellerID = u.userID " +
                    "WHERE a.auctionID = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, auctionID);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                auction = mapResultSetToAuction(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return auction;
    }
    
    public List<Auction> getAuctionsByUser(int userID) {
        List<Auction> auctions = new ArrayList<>();
        String sql = "SELECT a.*, i.itemName, i.description, i.itemCondition, " +
                    "u.username as sellerUsername, " +
                    "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "JOIN user u ON a.sellerID = u.userID " +
                    "WHERE a.sellerID = ? " +
                    "ORDER BY a.startDateTime DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, userID);
            ResultSet rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Auction auction = mapResultSetToAuction(rs);
                auctions.add(auction);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return auctions;
    }
    
    public int createAuction(Auction auction, int itemID) {
        Connection conn = null;
        int auctionID = -1;
        
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);
            
            // First create the item
            String itemSql = "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) " +
                            "VALUES (?, ?, ?, ?, ?)";
            PreparedStatement itemStmt = conn.prepareStatement(itemSql, Statement.RETURN_GENERATED_KEYS);
            itemStmt.setInt(1, auction.getCategoryID());
            itemStmt.setInt(2, auction.getSubcategoryID());
            itemStmt.setString(3, auction.getItemName());
            itemStmt.setString(4, auction.getDescription());
            itemStmt.setString(5, auction.getItemCondition());
            
            itemStmt.executeUpdate();
            ResultSet itemKeys = itemStmt.getGeneratedKeys();
            
            if (itemKeys.next()) {
                int newItemID = itemKeys.getInt(1);
                
                // Create the auction
                String auctionSql = "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, " +
                                   "reservePrice, currentPrice, startDateTime, closeDateTime, status) " +
                                   "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement auctionStmt = conn.prepareStatement(auctionSql, Statement.RETURN_GENERATED_KEYS);
                auctionStmt.setInt(1, newItemID);
                auctionStmt.setInt(2, auction.getSellerID());
                auctionStmt.setBigDecimal(3, auction.getInitialPrice());
                auctionStmt.setBigDecimal(4, auction.getBidIncrement());
                auctionStmt.setBigDecimal(5, auction.getReservePrice());
                auctionStmt.setBigDecimal(6, auction.getInitialPrice()); // Current price starts at initial
                auctionStmt.setTimestamp(7, auction.getStartDateTime());
                auctionStmt.setTimestamp(8, auction.getCloseDateTime());
                
                // Set status based on start time
                Timestamp now = new Timestamp(System.currentTimeMillis());
                String status = auction.getStartDateTime().after(now) ? "pending" : "active";
                auctionStmt.setString(9, status);
                
                auctionStmt.executeUpdate();
                ResultSet auctionKeys = auctionStmt.getGeneratedKeys();
                
                if (auctionKeys.next()) {
                    auctionID = auctionKeys.getInt(1);
                    conn.commit();
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
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
        
        return auctionID;
    }
    
    public List<Auction> searchAuctions(String keyword, Integer categoryID, 
                                       String minPrice, String maxPrice) {
        List<Auction> auctions = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT a.*, i.itemName, i.description, i.itemCondition, " +
            "u.username as sellerUsername, " +
            "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
            "FROM auction a " +
            "JOIN item i ON a.itemID = i.itemID " +
            "JOIN user u ON a.sellerID = u.userID " +
            "WHERE a.status = 'active' AND a.closeDateTime > NOW() ");
        
        List<Object> params = new ArrayList<>();
        
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (i.itemName LIKE ? OR i.description LIKE ?) ");
            params.add("%" + keyword + "%");
            params.add("%" + keyword + "%");
        }
        
        if (categoryID != null && categoryID > 0) {
            sql.append("AND (i.categoryID = ? OR i.subcategoryID = ?) ");
            params.add(categoryID);
            params.add(categoryID);
        }
        
        if (minPrice != null && !minPrice.isEmpty()) {
            sql.append("AND a.currentPrice >= ? ");
            params.add(minPrice);
        }
        
        if (maxPrice != null && !maxPrice.isEmpty()) {
            sql.append("AND a.currentPrice <= ? ");
            params.add(maxPrice);
        }
        
        sql.append("ORDER BY a.closeDateTime ASC");
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            ResultSet rs = pstmt.executeQuery();
            while (rs.next()) {
                Auction auction = mapResultSetToAuction(rs);
                auctions.add(auction);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        
        return auctions;
    }
    
    public int countActiveAuctions() {
        String sql = "SELECT COUNT(*) FROM auction WHERE status = 'active'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int countAuctionsBySeller(int sellerID) {
        String sql = "SELECT COUNT(*) FROM auction WHERE sellerID = ?";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, sellerID);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int countActiveAuctionsBySeller(int sellerID) {
        String sql = "SELECT COUNT(*) FROM auction WHERE sellerID = ? AND status = 'active'";
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, sellerID);
            ResultSet rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    private Auction mapResultSetToAuction(ResultSet rs) throws SQLException {
        Auction auction = new Auction();
        auction.setAuctionID(rs.getInt("auctionID"));
        auction.setItemID(rs.getInt("itemID"));
        auction.setSellerID(rs.getInt("sellerID"));
        auction.setInitialPrice(rs.getBigDecimal("initialPrice"));
        auction.setBidIncrement(rs.getBigDecimal("bidIncrement"));
        auction.setReservePrice(rs.getBigDecimal("reservePrice"));
        auction.setCurrentPrice(rs.getBigDecimal("currentPrice"));
        auction.setStartDateTime(rs.getTimestamp("startDateTime"));
        auction.setCloseDateTime(rs.getTimestamp("closeDateTime"));
        auction.setStatus(rs.getString("status"));
        
        // Additional fields if they exist
        try {
            auction.setItemName(rs.getString("itemName"));
            auction.setDescription(rs.getString("description"));
            auction.setItemCondition(rs.getString("itemCondition"));
            auction.setSellerUsername(rs.getString("sellerUsername"));
            auction.setBidCount(rs.getInt("bidCount"));
        } catch (SQLException e) {
            // These fields might not be in all queries
        }
        
        return auction;
    }
}