<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%
    int studentId = Integer.parseInt(request.getParameter("student_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));
    String msg;
    String type;
    Connection conn = openConn();
    try {
        conn.setAutoCommit(false);
        // A student may withdraw only before any round result has been recorded.
        PreparedStatement chk = conn.prepareStatement(
            "SELECT COUNT(*) FROM Result r JOIN Application a ON r.app_id = a.app_id " +
            "WHERE a.student_id = ? AND a.drive_id = ?");
        chk.setInt(1, studentId);
        chk.setInt(2, driveId);
        ResultSet rs = chk.executeQuery();
        rs.next();
        int results = rs.getInt(1);
        rs.close(); chk.close();

        if (results > 0) {
            conn.rollback();
            msg = "You cannot withdraw: round results are already recorded. Contact the placement cell.";
            type = "error";
        } else {
            PreparedStatement del = conn.prepareStatement(
                "DELETE FROM Application WHERE student_id = ? AND drive_id = ? " +
                "AND app_id NOT IN (SELECT app_id FROM Offer)");
            del.setInt(1, studentId);
            del.setInt(2, driveId);
            int rows = del.executeUpdate();
            del.close();
            conn.commit();
            msg = rows == 1 ? "Application withdrawn." : "Nothing to withdraw (an offer may already exist).";
            type = rows == 1 ? "success" : "error";
        }
    } catch (SQLException e) {
        conn.rollback();
        msg = "Could not withdraw: " + e.getMessage();
        type = "error";
    } finally {
        conn.close();
    }
    response.sendRedirect("dashboard.jsp?student_id=" + studentId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
