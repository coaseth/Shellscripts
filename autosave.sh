#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

eredeti=$(pwd)

cd /var/www/services

sudo chown -R silver:www-data ../services
sudo chmod -R 775 ../services

cd $eredeti

# Define the path of the file to backup
FILE_TO_BACKUP="/var/www/services"

# Define the directory where backups will be stored
BACKUP_DIR="/home/mentes"

# Get the current date in YYYY_MM_DD format
CURRENT_DATE=$(date +"%Y_%m_%d")

# Create a new directory named with the current date
NEW_BACKUP_DIR="$BACKUP_DIR/$CURRENT_DATE"

# Check if the backup directory already exists
if [ ! -d "$NEW_BACKUP_DIR" ]; then
    mkdir -p "$NEW_BACKUP_DIR"
fi

# Change to the new backup directory
cd "$NEW_BACKUP_DIR"

# Return to the original directory
cd "$eredeti"

# MySQL dumping the necessary database with all its data
USER='servicesuser'       # MySQL User
PASSWORD='servicespass'   # MySQL Password
DAYS_TO_KEEP=30           # 0 to keep forever
GZIP=0                    # 1 = Compress
BACKUP_PATH="$NEW_BACKUP_DIR"

# Get list of database names
databases=$(mysql -u $USER -p$PASSWORD -e "SHOW DATABASES;" | tr -d "|" | grep -v Database)

for db in $databases; do
    if [ "$db" = 'information_schema' ] || [ "$db" = 'performance_schema' ] || [ "$db" = 'mysql' ] || [ >
        echo "Skipping database: $db"
        continue
    fi
    date=$(date -I)
    if [ "$GZIP" -eq 0 ]; then
        echo "Backing up database: $db without compression"
        mysqldump -u $USER -p$PASSWORD --databases $db > $BACKUP_PATH/$date-$db.sql
    else
        echo "Backing up database: $db with compression"
        mysqldump -u $USER -p$PASSWORD --databases $db | gzip -c > $BACKUP_PATH/$date-$db.gz
    fi
done

# Delete old backups
if [ "$DAYS_TO_KEEP" -gt 0 ]; then
    echo "Deleting backups older than $DAYS_TO_KEEP days"
    find $BACKUP_PATH/* -mtime +$DAYS_TO_KEEP -exec rm {} \;
fi

# Copy the file to the new backup directory
cp -R "$FILE_TO_BACKUP" "$NEW_BACKUP_DIR"

# Print a message indicating the backup is complete
echo "Backup of $FILE_TO_BACKUP completed successfully to $NEW_BACKUP_DIR"

sudo chmod -R 775 "$NEW_BACKUP_DIR"

rsync -avz "$NEW_BACKUP_DIR" mentes@172.16.11.196:/home/mentes/
