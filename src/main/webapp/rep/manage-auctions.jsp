<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    if (user == null || !"customer_rep".equalsIgnoreCase(userType)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String filter = request.getParameter("filter");
    if (filter == null) filter = "active";
    
    String search = request.getParameter("search");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Auctions - BuyMe Rep</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #f5f5f5; min-height: 100vh; }
        
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
        }
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .back-btn { color: white; text-decoration: none; }
        
        .container { max-width: 1400px; margin: 30px auto; padding: 0 20px; }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .page-header h1 { color: #333; margin-bottom: 10px; }
        
        .filters {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
            margin-top: 15px;
        }
        .filter-btn {
            padding: 8px 16px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 20px;
            text-decoration: none;
            transition: all 0.3s;
        }
        .filter-btn:hover, .filter-btn.active {
            background: #667eea;
            color: white;
        }
        
        .search-box {
            display: flex;
            gap: 10px;
            margin-left: auto;
        }
        .search-box input {
            padding: 8px 15px;
            border: 2px solid #ddd;
            border-radius: 5px;
            width: 250px;
        }
        .search-box button {
            padding: 8px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        
        .auctions-table {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
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
        tr:hover { background: #f8f9fa; }
        
        .status-badge {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-pending { background: #fff3cd; color: #856404; }
        .status-closed { background: #e2e3e5; color: #383d41; }
        .status-cancelled { background: #f8d7da; color: #721c24; }
        
        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            margin-right: 5px;
            text-decoration: none;
            display: inline-block;
        }
        .btn-view { background: #17a2b8; color: white; }
        .btn-remove { background: #dc3545; color: white; }
        .btn-view:hover { background: #138496; }
        .btn-remove:hover { background: #c82333; }
        
        .no-results {
            padding: 50px;
            text-align: center;
            color: #666;
        }
        
        .price { font-weight: 600; color: #27ae60; }
        
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            z-index: 1000;
            justify-content: center;
            align-items: center;
        }
        .modal {
            background: white;
            padding: 30px;
            border-radius: 10px;
            max-width: 500px;
            width: 90%;
        }
        .modal h3 { margin-bottom: 20px; }
        .modal textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            min-height: 100px;
            margin-bottom: 15px;
        }
        .modal-buttons { display: flex; gap: 10px; justify-content: flex-end; }
        .modal-buttons button {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .btn-cancel { background: #6c757d; color: white; }
        .btn-confirm { background: #dc3545; color: white; }
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
                            <a href="<%= request.getContextPath() %>/auction/view.jsp?id=<%= auctionID %>" class="action-btn btn-view" target="_blank">View</a>
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
