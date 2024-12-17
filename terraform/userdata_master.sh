#!/bin/bash
# Update system and install Docker
yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user

# Add Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

# Install kubelet, kubeadm, and kubectl
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Enable and start kubelet
systemctl enable kubelet && systemctl start kubelet

# Initialize Kubernetes master node
kubeadm init --pod-network-cidr=10.244.0.0/16

# Set up kubeconfig
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

# Install Flannel for networking
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
