#!/bin/bash

# Configuration - Set these variables before running
NFS_SERVER_IP="YOUR_NFS_SERVER_IP"  # e.g., 142.132.210.239

# Install NFS Client
apt update
apt install -y nfs-common

# Create mount point and mount NFS share
mkdir -p /mnt/data/mssql
mount ${NFS_SERVER_IP}:/mnt/data/mssql /mnt/data/mssql

# Add to fstab for persistence
echo "${NFS_SERVER_IP}:/mnt/data/mssql /mnt/data/mssql nfs defaults 0 0" >> /etc/fstab

echo "Worker node NFS mount complete."
