#!/bin/bash
# ###########################################################################
# PWEBSYNC V1.0 10-02-2013
#
# Copyright (C) 2012-2013 Paprocki £ukasz <kontakt.lukaszpaprocki@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
# 
# This tool will search and synchronize a webpage and postgres database on a Linux Server
# The Supported Operating Systems are Linux / CentOS / RedHat
# ###########################################################################
# configuration variables
# ###########################################################################
REMOTEHOSTADDR="$REMOTEHOSTADDR"
REMOTEUSER="$USER"
PWD="$PASSWORD"
DB="$DBNAME"
DATA=`date --d='yesterday' +'%Y%m%d'`
FILE=$DATA'_pgsqldump.sql.gz'

LOCALWEB="/var/www/html/"
LOCALDB="/home/"

umask 077
# ###########################################################################
# check the shell
# ###########################################################################
if [ -z "$BASH_VERSION" ]; then
    echo -e "Error: this script requires BASH shell!"
    exit 1
fi 
# ###########################################################################
# funcions returns unix timestamp
# ###########################################################################
function utime
{
    echo $(date +%s)
}
# ###########################################################################
# function remove temporary files
# ###########################################################################
function remove_temp_files
{
        rm -fr "*.sql"
		rm -fr "*.gz"
}
# ###########################################################################
# first dir cfg
# ###########################################################################
REMOTEWEB1="//var/www/html/YOURNAME1"

expect -c "
    set timeout 7200
    spawn rsync -avz -e ssh $REMOTEUSER@$REMOTEHOSTADDR:REMOTEWEB1 $LOCALWEB
    expect {
    password: {send \"$PWD\r\"; exp_continue }
    }
"
# ###########################################################################
# second dir cfg
# ###########################################################################
REMOTEWEB2="//var/www/html/YOURNAME2"

expect -c "
   set timeout 7200
   spawn rsync -avz -e ssh $REMOTEUSER@$REMOTEHOSTADDR:REMOTEWEB2 $LOCALWEB
   expect {
   password: {send \"$PWD\r\"; exp_continue }
   }
"
# ###########################################################################
# db cfg
# ###########################################################################
REMOTEDB="//home/backups/postgres/$FILE"

expect -c "
     set timeout 17200
     spawn scp -c blowfish $REMOTEUSER@$REMOTEHOSTADDR:$REMOTEDB $LOCALDB
     expect {
     password: { send \"$PWD\r\"; exp_continue }    
     }
"
# ###########################################################################
# unpack db
# ###########################################################################
expect -c "
    spawn gunzip $FILE
    expect {
    EOF { exp_continue }
    }
"

mv $DATA'_pgsqldump.sql' $FILE
gunzip $FILE
# ###########################################################################
# db operations
# ###########################################################################
dbname="$DB"
username="$DB"

psql -d $dbname -U postgres << EOF
DROP SCHEMA lw CASCADE;
EOF

psql -d $dbname -U postgres << EOF
CREATE SCHEMA lw;
EOF

psql -d $dbname -U postgres < /home/$DATA'_pgsqldump.sql'

remove_temp_files