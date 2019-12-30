# 升级postgress 的docker镜像

1. copy 旧版本镜像中的data目录gitea_postgres_old目录

```shell
docker cp postgres_old:/var/lib/postgresql/data/ ../gitea_postgres_old/data
```

2. 使用`docker-compose up -d --build`启动新版本的postgres容器,然后使用`docker-compose down`关闭

3. 启动postgres_update容器

```shell
docker run --rm \
        -e PGUSER=gitea \
        -e POSTGRES_INITDB_ARGS="-U gitea" \
        -v /home/docker/drone_gitea_devops/gitea_postgres_old/data:/var/lib/postgresql/11/data \
        -v /home/docker/drone_gitea_devops/gitea_postgres/data:/var/lib/postgresql/12/data \
        tianon/postgres-upgrade:11-to-12
```

4. 使用docker-compose.yml文件启动所有drone相关容器
