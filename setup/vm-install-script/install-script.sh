#!/bin/bash
set -e

echo "=== Updating system ==="
apt-get update -y
apt-get upgrade -y

echo "=== Installing base dependencies ==="
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

##############################################
# JENKINS INSTALLATION (Modern Repo)
##############################################

echo "=== Adding Jenkins repository ==="

# Import Jenkins key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repo
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list > /dev/null

##############################################
# KUBERNETES INSTALLATION (Modern Repo)
##############################################

echo "=== Adding Kubernetes repository ==="

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

##############################################
# DOCKER INSTALLATION (Official Repo)
##############################################

echo "=== Adding Docker repository ==="

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

##############################################
# INSTALL ALL PACKAGES
##############################################

echo "=== Updating package lists ==="
apt-get update -y

echo "=== Installing Jenkins, Docker, Kubernetes ==="
apt-get install -y \
  jenkins \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
  kubelet kubeadm kubectl

echo "=== Enabling services ==="
systemctl enable jenkins
systemctl enable docker
systemctl enable kubelet

echo "=== Starting services ==="
systemctl start docker
systemctl start jenkins
systemctl start kubelet

##############################################
# POST-INSTALL CONFIG
##############################################

echo "=== Adding current user to docker group ==="
if id "azureuser" &>/dev/null; then
    usermod -aG docker azureuser
fi

echo "=== Script completed successfully ==="
echo "Jenkins will be available on: http://<your-vm-ip>:8080"
echo "Initial admin password:"
echo "-------------------------------------------"
cat /var/lib/jenkins/secrets/initialAdminPassword
echo "-------------------------------------------"
