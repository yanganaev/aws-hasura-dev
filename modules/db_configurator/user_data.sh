#!/bin/bash
set -xe
exec > >(tee /var/log/db-configurator.log) 2>&1

echo "Starting DB configurator script at $(date)"

# Проверяем обязательные переменные
if [ -z "${db_user}" ] || [ -z "${master_password}" ] || [ -z "${db_host}" ] || [ -z "${db_name}" ]; then
  echo "ERROR: One or more required environment variables are missing!"
  echo "db_user=${db_user}"
  echo "master_password=${master_password:+set}"
  echo "db_host=${db_host}"
  echo "db_name=${db_name}"
  exit 1
fi

echo "Variables are set, installing PostgreSQL client..."

# Установка PostgreSQL клиента
yum install -y postgresql

echo "PostgreSQL client version:"
psql --version

SCHEMAS=("auth" "public" "storage" "logs" "metadata")

for SCHEMA in "${SCHEMAS[@]}"; do
  echo "Creating schema: $SCHEMA"
  psql "postgresql://${db_user}:${master_password}@${db_host}/${db_name}" -c "CREATE SCHEMA IF NOT EXISTS ${SCHEMA};"
  if [ $? -ne 0 ]; then
    echo "Failed to create schema ${SCHEMA}"
  else
    echo "Schema ${SCHEMA} created or already exists"
  fi
done

echo "Schemas created successfully"

# Ждем 10 минут для диагностики (можно подключиться, проверить логи)
echo "Sleeping for 10 minutes before shutdown"
sleep 600

echo "Shutting down instance"
shutdown -h now
