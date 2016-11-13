#!/bin/bash
# Name: adddevice.sh
# Purpuse: add request URI to config file
# Creator: Mikael Ottosson, Enabletec AB
# Date: 20161112
########################################################
# Global Variables
CONFIGDIR=/etc/apache2/conf.d # Base config for Apache service
CONFIGFILE=macfilter.conf # This file needs to be added as Include directive in httpd.conf
APACHEBIN=httpd

########################################################
# Functions

function getMacAddress() {
	if [ -z "$1" ]
  		then
		echo "This is a script for adding one device to the filter. This script needs to have a valid input parameter."
    		echo "Command line argument example: ./adddevice.sh aabbccddee66"
	else
		if [ "$1" -eq 12 ]
			then
			inputcheck = 1
		fi
	fi	
}

function stringBuilder() {
	if [ $inputcheck == 1 ]
		then
		string=`SetEnvIf Request_URI ^"$1" allow` # allow needs to be added in Deny, Allow section in httpd.conf.
		echo $string >> $CONFIGDIR/$CONFIGFILE
	fi
}

function reloadService() {
	if [ inputcheck == 1 ]
		/etc/init.d/$APACHEBIN graceful # Service Reload.
		sleep 5
		httpdcheck=`ps -ef | grep $APACHEBIN | wc -l`
	fi
}

function errorCheck() {
	if [ inputcheck != 1 ]
		then
	else
		checkdata=`cat $CONFIGDIR/$CONFIGFILE | grep $string`
		if [ -z "$checkdata" ]
			then
			echo "There was a problem writing data to config file."
		else
			echo "Data entry with $1 has been successfully added to config."
		fi
		if [ httpdcheck -gt 0 ]
			echo "Config has been applied to webservice and the device is now ready for provisioning."	
		else
			echo "There was a problem startup the webservice."
	fi
}
########################################################
# Main

getMacAddress

stringBuilder

reloadService

errorCheck

exit 0
