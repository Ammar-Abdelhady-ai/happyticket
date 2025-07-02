#!/bin/bash

# Install NFS Server & Client
apt update
apt install -y nfs-kernel-server nfs-common

# Create NFS shared directory
mkdir -p /mnt/data/mssql
chown nobody:nogroup /mnt/data/mssql
chmod 777 /mnt/data/mssql

# Export NFS share
echo "/mnt/data/mssql 188.138.101.4/24(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports

# Restart NFS server
exportfs -a
systemctl restart nfs-kernel-server

echo "Master NFS Server setup complete. /mnt/data/mssql is now shared."
