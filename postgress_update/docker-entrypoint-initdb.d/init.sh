#!/bin/bash
set -e

# 删除gitea数据库
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "postgres" <<-EOSQL
    DROP DATABASE IF EXISTS ${POSTGRES_DB}
EOSQL
