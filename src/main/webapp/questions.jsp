<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Support - BuyMe</title>
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
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .nav-container {
            max-width: 1200px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 0 20px;
        }
        
        .logo {
            color: white;
            font-size: 24px;
            font-weight: bold;
            text-decoration: none;
        }
        
        .nav-menu {
            display: flex;
            list-style: none;
            gap: 30px;
        }
        
        .nav-menu a {
            color: white;
            text-decoration: none;
        }
        
        .user-info {
            color: white;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .logout-btn {
            background: rgba(255,255,255,0.2);
            color: white;
            border: 1px solid white;
            padding: 8px 20px;
            border-radius: 5px;
            text-decoration: none;
        }
        
        .container {
            max-width: 1200px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
        }
        
        .form-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 30px;
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
        
        input, select, textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 16px;
        }
        
        textarea {
            resize: vertical;
            min-height: 120px;
        }
        
        .btn {
            padding: 12px 30px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
        }
        
        .questions-section {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .question-card {
            padding: 20px;
            border-bottom: 1px solid #e1e1e1;
        }
        
        .question-card:last-child {
            border-bottom: none;
        }
        
        .question-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        
        .question-subject {
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        
        .question-message {
            color: #555;
            margin-bottom: 15px;
        }
        
        .answer-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 10px;
        }
        
        .status-open {
            background: #fff3cd;
            color: #856404;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .status-answered {
            background: #d4edda;
            color: #155724;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .no-questions {
            text-align: center;
            padding: 40px;
            color: #999;
        }
        
        .date-text {
            font-size: 12px;
            color: #999;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="logo">BuyMe</a>
            
            <ul class="nav-menu">
                <li><a href="dashboard.jsp">Home</a></li>
                <li><a href="browse.jsp">Browse Auctions</a></li>
                <li><a href="create-auction.jsp">Sell Item</a></li>
                <li><a href="my-bids.jsp">My Bids</a></li>
                <li><a href="questions.jsp">Support</a></li>
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <h1>Customer Support</h1>
        
        <%
            // Handle form submission
            if ("POST".equals(request.getMethod()) && request.getParameter("subject") != null) {
                String subject = request.getParameter("subject");
                String message = request.getParameter("message");
                String auctionID = request.getParameter("auctionID");
                
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    String sql = "INSERT INTO question (userID, subject, message, auctionID, status) VALUES (?, ?, ?, ?, 'open')";
                    PreparedStatement pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, user.getUserID());
                    pstmt.setString(2, subject);
                    pstmt.setString(3, message);
                    
                    if (auctionID != null && !auctionID.isEmpty()) {
                        pstmt.setInt(4, Integer.parseInt(auctionID));
                    } else {
                        pstmt.setNull(4, Types.INTEGER);
                    }
                    
                    pstmt.executeUpdate();
                    out.println("<div class='success'>Your question has been submitted successfully! A customer representative will respond soon.</div>");
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                }
            }
        %>
        
        <div class="form-section">
            <h2>Ask a Question</h2>
            <form method="post">
                <div class="form-group">
                    <label for="subject">Subject</label>
                    <input type="text" id="subject" name="subject" required placeholder="Brief description of your issue">
                </div>
                
                <div class="form-group">
                    <label for="auctionID">Related Auction (Optional)</label>
                    <select id="auctionID" name="auctionID">
                        <option value="">Not related to specific auction</option>
                        <%
                            try {
                                Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                
                                // Get user's recent auctions (as buyer or seller)
                                String sql = "SELECT DISTINCT a.auctionID, i.itemName " +
                                           "FROM auction a " +
                                           "JOIN item i ON a.itemID = i.itemID " +
                                           "LEFT JOIN bid b ON a.auctionID = b.auctionID " +
                                           "WHERE a.sellerID = ? OR b.buyerID = ? " +
                                           "ORDER BY a.closeDateTime DESC " +
                                           "LIMIT 20";
                                
                                PreparedStatement pstmt = conn.prepareStatement(sql);
                                pstmt.setInt(1, user.getUserID());
                                pstmt.setInt(2, user.getUserID());
                                ResultSet rs = pstmt.executeQuery();
                                
                                while(rs.next()) {
                        %>
                        <option value="<%= rs.getInt("auctionID") %>">
                            #<%= rs.getInt("auctionID") %> - <%= rs.getString("itemName") %>
                        </option>
                        <%
                                }
                                conn.close();
                            } catch(Exception e) {
                                e.printStackTrace();
                            }
                        %>
                    </select>
                </div>
                
                <div class="form-group">
                    <label for="message">Your Question</label>
                    <textarea id="message" name="message" required placeholder="Please describe your issue or question in detail..."></textarea>
                </div>
                
                <button type="submit" class="btn">Submit Question</button>
            </form>
        </div>
        
        <div class="questions-section">
            <h2>Your Previous Questions</h2>
            
            <%
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    String sql = "SELECT q.*, " +
                                "(SELECT username FROM user WHERE userID = " +
                                "(SELECT userID FROM customer_rep WHERE repID = q.repID)) as repName " +
                                "FROM question q " +
                                "WHERE q.userID = ? " +
                                "ORDER BY q.createdTime DESC";
                    
                    PreparedStatement pstmt = conn.prepareStatement(sql);
                    pstmt.setInt(1, user.getUserID());
                    ResultSet rs = pstmt.executeQuery();
                    
                    boolean hasQuestions = false;
                    while(rs.next()) {
                        hasQuestions = true;
                        String status = rs.getString("status");
            %>
            <div class="question-card">
                <div class="question-header">
                    <div class="question-subject"><%= rs.getString("subject") %></div>
                    <span class="status-<%= status %>"><%= status.toUpperCase() %></span>
                </div>
                
                <div class="date-text">Asked on <%= rs.getTimestamp("createdTime") %></div>
                
                <div class="question-message"><%= rs.getString("message") %></div>
                
                <% if (rs.getString("answer") != null) { %>
                <div class="answer-box">
                    <strong>Answer from <%= rs.getString("repName") %>:</strong><br>
                    <%= rs.getString("answer") %>
                    <div class="date-text" style="margin-top: 10px;">
                        Answered on <%= rs.getTimestamp("answeredTime") %>
                    </div>
                </div>
                <% } else if ("open".equals(status)) { %>
                <div class="answer-box" style="background: #fff3cd;">
                    Waiting for customer representative response...
                </div>
                <% } %>
            </div>
            <%
                    }
                    
                    if (!hasQuestions) {
                        out.println("<div class='no-questions'>You haven't asked any questions yet</div>");
                    }
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                }
            %>
        </div>
    </div>
</body>
</html>
