#!/usr/bin/python 
#coding:utf-8

import subprocess,re

def get_join_command():
    # 参数：（1）shell命令，（2）是否执行完成后打印完整命令和返回值，默认False
    result = subprocess.run('kubeadm token create --print-join-command', capture_output=True, shell=True, text=True)

    if result.returncode != 0:
        raise Exception("获取join command失败: %s" % result.stderr)
        
    return result.stdout.strip()

# print(get_join_command())  

def extract_kubeadm_join_info(filename):
    with open(filename, 'r') as file:
        content = file.read()
    
    pattern_control = r'(kubeadm join.*?--control-plane.*?)\n\n'
    result_control = re.findall(pattern_control, content, re.S)
    
    pattern_worker = r'(kubeadm join.*?--discovery-token-ca-cert-hash.*?)\n'
    result_worker = re.findall(pattern_worker, content, re.S)

    print("Control plane information:")
    for info in result_control:
        print(info) 
        
    print("\nWorker node information:")
    if  result_worker:
        if '--control-plane' not in result_worker[0]:
            print(result_worker[0])

if __name__ == '__main__':
    extract_kubeadm_join_info("./k8s_init.log")