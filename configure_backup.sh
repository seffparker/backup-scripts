#!/bin/bash

## This script fetch the backup scripts from GitHub repo and configure cron, syslog, logrotate etc.

## Author: Seff Parker
## Version: 20190315

DB_BACKUP="backup_mysql_databases"
DEL_DB_BACKUP="clean_old_database_backups"
HT_BACKUP="backup_index_files"

mkdir -p /root/scripts

if which ! wget &> /dev/null
	then
	echo "NOTICE: wget not found! Trying to install..."
	yum install -y wget
fi

echo "INFO: Downloading scripts..."
wget -O /root/scripts/${HT_BACKUP} https://raw.githubusercontent.com/seffparker/backup_scripts/master/${HT_BACKUP}
wget -O /root/scripts/${DB_BACKUP} https://raw.githubusercontent.com/seffparker/backup_scripts/master/${DB_BACKUP}
wget -O /root/scripts/${DEL_DB_BACKUP} https://raw.githubusercontent.com/seffparker/backup_scripts/master/${DEL_DB_BACKUP}

echo "INFO: Setting permissions..."
chmod +x /root/scripts/${DEL_DB_BACKUP} /root/scripts/${DB_BACKUP} /root/scripts/${HT_BACKUP}

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
	echo '0 1 * * * /root/scripts/${DB_BACKUP} 2>&1 | logger -it DB_BACKUP' >> /var/spool/cron/root
	CRON_MOD=true
else
	echo "NOTICE: Cron for ${DB_BACKUP} already exists. Skipping..."
fi

if ! grep -q ${DEL_DB_BACKUP} /var/spool/cron/root
	then
	echo "INFO: Configuring cron for ${DEL_DB_BACKUP}"
	echo '0 0 * *	* /root/scripts/${DEL_DB_BACKUP} --delete 2>&1 | logger -it DEL_DB_BACKUP' >> /var/spool/cron/root
	CRON_MOD=true
else
	echo "NOTICE: Cron for ${DEL_DB_BACKUP} already exists. Skipping..."
fi


if ! grep -q ${HT_BACKUP} /var/spool/cron/root
	then
	echo "INFO: Configuring cron for ${HT_BACKUP}"
	echo '0 2 * * * /root/scripts/${HT_BACKUP} 2>&1 | logger -it HT_BACKUP' >> /var/spool/cron/root
	CRON_MOD=true
else
	echo "NOTICE: Cron for ${HT_BACKUP} already exists. Skipping..."
fi

if $CRON_MOD
	then
	echo "INFO: Restarting crond service..."
	service crond restart
fi
