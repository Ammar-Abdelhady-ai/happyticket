#!/bin/bash

set -e

ROLE=$1  # controlplane or worker

NFS_BASE="/mnt/nfs-shared/mssql"

# Common: Create necessary directories
sudo mkdir -p ${NFS_BASE}/db-0
sudo mkdir -p ${NFS_BASE}/db-1
sudo chmod -R 777 /mnt/nfs-shared

if [[ "$ROLE" == "controlplane" ]]; then
    echo "[+] Setting up NFS Server on Control Plane..."

    sudo apt update && sudo apt install -y nfs-kernel-server

    # Configure /etc/exports
    cat <<EOF | sudo tee /etc/exports
/mnt/nfs-shared 188.138.101.4/24(rw,sync,no_subtree_check,no_root_squash)
/mnt/nfs-shared/mssql/db-0 188.138.101.4/24(rw,sync,no_subtree_check,no_root_squash)
/mnt/nfs-shared/mssql/db-1 188.138.101.4/24(rw,sync,no_subtree_check,no_root_squash)
EOF

    sudo exportfs -rav
    sudo systemctl restart nfs-kernel-server

    echo "[✔] NFS Server setup complete."

elif [[ "$ROLE" == "worker" ]]; then
    echo "[+] Setting up NFS Client on Worker Node..."

    sudo apt update && sudo apt install -y nfs-common

    # Test mount
    sudo mkdir -p /mnt/testnfs
    sudo mount -t nfs 142.132.210.239:/mnt/nfs-shared/mssql/db-0 /mnt/testnfs

    echo "[✔] NFS Client test mount success. Unmounting..."
    sudo umount /mnt/testnfs

else
    echo "[-] Invalid role. Use: controlplane OR worker"
    exit 1
fi


# ./setup_nfs_cluster.sh controlplane for Control Plane
# ./setup_nfs_cluster.sh worker for Worker Node