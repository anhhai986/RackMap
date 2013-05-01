#!/bin/sh

#==============================================================================+
# File name   : getos.sh
# Begin       : 2012-12-12
# Last Update : 2013-05-01
# Version     : 1.0.0
#
# Description : Get OS and hardware info from remote Linux machines listed on 
#               the hosts file.
#               This information can be saved on a file and imported into RackMap.
#               Your SSH key must be installed on the remote machines.
#
# Author: Nicola Asuni
#
# (c) Copyright:
#               Fubra Limited
#               Manor Coach House
#               Church Hill
#               Aldershot
#               Hampshire
#               GU12 4RQ
#               UK
#               http://www.fubra.com
#               support@fubra.com
#
# License:
#    Copyright (C) 2012-2013 Fubra Limited
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    See LICENSE.TXT file for more information.
#=============================================================================+

# USAGE EXAMPLE:
# sh getos.sh hosts.test > outputdata.txt

# check for image name
if [ -z "$1" ]; then
	echo "ERROR: No argument supplied. Please provide the hosts file name."
	exit 1
fi

# input file containing one IP address on each line
HOSTFILE=$1

# ssh options
SSHOPTIONS="-o BatchMode=yes -o ConnectTimeout=1 -o StrictHostKeyChecking=no"

# print header
echo "IP\tHOSTNAME\tRELEASE\tUNAME\tUNAMEO\tUNAMES\tUNAMER\tUNAMEV\tUNAMEM\tMANUFACTURER\tPRODUCT\tSERIAL\tUUID\tRAM\tHDDSIZE\tDISKS\tNETWORK\tLSCPU\tDMIDECODE\tHPDISKS"

# collect and print one line of data for each host
for IP in `cat $HOSTFILE | awk '{ print $1; }'`
do
	# hostname
	HOSTNAME=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(hostname)')
	# RedHat-style release name
	RELEASEA=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(cat /etc/redhat-release 2>/dev/null)')
	# Debian-style release name
	RELEASEB=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(lsb_release -d 2>/dev/null | sed "s/Description:\t//")')
	# kernel version
	UNAME=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -a)')
	# kernel operating system
	UNAMEO=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -o)')
	# kernel kernel name
	UNAMES=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -s)')
	# kernel kernel release
	UNAMER=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -r)')
	# kernel kernel version
	UNAMEV=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -v)')
	# kernel machine hardware name
	UNAMEM=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(uname -m)')
	# manufacturer
	MANUFACTURER=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(dmidecode -q -t 1 | grep "Manufacturer:" | head -n1 | sed "s/\tManufacturer:[\t ]*//")')
	# product name
	PRODUCT=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(dmidecode -q -t 1 | grep "Product Name:" | head -n1 | sed "s/\tProduct Name:[\t ]*//")')
	# machine serial number
	SERIAL=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(dmidecode -q -t 1 | grep "Serial Number:" | head -n1 | sed "s/\tSerial Number:[\t ]*//")')
	# machine UUID
	UUID=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(dmidecode -q -t 1 | grep "UUID:" | head -n1 | sed "s/\tUUID:[\t ]*//")')
	# total RAM memory in KB
	RAM=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(cat /proc/meminfo | grep "MemTotal:" | sed "s/MemTotal:[\t ]*//")')
	# total disk space in Bytes
	HDDSIZE=$(ssh ${SSHOPTIONS} root@"${IP}" 2>/dev/null 'echo $(df --total | grep "total" | sed "s/total[\t ]*//" | grep -Eo "[0-9]*" | head -n1)')
	# disks info
	DISKS=$(ssh ${SSHOPTIONS} root@"${IP}" fdisk -l 2>/dev/null | grep "Disk /dev" | sed 's/Disk //g' | sed 's/ bytes//g' | sed 's/[:,] /<T>/g' | sed ':a;N;$!ba;s/\n/<N>/g')
	# network info
	NETWORK=$(ssh ${SSHOPTIONS} root@"${IP}" ifconfig -a 2>/dev/null | sed 's/ \{2,\}/<T>/g' | sed ':a;N;$!ba;s/\n\n/<N>/g' | sed ':a;N;$!ba;s/\n//g' | sed 's/[ ]*</</g;s/>[ ]*/>/g' | sed 's/<T><T>/<T>/g')
	# get CPU(s) info
	LSCPU=$(ssh ${SSHOPTIONS} root@"${IP}" lscpu 2>/dev/null | sed 's/\:[ ]*/<T>/g' | sed ':a;N;$!ba;s/\n/<N>/g')
	# full dmidecode text block (newlines and tabs are replaced respectively with <N> and <T> tags)
	DMIDECODE=$(ssh ${SSHOPTIONS} root@"${IP}" dmidecode -q 2>/dev/null | sed ':a;N;$!ba;s/\t/<T>/g' | sed ':a;N;$!ba;s/\n/<N>/g')
	# HP Raid controller info (newlines and tabs are replaced respectively with <N> and <T> tags)
	HPDISKS=$(ssh ${SSHOPTIONS} root@"${IP}" hpacucli ctrl all show config detail 2>/dev/null | sed 's/ \{3\}/<T>/g' | sed ':a;N;$!ba;s/\n/<N>/g' | sed 's/[ ]*<T>[ ]*<N>/<N>/g' | sed 's/^<N>//g' | sed 's/\([^>]\)<T><T>/\1 /g' | sed 's/\([^>]\)<T>/\1/g' | sed 's/<N><N>/<N>/g' | sed 's/<N><N>/<N>/g')
	# output data in one TAB-separated line
	echo ${IP}"\t"${HOSTNAME}"\t"${RELEASEA}${RELEASEB}"\t"${UNAME}"\t"${UNAMEO}"\t"${UNAMES}"\t"${UNAMER}"\t"${UNAMEV}"\t"${UNAMEM}"\t"${MANUFACTURER}"\t"${PRODUCT}"\t"${SERIAL}"\t"${UUID}"\t"${RAM}"\t"${HDDSIZE}"\t"${DISKS}"\t"${NETWORK}"\t"${LSCPU}"\t"${DMIDECODE}"\t"${HPDISKS}
done

#==============================================================================+
# END OF FILE
#==============================================================================+
