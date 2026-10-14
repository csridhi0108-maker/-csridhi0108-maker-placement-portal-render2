<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%@ include file="/WEB-INF/admin-guard.jspf" %>
<%
    int driveId = Integer.parseInt(request.getParameter("drive_id"));
    String message = request.getParameter("msg");
    String msgType = request.getParameter("type");

    Connection conn = openConn();

    PreparedStatement psHeader = conn.prepareStatement(
        "SELECT c.name AS company_name, jp.role FROM Drive dr " +
        "JOIN Job_Profile jp ON dr.profile_id = jp.profile_id " +
        "JOIN Company c ON jp.company_id = c.company_id WHERE dr.drive_id = ?");
    psHeader.setInt(1, driveId);
    ResultSet rsHeader = psHeader.executeQuery();
    rsHeader.next();
    String companyName = rsHeader.getString("company_name");
    String role = rsHeader.getString("role");
    rsHeader.close(); psHeader.close();
%>
<!DOCTYPE html>
<html>
<head>
    <title>Manage Drive</title>
    <link rel="stylesheet" href="../css/style.css">
</head>
<body>
    <%@ include file="_nav.jspf" %>

    <div class="container">
        <% if (message != null) { %>
            <div class="alert <%= "success".equals(msgType) ? "success" : "error" %>"><%= message %></div>
        <% } %>

        <div class="card">
            <h2><%= companyName %> — <%= role %></h2>

            <table>
                <tr>
                    <th>Student</th><th>Rounds</th><th>Enter Result</th><th>Offer</th><th>Delete</th>
                </tr>
                <%
                    PreparedStatement psApps = conn.prepareStatement(
                        "SELECT a.app_id, s.student_id, s.name FROM Application a " +
                        "JOIN Student s ON a.student_id = s.student_id " +
                        "WHERE a.drive_id = ? ORDER BY s.name");
                    psApps.setInt(1, driveId);
                    ResultSet rsApps = psApps.executeQuery();
                    while (rsApps.next()) {
                        int appId = rsApps.getInt("app_id");
                %>
                <tr>
                    <td><%= rsApps.getString("name") %> (ID <%= rsApps.getInt("student_id") %>)</td>
                    <td>
                        <%
                            PreparedStatement psRounds = conn.prepareStatement(
                                "SELECT pr.round_no, pr.round_type, res.status FROM Placement_Round pr " +
                                "LEFT JOIN Result res ON res.round_id = pr.round_id AND res.app_id = ? " +
                                "WHERE pr.drive_id = ? ORDER BY pr.round_no");
                            psRounds.setInt(1, appId);
                            psRounds.setInt(2, driveId);
                            ResultSet rsRounds = psRounds.executeQuery();
                            while (rsRounds.next()) {
                                String status = rsRounds.getString("status");
                                String badgeClass = status == null ? "pending" : status.equals("Pass") ? "pass" : "fail";
                                String label = status == null ? "Pending" : status;
                        %>
                            <span class="badge <%= badgeClass %>"><%= rsRounds.getString("round_type") %>: <%= label %></span>
                        <% } rsRounds.close(); psRounds.close(); %>
                    </td>
                    <td>
                        <form class="inline" action="enter-result.jsp" method="post">
                            <input type="hidden" name="app_id" value="<%= appId %>">
                            <input type="hidden" name="drive_id" value="<%= driveId %>">
                            <select name="round_id" style="width:auto;display:inline-block;margin-right:4px;">
                                <%
                                    PreparedStatement psRoundOpts = conn.prepareStatement(
                                        "SELECT round_id, round_type FROM Placement_Round WHERE drive_id = ? ORDER BY round_no");
                                    psRoundOpts.setInt(1, driveId);
                                    ResultSet rsRoundOpts = psRoundOpts.executeQuery();
                                    while (rsRoundOpts.next()) {
                                %>
                                <option value="<%= rsRoundOpts.getInt("round_id") %>"><%= rsRoundOpts.getString("round_type") %></option>
                                <% } rsRoundOpts.close(); psRoundOpts.close(); %>
                            </select>
                            <select name="status" style="width:auto;display:inline-block;margin-right:4px;">
                                <option value="Pass">Pass</option>
                                <option value="Fail">Fail</option>
                            </select>
                            <button type="submit" class="small">Save</button>
                        </form>
                    </td>
                    <td>
                        <%
                            PreparedStatement psOffer = conn.prepareStatement("SELECT status FROM Offer WHERE app_id = ?");
                            psOffer.setInt(1, appId);
                            ResultSet rsOffer = psOffer.executeQuery();
                            if (rsOffer.next()) {
                        %>
                            <% String os = rsOffer.getString("status"); %>
                            <form class="inline" action="update-offer.jsp" method="post">
                                <input type="hidden" name="app_id" value="<%= appId %>">
                                <input type="hidden" name="drive_id" value="<%= driveId %>">
                                <select name="status" style="width:auto;display:inline-block;margin-right:4px;">
                                    <option <%= "Pending".equals(os) ? "selected" : "" %>>Pending</option>
                                    <option <%= "Accepted".equals(os) ? "selected" : "" %>>Accepted</option>
                                    <option <%= "Rejected".equals(os) ? "selected" : "" %>>Rejected</option>
                                </select>
                                <button type="submit" class="small">Update</button>
                            </form>
                        <% } else { %>
                            <form class="inline" action="issue-offer.jsp" method="post">
                                <input type="hidden" name="app_id" value="<%= appId %>">
                                <input type="hidden" name="drive_id" value="<%= driveId %>">
                                <button type="submit" class="small">Issue Offer</button>
                            </form>
                        <% } rsOffer.close(); psOffer.close(); %>
                    </td>
                    <td>
                        <form class="inline" action="delete-application.jsp" method="post"
                              onsubmit="return confirm('Delete this application with its results and offer?');">
                            <input type="hidden" name="app_id" value="<%= appId %>">
                            <input type="hidden" name="drive_id" value="<%= driveId %>">
                            <button type="submit" class="small" style="background:#e0574f;">Delete</button>
                        </form>
                    </td>
                </tr>
                <% } rsApps.close(); psApps.close(); conn.close(); %>
            </table>
        </div>
    </div>
</body>
</html>
