package com.buyme.dao;

import com.buyme.util.DatabaseConnection;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Exercises the place_bid stored procedure directly (the proxy/auto-bidding
 * engine PlaceBidServlet calls via {CALL place_bid(?,?,?)}). Needs a real
 * MySQL schema reachable via DB_URL/DB_USER/DB_PASSWORD (defaults to
 * buyme_test) with the procedures/triggers/events from buy_me_db.sql loaded.
 *
 * This suite exists because the procedure was found this session to be
 * non-atomic: a failed bid partway through an outbid could leave the auction
 * with no winner flagged at all (the old leader's isWinning got cleared before
 * the failure). The procedure now wraps its body in a transaction with a
 * rollback-and-resignal exit handler; the last test below is a permanent
 * regression test for that fix.
 */
class PlaceBidProcedureIT {

    private int sellerID;
    private int buyerAID;
    private int buyerBID;
    private int buyerCID;
    private int itemID;
    private int auctionID;

    @BeforeEach
    void setUp() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            sellerID = createEndUser(conn, "pbit_seller");
            buyerAID = createEndUser(conn, "pbit_buyerA");
            buyerBID = createEndUser(conn, "pbit_buyerB");
            buyerCID = createEndUser(conn, "pbit_buyerC");

            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO item (categoryID, subcategoryID, itemName, description, itemCondition) " +
                    "VALUES (1, 1, 'PlaceBidIT Item', 'desc', 'new')",
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
                auctionID = keys.getInt(1);
            }
        }
    }

    @AfterEach
    void tearDown() throws Exception {
        try (Connection conn = DatabaseConnection.getConnection()) {
            execUpdate(conn, "DELETE FROM bid_history WHERE auctionID = ?", auctionID);
            execUpdate(conn, "DELETE FROM notification WHERE relatedAuctionID = ?", auctionID);
            execUpdate(conn, "DELETE FROM bid WHERE auctionID = ?", auctionID);
            execUpdate(conn, "DELETE FROM auction WHERE auctionID = ?", auctionID);
            execUpdate(conn, "DELETE FROM item WHERE itemID = ?", itemID);
            execUpdate(conn, "DELETE FROM end_user WHERE userID IN (?, ?, ?, ?)", sellerID, buyerAID, buyerBID, buyerCID);
            execUpdate(conn, "DELETE FROM user WHERE userID IN (?, ?, ?, ?)", sellerID, buyerAID, buyerBID, buyerCID);
        }
    }

    @Test
    void firstBid_setsCurrentPriceToMinimumAndMakesBidderTheWinner() throws Exception {
        callPlaceBid(auctionID, buyerAID, new BigDecimal("200.00"));

        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT currentPrice, winnerID FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, auctionID);
                ResultSet rs = ps.executeQuery();
                rs.next();
                assertEquals(0, rs.getBigDecimal("currentPrice").compareTo(new BigDecimal("200.00")));
                assertEquals(buyerAID, rs.getInt("winnerID"));
            }
        }
    }

    @Test
    void lowerCompetingMax_autoRaisesPriceButLeaderKeepsTheLead() throws Exception {
        // A first bid always sets currentPrice to exactly that bidder's max (a quirk
        // of the real procedure), so the very next bid's minimum requirement already
        // exceeds that max - it can only ever become the new leader, never "lose while
        // raising the price". The "leader keeps the lead, price auto-raises" branch
        // only becomes reachable on a THIRD bid, once there's a gap between the
        // current leader's max and the price their max was capped down to.
        callPlaceBid(auctionID, buyerAID, new BigDecimal("1000.00")); // currentPrice -> 1000, leader=A
        callPlaceBid(auctionID, buyerBID, new BigDecimal("1500.00")); // 1500 > 1000 -> leader=B, currentPrice -> 1010
        callPlaceBid(auctionID, buyerCID, new BigDecimal("1200.00")); // 1200 <= 1500 -> B keeps the lead

        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT currentPrice, winnerID FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, auctionID);
                ResultSet rs = ps.executeQuery();
                rs.next();
                // buyerC's max(1200) + increment(10) = 1210, capped by buyerB's own max(1500)
                assertEquals(0, rs.getBigDecimal("currentPrice").compareTo(new BigDecimal("1210.00")));
                assertEquals(buyerBID, rs.getInt("winnerID"));
            }
            assertWinningFlag(conn, buyerBID, true);
            assertWinningFlag(conn, buyerAID, false);
        }
    }

    @Test
    void higherCompetingMax_changesTheLead() throws Exception {
        callPlaceBid(auctionID, buyerAID, new BigDecimal("200.00"));
        callPlaceBid(auctionID, buyerBID, new BigDecimal("500.00"));

        try (Connection conn = DatabaseConnection.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT currentPrice, winnerID FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, auctionID);
                ResultSet rs = ps.executeQuery();
                rs.next();
                // buyerA's max(200) + increment(10) = 210, capped by buyerB's own max(500)
                assertEquals(0, rs.getBigDecimal("currentPrice").compareTo(new BigDecimal("210.00")));
                assertEquals(buyerBID, rs.getInt("winnerID"));
            }
            assertWinningFlag(conn, buyerAID, false);
            assertWinningFlag(conn, buyerBID, true);
        }
    }

    @Test
    void sellerCannotBidOnOwnAuction() {
        SQLException ex = assertThrows(SQLException.class,
            () -> callPlaceBid(auctionID, sellerID, new BigDecimal("200.00")));
        assertTrue(ex.getMessage().contains("cannot bid on their own"),
            "PlaceBidServlet matches on this exact substring: " + ex.getMessage());
    }

    @Test
    void bidBelowMinimumIsRejected() {
        SQLException ex = assertThrows(SQLException.class,
            () -> callPlaceBid(auctionID, buyerAID, new BigDecimal("105.00")));
        assertTrue(ex.getMessage().contains("must be at least"),
            "PlaceBidServlet matches on this exact substring: " + ex.getMessage());
    }

    @Test
    void failedBidDoesNotCorruptPreviousWinnerState() throws Exception {
        // Establish buyerA as the winner.
        callPlaceBid(auctionID, buyerAID, new BigDecimal("200.00"));

        // A bid from a buyerID with no end_user row violates the bid/bid_history FK
        // constraints partway through the "new leader" branch. Before this session's
        // fix, that partial failure still committed the "clear old winner" update,
        // leaving no row flagged isWinning for the auction at all.
        int nonExistentBuyerID = 999_999;
        assertThrows(SQLException.class,
            () -> callPlaceBid(auctionID, nonExistentBuyerID, new BigDecimal("900.00")));

        try (Connection conn = DatabaseConnection.getConnection()) {
            assertWinningFlag(conn, buyerAID, true);
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT currentPrice, winnerID FROM auction WHERE auctionID = ?")) {
                ps.setInt(1, auctionID);
                ResultSet rs = ps.executeQuery();
                rs.next();
                assertEquals(0, rs.getBigDecimal("currentPrice").compareTo(new BigDecimal("200.00")));
                assertEquals(buyerAID, rs.getInt("winnerID"));
            }
        }
    }

    private static void callPlaceBid(int auctionID, int buyerID, BigDecimal maxBidLimit) throws SQLException {
        try (Connection conn = DatabaseConnection.getConnection();
             CallableStatement cstmt = conn.prepareCall("{CALL place_bid(?, ?, ?)}")) {
            cstmt.setInt(1, auctionID);
            cstmt.setInt(2, buyerID);
            cstmt.setBigDecimal(3, maxBidLimit);
            cstmt.execute();
        }
    }

    private void assertWinningFlag(Connection conn, int buyerID, boolean expected) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT isWinning FROM bid WHERE auctionID = ? AND buyerID = ?")) {
            ps.setInt(1, auctionID);
            ps.setInt(2, buyerID);
            ResultSet rs = ps.executeQuery();
            rs.next();
            assertEquals(expected, rs.getBoolean("isWinning"));
        }
    }

    private static int createEndUser(Connection conn, String username) throws SQLException {
        int userID;
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO user (username, password, email, userType) VALUES (?, 'x', ?, 'end_user')",
                Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, username + "_" + System.nanoTime());
            ps.setString(2, username + System.nanoTime() + "@example.com");
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            keys.next();
            userID = keys.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO end_user (userID, firstName, lastName, address, phone, isAnonymous) " +
                "VALUES (?, 'IT', 'Test', 'addr', '000', 0)")) {
            ps.setInt(1, userID);
            ps.executeUpdate();
        }
        return userID;
    }

    private static void execUpdate(Connection conn, String sql, int... params) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setInt(i + 1, params[i]);
            }
            ps.executeUpdate();
        }
    }
}
