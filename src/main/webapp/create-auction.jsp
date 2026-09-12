<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>
<%
    User user = (User) session.getAttribute("user");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Auction - BuyMe</title>
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
            padding: 8px 15px;
            border-radius: 5px;
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
            max-width: 800px;
            margin: 30px auto;
            padding: 0 20px;
        }
        
        .form-container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        h1 {
            color: #333;
            margin-bottom: 30px;
            padding-bottom: 10px;
            border-bottom: 2px solid #e1e1e1;
        }
        
        .form-section {
            margin-bottom: 30px;
        }
        
        .form-section h3 {
            color: #667eea;
            margin-bottom: 15px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 5px;
            color: #333;
            font-weight: 500;
        }
        
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 10px;
            border: 2px solid #e1e1e1;
            border-radius: 5px;
            font-size: 16px;
        }
        
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .form-group textarea {
            resize: vertical;
            min-height: 100px;
        }
        
        .form-row {
            display: flex;
            gap: 20px;
        }
        
        .form-row .form-group {
            flex: 1;
        }
        
        .help-text {
            font-size: 14px;
            color: #666;
            margin-top: 5px;
        }
        
        .submit-btn {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 40px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
        }
        
        .submit-btn:hover {
            transform: translateY(-2px);
        }
        
        .required {
            color: #e74c3c;
        }
        
        .error {
            background: #fee;
            color: #c33;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        
        .success {
            background: #efe;
            color: #3c3;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 20px;
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
            </ul>
            
            <div class="user-info">
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="logout" class="logout-btn">Logout</a>
            </div>
        </div>
    </nav>
    
    <div class="container">
        <div class="form-container">
            <h1>Create New Auction</h1>
            
            <% if (request.getAttribute("error") != null) { %>
                <div class="error"><%= request.getAttribute("error") %></div>
            <% } %>
            
            <% if (request.getAttribute("success") != null) { %>
                <div class="success"><%= request.getAttribute("success") %></div>
            <% } %>
            
            <form action="CreateAuctionServlet" method="post">
                <div class="form-section">
                    <h3>Item Details</h3>
                    
                    <div class="form-group">
                        <label for="itemName">Item Name <span class="required">*</span></label>
                        <input type="text" id="itemName" name="itemName" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="description">Description <span class="required">*</span></label>
                        <textarea id="description" name="description" required></textarea>
                        <div class="help-text">Provide a detailed description of your item</div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="category">Category <span class="required">*</span></label>
                            <select id="category" name="category" required onchange="loadSubcategories()">
                                <option value="">Select Category</option>
                                <%
                                    try {
                                        Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                        Statement stmt = conn.createStatement();
                                        ResultSet rs = stmt.executeQuery("SELECT * FROM category WHERE level = 1");
                                        while(rs.next()) {
                                %>
                                    <option value="<%= rs.getInt("categoryID") %>"><%= rs.getString("categoryName") %></option>
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
						    <label for="subcategory">Subcategory <span class="required">*</span></label>
						    <select id="subcategory" name="subcategory" required>
						        <option value="1">Truck</option>
						        <option value="2">Hatchback</option>
						        <option value="3">Sedan</option>
						    </select>
						</div>

                    </div>
                    
                    <div class="form-group">
                        <label for="condition">Item Condition <span class="required">*</span></label>
                        <select id="condition" name="condition" required>
                            <option value="New">New</option>
                            <option value="Like New">Like New</option>
                            <option value="Very Good">Very Good</option>
                            <option value="Good">Good</option>
                            <option value="Acceptable">Acceptable</option>
                        </select>
                    </div>
                </div>
                
                <div class="form-section">
                    <h3>Auction Settings</h3>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="initialPrice">Starting Price ($) <span class="required">*</span></label>
                            <input type="number" id="initialPrice" name="initialPrice" step="0.01" min="0.01" required>
                            <div class="help-text">Minimum starting bid</div>
                        </div>
                        
                        <div class="form-group">
                            <label for="bidIncrement">Bid Increment ($) <span class="required">*</span></label>
                            <input type="number" id="bidIncrement" name="bidIncrement" step="0.01" min="0.50" value="0.50" required>
                            <div class="help-text">Minimum bid increase</div>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label for="reservePrice">Reserve Price ($)</label>
                        <input type="number" id="reservePrice" name="reservePrice" step="0.01" min="0">
                        <div class="help-text">Optional: Minimum price you'll accept (kept secret)</div>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label for="startDateTime">Start Date & Time <span class="required">*</span></label>
                            <input type="datetime-local" id="startDateTime" name="startDateTime" required>
                        </div>
                        
                        <div class="form-group">
                            <label for="closeDateTime">End Date & Time <span class="required">*</span></label>
                            <input type="datetime-local" id="closeDateTime" name="closeDateTime" required>
                        </div>
                    </div>
                </div>
                
                <button type="submit" class="submit-btn">Create Auction</button>
            </form>
        </div>
    </div>
    
    <script>
    
	    function toLocalDateTimeValue(date) {
	        const pad = n => n.toString().padStart(2, '0');
	        const year   = date.getFullYear();
	        const month  = pad(date.getMonth() + 1);
	        const day    = pad(date.getDate());
	        const hour   = pad(date.getHours());
	        const minute = pad(date.getMinutes());
	        return `${year}-${month}-${day}T${hour}:${minute}`;
	    }
	
	    const now = new Date();
	    const nowStr = toLocalDateTimeValue(now);
	    const startInput  = document.getElementById('startDateTime');
	    const closeInput  = document.getElementById('closeDateTime');
	
	    // start: now
	    startInput.min   = nowStr;
	    startInput.value = nowStr;
	
	    // end: at least 24h later
	    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
	    const tomorrowStr = toLocalDateTimeValue(tomorrow);
	    closeInput.min   = tomorrowStr;
	    closeInput.value = tomorrowStr;
	

    </script>
</body>
</html>
