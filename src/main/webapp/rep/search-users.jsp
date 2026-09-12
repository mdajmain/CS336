<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String search = request.getParameter("search");
    String searchType = request.getParameter("searchType");
    if (searchType == null) searchType = "all";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Search Users - BuyMe Rep</title>
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
        .back-btn { color: white; text-decoration: none; }
        
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        
        .search-card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .search-card h1 { color: #333; margin-bottom: 20px; }
        
        .search-form {
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: flex-end;
        }
        .form-group { flex: 1; min-width: 200px; }
        .form-group label {
            display: block;
            margin-bottom: 5px;
            font-weight: 600;
            color: #333;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
        }
        .form-group input:focus, .form-group select:focus {
            border-color: #667eea;
            outline: none;
        }
        
        .search-btn {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
        }
        .search-btn:hover { opacity: 0.9; }
        
        .results-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .results-header {
            padding: 20px;
            background: #f8f9fa;
            border-bottom: 1px solid #eee;
        }
        .results-header h3 { color: #333; }
        
        .results-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
            padding: 20px;
        }
        
        .user-card {
            border: 1px solid #eee;
            border-radius: 8px;
            padding: 20px;
            transition: box-shadow 0.3s;
        }
        .user-card:hover { box-shadow: 0 5px 15px rgba(0,0,0,0.1); }
        
        .user-card .header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 15px;
        }
        .user-card .username {
            font-size: 18px;
            font-weight: 600;
            color: #333;
        }
        .user-card .user-id {
            color: #666;
            font-size: 12px;
        }
        .user-card .status {
            padding: 4px 10px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 600;
        }
        .status-active { background: #d4edda; color: #155724; }
        .status-suspended { background: #f8d7da; color: #721c24; }
        
        .user-card .info {
            margin-bottom: 15px;
        }
        .user-card .info p {
            color: #666;
            font-size: 14px;
            margin-bottom: 5px;
        }
        .user-card .info p strong { color: #333; }
        
        .user-card .stats {
            display: flex;
            gap: 20px;
            padding: 10px 0;
            border-top: 1px solid #eee;
            margin-bottom: 15px;
        }
        .user-card .stat {
            text-align: center;
        }
        .user-card .stat .number {
            font-size: 20px;
            font-weight: 600;
            color: #667eea;
        }
        .user-card .stat .label {
            font-size: 11px;
            color: #666;
        }
        
        .user-card .actions {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }
        .action-btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            text-decoration: none;
        }
        .btn-primary { background: #667eea; color: white; }
        .btn-warning { background: #ffc107; color: #333; }
        .btn-info { background: #17a2b8; color: white; }
        
        .no-results {
            padding: 50px;
            text-align: center;
            color: #666;
        }
        .no-results h3 { margin-bottom: 10px; }
        
        .quick-stats {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-box {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            flex: 1;
            text-align: center;
        }
        .stat-box .number {
            font-size: 28px;
            font-weight: bold;
            color: #667eea;
        }
        .stat-box .label {
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
            <h2>Search Users</h2>
            <span>Rep: <%= user.getUsername() %></span>
        </div>
    </nav>

    <div class="container">
        <%
            // Get quick stats
            int totalUsers = 0;
            int activeUsers = 0;
            int suspendedUsers = 0;
            
            try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                try (PreparedStatement ps1 = conn.prepareStatement(
                    "SELECT COUNT(*) FROM user WHERE userType = 'end_user'");
                     ResultSet rs1 = ps1.executeQuery()) {
                    if (rs1.next()) totalUsers = rs1.getInt(1);
                }
                
                try (PreparedStatement ps2 = conn.prepareStatement(
                    "SELECT COUNT(*) FROM user WHERE userType = 'end_user' AND (isSuspended = FALSE OR isSuspended IS NULL)");
                     ResultSet rs2 = ps2.executeQuery()) {
                    if (rs2.next()) activeUsers = rs2.getInt(1);
                }
                
                try (PreparedStatement ps3 = conn.prepareStatement(
                    "SELECT COUNT(*) FROM user WHERE userType = 'end_user' AND isSuspended = TRUE");
                     ResultSet rs3 = ps3.executeQuery()) {
                    if (rs3.next()) suspendedUsers = rs3.getInt(1);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        %>
        
        <div class="quick-stats">
            <div class="stat-box">
                <div class="number"><%= totalUsers %></div>
                <div class="label">Total Users</div>
            </div>
            <div class="stat-box">
                <div class="number"><%= activeUsers %></div>
                <div class="label">Active Users</div>
            </div>
            <div class="stat-box">
                <div class="number"><%= suspendedUsers %></div>
                <div class="label">Suspended Users</div>
            </div>
        </div>
        
        <div class="search-card">
            <h1>Search Users</h1>
            <form class="search-form" method="get">
                <div class="form-group" style="flex: 2;">
                    <label>Search Term</label>
                    <input type="text" name="search" placeholder="Username, email, or name..." value="<%= search != null ? search : "" %>" autofocus>
                </div>
                <div class="form-group">
                    <label>Search In</label>
                    <select name="searchType">
                        <option value="all" <%= "all".equals(searchType) ? "selected" : "" %>>All Fields</option>
                        <option value="username" <%= "username".equals(searchType) ? "selected" : "" %>>Username</option>
                        <option value="email" <%= "email".equals(searchType) ? "selected" : "" %>>Email</option>
                        <option value="name" <%= "name".equals(searchType) ? "selected" : "" %>>Name</option>
                    </select>
                </div>
                <button type="submit" class="search-btn">Search</button>
            </form>
        </div>
        
        <% if (search != null && !search.trim().isEmpty()) { %>
        <div class="results-card">
            <div class="results-header">
                <h3>Search Results for "<%= search %>"</h3>
            </div>
            <div class="results-grid">
                <%
                    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                        StringBuilder sql = new StringBuilder();
                        sql.append("SELECT u.*, e.firstName, e.lastName, ");
                        sql.append("(SELECT COUNT(*) FROM auction WHERE sellerID = u.userID) as auctionCount, ");
                        sql.append("(SELECT COUNT(*) FROM bid WHERE buyerID = u.userID) as bidCount, ");
                        sql.append("(SELECT COUNT(*) FROM auction WHERE sellerID = u.userID AND status = 'closed' AND winnerID IS NOT NULL) as salesCount ");
                        sql.append("FROM user u ");
                        sql.append("LEFT JOIN end_user e ON u.userID = e.userID ");
                        sql.append("WHERE u.userType = 'end_user' ");
                        
                        String searchPattern = "%" + search + "%";
                        
                        if ("username".equals(searchType)) {
                            sql.append("AND u.username LIKE ? ");
                        } else if ("email".equals(searchType)) {
                            sql.append("AND u.email LIKE ? ");
                        } else if ("name".equals(searchType)) {
                            sql.append("AND (e.firstName LIKE ? OR e.lastName LIKE ?) ");
                        } else {
                            sql.append("AND (u.username LIKE ? OR u.email LIKE ? OR e.firstName LIKE ? OR e.lastName LIKE ?) ");
                        }
                        sql.append("ORDER BY u.createdDate DESC LIMIT 50");
                        
                        try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                            int paramIndex = 1;
                            
                            if ("name".equals(searchType)) {
                                ps.setString(paramIndex++, searchPattern);
                                ps.setString(paramIndex++, searchPattern);
                            } else if ("all".equals(searchType)) {
                                ps.setString(paramIndex++, searchPattern);
                                ps.setString(paramIndex++, searchPattern);
                                ps.setString(paramIndex++, searchPattern);
                                ps.setString(paramIndex++, searchPattern);
                            } else {
                                ps.setString(paramIndex++, searchPattern);
                            }
                            
                            try (ResultSet rs = ps.executeQuery()) {
                                boolean hasResults = false;
                                
                                while (rs.next()) {
                                    hasResults = true;
                                    int userID = rs.getInt("userID");
                                    String username = rs.getString("username");
                                    String email = rs.getString("email");
                                    String firstName = rs.getString("firstName");
                                    String lastName = rs.getString("lastName");
                                    boolean isSuspended = rs.getBoolean("isSuspended");
                                    Timestamp createdDate = rs.getTimestamp("createdDate");
                                    int auctionCount = rs.getInt("auctionCount");
                                    int bidCount = rs.getInt("bidCount");
                                    int salesCount = rs.getInt("salesCount");
                                    
                                    String fullName = "";
                                    if (firstName != null) fullName += firstName;
                                    if (lastName != null) fullName += " " + lastName;
                                    fullName = fullName.trim();
                %>
                <div class="user-card">
                    <div class="header">
                        <div>
                            <div class="username"><%= username %></div>
                            <div class="user-id">ID: #<%= userID %></div>
                        </div>
                        <span class="status <%= isSuspended ? "status-suspended" : "status-active" %>">
                            <%= isSuspended ? "SUSPENDED" : "ACTIVE" %>
                        </span>
                    </div>
                    <div class="info">
                        <p><strong>Email:</strong> <%= email %></p>
                        <p><strong>Name:</strong> <%= fullName.isEmpty() ? "Not provided" : fullName %></p>
                        <p><strong>Joined:</strong> <%= createdDate != null ? createdDate.toString().substring(0, 10) : "Unknown" %></p>
                    </div>
                    <div class="stats">
                        <div class="stat">
                            <div class="number"><%= auctionCount %></div>
                            <div class="label">Auctions</div>
                        </div>
                        <div class="stat">
                            <div class="number"><%= bidCount %></div>
                            <div class="label">Bids</div>
                        </div>
                        <div class="stat">
                            <div class="number"><%= salesCount %></div>
                            <div class="label">Sales</div>
                        </div>
                    </div>
                    <div class="actions">
                        <a href="manage-users.jsp?search=<%= username %>" class="action-btn btn-primary">View Details</a>
                        <a href="reset-password.jsp?userID=<%= userID %>" class="action-btn btn-warning">Reset Password</a>
                        <a href="manage-bids.jsp?userID=<%= userID %>" class="action-btn btn-info">View Bids</a>
                    </div>
                </div>
                <%
                                }
                                
                                if (!hasResults) {
                %>
                <div class="no-results" style="grid-column: 1 / -1;">
                    <h3>No Users Found</h3>
                    <p>No users match your search criteria "<%= search %>"</p>
                </div>
                <%
                                }
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                %>
                <div class="no-results" style="grid-column: 1 / -1;">
                    <h3>Error</h3>
                    <p>Error searching users: <%= e.getMessage() %></p>
                </div>
                <%
                    }
                %>
            </div>
        </div>
        <% } else { %>
        <div class="results-card">
            <div class="no-results">
                <h3>Enter a Search Term</h3>
                <p>Use the search box above to find users by username, email, or name</p>
            </div>
        </div>
        <% } %>
    </div>
</body>
</html>
