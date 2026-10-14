<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%@ include file="/WEB-INF/admin-guard.jspf" %>
<%!
    // Prints any query result as an HTML table, using the column names from the result set.
    void printTable(JspWriter out, Connection conn, String title, String sql) throws Exception {
        out.println("<div class=\"card\"><h3>" + title + "</h3><table>");
        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery(sql);
        ResultSetMetaData md = rs.getMetaData();
        int n = md.getColumnCount();
        out.print("<tr>");
        for (int i = 1; i <= n; i++) out.print("<th>" + md.getColumnLabel(i).replace('_', ' ') + "</th>");
        out.println("</tr>");
        boolean any = false;
        while (rs.next()) {
            any = true;
            out.print("<tr>");
            for (int i = 1; i <= n; i++) out.print("<td>" + rs.getString(i) + "</td>");
            out.println("</tr>");
        }
        if (!any) out.println("<tr><td colspan=\"" + n + "\">No data.</td></tr>");
        rs.close(); st.close();
        out.println("</table></div>");
    }
%>
<%
    Connection conn = openConn();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Reports</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <%@ include file="_nav.jspf" %>
    <div class="container">
        <% 
            printTable(out, conn, "Report 1: Department-wise placement statistics (view vw_department_placement_stats)",
                "SELECT * FROM vw_department_placement_stats");
            printTable(out, conn, "Report 2: Company-wise offer statistics (view vw_company_offer_stats)",
                "SELECT * FROM vw_company_offer_stats");
            printTable(out, conn, "Report 3: Offers issued",
                "SELECT s.name AS student, c.name AS company, jp.role, jp.package_lpa AS package_lpa, o.status " +
                "FROM Offer o JOIN Application a ON o.app_id = a.app_id " +
                "JOIN Student s ON a.student_id = s.student_id " +
                "JOIN Drive dr ON a.drive_id = dr.drive_id " +
                "JOIN Job_Profile jp ON dr.profile_id = jp.profile_id " +
                "JOIN Company c ON jp.company_id = c.company_id ORDER BY s.name");
            printTable(out, conn, "Report 4: Students with above-average CGPA",
                "SELECT s.name AS student, ar.cgpa FROM Student s JOIN Academic_Record ar ON s.student_id = ar.student_id " +
                "WHERE ar.cgpa > (SELECT AVG(cgpa) FROM Academic_Record) ORDER BY ar.cgpa DESC");
            conn.close();
        %>
    </div>
</body>
</html>
