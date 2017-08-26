#! /bin/bash
#
# ***(WIP) probably a lot of bugs for the moment.***
#
# Does a lot of things, but mostly related to cPanel maintenance.
# Crafted with love by bhardy from many many "one-liners".
# ISSUES:
# 1. Ensure that the appends print to the terminal as well (tee it if needed?)
# 2. Lots of other things.
#
# Pre-script sanity checks and prep:
mkdir /root/singlehop/
cd /root/singlehop/
mysqllog="/root/singlehop/sh.maintenance.mysql.log"
cpanellog="/root/singlehop/maintenance.cpanel.log"
# main:
#
#------------------------------------ (Merge with cPanel maintenance?)
echo "Starting maintenance, please be patient as this progresses."
csflocation=$(which csf)
if [ -w /etc/csf/csf.conf]  # Sanity check to see if CSF (or at least it's config) exists and is writeable.
  csfexists=1
  echo "detected CSF installation, performing maintenance."
# ask if we're flushing the deny and temp deny chains
# csf -tf
# csf -df #flush CSF deny chain, as I noticed it gets "clogged".
# read "Would you like to install the silent CSF config? [Y/n]"
# if yes, do it. if no, nope.
else
  csfexists=0
  echo "csf not present, skipping csf portion"
# or possibly:
# echo "ConfigServer Firewall not present, would you like to install it?"
#... but that's likely going into another script that this script will call based on the prompt above.
fi
#-------------------------------------- cPanel-based servers (create "if" statement to determine if this exists)
echo "performing cPanel maintenance now - this may cause temporary disruption of WHM/cPanel" #ask first?
echo "Setting Let's Encrypt's CA as an option for AutoSSL for Engintron bug ID x" #find the bug ID, and put it here.
sh /scripts/install_lets_encrypt_autossl_provider 2> /dev/null
# insert if statement detecting an Engintron installation before asking the Engintron related questions.
# echo "Done - would you like to run AutoSSL at this time? [cpaneluser/ALL/n]"
echo "Running cPanel's maintenance script..."
echo "/scripts/maintenance started on" >> $cpanellog
date >> /root/singlehop/maintenance.log
sh /scripts/maintenance >> $cpanellog
echo "Checking cPanel provided RPMs..."
sh /scripts/check_cpanel_rpms >> $cpanellog
echo "purging stale ModSec logs..."
sh /scripts/purge_modsec_log
#########echo "Performing general cPanel maintenance"
# echo "Fixing quotas - this may take some time to finish, please be patient."
# sh /scripts/fixquotas
#####
#echo "Performing an in-place upcp in a screen... this may take some time."
#sh /scripts/upcp >> $cpanellog # needs to wait for completion
echo "performing service maintenance now..."
echo "Updating Dovecot..."
sh /scripts/dovecotup
echo "Restarting Dovecot..."
service dovecot restart
echo "Updating Exim..."
sh /scripts/eximup
echo "Restarting Exim..."
service exim restart
####################
# echo "Running SSP, logging to /root/singlehop/ssp.log"
# wget ssplink
# sh /path/to/ssp >> /root/singlehop/ssp.log
####################
#==================================================== Start of cPanel-based MySQL maintenance:
echo "Starting cPanel-based MySQL maintenance now."
echo "First, converting RoundCube and Horde DB to a SQLite format..." ## See https://documentation.cpanel.net/display/CKB/How+to+Convert+Roundcube+to+SQLite
sh /scripts/convert_roundcube_mysql2sqlite >> $mysqllog
sh /scripts/horde_mysqltosqlite >> $mysqllog

# Maybe others?

echo "Detecting the presence of EximStats DB, and clearing for performance."
if [ -a /var/lib/mysql/eximstats ]
  echo "Detected the presence of Eximstats DB" >> $mysqllog   #***tee it if needed.***
  echo "Clearing EximStats DB for MySQL performance purposes..." >> $mysqllog
  mysql -e "use eximstats; delete from sends; delete from defers; delete from failures; delete from smtp;" >> $mysqllog
  echo "Eximstats DB cleared. Restarting MySQL." >> $mysqllog
  service mysql restart
else
  echo "EximStats DB not detected. Proceeding."
fi

#------------------------------------- Starting "general maintenance":
# prompt y/n for Yum maintenance and updates here...
echo "Updating packages via Yum..."
yum clean all
yum makecache fast
yum -y update
# yum -y install yumupdatesd #set this to automatically update in the future...

#------------------------------------- Starting security checks:
echo "Running security advisor from CLI, logging to /root/singlehop/secadvisor.log"
sh /scripts/check_security_advice_changes >> /root/singlehop/secadvisor.log
echo "Security Advisor finished, please check the logs if this is relevant to your issue."
#if [ csf not installed]
#install csf.

# Working on it, more coming later.


