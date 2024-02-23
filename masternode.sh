#!/bin/sh
## Kannan Manoharan
## VMware Certified Instructor and Microsoft Certified Trainer
##Setup Hostname
hostnamectl set-hostname master

### Prerequisites
apt-get update
apt-get install vim curl net-tools openssh-server -y
systemctl start ssh
systemctl enable ssh
ufw allow ssh


##Configure Kubernetes Repository

sudo apt update
sudo apt -y install curl apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

##Install Required Packages
sudo apt update
sudo apt -y install vim git curl wget kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

##Disable Swap
vim -c "g/swap/d" -c "wq" /etc/fstab
swapoff -a

##Configure Sysctl
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

##Install Container Runtime CRIO
OS=xUbuntu_22.04
VERSION=1.25

echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
echo "deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | apt-key add -
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | apt-key add -

apt-get update
apt-get install cri-o cri-o-runc -y

sudo systemctl daemon-reload
sudo systemctl start crio
sudo systemctl enable crio
sudo systemctl start kubelet
sudo systemctl enable kubelet

##Initialize Kubernetes
kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket unix:///var/run/crio/crio.sock
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
wget -O /root/calico.yaml https://docs.projectcalico.org/manifests/calico.yaml
vim -c "%s/docker.io/quay.io/g" -c "wq" /root/calico.yaml
kubectl apply -f /root/calico.yaml


echo "COPY JOIN COMMAND AND PASTE ON WORKER NODES"
