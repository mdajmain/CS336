// File: src/main/java/com/buyme/model/Auction.java
package com.buyme.model;

import java.math.BigDecimal;
import java.sql.Timestamp;

public class Auction {
    private int auctionID;
    private int itemID;
    private int sellerID;
    private BigDecimal initialPrice;
    private BigDecimal bidIncrement;
    private BigDecimal reservePrice;
    private BigDecimal currentPrice;
    private Timestamp startDateTime;
    private Timestamp closeDateTime;
    private String status;
    private Integer winnerID;
    
    // Item details
    private String itemName;
    private String description;
    private String itemCondition;
    private int categoryID;
    private int subcategoryID;
    
    // Seller details
    private String sellerUsername;
    
    // Bid count
    private int bidCount;
    
    // Constructors
    public Auction() {
        this.initialPrice = new BigDecimal("0.01");
        this.bidIncrement = new BigDecimal("0.50");
        this.currentPrice = new BigDecimal("0.00");
        this.status = "pending";
    }
    
    // Getters and Setters
    public int getAuctionID() { return auctionID; }
    public void setAuctionID(int auctionID) { this.auctionID = auctionID; }
    
    public int getItemID() { return itemID; }
    public void setItemID(int itemID) { this.itemID = itemID; }
    
    public int getSellerID() { return sellerID; }
    public void setSellerID(int sellerID) { this.sellerID = sellerID; }
    
    public BigDecimal getInitialPrice() { return initialPrice; }
    public void setInitialPrice(BigDecimal initialPrice) { this.initialPrice = initialPrice; }
    
    public BigDecimal getBidIncrement() { return bidIncrement; }
    public void setBidIncrement(BigDecimal bidIncrement) { this.bidIncrement = bidIncrement; }
    
    public BigDecimal getReservePrice() { return reservePrice; }
    public void setReservePrice(BigDecimal reservePrice) { this.reservePrice = reservePrice; }
    
    public BigDecimal getCurrentPrice() { return currentPrice; }
    public void setCurrentPrice(BigDecimal currentPrice) { this.currentPrice = currentPrice; }
    
    public Timestamp getStartDateTime() { return startDateTime; }
    public void setStartDateTime(Timestamp startDateTime) { this.startDateTime = startDateTime; }
    
    public Timestamp getCloseDateTime() { return closeDateTime; }
    public void setCloseDateTime(Timestamp closeDateTime) { this.closeDateTime = closeDateTime; }
    
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    
    public Integer getWinnerID() { return winnerID; }
    public void setWinnerID(Integer winnerID) { this.winnerID = winnerID; }
    
    public String getItemName() { return itemName; }
    public void setItemName(String itemName) { this.itemName = itemName; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getItemCondition() { return itemCondition; }
    public void setItemCondition(String itemCondition) { this.itemCondition = itemCondition; }
    
    public int getCategoryID() { return categoryID; }
    public void setCategoryID(int categoryID) { this.categoryID = categoryID; }
    
    public int getSubcategoryID() { return subcategoryID; }
    public void setSubcategoryID(int subcategoryID) { this.subcategoryID = subcategoryID; }
    
    public String getSellerUsername() { return sellerUsername; }
    public void setSellerUsername(String sellerUsername) { this.sellerUsername = sellerUsername; }
    
    public int getBidCount() { return bidCount; }
    public void setBidCount(int bidCount) { this.bidCount = bidCount; }
    
    // Helper methods
    public boolean isActive() {
        return "active".equals(status) && 
               closeDateTime != null && 
               closeDateTime.after(new Timestamp(System.currentTimeMillis()));
    }
    
    public BigDecimal getMinimumBid() {
        return currentPrice.add(bidIncrement);
    }
}