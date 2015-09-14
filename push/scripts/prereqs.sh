#!/bin/bash

# define the global variables
export STAGE="/u01/stage"
export SOFTWARE="/var/tmp"
export PASSWORD="Password1#"
export VERSION="12.1.0.2"

###################
# Functions
###################

installPackages(){
  PACKAGES=$@
  rpm -q $PACKAGES 
  if [ $? -ne 0 ]; then
    #yum clean metadata
    yum -y install $PACKAGES
    if [ $? -ne 0 ]; then
      echo "error installing packages :("
      exit 1
    fi
  fi
}

updateLimits(){
  if [ $# -eq 4 ]; then
    [ -f /etc/security/limits.conf.ori ] || cp /etc/security/limits.conf /etc/security/limits.conf.ori
    > /etc/security/limits.conf.tmp
    mv /etc/security/limits.conf /etc/security/limits.conf.tmp
    grep -v -E "$2.*.$3" /etc/security/limits.conf.tmp >> /etc/security/limits.conf
    echo $@ >> /etc/security/limits.conf
  fi
}

# Proxy
[ -f /proxy/.proxy.env ] && source /proxy/.proxy.env

#Install required packages
installPackages oracle-rdbms-server-12cR1-preinstall.x86_64 xorg-x11-xauth.x86_64 xorg-x11-server-utils.x86_64 ntp

# Install following for graphical install
installPackages tigervnc-server xterm twm 


# grid and oracle user
#create the extra groups for db12c role separation
echo "Checking groups for grid and oracle user"

grep ^asmdba:    /etc/group 2>&1 > /dev/null || groupadd -g 54318 asmdba
grep ^asmoper:   /etc/group 2>&1 > /dev/null || groupadd -g 54319 asmoper
grep ^asmadmin:  /etc/group 2>&1 > /dev/null || groupadd -g 54320 asmadmin
grep ^oinstall:  /etc/group 2>&1 > /dev/null || groupadd -g 54321 oinstall
grep ^dba:       /etc/group 2>&1 > /dev/null || groupadd -g 54322 dba
grep ^backupdba: /etc/group 2>&1 > /dev/null || groupadd -g 54323 backupdba
grep ^oper:      /etc/group 2>&1 > /dev/null || groupadd -g 54324 oper
grep ^dgdba:     /etc/group 2>&1 > /dev/null || groupadd -g 54325 dgdba
grep ^kmdba:     /etc/group 2>&1 > /dev/null || groupadd -g 54326 kmdba

#create or modify as required user grid and oracle
echo "verifying grid user"
id grid   2>&1  > /dev/null  && usermod -a -g oinstall -G asmdba,asmadmin,asmoper,dba grid || useradd -u 54320 -g oinstall -G asmdba,asmadmin,asmoper,dba grid
echo "verifying oracle user"
id oracle 2>&1 > /dev/null  && usermod -a -g oinstall -G dba,asmdba,backupdba,oper,dgdba,kmdba oracle   || useradd -u 54321 -g oinstall -G dba,asmdba,backupdba,oper,dgdba,kmdba oracle

#set initial password
echo oracle | passwd --stdin oracle
echo grid   | passwd --stdin grid

# Unpack previously downloaded software

mkdir -p /u01 /u02 /u03
mkdir -p /u01/stage

pushd ${STAGE}
for zipfile in linuxamd64_12102_grid_1of2.zip linuxamd64_12102_grid_2of2.zip; do
  unzip -n ${SOFTWARE}/${zipfile} -d ${STAGE} && rm ${SOFTWARE}/${zipfile}
done
popd


# Directories
#Oracle Home
#mkdir -p /u01/app/oracle/product/$VERSION
#Grid Home
mkdir -p /u01/app/$VERSION/grid
#Grid Base
mkdir -p /u01/app/grid
#Oracle Base
mkdir -p /u01/app/oracle
#OraInventory
#mkdir ... 

# Update permissions
chown -R grid:oinstall /u01
chmod -R 775 /u01/
chown oracle:oinstall /u01/app/oracle

# Add umask to grid - oracle
# from https://docs.oracle.com/database/121/CWLIN/usrgrps.htm
# 6.2.1 Environment Requirements for Oracle Software Owners

for user in grid oracle ; do
  grep "umask 022" /home/$user/.bash_profile
  if [ $? -ne 0 ]; then
    echo "umask 022" | sudo -u $user tee -a /home/$user/.bash_profile
  fi
done


# Update user limits
if [ `ulimit -Sn` -lt  1024 ]; then updateLimits grid     soft     nofile       1024 ; fi
if [ `ulimit -Hn` -lt 65536 ]; then updateLimits grid     hard     nofile      65536 ; fi
if [ `ulimit -Su` -lt  2047 ]; then updateLimits grid     soft     nproc        2047 ; fi
if [ `ulimit -Hu` -lt 16384 ]; then updateLimits grid     hard     nproc       16384 ; fi
if [ `ulimit -Ss` -lt 10240 ]; then updateLimits grid     soft     stack       10240 ; fi
if [ `ulimit -Hs` = "unlimited" ] || [ `ulimit -Hs` -lt 32768 ]; then updateLimits grid     hard     stack       32768 ; fi

# Start NTP daemon
service ntpd status && service ntpd restart || service ntpd start
chkconfig ntpd on

pushd ${STAGE}
for zipfile in linuxamd64_12102_database_1of2.zip linuxamd64_12102_database_2of2.zip; do
  unzip -n ${SOFTWARE}/${zipfile} -d ${STAGE} && rm ${SOFTWARE}/${zipfile}
done
popd

