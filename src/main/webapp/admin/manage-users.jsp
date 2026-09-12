<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>

<%
    User user = (User) session.getAttribute("user");

    String message = null;
    String error = null;

    // Handle POST actions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String userIdStr = request.getParameter("userID");
        
        try {
            int targetUserID = Integer.parseInt(userIdStr);
            
            if (targetUserID == user.getUserID()) {
                error = "You cannot perform this action on your own account.";
            } else {
                Connection conn = null;
                try {
                    conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    if ("delete".equals(action)) {
                        PreparedStatement delStmt = conn.prepareStatement(
                            "DELETE FROM user WHERE userID = ?"
                        );
                        delStmt.setInt(1, targetUserID);
                        int rows = delStmt.executeUpdate();
                        
                        if (rows > 0) {
                            message = "User deleted successfully.";
                        } else {
                            error = "User not found.";
                        }
                        
                    } else if ("suspend".equals(action)) {
                        PreparedStatement suspendStmt = conn.prepareStatement(
                            "UPDATE user SET isSuspended = TRUE WHERE userID = ?"
                        );
                        suspendStmt.setInt(1, targetUserID);
                        suspendStmt.executeUpdate();
                        
                        // Log the suspension
                        PreparedStatement logStmt = conn.prepareStatement(
                            "INSERT INTO user_suspension_log (userID, suspendedBy, action, reason) VALUES (?, ?, 'suspended', ?)"
                        );
                        logStmt.setInt(1, targetUserID);
                        logStmt.setInt(2, user.getUserID());
                        logStmt.setString(3, request.getParameter("reason"));
                        logStmt.executeUpdate();
                        
                        message = "User suspended successfully.";
                        
                    } else if ("unsuspend".equals(action)) {
                        PreparedStatement unsuspendStmt = conn.prepareStatement(
                            "UPDATE user SET isSuspended = FALSE WHERE userID = ?"
                        );
                        unsuspendStmt.setInt(1, targetUserID);
                        unsuspendStmt.executeUpdate();
                        
                        // Log the unsuspension
                        PreparedStatement logStmt = conn.prepareStatement(
                            "INSERT INTO user_suspension_log (userID, suspendedBy, action, reason) VALUES (?, ?, 'unsuspended', ?)"
                        );
                        logStmt.setInt(1, targetUserID);
                        logStmt.setInt(2, user.getUserID());
                        logStmt.setString(3, "Account reactivated by admin");
                        logStmt.executeUpdate();
                        
                        message = "User unsuspended successfully.";
                    }
                    
                    conn.close();
                } catch (Exception ex) {
                    ex.printStackTrace();
                    error = "Error: " + ex.getMessage();
                }
            }
        } catch (NumberFormatException ex) {
            error = "Invalid user ID.";
        }
    }

    // Get filter parameters
    String filterType = request.getParameter("filterType");
    if (filterType == null) filterType = "all";
    
    String searchQuery = request.getParameter("search");
    if (searchQuery == null) searchQuery = "";
    
    String sortBy = request.getParameter("sortBy");
    if (sortBy == null) sortBy = "createdDate";
    
    String sortOrder = request.getParameter("sortOrder");
    if (sortOrder == null) sortOrder = "DESC";
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Users - Admin Panel</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        .navbar {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 15px 0;
            color: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-right a {
            color: white;
            text-decoration: none;
            margin-left: 20px;
            transition: opacity 0.3s;
        }
        .nav-right a:hover {
            opacity: 0.8;
        }
        .container {
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 15px;
            text-decoration: none;
            color: #667eea;
            font-weight: 500;
        }
        .back-link:hover {
            text-decoration: underline;
        }
        
        /* Stats Cards */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
            text-align: center;
        }
        .stat-number {
            font-size: 32px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #666;
            margin-top: 5px;
            font-size: 14px;
        }
        
        /* Main Section */
        .section {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.08);
        }
        .section-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 15px;
        }
        h1 {
            color: #333;
            font-size: 28px;
        }
        
        /* Filters */
        .filters {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            margin-bottom: 20px;
            padding-bottom: 20px;
            border-bottom: 2px solid #f0f0f0;
        }
        .filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .filter-group label {
            font-size: 12px;
            color: #666;
            font-weight: 600;
            text-transform: uppercase;
        }
        .filter-group select,
        .filter-group input[type="text"] {
            padding: 8px 12px;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            min-width: 200px;
        }
        .filter-group button {
            padding: 8px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: background 0.3s;
        }
        .filter-group button:hover {
            background: #5568d3;
        }
        
        /* Alerts */
        .alert {
            padding: 12px 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            font-size: 14px;
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
        
        /* Table */
        .table-container {
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        th, td {
            padding: 12px;
            border-bottom: 1px solid #e1e1e1;
            text-align: left;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
            cursor: pointer;
            user-select: none;
            position: relative;
        }
        th:hover {
            background: #e9ecef;
        }
        th.sortable::after {
            content: ' ↕';
            opacity: 0.3;
        }
        th.sorted-asc::after {
            content: ' ↑';
            opacity: 1;
        }
        th.sorted-desc::after {
            content: ' ↓';
            opacity: 1;
        }
        tr:hover {
            background: #f9f9f9;
        }
        
        /* Badges */
        .badge {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            text-transform: uppercase;
            color: white;
        }
        .badge-end_user { background: #17a2b8; }
        .badge-customer_rep { background: #ffc107; color: #333; }
        .badge-admin { background: #dc3545; }
        .badge-suspended { background: #6c757d; margin-left: 5px; }
        
        /* User Info */
        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .user-avatar {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 16px;
        }
        .user-details strong {
            display: block;
            color: #333;
            font-size: 14px;
        }
        .user-details .small {
            display: block;
            color: #666;
            font-size: 12px;
            margin-top: 2px;
        }
        
        /* Stats in table */
        .stat-item {
            font-size: 12px;
            color: #666;
            margin: 2px 0;
        }
        .stat-item strong {
            color: #333;
        }
        
        /* Buttons */
        .btn-group {
            display: flex;
            gap: 5px;
            flex-wrap: wrap;
        }
        .btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 500;
            text-decoration: none;
            display: inline-block;
            transition: opacity 0.3s;
        }
        .btn:hover {
            opacity: 0.8;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-warning {
            background: #ffc107;
            color: #333;
        }
        .btn-success {
            background: #28a745;
            color: white;
        }
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        .btn:disabled {
            background: #ccc;
            cursor: not-allowed;
            opacity: 0.6;
        }
        
        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #999;
        }
        .empty-state svg {
            width: 80px;
            height: 80px;
            margin-bottom: 20px;
            opacity: 0.3;
        }
        
        /* Responsive */
        @media (max-width: 768px) {
            .stats-grid {
                grid-template-columns: 1fr 1fr;
            }
            .filters {
                flex-direction: column;
            }
            .filter-group select,
            .filter-group input[type="text"] {
                width: 100%;
            }
        }
    </style>
</head>
<body>

<nav class="navbar">
    <div class="nav-container">
        <h2>BuyMe Admin Panel</h2>
        <div class="nav-right">
            <span>Admin: <%= user.getUsername() %></span>
            <a href="dashboard.jsp">Dashboard</a>
            <a href="../logout">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <a href="dashboard.jsp" class="back-link">← Back to Dashboard</a>

    <!-- Statistics Cards -->
    <%
        Connection statsConn = null;
        int totalUsers = 0, totalEndUsers = 0, totalReps = 0, suspendedUsers = 0;
        try {
            statsConn = com.buyme.util.DatabaseConnection.getConnection();
            
            PreparedStatement statsStmt = statsConn.prepareStatement(
                "SELECT " +
                "COUNT(*) as total, " +
                "SUM(CASE WHEN userType = 'end_user' THEN 1 ELSE 0 END) as endUsers, " +
                "SUM(CASE WHEN userType = 'customer_rep' THEN 1 ELSE 0 END) as reps, " +
                "SUM(CASE WHEN isSuspended = TRUE THEN 1 ELSE 0 END) as suspended " +
                "FROM user"
            );
            ResultSet statsRs = statsStmt.executeQuery();
            if (statsRs.next()) {
                totalUsers = statsRs.getInt("total");
                totalEndUsers = statsRs.getInt("endUsers");
                totalReps = statsRs.getInt("reps");
                suspendedUsers = statsRs.getInt("suspended");
            }
            statsConn.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    %>
    
    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-number"><%= totalUsers %></div>
            <div class="stat-label">Total Users</div>
        </div>
        <div class="stat-card">
            <div class="stat-number"><%= totalEndUsers %></div>
            <div class="stat-label">End Users</div>
        </div>
        <div class="stat-card">
            <div class="stat-number"><%= totalReps %></div>
            <div class="stat-label">Customer Reps</div>
        </div>
        <div class="stat-card">
            <div class="stat-number"><%= suspendedUsers %></div>
            <div class="stat-label">Suspended</div>
        </div>
    </div>

    <!-- Main Section -->
    <div class="section">
        <div class="section-header">
            <h1>User Management</h1>
        </div>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <!-- Filters -->
        <form method="get" action="manage-users.jsp">
            <div class="filters">
                <div class="filter-group">
                    <label>User Type</label>
                    <select name="filterType" onchange="this.form.submit()">
                        <option value="all" <%= "all".equals(filterType) ? "selected" : "" %>>All Users</option>
                        <option value="end_user" <%= "end_user".equals(filterType) ? "selected" : "" %>>End Users</option>
                        <option value="customer_rep" <%= "customer_rep".equals(filterType) ? "selected" : "" %>>Customer Reps</option>
                        <option value="admin" <%= "admin".equals(filterType) ? "selected" : "" %>>Admins</option>
                        <option value="suspended" <%= "suspended".equals(filterType) ? "selected" : "" %>>Suspended</option>
                    </select>
                </div>
                
                <div class="filter-group">
                    <label>Search</label>
                    <input type="text" 
                           name="search" 
                           placeholder="Username or email..." 
                           value="<%= searchQuery %>"
                           onkeypress="if(event.keyCode==13) this.form.submit()">
                </div>
                
                <div class="filter-group">
                    <label>&nbsp;</label>
                    <button type="submit">Apply Filters</button>
                </div>
            </div>
            
            <input type="hidden" name="sortBy" value="<%= sortBy %>">
            <input type="hidden" name="sortOrder" value="<%= sortOrder %>">
        </form>

        <!-- Users Table -->
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th class="sortable">User</th>
                        <th class="sortable">Account Info</th>
                        <th class="sortable">Activity Stats</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    Connection conn = null;
                    try {
                        conn = com.buyme.util.DatabaseConnection.getConnection();

                        // Build dynamic SQL query
                        StringBuilder sql = new StringBuilder(
                            "SELECT u.userID, u.username, u.email, u.userType, u.createdDate, u.isSuspended, " +
                            "       eu.firstName, eu.lastName, eu.address, eu.phone, " +
                            "       cr.department, " +
                            "       (SELECT COUNT(*) FROM bid WHERE buyerID = u.userID) as totalBids, " +
                            "       (SELECT COUNT(*) FROM auction WHERE sellerID = u.userID) as totalAuctions, " +
                            "       (SELECT COUNT(*) FROM auction WHERE winnerID = u.userID AND status = 'closed') as totalWins " +
                            "FROM user u " +
                            "LEFT JOIN end_user eu ON u.userID = eu.userID " +
                            "LEFT JOIN customer_rep cr ON u.userID = cr.userID " +
                            "WHERE 1=1 "
                        );

                        // Add filters
                        if (!"all".equals(filterType)) {
                            if ("suspended".equals(filterType)) {
                                sql.append("AND u.isSuspended = TRUE ");
                            } else {
                                sql.append("AND u.userType = ? ");
                            }
                        }
                        
                        if (!searchQuery.isEmpty()) {
                            sql.append("AND (u.username LIKE ? OR u.email LIKE ?) ");
                        }

                        sql.append("ORDER BY u.").append(sortBy).append(" ").append(sortOrder);

                        PreparedStatement ps = conn.prepareStatement(sql.toString());
                        
                        int paramIndex = 1;
                        if (!"all".equals(filterType) && !"suspended".equals(filterType)) {
                            ps.setString(paramIndex++, filterType);
                        }
                        if (!searchQuery.isEmpty()) {
                            String searchPattern = "%" + searchQuery + "%";
                            ps.setString(paramIndex++, searchPattern);
                            ps.setString(paramIndex++, searchPattern);
                        }

                        ResultSet rs = ps.executeQuery();

                        boolean hasResults = false;
                        while (rs.next()) {
                            hasResults = true;
                            int userID = rs.getInt("userID");
                            String username = rs.getString("username");
                            String email = rs.getString("email");
                            String userType = rs.getString("userType");
                            Timestamp created = rs.getTimestamp("createdDate");
                            boolean isSuspended = rs.getBoolean("isSuspended");
                            String firstName = rs.getString("firstName");
                            String lastName = rs.getString("lastName");
                            String department = rs.getString("department");
                            int totalBids = rs.getInt("totalBids");
                            int totalAuctions = rs.getInt("totalAuctions");
                            int totalWins = rs.getInt("totalWins");
                            
                            String initials = username.substring(0, Math.min(2, username.length())).toUpperCase();
                %>
                <tr>
                    <!-- User Info -->
                    <td>
                        <div class="user-info">
                            <div class="user-avatar"><%= initials %></div>
                            <div class="user-details">
                                <strong>#<%= userID %> - <%= username %></strong>
                                <span class="small"><%= email %></span>
                                <div style="margin-top: 5px;">
                                    <span class="badge badge-<%= userType %>"><%= userType.replace("_", " ") %></span>
                                    <% if (isSuspended) { %>
                                        <span class="badge badge-suspended">SUSPENDED</span>
                                    <% } %>
                                </div>
                            </div>
                        </div>
                    </td>

                    <!-- Account Info -->
                    <td>
                        <div class="stat-item">
                            <strong>Joined:</strong> <%= created.toString().substring(0, 10) %>
                        </div>
                        <% if ("end_user".equals(userType) && firstName != null) { %>
                            <div class="stat-item">
                                <strong>Name:</strong> <%= firstName %> <%= lastName != null ? lastName : "" %>
                            </div>
                        <% } %>
                        <% if ("customer_rep".equals(userType) && department != null) { %>
                            <div class="stat-item">
                                <strong>Dept:</strong> <%= department %>
                            </div>
                        <% } %>
                    </td>

                    <!-- Activity Stats -->
                    <td>
                        <% if ("end_user".equals(userType)) { %>
                            <div class="stat-item"><strong>Bids:</strong> <%= totalBids %></div>
                            <div class="stat-item"><strong>Auctions:</strong> <%= totalAuctions %></div>
                            <div class="stat-item"><strong>Wins:</strong> <%= totalWins %></div>
                        <% } else if ("customer_rep".equals(userType)) { %>
                            <%
                                PreparedStatement qStmt = conn.prepareStatement(
                                    "SELECT COUNT(*) as answered FROM question WHERE repID = (SELECT repID FROM customer_rep WHERE userID = ?)"
                                );
                                qStmt.setInt(1, userID);
                                ResultSet qRs = qStmt.executeQuery();
                                int answered = 0;
                                if (qRs.next()) answered = qRs.getInt("answered");
                            %>
                            <div class="stat-item"><strong>Questions Answered:</strong> <%= answered %></div>
                        <% } else { %>
                            <div class="stat-item" style="color: #999;">Admin account</div>
                        <% } %>
                    </td>

                    <!-- Status -->
                    <td>
                        <% if (isSuspended) { %>
                            <span style="color: #dc3545; font-weight: 600;">🔒 Suspended</span>
                        <% } else { %>
                            <span style="color: #28a745; font-weight: 600;">✓ Active</span>
                        <% } %>
                    </td>

                    <!-- Actions -->
                    <td>
                        <div class="btn-group">
                            <a href="user-details.jsp?userID=<%= userID %>" class="btn btn-primary">
                                View Details
                            </a>
                            
                            <% if (userID != user.getUserID()) { %>
                                <% if (isSuspended) { %>
                                    <form method="post" style="display: inline;">
                                        <input type="hidden" name="action" value="unsuspend">
                                        <input type="hidden" name="userID" value="<%= userID %>">
                                        <button type="submit" class="btn btn-success">Unsuspend</button>
                                    </form>
                                <% } else { %>
                                    <form method="post" style="display: inline;"
                                          onsubmit="return confirm('Suspend user <%= username %>?');">
                                        <input type="hidden" name="action" value="suspend">
                                        <input type="hidden" name="userID" value="<%= userID %>">
                                        <input type="hidden" name="reason" value="Suspended by admin">
                                        <button type="submit" class="btn btn-warning">Suspend</button>
                                    </form>
                                <% } %>
                                
                                <form method="post" style="display: inline;"
                                      onsubmit="return confirm('PERMANENTLY DELETE user <%= username %>? This cannot be undone!');">
                                    <input type="hidden" name="action" value="delete">
                                    <input type="hidden" name="userID" value="<%= userID %>">
                                    <button type="submit" class="btn btn-danger">Delete</button>
                                </form>
                            <% } else { %>
                                <button class="btn" disabled>Cannot modify self</button>
                            <% } %>
                        </div>
                    </td>
                </tr>
                <%
                        }

                        if (!hasResults) {
                %>
                <tr>
                    <td colspan="5">
                        <div class="empty-state">
                            <p style="font-size: 18px; margin-bottom: 10px;">No users found</p>
                            <p>Try adjusting your filters or search query</p>
                        </div>
                    </td>
                </tr>
                <%
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                %>
                <tr>
                    <td colspan="5" style="color: red; padding: 20px;">
                        Error loading users: <%= e.getMessage() %>
                    </td>
                </tr>
                <%
                    } finally {
                        if (conn != null) conn.close();
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>

</body>
</html>


