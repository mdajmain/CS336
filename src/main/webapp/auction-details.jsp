<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.math.BigDecimal" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
    
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
    
    try {
        conn = com.buyme.util.DatabaseConnection.getConnection();
        
        // Get auction details
        String sql = "SELECT a.*, i.*, u.username as sellerName, " +
                    "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                    "FROM auction a " +
                    "JOIN item i ON a.itemID = i.itemID " +
                    "JOIN user u ON a.sellerID = u.userID " +
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
            max-width: 1200px;
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
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .auction-detail {
            display: grid;
            grid-template-columns: 1fr 400px;
            gap: 30px;
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
        }
        
        h1 {
            color: #333;
            margin-bottom: 20px;
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
            width: 120px;
        }
        
        .info-value {
            color: #333;
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
        
        .bid-history {
            margin-top: 30px;
        }
        
        .bid-history h3 {
            color: #333;
            margin-bottom: 20px;
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
        <% if (request.getAttribute("success") != null) { %>
            <div class="alert alert-success"><%= request.getAttribute("success") %></div>
        <% } %>
        
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-error"><%= request.getAttribute("error") %></div>
        <% } %>
        
        <div class="auction-detail">
            <div class="main-section">
                <h1><%= itemName %></h1>
                
                <div class="item-info">
                    <div class="info-row">
                        <div class="info-label">Seller:</div>
                        <div class="info-value"><%= sellerName %></div>
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
                </div>
                
                <h3>Description</h3>
                <p style="margin-top: 10px; line-height: 1.6;"><%= description %></p>
                
                <div class="bid-history">
                    <h3>Bid History</h3>
                    <table>
                        <thead>
                            <tr>
                                <th>Bidder</th>
                                <th>Bid Amount</th>
                                <th>Time</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                PreparedStatement histStmt = conn.prepareStatement(
                                    "SELECT bh.*, u.username " +
                                    "FROM bid_history bh " +
                                    "JOIN user u ON bh.buyerID = u.userID " +
                                    "WHERE bh.auctionID = ? " +
                                    "ORDER BY bh.bidTime DESC"
                                );
                                histStmt.setInt(1, Integer.parseInt(auctionID));
                                ResultSet histRs = histStmt.executeQuery();
                                
                                boolean hasHistory = false;
                                while(histRs.next()) {
                                    hasHistory = true;
                            %>
                            <tr>
                                <td><%= histRs.getString("username") %></td>
                                <td>$<%= String.format("%.2f", histRs.getDouble("bidAmount")) %></td>
                                <td><%= histRs.getTimestamp("bidTime") %></td>
                            </tr>
                            <%
                                }
                                if (!hasHistory) {
                                    out.println("<tr><td colspan='3' style='text-align:center; color:#999;'>No bids yet</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>
                </div>
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
