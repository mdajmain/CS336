<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect("login");
        return;
    }
    
    // Get view mode and search parameters
    String viewMode = request.getParameter("view");
    if (viewMode == null) viewMode = "my";
    
    String searchKeyword = request.getParameter("search");
    if (searchKeyword == null) searchKeyword = "";
    
    String filterStatus = request.getParameter("status");
    if (filterStatus == null) filterStatus = "all";
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Q&A Support - BuyMe</title>
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
            max-width: 1400px;
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
            max-width: 1400px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .page-header {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        
        .page-header p {
            color: #666;
        }
        
        /* Tabs */
        .tabs {
            background: white;
            padding: 15px 20px 0 20px;
            border-radius: 10px 10px 0 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            display: flex;
            gap: 10px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .tab {
            padding: 12px 24px;
            background: none;
            border: none;
            color: #666;
            cursor: pointer;
            border-bottom: 3px solid transparent;
            margin-bottom: -2px;
            font-weight: 600;
            text-decoration: none;
            display: inline-block;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        /* Search Section */
        .search-section {
            background: white;
            padding: 20px;
            border-radius: 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            margin-bottom: 0;
        }
        
        .search-form {
            display: flex;
            gap: 10px;
            align-items: center;
            flex-wrap: wrap;
        }
        
        .search-input {
            flex: 1;
            min-width: 300px;
            padding: 10px 15px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 15px;
        }
        
        .search-select {
            padding: 10px 15px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 15px;
        }
        
        .search-btn {
            padding: 10px 25px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 600;
        }
        
        .search-btn:hover {
            background: #5568d3;
        }
        
        .clear-btn {
            padding: 10px 20px;
            background: #6c757d;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            text-decoration: none;
        }
        
        /* Form Section */
        .form-section {
            background: white;
            padding: 30px;
            border-radius: 0 0 10px 10px;
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
        
        /* Questions Section */
        .questions-section {
            background: white;
            padding: 30px;
            border-radius: 0 0 10px 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .section-title {
            color: #333;
            margin-bottom: 20px;
            font-size: 20px;
        }
        
        .question-card {
            padding: 20px;
            border-bottom: 1px solid #e1e1e1;
            transition: background 0.3s;
        }
        
        .question-card:last-child {
            border-bottom: none;
        }
        
        .question-card:hover {
            background: #f8f9fa;
        }
        
        .question-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            margin-bottom: 10px;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .question-subject {
            font-weight: bold;
            color: #333;
            font-size: 18px;
        }
        
        .question-meta {
            display: flex;
            gap: 15px;
            margin-bottom: 10px;
            font-size: 13px;
            color: #666;
        }
        
        .question-meta-item {
            display: flex;
            align-items: center;
            gap: 5px;
        }
        
        .question-message {
            color: #555;
            margin-bottom: 15px;
            line-height: 1.6;
        }
        
        .answer-box {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-top: 10px;
            border-left: 4px solid #28a745;
        }
        
        .answer-header {
            font-weight: 600;
            color: #28a745;
            margin-bottom: 8px;
        }
        
        .badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
        }
        
        .status-open {
            background: #fff3cd;
            color: #856404;
        }
        
        .status-answered {
            background: #d4edda;
            color: #155724;
        }
        
        .status-closed {
            background: #f8d7da;
            color: #721c24;
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
            padding: 60px 20px;
            color: #999;
        }
        
        .no-questions h3 {
            margin-bottom: 10px;
            color: #666;
        }
        
        .date-text {
            font-size: 12px;
            color: #999;
        }
        
        .search-highlight {
            background: #fff3cd;
            padding: 2px 4px;
            border-radius: 3px;
        }
        
        .stats-bar {
            background: #f8f9fa;
            padding: 15px 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .stat-item {
            font-size: 14px;
            color: #666;
        }
        
        .stat-item strong {
            color: #333;
            font-size: 20px;
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
        <div class="page-header">
            <h1>Customer Support & Q&A</h1>
            <p>Ask questions and browse community answers</p>
        </div>
        
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
                    out.println("<div class='success'>✅ Your question has been submitted successfully! A customer representative will respond soon.</div>");
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    out.println("<div class='alert-error'>Error submitting question. Please try again.</div>");
                }
            }
        %>
        
        <!-- Tabs -->
        <div class="tabs">
            <a href="questions.jsp?view=my" class="tab <%= "my".equals(viewMode) ? "active" : "" %>">
                My Questions
            </a>
            <a href="questions.jsp?view=ask" class="tab <%= "ask".equals(viewMode) ? "active" : "" %>">
                Ask a Question
            </a>
            <a href="questions.jsp?view=browse" class="tab <%= "browse".equals(viewMode) ? "active" : "" %>">
                Browse All Q&A
            </a>
        </div>
        
        <% if ("ask".equals(viewMode)) { %>
        <!-- Ask Question Form -->
        <div class="form-section">
            <h2 class="section-title">Submit Your Question</h2>
            <form method="post">
                <div class="form-group">
                    <label for="subject">Subject *</label>
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
                    <label for="message">Your Question *</label>
                    <textarea id="message" name="message" required placeholder="Please describe your issue or question in detail..."></textarea>
                </div>
                
                <button type="submit" class="btn">Submit Question</button>
            </form>
        </div>
        
        <% } else if ("browse".equals(viewMode)) { %>
        <!-- Browse All Q&A -->
        <div class="search-section">
            <form method="get" action="questions.jsp" class="search-form">
                <input type="hidden" name="view" value="browse">
                <input type="text" 
                       name="search" 
                       class="search-input"
                       placeholder="🔍 Search questions by keywords..."
                       value="<%= searchKeyword %>">
                <select name="status" class="search-select">
                    <option value="all" <%= "all".equals(filterStatus) ? "selected" : "" %>>All Status</option>
                    <option value="open" <%= "open".equals(filterStatus) ? "selected" : "" %>>Open</option>
                    <option value="answered" <%= "answered".equals(filterStatus) ? "selected" : "" %>>Answered</option>
                    <option value="closed" <%= "closed".equals(filterStatus) ? "selected" : "" %>>Closed</option>
                </select>
                <button type="submit" class="search-btn">Search</button>
                <a href="questions.jsp?view=browse" class="clear-btn">Clear</a>
            </form>
        </div>
        
        <div class="questions-section">
            <%
                try {
                    Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                    
                    // Build query with search and filters
                    StringBuilder sql = new StringBuilder();
                    sql.append("SELECT q.*, u.username as askerName, ");
                    sql.append("(SELECT username FROM user WHERE userID = ");
                    sql.append("(SELECT userID FROM customer_rep WHERE repID = q.repID)) as repName ");
                    sql.append("FROM question q ");
                    sql.append("JOIN user u ON q.userID = u.userID ");
                    sql.append("WHERE 1=1 ");
                    
                    if (!searchKeyword.isEmpty()) {
                        sql.append("AND (q.subject LIKE ? OR q.message LIKE ? OR q.answer LIKE ?) ");
                    }
                    
                    if (!"all".equals(filterStatus)) {
                        sql.append("AND q.status = ? ");
                    }
                    
                    sql.append("ORDER BY q.createdTime DESC");
                    
                    PreparedStatement pstmt = conn.prepareStatement(sql.toString());
                    int paramIndex = 1;
                    
                    if (!searchKeyword.isEmpty()) {
                        String searchPattern = "%" + searchKeyword + "%";
                        pstmt.setString(paramIndex++, searchPattern);
                        pstmt.setString(paramIndex++, searchPattern);
                        pstmt.setString(paramIndex++, searchPattern);
                    }
                    
                    if (!"all".equals(filterStatus)) {
                        pstmt.setString(paramIndex++, filterStatus);
                    }
                    
                    ResultSet rs = pstmt.executeQuery();
                    
                    // Count results
                    int totalResults = 0;
                    SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy 'at' HH:mm");
            %>
            
            <div class="stats-bar">
                <div class="stat-item">
                    <strong id="resultCount">0</strong> questions found
                    <% if (!searchKeyword.isEmpty()) { %>
                        matching "<%= searchKeyword %>"
                    <% } %>
                </div>
            </div>
            
            <%
                    boolean hasQuestions = false;
                    while(rs.next()) {
                        hasQuestions = true;
                        totalResults++;
                        String status = rs.getString("status");
                        String askerName = rs.getString("askerName");
                        String repName = rs.getString("repName");
            %>
            <div class="question-card">
                <div class="question-header">
                    <div class="question-subject"><%= rs.getString("subject") %></div>
                    <span class="badge status-<%= status %>"><%= status.toUpperCase() %></span>
                </div>
                
                <div class="question-meta">
                    <div class="question-meta-item">
                        👤 Asked by: <strong><%= askerName %></strong>
                    </div>
                    <div class="question-meta-item">
                        📅 <%= sdf.format(rs.getTimestamp("createdTime")) %>
                    </div>
                    <% if (rs.getInt("auctionID") != 0) { %>
                    <div class="question-meta-item">
                        🏷️ <a href="auction-details.jsp?id=<%= rs.getInt("auctionID") %>" style="color: #667eea;">
                            Auction #<%= rs.getInt("auctionID") %>
                        </a>
                    </div>
                    <% } %>
                </div>
                
                <div class="question-message"><%= rs.getString("message") %></div>
                
                <% if (rs.getString("answer") != null) { %>
                <div class="answer-box">
                    <div class="answer-header">
                        ✅ Answer from <%= repName != null ? repName : "Support Team" %>:
                    </div>
                    <%= rs.getString("answer") %>
                    <div class="date-text" style="margin-top: 10px;">
                        Answered on <%= sdf.format(rs.getTimestamp("answeredTime")) %>
                    </div>
                </div>
                <% } else if ("open".equals(status)) { %>
                <div style="background: #fff3cd; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 14px;">
                    ⏳ Waiting for customer representative response...
                </div>
                <% } %>
            </div>
            <%
                    }
                    
                    if (!hasQuestions) {
            %>
            <div class="no-questions">
                <h3>No questions found</h3>
                <p>Try adjusting your search or filters</p>
            </div>
            <%
                    }
            %>
            
            <script>
                document.getElementById('resultCount').textContent = '<%= totalResults %>';
            </script>
            
            <%
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    out.println("<div class='no-questions' style='color: red;'>Error loading questions: " + e.getMessage() + "</div>");
                }
            %>
        </div>
        
        <% } else { %>
        <!-- My Questions -->
        <div class="questions-section">
            <h2 class="section-title">Your Questions</h2>
            
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
                    SimpleDateFormat sdf = new SimpleDateFormat("MMM dd, yyyy 'at' HH:mm");
                    
                    while(rs.next()) {
                        hasQuestions = true;
                        String status = rs.getString("status");
            %>
            <div class="question-card">
                <div class="question-header">
                    <div class="question-subject"><%= rs.getString("subject") %></div>
                    <span class="badge status-<%= status %>"><%= status.toUpperCase() %></span>
                </div>
                
                <div class="date-text" style="margin-bottom: 10px;">
                    Asked on <%= sdf.format(rs.getTimestamp("createdTime")) %>
                </div>
                
                <div class="question-message"><%= rs.getString("message") %></div>
                
                <% if (rs.getString("answer") != null) { %>
                <div class="answer-box">
                    <div class="answer-header">
                        ✅ Answer from <%= rs.getString("repName") != null ? rs.getString("repName") : "Support Team" %>:
                    </div>
                    <%= rs.getString("answer") %>
                    <div class="date-text" style="margin-top: 10px;">
                        Answered on <%= sdf.format(rs.getTimestamp("answeredTime")) %>
                    </div>
                </div>
                <% } else if ("open".equals(status)) { %>
                <div style="background: #fff3cd; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 14px;">
                    ⏳ Waiting for customer representative response...
                </div>
                <% } %>
            </div>
            <%
                    }
                    
                    if (!hasQuestions) {
            %>
            <div class="no-questions">
                <h3>You haven't asked any questions yet</h3>
                <p><a href="questions.jsp?view=ask" style="color: #667eea;">Ask your first question</a> or 
                   <a href="questions.jsp?view=browse" style="color: #667eea;">browse community Q&A</a></p>
            </div>
            <%
                    }
                    
                    conn.close();
                } catch(Exception e) {
                    e.printStackTrace();
                    out.println("<div class='no-questions' style='color: red;'>Error loading questions</div>");
                }
            %>
        </div>
        <% } %>
    </div>
</body>
</html>

