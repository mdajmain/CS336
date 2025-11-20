// File: src/main/java/com/buyme/model/Bid.java
package com.buyme.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Bid {
    private int bidID;
    private int auctionID;
    private int buyerID;
    private BigDecimal bidAmount;
    private BigDecimal maxBidLimit;
    private Timestamp bidTime;
    private boolean isWinning;
    
    // Additional fields for display
    private String buyerUsername;
    private String itemName;
    private String auctionStatus;
    
    // Constructors
    public Bid() {}
    
    public Bid(int auctionID, int buyerID, BigDecimal maxBidLimit) {
        this.auctionID = auctionID;
        this.buyerID = buyerID;
        this.maxBidLimit = maxBidLimit;
        this.bidTime = new Timestamp(System.currentTimeMillis());
    }
    
    // Getters and Setters
    public int getBidID() { return bidID; }
    public void setBidID(int bidID) { this.bidID = bidID; }
    
    public int getAuctionID() { return auctionID; }
    public void setAuctionID(int auctionID) { this.auctionID = auctionID; }
    
    public int getBuyerID() { return buyerID; }
    public void setBuyerID(int buyerID) { this.buyerID = buyerID; }
    
    public BigDecimal getBidAmount() { return bidAmount; }
    public void setBidAmount(BigDecimal bidAmount) { this.bidAmount = bidAmount; }
    
    public BigDecimal getMaxBidLimit() { return maxBidLimit; }
    public void setMaxBidLimit(BigDecimal maxBidLimit) { this.maxBidLimit = maxBidLimit; }
    
    public Timestamp getBidTime() { return bidTime; }
    public void setBidTime(Timestamp bidTime) { this.bidTime = bidTime; }
    
    public boolean isWinning() { return isWinning; }
    public void setWinning(boolean winning) { isWinning = winning; }
    
    public String getBuyerUsername() { return buyerUsername; }
    public void setBuyerUsername(String buyerUsername) { this.buyerUsername = buyerUsername; }
    
    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }
    
    public String getAuctionStatus() { return auctionStatus; }
    public void setAuctionStatus(String auctionStatus) { this.auctionStatus = auctionStatus; }
}