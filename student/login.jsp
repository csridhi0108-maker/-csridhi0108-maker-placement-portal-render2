<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <title>Student Login</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="login-box">
        <h2>🎓 Student Login</h2>
        <% if ("1".equals(request.getParameter("notfound"))) { %>
            <div class="alert error">No student found with that ID. Try again.</div>
        <% } %>
        <form action="dashboard.jsp" method="get">
            <label>Student ID</label>
            <input type="number" name="student_id" placeholder="e.g. 101" required>
            <button type="submit" style="width:100%">Login</button>
        </form>
        <p style="text-align:center;margin-top:16px;"><a href="../index.jsp">&larr; Back</a></p>
    </div>
</body>
</html>
