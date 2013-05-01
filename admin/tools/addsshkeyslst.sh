#!/bin/sh

#==============================================================================+
# File name   : addsshkeyslst.sh
# Begin       : 2013-01-08
# Last Update : 2013-05-01
# Version     : 1.0.0
#
# Description : Update SSH keys on remote hosts.
#               You must provide a host file containing a list of IP addresses
#               of the machines to update, and the file containing the public
#               keys to insert. The keys files must be named key1.pub, key2.pub,
#               ... and so on. By default the loop on the code below tries to
#               add to keys: key1.pub, key2.pub (line 76).
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
# sh addsshkeyslst.sh hosts.test > outputdata.txt


# check for image name
if [ -z "$1" ]; then
	echo "ERROR: No argument supplied. Please provide the hosts file name."
	exit 1
fi

# input file containing one IP address on each line
HOSTFILE=$1

# ssh options
SSHOPTIONS="-o BatchMode=yes -o ConnectTimeout=1 -o StrictHostKeyChecking=no"

# remote user for SSH login
USER="root"

# print header
echo "ADD SSH KEYS ..."

# for each host
for IP in `cat $HOSTFILE | awk '{ print $1; }'`
do
	# output the IP
	echo ${IP}
	
	for i in 1 2
	do
		# read the public key file
		pubkey=$(cat key"${i}".pub)

		# check if the key already exist
		EXIST=$(ssh ${SSHOPTIONS} "${USER}"@"${IP}" 2>/dev/null 'echo $(grep -c "'$pubkey'" ~/.ssh/authorized_keys)')
		if [ "$EXIST" = "0" ]; then
			# add the key
			echo [+] Adding key: key${i}.pub
			ssh-copy-id -i key"${i}".pub "${USER}"@"${IP}" 1>/dev/null 2>&1
		else
			echo [x] SKIPPING KEY: key${i}.pub
		fi

	done

done

#==============================================================================+
# END OF FILE
#==============================================================================+
