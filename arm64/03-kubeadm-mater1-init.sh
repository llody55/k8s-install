#!/bin/bash
###
 # @Author: 745719408@qq.com 745719408@qq.com
 # @Date: 2023-08-30 15:41:53
 # @LastEditors: 745719408@qq.com 745719408@qq.com
 # @LastEditTime: 2023-11-13 10:38:29
 # @FilePath: \K8S\组件包\k8s-部署\shell\k8s\03-kubeadm-install.sh
 # @Description: k8s初始化脚本
### 

# 青色文本
print_separator() {
  echo -e "\033[36m------------------------------------------------------------------------------\033[0m"
}
# 绿色时间戳和青色文本信息
print_info_green() {
  echo -e "\033[32m【`hostname` `date '+%Y-%m-%d %H:%M:%S'`】\033[0m" "\033[36m$1\033[0m"
}
# 青色文本
print_cyan() {
  echo -e "\033[36m$1\033[0m"
}
# 黄色时间戳和红色文本信息
print_info_yellow() {
  echo -e "\033[33m【`hostname` `date '+%Y-%m-%d %H:%M:%S'`】\033[0m" "\033[91m$1\033[0m"
}
# 青色文本
print_separator_line() {
  print_cyan "=============================================================================="
}

# 配色方案
print_color() {
    local color=$1
    local message=$2
    local host=$(hostname)
    local now=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "\033[${color}m${host} ${now}: ${message}\033[0m"
}

action() {
    local message="$1"
    local return_status="$2"

    printf "%-60s [%s]\n" "$message" "$(if [ "${return_status}" == 'true' ]; then echo -e "\033[32mok\033[0m"; else echo -e "\033[31mfailed\033[0m"; fi)"      
}

hosts_init(){
    # 获取主机名和IP地址
    HOSTNAME=$(hostname)
    IP_ADDRESS=$(hostname -I | awk '{print $1}')
    # echo "$IP_ADDRESS $HOSTNAME" >> /etc/hosts
    # echo "$IP_ADDRESS apiserver.cluster.local" >> /etc/hosts
    #echo "192.168.0.244 node1" >> /etc/hosts
    # echo "192.168.111.131 node2" >> /etc/hosts
    # echo "192.168.111.133 node3" >> /etc/hosts
    # 这个vip指向主机必须是master1节点，所有主机都会向此节点注册，所有dns必须添加
    echo "192.168.0.146 apiserver.cluster.local" >> /etc/hosts
    if [ $? -eq 0 ]; then
        action "hosts写入:" true
    else
        action "hosts写入:" false
        print_info_yellow "可能没有权限写入/etc/hosts文件，请检查"
        exit 5
    fi
}


# 系统架构检测
platform(){
    # 检查是否为64位系统，这个脚本只支持64位脚本
    platform=`uname -i`
    if [ $platform = "aarch64" ];then
        platform_type="aarch64"
        action "操作系统检测:" true
    else
        action "系统不是arm64架构，请知悉,无法满足初始化要求,请下载对应版本软件包!!!" false
        exit 1
    fi

    sleep 2
}

# 确定系统类型
get_system_type(){
    if cat /etc/os-release | grep "CentOS Linux 7" >/dev/null
    then
        system_type="centos7"
    elif cat /etc/os-release | grep "openEuler 22.03" >/dev/null
    then
        system_type="openeuler"
    else
        print_color 31 "未经测试或者不支持的系统类型！！！"
        exit 1
    fi 
}

# 检查IPVS是否已经开启
check_ipvs() {
    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules 
    modprobe br_netfilter &>/dev/null
    if (lsmod | grep -q -e ip_vs -e nf_conntrack_ipv4)&>/dev/null; then
        action "ipvs检测:" true
    else
        action "ipvs模块:" false
        exit 5
    fi
}

# 检查内核版本是否大于4.19
check_kernel_version() {
    kernel_version=$(uname -r | cut -d- -f1)
    required_kernel_version="4.19"
    if [[ "$(printf '%s\n' "$required_kernel_version" "$kernel_version" | sort -V | head -n1)" == "$required_kernel_version" ]]; then
        action "内核检测:" true
    else
        action "内核检测:" false
        print_info_yellow "内核检测不通过，请升级到4.19版本以上。"
        exit 5
    fi
}


# 检查containerd服务状态是否正常
check_containerd() {
    systemctl is-active --quiet containerd
    if [ $? -eq 0 ]; then
        action "containerd检测:" true
    else
        action "containerd检测:" false
        print_info_yellow "请安装或者启动containerd"
        exit 5
    fi
}

get_system_info() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        SYSTEM=$ID
        VERSION=$VERSION_ID
        action "系统检测:" true
        echo "当前系统为$SYSTEM，版本为$VERSION"
        
    else
        action "系统检测:" false
        echo "无法识别当前系统"
        exit 1
    fi
}
yum_kubeadm_init(){
    get_system_type
    offline_rpm_path="./repo/$system_type/*.rpm"
    if ! (which kubeadm &>/dev/null);then
        print_info_yellow "kubeadm未安装，开始离线安装"
        yum localinstall -y ./repo/$system_type/*.rpm &>/dev/null
        systemctl enable kubelet.service
        if (which kubeadm &>/dev/null);then
            action "kubeadm安装:" true
            kubectl completion bash > /tmp/outfile
            echo "source /tmp/outfile" >> ~/.bash_profile
            source ~/.bash_profile
        fi
    else
       action "kubeadm检查:" true
    fi
}
# 使用nerdctl导出的镜像最好使用nerdctl进行导入
kubeadm_init(){
    repository="registry.aliyuncs.com/google_containers"
    k8s_version="v1.25.4"
    print_info_yellow "开始导入离线镜像"
    #ctr -n=k8s.io image import images_v1.25.4.tar &>/dev/null
    nerdctl -n k8s.io image load -i images_v1.25.4.tar &>/dev/null
    # kubeadm init --apiserver-advertise-address=${node} --image-repository ${repository} --kubernetes-version ${k8s_version} --service-cidr=10.96.0.0/12 --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=all
    print_info_yellow "kubeadm开始初始化master节点"
    kubeadm init --config kubeadm-config.yaml &>k8s_init.log
    if [[ $? -eq 0 ]];then
        action "K8s初始化:" true
        mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
        sudo chown $(id -u):$(id -g) $HOME/.kube/config
        print_info_yellow "master和worker节点的加入连接如下"
        python3 py_join.py
    else
        action "K8s初始化:" false
        exit 5
    fi
}

run_and_check(){
    hosts_init
    check_ipvs
    check_kernel_version
    check_containerd
    get_system_info
    yum_kubeadm_init
    kubeadm_init
}
log(){
    print_separator_line 
    print_info_yellow "执行脚本的方式示例: sh $0 run"
    print_info_yellow "run  包含：检测系统版本、内核版本、ipvs设置、containerd服务、用kubeadm初始化master1节点"
    print_separator_line
}
if [ $# -ne 1 ]; then 
   log 
else
    case $1 in
        "run")
            run_and_check
            ;;
        "all")
            run_and_check
            ;;
        *)
            log
            ;;
    esac
fi