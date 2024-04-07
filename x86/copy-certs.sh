#!/bin/bash
###
 # @Author: 745719408@qq.com 745719408@qq.com
 # @Date: 2023-09-07 16:59:55
 # @LastEditors: 745719408@qq.com 745719408@qq.com
 # @LastEditTime: 2023-09-22 10:37:26
 # @FilePath: \K8S\组件包\k8s-部署\shell\copy-certs.sh
 # @Description: master节点拷贝证书到新增master上
###

# 多IP写法 
#CONTROL_PLANE_IPS="192.168.111.131 192.168.111.133"

USER=root
CONTROL_PLANE_IPS="192.168.111.130 192.168.111.131 192.168.111.133"
for host in ${CONTROL_PLANE_IPS}; do
    ssh "${USER}"@$host "mkdir -p /etc/kubernetes/pki/etcd"
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/etcd/ca.crt "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.crt
    scp /etc/kubernetes/pki/etcd/ca.key "${USER}"@$host:/etc/kubernetes/pki/etcd/ca.key
    echo "Host $host done"
done
