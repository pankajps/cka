#!/bin/bash
# kubeadm installation instructions as on
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

# this script supports Ubuntu 20.04 and later only
# run this script with sudo

if ! [ $USER = root ]
then
	echo run this script with sudo
	exit 3
fi

# setting MYOS variable
MYOS=$(hostnamectl | awk '/Operating/ { print $3 }')
OSVERSION=$(hostnamectl | awk '/Operating/ { print $4 }')
if [ $MYOS = "Ubuntu" ]
then
	echo RUNNING UBUNTU CONFIG
	cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
	br_netfilter
EOF
	
	sudo apt-get update && sudo apt-get install -y apt-transport-https curl
        sudo mkdir /etc/apt/keyrings
	echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
	curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

	sudo apt-get update
	sudo apt-get install -y kubelet=1.28.0-1.1 kubeadm=1.28.0-1.1 kubectl=1.28.0-1.1
	sudo apt-mark hold kubelet kubeadm kubectl
	swapoff -a
	
	sed -i 's/\/swap/#\/swap/' /etc/fstab
fi

# Set iptables bridging
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

sudo crictl config --set \
    runtime-endpoint=unix:///run/containerd/containerd.sock

echo 'after initializing the control node, follow instructions and use kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml to install the calico plugin (control node only). On the worker nodes, use sudo kubeadm join ... to join'

