# 升级postgress 的docker镜像

1. 先运行一个旧版本的postgress

``` shell
docker run --name postgres_old -d postgres:11.6-alpine
```

2. copy 旧版本镜像中的库

```shell
docker cp postgres_old:/usr/local/bin/ ../gitea_postgres_old/bin
docker cp postgres_old:/usr/local/share/postgresql/ ../gitea_postgres_old/share
```

3. 启动新版本的postgres容器

```shell
docker-compose up -d --build
```

4. 附加进入新版本postgres容器

```shell
docker exec -it postgres_update /bin/sh -c "[ -e /bin/bash ] && /bin/bash || /bin/sh"
```

6. 使用pg_upgrade进行升级
   1. 使用 `su - postgres` 把用户切换成 postgres
   2. 先使用`pg_ctl -D /var/lib/postgresql/data stop`关闭 PostgreSQL 的 postmaster 服务，不然会报以下错误:

    ```shell
    There seems to be a postmaster servicing the new cluster.
    Please shutdown that postmaster and try again.
    Failure, exiting
    ```

   3. 升级

```shell
# pg_upgrade -b /usr/local/binold -B /usr/local/bin -d /var/lib/postgresql/dataold -D /var/lib/postgresql/data -o ../gitea_postgres_old/data/postgresql.conf -O ../gitea_postgres/data/postgresql.conf
docker run --rm \
        -e PGUSER=gitea \
        -e POSTGRES_INITDB_ARGS="-U gitea" \
        -v /home/docker/drone_gitea_devops/gitea_postgres_old/data:/var/lib/postgresql/11/data \
        -v /home/docker/drone_gitea_devops/gitea_postgres/data:/var/lib/postgresql/12/data \
        tianon/postgres-upgrade:11-to-12
```
