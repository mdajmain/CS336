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

    // Handle account update
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String address = request.getParameter("address");
        String phone = request.getParameter("phone");
        String department = request.getParameter("department");

        Connection conn = null;
        try {
            conn = com.buyme.util.DatabaseConnection.getConnection();

            // Update end_user table if user is end_user
            if ("end_user".equals(user.getUserType())) {
                PreparedStatement updateEndUserStmt = conn.prepareStatement(
                    "UPDATE end_user SET firstName = ?, lastName = ?, address = ?, phone = ? WHERE userID = ?"
                );
                updateEndUserStmt.setString(1, firstName);
                updateEndUserStmt.setString(2, lastName);
                updateEndUserStmt.setString(3, address);
                updateEndUserStmt.setString(4, phone);
                updateEndUserStmt.setInt(5, user.getUserID());
                updateEndUserStmt.executeUpdate();

                message = "Account updated successfully!";
            }

            // Update customer_rep table if user is customer_rep
            if ("customer_rep".equals(user.getUserType())) {
                PreparedStatement updateRepStmt = conn.prepareStatement(
                    "UPDATE customer_rep SET department = ? WHERE userID = ?"
                );
                updateRepStmt.setString(1, department);
                updateRepStmt.setInt(2, user.getUserID());
                updateRepStmt.executeUpdate();

                message = "Account updated successfully!";
            }

            conn.close();
        } catch (Exception ex) {
            ex.printStackTrace();
            error = "Error updating account: " + ex.getMessage();
        }
    }

    // Load current user data
    String currentEmail = user.getEmail();
    String currentFirstName = "";
    String currentLastName = "";
    String currentAddress = "";
    String currentPhone = "";
    String currentDepartment = "";

    Connection conn = null;
    try {
        conn = com.buyme.util.DatabaseConnection.getConnection();

        if ("end_user".equals(user.getUserType())) {
            PreparedStatement stmt = conn.prepareStatement(
                "SELECT firstName, lastName, address, phone FROM end_user WHERE userID = ?"
            );
            stmt.setInt(1, user.getUserID());
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                currentFirstName = rs.getString("firstName") != null ? rs.getString("firstName") : "";
                currentLastName = rs.getString("lastName") != null ? rs.getString("lastName") : "";
                currentAddress = rs.getString("address") != null ? rs.getString("address") : "";
                currentPhone = rs.getString("phone") != null ? rs.getString("phone") : "";
            }
        } else if ("customer_rep".equals(user.getUserType())) {
            PreparedStatement stmt = conn.prepareStatement(
                "SELECT department FROM customer_rep WHERE userID = ?"
            );
            stmt.setInt(1, user.getUserID());
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                currentDepartment = rs.getString("department") != null ? rs.getString("department") : "";
            }
        }

        conn.close();
    } catch (Exception ex) {
        ex.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Edit Account - BuyMe</title>
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
        .edit-account-card {
            background: white;
            padding: 40px;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            width: 100%;
            max-width: 600px;
        }
        .edit-account-card h1 {
            color: #333;
            margin-bottom: 10px;
            font-size: 28px;
        }
        .edit-account-card p {
            color: #666;
            margin-bottom: 30px;
        }
        .user-info-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 25px;
        }
        .user-info-box .info-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 8px;
            font-size: 14px;
        }
        .user-info-box .info-item:last-child {
            margin-bottom: 0;
        }
        .user-info-box .label {
            color: #666;
            font-weight: 600;
        }
        .user-info-box .value {
            color: #333;
        }
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
            margin-bottom: 20px;
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
        .form-group input,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #e1e1e1;
            border-radius: 8px;
            font-size: 14px;
            font-family: inherit;
            transition: border-color 0.3s;
        }
        .form-group input:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        .form-group textarea {
            resize: vertical;
            min-height: 80px;
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
        .btn-group {
            display: flex;
            gap: 10px;
            margin-top: 25px;
        }
        .btn {
            flex: 1;
            padding: 14px;
            border: none;
            border-radius: 8px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .btn-primary {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 20px rgba(102, 126, 234, 0.4);
        }
        .btn-primary:active {
            transform: translateY(0);
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
            text-decoration: none;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .btn-secondary:hover {
            background: #5a6268;
        }
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: white;
            margin-left: 10px;
        }
        .badge-end_user { background: #17a2b8; }
        .badge-customer_rep { background: #ffc107; color: #333; }
        .badge-admin { background: #dc3545; }

        @media (max-width: 600px) {
            .form-row {
                grid-template-columns: 1fr;
            }
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
    <div class="edit-account-card">
        <h1>
            Edit Account
            <span class="badge badge-<%= user.getUserType() %>"><%= user.getUserType().replace("_", " ") %></span>
        </h1>
        <p>Update your account information</p>

        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>

        <div class="user-info-box">
            <div class="info-item">
                <span class="label">Username:</span>
                <span class="value"><%= user.getUsername() %></span>
            </div>
            <div class="info-item">
                <span class="label">User ID:</span>
                <span class="value">#<%= user.getUserID() %></span>
            </div>
            <div class="info-item">
                <span class="label">Account Type:</span>
                <span class="value"><%= user.getUserType().replace("_", " ").toUpperCase() %></span>
            </div>
        </div>

        <form method="post" action="edit-account.jsp">
            <div class="form-group">
                <label for="email">Email Address</label>
                <input type="email" 
                       id="email" 
                       name="email" 
                       value="<%= currentEmail %>"
                       readonly
                       style="background: #f8f9fa; cursor: not-allowed;"
                       title="Email cannot be changed. Please create a new account if you need a different email.">
                <small style="display: block; margin-top: 5px; color: #666; font-size: 12px;">
                    Email address cannot be changed. If you need to use a different email, please create a new account.
                </small>
            </div>

            <% if ("end_user".equals(user.getUserType())) { %>
                <div class="form-row">
                    <div class="form-group">
                        <label for="firstName">First Name</label>
                        <input type="text" 
                               id="firstName" 
                               name="firstName" 
                               value="<%= currentFirstName %>"
                               placeholder="Enter first name">
                    </div>

                    <div class="form-group">
                        <label for="lastName">Last Name</label>
                        <input type="text" 
                               id="lastName" 
                               name="lastName" 
                               value="<%= currentLastName %>"
                               placeholder="Enter last name">
                    </div>
                </div>

                <div class="form-group">
                    <label for="phone">Phone Number</label>
                    <input type="tel" 
                           id="phone" 
                           name="phone" 
                           value="<%= currentPhone %>"
                           placeholder="Enter phone number">
                </div>

                <div class="form-group">
                    <label for="address">Address</label>
                    <textarea id="address" 
                              name="address" 
                              placeholder="Enter your address"><%= currentAddress %></textarea>
                </div>
            <% } else if ("customer_rep".equals(user.getUserType())) { %>
                <div class="form-group">
                    <label for="department">Department</label>
                    <input type="text" 
                           id="department" 
                           name="department" 
                           value="<%= currentDepartment %>"
                           placeholder="Enter department">
                </div>
            <% } %>

            <div class="btn-group">
                <button type="submit" class="btn btn-primary">Save Changes</button>
                <a href="<%= dashboardLink %>" class="btn btn-secondary">Cancel</a>
            </div>
        </form>

        <hr style="margin: 30px 0; border: none; border-top: 1px solid #e1e1e1;">
        
        <div style="text-align: center;">
            <p style="font-size: 14px; color: #666; margin-bottom: 10px;">Need to change your password?</p>
            <a href="change-password.jsp" style="color: #667eea; text-decoration: none; font-weight: 600;">Change Password →</a>
        </div>
    </div>
</div>

</body>
</html>
