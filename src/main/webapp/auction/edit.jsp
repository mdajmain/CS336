<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    if (user == null || !"end_user".equalsIgnoreCase(userType)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    
    String auctionIDStr = request.getParameter("id");
    if (auctionIDStr == null) {
        response.sendRedirect("my-auctions.jsp?error=No auction specified");
        return;
    }
    
    int auctionID;
    try {
        auctionID = Integer.parseInt(auctionIDStr);
    } catch (NumberFormatException e) {
        response.sendRedirect("my-auctions.jsp?error=Invalid auction ID");
        return;
    }
    
    // Auction details
    String itemName = "";
    String description = "";
    String itemCondition = "";
    int categoryID = 0;
    int subcategoryID = 0;
    double initialPrice = 0;
    double bidIncrement = 0;
    Double reservePrice = null;
    Timestamp startDateTime = null;
    Timestamp closeDateTime = null;
    String status = "";
    int sellerID = 0;
    int bidCount = 0;
    
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Auction - BuyMe</title>
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
        
        .container { max-width: 800px; margin: 30px auto; padding: 0 20px; }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
        }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        .alert-warning { background: #fff3cd; color: #856404; }
        
        .form-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 30px;
        }
        .form-card h1 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .form-section {
            margin-bottom: 25px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .form-section h3 {
            color: #333;
            margin-bottom: 15px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: #667eea;
            outline: none;
        }
        .form-group input:disabled,
        .form-group select:disabled {
            background: #e9ecef;
            cursor: not-allowed;
        }
        .form-group .help-text {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        
        .btn {
            padding: 12px 25px;
            border: none;
            border-radius: 5px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
            text-decoration: none;
        }
        
        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 25px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="<%= request.getContextPath() %>/logout" style="margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <a href="my-auctions.jsp" class="back-link">← Back to My Auctions</a>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <%
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                // Get auction details
                String sql = "SELECT a.*, i.itemName, i.description, i.itemCondition, i.categoryID, i.subcategoryID, " +
                             "(SELECT COUNT(*) FROM bid WHERE auctionID = a.auctionID) as bidCount " +
                             "FROM auction a JOIN item i ON a.itemID = i.itemID WHERE a.auctionID = ?";
                
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, auctionID);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next()) {
        %>
                            <div class="alert alert-error">Auction not found.</div>
        <%
                            return;
                        }
                        
                        sellerID = rs.getInt("sellerID");
                        
                        // Check if user is the seller
                        if (sellerID != user.getUserID()) {
        %>
                            <div class="alert alert-error">You don't have permission to edit this auction.</div>
        <%
                            return;
                        }
                        
                        itemName = rs.getString("itemName");
                        description = rs.getString("description");
                        itemCondition = rs.getString("itemCondition");
                        categoryID = rs.getInt("categoryID");
                        subcategoryID = rs.getInt("subcategoryID");
                        initialPrice = rs.getDouble("initialPrice");
                        bidIncrement = rs.getDouble("bidIncrement");
                        reservePrice = rs.getObject("reservePrice") != null ? rs.getDouble("reservePrice") : null;
                        startDateTime = rs.getTimestamp("startDateTime");
                        closeDateTime = rs.getTimestamp("closeDateTime");
                        status = rs.getString("status");
                        bidCount = rs.getInt("bidCount");
                        
                        boolean hasBids = bidCount > 0;
                        boolean canEditPricing = !hasBids && ("pending".equals(status) || "active".equals(status));
                        boolean canEditDates = "pending".equals(status) || "active".equals(status);
        %>
        
        <% if (hasBids) { %>
            <div class="alert alert-warning">
                This auction has <%= bidCount %> bid(s). Some fields cannot be modified.
            </div>
        <% } %>
        
        <div class="form-card">
            <h1>Edit Auction #<%= auctionID %></h1>
            
            <form action="<%= request.getContextPath() %>/update-auction" method="post">
                <input type="hidden" name="auctionID" value="<%= auctionID %>">
                
                <div class="form-section">
                    <h3>Item Information</h3>
                    
                    <div class="form-group">
                        <label>Item Name</label>
                        <input type="text" name="itemName" value="<%= itemName %>" required maxlength="255">
                    </div>
                    
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" rows="4"><%= description != null ? description : "" %></textarea>
                    </div>
                    
                    <div class="form-group">
                        <label>Condition</label>
                        <select name="itemCondition">
                            <option value="New" <%= "New".equals(itemCondition) ? "selected" : "" %>>New</option>
                            <option value="Like New" <%= "Like New".equals(itemCondition) ? "selected" : "" %>>Like New</option>
                            <option value="Very Good" <%= "Very Good".equals(itemCondition) ? "selected" : "" %>>Very Good</option>
                            <option value="Good" <%= "Good".equals(itemCondition) ? "selected" : "" %>>Good</option>
                            <option value="Acceptable" <%= "Acceptable".equals(itemCondition) ? "selected" : "" %>>Acceptable</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-section">
                    <h3>Pricing</h3>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Starting Price ($)</label>
                            <input type="number" name="initialPrice" step="0.01" min="0.01" 
                                   value="<%= String.format("%.2f", initialPrice) %>" 
                                   <%= canEditPricing ? "" : "disabled" %>>
                            <% if (!canEditPricing) { %>
                                <p class="help-text">Cannot change - auction has bids</p>
                            <% } %>
                        </div>
                        
                        <div class="form-group">
                            <label>Bid Increment ($)</label>
                            <input type="number" name="bidIncrement" step="0.01" min="0.01" 
                                   value="<%= String.format("%.2f", bidIncrement) %>"
                                   <%= canEditPricing ? "" : "disabled" %>>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Reserve Price ($)</label>
                        <input type="number" name="reservePrice" step="0.01" min="0" 
                               value="<%= reservePrice != null ? String.format("%.2f", reservePrice) : "" %>"
                               placeholder="Optional">
                        <p class="help-text">You can always adjust the reserve price</p>
                    </div>
                </div>
                
                <div class="form-section">
                    <h3>Auction Duration</h3>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Start Date & Time</label>
                            <input type="datetime-local" name="startDateTime" 
                                   value="<%= startDateTime != null ? startDateTime.toString().replace(" ", "T").substring(0, 16) : "" %>"
                                   <%= "pending".equals(status) ? "" : "disabled" %>>
                            <% if (!"pending".equals(status)) { %>
                                <p class="help-text">Cannot change - auction already started</p>
                            <% } %>
                        </div>
                        
                        <div class="form-group">
                            <label>End Date & Time</label>
                            <input type="datetime-local" name="closeDateTime" 
                                   value="<%= closeDateTime != null ? closeDateTime.toString().replace(" ", "T").substring(0, 16) : "" %>"
                                   <%= canEditDates ? "" : "disabled" %>>
                        </div>
                    </div>
                </div>
                
                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                    <a href="my-auctions.jsp" class="btn btn-secondary">Cancel</a>
                </div>
            </form>
        </div>
        
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
</body>
</html>
