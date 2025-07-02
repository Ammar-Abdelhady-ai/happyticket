#!/bin/bash

# Install NFS Client
apt update
apt install -y nfs-common

# Create mount point and mount NFS share
mkdir -p /mnt/data/mssql
mount 142.132.210.239:/mnt/data/mssql /mnt/data/mssql

# Add to fstab for persistence
echo "142.132.210.239:/mnt/data/mssql /mnt/data/mssql nfs defaults 0 0" >> /etc/fstab

echo "Worker node NFS mount complete."
