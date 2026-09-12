package com.buyme.dao;

import com.buyme.util.DatabaseConnection;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuctionDAOCountsIT {

    private final AuctionDAO auctionDAO = new AuctionDAO();
    private int sellerID;
    private int itemID;
    private int activeAuctionID;
    private int closedAuctionID;

    @BeforeEach
    void setUp() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            // A brand-new end_user with zero pre-existing auctions, so the seller-scoped
            // counts below are deterministic regardless of whatever else is seeded.
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO user (username, password, email, userType) VALUES (?, 'x', ?, 'end_user')",
                    Statement.RETURN_GENERATED_KEYS)) {
                String unique = "countsit_seller_" + System.nanoTime();
                ps.setString(1, unique);
                ps.setString(2, unique + "@example.com");
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                sellerID = keys.getInt(1);
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO end_user (userID, firstName, lastName, address, phone, isAnonymous) " +
                    "VALUES (?, 'IT', 'Test', 'addr', '000', 0)")) {
                ps.setInt(1, sellerID);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) " +
                    "VALUES (1, 1, 'CountsIT Item', 'desc', 'new')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                itemID = keys.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, currentPrice, " +
                    "startDateTime, closeDateTime, status) VALUES " +
                    "(?, ?, 10.00, 1.00, 10.00, NOW(), DATE_ADD(NOW(), INTERVAL 1 DAY), 'active')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, itemID);
                ps.setInt(2, sellerID);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                activeAuctionID = keys.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, currentPrice, " +
                    "startDateTime, closeDateTime, status) VALUES " +
                    "(?, ?, 10.00, 1.00, 10.00, NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, 'closed')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, itemID);
                ps.setInt(2, sellerID);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                closedAuctionID = keys.getInt(1);
            }
        }
    }

    @AfterEach
    void tearDown() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM auction WHERE auctionID IN (?, ?)")) {
                ps.setInt(1, activeAuctionID);
                ps.setInt(2, closedAuctionID);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM item WHERE itemID = ?")) {
                ps.setInt(1, itemID);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM end_user WHERE userID = ?")) {
                ps.setInt(1, sellerID);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM user WHERE userID = ?")) {
                ps.setInt(1, sellerID);
                ps.executeUpdate();
            }
        }
    }

    @Test
    void countActiveAuctions_includesTheFreshActiveOne() {
        assertTrue(auctionDAO.countActiveAuctions() >= 1);
    }

    @Test
    void countAuctionsBySeller_countsBothActiveAndClosed() {
        assertEquals(2, auctionDAO.countAuctionsBySeller(sellerID));
    }

    @Test
    void countActiveAuctionsBySeller_countsOnlyTheActiveOne() {
        assertEquals(1, auctionDAO.countActiveAuctionsBySeller(sellerID));
    }
}
