#!/bin/bash
yum update -y
amazon-linux-extras install -y docker
service docker start
usermod -a -G docker ec2-user

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
EOF

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Join the master node
# You will need to manually replace the placeholders <token>, <master-ip>, and <hash> with actual values from the master node
kubeadm join --token <token> <master-ip>:6443 --discovery-token-ca-cert-hash sha256:<hash>
