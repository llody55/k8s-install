#!/bin/bash
###
 # @Author: 745719408@qq.com 745719408@qq.com
 # @Date: 2023-09-13 09:13:58
 # @LastEditors: 745719408@qq.com 745719408@qq.com
 # @LastEditTime: 2023-10-19 10:38:19
 # @FilePath: \K8S\组件包\k8s-部署\shell\k8s\01-rhel_init.sh
 # @Description: 这是一个centos7，系统初始化脚本
### 

# 为action方法提供支持
# . /etc/init.d/functions

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


# 用户检测
system_init(){
    # 检查是否为root用户，脚本必须在root权限下运行
    if [[ "$(whoami)" != "root" ]]; then
        action "请以超级用户身份运行此脚本,当前用户 $(whoami)" false
        exit 1
    else
        action "执行用户检测:" true
    fi
}

# 系统架构检测
platform(){
    # 检查是否为64位系统，这个脚本只支持64位脚本
    platform=`uname -i`
    if [ $platform != "x86_64" ];then
        action "系统不是64位,无法满足初始化要求!!!"
        exit 1
    else
        action "操作系统检测:" true
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

# 网络检测
networkCheck(){
    ping -c 1 www.baidu.com > /dev/null 2>&1

    if [ $? -eq 0 ];then
        action "外网权限检查:" true
    else
        action "外网权限检查:" false
        # echo "此脚本需要访问外网权限才可成功执行,退出脚本"
        # exit 5
    fi
}
# CPU资源检测
cpuCheck(){
    cpuCores=$(grep -c ^processor /proc/cpuinfo)
    if [[ ${cpuCores} -lt 2 ]];then
        action "CPU配置检查:" false
        echo -e "\033[32m# 当前主机CPU ${cpuCores}核 < 2核,不满足安装K8s最低需求,请检查配置\033[0m"
        exit 5
    else
        action "CPU配置检查:" true
    fi
}
# 内存资源检测
menoryCheck(){
    menorySize=$(free -m|grep -i mem|awk '{print $2}')

    if [[ ${menorySize} -lt 1800 ]];then
            action "内存配置检查:" false
            echo -e "\033[32m# 当前主机内存 ${menorySize}M < 1800M(2G),不满足安装K8s最低需求,请检查配置\033[0m"
        exit 5
    else
            action "内存配置检查:" true
    fi
}

# 关闭防火墙和selinux
stopFirewall(){
    systemctl disable firewalld --now &>/dev/null
    setenforce 0 &>/dev/null
    sed  -i.$(date +%F) -r 's/SELINUX=[ep].*/SELINUX=disabled/g' /etc/selinux/config

    if (grep SELINUX=disabled /etc/selinux/config) &>/dev/null;then
        action "关闭防火墙 :" true
    else
        action "关闭防火墙 :" false
    fi
}

# 关闭缓存交换分区
swapOff(){
    swapoff --all
    sed -i -r '/swap/ s/^/#/' /etc/fstab

    if [[ $(free | grep -i swap | awk '{print $2}') -eq 0 ]]; then
        action "关闭交换分区:" true
    else
        action "关闭交换分区:" false
    fi
}

# 安装必要软件包
set_install_soft (){
    get_system_type
    print_color 32 "将安装的运维命令: 【gcc、bash-completion、vim、screen、lrzsz、tree、psmisc、zip、unzip、bzip2、gdisk、telnet、net-tools、sysstat、iftop、lsof、iotop、htop、dstat】"
    echo "请选择软件包安装方式："
    echo "1. 联网在线下载并安装"
    echo "2. 离线下载安装"
    echo "3. 跳过安装操作"
    read -p "请输入你的选择(1/2/3):" install_choice

    # 执行 ping 命令，检查是否可以访问互联网
    ping -c 1 www.baidu.com > /dev/null 2>&1
    internet_conn=$?

    if [ $install_choice = 1 ]
    then
        print_color 32 "安装失败请忽略！！！"
        # 如果网络不通，报错并退出
        if [ $internet_conn -ne 0 ]; then
            print_color 31 "无法访问互联网，请确认你的网络连接正常或选择其他安装方式。"
            exit 1
        else
            print_color 32 "联网在线下载并安装软件包,时间可能比较长，请耐心等待。。。"
            yum install -y makecache &>/dev/null
            yum update -y  &>/dev/null
            yum install -y epel-release &>/dev/null
            yum install -y gcc bash-completion vim screen lrzsz tree psmisc zip unzip bzip2 gdisk telnet net-tools sysstat iftop lsof iotop htop dstat &>/dev/null
        fi
    elif [ $install_choice = 2 ]
    then
        print_color 32 "离线更新软件包: 【gcc、bash-completion、vim、screen、lrzsz、tree、psmisc、zip、unzip、bzip2、gdisk、telnet、net-tools、sysstat、iftop、lsof、iotop、htop、dstat】"
        print_color 32 $system_type
        if (! yum -y localinstall ./rely/$system_type/*.rpm &>/dev/null);then  
            action "软件包安装: " false
        else
            action "软件包安装: " true
        fi
    elif [ $install_choice = 3 ]
    then
      print_color 32 "跳过软件包安装操作。。。"
    else
        print_color 31 "您的选择不在范围内，请重新执行脚本并选择！"
	exit 1
    fi 
    
}

# 设置时间同步
time_aliyun(){
    if ! (which ntpdate &>/dev/null);then
        echo -e "\033[32m# ntpdate未安装,开始进行安装....\033[0m"
        yum -y install ntpdate &>/dev/null
        if (which ntpdate &>/dev/null);then
            action "ntpdate安装:" true
        else
            action "ntpdate安装:" true
        fi
    fi

    if (ntpdate ntp1.aliyun.com &>/dev/null);then
        if ! (egrep "ntpdate +ntp1.aliyun.com" /var/spool/cron/root &>/dev/null);then
            echo "0 1 * * * ntpdate ntp1.aliyun.com" >> /var/spool/cron/root
        fi
            action "时间同步检测:" true
    else
        action "时间同步检测:" false
        fi
}

# 内核优化
sysctl_config(){
  if [ ! -f "/etc/sysctl.conf.bak" ]; then
    cp /etc/sysctl.conf /etc/sysctl.conf.bak
    cp ./conf/sysctl.conf /etc/sysctl.conf
    cp ./conf/k8s.conf /etc/k8s.conf
    
    /sbin/sysctl -p &>/dev/null
    sysctl --system &>/dev/null
    
  fi
  if [[ $(sysctl net.ipv4.tcp_syncookies) = *"= 1"* ]]; then
      action "添加内核参数:" true
  else
      action "添加内核参数:" false
  fi

}

# ipvs优化
ipvsAll(){
    cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
 /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
 if [ $? -eq 0 ]; then
 /sbin/modprobe \${kernel_module}
 fi
done
EOF
    chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules 
    modprobe br_netfilter &>/dev/null
    if (lsmod | grep -q -e ip_vs -e nf_conntrack_ipv4)&>/dev/null; then
        action "启用ipvs模块:" true
    else
        action "启用ipvs模块:" false
    fi
}

# 历史记录
history_init(){
    if ! grep HISTTIMEFORMAT /etc/bashrc; then
        echo 'export HISTTIMEFORMAT="%F %T `whoami` "' >> /etc/bashrc  >/dev/null
    fi
    if [ $? -eq 0 ] ;then
        action "历史命令格式" true
    else
        action "历史命令格式" false
    fi
}

# 内核更新方法
update_kernel_version(){
    get_system_type
    if [ $system_type = "openeuler" ]
    then
       print_color 31 "openeuler内核不做单独更新，如有特殊需求，请手动更新"
    else
        kernel_version=$(uname -r | cut -d- -f1)
        required_kernel_version="4.19"
        offline_rpm_path="./kernel/kernel-ml-4.19.12-1.el7.elrepo.x86_64.rpm"
        if [[ "$(printf '%s\n' "$required_kernel_version" "$kernel_version" | sort -V | head -n1)" == "$required_kernel_version" ]]; then
            print_separator
            print_info_green "当前内核 ($kernel_version) 等于或高于 $required_kernel_version. 无需更新."
            print_separator
        else
            print_color 32 "当前内核 ($kernel_version) 低于 $required_kernel_version. 正在启动更新..."
            (yum localinstall -y "${offline_rpm_path}") &>/dev/null

            sudo sed -i 's/^GRUB_DEFAULT=.*/# GRUB_DEFAULT=saved/' /etc/default/grub
            sudo sed -i '$ a GRUB_DEFAULT=0' /etc/default/grub
            # 重新编译内核文件
            (sudo grub2-mkconfig -o /boot/grub2/grub.cfg) &>/dev/null
            # 更新引导
            (sudo grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg) &>/dev/null
            print_separator
            print_info_green "内核已更新完成，请在确认无误后重启服务器！！！" true
            print_separator
        fi
    fi      
}

run_and_check(){
    system_init
    platform
    networkCheck
    cpuCheck
    menoryCheck
    stopFirewall
    swapOff
    history_init
    set_install_soft
    time_aliyun
    sysctl_config
    ipvsAll
    print_separator
    print_info_green "服务器部署K8S的基础环境初始化操作已经完成,请在确认无误后重启服务器，以便配置文件生效。"
    print_separator

}
log(){
    print_separator_line 
    print_info_yellow "执行脚本的方式示例: sh $0 all"
    print_info_yellow "run  初始化包含：关闭防火墙、软件包安装、内核参数等"
    print_info_yellow "check  包含更新内核到4.19"
    print_info_yellow "all  同时执行 run 和 check 操作"
    print_separator_line
}
if [ $# -ne 1 ]; then 
   log 
else
    case $1 in
        "check")
            update_kernel_version
            ;;
        "run")
            run_and_check
            ;;
        "all")
            run_and_check
            update_kernel_version
            ;;
        *)
            log
            ;;
    esac
fi