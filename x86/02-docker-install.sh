#!/bin/bash
###
 # @Author: 745719408@qq.com 745719408@qq.com
 # @Date: 2023-08-30 16:47:11
 # @LastEditors: 745719408@qq.com 745719408@qq.com
 # @LastEditTime: 2023-11-23 16:58:09
 # @FilePath: \K8S\组件包\k8s-部署\shell\02-docker-install.sh
 # @Description: docker离线安装脚本
### 

# 定义离线包路径和Docker版本
OFFLINE_PACKAGE="packages/docker-20.10.21.tgz"
DOCKER_VERSION="20.10.21"

# 创建安装目录
INSTALL_DIR="/opt/"
# sudo mkdir -p $INSTALL_DIR

# 解压离线包
sudo tar -xzvf $OFFLINE_PACKAGE -C $INSTALL_DIR --strip-components=1

# 将可执行文件复制到/usr/bin目录
sudo cp $INSTALL_DIR/* /usr/bin/

# 创建用户组
groupadd docker

# 创建containerd运行时server
cat >/usr/lib/systemd/system/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target local-fs.target


[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/bin/containerd
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=1048576
TasksMax=infinity
OOMScoreAdjust=-999


[Install]
WantedBy=multi-user.target
EOF

# 拷贝Docker systemd服务单元文件
cp ./conf/docker.service /usr/lib/systemd/system/docker.service
cp ./conf/docker.socket /usr/lib/systemd/system/docker.socket

# 授权docker组
# chown root:docker /var/run/docker.sock


# 启动Docker并设置开机启动
sudo systemctl daemon-reload
sudo systemctl start containerd.service
sudo systemctl enable containerd.service 
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker $DOCKER_VERSION 已安装并配置为systemd服务！"
