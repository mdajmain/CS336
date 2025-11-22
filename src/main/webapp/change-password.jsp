<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }

    String message = null;
    String error = null;

    // Handle password change
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // Validation
        if (currentPassword == null || currentPassword.trim().isEmpty()) {
            error = "Please enter your current password.";
        } else if (newPassword == null || newPassword.trim().isEmpty()) {
            error = "Please enter a new password.";
        } else if (newPassword.length() < 6) {
            error = "New password must be at least 6 characters long.";
        } else if (!newPassword.equals(confirmPassword)) {
            error = "New passwords do not match.";
        } else {
            Connection conn = null;
            try {
                conn = com.buyme.util.DatabaseConnection.getConnection();

                // Verify current password
                PreparedStatement verifyStmt = conn.prepareStatement(
                    "SELECT password FROM user WHERE userID = ?"
                );
                verifyStmt.setInt(1, user.getUserID());
                ResultSet rs = verifyStmt.executeQuery();

                if (rs.next()) {
                    String storedPassword = rs.getString("password");
                    
                    if (!storedPassword.equals(currentPassword)) {
                        error = "Current password is incorrect.";
                    } else if (storedPassword.equals(newPassword)) {
                        error = "New password must be different from current password.";
                    } else {
                        // Update password
                        PreparedStatement updateStmt = conn.prepareStatement(
                            "UPDATE user SET password = ? WHERE userID = ?"
                        );
                        updateStmt.setString(1, newPassword);
                        updateStmt.setInt(2, user.getUserID());
                        int rows = updateStmt.executeUpdate();

                        if (rows > 0) {
                            message = "Password changed successfully!";
                        } else {
                            error = "Failed to update password. Please try again.";
                        }
                    }
                } else {
                    error = "User not found.";
                }

                conn.close();
            } catch (Exception ex) {
                ex.printStackTrace();
                error = "Error: " + ex.getMessage();
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Change Password - BuyMe</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        .navbar {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            padding: 15px 0;
            color: white;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .nav-container h2 {
            font-size: 24px;
        }
        .nav-right {
            display: flex;
            gap: 20px;
            align-items: center;
        }
        .nav-right a {
            color: white;
            text-decoration: none;
            padding: 8px 16px;
            border-radius: 5px;
            transition: background 0.3s;
        }
        .nav-right a:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        .container {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 40px 20px;
        }
        .change-password-card {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 500px;
        }
        .change-password-card h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .change-password-card p {
            color: #666;
            margin-bottom: 30px;
        }
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            color: #333;
            font-weight: 600;
            font-size: 14px;
        }
        .form-group input {
            width: 100%;
            padding: 12px;
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        .alert {
            padding: 12px 16px;
            border-radius: 8px;
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
        .btn {
            width: 100%;
            padding: 14px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        .btn:active {
            transform: translateY(0);
        }
        .back-link {
            display: inline-block;
            margin-top: 20px;
            color: #667eea;
            text-decoration: none;
            font-size: 14px;
        }
        .back-link:hover {
            text-decoration: underline;
        }
        .password-requirements {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
            font-size: 13px;
            color: #666;
        }
        .password-requirements ul {
            margin-left: 20px;
            margin-top: 8px;
        }
        .password-requirements li {
            margin-bottom: 5px;
        }
    </style>
</head>
<body>

<nav class="navbar">
    <div class="nav-container">
        <h2>BuyMe</h2>
        <div class="nav-right">
            <span>Logged in as: <%= user.getUsername() %></span>
            <%
                String dashboardLink = "dashboard.jsp";
                if ("admin".equals(user.getUserType())) {
                    dashboardLink = "admin/dashboard.jsp";
                } else if ("customer_rep".equals(user.getUserType())) {
                    dashboardLink = "rep/dashboard.jsp";
                }
            %>
            <a href="<%= dashboardLink %>">Dashboard</a>
            <a href="logout">Logout</a>
        </div>
    </div>
</nav>

<div class="container">
    <div class="change-password-card">
        <h1>Change Password</h1>
        <p>Update your account password</p>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <div class="password-requirements">
            <strong>Password Requirements:</strong>
            <ul>
                <li>Minimum 6 characters</li>
                <li>Must be different from current password</li>
            </ul>
        </div>

        <form method="post" action="change-password.jsp">
            <div class="form-group">
                <label for="currentPassword">Current Password</label>
                <input type="password" 
                       id="currentPassword" 
                       name="currentPassword" 
                       required
                       placeholder="Enter your current password">
            </div>

            <div class="form-group">
                <label for="newPassword">New Password</label>
                <input type="password" 
                       id="newPassword" 
                       name="newPassword" 
                       required
                       minlength="6"
                       placeholder="Enter your new password">
            </div>

            <div class="form-group">
                <label for="confirmPassword">Confirm New Password</label>
                <input type="password" 
                       id="confirmPassword" 
                       name="confirmPassword" 
                       required
                       minlength="6"
                       placeholder="Re-enter your new password">
            </div>

            <button type="submit" class="btn">Change Password</button>
        </form>

        <a href="<%= dashboardLink %>" class="back-link">← Back to Dashboard</a>
    </div>
</div>

<script>
    // Client-side password match validation
    document.querySelector('form').addEventListener('submit', function(e) {
        const newPassword = document.getElementById('newPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;
        
        if (newPassword !== confirmPassword) {
            e.preventDefault();
            alert('New passwords do not match!');
            return false;
        }
    });
</script>

</body>
</html>
