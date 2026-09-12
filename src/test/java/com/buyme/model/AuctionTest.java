package com.buyme.model;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.sql.Timestamp;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class AuctionTest {

    private Auction auctionWith(String status, long closeOffsetMillis) {
        Auction auction = new Auction();
        auction.setStatus(status);
        auction.setCloseDateTime(new Timestamp(System.currentTimeMillis() + closeOffsetMillis));
        return auction;
    }

    @Test
    void isActive_trueWhenActiveAndNotYetClosed() {
        Auction auction = auctionWith("active", 60_000L);
        assertTrue(auction.isActive());
    }

    @Test
    void isActive_falseWhenStatusIsNotActive() {
        Auction auction = auctionWith("pending", 60_000L);
        assertFalse(auction.isActive());

        Auction closed = auctionWith("closed", 60_000L);
        assertFalse(closed.isActive());
    }

    @Test
    void isActive_falseWhenCloseDateTimeHasAlreadyPassed() {
        Auction auction = auctionWith("active", -60_000L);
        assertFalse(auction.isActive());
    }

    @Test
    void isActive_falseWhenCloseDateTimeIsNull() {
        Auction auction = new Auction();
        auction.setStatus("active");
        assertFalse(auction.isActive());
    }

    @Test
    void getMinimumBid_isCurrentPricePlusBidIncrement() {
        Auction auction = new Auction();
        auction.setCurrentPrice(new BigDecimal("100.00"));
        auction.setBidIncrement(new BigDecimal("10.00"));

        assertEquals(new BigDecimal("110.00"), auction.getMinimumBid());
    }

    @Test
    void getMinimumBid_noBidsYet_usesDefaultCurrentPriceAndIncrement() {
        // Default constructor: currentPrice = 0.00, bidIncrement = 0.50
        Auction auction = new Auction();
        assertEquals(new BigDecimal("0.50"), auction.getMinimumBid());
    }
}
