<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // Get auction ID from parameter
    String auctionIDStr = request.getParameter("id");
    if (auctionIDStr == null || auctionIDStr.isEmpty()) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=No auction specified");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect(request.getContextPath() + "/index.jsp?error=Invalid auction ID");
        return;
    }
    
    // Get logged in user (optional - can view auctions without login)
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null) ? null : user.getUserType().trim();
    
    // Auction details
    String itemName = "";
    String description = "";
    String itemCondition = "";
    String categoryName = "";
    String subcategoryName = "";
    double initialPrice = 0;
    double currentPrice = 0;
    double bidIncrement = 0;
    Double reservePrice = null;
    Timestamp startDateTime = null;
    Timestamp closeDateTime = null;
    String status = "";
    int sellerID = 0;
    String sellerUsername = "";
    Integer winnerID = null;
    String winnerUsername = "";
    int bidCount = 0;
    boolean isExpired = false;
    boolean userIsHighestBidder = false;
    double userMaxBid = 0;
    
    // Check if current user can see reserve (seller, admin, or rep)
    boolean canSeeReserve = false;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Auction Details - BuyMe</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; min-height: 100vh; }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
        }
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-container a { color: white; text-decoration: none; }
        .nav-links { display: flex; gap: 20px; align-items: center; }
        .nav-links a:hover { text-decoration: underline; }
        
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
        }
        .back-link:hover { text-decoration: underline; }
        
        .auction-container {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 30px;
        }
        
        @media (max-width: 768px) {
            .auction-container { grid-template-columns: 1fr; }
        }
        
        .main-content {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .auction-header {
            padding: 25px;
            border-bottom: 1px solid #eee;
        }
        .auction-header h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 24px;
        }
        .auction-meta {
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
            color: #666;
            font-size: 14px;
        }
        .auction-meta span { display: flex; align-items: center; gap: 5px; }
        
        .status-badge {
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-pending { background: #fff3cd; color: #856404; }
        .status-closed { background: #e2e3e5; color: #383d41; }
        .status-cancelled { background: #f8d7da; color: #721c24; }
        
        .auction-body { padding: 25px; }
        
        .section { margin-bottom: 25px; }
        .section h3 {
            color: #333;
            margin-bottom: 10px;
            font-size: 16px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 5px;
            display: inline-block;
        }
        .section p { color: #666; line-height: 1.6; }
        
        .item-details {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 15px;
        }
        .detail-item {
            background: #f8f9fa;
            padding: 12px;
            border-radius: 5px;
        }
        .detail-item label {
            display: block;
            font-size: 12px;
            color: #666;
            margin-bottom: 3px;
        }
        .detail-item span {
            font-weight: 600;
            color: #333;
        }
        
        .sidebar {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }
        
        .price-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
        }
        .current-price {
            text-align: center;
            margin-bottom: 20px;
        }
        .current-price label {
            display: block;
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }
        .current-price .price {
            font-size: 36px;
            font-weight: bold;
            color: #27ae60;
        }
        .price-details {
            border-top: 1px solid #eee;
            padding-top: 15px;
            margin-top: 15px;
        }
        .price-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
        }
        .price-row label { color: #666; }
        .price-row span { font-weight: 600; color: #333; }
        
        .bid-form { margin-top: 20px; }
        .bid-form input {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
            margin-bottom: 10px;
        }
        .bid-form input:focus {
            border-color: #667eea;
            outline: none;
        }
        .bid-form button {
            width: 100%;
            padding: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: opacity 0.3s;
        }
        .bid-form button:hover { opacity: 0.9; }
        .bid-form button:disabled {
            background: #ccc;
            cursor: not-allowed;
        }
        .bid-note {
            font-size: 12px;
            color: #666;
            margin-top: 10px;
            text-align: center;
        }
        
        .timer-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
            text-align: center;
        }
        .timer-card h3 {
            color: #333;
            margin-bottom: 15px;
        }
        .countdown {
            font-size: 24px;
            font-weight: bold;
            color: #e74c3c;
        }
        .countdown.ended { color: #666; }
        
        .seller-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
        }
        .seller-card h3 {
            color: #333;
            margin-bottom: 15px;
        }
        .seller-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }
        .seller-avatar {
            width: 50px;
            height: 50px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 20px;
        }
        .seller-name { font-weight: 600; color: #333; }
        
        .bid-history {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 25px;
            margin-top: 20px;
        }
        .bid-history h3 {
            color: #333;
            margin-bottom: 15px;
        }
        .bid-list { max-height: 300px; overflow-y: auto; }
        .bid-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .bid-item:last-child { border-bottom: none; }
        .bid-item .bidder { color: #333; }
        .bid-item .amount { font-weight: 600; color: #27ae60; }
        .bid-item .time { font-size: 12px; color: #999; }
        .bid-item.winning { background: #e8f5e9; margin: 0 -10px; padding: 10px; border-radius: 5px; }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        .alert-info { background: #cce5ff; color: #004085; }
        .alert-warning { background: #fff3cd; color: #856404; }
        
        .winner-banner {
            background: linear-gradient(135deg, #27ae60, #2ecc71);
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        .winner-banner h2 { margin-bottom: 5px; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div class="nav-links">
                <a href="<%= request.getContextPath() %>/index.jsp">Home</a>
                <a href="<%= request.getContextPath() %>/browse.jsp">Browse</a>
                <% if (user != null) { %>
                    <a href="<%= request.getContextPath() %>/dashboard.jsp">Dashboard</a>
                    <span>Welcome, <%= user.getUsername() %></span>
                    <a href="<%= request.getContextPath() %>/logout">Logout</a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/login">Login</a>
                    <a href="<%= request.getContextPath() %>/register">Register</a>
                <% } %>
            </div>
        </div>
    </nav>

    <div class="container">
        <a href="javascript:history.back()" class="back-link">← Back</a>
        
        <%
            String message = request.getParameter("message");
            String error = request.getParameter("error");
            
            if (message != null) {
        %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <%
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Get auction details
                String sql = "SELECT a.*, i.itemName, i.description, i.itemCondition, " +
                             "c1.categoryName, c2.categoryName as subcategoryName, " +
                             "u.username as sellerUsername, " +
                             "w.username as winnerUsername, " +
                             "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount " +
                             "FROM auction a " +
                             "JOIN item i ON a.itemID = i.itemID " +
                             "JOIN category c1 ON i.categoryID = c1.categoryID " +
                             "LEFT JOIN category c2 ON i.subcategoryID = c2.categoryID " +
                             "JOIN user u ON a.sellerID = u.userID " +
                             "LEFT JOIN user w ON a.winnerID = w.userID " +
                             "WHERE a.auctionID = ?";
                
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, auctionID);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
        %>
                            <div class="alert alert-error">Auction not found.</div>
        <%
                            return;
                        }
                        
                        itemName = rs.getString("itemName");
                        description = rs.getString("description");
                        itemCondition = rs.getString("itemCondition");
                        categoryName = rs.getString("categoryName");
                        subcategoryName = rs.getString("subcategoryName");
                        initialPrice = rs.getDouble("initialPrice");
                        currentPrice = rs.getDouble("currentPrice");
                        bidIncrement = rs.getDouble("bidIncrement");
                        reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
                        startDateTime = rs.getTimestamp("startDateTime");
                        closeDateTime = rs.getTimestamp("closeDateTime");
                        status = rs.getString("status");
                        sellerID = rs.getInt("sellerID");
                        sellerUsername = rs.getString("sellerUsername");
                        winnerID = rs.getObject("winnerID") != null ? rs.getInt("winnerID") : null;
                        winnerUsername = rs.getString("winnerUsername");
                        bidCount = rs.getInt("bidCount");
                        
                        isExpired = closeDateTime != null && closeDateTime.before(new Timestamp(System.currentTimeMillis()));
                        
                        // Check if user can see reserve price
                        if (user != null) {
                            canSeeReserve = (user.getUserID() == sellerID) || 
                                           "admin".equalsIgnoreCase(userType) || 
                                           "customer_rep".equalsIgnoreCase(userType);
                            
                            // Check if user is highest bidder
                            if ("end_user".equalsIgnoreCase(userType)) {
                                try (PreparedStatement bidPs = conn.prepareStatement(
                                    "SELECT maxBidLimit, isWinning FROM bid WHERE auctionID = ? AND buyerID = ?")) {
                                    bidPs.setInt(1, auctionID);
                                    bidPs.setInt(2, user.getUserID());
                                    try (ResultSet bidRs = bidPs.executeQuery()) {
                                        if (bidRs.next()) {
                                            userMaxBid = bidRs.getDouble("maxBidLimit");
                                            userIsHighestBidder = bidRs.getBoolean("isWinning");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Show winner banner if auction is closed and has a winner
                if ("closed".equals(status) && winnerID != null) {
                    boolean reserveMet = (reservePrice == null || currentPrice >= reservePrice);
                    if (reserveMet) {
        %>
                        <div class="winner-banner">
                            <h2>🎉 Auction Ended!</h2>
                            <p>Winner: <strong><%= winnerUsername %></strong> with a bid of <strong>$<%= String.format("%.2f", currentPrice) %></strong></p>
                        </div>
        <%
                    } else {
        %>
                        <div class="alert alert-warning">
                            <strong>Auction Ended - Reserve Not Met</strong><br>
                            The reserve price was not met. No winner for this auction.
                        </div>
        <%
                    }
                }
        %>
        
        <div class="auction-container">
            <div class="main-content">
                <div class="auction-header">
                    <h1><%= itemName %></h1>
                    <div class="auction-meta">
                        <span><strong>Category:</strong> <%= categoryName %><%= subcategoryName != null ? " > " + subcategoryName : "" %></span>
                        <span><strong>Condition:</strong> <%= itemCondition %></span>
                        <span><strong>Bids:</strong> <%= bidCount %></span>
                        <span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span>
                    </div>
                </div>
                
                <div class="auction-body">
                    <div class="section">
                        <h3>Description</h3>
                        <p><%= description != null && !description.isEmpty() ? description : "No description provided." %></p>
                    </div>
                    
                    <%
                        // Get item fields
                        try (PreparedStatement fieldPs = conn.prepareStatement(
                            "SELECT fieldName, fieldValue FROM item_field WHERE itemID = (SELECT itemID FROM auction WHERE auctionID = ?)")) {
                            fieldPs.setInt(1, auctionID);
                            try (ResultSet fieldRs = fieldPs.executeQuery()) {
                                boolean hasFields = false;
                    %>
                    <div class="section">
                        <h3>Item Details</h3>
                        <div class="item-details">
                    <%
                                while (fieldRs.next()) {
                                    hasFields = true;
                                    String fieldName = fieldRs.getString("fieldName");
                                    String fieldValue = fieldRs.getString("fieldValue");
                    %>
                            <div class="detail-item">
                                <label><%= fieldName.replace("_", " ").toUpperCase() %></label>
                                <span><%= fieldValue %></span>
                            </div>
                    <%
                                }
                                if (!hasFields) {
                    %>
                            <p style="color: #666;">No additional details available.</p>
                    <%
                                }
                    %>
                        </div>
                    </div>
                    <%
                            }
                        }
                    %>
                </div>
            </div>
            
            <div class="sidebar">
                <div class="price-card">
                    <div class="current-price">
                        <label>Current Price</label>
                        <div class="price">$<%= String.format("%.2f", currentPrice) %></div>
                    </div>
                    
                    <div class="price-details">
                        <div class="price-row">
                            <label>Starting Price:</label>
                            <span>$<%= String.format("%.2f", initialPrice) %></span>
                        </div>
                        <div class="price-row">
                            <label>Bid Increment:</label>
                            <span>$<%= String.format("%.2f", bidIncrement) %></span>
                        </div>
                        <div class="price-row">
                            <label>Minimum Bid:</label>
                            <span>$<%= String.format("%.2f", currentPrice + bidIncrement) %></span>
                        </div>
                        <% if (canSeeReserve && reservePrice != null) { %>
                        <div class="price-row">
                            <label>Reserve Price:</label>
                            <span>$<%= String.format("%.2f", reservePrice) %></span>
                        </div>
                        <% } %>
                    </div>
                    
                    <% if (userIsHighestBidder) { %>
                        <div class="alert alert-success" style="margin-top: 15px;">
                            You are the highest bidder! (Max: $<%= String.format("%.2f", userMaxBid) %>)
                        </div>
                    <% } else if (userMaxBid > 0) { %>
                        <div class="alert alert-warning" style="margin-top: 15px;">
                            You have been outbid. Your max bid was $<%= String.format("%.2f", userMaxBid) %>
                        </div>
                    <% } %>
                    
                    <% if ("active".equals(status) && !isExpired) { %>
                        <% if (user == null) { %>
                            <div class="alert alert-info" style="margin-top: 15px;">
                                <a href="<%= request.getContextPath() %>/login">Login</a> to place a bid
                            </div>
                        <% } else if (user.getUserID() == sellerID) { %>
                            <div class="alert alert-info" style="margin-top: 15px;">
                                This is your auction
                            </div>
                        <% } else if ("end_user".equalsIgnoreCase(userType)) { %>
                            <form class="bid-form" action="<%= request.getContextPath() %>/place-bid" method="post">
                                <input type="hidden" name="auctionID" value="<%= auctionID %>">
                                <input type="number" name="maxBid" step="0.01" 
                                       min="<%= String.format("%.2f", currentPrice + bidIncrement) %>" 
                                       placeholder="Enter your maximum bid"
                                       required>
                                <button type="submit">Place Bid</button>
                                <p class="bid-note">
                                    Enter your maximum bid. The system will automatically bid for you up to this amount.
                                </p>
                            </form>
                        <% } %>
                    <% } else { %>
                        <div class="alert alert-info" style="margin-top: 15px;">
                            This auction is <%= status %>
                        </div>
                    <% } %>
                </div>
                
                <div class="timer-card">
                    <h3><%= isExpired || "closed".equals(status) ? "Auction Ended" : "Time Remaining" %></h3>
                    <div class="countdown <%= isExpired || "closed".equals(status) ? "ended" : "" %>" 
                         id="countdown" 
                         data-end="<%= closeDateTime != null ? closeDateTime.getTime() : 0 %>">
                        <%= isExpired || "closed".equals(status) ? "Ended" : "Loading..." %>
                    </div>
                    <p style="font-size: 12px; color: #666; margin-top: 10px;">
                        Ends: <%= closeDateTime %>
                    </p>
                </div>
                
                <div class="seller-card">
                    <h3>Seller</h3>
                    <div class="seller-info">
                        <div class="seller-avatar"><%= sellerUsername.substring(0, 1).toUpperCase() %></div>
                        <div>
                            <div class="seller-name"><%= sellerUsername %></div>
                            <div style="font-size: 12px; color: #666;">Member</div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- Bid History -->
        <div class="bid-history">
            <h3>Bid History (<%= bidCount %> bids)</h3>
            <div class="bid-list">
                <%
                    try (PreparedStatement histPs = conn.prepareStatement(
                        "SELECT bh.*, u.username FROM bid_history bh " +
                        "JOIN user u ON bh.buyerID = u.userID " +
                        "WHERE bh.auctionID = ? ORDER BY bh.bidTime DESC LIMIT 50")) {
                        histPs.setInt(1, auctionID);
                        try (ResultSet histRs = histPs.executeQuery()) {
                            boolean hasBids = false;
                            boolean isFirst = true;
                            
                            while (histRs.next()) {
                                hasBids = true;
                                String bidderName = histRs.getString("username");
                                double bidAmount = histRs.getDouble("bidAmount");
                                Timestamp bidTime = histRs.getTimestamp("bidTime");
                %>
                    <div class="bid-item <%= isFirst ? "winning" : "" %>">
                        <div>
                            <span class="bidder"><%= bidderName %></span>
                            <span class="time"><%= bidTime %></span>
                        </div>
                        <span class="amount">$<%= String.format("%.2f", bidAmount) %></span>
                    </div>
                <%
                                isFirst = false;
                            }
                            
                            if (!hasBids) {
                %>
                    <p style="color: #666; text-align: center; padding: 20px;">No bids yet. Be the first to bid!</p>
                <%
                            }
                        }
                    }
                %>
            </div>
        </div>
        
        <%
            } catch (Exception e) {
                e.printStackTrace();
        %>
            <div class="alert alert-error">Error loading auction: <%= e.getMessage() %></div>
        <%
            }
        %>
    </div>
    
    <script>
        // Countdown timer
        function updateCountdown() {
            var countdownEl = document.getElementById('countdown');
            var endTime = parseInt(countdownEl.getAttribute('data-end'));
            
            if (endTime === 0) return;
            
            var now = new Date().getTime();
            var distance = endTime - now;
            
            if (distance < 0) {
                countdownEl.textContent = 'Ended';
                countdownEl.classList.add('ended');
                return;
            }
            
            var days = Math.floor(distance / (1000 * 60 * 60 * 24));
            var hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            var minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
            var seconds = Math.floor((distance % (1000 * 60)) / 1000);
            
            var text = '';
            if (days > 0) text += days + 'd ';
            if (hours > 0 || days > 0) text += hours + 'h ';
            text += minutes + 'm ' + seconds + 's';
            
            countdownEl.textContent = text;
        }
        
        updateCountdown();
        setInterval(updateCountdown, 1000);
    </script>
</body>
</html>
