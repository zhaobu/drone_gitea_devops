# 本脚本只适用于centos7安装最新版docker-ce,会替换系统镜像源为阿里云镜像
# switch mirrors.aliyun
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
yum clean all
yum  makecache
yum install -y yum-plugin-fastestmirror
# Uninstall old versions
yum remove docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-engine
# Install required packages
yum install -y yum-utils device-mapper-persistent-data lvm2
# set up the stable repository
wget -O /etc/yum.repos.d/docker-ce.repo https://download.docker.com/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.tuna.tsinghua.edu.cn/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Install the latest version of Docker Engine - Community and containerd
yum makecache fast
yum install -y docker-ce docker-ce-cli containerd.io