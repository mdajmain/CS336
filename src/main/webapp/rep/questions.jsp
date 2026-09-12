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
    <title>Customer Questions - BuyMe Rep</title>
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
        .back-btn {
            color: white;
            text-decoration: none;
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .container { max-width: 1200px; margin: 30px auto; padding: 0 20px; }
        
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
        .alert-success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .alert-error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        
        .questions-list { display: flex; flex-direction: column; gap: 15px; }
        
        .question-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .question-header {
            padding: 20px;
            border-bottom: 1px solid #eee;
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }
        .question-meta h3 { color: #333; margin-bottom: 5px; }
        .question-meta p { color: #666; font-size: 14px; }
        .question-status {
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 12px;
            font-weight: 600;
        }
        .status-open { background: #fff3cd; color: #856404; }
        .status-answered { background: #cce5ff; color: #004085; }
        .status-closed { background: #d4edda; color: #155724; }
        
        .question-body { padding: 20px; }
        .question-body .message {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
            border-left: 4px solid #667eea;
        }
        .question-body .answer {
            background: #e8f5e9;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 15px;
            border-left: 4px solid #27ae60;
        }
        .question-body .answer h4 { color: #27ae60; margin-bottom: 10px; }
        
        .answer-form { margin-top: 15px; }
        .answer-form textarea {
            width: 100%;
            padding: 15px;
            border: 2px solid #ddd;
            border-radius: 5px;
            resize: vertical;
            min-height: 100px;
            font-family: inherit;
        }
        .answer-form textarea:focus {
            border-color: #667eea;
            outline: none;
        }
        .form-actions {
            display: flex;
            gap: 10px;
            margin-top: 10px;
        }
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: opacity 0.3s;
        }
        .btn-primary { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; }
        .btn-success { background: #27ae60; color: white; }
        .btn-secondary { background: #6c757d; color: white; }
        .btn:hover { opacity: 0.9; }
        
        .no-questions {
            background: white;
            padding: 50px;
            text-align: center;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .no-questions h3 { color: #333; margin-bottom: 10px; }
        .no-questions p { color: #666; }
        
        .auction-link {
            display: inline-block;
            margin-top: 10px;
            color: #667eea;
            text-decoration: none;
        }
        .auction-link:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="dashboard.jsp" class="back-btn">← Back to Dashboard</a>
            <h2>Customer Questions</h2>
            <span>Rep: <%= user.getUsername() %></span>
        </div>
    </nav>

    <div class="container">
        <div class="page-header">
            <h1>Customer Questions & Support</h1>
            <p>View and respond to customer inquiries</p>
            
            <div class="filters">
                <a href="questions.jsp?filter=all" class="filter-btn <%= "all".equals(filter) ? "active" : "" %>">All Questions</a>
                <a href="questions.jsp?filter=open" class="filter-btn <%= "open".equals(filter) ? "active" : "" %>">Open</a>
                <a href="questions.jsp?filter=answered" class="filter-btn <%= "answered".equals(filter) ? "active" : "" %>">Answered</a>
                <a href="questions.jsp?filter=closed" class="filter-btn <%= "closed".equals(filter) ? "active" : "" %>">Closed</a>
                
                <form class="search-box" method="get">
                    <input type="hidden" name="filter" value="<%= filter %>">
                    <input type="text" name="search" placeholder="Search by keyword..." value="<%= search != null ? search : "" %>">
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
        
        <div class="questions-list">
            <%
                try (Connection conn = com.buyme.util.DatabaseConnection.getConnection()) {
                    StringBuilder sql = new StringBuilder();
                    sql.append("SELECT q.*, u.username, u.email, ");
                    sql.append("a.auctionID as auctionNum, i.itemName ");
                    sql.append("FROM question q ");
                    sql.append("JOIN user u ON q.userID = u.userID ");
                    sql.append("LEFT JOIN auction a ON q.auctionID = a.auctionID ");
                    sql.append("LEFT JOIN item i ON a.itemID = i.itemID ");
                    sql.append("WHERE 1=1 ");
                    
                    if (!"all".equals(filter)) {
                        sql.append("AND q.status = ? ");
                    }
                    if (search != null && !search.trim().isEmpty()) {
                        sql.append("AND (q.subject LIKE ? OR q.message LIKE ? OR u.username LIKE ?) ");
                    }
                    sql.append("ORDER BY CASE q.status WHEN 'open' THEN 1 WHEN 'answered' THEN 2 ELSE 3 END, q.createdTime DESC");
                    
                    try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                        int paramIndex = 1;
                        
                        if (!"all".equals(filter)) {
                            ps.setString(paramIndex++, filter);
                        }
                        if (search != null && !search.trim().isEmpty()) {
                            String searchPattern = "%" + search + "%";
                            ps.setString(paramIndex++, searchPattern);
                            ps.setString(paramIndex++, searchPattern);
                            ps.setString(paramIndex++, searchPattern);
                        }
                        
                        try (ResultSet rs = ps.executeQuery()) {
                            boolean hasQuestions = false;
                            
                            while (rs.next()) {
                                hasQuestions = true;
                                int questionID = rs.getInt("questionID");
                                String username = rs.getString("username");
                                String email = rs.getString("email");
                                String subject = rs.getString("subject");
                                String questionMessage = rs.getString("message");
                                String answer = rs.getString("answer");
                                String status = rs.getString("status");
                                Timestamp createdTime = rs.getTimestamp("createdTime");
                                Timestamp answeredTime = rs.getTimestamp("answeredTime");
                                Integer auctionNum = rs.getObject("auctionNum") != null ? rs.getInt("auctionNum") : null;
                                String itemName = rs.getString("itemName");
            %>
                <div class="question-card">
                    <div class="question-header">
                        <div class="question-meta">
                            <h3><%= subject != null && !subject.isEmpty() ? subject : "No Subject" %></h3>
                            <p>From: <strong><%= username %></strong> (<%= email %>) | <%= createdTime %></p>
                            <% if (auctionNum != null) { %>
                                <a href="<%= request.getContextPath() %>/auction/view.jsp?id=<%= auctionNum %>" class="auction-link">
                                    Related Auction: <%= itemName %> (#<%= auctionNum %>)
                                </a>
                            <% } %>
                        </div>
                        <span class="question-status status-<%= status %>"><%= status.toUpperCase() %></span>
                    </div>
                    <div class="question-body">
                        <div class="message">
                            <strong>Question:</strong>
                            <p><%= questionMessage %></p>
                        </div>
                        
                        <% if (answer != null && !answer.isEmpty()) { %>
                            <div class="answer">
                                <h4>Answer:</h4>
                                <p><%= answer %></p>
                                <% if (answeredTime != null) { %>
                                    <small>Answered on: <%= answeredTime %></small>
                                <% } %>
                            </div>
                        <% } %>
                        
                        <% if (!"closed".equals(status)) { %>
                            <form class="answer-form" action="answer-question.jsp" method="post">
                                <input type="hidden" name="questionID" value="<%= questionID %>">
                                <textarea name="answer" placeholder="Type your answer here..." required><%= answer != null ? answer : "" %></textarea>
                                <div class="form-actions">
                                    <button type="submit" name="action" value="answer" class="btn btn-primary">
                                        <%= answer != null ? "Update Answer" : "Submit Answer" %>
                                    </button>
                                    <% if (answer != null) { %>
                                        <button type="submit" name="action" value="close" class="btn btn-success">Mark as Closed</button>
                                    <% } %>
                                </div>
                            </form>
                        <% } else { %>
                            <form action="answer-question.jsp" method="post" style="margin-top: 10px;">
                                <input type="hidden" name="questionID" value="<%= questionID %>">
                                <button type="submit" name="action" value="reopen" class="btn btn-secondary">Reopen Question</button>
                            </form>
                        <% } %>
                    </div>
                </div>
            <%
                            }
                            
                            if (!hasQuestions) {
            %>
                <div class="no-questions">
                    <h3>No Questions Found</h3>
                    <p>
                        <% if (!"all".equals(filter)) { %>
                            No <%= filter %> questions at the moment.
                        <% } else if (search != null && !search.isEmpty()) { %>
                            No questions matching "<%= search %>".
                        <% } else { %>
                            There are no customer questions to display.
                        <% } %>
                    </p>
                </div>
            <%
                            }
                        }
                    }
                } catch (Exception e) {
                    e.printStackTrace();
            %>
                <div class="alert alert-error">Error loading questions: <%= e.getMessage() %></div>
            <%
                }
            %>
        </div>
    </div>
</body>
</html>
