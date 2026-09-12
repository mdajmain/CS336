<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.buyme.model.User" %>
<%
    // Session check - must be logged in as customer rep
    User user = (User) session.getAttribute("user");
    
    String filter = request.getParameter("filter");
    if (filter == null || filter.isEmpty()) {
        filter = "all";
    }
    
    String search = request.getParameter("search");
    String message = (String) session.getAttribute("message");
    String error = (String) session.getAttribute("error");
    
    // Clear session messages after reading
    session.removeAttribute("message");
    session.removeAttribute("error");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Auctions | BuyMe Rep</title>
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
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .back-btn {
            color: #4da6ff;
            text-decoration: none;
            font-weight: 500;
        }
        
        .back-btn:hover {
            text-decoration: underline;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 30px;
        }
        
        .page-header {
            margin-bottom: 30px;
        }
        
        .page-header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .page-header p {
            color: #666;
        }
        
        .filters {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 20px;
            align-items: center;
        }
        
        .filter-btn {
            padding: 10px 20px;
            background: white;
            border: 1px solid #ddd;
            border-radius: 25px;
            text-decoration: none;
            color: #333;
            font-weight: 500;
            transition: all 0.2s;
        }
        
        .filter-btn:hover {
            background: #f0f0f0;
        }
        
        .filter-btn.active {
            background: #1a1a2e;
            color: white;
            border-color: #1a1a2e;
        }
        
        .search-box {
            display: flex;
            margin-left: auto;
        }
        
        .search-box input {
            padding: 10px 15px;
            border: 1px solid #ddd;
            border-radius: 25px 0 0 25px;
            font-size: 1rem;
            width: 250px;
        }
        
        .search-box button {
            padding: 10px 20px;
            background: #1a1a2e;
            color: white;
            border: none;
            border-radius: 0 25px 25px 0;
            cursor: pointer;
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
        
        .auctions-table {
            background: white;
            border-radius: 12px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
        }
        
        th, td {
            padding: 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .price {
            color: #27ae60;
            font-weight: 600;
        }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85rem;
            font-weight: 600;
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
        
        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 0.85rem;
            text-decoration: none;
            margin-right: 5px;
        }
        
        .btn-view {
            background: #3498db;
            color: white;
        }
        
        .btn-view:hover {
            background: #2980b9;
        }
        
        .btn-remove {
            background: #e74c3c;
            color: white;
        }
        
        .btn-remove:hover {
            background: #c0392b;
        }
        
        .no-results {
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
        }
        
        .modal h3 {
            margin-bottom: 15px;
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
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
            <h2>Manage Auctions</h2>
            <span>Rep: <%= user.getUsername() %></span>
        </div>
    </nav>

    <div class="container">
        <div class="page-header">
            <h1>Auction Management</h1>
            <p>View, monitor, and remove inappropriate auctions</p>
            
            <div class="filters">
                <a href="manage-auctions.jsp?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All</a>
                <a href="manage-auctions.jsp?filter=active" class="filter-btn <%= "active".equals(filter) ? "active" : "" %>">Active</a>
                <a href="manage-auctions.jsp?filter=pending" class="filter-btn <%= "pending".equals(filter) ? "active" : "" %>">Pending</a>
                <a href="manage-auctions.jsp?filter=closed" class="filter-btn <%= "closed".equals(filter) ? "active" : "" %>">Closed</a>
                <a href="manage-auctions.jsp?filter=cancelled" class="filter-btn <%= "cancelled".equals(filter) ? "active" : "" %>">Cancelled</a>
                
                <form class="search-box" method="get">
                    <input type="hidden" name="filter" value="<%= filter %>">
                    <input type="text" name="search" placeholder="Search items or sellers..." value="<%= search != null ? search : "" %>">
                    <button type="submit">Search</button>
                </form>
            </div>
        </div>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <div class="auctions-table">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Item</th>
                        <th>Seller</th>
                        <th>Current Price</th>
                        <th>Reserve</th>
                        <th>Bids</th>
                        <th>End Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                            StringBuilder sql = new StringBuilder();
                            sql.append("SELECT a.*, i.itemName, u.username as sellerName, ");
                            sql.append("(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as bidCount ");
                            sql.append("FROM auction a ");
                            sql.append("JOIN item i ON a.itemID = i.itemID ");
                            sql.append("JOIN user u ON a.sellerID = u.userID ");
                            sql.append("WHERE 1=1 ");
                            
                            if (!"all".equals(filter)) {
                                sql.append("AND a.status = ? ");
                            }
                            if (search != null && !search.trim().isEmpty()) {
                                sql.append("AND (i.itemName LIKE ? OR u.username LIKE ?) ");
                            }
                            sql.append("ORDER BY a.closeDateTime DESC");
                            
                            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                                int paramIndex = 1;
                                
                                if (!"all".equals(filter)) {
                                    ps.setString(paramIndex++, filter);
                                }
                                if (search != null && !search.trim().isEmpty()) {
                                    String searchPattern = "%" + search + "%";
                                    ps.setString(paramIndex++, searchPattern);
                                    ps.setString(paramIndex++, searchPattern);
                                }
                                
                                try (ResultSet rs = ps.executeQuery()) {
                                    boolean hasAuctions = false;
                                    
                                    while (rs.next()) {
                                        hasAuctions = true;
                                        int auctionID = rs.getInt("auctionID");
                                        String itemName = rs.getString("itemName");
                                        String sellerName = rs.getString("sellerName");
                                        double currentPrice = rs.getDouble("currentPrice");
                                        Double reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
                                        int bidCount = rs.getInt("bidCount");
                                        Timestamp closeDateTime = rs.getTimestamp("closeDateTime");
                                        String status = rs.getString("status");
                    %>
                    <tr>
                        <td>#<%= auctionID %></td>
                        <td><%= itemName %></td>
                        <td><%= sellerName %></td>
                        <td class="price">$<%= String.format("%.2f", currentPrice) %></td>
                        <td><%= reservePrice != null ? "$" + String.format("%.2f", reservePrice) : "None" %></td>
                        <td><%= bidCount %></td>
                        <td><%= closeDateTime %></td>
                        <td><span class="status-badge status-<%= status %>"><%= status.toUpperCase() %></span></td>
                        <td>
                            <!-- FIXED: Now points to rep/view.jsp instead of auction/auction-details.jsp -->
                            <a href="view.jsp?id=<%= auctionID %>" class="action-btn btn-view" target="_blank">View</a>
                            <% if (!"cancelled".equals(status)) { %>
                                <button class="action-btn btn-remove" onclick="showRemoveModal(<%= auctionID %>, '<%= itemName.replace("'", "\\'").replace("\"", "\\\"") %>')">Remove</button>
                            <% } %>
                        </td>
                    </tr>
                    <%
                                    }
                                    
                                    if (!hasAuctions) {
                    %>
                    <tr>
                        <td colspan="9" class="no-results">
                            No auctions found matching your criteria.
                        </td>
                    </tr>
                    <%
                                    }
                                }
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                    %>
                    <tr>
                        <td colspan="9" class="no-results">
                            Error loading auctions: <%= e.getMessage() %>
                        </td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Remove Auction Modal -->
    <div class="modal-overlay" id="removeModal">
        <div class="modal">
            <h3>Remove Auction</h3>
            <p>Are you sure you want to remove auction: <strong id="auctionName"></strong>?</p>
            <p style="margin-top: 10px; color: #666;">Please provide a reason for removal:</p>
            <form action="remove-auction.jsp" method="post">
                <input type="hidden" name="auctionID" id="removeAuctionID">
                <textarea name="reason" placeholder="Reason for removal (required)..." required></textarea>
                <div class="modal-buttons">
                    <button type="button" class="btn-cancel" onclick="hideRemoveModal()">Cancel</button>
                    <button type="submit" class="btn-confirm">Remove Auction</button>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        function showRemoveModal(auctionID, itemName) {
            document.getElementById('removeAuctionID').value = auctionID;
            document.getElementById('auctionName').textContent = itemName + ' (#' + auctionID + ')';
            document.getElementById('removeModal').style.display = 'flex';
        }
        
        function hideRemoveModal() {
            document.getElementById('removeModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        document.getElementById('removeModal').addEventListener('click', function(e) {
            if (e.target === this) hideRemoveModal();
        });
    </script>
</body>
</html>
