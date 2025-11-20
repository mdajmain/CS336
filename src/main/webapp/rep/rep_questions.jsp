<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"customer_rep".equals(user.getUserType())) {
        response.sendRedirect("../login");
        return;
    }
    
    // Get rep ID
    int repID = 0;
    try {
        Connection conn = com.buyme.util.DatabaseConnection.getConnection();
        PreparedStatement pstmt = conn.prepareStatement("SELECT repID FROM customer_rep WHERE userID = ?");
        pstmt.setInt(1, user.getUserID());
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            repID = rs.getInt("repID");
        }
        conn.close();
    } catch(Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Customer Questions - Rep Dashboard</title>
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
        
        .question-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .question-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 10px;
            border-bottom: 1px solid #e1e1e1;
        }
        
        .question-info {
            color: #666;
            font-size: 14px;
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
        
        .status-closed {
            background: #f8d7da;
            color: #721c24;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
        }
        
        .question-subject {
            font-size: 18px;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        
        .question-message {
            color: #555;
            margin-bottom: 15px;
            line-height: 1.6;
        }
        
        .answer-section {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 15px;
        }
        
        .answer-form textarea {
            width: 100%;
            padding: 10px;
            border: 1px solid #ddd;
            border-radius: 5px;
            margin-bottom: 10px;
            resize: vertical;
            min-height: 100px;
        }
        
        .btn {
            padding: 10px 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .tab {
            padding: 10px 20px;
            background: none;
            border: none;
            color: #666;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
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
        
        .success {
            background: #d4edda;
            color: #155724;
            padding: 12px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .no-questions {
            text-align: center;
            padding: 60px;
            background: white;
            border-radius: 10px;
            color: #999;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <h2>Customer Representative Dashboard</h2>
            <div>
                <span>Rep: <%= user.getUsername() %></span>
                <a href="../logout" style="color: white; margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
        
        <h1>Customer Questions</h1>
        
        <%
            // Handle answer submission
            if ("POST".equals(request.getMethod()) && request.getParameter("answer") != null) {
                String questionID = request.getParameter("questionID");
                String answer = request.getParameter("answer");
                
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    // Update question with answer
                    PreparedStatement updateStmt = conn.prepareStatement(
                        "UPDATE question SET answer = ?, status = 'answered', answeredTime = NOW(), repID = ? WHERE questionID = ?"
                    );
                    updateStmt.setString(1, answer);
                    updateStmt.setInt(2, repID);
                    updateStmt.setString(3, questionID);
                    updateStmt.executeUpdate();
                    
                    out.println("<div class='success'>Answer submitted successfully!</div>");
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                }
            }
        %>
        
        <div class="tabs">
            <button class="tab active" onclick="showTab('open')">Open Questions</button>
            <button class="tab" onclick="showTab('answered')">Answered</button>
            <button class="tab" onclick="showTab('all')">All Questions</button>
        </div>
        
        <div id="questions-container">
            <%
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    // Get all questions
                    String sql = "SELECT q.*, u.username, " +
                                "(SELECT username FROM user WHERE userID = " +
                                "(SELECT userID FROM customer_rep WHERE repID = q.repID)) as repName " +
                                "FROM question q " +
                                "JOIN user u ON q.userID = u.userID " +
                                "ORDER BY " +
                                "CASE WHEN q.status = 'open' THEN 1 " +
                                "WHEN q.status = 'answered' THEN 2 " +
                                "ELSE 3 END, " +
                                "q.createdTime DESC";
                    
                    Statement stmt = conn.createStatement();
                    ResultSet rs = stmt.executeQuery(sql);
                    
                    boolean hasQuestions = false;
                    while(rs.next()) {
                        hasQuestions = true;
                        String status = rs.getString("status");
                        String statusClass = "status-" + status;
            %>
            <div class="question-card" data-status="<%= status %>">
                <div class="question-header">
                    <div>
                        <span class="question-info">From: <%= rs.getString("username") %></span>
                        <span class="question-info"> | </span>
                        <span class="question-info"><%= rs.getTimestamp("createdTime") %></span>
                    </div>
                    <span class="<%= statusClass %>"><%= status.toUpperCase() %></span>
                </div>
                
                <div class="question-subject"><%= rs.getString("subject") %></div>
                <div class="question-message"><%= rs.getString("message") %></div>
                
                <% if ("open".equals(status)) { %>
                <div class="answer-section">
                    <h4>Your Answer:</h4>
                    <form method="post" class="answer-form">
                        <input type="hidden" name="questionID" value="<%= rs.getInt("questionID") %>">
                        <textarea name="answer" required placeholder="Type your answer here..."></textarea>
                        <button type="submit" class="btn">Submit Answer</button>
                    </form>
                </div>
                <% } else if (rs.getString("answer") != null) { %>
                <div class="answer-section">
                    <h4>Answer (by <%= rs.getString("repName") %>):</h4>
                    <p><%= rs.getString("answer") %></p>
                    <p style="font-size: 12px; color: #666; margin-top: 10px;">
                        Answered on: <%= rs.getTimestamp("answeredTime") %>
                    </p>
                </div>
                <% } %>
            </div>
            <%
                    }
                    
                    if (!hasQuestions) {
                        out.println("<div class='no-questions'>No questions found</div>");
                    }
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                }
            %>
        </div>
    </div>
    
    <script>
        function showTab(tab) {
            const cards = document.querySelectorAll('.question-card');
            
            cards.forEach(card => {
                const status = card.dataset.status;
                
                if (tab === 'all') {
                    card.style.display = 'block';
                } else if (tab === 'open' && status === 'open') {
                    card.style.display = 'block';
                } else if (tab === 'answered' && (status === 'answered' || status === 'closed')) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
            
            document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
            event.target.classList.add('active');
        }
        
        // Show only open questions by default
        showTab('open');
    </script>
</body>
</html>
