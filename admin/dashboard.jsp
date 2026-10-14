<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%@ include file="/WEB-INF/admin-guard.jspf" %>
<%
    Connection conn = openConn();
    String q = request.getParameter("q"); if (q == null) q = "";
%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <%@ include file="_nav.jspf" %>

    <div class="container">
        <div class="card">
            <h3>Department-wise Placement Stats</h3>
            <table>
                <tr><th>Department</th><th>Offers Made</th></tr>
                <%
                    Statement st1 = conn.createStatement();
                    ResultSet rs1 = st1.executeQuery("SELECT * FROM vw_department_placement_stats");
                    while (rs1.next()) {
                %>
                <tr><td><%= rs1.getString(1) %></td><td><%= rs1.getInt(2) %></td></tr>
                <% } rs1.close(); st1.close(); %>
            </table>
        </div>

        <div class="card">
            <h3>Company-wise Offer Stats</h3>
            <table>
                <tr><th>Company</th><th>Role</th><th>Offers Made</th></tr>
                <%
                    Statement st2 = conn.createStatement();
                    ResultSet rs2 = st2.executeQuery(
                        "SELECT company_name, role, offers_made FROM vw_company_offer_stats");
                    while (rs2.next()) {
                %>
                <tr><td><%= rs2.getString(1) %></td><td><%= rs2.getString(2) %></td><td><%= rs2.getInt(3) %></td></tr>
                <% } rs2.close(); st2.close(); %>
            </table>
        </div>

        <div class="card">
            <h3>Drives</h3>
            <form method="get" action="dashboard.jsp" style="margin-bottom:12px;">
                <input type="text" name="q" value="<%= q.replace("\"", "&quot;") %>" placeholder="Search drives by company or role" style="width:50%;display:inline-block;">
                <button type="submit" class="small">Search</button> <a href="dashboard.jsp">Clear</a>
            </form>
            <table>
                <tr><th>Company</th><th>Role</th><th>Date</th><th>Applications</th><th></th></tr>
                <%
                    PreparedStatement psDrives = conn.prepareStatement(
                        "SELECT dr.drive_id, c.name AS company_name, jp.role, dr.drive_date, " +
                        "   (SELECT COUNT(*) FROM Application a WHERE a.drive_id = dr.drive_id) AS app_count " +
                        "FROM Drive dr " +
                        "JOIN Job_Profile jp ON dr.profile_id = jp.profile_id " +
                        "JOIN Company c ON jp.company_id = c.company_id " +
                        "WHERE UPPER(c.name) LIKE ? OR UPPER(jp.role) LIKE ? ORDER BY dr.drive_date");
                    psDrives.setString(1, "%" + q.trim().toUpperCase() + "%");
                    psDrives.setString(2, "%" + q.trim().toUpperCase() + "%");
                    ResultSet rsDrives = psDrives.executeQuery();
                    while (rsDrives.next()) {
                %>
                <tr>
                    <td><%= rsDrives.getString("company_name") %></td>
                    <td><%= rsDrives.getString("role") %></td>
                    <td><%= rsDrives.getDate("drive_date") %></td>
                    <td><%= rsDrives.getInt("app_count") %></td>
                    <td><a class="btn small" href="drive-detail.jsp?drive_id=<%= rsDrives.getInt("drive_id") %>">Manage</a></td>
                </tr>
                <% } rsDrives.close(); psDrives.close(); conn.close(); %>
            </table>
        </div>
    </div>
</body>
</html>
