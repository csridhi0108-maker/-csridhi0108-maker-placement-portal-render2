<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ include file="/WEB-INF/db.jspf" %>
<%@ include file="/WEB-INF/admin-guard.jspf" %>
<%
    int appId = Integer.parseInt(request.getParameter("app_id"));
    int driveId = Integer.parseInt(request.getParameter("drive_id"));
    String status = request.getParameter("status");
    String msg;
    String type;
    if (!"Pending".equals(status) && !"Accepted".equals(status) && !"Rejected".equals(status)) {
        msg = "Invalid offer status.";
        type = "error";
    } else {
        Connection conn = openConn();
        try {
            conn.setAutoCommit(false);
            PreparedStatement ps = conn.prepareStatement("UPDATE Offer SET status = ? WHERE app_id = ?");
            ps.setString(1, status);
            ps.setInt(2, appId);
            int rows = ps.executeUpdate();
            ps.close();
            conn.commit();
            msg = rows == 1 ? "Offer marked " + status + "." : "No offer found for this application.";
            type = rows == 1 ? "success" : "error";
        } catch (SQLException e) {
            conn.rollback();
            msg = "Could not update offer: " + e.getMessage();
            type = "error";
        } finally {
            conn.close();
        }
    }
    response.sendRedirect("drive-detail.jsp?drive_id=" + driveId
        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8") + "&type=" + type);
%>
