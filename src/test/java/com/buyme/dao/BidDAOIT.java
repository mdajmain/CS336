package com.buyme.dao;

import com.buyme.model.Bid;
import com.buyme.util.DatabaseConnection;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class BidDAOIT {

    private final BidDAO bidDAO = new BidDAO();
    private int sellerID;
    private int buyerID;
    private int itemID;
    private int auctionID;

    @BeforeEach
    void setUp() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT userID FROM end_user ORDER BY userID LIMIT 2")) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                sellerID = rs.getInt(1);
                if (rs.next()) {
                    buyerID = rs.getInt(1);
                } else {
                    buyerID = sellerID; // only one end_user seeded; still fine, we control the FK rows below
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) " +
                    "VALUES (1, 1, 'BidDAOIT Item', 'desc', 'new')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                itemID = keys.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, currentPrice, " +
                    "startDateTime, closeDateTime, status) VALUES (?, ?, 100.00, 10.00, 120.00, NOW(), " +
                    "DATE_ADD(NOW(), INTERVAL 1 DAY), 'active')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, itemID);
                ps.setInt(2, sellerID);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                auctionID = keys.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO bid_history (auctionID, buyerID, bidAmount, actualBid, bidTime, wasWinning) " +
                    "VALUES (?, ?, 110.00, 110.00, NOW() - INTERVAL 2 MINUTE, 0), " +
                    "(?, ?, 120.00, 120.00, NOW() - INTERVAL 1 MINUTE, 1)")) {
                ps.setInt(1, auctionID);
                ps.setInt(2, buyerID);
                ps.setInt(3, auctionID);
                ps.setInt(4, buyerID);
                ps.executeUpdate();
            }
        }
    }

    @AfterEach
    void tearDown() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps1 = conn.prepareStatement("DELETE FROM bid_history WHERE auctionID = ?");
             PreparedStatement ps2 = conn.prepareStatement("DELETE FROM auction WHERE auctionID = ?");
             PreparedStatement ps3 = conn.prepareStatement("DELETE FROM item WHERE itemID = ?")) {
            ps1.setInt(1, auctionID);
            ps1.executeUpdate();
            ps2.setInt(1, auctionID);
            ps2.executeUpdate();
            ps3.setInt(1, itemID);
            ps3.executeUpdate();
        }
    }

    @Test
    void getBidHistoryForAuction_returnsMostRecentFirst() {
        List<Bid> history = bidDAO.getBidHistoryForAuction(auctionID);

        assertEquals(2, history.size());
        // ORDER BY bh.bidTime DESC -> the 120.00 bid (more recent) comes first
        assertEquals(0, history.get(0).getBidAmount().compareTo(new java.math.BigDecimal("120.00")));
        assertEquals(0, history.get(1).getBidAmount().compareTo(new java.math.BigDecimal("110.00")));
        assertTrue(history.get(0).isWinning());
    }
}
