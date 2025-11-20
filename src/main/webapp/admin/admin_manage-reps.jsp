<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getUserType())) {
        response.sendRedirect("../login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Manage Customer Reps - Admin</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f5f5;
        }
        
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
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
        }
        
        h1, h2 {
            color: #333;
            margin-bottom: 20px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
        }
        
        input, select {
            width: 100%;
            padding: 10px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 16px;
        }
        
        .btn {
            padding: 10px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th {
            background: #f8f9fa;
            padding: 12px;
            text-align: left;
            border-bottom: 2px solid #dee2e6;
        }
        
        td {
            padding: 12px;
            border-bottom: 1px solid #dee2e6;
        }
        
        .delete-btn {
            background: #dc3545;
            color: white;
            padding: 5px 10px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .error {
            background: #f8d7da;
            color: #721c24;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .back-btn {
            display: inline-block;
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 20px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>Admin Panel - Customer Representative Management</h2>
            <div>
                <span>Admin: <%= user.getUsername() %></span>
                <a href="../logout" style="color: white; margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
        
        <div class="section">
            <h2>Create New Customer Representative</h2>
            
            <%
                // Handle form submission
                if ("POST".equals(request.getMethod()) && request.getParameter("action") != null) {
                    String action = request.getParameter("action");
                    
                    if ("create".equals(action)) {
                        String username = request.getParameter("username");
                        String password = request.getParameter("password");
                        String email = request.getParameter("email");
                        String department = request.getParameter("department");
                        
                        Connection conn = null;
                        try {
                            conn = com.buyme.util.DatabaseConnection.getConnection();
                            conn.setAutoCommit(false);
                            
                            // Create user account
                            String userSql = "INSERT INTO user (username, password, email, userType) VALUES (?, ?, ?, 'customer_rep')";
                            PreparedStatement userStmt = conn.prepareStatement(userSql, Statement.RETURN_GENERATED_KEYS);
                            userStmt.setString(1, username);
                            userStmt.setString(2, password);
                            userStmt.setString(3, email);
                            userStmt.executeUpdate();
                            
                            ResultSet keys = userStmt.getGeneratedKeys();
                            if (keys.next()) {
                                int userID = keys.getInt(1);
                                
                                // Create customer rep record
                                String repSql = "INSERT INTO customer_rep (userID, department) VALUES (?, ?)";
                                PreparedStatement repStmt = conn.prepareStatement(repSql);
                                repStmt.setInt(1, userID);
                                repStmt.setString(2, department);
                                repStmt.executeUpdate();
                                
                                conn.commit();
                                out.println("<div class='success'>Customer Representative created successfully!</div>");
                            }
                        } catch (Exception e) {
                            if (conn != null) conn.rollback();
                            out.println("<div class='error'>Error: " + e.getMessage() + "</div>");
                        } finally {
                            if (conn != null) {
                                conn.setAutoCommit(true);
                                conn.close();
                            }
                        }
                    } else if ("delete".equals(action)) {
                        String repID = request.getParameter("repID");
                        
                        try {
                            Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                            
                            // Get userID first
                            PreparedStatement getStmt = conn.prepareStatement("SELECT userID FROM customer_rep WHERE repID = ?");
                            getStmt.setString(1, repID);
                            ResultSet rs = getStmt.executeQuery();
                            
                            if (rs.next()) {
                                int userID = rs.getInt("userID");
                                
                                // Delete from user table (cascade will handle customer_rep)
                                PreparedStatement deleteStmt = conn.prepareStatement("DELETE FROM user WHERE userID = ?");
                                deleteStmt.setInt(1, userID);
                                deleteStmt.executeUpdate();
                                
                                out.println("<div class='success'>Customer Representative deleted successfully!</div>");
                            }
                            
                            conn.close();
                        } catch (Exception e) {
                            out.println("<div class='error'>Error deleting rep: " + e.getMessage() + "</div>");
                        }
                    }
                }
            %>
            
            <form method="post">
                <input type="hidden" name="action" value="create">
                
                <div class="form-group">
                    <label for="username">Username</label>
                    <input type="text" id="username" name="username" required>
                </div>
                
                <div class="form-group">
                    <label for="password">Password</label>
                    <input type="password" id="password" name="password" required>
                </div>
                
                <div class="form-group">
                    <label for="email">Email</label>
                    <input type="email" id="email" name="email" required>
                </div>
                
                <div class="form-group">
                    <label for="department">Department</label>
                    <select id="department" name="department" required>
                        <option value="General Support">General Support</option>
                        <option value="Technical Support">Technical Support</option>
                        <option value="Billing">Billing</option>
                        <option value="Disputes">Disputes</option>
                    </select>
                </div>
                
                <button type="submit" class="btn">Create Customer Representative</button>
            </form>
        </div>
        
        <div class="section">
            <h2>Existing Customer Representatives</h2>
            
            <table>
                <thead>
                    <tr>
                        <th>Rep ID</th>
                        <th>Username</th>
                        <th>Email</th>
                        <th>Department</th>
                        <th>Hire Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        try {
                            Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                            String sql = "SELECT cr.*, u.username, u.email " +
                                       "FROM customer_rep cr " +
                                       "JOIN user u ON cr.userID = u.userID " +
                                       "ORDER BY cr.repID";
                            
                            Statement stmt = conn.createStatement();
                            ResultSet rs = stmt.executeQuery(sql);
                            
                            boolean hasReps = false;
                            while(rs.next()) {
                                hasReps = true;
                    %>
                    <tr>
                        <td><%= rs.getInt("repID") %></td>
                        <td><%= rs.getString("username") %></td>
                        <td><%= rs.getString("email") %></td>
                        <td><%= rs.getString("department") %></td>
                        <td><%= rs.getDate("hireDate") != null ? rs.getDate("hireDate") : "N/A" %></td>
                        <td>
                            <form method="post" style="display: inline;">
                                <input type="hidden" name="action" value="delete">
                                <input type="hidden" name="repID" value="<%= rs.getInt("repID") %>">
                                <button type="submit" class="delete-btn" onclick="return confirm('Are you sure?')">Delete</button>
                            </form>
                        </td>
                    </tr>
                    <%
                            }
                            
                            if (!hasReps) {
                                out.println("<tr><td colspan='6' style='text-align:center;'>No customer representatives found</td></tr>");
                            }
                            
                            conn.close();
                        } catch(Exception e) {
                            e.printStackTrace();
                            out.println("<tr><td colspan='6'>Error loading representatives</td></tr>");
                        }
                    %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
