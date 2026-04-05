#!/bin/bash
set -e

echo "=== Updating system ==="
apt-get update -y
apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https

echo "=== Setting prompt (optional) ==="
PS1='\[\e[01;36m\]\u\[\e[01;37m\]@\[\e[01;33m\]\H\[\e[01;37m\]:\[\e[01;32m\]\w\[\e[01;37m\]\$\[\033[0;37m\] '
echo "PS1='$PS1'" >> ~/.bashrc
source ~/.bashrc

# ---------------------------------------------------------
# 1. Install Docker (official repo)
# ---------------------------------------------------------
echo "=== Installing Docker Engine ==="

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Configure containerd for Kubernetes
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

systemctl restart containerd
systemctl enable containerd
systemctl enable docker

# ---------------------------------------------------------
# 2. Install Kubernetes (modern repo)
# ---------------------------------------------------------
echo "=== Installing Kubernetes 1.29 ==="

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-1-29.gpg

chmod a+r /etc/apt/keyrings/kubernetes-1-29.gpg

echo \
  "deb [signed-by=/etc/apt/keyrings/kubernetes-1-29.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

# ---------------------------------------------------------
# 3. Initialize Kubernetes cluster
# ---------------------------------------------------------
echo "=== Initializing Kubernetes cluster ==="

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

kubeadm reset -f
kubeadm init --pod-network-cidr=192.168.0.0/16 --skip-token-print

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# ---------------------------------------------------------
# 4. Install Calico CNI
# ---------------------------------------------------------
echo "=== Installing Calico CNI ==="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

echo "Waiting for Calico to become ready..."
sleep 45

# Remove master taint so node can schedule pods
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# ---------------------------------------------------------
# 5. Install Java + Maven
# ---------------------------------------------------------
echo "=== Installing Java 17 and Maven ==="
apt-get install -y openjdk-17-jdk maven

# ---------------------------------------------------------
# 6. Install Jenkins (modern repo)
# ---------------------------------------------------------
echo "=== Installing Jenkins ==="

curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

echo \
  "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

apt-get update -y
apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

# Allow Jenkins to use Docker
usermod -aG docker jenkins

echo "=== Installation Complete ==="
echo "Jenkins is running on port 8080"
echo "Kubernetes cluster is ready"
echo "Docker is installed and configured"
