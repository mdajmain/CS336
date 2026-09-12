package com.buyme.dao;

import com.buyme.model.Auction;
import com.buyme.util.DatabaseConnection;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Needs a real MySQL schema (see README) reachable via DB_URL/DB_USER/DB_PASSWORD,
 * defaulting to buyme_test so it never touches real dev data.
 */
class AuctionDAOIT {

    private final AuctionDAO auctionDAO = new AuctionDAO();
    private int sellerID;
    private int activeAuctionID;
    private int itemID;

    @BeforeEach
    void setUp() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT userID FROM end_user LIMIT 1")) {
                ResultSet rs = ps.executeQuery();
                rs.next();
                sellerID = rs.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) " +
                    "VALUES (1, 1, 'IT Test Item', 'inserted by AuctionDAOIT', 'new')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                itemID = keys.getInt(1);
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO auction (itemID, sellerID, initialPrice, bidIncrement, currentPrice, " +
                    "startDateTime, closeDateTime, status) VALUES (?, ?, 100.00, 10.00, 100.00, NOW(), " +
                    "DATE_ADD(NOW(), INTERVAL 1 DAY), 'active')",
                    Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, itemID);
                ps.setInt(2, sellerID);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                keys.next();
                activeAuctionID = keys.getInt(1);
            }
        }
    }

    @AfterEach
    void tearDown() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement ps1 = conn.prepareStatement("DELETE FROM auction WHERE auctionID = ?");
             PreparedStatement ps2 = conn.prepareStatement("DELETE FROM item WHERE itemID = ?")) {
            ps1.setInt(1, activeAuctionID);
            ps1.executeUpdate();
            ps2.setInt(1, itemID);
            ps2.executeUpdate();
        }
    }

    @Test
    void getActiveAuctions_includesFreshlyCreatedActiveAuction() {
        List<Auction> active = auctionDAO.getActiveAuctions();

        assertTrue(active.stream().anyMatch(a -> a.getAuctionID() == activeAuctionID),
            "getActiveAuctions() should include the freshly inserted active auction");
    }

    @Test
    void getAuctionById_roundTripsFields() {
        Auction auction = auctionDAO.getAuctionById(activeAuctionID);

        assertNotNull(auction);
        assertEquals(sellerID, auction.getSellerID());
        assertEquals(new BigDecimal("100.00"), auction.getCurrentPrice());
        assertEquals("active", auction.getStatus());
    }

    @Test
    void createAuction_thenGetAuctionById_roundTrips() {
        Auction auction = new Auction();
        auction.setSellerID(sellerID);
        auction.setInitialPrice(new BigDecimal("50.00"));
        auction.setBidIncrement(new BigDecimal("5.00"));
        auction.setCategoryID(1);
        auction.setSubcategoryID(1);
        auction.setItemName("createAuction IT item");
        auction.setDescription("desc");
        auction.setItemCondition("new");
        auction.setStartDateTime(new Timestamp(System.currentTimeMillis()));
        auction.setCloseDateTime(new Timestamp(System.currentTimeMillis() + 86_400_000L));

        int newAuctionID = auctionDAO.createAuction(auction, -1);
        try {
            assertTrue(newAuctionID > 0);
            Auction fetched = auctionDAO.getAuctionById(newAuctionID);
            assertNotNull(fetched);
            assertEquals("createAuction IT item", fetched.getItemName());
        } finally {
            cleanupCreatedAuction(newAuctionID);
        }
    }

    private void cleanupCreatedAuction(int createdAuctionID) {
        if (createdAuctionID <= 0) return;
        try (Connection conn = DatabaseConnection.getConnection()) {
            int itemIdToDelete;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT itemID FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, createdAuctionID);
                ResultSet rs = ps.executeQuery();
                rs.next();
                itemIdToDelete = rs.getInt(1);
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, createdAuctionID);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM item WHERE itemID = ?")) {
                ps.setInt(1, itemIdToDelete);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }
}
