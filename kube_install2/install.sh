#!/usr/bin/env bash
systemctl stop firewalld
systemctl disable firewalld


cat >/etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

172.16.45.150  master
172.16.45.151 slaver1
172.16.45.152  slaver2
EOF

cat >/etc/sysconfig/network-scripts/ifcfg-ens33 <<EOF
TYPE="Ethernet"
PROXY_METHOD="none"
BROWSER_ONLY="no"
BOOTPROTO="static"
DEFROUTE="yes"
IPV4_FAILURE_FATAL="no"
IPV6INIT="yes"
IPV6_AUTOCONF="yes"
IPV6_DEFROUTE="yes"
IPV6_FAILURE_FATAL="no"
IPV6_ADDR_GEN_MODE="stable-privacy"
NAME="ens33"
UUID="10517e01-6062-4eaa-a66c-d25ff6d60cb3"
DEVICE="ens33"
ONBOOT="yes"
IPADDR=172.16.45.150
NETMASK=255.255.255.0
GATEWAY=172.16.45.2
DNS1=114.114.114.114
DNS2=8.8.8.8
EOF

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

setenforce 0

sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/sysconfig/selinux
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab
echo "vm.swappiness = 0">> /etc/sysctl.conf

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

yum install -y ipset
yum install -y ipvsadm
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum makecache fast
# sudo yum -y install docker-ce
sudo yum install -y --setopt=obsoletes=0 docker-ce-18.09.8-3.el7
systemctl enable docker.service
systemctl restart docker
systemctl enable docker
systemctl restart docker

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

cat <<EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["https://tqvgn53t.mirror.aliyuncs.com"],
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

yum makecache fast
yum install -y kubelet kubeadm kubectl

MY_REGISTRY=gcr.azk8s.cn/google-containers

## 拉取镜像
docker pull ${MY_REGISTRY}/kube-apiserver:v1.17.0
docker pull ${MY_REGISTRY}/kube-controller-manager:v1.17.0
docker pull ${MY_REGISTRY}/kube-scheduler:v1.17.0
docker pull ${MY_REGISTRY}/kube-proxy:v1.17.0
docker pull ${MY_REGISTRY}/pause:3.1
docker pull ${MY_REGISTRY}/etcd:3.4.3-0
docker pull ${MY_REGISTRY}/coredns:1.6.5

## 添加Tag
docker tag ${MY_REGISTRY}/kube-apiserver:v1.17.0 k8s.gcr.io/kube-apiserver:v1.17.0
docker tag ${MY_REGISTRY}/kube-controller-manager:v1.17.0 k8s.gcr.io/kube-controller-manager:v1.17.0
docker tag ${MY_REGISTRY}/kube-scheduler:v1.17.0 k8s.gcr.io/kube-scheduler:v1.17.0
docker tag ${MY_REGISTRY}/kube-proxy:v1.17.0 k8s.gcr.io/kube-proxy:v1.17.0
docker tag ${MY_REGISTRY}/pause:3.1 k8s.gcr.io/pause:3.1
docker tag ${MY_REGISTRY}/etcd:3.4.3-0 k8s.gcr.io/etcd:3.4.3-0
docker tag ${MY_REGISTRY}/coredns:1.6.5 k8s.gcr.io/coredns:1.6.5

#删除无用的镜像
docker images | grep ${MY_REGISTRY} | awk '{print "docker rmi "  $1":"$2}' | sh -x

echo "end"

