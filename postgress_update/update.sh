#!/bin/bash

docker-compose up -d --build
docker-compose down
docker run --rm \
    -e PGUSER=gitea \
    -e POSTGRES_INITDB_ARGS="-U gitea" \
    -v /home/docker/drone_gitea_devops/gitea_postgres_old/data:/var/lib/postgresql/11/data \
    -v /home/docker/drone_gitea_devops/gitea_postgres/data:/var/lib/postgresql/12/data \
    tianon/postgres-upgrade:11-to-12
