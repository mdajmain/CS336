// File: src/main/java/com/buyme/dao/BidDAO.java
package com.buyme.dao;

import com.buyme.model.Bid;
import com.buyme.util.DatabaseConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BidDAO {

    // 1) Full bid history for a specific auction
    public List<Bid> getBidHistoryForAuction(int auctionID) {
        List<Bid> bids = new ArrayList<>();

        String sql =
            "SELECT bh.historyID, bh.auctionID, bh.buyerID, " +
            "       bh.bidAmount, bh.actualBid, bh.bidTime, bh.wasWinning, " +
            "       u.username AS buyerUsername " +
            "FROM bid_history bh " +
            "JOIN end_user e ON bh.buyerID = e.userID " +
            "JOIN user u ON e.userID = u.userID " +
            "WHERE bh.auctionID = ? " +
            "ORDER BY bh.bidTime DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, auctionID);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Bid bid = new Bid();
                // historyID is not in Bid, but we do not need it really
                bid.setAuctionID(rs.getInt("auctionID"));
                bid.setBuyerID(rs.getInt("buyerID"));
                bid.setBidAmount(rs.getBigDecimal("bidAmount"));
                // Store actualBid into maxBidLimit just so we can see it if we want
                bid.setMaxBidLimit(rs.getBigDecimal("actualBid"));
                bid.setBidTime(rs.getTimestamp("bidTime"));
                bid.setWinning(rs.getBoolean("wasWinning"));
                bid.setBuyerUsername(rs.getString("buyerUsername"));

                bids.add(bid);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return bids;
    }

    // 1b) Same as above, paginated (used by pages that page through long bid histories)
    public List<Bid> getBidHistoryForAuction(int auctionID, int limit, int offset) {
        List<Bid> bids = new ArrayList<>();

        String sql =
            "SELECT bh.historyID, bh.auctionID, bh.buyerID, " +
            "       bh.bidAmount, bh.actualBid, bh.bidTime, bh.wasWinning, " +
            "       u.username AS buyerUsername " +
            "FROM bid_history bh " +
            "JOIN end_user e ON bh.buyerID = e.userID " +
            "JOIN user u ON e.userID = u.userID " +
            "WHERE bh.auctionID = ? " +
            "ORDER BY bh.bidTime DESC " +
            "LIMIT ? OFFSET ?";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, auctionID);
            pstmt.setInt(2, limit);
            pstmt.setInt(3, offset);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Bid bid = new Bid();
                bid.setAuctionID(rs.getInt("auctionID"));
                bid.setBuyerID(rs.getInt("buyerID"));
                bid.setBidAmount(rs.getBigDecimal("bidAmount"));
                bid.setMaxBidLimit(rs.getBigDecimal("actualBid"));
                bid.setBidTime(rs.getTimestamp("bidTime"));
                bid.setWinning(rs.getBoolean("wasWinning"));
                bid.setBuyerUsername(rs.getString("buyerUsername"));

                bids.add(bid);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return bids;
    }

    // 2) All auctions a given buyer has participated in
    // Uses your user_bidding_history view
    public List<Bid> getBiddingHistoryForUser(int buyerID) {
        List<Bid> bids = new ArrayList<>();

        String sql =
            "SELECT auctionID, itemName, bidAmount, bidTime, auctionStatus, bidStatus " +
            "FROM user_bidding_history " +
            "WHERE buyerID = ? " +
            "ORDER BY bidTime DESC";

        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, buyerID);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Bid bid = new Bid();
                bid.setAuctionID(rs.getInt("auctionID"));
                bid.setItemName(rs.getString("itemName"));
                bid.setBidAmount(rs.getBigDecimal("bidAmount"));
                bid.setBidTime(rs.getTimestamp("bidTime"));

                // Your Bid model has auctionStatus, we can store the human readable status there
                // Example values from the view: Won, Lost, Active
                bid.setAuctionStatus(rs.getString("bidStatus"));

                bids.add(bid);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }

        return bids;
    }
}
