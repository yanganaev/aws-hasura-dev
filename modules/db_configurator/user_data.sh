#!/bin/bash
exec > >(tee /var/log/db-configurator.log) 2>&1

# Installing PostgreSQL client
yum install -y postgresql

# Creating 5 schemas in PostgreSQL
SCHEMAS=("auth" "public" "storage" "logs" "metadata")

for SCHEMA in "${SCHEMAS[@]}"; do
  psql postgresql://${db_user}:${master_password}@${db_host}/${db_name} -c "CREATE SCHEMA IF NOT EXISTS ${SCHEMA};"
done

# Automatic termination
shutdown -h now