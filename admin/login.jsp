<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String error = request.getParameter("error");
    if ("1".equals(request.getParameter("check"))) {
        String u = request.getParameter("username");
        String p = request.getParameter("password");
        // NOTE: hardcoded for simplicity in this coursework project.
        // A production system would store admin credentials in a table
        // with a hashed password, not plain text in code.
        String adminPass = System.getenv("ADMIN_PASSWORD") != null ? System.getenv("ADMIN_PASSWORD") : "admin123";
        if ("admin".equals(u) && adminPass.equals(p)) {
            session.setAttribute("admin", Boolean.TRUE);
            response.sendRedirect("dashboard.jsp");
            return;
        } else {
            response.sendRedirect("login.jsp?error=1");
            return;
        }
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Login</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="login-box">
        <h2>🛠️ Placement Cell Login</h2>
        <% if ("1".equals(error)) { %>
            <div class="alert error">Invalid username or password.</div>
        <% } %>
        <form action="login.jsp" method="post">
            <input type="hidden" name="check" value="1">
            <label>Username</label>
            <input type="text" name="username" placeholder="admin" required>
            <label>Password</label>
            <input type="password" name="password" placeholder="••••••••" required>
            <button type="submit" style="width:100%">Login</button>
        </form>
        <% if (System.getenv("ADMIN_PASSWORD") == null) { %>
        <p style="text-align:center;margin-top:16px;color:var(--text-muted);font-size:0.8em;">
            Default: admin / admin123
        </p>
        <% } %>
        <p style="text-align:center;"><a href="../index.jsp">&larr; Back</a></p>
    </div>
</body>
</html>
