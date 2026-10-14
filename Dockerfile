FROM tomcat:9.0-jdk17-temurin

# Fresh ROOT app = our portal
RUN rm -rf /usr/local/tomcat/webapps/*
COPY . /usr/local/tomcat/webapps/ROOT/

# PostgreSQL JDBC driver (downloaded at build time from Maven Central)
ADD https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.3/postgresql-42.7.3.jar /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/postgresql-42.7.3.jar
RUN chmod 644 /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/postgresql-42.7.3.jar

# Render gives the port in $PORT (default 10000)
CMD ["sh", "-c", "sed -i \"s/port=\\\"8080\\\"/port=\\\"${PORT:-10000}\\\"/\" /usr/local/tomcat/conf/server.xml && exec catalina.sh run"]
