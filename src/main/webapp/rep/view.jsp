<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.util.DatabaseConnection" %>
<%@ page import="com.buyme.model.User" %>
<%
    // Session check - must be logged in as customer rep
    User user = (User) session.getAttribute("user");
	if (user == null || !"customer_rep".equals(user.getUserType())) {
	    response.sendRedirect(request.getContextPath() + "/login");
	    return;
	}
    // Get auction ID
    String idParam = request.getParameter("id");
    if (idParam == null || idParam.trim().isEmpty()) {
        response.sendRedirect("manage-auctions.jsp?error=No auction ID provided");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(idParam);
    } catch (NumberFormatException e) {
        response.sendRedirect("manage-auctions.jsp?error=Invalid auction ID");
        return;
    }
    
    // Handle actions
    String action = request.getParameter("action");
    String message = null;
    String error = null;
    
    if ("cancelBid".equals(action) && "POST".equals(request.getMethod())) {
        String historyIdParam = request.getParameter("historyID");
        String reason = request.getParameter("reason");
        
        if (historyIdParam != null && reason != null && !reason.trim().isEmpty()) {
            try (Connection conn = DatabaseConnection.getConnection()) {
                // Get bid details first
                String getBidSql = "SELECT bh.*, u.username, u.email FROM bid_history bh JOIN user u ON bh.buyerID = u.userID WHERE bh.historyID = ?";
                try (PreparedStatement ps = conn.prepareStatement(getBidSql)) {
                    ps.setInt(1, Integer.parseInt(historyIdParam));
                    ResultSet rs = ps.executeQuery();
                    
                    if (rs.next()) {
                        double bidAmount = rs.getDouble("bidAmount");
                        String bidderUsername = rs.getString("username");
                        
                        // Delete the bid
                        String deleteSql = "DELETE FROM bid_history WHERE historyID = ?";
                        try (PreparedStatement deletePs = conn.prepareStatement(deleteSql)) {
                            deletePs.setInt(1, Integer.parseInt(historyIdParam));
                            deletePs.executeUpdate();
                        }
                        
                        // Update current price to highest remaining bid or starting price
                        String updatePriceSql = "UPDATE auction SET currentPrice = COALESCE((SELECT MAX(bidAmount) FROM bid_history WHERE auctionID = ?), initialPrice) WHERE auctionID = ?";
                        try (PreparedStatement updatePs = conn.prepareStatement(updatePriceSql)) {
                            updatePs.setInt(1, auctionID);
                            updatePs.setInt(2, auctionID);
                            updatePs.executeUpdate();
                        }
                        
                        // Log the action
                        String logSql = "INSERT INTO rep_action_log (repID, actionType, targetID, targetType, reason, actionDate) VALUES (?, 'CANCEL_BID', ?, 'BID', ?, NOW())";
                        try (PreparedStatement logPs = conn.prepareStatement(logSql)) {
                            logPs.setInt(1, user.getUserID());
                            logPs.setInt(2, Integer.parseInt(historyIdParam));
                            logPs.setString(3, reason);
                            logPs.executeUpdate();
                        } catch (SQLException e) {
                            // Log table might not exist, continue anyway
                        }
                        
                        message = "Bid #" + historyIdParam + " ($" + String.format("%.2f", bidAmount) + ") by " + bidderUsername + " has been cancelled.";
                    }
                }
            } catch (Exception e) {
                error = "Error cancelling bid: " + e.getMessage();
                e.printStackTrace();
            }
        } else {
            error = "Reason is required to cancel a bid.";
        }
    }
    
    if ("cancelUserBids".equals(action) && "POST".equals(request.getMethod())) {
        String userIdParam = request.getParameter("userID");
        String reason = request.getParameter("reason");
        
        if (userIdParam != null && reason != null && !reason.trim().isEmpty()) {
            try (Connection conn = DatabaseConnection.getConnection()) {
                int targetUserID = Integer.parseInt(userIdParam);
                
                // Count bids to be deleted
                String countSql = "SELECT COUNT(*) as cnt FROM bid_history WHERE auctionID = ? AND buyerID = ?";
                int bidCount = 0;
                try (PreparedStatement ps = conn.prepareStatement(countSql)) {
                    ps.setInt(1, auctionID);
                    ps.setInt(2, targetUserID);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        bidCount = rs.getInt("cnt");
                    }
                }
                
                if (bidCount > 0) {
                    // Delete all bids from this user on this auction
                    String deleteSql = "DELETE FROM bid_history WHERE auctionID = ? AND buyerID = ?";
                    try (PreparedStatement deletePs = conn.prepareStatement(deleteSql)) {
                        deletePs.setInt(1, auctionID);
                        deletePs.setInt(2, targetUserID);
                        deletePs.executeUpdate();
                    }
                    
                    // Update current price
                    String updatePriceSql = "UPDATE auction SET currentPrice = COALESCE((SELECT MAX(bidAmount) FROM bid_history WHERE auctionID = ?), initialPrice) WHERE auctionID = ?";
                    try (PreparedStatement updatePs = conn.prepareStatement(updatePriceSql)) {
                        updatePs.setInt(1, auctionID);
                        updatePs.setInt(2, auctionID);
                        updatePs.executeUpdate();
                    }
                    
                    // Log the action
                    String logSql = "INSERT INTO rep_action_log (repID, actionType, targetID, targetType, reason, actionDate) VALUES (?, 'CANCEL_USER_BIDS', ?, 'USER_AUCTION', ?, NOW())";
                    try (PreparedStatement logPs = conn.prepareStatement(logSql)) {
                        logPs.setInt(1, user.getUserID());
                        logPs.setInt(2, targetUserID);
                        logPs.setString(3, reason + " (Auction #" + auctionID + ")");
                        logPs.executeUpdate();
                    } catch (SQLException e) {
                        // Log table might not exist
                    }
                    
                    message = bidCount + " bid(s) from user #" + targetUserID + " have been cancelled.";
                } else {
                    error = "No bids found for this user on this auction.";
                }
            } catch (Exception e) {
                error = "Error cancelling user bids: " + e.getMessage();
                e.printStackTrace();
            }
        } else {
            error = "Reason is required to cancel bids.";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Auction Details - Rep View | BuyMe</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
            min-height: 100vh;
        }
        
        .navbar {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: white;
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .navbar h2 {
            font-size: 1.3rem;
        }
        
        .navbar a {
            color: #4da6ff;
            text-decoration: none;
        }
        
        .navbar a:hover {
            text-decoration: underline;
        }
        
        .rep-badge {
            background: #e74c3c;
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px;
        }
        
        .alert {
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-weight: 500;
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
        
        .grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 30px;
        }
        
        @media (max-width: 1000px) {
            .grid {
                grid-template-columns: 1fr;
            }
        }
        
        .card {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        
        .card-header {
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: white;
            padding: 20px;
            font-size: 1.2rem;
            font-weight: 600;
        }
        
        .card-header.warning {
            background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
        }
        
        .card-body {
            padding: 25px;
        }
        
        .auction-image {
            width: 100%;
            max-height: 300px;
            object-fit: cover;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #eee;
        }
        
        .detail-row:last-child {
            border-bottom: none;
        }
        
        .detail-label {
            color: #666;
            font-weight: 500;
        }
        
        .detail-value {
            font-weight: 600;
            color: #333;
        }
        
        .price {
            color: #27ae60;
            font-size: 1.3rem;
        }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-active {
            background: #d4edda;
            color: #155724;
        }
        
        .status-pending {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-closed {
            background: #cce5ff;
            color: #004085;
        }
        
        .status-cancelled {
            background: #f8d7da;
            color: #721c24;
        }
        
        /* Bids Table */
        .bids-section {
            grid-column: 1 / -1;
        }
        
        .bids-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .bids-table th,
        .bids-table td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        .bids-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        
        .bids-table tr:hover {
            background: #f8f9fa;
        }
        
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
            font-size: 0.9rem;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .btn-danger {
            background: #e74c3c;
            color: white;
        }
        
        .btn-danger:hover {
            background: #c0392b;
        }
        
        .btn-warning {
            background: #f39c12;
            color: white;
        }
        
        .btn-warning:hover {
            background: #d68910;
        }
        
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        .action-buttons {
            display: flex;
            gap: 8px;
        }
        
        .highest-bid {
            background: #d4edda !important;
        }
        
        .no-bids {
            text-align: center;
            padding: 40px;
            color: #666;
        }
        
        /* Modal Styles */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: rgba(0,0,0,0.5);
            justify-content: center;
            align-items: center;
            z-index: 1000;
        }
        
        .modal {
            background: white;
            padding: 30px;
            border-radius: 12px;
            max-width: 500px;
            width: 90%;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        
        .modal h3 {
            margin-bottom: 15px;
            color: #333;
        }
        
        .modal p {
            color: #666;
            margin-bottom: 10px;
        }
        
        .modal textarea {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
            font-size: 1rem;
            resize: vertical;
            min-height: 100px;
            margin: 15px 0;
        }
        
        .modal-buttons {
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }
        
        .btn-cancel {
            background: #6c757d;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
        }
        
        .btn-confirm {
            background: #e74c3c;
            color: white;
            padding: 10px 20px;
            border: none;
            border-radius: 6px;
            cursor: pointer;
        }
        
        .btn-confirm:hover {
            background: #c0392b;
        }
        
        /* Description box */
        .description-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-top: 15px;
            color: #333;
            line-height: 1.6;
        }
        
        /* Rep notice */
        .rep-notice {
            background: #fff3cd;
            border: 1px solid #ffc107;
            color: #856404;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .rep-notice strong {
            color: #664d03;
        }
        
        /* User info in bids */
        .user-info {
            display: flex;
            flex-direction: column;
        }
        
        .user-info .username {
            font-weight: 600;
            color: #333;
        }
        
        .user-info .user-id {
            font-size: 0.8rem;
            color: #999;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <a href="manage-auctions.jsp">← Back to Auction Management</a>
        <h2>Auction Details - Rep View</h2>
        <span class="rep-badge">REP: <%= user.getUsername() %></span>
    </nav>
    
    <div class="container">
        <div class="rep-notice">
            <strong>⚠️ Representative Mode:</strong> You are viewing this auction as a Customer Representative. You can view all details and manage bids, but cannot place bids.
        </div>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <%
            // Fetch auction details
            try (Connection conn = DatabaseConnection.getConnection()) {
                String auctionSql = "SELECT a.*, i.itemName, i.description as itemDescription, " +
                                   "u.username as sellerName, u.userID as sellerID, u.email as sellerEmail, " +
                                   "c.categoryName " +
                                   "FROM auction a " +
                                   "JOIN item i ON a.itemID = i.itemID " +
                                   "JOIN user u ON a.sellerID = u.userID " +
                                   "LEFT JOIN category c ON i.categoryID = c.categoryID " +
                                   "WHERE a.auctionID = ?";
                
                try (PreparedStatement ps = conn.prepareStatement(auctionSql)) {
                    ps.setInt(1, auctionID);
                    ResultSet rs = ps.executeQuery();
                    
                    if (rs.next()) {
                        String itemName = rs.getString("itemName");
                        String itemDescription = rs.getString("itemDescription");
                        String sellerName = rs.getString("sellerName");
                        int sellerID = rs.getInt("sellerID");
                        String sellerEmail = rs.getString("sellerEmail");
                        String categoryName = rs.getString("categoryName");
                        double initialPrice = rs.getDouble("initialPrice");
                        double currentPrice = rs.getDouble("currentPrice");
                        Double reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
                        double bidIncrement = rs.getDouble("bidIncrement");
                        Timestamp startDateTime = rs.getTimestamp("startDateTime");
                        Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                        String status = rs.getString("status");
        %>
        
        <div class="grid">
            <!-- Auction Details Card -->
            <div class="card">
                <div class="card-header">
                    📦 Auction #<%= auctionID %>: <%= itemName %>
                </div>
                <div class="card-body">
                    
                    <div class="detail-row">
                        <span class="detail-label">Status</span>
                        <span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Category</span>
                        <span class="detail-value"><%= categoryName != null ? categoryName : "Uncategorized" %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Starting Price</span>
                        <span class="detail-value">$<%= String.format("%.2f", initialPrice) %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Current Price</span>
                        <span class="detail-value price">$<%= String.format("%.2f", currentPrice) %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Reserve Price</span>
                        <span class="detail-value"><%= reservePrice != null ? "$" + String.format("%.2f", reservePrice) : "None" %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Bid Increment</span>
                        <span class="detail-value">$<%= String.format("%.2f", bidIncrement) %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Opens</span>
                        <span class="detail-value"><%= startDateTime %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Closes</span>
                        <span class="detail-value"><%= closeDateTime %></span>
                    </div>
                    
                    <% if (itemDescription != null && !itemDescription.isEmpty()) { %>
                        <div class="description-box">
                            <strong>Description:</strong><br>
                            <%= itemDescription %>
                        </div>
                    <% } %>
                </div>
            </div>
            
            <!-- Seller Info Card -->
            <div class="card">
                <div class="card-header">
                    👤 Seller Information
                </div>
                <div class="card-body">
                    <div class="detail-row">
                        <span class="detail-label">Seller ID</span>
                        <span class="detail-value">#<%= sellerID %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Username</span>
                        <span class="detail-value"><%= sellerName %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Email</span>
                        <span class="detail-value"><%= sellerEmail %></span>
                    </div>
                    
                    <%
                        // Get seller stats
                        String sellerStatsSql = "SELECT COUNT(*) as totalAuctions, " +
                                               "(SELECT COUNT(*) FROM auction WHERE sellerID = ? AND status = 'active') as activeAuctions " +
                                               "FROM auction WHERE sellerID = ?";
                        try (PreparedStatement statsPs = conn.prepareStatement(sellerStatsSql)) {
                            statsPs.setInt(1, sellerID);
                            statsPs.setInt(2, sellerID);
                            ResultSet statsRs = statsPs.executeQuery();
                            if (statsRs.next()) {
                    %>
                    <div class="detail-row">
                        <span class="detail-label">Total Auctions</span>
                        <span class="detail-value"><%= statsRs.getInt("totalAuctions") %></span>
                    </div>
                    <div class="detail-row">
                        <span class="detail-label">Active Auctions</span>
                        <span class="detail-value"><%= statsRs.getInt("activeAuctions") %></span>
                    </div>
                    <%
                            }
                        }
                    %>
                </div>
            </div>
            
            <!-- Bid History Card -->
            <div class="card bids-section">
                <div class="card-header warning">
                    💰 Bid History & Management
                </div>
                <div class="card-body" style="padding: 0;">
                    <%
                        String bidsSql = "SELECT bh.historyID, bh.bidAmount, bh.bidTime, bh.buyerID, u.username, u.userID " +
                                        "FROM bid_history bh " +
                                        "JOIN user u ON bh.buyerID = u.userID " +
                                        "WHERE bh.auctionID = ? " +
                                        "ORDER BY bh.bidAmount DESC";
                        try (PreparedStatement bidsPs = conn.prepareStatement(bidsSql)) {
                            bidsPs.setInt(1, auctionID);
                            ResultSet bidsRs = bidsPs.executeQuery();
                            
                            boolean hasBids = false;
                            boolean isFirst = true;
                    %>
                    <table class="bids-table">
                        <thead>
                            <tr>
                                <th>Bid ID</th>
                                <th>Bidder</th>
                                <th>Amount</th>
                                <th>Time</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                    <%
                            while (bidsRs.next()) {
                                hasBids = true;
                                int historyID = bidsRs.getInt("historyID");
                                int bidderID = bidsRs.getInt("buyerID");
                                String bidderUsername = bidsRs.getString("username");
                                double bidAmount = bidsRs.getDouble("bidAmount");
                                Timestamp bidTime = bidsRs.getTimestamp("bidTime");
                    %>
                            <tr class="<%= isFirst ? "highest-bid" : "" %>">
                                <td>#<%= historyID %></td>
                                <td>
                                    <div class="user-info">
                                        <span class="username"><%= bidderUsername %></span>
                                        <span class="user-id">User #<%= bidderID %></span>
                                    </div>
                                </td>
                                <td class="price">$<%= String.format("%.2f", bidAmount) %> <%= isFirst ? "👑" : "" %></td>
                                <td><%= bidTime %></td>
                                <td>
                                    <div class="action-buttons">
                                        <button class="btn btn-danger" onclick="showCancelBidModal(<%= historyID %>, '<%= bidderUsername %>', <%= bidAmount %>)">
                                            Cancel Bid
                                        </button>
                                        <button class="btn btn-warning" onclick="showCancelUserBidsModal(<%= bidderID %>, '<%= bidderUsername %>')">
                                            Cancel All User Bids
                                        </button>
                                    </div>
                                </td>
                            </tr>
                    <%
                                isFirst = false;
                            }
                            
                            if (!hasBids) {
                    %>
                            <tr>
                                <td colspan="5" class="no-bids">
                                    No bids have been placed on this auction yet.
                                </td>
                            </tr>
                    <%
                            }
                        }
                    %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        
        <%
                    } else {
        %>
        <div class="alert alert-error">Auction not found with ID: <%= auctionID %></div>
        <%
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
        %>
        <div class="alert alert-error">Error loading auction: <%= e.getMessage() %></div>
        <%
            }
        %>
    </div>
    
    <!-- Cancel Single Bid Modal -->
    <div class="modal-overlay" id="cancelBidModal">
        <div class="modal">
            <h3>Cancel Bid</h3>
            <p>Are you sure you want to cancel this bid?</p>
            <p><strong id="bidDetails"></strong></p>
            <form method="post" action="view.jsp?id=<%= auctionID %>&action=cancelBid">
                <input type="hidden" name="historyID" id="cancelBidID">
                <textarea name="reason" placeholder="Reason for cancellation (required)..." required></textarea>
                <div class="modal-buttons">
                    <button type="button" class="btn-cancel" onclick="hideModal('cancelBidModal')">Cancel</button>
                    <button type="submit" class="btn-confirm">Cancel Bid</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Cancel All User Bids Modal -->
    <div class="modal-overlay" id="cancelUserBidsModal">
        <div class="modal">
            <h3>Cancel All Bids from User</h3>
            <p>Are you sure you want to cancel ALL bids from this user on this auction?</p>
            <p><strong id="userBidsDetails"></strong></p>
            <form method="post" action="view.jsp?id=<%= auctionID %>&action=cancelUserBids">
                <input type="hidden" name="userID" id="cancelUserID">
                <textarea name="reason" placeholder="Reason for cancellation (required)..." required></textarea>
                <div class="modal-buttons">
                    <button type="button" class="btn-cancel" onclick="hideModal('cancelUserBidsModal')">Cancel</button>
                    <button type="submit" class="btn-confirm">Cancel All User Bids</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        function showCancelBidModal(bidID, username, amount) {
            document.getElementById('cancelBidID').value = bidID;
            document.getElementById('bidDetails').textContent = 'Bid #' + bidID + ' - $' + amount.toFixed(2) + ' by ' + username;
            document.getElementById('cancelBidModal').style.display = 'flex';
        }
        
        function showCancelUserBidsModal(userID, username) {
            document.getElementById('cancelUserID').value = userID;
            document.getElementById('userBidsDetails').textContent = 'All bids by ' + username + ' (User #' + userID + ')';
            document.getElementById('cancelUserBidsModal').style.display = 'flex';
        }
        
        function hideModal(modalId) {
            document.getElementById(modalId).style.display = 'none';
        }
        
        // Close modals when clicking outside
        document.querySelectorAll('.modal-overlay').forEach(function(modal) {
            modal.addEventListener('click', function(e) {
                if (e.target === this) {
                    this.style.display = 'none';
                }
            });
        });
    </script>
</body>
</html>

