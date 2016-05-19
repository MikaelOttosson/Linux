#!/bin/bash
#
# Invoicing Script
# Company: Enabletec AB
# Creator: Mikael Ottosson
# Date: 2015-08-01
#
# Global Variables
####################################################################
IPATH=/www/c1_faktura/sites/default/files/feeds/mh
FPATH=public://feeds/mh/
FILESOURCE=/mnt/invoices_c1
DAT=`date +%Y%m%d`
YESTERDAY=`date --date='-1 day' +%Y%m%d` 
FCOUNT=0
NADDRESS=user1@company1.com
NADDRESS2=user2@company2.com
IMPORTURL=http://faktura.company2.com/cron.php?cron_key=BE5_p9gRFSXPvqttNBGU3u-fHwvqFBdEbASAFl84ggs775j732


# Create CSV file from files to import.
####################################################################
function createCSV() {
        
	if [ $FCOUNT -gt 0 ]
	then
		echo "leverantör;fakturanummer;fil" > $IPATH/Bok1.csv
       		find $IPATH -type f -name "*.pdf" -exec basename {} \; | while read x; do
               	if [[ $x != *['!'@#\$%^\&*():\;+\/]* ]] # File sanitizing
               	then
			# Create string for csv import file
                       	PART2=`printf "${x}" | tr -s '[:blank:]' '-'`
                       	PART1=`printf "${x}"  |  awk -F "_" '{ print $1 ";" $2 }' | awk -F "." '{ print $1 ";" }'` ; echo $PART1$FPATH$PART2 >> $IPATH/Bok1.csv
                       	if [ "$IPATH/$x" != "$IPATH/$PART2" ]
                        then
                               	mv -n "$IPATH/$x" "$IPATH/$PART2" # Replace spacing to hyphen
                       	fi
               	else
                       	echo "There is special characters in filename: $x" >> /tmp/import_error.log
               	fi
       		done
	fi
	
}

# Filecopy section
####################################################################
function fileCopy() {

	if [ ! -f $IPATH/$DAT.lock ]
        then
		mount -t cifs -o username=user,domain=domain,password='010101010101' //192.168.30.200/c2 /mnt/invoices_c2
		sleep 5
		FCOUNT=`find $FILESOURCE -maxdepth 1 -name *.pdf | wc -l`
		if [ $FCOUNT -gt 0 ]
		then
			cp -n $FILESOURCE/*.pdf $IPATH
			mv -n $FILESOURCE/*.pdf $FILESOURCE/archive
			touch $IPATH/$DAT.lock
			if [ -f $IPATH/$YESTERDAY.lock ]
			then
				rm $IPATH/$YESTERDAY.lock
			fi
		fi
		sleep 5
                umount /mnt/invoices_c2
	fi	
}

#
# Import to drupal
####################################################################
function drupalImport() {
wget -O - -q -t 1 $IMPORTURL
}

# Notification output
####################################################################
function notificationOutput() {
	if [ -f $IPATH/$DAT.lock ]
        then
		if [ ! -f $IPATH/mailout.txt ]
		then
			echo -e "Nya fakturor är nu inscannade och redo för attest." "\n" > $IPATH/mailout.txt
			find $IPATH -type f -name "*.pdf" -exec basename {} \; | awk -F "_" '{ print " Leverantör","\n",$1,"\n","Fakturanummer","\n",$2,"\n" }' >> $IPATH/mailout.txt
			echo -e "Med vänliga hälsningar""\n""Company1" >> $IPATH/mailout.txt
			echo -e ""\n"Logga in på: http://faktura.company1.com" >> $IPATH/mailout.txt
			export EMAIL=info@company1.com && mutt -s "Nya fakturor för attest" $NADDRESS,$NADDRESS2  < $IPATH/mailout.txt
			sleep 60
		fi
	fi
}

# Cleanup files in feed directory
####################################################################
function cleanUp() {
	if [ -f $IPATH/$DAT.lock ]	
	then	rm $IPATH/*
	fi
}



fileCopy

createCSV

drupalImport

notificationOutput

cleanUp

exit 0


