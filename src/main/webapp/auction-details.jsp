<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="com.buyme.model.Bid" %>
<%@ page import="com.buyme.dao.BidDAO" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.math.BigDecimal" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List" %>
<%
    User user = (User) session.getAttribute("user");
    
    String auctionID = request.getParameter("id");
    if (auctionID == null) {
        response.sendRedirect("browse.jsp");
        return;
    }
    
    // Load auction details
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    String itemName = "";
    String description = "";
    String condition = "";
    BigDecimal currentPrice = BigDecimal.ZERO;
    BigDecimal bidIncrement = BigDecimal.ZERO;
    BigDecimal minBid = BigDecimal.ZERO;
    Timestamp closeDateTime = null;
    int sellerID = 0;
    String sellerName = "";
    String status = "";
    int bidCount = 0;
    boolean isOwnAuction = false;
    int subcategoryID = 0;
    String categoryName = "";
    
    try {
        conn = com.buyme.util.DatabaseConnection.getConnection();
        
        // Get auction details
        String sql = "SELECT a.*, i.*, u.username as sellerName, c.categoryName, " +
                    "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "JOIN user u ON a.sellerID = u.userID " +
                    "LEFT JOIN category c ON i.subcategoryID = c.categoryID " +
                    "WHERE a.auctionID = ?";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, Integer.parseInt(auctionID));
        rs = pstmt.executeQuery();
        
        if (rs.next()) {
            itemName = rs.getString("itemName");
            description = rs.getString("description");
            condition = rs.getString("itemCondition");
            currentPrice = rs.getBigDecimal("currentPrice");
            bidIncrement = rs.getBigDecimal("bidIncrement");
            closeDateTime = rs.getTimestamp("closeDateTime");
            sellerID = rs.getInt("sellerID");
            sellerName = rs.getString("sellerName");
            status = rs.getString("status");
            bidCount = rs.getInt("bidCount");
            subcategoryID = rs.getInt("subcategoryID");
            categoryName = rs.getString("categoryName");
            
            minBid = currentPrice.add(bidIncrement);
            isOwnAuction = (sellerID == user.getUserID());
        } else {
            response.sendRedirect("browse.jsp");
            return;
        }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= itemName %> - BuyMe Auction</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 20px;
        }
        
        .logo {
            color: white;
            font-size: 24px;
            font-weight: bold;
            text-decoration: none;
        }
        
        .nav-menu {
            display: flex;
            list-style: none;
            gap: 30px;
        }
        
        .nav-menu a {
            color: white;
            text-decoration: none;
        }
        
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
            font-weight: 500;
        }
        
        .auction-detail {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 30px;
            margin-bottom: 30px;
        }
        
        .main-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .bid-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            height: fit-content;
            position: sticky;
            top: 20px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .breadcrumb {
            color: #666;
            font-size: 14px;
            margin-bottom: 15px;
        }
        
        .breadcrumb a {
            color: #667eea;
            text-decoration: none;
        }
        
        .item-info {
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 1px solid #e1e1e1;
        }
        
        .info-row {
            display: flex;
            margin-bottom: 10px;
        }
        
        .info-label {
            font-weight: 600;
            color: #666;
            width: 150px;
        }
        
        .info-value {
            color: #333;
        }
        
        .info-value a {
            color: #667eea;
            text-decoration: none;
        }
        
        .info-value a:hover {
            text-decoration: underline;
        }
        
        .current-price {
            font-size: 36px;
            color: #28a745;
            font-weight: bold;
            margin-bottom: 10px;
        }
        
        .bid-count {
            color: #666;
            margin-bottom: 20px;
        }
        
        .bid-form {
            margin-top: 20px;
        }
        
        .bid-input {
            width: 100%;
            padding: 12px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 18px;
            margin-bottom: 10px;
        }
        
        .bid-btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 18px;
            font-weight: bold;
            cursor: pointer;
        }
        
        .bid-btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        
        .time-left {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            text-align: center;
            margin-bottom: 20px;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        .section h3 {
            color: #333;
            margin-bottom: 20px;
            font-size: 20px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th {
            background: #f8f9fa;
            padding: 10px;
            text-align: left;
            border-bottom: 2px solid #dee2e6;
        }
        
        td {
            padding: 10px;
            border-bottom: 1px solid #dee2e6;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .help-text {
            font-size: 14px;
            color: #666;
            margin-top: 10px;
        }
        
        .alert {
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .alert-success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        
        .alert-error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        
        .alert-warning {
            background: #fff3cd;
            color: #856404;
            border: 1px solid #ffeeba;
        }
        
        /* Similar Items */
        .similar-items-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
            gap: 20px;
        }
        
        .similar-item-card {
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            padding: 15px;
            transition: all 0.3s;
        }
        
        .similar-item-card:hover {
            border-color: #667eea;
            box-shadow: 0 3px 10px rgba(102, 126, 234, 0.2);
        }
        
        .similar-item-title {
            font-weight: 600;
            color: #333;
            margin-bottom: 8px;
            font-size: 15px;
        }
        
        .similar-item-price {
            font-size: 20px;
            color: #28a745;
            font-weight: bold;
            margin-bottom: 8px;
        }
        
        .similar-item-meta {
            font-size: 13px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .similar-item-btn {
            display: block;
            width: 100%;
            padding: 8px;
            background: #667eea;
            color: white;
            text-align: center;
            text-decoration: none;
            border-radius: 5px;
            font-size: 14px;
        }
        
        .similar-item-btn:hover {
            background: #5568d3;
        }
        
        .no-similar {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        @media (max-width: 968px) {
            .auction-detail {
                grid-template-columns: 1fr;
            }
            
            .bid-section {
                position: static;
            }
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="logo">BuyMe</a>
            
            <ul class="nav-menu">
                <li><a href="dashboard.jsp">Home</a></li>
                <li><a href="browse.jsp">Browse Auctions</a></li>
                <li><a href="create-auction.jsp">Sell Item</a></li>
                <li><a href="my-bids.jsp">My Bids</a></li>
            </ul>
        </div>
    </nav>
    
    <div class="container">
        <a href="browse.jsp" class="back-link">← Back to Browse</a>
        
        <% if (request.getAttribute("success") != null) { %>
            <div class="alert alert-success"><%= request.getAttribute("success") %></div>
        <% } %>
        
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-error"><%= request.getAttribute("error") %></div>
        <% } %>
        
        <div class="auction-detail">
            <div class="main-section">
                <div class="breadcrumb">
                    <a href="browse.jsp">Auctions</a> › 
                    <% if (categoryName != null && !categoryName.isEmpty()) { %>
                        <%= categoryName %> ›
                    <% } %>
                    Auction #<%= auctionID %>
                </div>
                
                <h1><%= itemName %></h1>
                
                <div class="item-info">
                    <div class="info-row">
                        <div class="info-label">Seller:</div>
                        <div class="info-value">
                            <a href="user-auctions.jsp?userID=<%= sellerID %>"><%= sellerName %></a>
                        </div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Condition:</div>
                        <div class="info-value"><%= condition %></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Auction Ends:</div>
                        <div class="info-value"><%= closeDateTime %></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Status:</div>
                        <div class="info-value"><%= status.toUpperCase() %></div>
                    </div>
                    <div class="info-row">
                        <div class="info-label">Bid Increment:</div>
                        <div class="info-value">$<%= String.format("%.2f", bidIncrement) %></div>
                    </div>
                </div>
                
                <h3>Description</h3>
                <p style="margin-top: 10px; line-height: 1.6;"><%= description %></p>
            </div>
            
            <div class="bid-section">
                <div class="current-price">
                    $<%= String.format("%.2f", currentPrice) %>
                </div>
                <div class="bid-count">
                    <%= bidCount %> bid<%= bidCount != 1 ? "s" : "" %>
                </div>
                
                <div class="time-left">
                    <%
                        long timeLeft = closeDateTime.getTime() - System.currentTimeMillis();
                        long daysLeft = timeLeft / (1000 * 60 * 60 * 24);
                        long hoursLeft = (timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60);
                        
                        if (timeLeft > 0) {
                            out.println("<strong>" + daysLeft + " days, " + hoursLeft + " hours left</strong>");
                        } else {
                            out.println("<strong style='color:red;'>Auction Ended</strong>");
                        }
                    %>
                </div>
                
                <% if ("active".equals(status) && !isOwnAuction) { %>
                <form action="PlaceBidServlet" method="post" class="bid-form">
                    <input type="hidden" name="auctionID" value="<%= auctionID %>">
                
                    <label for="bidAmount" style="font-weight: 600; margin-bottom: 10px; display: block;">
                        Your bid amount
                    </label>
                
                    <input type="number"
                           name="bidAmount"
                           id="bidAmount"
                           class="bid-input"
                           min="<%= minBid %>"
                           step="0.01"
                           placeholder="Minimum: $<%= String.format("%.2f", minBid) %>"
                           required>
                
                    <div class="help-text" style="margin: 8px 0;">
                        This is the amount you are bidding right now.
                    </div>
                
                    <label style="display: block; margin-top: 10px;">
                        <input type="checkbox" id="useAuto" name="useAuto" value="true"
                               onclick="document.getElementById('autoMaxContainer').style.display = this.checked ? 'block' : 'none';">
                        Use automatic bidding up to a higher maximum
                    </label>
                
                    <div id="autoMaxContainer" style="display:none; margin-top: 10px;">
                        <label for="maxBidAmount" style="font-weight: 600; margin-bottom: 5px; display: block;">
                            Maximum you are willing to pay
                        </label>
                        <input type="number"
                               name="maxBidAmount"
                               id="maxBidAmount"
                               class="bid-input"
                               min="<%= minBid %>"
                               step="0.01">
                        <div class="help-text">
                            We will automatically bid for you up to this maximum.
                        </div>
                    </div>
                
                    <button type="submit" class="bid-btn" style="margin-top: 15px;">Place Bid</button>
                
                    <div class="help-text" style="margin-top: 10px;">
                        <strong>Minimum bid:</strong> $<%= String.format("%.2f", minBid) %>
                        (Current + $<%= String.format("%.2f", bidIncrement) %> increment)
                    </div>
                </form>
                <% } else if (isOwnAuction) { %>
                <div class="alert alert-warning">
                    This is your own auction. You cannot bid on it.
                </div>
                <% } else { %>
                <div class="alert alert-warning">
                    This auction is not currently active.
                </div>
                <% } %>
            </div>
        </div>
        
        <!-- Bid History Section -->
        <div class="section" id="history">
            <h3>📜 Complete Bid History</h3>
            <table>
                <thead>
                    <tr>
                        <th>Bidder</th>
                        <th>Bid Amount</th>
                        <th>Time</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        List<Bid> bidHistory = new BidDAO().getBidHistoryForAuction(Integer.parseInt(auctionID));
                        SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy HH:mm:ss");
                        for (Bid histBid : bidHistory) {
                    %>
                    <tr>
                        <td><%= histBid.getBuyerUsername() %></td>
                        <td><strong>$<%= String.format("%.2f", histBid.getBidAmount().doubleValue()) %></strong></td>
                        <td><%= sdf.format(histBid.getBidTime()) %></td>
                        <td><%= histBid.isWinning() ? "Was Winning" : "-" %></td>
                    </tr>
                    <%
                        }
                        if (bidHistory.isEmpty()) {
                            out.println("<tr><td colspan='4' style='text-align:center; color:#999; padding: 30px;'>No bids yet. Be the first to bid!</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>
        
        <!-- Similar Items Section -->
        <div class="section">
            <h3>🔍 Similar Items (Past 30 Days)</h3>
            <p style="color: #666; margin-bottom: 20px;">
                Other auctions in the same category with similar pricing
            </p>
            
            <%
                // Get similar items from the same subcategory in the last 30 days
                PreparedStatement similarStmt = conn.prepareStatement(
                    "SELECT a.auctionID, a.currentPrice, a.status, a.closeDateTime, " +
                    "i.itemName, i.itemCondition, " +
                    "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "WHERE i.subcategoryID = ? " +
                    "AND a.auctionID != ? " +
                    "AND a.startDateTime >= DATE_SUB(NOW(), INTERVAL 30 DAY) " +
                    "AND a.status IN ('active', 'closed') " +
                    "AND ABS(a.currentPrice - ?) / ? <= 0.3 " +
                    "ORDER BY ABS(a.currentPrice - ?) ASC, a.closeDateTime DESC " +
                    "LIMIT 6"
                );
                similarStmt.setInt(1, subcategoryID);
                similarStmt.setInt(2, Integer.parseInt(auctionID));
                similarStmt.setDouble(3, currentPrice.doubleValue());
                similarStmt.setDouble(4, currentPrice.doubleValue());
                similarStmt.setDouble(5, currentPrice.doubleValue());
                
                ResultSet similarRs = similarStmt.executeQuery();
                boolean hasSimilar = false;
            %>
            
            <div class="similar-items-grid">
                <%
                    SimpleDateFormat dateFormat = new SimpleDateFormat("MMM dd, yyyy");
                    while(similarRs.next()) {
                        hasSimilar = true;
                        int simAuctionID = similarRs.getInt("auctionID");
                        String simItemName = similarRs.getString("itemName");
                        double simPrice = similarRs.getDouble("currentPrice");
                        String simStatus = similarRs.getString("status");
                        Timestamp simCloseTime = similarRs.getTimestamp("closeDateTime");
                        String simCondition = similarRs.getString("itemCondition");
                        int simBidCount = similarRs.getInt("bidCount");
                        
                        // Calculate price difference
                        double priceDiff = simPrice - currentPrice.doubleValue();
                        String priceDiffStr = (priceDiff >= 0 ? "+" : "") + String.format("%.2f", priceDiff);
                %>
                <div class="similar-item-card">
                    <div class="similar-item-title"><%= simItemName %></div>
                    <div class="similar-item-price">
                        $<%= String.format("%.2f", simPrice) %>
                        <span style="font-size: 12px; color: #666;">
                            (<%= priceDiffStr %>)
                        </span>
                    </div>
                    <div class="similar-item-meta">
                        <div>Condition: <%= simCondition %></div>
                        <div><%= simBidCount %> bid<%= simBidCount != 1 ? "s" : "" %></div>
                        <div style="margin-top: 5px;">
                            <% if ("active".equals(simStatus)) { %>
                                <span style="color: #28a745;">● Active</span>
                                <div style="font-size: 11px;">Ends: <%= dateFormat.format(simCloseTime) %></div>
                            <% } else { %>
                                <span style="color: #dc3545;">● Closed</span>
                                <div style="font-size: 11px;">Ended: <%= dateFormat.format(simCloseTime) %></div>
                            <% } %>
                        </div>
                    </div>
                    <a href="auction-details.jsp?id=<%= simAuctionID %>" class="similar-item-btn">
                        View Auction
                    </a>
                </div>
                <%
                    }
                    
                    if (!hasSimilar) {
                %>
                <div class="no-similar" style="grid-column: 1/-1;">
                    <p>No similar items found in the past 30 days.</p>
                </div>
                <%
                    }
                %>
            </div>
        </div>
        
    </div>
    <%
        } catch(Exception e) {
            e.printStackTrace();
        } finally {
            if (conn != null) conn.close();
        }
    %>
</body>
</html>

