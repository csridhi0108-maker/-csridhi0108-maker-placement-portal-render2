<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%@ include file="/WEB-INF/admin-guard.jspf" %>
<%
    String q = request.getParameter("q");
    if (q == null) q = "";
    String message = request.getParameter("msg");
    String msgType = request.getParameter("type");

    Connection conn = openConn();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Students</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <%@ include file="_nav.jspf" %>
    <div class="container">
        <% if (message != null) { %>
            <div class="alert <%= "success".equals(msgType) ? "success" : "error" %>"><%= message %></div>
        <% } %>
        <div class="card">
            <h2>Students &mdash; Search &amp; Update</h2>
            <form method="get" action="students.jsp" style="margin-bottom:14px;">
                <input type="text" name="q" value="<%= q.replace("\"", "&quot;") %>"
                       placeholder="Search by name, email or department" style="width:60%;display:inline-block;">
                <button type="submit" class="small">Search</button>
                <a href="students.jsp">Clear</a>
            </form>
            <table>
                <tr><th>ID</th><th>Name</th><th>Department</th><th>Email</th><th>Update CGPA / Backlogs</th></tr>
                <%
                    PreparedStatement ps = conn.prepareStatement(
                        "SELECT s.student_id, s.name, s.email, d.dept_name, ar.cgpa, ar.backlogs " +
                        "FROM Student s JOIN Department d ON s.dept_id = d.dept_id " +
                        "JOIN Academic_Record ar ON ar.student_id = s.student_id " +
                        "WHERE UPPER(s.name) LIKE ? OR UPPER(s.email) LIKE ? OR UPPER(d.dept_name) LIKE ? " +
                        "ORDER BY s.student_id");
                    String like = "%" + q.trim().toUpperCase() + "%";
                    ps.setString(1, like); ps.setString(2, like); ps.setString(3, like);
                    ResultSet rs = ps.executeQuery();
                    boolean any = false;
                    while (rs.next()) {
                        any = true;
                %>
                <tr>
                    <td><%= rs.getInt("student_id") %></td>
                    <td><%= rs.getString("name") %></td>
                    <td><%= rs.getString("dept_name") %></td>
                    <td><%= rs.getString("email") %></td>
                    <td>
                        <form class="inline" action="update-student.jsp" method="post">
                            <input type="hidden" name="student_id" value="<%= rs.getInt("student_id") %>">
                            <input type="hidden" name="q" value="<%= q.replace("\"", "&quot;") %>">
                            CGPA <input type="number" step="0.01" min="0" max="10" name="cgpa" value="<%= rs.getBigDecimal("cgpa") %>" style="width:80px;display:inline-block;">
                            Backlogs <input type="number" min="0" name="backlogs" value="<%= rs.getInt("backlogs") %>" style="width:70px;display:inline-block;">
                            <button type="submit" class="small">Update</button>
                        </form>
                    </td>
                </tr>
                <% } rs.close(); ps.close(); conn.close();
                   if (!any) { %>
                <tr><td colspan="5" style="color:var(--text-muted);">No students match your search.</td></tr>
                <% } %>
            </table>
        </div>
    </div>
</body>
</html>
