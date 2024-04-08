# k8s-install

部署K8S集群的方法仓库

## 安装方法及目录结构参考

### ARM环境参考(目前测试了麒麟V10)

[openeuler离线部署K8S集群（v1.25.4）_man is needed by libtiff-help-4.3.0-32.oe2203sp2.n-CSDN博客](https://blog.csdn.net/u012429202/article/details/133033359)

### X86环境参考

[kubeadm一键部署k8s1.25.4高可用集群--更新（2023-09-15）_kubeadm高可用集群最新-CSDN博客](https://blog.csdn.net/u012429202/article/details/132878726)

### 基础目录结构

```
[root@node1 ~]# tree .
.
├── 01-rhel_init.sh   # 初始化脚本，主要用于检查主机是否满足部署K8S的基础条件，并做一些基础初始化。
├── 02-containerd-install.sh  # 安装容器运行时，默认使用containerd
├── 03-kubeadm-mater1-init.sh # 用于安装kubeadm等服务，并初始化master1节点，创建出token，用于其他节点注册。
├── 04-kubeadm-mater-install.sh # 用于其他节点安装kubeadm等服务，并向master1进行注册。需要修改hosts_init方法中的集群hosts解析，并用master1的token进行注册。
├── copy-certs.sh # 在多master节点的环境中，需要先使用copy-certs.sh将需要用到的证书都分发到master中后再使用token进行集群注册。
├── bin                       # 主要是一些需要用到的工具
│   ├── etcdctl
│   ├── nerdctl
│   └── runc注册时
├── conf                      # 包含需要用到的部分配置文件
│   ├── containerd.service
│   ├── docker.service
│   ├── k8s.conf
│   └── sysctl.conf
├── images_v1.25.4.tar        # K8S用到的一些离线镜像包
├── k8s_init.log              # 安装过程中产生的日志文件
├── kubeadm-config.yaml       # kubeadm初始化需要用到的配置文件，需要修改advertiseAddress中的IP和certSANs下的IP，都为master1节点IP，多master就把所有master的IP都添加进去。
├── packages                  # 运行时的离线软件包
├── py_join.py                # 获取日志中初始化成功后输出的join token
├── rely                      # 存放工具软件离线软件包，主要为yum的
│   ├── centos7
│   └── openeuler
└── repo                      # 存放K8S主要工件的离线软件包，如：kubeadm,kubectl,kubelet等。
    ├── centos7
    └── openeuler
```

> 本仓库主要用于存放部署脚本，后续会继续进行优化，主要方向为arm架构和离线部署相关，欢迎志同道合的朋友一起努力。
>
> 离线包会以版本的方式存放在云盘中。
>
> 脚本并不完善，可自定义进行修改，也可提交更好的方法进行安装，或者提交PR共同努力。

### 离线部署包

> https://web.ugreen.cloud/web/#/share/460e4b6dc9844d5d8bb66dac0061bf68 提取码：WT36
