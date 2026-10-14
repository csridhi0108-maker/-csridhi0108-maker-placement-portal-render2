<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%
    String studentIdParam = request.getParameter("student_id");
    if (studentIdParam == null || studentIdParam.trim().isEmpty()) {
        response.sendRedirect("login.jsp");
        return;
    }
    int studentId = Integer.parseInt(studentIdParam.trim());

    // ---- DB connection: see WEB-INF/db.jspf ----
    Connection conn = openConn();

    // ---- Load student + academic record ----
    String studentName = null;
    String deptName = null;
    double cgpa = 0;
    int backlogs = 0;

    PreparedStatement psStudent = conn.prepareStatement(
        "SELECT s.name, d.dept_name, ar.cgpa, ar.backlogs " +
        "FROM Student s JOIN Department d ON s.dept_id = d.dept_id " +
        "JOIN Academic_Record ar ON s.student_id = ar.student_id " +
        "WHERE s.student_id = ?");
    psStudent.setInt(1, studentId);
    ResultSet rsStudent = psStudent.executeQuery();
    if (rsStudent.next()) {
        studentName = rsStudent.getString("name");
        deptName = rsStudent.getString("dept_name");
        cgpa = rsStudent.getDouble("cgpa");
        backlogs = rsStudent.getInt("backlogs");
    } else {
        rsStudent.close(); psStudent.close(); conn.close();
        response.sendRedirect("login.jsp?notfound=1");
        return;
    }
    rsStudent.close();
    psStudent.close();

    String q = request.getParameter("q"); if (q == null) q = "";
    String message = request.getParameter("msg");
    String msgType = request.getParameter("type");
%>
<!DOCTYPE html>
<html>
<head>
    <title>Student Dashboard</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <div class="topbar">
        <div class="brand">Placement <span>Portal</span></div>
        <div class="logout-link"><a href="../index.jsp">Log out</a></div>
    </div>

    <div class="container">
        <% if (message != null) { %>
            <div class="alert <%= "success".equals(msgType) ? "success" : "error" %>"><%= message %></div>
        <% } %>

        <div class="card">
            <h2>Welcome, <%= studentName %></h2>
            <div class="stat-grid">
                <div class="stat-box"><div class="num"><%= deptName %></div><div class="label">Department</div></div>
                <div class="stat-box"><div class="num"><%= cgpa %></div><div class="label">CGPA</div></div>
                <div class="stat-box"><div class="num"><%= backlogs %></div><div class="label">Backlogs</div></div>
            </div>
        </div>

        <div class="card">
            <h3>Available Drives</h3>
            <form method="get" action="dashboard.jsp" style="margin-bottom:12px;">
                <input type="hidden" name="student_id" value="<%= studentId %>">
                <input type="text" name="q" value="<%= q.replace("\"", "&quot;") %>" placeholder="Search by company or role" style="width:50%;display:inline-block;">
                <button type="submit" class="small">Search</button>
                <a href="dashboard.jsp?student_id=<%= studentId %>">Clear</a>
            </form>
            <table>
                <tr>
                    <th>Company</th><th>Role</th><th>Drive Date</th>
                    <th>Eligibility</th><th>Your Status</th><th></th>
                </tr>
                <%
                    PreparedStatement psDrives = conn.prepareStatement(
                        "SELECT dr.drive_id, c.name AS company_name, jp.role, dr.drive_date, " +
                        "       ec.min_cgpa, ec.max_backlogs " +
                        "FROM Drive dr " +
                        "JOIN Job_Profile jp ON dr.profile_id = jp.profile_id " +
                        "JOIN Company c ON jp.company_id = c.company_id " +
                        "JOIN Eligibility_Criteria ec ON ec.drive_id = dr.drive_id " +
                        "WHERE UPPER(c.name) LIKE ? OR UPPER(jp.role) LIKE ? ORDER BY dr.drive_date");
                    psDrives.setString(1, "%" + q.trim().toUpperCase() + "%");
                    psDrives.setString(2, "%" + q.trim().toUpperCase() + "%");
                    ResultSet rsDrives = psDrives.executeQuery();
                    while (rsDrives.next()) {
                        int driveId = rsDrives.getInt("drive_id");
                        double minCgpa = rsDrives.getDouble("min_cgpa");
                        int maxBacklogs = rsDrives.getInt("max_backlogs");
                        boolean eligible = (cgpa >= minCgpa && backlogs <= maxBacklogs);

                        // has this student already applied to this drive?
                        PreparedStatement psApp = conn.prepareStatement(
                            "SELECT app_id FROM Application WHERE student_id = ? AND drive_id = ?");
                        psApp.setInt(1, studentId);
                        psApp.setInt(2, driveId);
                        ResultSet rsApp = psApp.executeQuery();
                        boolean applied = rsApp.next();
                        int appId = applied ? rsApp.getInt("app_id") : -1;
                        rsApp.close(); psApp.close();

                        String offerStatus = null;
                        if (applied) {
                            PreparedStatement psOffer = conn.prepareStatement(
                                "SELECT status FROM Offer WHERE app_id = ?");
                            psOffer.setInt(1, appId);
                            ResultSet rsOffer = psOffer.executeQuery();
                            if (rsOffer.next()) offerStatus = rsOffer.getString("status");
                            rsOffer.close(); psOffer.close();
                        }
                %>
                <tr>
                    <td><%= rsDrives.getString("company_name") %></td>
                    <td><%= rsDrives.getString("role") %></td>
                    <td><%= rsDrives.getDate("drive_date") %></td>
                    <td>
                        <% if (eligible) { %>
                            <span class="badge eligible">Eligible</span>
                        <% } else { %>
                            <span class="badge not-eligible">Not Eligible</span>
                        <% } %>
                        <div style="font-size:0.75em;color:var(--text-muted);margin-top:4px;">
                            Needs CGPA &ge; <%= minCgpa %>, backlogs &le; <%= maxBacklogs %>
                        </div>
                    </td>
                    <td>
                        <% if (!applied) { %>
                            —
                        <% } else if (offerStatus != null) { %>
                            <span class="badge accepted">Offer: <%= offerStatus %></span>
                        <% } else { %>
                            <span class="badge applied">Applied</span>
                        <% } %>
                    </td>
                    <td>
                        <% if (!applied && eligible) { %>
                        <form class="inline" action="apply.jsp" method="post">
                            <input type="hidden" name="student_id" value="<%= studentId %>">
                            <input type="hidden" name="drive_id" value="<%= driveId %>">
                            <button type="submit" class="small">Apply</button>
                        </form>
                        <% } else if (applied && offerStatus == null) { %>
                        <form class="inline" action="withdraw.jsp" method="post"
                              onsubmit="return confirm('Withdraw your application?');">
                            <input type="hidden" name="student_id" value="<%= studentId %>">
                            <input type="hidden" name="drive_id" value="<%= driveId %>">
                            <button type="submit" class="small" style="background:#e0574f;">Withdraw</button>
                        </form>
                        <% } %>
                    </td>
                </tr>
                <% } rsDrives.close(); psDrives.close(); %>
            </table>
        </div>

        <div class="card">
            <h3>Your Application Progress</h3>
            <table>
                <tr><th>Company</th><th>Round</th><th>Result</th></tr>
                <%
                    PreparedStatement psProgress = conn.prepareStatement(
                        "SELECT c.name AS company_name, pr.round_type, pr.round_no, res.status " +
                        "FROM Application a " +
                        "JOIN Drive dr ON a.drive_id = dr.drive_id " +
                        "JOIN Job_Profile jp ON dr.profile_id = jp.profile_id " +
                        "JOIN Company c ON jp.company_id = c.company_id " +
                        "JOIN Placement_Round pr ON pr.drive_id = dr.drive_id " +
                        "LEFT JOIN Result res ON res.app_id = a.app_id AND res.round_id = pr.round_id " +
                        "WHERE a.student_id = ? ORDER BY c.name, pr.round_no");
                    psProgress.setInt(1, studentId);
                    ResultSet rsProgress = psProgress.executeQuery();
                    boolean anyProgress = false;
                    while (rsProgress.next()) {
                        anyProgress = true;
                        String status = rsProgress.getString("status");
                %>
                <tr>
                    <td><%= rsProgress.getString("company_name") %></td>
                    <td><%= rsProgress.getString("round_type") %></td>
                    <td>
                        <% if (status == null) { %>
                            <span class="badge pending">Not yet held</span>
                        <% } else if ("Pass".equals(status)) { %>
                            <span class="badge pass">Pass</span>
                        <% } else { %>
                            <span class="badge fail">Fail</span>
                        <% } %>
                    </td>
                </tr>
                <% } rsProgress.close(); psProgress.close();
                   if (!anyProgress) { %>
                <tr><td colspan="3" style="color:var(--text-muted);">No applications yet — apply to a drive above.</td></tr>
                <% } %>
            </table>
        </div>
    </div>
    <% conn.close(); %>
</body>
</html>
