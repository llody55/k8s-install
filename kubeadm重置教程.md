## 重置集群

```
kubeadm reset -f
```

## 删除所有镜像

```
nerdctl -n k8s.io rmi -f $(nerdctl -n k8s.io image ls -q)
```

删除 `/etc/kubernetes` 文件夹

```
sudo rm -rf /etc/kubernetes
```

删除 `/var/lib/kubelet` 文件夹

```
sudo rm -rf /var/lib/kubelet
```

删除 `/var/lib/etcd` 文件夹

```
sudo rm -rf /var/lib/etcd
```

删除cni网络相关的配置和二进制文件

```
sudo rm -rf /etc/cni
```

清空iptables规则：

```
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X
```

重启服务器
