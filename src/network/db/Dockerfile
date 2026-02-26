FROM mysql:8.0

ENV MYSQL_ROOT_PASSWORD=rootpass
ENV MYSQL_USER=user
ENV MYSQL_PASSWORD=pass
ENV MYSQL_DATABASE=hw_shop

COPY init.sql /docker-entrypoint-initdb.d/init.sql

# Run the MySQL init process to pre-populate the database,
# then stop the server so the image is ready to start quickly.
RUN docker-entrypoint.sh mysqld & \
    SERVER_PID=$! && \
    until mysqladmin ping -h 127.0.0.1 -u root -prootpass --silent 2>/dev/null; do sleep 1; done && \
    mysqladmin shutdown -u root -prootpass && \
    wait $SERVER_PID
