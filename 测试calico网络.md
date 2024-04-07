```
[root@pengfei-master1 ~]# kubectl run busybox --image docker.io/library/busybox:1.28  --image-pull-policy=IfNotPresent --restart=Never --rm -it busybox -- sh
If you don't see a command prompt, try pressing enter.
/ #  ping www.baidu.com  #ping baidu.com是否正常
PING www.baidu.com (36.152.44.96): 56 data bytes
64 bytes from 36.152.44.96: seq=0 ttl=127 time=18.008 ms
64 bytes from 36.152.44.96: seq=1 ttl=127 time=13.028 ms
#可以看到能访问网络，说明calico网络插件已经被正常安装了

/ # nslookup kubernetes.default.svc.cluster.local
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default.svc.cluster.local
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local

#10.96.0.10 就是我们coreDNS的clusterIP，说明coreDNS配置好了。
#解析内部Service的名称，是通过coreDNS去解析的。

#注意：
#busybox要用指定的1.28版本，不能用最新版本，最新版本，nslookup会解析不到dns和ip
```
