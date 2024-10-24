# Use the official PostgreSQL image as the base
FROM postgres:13

# Copy the initialization SQL script to the directory PostgreSQL will run it from
COPY ./motd_init.sql /docker-entrypoint-initdb.d/

# Expose PostgreSQL's default port
EXPOSE 5432
