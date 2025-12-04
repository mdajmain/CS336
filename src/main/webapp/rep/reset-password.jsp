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
    
    String userIDParam = request.getParameter("userID");
    String message = request.getParameter("message");
    String error = request.getParameter("error");
    
    // Pre-selected user info
    String selectedUsername = "";
    String selectedEmail = "";
    int selectedUserID = 0;
    
    if (userIDParam != null && !userIDParam.isEmpty()) {
        try (Connection conn = com.buyme.util.DatabaseConnection.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT userID, username, email FROM user WHERE userID = ? AND userType = 'end_user'")) {
            ps.setInt(1, Integer.parseInt(userIDParam));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    selectedUserID = rs.getInt("userID");
                    selectedUsername = rs.getString("username");
                    selectedEmail = rs.getString("email");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Reset Password - BuyMe Rep</title>
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
        
        .container { max-width: 800px; margin: 30px auto; padding: 0 20px; }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .page-header h1 { color: #333; margin-bottom: 10px; }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        
        .card {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .card h3 { margin-bottom: 20px; color: #333; }
        
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        .form-group input, .form-group select {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
        }
        .form-group input:focus, .form-group select:focus {
            border-color: #667eea;
            outline: none;
        }
        
        .search-user {
            display: flex;
            gap: 10px;
        }
        .search-user input { flex: 1; }
        .search-user button {
            padding: 12px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        
        .user-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .user-info p { margin-bottom: 5px; }
        .user-info strong { color: #333; }
        
        .btn {
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: opacity 0.3s;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
            text-decoration: none;
            display: inline-block;
        }
        .btn:hover { opacity: 0.9; }
        
        .password-options { margin-top: 20px; }
        .password-option {
            display: flex;
            align-items: center;
            margin-bottom: 10px;
        }
        .password-option input[type="radio"] {
            width: auto;
            margin-right: 10px;
        }
        .password-option label {
            margin-bottom: 0;
            font-weight: normal;
        }
        
        .custom-password {
            margin-top: 15px;
            display: none;
        }
        .custom-password.show { display: block; }
        
        .password-requirements {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
            <h2>Reset Password</h2>
            <span>Rep: <%= user.getUsername() %></span>
        </div>
    </nav>

    <div class="container">
        <div class="page-header">
            <h1>Password Reset</h1>
            <p>Help users who are locked out of their accounts by resetting their password</p>
        </div>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <div class="card">
            <h3>Find User</h3>
            <form method="get">
                <div class="form-group">
                    <label>Search by Username or Email</label>
                    <div class="search-user">
                        <input type="text" name="search" placeholder="Enter username or email...">
                        <button type="submit">Search</button>
                    </div>
                </div>
            </form>
            
            <%
                String searchQuery = request.getParameter("search");
                if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                         PreparedStatement ps = conn.prepareStatement(
                            "SELECT userID, username, email FROM user WHERE userType = 'end_user' AND (username LIKE ? OR email LIKE ?) LIMIT 10")) {
                        String pattern = "%" + searchQuery + "%";
                        ps.setString(1, pattern);
                        ps.setString(2, pattern);
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean found = false;
            %>
            <div class="form-group" style="margin-top: 20px;">
                <label>Select User</label>
                <select name="userSelect" onchange="if(this.value) window.location.href='reset-password.jsp?userID='+this.value">
                    <option value="">-- Select a user --</option>
                    <%
                            while (rs.next()) {
                                found = true;
                                int uid = rs.getInt("userID");
                                String uname = rs.getString("username");
                                String uemail = rs.getString("email");
                    %>
                    <option value="<%= uid %>" <%= uid == selectedUserID ? "selected" : "" %>>
                        <%= uname %> (<%= uemail %>)
                    </option>
                    <%
                            }
                            if (!found) {
                    %>
                    <option value="" disabled>No users found matching "<%= searchQuery %>"</option>
                    <%
                            }
                    %>
                </select>
            </div>
            <%
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
            %>
        </div>
        
        <% if (selectedUserID > 0) { %>
        <div class="card">
            <h3>Reset Password for User</h3>
            
            <div class="user-info">
                <p><strong>User ID:</strong> #<%= selectedUserID %></p>
                <p><strong>Username:</strong> <%= selectedUsername %></p>
                <p><strong>Email:</strong> <%= selectedEmail %></p>
            </div>
            
            <form action="process-reset-password.jsp" method="post">
                <input type="hidden" name="userID" value="<%= selectedUserID %>">
                
                <div class="password-options">
                    <div class="password-option">
                        <input type="radio" name="passwordType" id="generatePassword" value="generate" checked onchange="toggleCustomPassword()">
                        <label for="generatePassword">Generate a temporary password</label>
                    </div>
                    <div class="password-option">
                        <input type="radio" name="passwordType" id="customPassword" value="custom" onchange="toggleCustomPassword()">
                        <label for="customPassword">Set a custom password</label>
                    </div>
                </div>
                
                <div class="custom-password" id="customPasswordField">
                    <div class="form-group">
                        <label>New Password</label>
                        <input type="password" name="newPassword" id="newPasswordInput" minlength="6">
                        <p class="password-requirements">Password must be at least 6 characters long</p>
                    </div>
                    <div class="form-group">
                        <label>Confirm Password</label>
                        <input type="password" name="confirmPassword" id="confirmPasswordInput" minlength="6">
                    </div>
                </div>
                
                <div class="form-group">
                    <label>
                        <input type="checkbox" name="notifyUser" value="true" checked style="width: auto; margin-right: 8px;">
                        Send notification to user about password reset
                    </label>
                </div>
                
                <button type="submit" class="btn btn-primary">Reset Password</button>
                <a href="manage-users.jsp" class="btn btn-secondary" style="margin-left: 10px;">Cancel</a>
            </form>
        </div>
        <% } %>
    </div>
    
    <script>
        function toggleCustomPassword() {
            var customField = document.getElementById('customPasswordField');
            var customRadio = document.getElementById('customPassword');
            var newPasswordInput = document.getElementById('newPasswordInput');
            var confirmPasswordInput = document.getElementById('confirmPasswordInput');
            
            if (customRadio.checked) {
                customField.classList.add('show');
                newPasswordInput.required = true;
                confirmPasswordInput.required = true;
            } else {
                customField.classList.remove('show');
                newPasswordInput.required = false;
                confirmPasswordInput.required = false;
            }
        }
    </script>
</body>
</html>
