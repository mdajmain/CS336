<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");
    
    String auctionIDStr = request.getParameter("id");
    if (auctionIDStr == null) {
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
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Bid History - BuyMe</title>
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
        
        .container { max-width: 900px; margin: 30px auto; padding: 0 20px; }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
        }
        
        .history-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .history-header {
            padding: 25px;
            border-bottom: 1px solid #eee;
        }
        .history-header h1 { color: #333; margin-bottom: 5px; }
        .history-header p { color: #666; }
        
        .auction-summary {
            display: flex;
            gap: 30px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        .summary-item label {
            font-size: 12px;
            color: #666;
            display: block;
        }
        .summary-item span {
            font-size: 18px;
            font-weight: bold;
            color: #333;
        }
        .summary-item span.price { color: #27ae60; }
        
        .history-table {
            width: 100%;
            border-collapse: collapse;
        }
        .history-table th,
        .history-table td {
            padding: 15px 20px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        .history-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        .history-table tr:hover { background: #f8f9fa; }
        
        .history-table .rank {
            color: #666;
            font-weight: 600;
        }
        .history-table .bid-amount {
            font-weight: 600;
            color: #27ae60;
        }
        .history-table .bidder {
            color: #333;
        }
        .history-table .time {
            color: #666;
            font-size: 13px;
        }
        
        .winning-row {
            background: #e8f5e9 !important;
        }
        .winning-badge {
            background: #28a745;
            color: white;
            padding: 3px 8px;
            border-radius: 10px;
            font-size: 11px;
            margin-left: 8px;
        }
        
        .no-bids {
            padding: 50px;
            text-align: center;
            color: #666;
        }
        
        .pagination {
            padding: 20px;
            display: flex;
            justify-content: center;
            gap: 10px;
        }
        .pagination a {
            padding: 8px 15px;
            border: 1px solid #ddd;
            border-radius: 5px;
            text-decoration: none;
            color: #667eea;
        }
        .pagination a:hover { background: #f8f9fa; }
        .pagination a.active {
            background: #667eea;
            color: white;
            border-color: #667eea;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div>
                <% if (user != null) { %>
                    <span>Welcome, <%= user.getUsername() %></span>
                    <a href="<%= request.getContextPath() %>/logout" style="margin-left: 20px;">Logout</a>
                <% } else { %>
                    <a href="<%= request.getContextPath() %>/login">Login</a>
                <% } %>
            </div>
        </div>
    </nav>

    <div class="container">
        <a href="view.jsp?id=<%= auctionID %>" class="back-link">← Back to Auction</a>
        
        <%
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Get auction info
                String auctionSql = "SELECT a.*, i.itemName, " +
                                   "(SELECT COUNT(*) FROM bid_history WHERE auctionID = a.auctionID) as totalBids " +
                                   "FROM auction a JOIN item i ON a.itemID = i.itemID WHERE a.auctionID = ?";
                
                String itemName = "";
                double currentPrice = 0;
                String status = "";
                int totalBids = 0;
                Integer winnerID = null;
                
                try (PreparedStatement ps = conn.prepareStatement(auctionSql)) {
                    ps.setInt(1, auctionID);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            itemName = rs.getString("itemName");
                            currentPrice = rs.getDouble("currentPrice");
                            status = rs.getString("status");
                            totalBids = rs.getInt("totalBids");
                            winnerID = rs.getObject("winnerID") != null ? rs.getInt("winnerID") : null;
                        } else {
        %>
                            <div class="history-card">
                                <div class="no-bids">Auction not found.</div>
                            </div>
        <%
                            return;
                        }
                    }
                }
                
                // Pagination
                int page_ = 1;
                try {
                    page = Integer.parseInt(request.getParameter("page"));
                } catch (Exception e) {}
                int perPage = 25;
                int offset = (page_ - 1) * perPage;
                int totalPages = (int) Math.ceil((double) totalBids / perPage);
        %>
        
        <div class="history-card">
            <div class="history-header">
                <h1>Bid History</h1>
                <p><%= itemName %> (Auction #<%= auctionID %>)</p>
                
                <div class="auction-summary">
                    <div class="summary-item">
                        <label>Current Price</label>
                        <span class="price">$<%= String.format("%.2f", currentPrice) %></span>
                    </div>
                    <div class="summary-item">
                        <label>Total Bids</label>
                        <span><%= totalBids %></span>
                    </div>
                    <div class="summary-item">
                        <label>Status</label>
                        <span><%= status.toUpperCase() %></span>
                    </div>
                </div>
            </div>
            
            <% if (totalBids > 0) { %>
            <table class="history-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Bidder</th>
                        <th>Bid Amount</th>
                        <th>Time</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        String bidsSql = "SELECT bh.*, u.username FROM bid_history bh " +
                                        "JOIN user u ON bh.buyerID = u.userID " +
                                        "WHERE bh.auctionID = ? ORDER BY bh.bidTime DESC LIMIT ? OFFSET ?";
                        
                        try (PreparedStatement ps = conn.prepareStatement(bidsSql)) {
                            ps.setInt(1, auctionID);
                            ps.setInt(2, perPage);
                            ps.setInt(3, offset);
                            
                            try (ResultSet rs = ps.executeQuery()) {
                                int rank = offset;
                                while (rs.next()) {
                                    rank++;
                                    int buyerID = rs.getInt("buyerID");
                                    String username = rs.getString("username");
                                    double bidAmount = rs.getDouble("bidAmount");
                                    Timestamp bidTime = rs.getTimestamp("bidTime");
                                    
                                    boolean isWinner = winnerID != null && buyerID == winnerID && rank == offset + 1;
                    %>
                    <tr class="<%= isWinner ? "winning-row" : "" %>">
                        <td class="rank"><%= rank %></td>
                        <td class="bidder">
                            <%= username %>
                            <% if (isWinner) { %><span class="winning-badge">WINNER</span><% } %>
                        </td>
                        <td class="bid-amount">$<%= String.format("%.2f", bidAmount) %></td>
                        <td class="time"><%= bidTime %></td>
                    </tr>
                    <%
                                }
                            }
                        }
                    %>
                </tbody>
            </table>
            
            <% if (totalPages > 1) { %>
            <div class="pagination">
                <% if (page_ > 1) { %>
                    <a href="bid-history.jsp?id=<%= auctionID %>&page=<%= page_ - 1 %>">« Prev</a>
                <% } %>
                
                <% for (int i = 1; i <= totalPages; i++) { %>
                    <a href="bid-history.jsp?id=<%= auctionID %>&page=<%= i %>" class="<%= i == page_ ? "active" : "" %>"><%= i %></a>
                <% } %>
                
                <% if (page_ < totalPages) { %>
                    <a href="bid-history.jsp?id=<%= auctionID %>&page=<%= page_ + 1 %>">Next »</a>
                <% } %>
            </div>
            <% } %>
            
            <% } else { %>
            <div class="no-bids">
                <h3>No Bids Yet</h3>
                <p>Be the first to bid on this item!</p>
            </div>
            <% } %>
        </div>
        
        <%
            } catch (Exception e) {
                e.printStackTrace();
        %>
            <div class="history-card">
                <div class="no-bids">Error loading bid history: <%= e.getMessage() %></div>
            </div>
        <%
            }
        %>
    </div>
</body>
</html>
