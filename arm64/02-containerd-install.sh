# 创建解压目录
###
 # @Author: 745719408@qq.com 745719408@qq.com
 # @Date: 2023-08-31 10:00:13
 # @LastEditors: 745719408@qq.com 745719408@qq.com
 # @LastEditTime: 2023-10-19 09:46:43
 # @FilePath: \K8S\组件包\k8s-部署\shell\02-containerd-install.sh
 # @Description: containerd安装脚本
### 

# 指定版本
OFFLINE_PACKAGE="packages/containerd-1.6.10-linux-arm64.tar.gz"
CNI_PLUGINS="packages/cni-plugins-linux-arm64-v1.1.1.tgz"
CONTAINERD_VERSION="containerd-1.6.10"


# 创建解压目录
INSTALL_DIR="/opt/containerd"
sudo mkdir -p $INSTALL_DIR

# 解压 containerd 离线包
sudo tar -xf $OFFLINE_PACKAGE -C $INSTALL_DIR --strip-components=1

# 将可执行文件复制到/usr/bin目录
(sudo cp $INSTALL_DIR/* /usr/local/bin/ ) &>/dev/null

# 将配置文件复制到/etc/containerd目录
sudo mkdir -p /etc/containerd

# 创建配置文件
sudo touch /etc/containerd/config.toml

# 配置写入指定文件
containerd config default > /etc/containerd/config.toml

# 修改参数
sudo sed -i "s#SystemdCgroup = false#SystemdCgroup = true#g" /etc/containerd/config.toml

# 修改pause镜像地址-sandbox_image = "registry.k8s.io/pause:3.6"
sed -i 's#sandbox_image = "registry.k8s.io/pause:3.6"#sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.8"#g' /etc/containerd/config.toml

# 拷贝配置文件
sudo cp ./conf/containerd.service /etc/systemd/system/containerd.service

# 创建cni目录
mkdir -p /opt/cni/bin

# 解压cni网络插件到指定目录
(tar Cxzvf /opt/cni/bin $CNI_PLUGINS) &>/dev/null

# 给runc组件授权
chmod +x ./bin/runc

# 拷贝到containerd安装目录
cp bin/runc /usr/local/bin/

# 拷贝crictl.yaml文件到指定目录
cp conf/crictl.yaml /etc/crictl.yaml

# 给终端工具授权
chmod +x ./bin/nerdctl
chmod +x ./bin/etcdctl

# 拷贝终端工具到执行目录
cp bin/nerdctl /usr/local/bin/
cp bin/etcdctl /usr/local/bin/


sudo systemctl daemon-reload
sudo systemctl enable containerd
sudo systemctl start containerd

echo "Containerd $CONTAINERD_VERSION 已安装并配置为systemd服务！"
echo "使用如下命令进行测试是否安装成功：nerdctl run -d -p 8080:80 --name nginx nginx:alpine"