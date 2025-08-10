#!/bin/bash -xe

# Wait for cloud-init to complete
cloud-init status --wait

# Kernel modules for Kubernetes
cat > /etc/modules-load.d/k8s.conf << '__EOF_MODULES'
overlay
br_netfilter
__EOF_MODULES

modprobe overlay
modprobe br_netfilter

# Sysctl params required by Kubernetes
cat > /etc/sysctl.d/k8s.conf << '__EOF_K8S_CONF'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
__EOF_K8S_CONF

# Apply sysctl params
sysctl --system

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Install dependencies
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

# Add Kubernetes apt repository
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Install Kubernetes components
KUBERNETES_VERSION="${kubernetes_version}"
apt-get update
apt-get install -y kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION
apt-mark hold kubelet kubeadm kubectl

# Install containerd
cd /tmp
CONTAINERD_VERSION="2.0.0"
wget https://github.com/containerd/containerd/releases/download/v$CONTAINERD_VERSION/containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz
tar Cxzvf /usr/local containerd-$CONTAINERD_VERSION-linux-amd64.tar.gz

# Install containerd service
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /lib/systemd/system/

# Configure containerd
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml << '__EOF_CONTAINERD'
version = 2

[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    [plugins."io.containerd.grpc.v1.cri".containerd]
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
__EOF_CONTAINERD

# Start containerd
systemctl daemon-reload
systemctl enable --now containerd

# Install runc
RUNC_VERSION="1.2.3"
wget https://github.com/opencontainers/runc/releases/download/v$RUNC_VERSION/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc

# Install CNI plugins
CNI_VERSION="1.6.1"
wget https://github.com/containernetworking/plugins/releases/download/v$CNI_VERSION/cni-plugins-linux-amd64-v$CNI_VERSION.tgz
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v$CNI_VERSION.tgz

# Set hostname using AWS metadata
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
hostnamectl set-hostname $HOSTNAME

# Wait for master API server to be ready
echo "Waiting for master API server at ${apiserver_ip}:6443..."
until curl --output /dev/null --silent --fail https://${apiserver_ip}:6443/healthz -k; do
    printf '.'
    sleep 5
done
echo ""
echo "API Server is ready!"

# Create kubeadm join config
cat > /tmp/worker.yaml << '__EOF_KUBEADM'
${worker_config}
__EOF_KUBEADM

# Replace placeholder with actual hostname
sed -i "s/NODE_HOSTNAME/$HOSTNAME/g" /tmp/worker.yaml

# Join the cluster
kubeadm join --config /tmp/worker.yaml

echo "Worker node joined successfully!"