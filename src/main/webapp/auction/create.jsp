<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.buyme.model.User" %>
<%@ page import="java.sql.*" %>

<%
    // AUTH GUARD - Must be logged in as end_user
    User user = (User) session.getAttribute("user");
    String userType = (user == null || user.getUserType() == null)
            ? null
            : user.getUserType().trim();

    if (user == null || !"end_user".equalsIgnoreCase(userType)) {
        response.sendRedirect(request.getContextPath() + "/login?error=Please login to create an auction");
        return;
    }
    
    String message = request.getParameter("message");
    String error = request.getParameter("error");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Create Auction - BuyMe</title>
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
        .nav-container a { color: white; text-decoration: none; }
        
        .container { max-width: 800px; margin: 30px auto; padding: 0 20px; }
        
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #667eea;
            text-decoration: none;
        }
        
        .form-card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            padding: 30px;
        }
        .form-card h1 {
            color: #333;
            margin-bottom: 10px;
        }
        .form-card .subtitle {
            color: #666;
            margin-bottom: 30px;
        }
        
        .alert {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .alert-success { background: #d4edda; color: #155724; }
        .alert-error { background: #f8d7da; color: #721c24; }
        
        .form-section {
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 1px solid #eee;
        }
        .form-section:last-child { border-bottom: none; }
        .form-section h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 16px;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #333;
        }
        .form-group label span {
            color: #e74c3c;
        }
        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 12px;
            border: 2px solid #ddd;
            border-radius: 5px;
            font-size: 14px;
            font-family: inherit;
        }
        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            border-color: #667eea;
            outline: none;
        }
        .form-group textarea {
            min-height: 120px;
            resize: vertical;
        }
        .form-group .help-text {
            font-size: 12px;
            color: #666;
            margin-top: 5px;
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        @media (max-width: 600px) {
            .form-row { grid-template-columns: 1fr; }
        }
        
        .price-inputs {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
        }
        @media (max-width: 600px) {
            .price-inputs { grid-template-columns: 1fr; }
        }
        
        .dynamic-fields {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 5px;
            margin-top: 15px;
        }
        .dynamic-fields h4 {
            color: #333;
            margin-bottom: 15px;
        }
        
        .btn {
            padding: 15px 30px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
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
        
        .form-actions {
            display: flex;
            gap: 15px;
            margin-top: 30px;
        }
    </style>
</head>
<body>
    <nav class="navbar">
        <div class="nav-container">
            <a href="<%= request.getContextPath() %>/index.jsp"><h2>BuyMe</h2></a>
            <div>
                <span>Welcome, <%= user.getUsername() %></span>
                <a href="<%= request.getContextPath() %>/logout" style="margin-left: 20px;">Logout</a>
            </div>
        </div>
    </nav>

    <div class="container">
        <a href="<%= request.getContextPath() %>/dashboard.jsp" class="back-link">← Back to Dashboard</a>
        
        <% if (message != null) { %>
            <div class="alert alert-success"><%= message %></div>
        <% } %>
        <% if (error != null) { %>
            <div class="alert alert-error"><%= error %></div>
        <% } %>
        
        <div class="form-card">
            <h1>Create New Auction</h1>
            <p class="subtitle">List your item for sale on BuyMe</p>
            
            <form action="<%= request.getContextPath() %>/create-auction" method="post" id="auctionForm">
                
                <!-- Item Information -->
                <div class="form-section">
                    <h3>Item Information</h3>
                    
                    <div class="form-group">
                        <label>Item Name <span>*</span></label>
                        <input type="text" name="itemName" required maxlength="255" placeholder="Enter a descriptive title for your item">
                    </div>
                    
                    <div class="form-group">
                        <label>Description</label>
                        <textarea name="description" placeholder="Describe your item in detail. Include any important information buyers should know."></textarea>
                    </div>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Category <span>*</span></label>
                            <select name="categoryID" id="categorySelect" required onchange="loadSubcategories()">
                                <option value="">Select a category</option>
                                <%
                                    try (Connection conn = com.buyme.util.DatabaseConnection.getConnection();
                                         PreparedStatement ps = conn.prepareStatement(
                                            "SELECT categoryID, categoryName FROM category WHERE level = 1 ORDER BY categoryName");
                                         ResultSet rs = ps.executeQuery()) {
                                        while (rs.next()) {
                                %>
                                    <option value="<%= rs.getInt("categoryID") %>"><%= rs.getString("categoryName") %></option>
                                <%
                                        }
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                %>
                            </select>
                        </div>
                        
                        <div class="form-group">
                            <label>Subcategory <span>*</span></label>
                            <select name="subcategoryID" id="subcategorySelect" required>
                                <option value="">Select category first</option>
                            </select>
                        </div>
                    </div>
                    
                    <div class="form-group">
                        <label>Condition <span>*</span></label>
                        <select name="itemCondition" required>
                            <option value="New">New</option>
                            <option value="Like New">Like New</option>
                            <option value="Very Good">Very Good</option>
                            <option value="Good" selected>Good</option>
                            <option value="Acceptable">Acceptable</option>
                        </select>
                    </div>
                    
                    <!-- Dynamic fields based on subcategory -->
                    <div class="dynamic-fields" id="dynamicFields" style="display: none;">
                        <h4>Category-Specific Details</h4>
                        <div id="dynamicFieldsContainer"></div>
                    </div>
                </div>
                
                <!-- Pricing -->
                <div class="form-section">
                    <h3>Pricing</h3>
                    
                    <div class="price-inputs">
                        <div class="form-group">
                            <label>Starting Price ($) <span>*</span></label>
                            <input type="number" name="initialPrice" step="0.01" min="0.01" required placeholder="0.01">
                            <p class="help-text">Minimum starting price is $0.01</p>
                        </div>
                        
                        <div class="form-group">
                            <label>Bid Increment ($) <span>*</span></label>
                            <input type="number" name="bidIncrement" step="0.01" min="0.01" value="1.00" required placeholder="1.00">
                            <p class="help-text">Minimum amount to add per bid</p>
                        </div>
                        
                        <div class="form-group">
                            <label>Reserve Price ($)</label>
                            <input type="number" name="reservePrice" step="0.01" min="0" placeholder="Optional">
                            <p class="help-text">Secret minimum price (optional)</p>
                        </div>
                    </div>
                </div>
                
                <!-- Auction Duration -->
                <div class="form-section">
                    <h3>Auction Duration</h3>
                    
                    <div class="form-row">
                        <div class="form-group">
                            <label>Start Date & Time <span>*</span></label>
                            <input type="datetime-local" name="startDateTime" id="startDateTime" required>
                            <p class="help-text">When should bidding start?</p>
                        </div>
                        
                        <div class="form-group">
                            <label>End Date & Time <span>*</span></label>
                            <input type="datetime-local" name="closeDateTime" id="closeDateTime" required>
                            <p class="help-text">When should bidding end?</p>
                        </div>
                    </div>
                </div>
                
                <div class="form-actions">
                    <button type="submit" class="btn btn-primary">Create Auction</button>
                    <a href="<%= request.getContextPath() %>/dashboard.jsp" class="btn btn-secondary">Cancel</a>
                </div>
            </form>
        </div>
    </div>
    
    <script>
        // Set minimum dates
        var now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
        var minDateTime = now.toISOString().slice(0, 16);
        document.getElementById('startDateTime').min = minDateTime;
        document.getElementById('closeDateTime').min = minDateTime;
        
        // Default start time to now
        document.getElementById('startDateTime').value = minDateTime;
        
        // Default end time to 7 days from now
        var endDate = new Date();
        endDate.setDate(endDate.getDate() + 7);
        endDate.setMinutes(endDate.getMinutes() - endDate.getTimezoneOffset());
        document.getElementById('closeDateTime').value = endDate.toISOString().slice(0, 16);
        
        // Update close min when start changes
        document.getElementById('startDateTime').addEventListener('change', function() {
            document.getElementById('closeDateTime').min = this.value;
        });
        
        // Load subcategories based on category selection
        function loadSubcategories() {
            var categoryID = document.getElementById('categorySelect').value;
            var subcategorySelect = document.getElementById('subcategorySelect');
            
            subcategorySelect.innerHTML = '<option value="">Loading...</option>';
            document.getElementById('dynamicFields').style.display = 'none';
            
            if (!categoryID) {
                subcategorySelect.innerHTML = '<option value="">Select category first</option>';
                return;
            }
            
            // AJAX call to get subcategories
            var xhr = new XMLHttpRequest();
            xhr.open('GET', '<%= request.getContextPath() %>/get-subcategories?categoryID=' + categoryID, true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4 && xhr.status === 200) {
                    var subcategories = JSON.parse(xhr.responseText);
                    subcategorySelect.innerHTML = '<option value="">Select subcategory</option>';
                    
                    subcategories.forEach(function(sub) {
                        var option = document.createElement('option');
                        option.value = sub.categoryID;
                        option.textContent = sub.categoryName;
                        option.setAttribute('data-fields', sub.requiredFields || '[]');
                        subcategorySelect.appendChild(option);
                    });
                }
            };
            xhr.send();
        }
        
        // Load dynamic fields based on subcategory
        document.getElementById('subcategorySelect').addEventListener('change', function() {
            var selectedOption = this.options[this.selectedIndex];
            var fieldsJson = selectedOption.getAttribute('data-fields');
            var dynamicFieldsDiv = document.getElementById('dynamicFields');
            var container = document.getElementById('dynamicFieldsContainer');
            
            container.innerHTML = '';
            
            if (fieldsJson && fieldsJson !== '[]' && fieldsJson !== 'null') {
                try {
                    var fields = JSON.parse(fieldsJson);
                    if (fields.length > 0) {
                        dynamicFieldsDiv.style.display = 'block';
                        
                        fields.forEach(function(field) {
                            var div = document.createElement('div');
                            div.className = 'form-group';
                            div.innerHTML = 
                                '<label>' + field.replace(/_/g, ' ').replace(/\b\w/g, function(l) { return l.toUpperCase(); }) + '</label>' +
                                '<input type="text" name="field_' + field + '" placeholder="Enter ' + field.replace(/_/g, ' ') + '">';
                            container.appendChild(div);
                        });
                    } else {
                        dynamicFieldsDiv.style.display = 'none';
                    }
                } catch (e) {
                    console.error('Error parsing fields:', e);
                    dynamicFieldsDiv.style.display = 'none';
                }
            } else {
                dynamicFieldsDiv.style.display = 'none';
            }
        });
    </script>
</body>
</html>
