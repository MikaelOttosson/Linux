#!/bin/bash

# Script for backup purposes
# Company: Enabletec AB
# Creator: Mikael Ottosson
# Date: 2015-05-01

# GLOBAL Variables
#####################################
DNOW=`date +%Y-%m-%d`
OPUTDIR=/www/backup
KEEPFILESDAYS=31
EMAILNOTIFY=abc@enabletec.se
LOGFILE=/var/log/webbackup.log

# Functions declaration
#####################################
filesCondition() {
        WEBFEXIST=(/www/backup/*_web_files_$DNOW*)
        DBFEXIST=(/www/backup/*_web_db_$DNOW*)
        WEBFSIZE=`ls -l --block-size=1K $OPUTDIR/*web_files_$DNOW* | awk '{ print $5 }' | head -1`
        DBFSIZE=`ls -l --block-size=1K $OPUTDIR/*_web_db_$DNOW* | awk '{ print $5 }' | head -1`

        if [[ -f $WEBFEXIST ]] && [[ -f $DBFEXIST ]]
        then
                if [[ $WEBFSIZE -gt 1000 ]] && [[ $DBFSIZE -gt 100 ]]
                then
                        ERRNR=0
                else
                        ERRNR=1
                fi
        else
                ERRNR=2
        fi

         case $ERRNR in
        0) MESSAGE="Web and DB Backup Successfully"
        ;;
        1) MESSAGE="Web and DB Backup Problem - filesize issues"
        ;;
        2) MESSAGE="Web and DB Backup Problem - Output is missing"
        ;;
        esac
}


mailFunction() {
	mail -s $MESSAGE $EMAILNOTIFY < /dev/null
}

logFunction() {
	echo $DNOW $MESSAGE >> $LOGFILE

	if  [ ERRNR == 1 ]
	then
		echo $DNOW `ls -ls /www/backup/*_web_files_$DNOW*` >> $LOGFILE
		echo $DNOW `ls -ls /www/backup/*_db_files_$DNOW*` >> $LOGFILE
	fi
}

# Backup web files
tar -zcvf /www/backup/sites_web_files_$DNOW.tar.gz /www/sites

# Backup db files
mysqldump -u root -p'password' site1 | gzip > /www/backup/site1_web_db_$DNOW.sql.gz

# Mount a cifs share on windows server and copy backupfiles
mount -t cifs -o username=backup,domain=domain,password='password' //172.16.88.240/web_backup /mnt/share
sleep 2
cp /www/backup/sites_web_files_$DNOW.tar.gz /mnt/share
cp /www/backup/sites_web_db_$DNOW.sql.gz /mnt/share
sleep 5

# Remove old files from local and cifs share
find /www/backup/ -name '*gz' -type f -mtime +$KEEPFILESDAYS | xargs /bin/rm -f
find /mnt/share/ -name '*gz' -type f -mtime +$KEEPFILESDAYS | xargs /bin/rm -f

# Unmount
#####################################
sleep 10
umount /mnt/share


# Executing funtions
filesCondition

mailFunction

logFunction

exit 0
