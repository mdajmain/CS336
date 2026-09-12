<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    
    String filter = request.getParameter("filter");
    if (filter == null) filter = "all";
    
    String search = request.getParameter("search");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Users - BuyMe Rep</title>
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
        
        .users-table {
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
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #eee;
        }
        th {
            background: #f8f9fa;
            font-weight: 600;
            color: #333;
        }
        tr:hover { background: #f8f9fa; }
        
        .user-type {
            padding: 3px 10px;
            border-radius: 15px;
            font-size: 11px;
            font-weight: 600;
        }
        .type-end_user { background: #cce5ff; color: #004085; }
        .type-customer_rep { background: #d4edda; color: #155724; }
        .type-admin { background: #f8d7da; color: #721c24; }
        
        .status-active { color: #28a745; }
        .status-suspended { color: #dc3545; font-weight: 600; }
        
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
        .btn-edit { background: #17a2b8; color: white; }
        .btn-password { background: #ffc107; color: #333; }
        .btn-suspend { background: #dc3545; color: white; }
        .btn-unsuspend { background: #28a745; color: white; }
        .btn-delete { background: #6c757d; color: white; }
        
        .no-results {
            padding: 50px;
            text-align: center;
            color: #666;
        }
        
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
            max-height: 90vh;
            overflow-y: auto;
        }
        .modal h3 { margin-bottom: 20px; color: #333; }
        .modal label { display: block; margin-bottom: 5px; font-weight: 600; color: #333; }
        .modal input, .modal select {
            width: 100%;
            padding: 10px;
            border: 2px solid #ddd;
            border-radius: 5px;
            margin-bottom: 15px;
        }
        .modal-buttons { display: flex; gap: 10px; justify-content: flex-end; margin-top: 20px; }
        .modal-buttons button {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .btn-cancel { background: #6c757d; color: white; }
        .btn-save { background: #667eea; color: white; }
        .btn-confirm-delete { background: #dc3545; color: white; }
        
        .user-stats {
            font-size: 12px;
            color: #666;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
            <h2>Manage Users</h2>
            <span>Rep: <%= user.getUsername() %></span>
        </div>
    </nav>

    <div class="container">
        <div class="page-header">
            <h1>User Management</h1>
            <p>Edit user accounts, reset passwords, and manage account status</p>
            
            <div class="filters">
                <a href="manage-users.jsp?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All Users</a>
                <a href="manage-users.jsp?filter=end_user" class="filter-btn <%= "end_user".equals(filter) ? "active" : "" %>">End Users</a>
                <a href="manage-users.jsp?filter=suspended" class="filter-btn <%= "suspended".equals(filter) ? "active" : "" %>">Suspended</a>
                
                <form class="search-box" method="get">
                    <input type="hidden" name="filter" value="<%= filter %>">
                    <input type="text" name="search" placeholder="Search username or email..." value="<%= search != null ? search : "" %>">
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
        
        <div class="users-table">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Name</th>
                        <th>Type</th>
                        <th>Status</th>
                        <th>Joined</th>
                        <th>Activity</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                            StringBuilder sql = new StringBuilder();
                            sql.append("SELECT u.*, e.firstName, e.lastName, ");
                            sql.append("(SELECT COUNT(*) FROM auction WHERE sellerID = u.userID) as auctionCount, ");
                            sql.append("(SELECT COUNT(*) FROM bid WHERE buyerID = u.userID) as bidCount ");
                            sql.append("FROM user u ");
                            sql.append("LEFT JOIN end_user e ON u.userID = e.userID ");
                            sql.append("WHERE u.userType != 'admin' ");
                            
                            if ("end_user".equals(filter)) {
                                sql.append("AND u.userType = 'end_user' ");
                            } else if ("suspended".equals(filter)) {
                                sql.append("AND u.isSuspended = TRUE ");
                            }
                            
                            if (search != null && !search.trim().isEmpty()) {
                                sql.append("AND (u.username LIKE ? OR u.email LIKE ? OR e.firstName LIKE ? OR e.lastName LIKE ?) ");
                            }
                            sql.append("ORDER BY u.createdDate DESC");
                            
                            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                                int paramIndex = 1;
                                
                                if (search != null && !search.trim().isEmpty()) {
                                    String searchPattern = "%" + search + "%";
                                    ps.setString(paramIndex++, searchPattern);
                                    ps.setString(paramIndex++, searchPattern);
                                    ps.setString(paramIndex++, searchPattern);
                                    ps.setString(paramIndex++, searchPattern);
                                }
                                
                                try (ResultSet rs = ps.executeQuery()) {
                                    boolean hasUsers = false;
                                    
                                    while (rs.next()) {
                                        hasUsers = true;
                                        int userID = rs.getInt("userID");
                                        String username = rs.getString("username");
                                        String email = rs.getString("email");
                                        String firstName = rs.getString("firstName");
                                        String lastName = rs.getString("lastName");
                                        String uType = rs.getString("userType");
                                        boolean isSuspended = rs.getBoolean("isSuspended");
                                        Timestamp createdDate = rs.getTimestamp("createdDate");
                                        int auctionCount = rs.getInt("auctionCount");
                                        int bidCount = rs.getInt("bidCount");
                                        
                                        String fullName = "";
                                        if (firstName != null) fullName += firstName;
                                        if (lastName != null) fullName += " " + lastName;
                                        fullName = fullName.trim();
                    %>
                    <tr>
                        <td>#<%= userID %></td>
                        <td><strong><%= username %></strong></td>
                        <td><%= email %></td>
                        <td><%= fullName.isEmpty() ? "-" : fullName %></td>
                        <td><span class="user-type type-<%= uType %>"><%= uType.replace("_", " ").toUpperCase() %></span></td>
                        <td class="<%= isSuspended ? "status-suspended" : "status-active" %>">
                            <%= isSuspended ? "SUSPENDED" : "Active" %>
                        </td>
                        <td><%= createdDate != null ? createdDate.toString().substring(0, 10) : "-" %></td>
                        <td class="user-stats">
                            Auctions: <%= auctionCount %><br>
                            Bids: <%= bidCount %>
                        </td>
                        <td>
                            <% if ("end_user".equals(uType)) { %>
                                <button class="action-btn btn-edit" onclick="showEditModal(<%= userID %>, '<%= username.replace("'", "\\'") %>', '<%= email.replace("'", "\\'") %>', '<%= firstName != null ? firstName.replace("'", "\\'") : "" %>', '<%= lastName != null ? lastName.replace("'", "\\'") : "" %>')">Edit</button>
                                <a href="reset-password.jsp?userID=<%= userID %>" class="action-btn btn-password">Password</a>
                                <% if (isSuspended) { %>
                                    <button class="action-btn btn-unsuspend" onclick="toggleSuspend(<%= userID %>, '<%= username.replace("'", "\\'") %>', false)">Unsuspend</button>
                                <% } else { %>
                                    <button class="action-btn btn-suspend" onclick="toggleSuspend(<%= userID %>, '<%= username.replace("'", "\\'") %>', true)">Suspend</button>
                                <% } %>
                                <button class="action-btn btn-delete" onclick="showDeleteModal(<%= userID %>, '<%= username.replace("'", "\\'") %>')">Delete</button>
                            <% } else { %>
                                <span style="color: #999;">Staff Account</span>
                            <% } %>
                        </td>
                    </tr>
                    <%
                                    }
                                    
                                    if (!hasUsers) {
                    %>
                    <tr>
                        <td colspan="9" class="no-results">
                            No users found matching your criteria.
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
                            Error loading users: <%= e.getMessage() %>
                        </td>
                    </tr>
                    <%
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- Edit User Modal -->
    <div class="modal-overlay" id="editModal">
        <div class="modal">
            <h3>Edit User</h3>
            <form action="update-user.jsp" method="post">
                <input type="hidden" name="userID" id="editUserID">
                <input type="hidden" name="action" value="edit">
                
                <label>Username</label>
                <input type="text" name="username" id="editUsername" required>
                
                <label>Email</label>
                <input type="email" name="email" id="editEmail" required>
                
                <label>First Name</label>
                <input type="text" name="firstName" id="editFirstName">
                
                <label>Last Name</label>
                <input type="text" name="lastName" id="editLastName">
                
                <div class="modal-buttons">
                    <button type="button" class="btn-cancel" onclick="hideEditModal()">Cancel</button>
                    <button type="submit" class="btn-save">Save Changes</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Delete User Modal -->
    <div class="modal-overlay" id="deleteModal">
        <div class="modal">
            <h3>Delete User</h3>
            <p>Are you sure you want to delete user <strong id="deleteUsername"></strong>?</p>
            <p style="color: #dc3545; margin-top: 10px;">This action cannot be undone. All user data including auctions and bids will be affected.</p>
            <form action="update-user.jsp" method="post">
                <input type="hidden" name="userID" id="deleteUserID">
                <input type="hidden" name="action" value="delete">
                <div class="modal-buttons">
                    <button type="button" class="btn-cancel" onclick="hideDeleteModal()">Cancel</button>
                    <button type="submit" class="btn-confirm-delete">Delete User</button>
                </div>
            </form>
        </div>
    </div>
    
    <!-- Suspend Form (hidden) -->
    <form id="suspendForm" action="update-user.jsp" method="post" style="display: none;">
        <input type="hidden" name="userID" id="suspendUserID">
        <input type="hidden" name="action" id="suspendAction">
    </form>
    
    <script>
        function showEditModal(userID, username, email, firstName, lastName) {
            document.getElementById('editUserID').value = userID;
            document.getElementById('editUsername').value = username;
            document.getElementById('editEmail').value = email;
            document.getElementById('editFirstName').value = firstName;
            document.getElementById('editLastName').value = lastName;
            document.getElementById('editModal').style.display = 'flex';
        }
        
        function hideEditModal() {
            document.getElementById('editModal').style.display = 'none';
        }
        
        function showDeleteModal(userID, username) {
            document.getElementById('deleteUserID').value = userID;
            document.getElementById('deleteUsername').textContent = username;
            document.getElementById('deleteModal').style.display = 'flex';
        }
        
        function hideDeleteModal() {
            document.getElementById('deleteModal').style.display = 'none';
        }
        
        function toggleSuspend(userID, username, suspend) {
            if (confirm((suspend ? 'Suspend' : 'Unsuspend') + ' user ' + username + '?')) {
                document.getElementById('suspendUserID').value = userID;
                document.getElementById('suspendAction').value = suspend ? 'suspend' : 'unsuspend';
                document.getElementById('suspendForm').submit();
            }
        }
        
        // Close modals when clicking outside
        document.querySelectorAll('.modal-overlay').forEach(function(modal) {
            modal.addEventListener('click', function(e) {
                if (e.target === this) this.style.display = 'none';
            });
        });
    </script>
</body>
</html>
