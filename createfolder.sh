#!/bin/bash


mkdir -p /mnt/data/mssql/controlplane
mkdir -p /mnt/data/mssql/worker-1

mkdir -p /mnt/data/mssql/backup

mkdir -p /mnt/data/wwwroot

chmod -R 777 /mnt/data/mssql
chmod -R 777 /mnt/data/wwwroot

echo "All required folders created and permissions set."
