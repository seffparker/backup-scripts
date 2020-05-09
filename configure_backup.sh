#!/bin/bash

## This script fetch the backup scripts from GitHub repo and configure cron, syslog, logrotate etc.

## Author: Seff Parker
## Version: 20190315

DB_BACKUP="backup_mysql_databases"

mkdir -p /root/scripts

if which ! wget &> /dev/null
	then
	echo "NOTICE: wget not found! Trying to install..."
	yum install -y wget
fi

echo "INFO: Downloading scripts..."
wget -O /root/scripts/${DB_BACKUP} https://raw.githubusercontent.com/seffparker/backup_scripts/master/${DB_BACKUP}

echo "INFO: Setting permissions..."
chmod +x /root/scripts/${DB_BACKUP}

echo "INFO: Setting up logrotate..."
echo "/var/log/backup.log" > /etc/logrotate.d/backup

if ! grep -q BACKUP /etc/rsyslog.d/backup.conf
	then
	echo "INFO: Setting syslog handler..."
	echo ':programname, contains, "BACKUP" /var/log/backup.log' > /etc/rsyslog.d/backup.conf
	echo "INFO: Restarting rsyslogd service..."
	service rsyslog restart
else
	echo "NOTICE: syslog handler already exists. Skipping..."
fi

if ! grep -q ${DB_BACKUP} /var/spool/cron/root
	then
	echo "INFO: Configuring cron for ${DB_BACKUP}"
	echo "0 1 * * * /root/scripts/${DB_BACKUP} 2>&1 | logger -it DB_BACKUP" >> /var/spool/cron/root
	CRON_MOD=true
else
	echo "NOTICE: Cron for ${DB_BACKUP} already exists. Skipping..."
fi

if [ $CRON_MOD ]
	then
	echo "INFO: Restarting crond service..."
	service crond restart
fi
