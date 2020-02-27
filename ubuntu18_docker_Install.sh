# switch mirrors.aliyun
mv /etc/apt/sources.list /etc/apt/sources.list.bak

cat>/etc/apt/sources.list<<EOF
echo deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse /
deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse /
deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse /
deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse /
deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse /
deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse /
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse /
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse /
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse /
deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse /
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
EOF

# 1.Uninstall old versions
apt-get -y remove docker docker-engine docker.io containerd runc

# 2.Update the apt package index:
apt-get update

curl -sSL https://get.daocloud.io/docker | sh
# 安装体验版或测试版，体验最新Docker。
# curl -sSL https://get.daocloud.io/docker-experimental | sh
# curl -sSL https://get.daocloud.io/docker-test | sh


# 安装 Docker Compose
curl -L https://get.daocloud.io/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 启动docker
service docker start

# 配置加速器
curl -sSL https://get.daocloud.io/daotools/set_mirror.sh | sh -s http://f1361db2.m.daocloud.io

service docker restart