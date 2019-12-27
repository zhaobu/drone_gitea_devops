# gitea+drone+k8s+harbor搭建devops流水线

## DevOps基本介绍

​	**DevOps** 一词的来自于 Development 和 Operations 的组合，突出重视软件开发人员和运维人员的沟通合作，通过自动化流程来使得软件构建、测试、发布更加快捷、频繁和可靠。DevOps 其实包含了三个部分：开发、测试和运维。换句话 DevOps 希望做到的是软件产品交付过程中IT工具链的打通，使得各个团队减少时间损耗，更加高效地协同工作。

​	关于devops的基础概念可以参考[关于DevOps落地方案的个人观点](https://www.yuque.com/docs/share/71737f10-933d-470d-97f8-bd68e775334e?#)了解，一般来说一次版本发布包含如下Checklist：

>- 代码的下载构建及编译
>- 运行单元测试，生成单元测试报告及覆盖率报告等
>- 在测试环境对当前版本进行测试
>- 为待发布的代码打上版本号
>- 编写 ChangeLog 说明当前版本所涉及的修改
>- 构建 Docker 镜像
>- 将 Docker 镜像推送到镜像仓库
>- 在预发布环境测试当前版本
>- 正式发布到生产环境



### 单人开发模式

>- clone 项目到本地， 修改项目代码， 如将 Hello World 改为 Hello World V2。  
>- git add .，然后书写符合约定的 commit 并提交代码， git commit -m "feature: hello world v2”
>-   推送代码到代码库git push，等待数分钟后，开发人员会看到单元测试结果，gitea 仓库会产生一次新版本的 release，release 内容为当前版本的 changeLog， 同时线上已经完成了新功能的发布。

虽然在开发者看来，一次发布简单到只需 3 个指令，但背后经过了如下的若干次交互，这是一次发布实际产生交互的时序图，具体每个环节如何工作将在后面中详细说明。

![](C:%5CUsers%5Clw%5CDesktop%5Cshortcut%5C1628481-20190402204444360-1195432287.png)



### 多人开发模式：

>- Clone 项目到本地，创建一个分支来完成新功能的开发, git checkout -b feature/hello-world-v3。在这个分支修改一些代码，比如将Hello World V2修改为Hello World V3 
>
>- git add .，书写符合规范的 Commit 并提交代码， git commit -m "feature: hello world v3” 
>- 将代码推送到代码库的对应分支， git push origin feature/hello-world 
>- 如果功能已经开发完毕，可以向 Master 分支发起一个 Pull Request，并让项目的负责人 Code Review 
>- Review 通过后，项目负责人将分支合并入主干，Github 仓库会产生一次新版本的 release，同时线上已经完成了新功能的发布。

这个流程相比单人开发来多了 2 个环节，很适用于小团队合作，不仅强制加入了 Code Review 把控代码质量，同时也避免新人的不规范行为对发布带来影响。实际项目中，可以在 Gitea 的设置界面对 master 分支设置写入保护，这样就从根本上杜绝了误操作的可能。当然如果团队中都是熟手，就无需如此谨慎，每个人都可以负责 PR 的合并，从而进一步提升效率。

![](https://img2018.cnblogs.com/blog/1628481/201904/1628481-20190402204701308-1519040720.png)

### GitFlow 开发模式：

在更大的项目中，参与的角色更多，一般会有开发、测试、运维几种角色的划分；还会划分出开发环境、测试环境、预发布环境、生产环境等用于代码的验证和测试；同时还会有多个功能会在同一时间并行开发。可想而知 CI 的流程也会进一步复杂。

能比较好应对这种复杂性的，首选 GitFlow 工作流， 即通过并行两个长期分支的方式规范代码的提交。而如果使用了 Gitea，由于有非常好用的 Pull Request 功能，可以将 GitFlow 进行一定程度的简化，最终有这样的工作流：

![](https://img2018.cnblogs.com/blog/1628481/201904/1628481-20190402204839275-100825880.png)

这个模式主要遵循以下约定

>- 以 dev 为主开发分支，master 为发布分支  
>- 开发人员始终从 dev 创建自己的分支，如 feature-a  
>- feature-a 开发完毕后创建 PR 到 dev 分支，并进行 code review  
>- review 后 feature-a 的新功能被合并入 dev，如有多个并行功能亦然  
>- 待当前开发周期内所有功能都合并入 dev 后，从 dev 创建 PR 到 master  
>- dev 合并入 master，并创建一个新的 release

上述是从 Git 分支角度看代码仓库发生的变化，实际在开发人员视角里，工作流程是怎样的呢。假设我是项目的一名开发人员，今天开始一期新功能的开发：

>1. Clone 项目到本地，git checkout dev。从 dev 创建一个分支来完成新功能的开发, git checkout -b feature/feature-a。在这个分支修改一些代码，比如将Hello World V3修改为Hello World Feature A  
>2. git add .，书写符合规范的 Commit 并提交代码， git commit -m "feature: hello world feature A"  
>3. 将代码推送到代码库的对应分支， git push origin feature/feature-a:feature/feature-a  
>4. 由于分支是以feature/命名的，因此 CI 会运行单元测试，并自动构建一个当前分支的镜像，发布到测试环境，并自动配置一个当前分支的域名如 test-featue-a.avnpc.com  
>5. 联系产品及测试同学在测试环境验证并完善新功能  
>6. 功能通过验收后发起 PR 到 dev 分支，由 Leader 进行 code review  
>7. Code Review 通过后，Leader 合并当前 PR，此时 CI 会运行单元测试，构建镜像，并发布到测试环境  
>8. 此时 dev 分支有可能已经积累了若干个功能，可以访问测试环境对应 dev 分支的域名，如 test.avnpc.com，进行集成测试。  
>9. 集成测试完成后，由运维同学从 Dev 发起一个 PR 到 Master 分支，此时会 CI 会运行单元测试，构建镜像，并发布到预发布环境  
>10. 测试人员在预发布环境下再次验证功能，团队做上线前的其他准备工作  
>11. 运维同学合并 PR，CI 将为本次发布的代码及镜像自动打上版本号并书写 ChangeLog，同时发布到生产环境。
由此就完成了上文中 Checklist 所需的所有工作。虽然描述起来看似冗长，但不难发现实际作为开发人员，并没有任何复杂的操作，流程化的部分全部由 CI 完成，开发人员只需要关注自己的核心任务：按照工作流规范，写好代码，写好 Commit，提交代码即可。

### 总结

>+ 如果搭建了Gerrit服务，可以使用Gerrit作为ReviewCode的中间代码仓库
>
>+ golang静态分析工具有sonarqube和golangci-lint等，运行静态分析可以保证代码没有明显的错误。

## 使用docker-compose实现CI

具体的代码库可以访问[drone_gitea_devops](https://gitee.com/zhaobu/drone_gitea_devops)仓库查看，这部分只实现了持续集成，并未实现持续发布和持续部署。

### 代码管理

#### git基本使用

​	详情访问[赵布的学习笔记-Git的使用](https://www.yuque.com/docs/share/ead50f5b-5d9f-47ad-a37a-d98867d45be8?#)查看

#### gitea部署代码仓库

​	采用如下docker-compose部署:

```yaml
version: "3.7"

networks:
  dronenet:
    name: dronenet
services:
  # 使用nginx做反向代理
  # nginx:
  #   image: nginx:alpine
  #   container_name: drone_nginx
  #   ports:
  #     - "8080:80"
  #   restart: always
  #   networks:
  #     - dronenet
  #   volumes:
  #     - ./nginx/conf:/etc/nginx/conf.d:rw
  #     - ./nginx/nginx.conf:/etc/nginx/nginx.conf
  #     - ./nginx/hosts:/etc/hosts:rw

  # gitea 服务
  gitea_server:
    image: gitea/gitea:latest
    ports:
      - 3000:3000
      # 必须映射22端口,不然只能使用http cloen仓库
      - "3022:22"
    volumes:
      - ./gitea_server/data:/data
      - ./gitea_server/conf/app.ini:/data/gitea/conf/app.ini
    restart: always
    container_name: gitea_server
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - HTTP_PORT=3000
      - DB_TYPE=postgres
      - DB_HOST=gitea_postgres:5432
      - DB_USER=${POSTGRES_USER}
      - DB_NAME=${POSTGRES_DB}
      - DB_PASSWD={POSTGRES_PASSWORD}
      - APP_NAME="DROG (gitea + drone) test"
      # this exposes to end users
      - ROOT_URL=http://${HOST}:3000
    networks:
      dronenet:

  # gitea 可以用postgres也可以用mysql
  gitea_postgres:
    image: postgres:alpine
    # ports:
    #   - 5432:5432
    restart: always
    container_name: gitea_postgres
    volumes:
      - ./gitea_postgres/data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    networks:
      dronenet:
```

#### gitea部署需要注意点:

+ gitea可以使用postgress也可使用mysql,但是mysql在映射volume时如果想映射到当前目录,会出现读写问题,具体的问题,可以试一下就会明白
+ ports端口映射时需要映射两个端口,一个是默认的3000,可以使用http/https协议进行git clone,还有需要映射内部的22端口,才能使用git协议

### 使用Drone实现CI

增加部署drone的部分：

```yaml
version: "3.7"

networks:
  dronenet:
    name: dronenet
# volumes:
#   portainerdata:
#     name: portainerdata

services:
  # 使用nginx做反向代理
  # nginx:
  #   image: nginx:alpine
  #   container_name: drone_nginx
  #   ports:
  #     - "8080:80"
  #   restart: always
  #   networks:
  #     - dronenet
  #   volumes:
  #     - ./nginx/conf:/etc/nginx/conf.d:rw
  #     - ./nginx/nginx.conf:/etc/nginx/nginx.conf
  #     - ./nginx/hosts:/etc/hosts:rw

  # gitea 服务
  gitea_server:
    image: gitea/gitea:latest
    ports:
      - 3000:3000
      # 必须映射22端口,不然只能使用http cloen仓库
      - "3022:22"
    volumes:
      - ./gitea_server/data:/data
      - ./gitea_server/conf/app.ini:/data/gitea/conf/app.ini
    restart: always
    container_name: gitea_server
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - HTTP_PORT=3000
      - DB_TYPE=postgres
      - DB_HOST=gitea_postgres:5432
      - DB_USER=${POSTGRES_USER}
      - DB_NAME=${POSTGRES_DB}
      - DB_PASSWD={POSTGRES_PASSWORD}
      - APP_NAME="DROG (gitea + drone) test"
      # this exposes to end users
      - ROOT_URL=http://${HOST}:3000
    networks:
      dronenet:

  # gitea 可以用postgres也可以用mysql
  gitea_postgres:
    image: postgres:alpine
    # ports:
    #   - 5432:5432
    restart: always
    container_name: gitea_postgres
    volumes:
      - ./gitea_postgres/data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    networks:
      dronenet:

  # drone使用mysql
  drone_mysql:
    image: mysql
    restart: always
    container_name: drone_mysql
    # ports:
    #   - 3306:3306
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
    networks:
      dronenet:
    volumes:
      - ./drone_mysql/conf/my.cnf:/etc/mysql/my.cnf:rw
      - ./drone_mysql/data:/var/lib/mysql/:rw
      - ./drone_mysql/logs:/var/log/mysql/:rw

  # drone 服务端
  drone_server:
    image: drone/drone
    container_name: drone_server
    ports:
      - 8080:80 # drone comtainer serves via port 80, we expose to end users via port 8381
      # - 8443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./drone_server/data:/data:rw
      - ./drone_server/drone:/var/lib/drone:rw
    restart: always
    environment:
      # db Config
      - DRONE_DATABASE_DATASOURCE=${MYSQL_DATABASE}:${MYSQL_PASSWORD}@tcp(drone_mysql:3306)/drone?parseTime=true #mysql配置，要与上边mysql容器中的配置一致
      - DRONE_DATABASE_DRIVER=mysql

      - DRONE_TLS_AUTOCERT=false

      # gitea Config
      # - DRONE_AGENTS_ENABLED=true
      - DRONE_GITEA_SERVER=http://${HOST}:3000 # this is internal communication with gitea server on the same network
      - DRONE_GITEA_CLIENT_ID=${DRONE_GITEA_CLIENT_ID}
      - DRONE_GITEA_CLIENT_SECRET=${DRONE_GITEA_CLIENT_SECRET}
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET} #RPC秘钥
      - DRONE_SERVER_HOST=${HOST}:8080
      - DRONE_SERVER_PROTO=http
      - DRONE_RUNNER_CAPACITY=2
      - DRONE_USER_CREATE=username:zhaobu,admin:true #管理员账号，是你想要作为管理员的Gitea用户名
      # droneclient Config

      # dronelog
      - DRONE_LOGS_PRETTY=true
      - DRONE_LOGS_COLOR=true
      - DRONE_LOGS_TEXT=true
      - DRONE_LOGS_DEBUG=true
      - DRONE_LOGS_TRACE=true
    depends_on:
      - gitea_server
    networks:
      dronenet:

  drone_agent:
    image: drone/agent:latest
    container_name: drone_agent
    restart: always
    depends_on:
      - drone_server
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DRONE_RPC_PROTO=http
      - DRONE_RPC_HOST=drone_server
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET} #RPC秘钥，要与drone_server中的一致
      - DRONE_RUNNER_CAPACITY=3
      - DRONE_LOGS_TRACE=true
      - DRONE_LOGS_DEBUG=true
      - DRONE_UI_USERNAME=root
      - DRONE_UI_PASSWORD=root
    networks:
      dronenet:
```



## 自动化测试



参考了:

- [容器环境下的持续集成最佳实践](https://www.cnblogs.com/jasonzhuo/articles/10645372.html)

+ [嘿,我用Drone做CI](https://juejin.im/post/5df0801c5188251257286699)