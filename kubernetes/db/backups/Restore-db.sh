#!/bin/sh
DB_NAME="NewHappy2"
BACKUP_FILE="/backups/NewHappy2-2025-08-04-1158.sql"   
/opt/mssql-tools/bin/sqlcmd -S db-0.db.happyticket.svc.cluster.local \
  -U sa -P "$SA_PASSWORD" \
  -Q "RESTORE DATABASE [${DB_NAME}] FROM DISK='${BACKUP_FILE}' WITH REPLACE"
