# mysql-backup
A BASH script to dump MySQL databases and optionally sync to NFS, SSH, or AWS S3

## Basic Configuration
### Step 1: Install the script
 1. Place the configuration at /etc/mysql-backup.conf
 1. Place the script at any binary path, like /usr/local/bin/ and set the executable permission.

### Step 2: Configuring the cron
To backup once daily, schedule the cron at midnight. Please make sure the server timezone is in-sync with the website's visitor traffic:
```
0 0 * * * /usr/local/bin/mysql-backup | logger -it DB_BACKUP
```
The logs of backup tasks will be present in the system log.

## Advanced Configuration (Optional)

### Run the backup as non-root user
The script by default run as ROOT user. But it can run as a normal user too. 

Specify the Database user in the configuration:
```
MYSQL_USER="db_user1"
```

Create a password file in the user's home directory:
```
/home/system_user1/.my.cnf
[client]
user=db_user1
password="db_user1_password"
```
Make sure the local backup path is accessible by the system_user1
```
LOCAL_BACKUP_ROOT="/home/system_user1/backup"
```

### Backup Retention
The backup retention can be controlled by the variable BACKUP_FREQUENCY. The frequency "Sun - Sat" will keep 7 points and start overwriting after a week.

You can also write advanced patterns. For example, if we need to take four backups daily in 6 hour interval, and keep it there for 7 days, we can set as follows:
```
BACKUP_FREQUENCY="$(date +%a)/$(date +%H)"
```
This will store backup in directory structure like below, and start overwriting after a week.
```
Sun/00/
Sun/06/
Sun/12/
Sun/18/
Mon/00/
..
..
Sat/18/
```
### Sync Backups to NFS
We can sync the backups to a locally mounted NFS directory. 

1. Mount the NFS directory via /etc/fstab
2. Specify the target NFS path
```
NFS_BACKUP_ROOT="/path/to/local/nfs/mount"
```
3. Touch a file in the NFS mount to check whether the NFS is present before initiating the sync.
```
touch /path/to/local/nfs/mount/nfs_mounted
```
4. Specify the mount-check file in the backup configuration
```
NFS_MOUNT_CHECK="/path/to/local/nfs/mount/nfs_mounted"
```

### Sync Backups over SSH
We can also sync the backups to a remote server over SSH.

1. Setup SSH Key-based authentication from **Backup System User** to the **Remote SSH User**
2. Specify the SSH details in the backup configuration:
```
SSH_HOST="backup1.domain.com"
SSH_USER="backup_user1"
SSH_PORT="4321"
SSH_ROOT="~/db_backup/webserver1"
```
Make sure the path specified in SSH_ROOT is accessible by the SSH user *backup_user1*

### Sync Backups to AWS S3
1. Create an S3 bucket
2. Create an IAM Policy with following JSON Code:
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::s3-bucket-name"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::s3-bucket-name/*"]
    }
  ]
}
```
Replace the **s3-bucket-name** with the name we have created in Step 1

3. Create an IAM Programmatic User and attach the policy we have created in Step 2.
4. Note down the Access Key and Secret Key
5. Add the Access Key, Secret Key and Bucket Name in to the backup configuration file:
```
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
S3_BUCKET_NAME=""
```
6. Install the s3cmd. Its a simple alternative to official AWS-CLI
```
yum install s3cmd || apt-get install s3cmd
```

### Clean Orphaned Database Backups
When a database is removed from the MySQL Server, its backup may stored forever. To avoid this, we can configure cleaning, which will remove any extra database backups that are not currently present in the MySQL server
```
CLEAN_DB_DUMP=true
SCAN_AGE_DAYS=8
EXT=".sql.gz"
```
As per the above configuration, the script will remove backup files with extension ".sql.gz" that are older than 8 days.
