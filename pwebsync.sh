#!/bin/bash
# PWEBSYNC V1.0 10-02-2013
# This tool will search and synchronize a webpage and postgres database on a Linux Server
# The Supported Operating Systems are Linux / CentOS / RedHat

HOST="$HOST"
USR="$USER"
PWD="$PASSWORD"
DB="$DBNAME"
DATA=`date --d='yesterday' +'%Y%m%d'`
FILE=$DATA'_pgsqldump.sql.gz'

LOCALWEB="/var/www/html/"
LOCALDB="/home/"


# first dir cfg
REMOTEWEB1="//var/www/html/YOURNAME1"

expect -c "
    set timeout 7200
    spawn rsync -avz -e ssh $USER@$HOST://var/www/html/learnway $LOCALWEB
    expect {
    password: {send \"$PWD\r\"; exp_continue }
    }
"

# second dir cfg
REMOTEWEB2="//var/www/html/YOURNAME2"

expect -c "
   set timeout 7200
   spawn rsync -avz -e ssh $USER@$HOST://var/www/html/symfony $LOCALWEB
   expect {
   password: {send \"$PWD\r\"; exp_continue }
   }
"

# db cfg
REMOTEDB="//home/backups/postgres/$FILE"

expect -c "
     set timeout 17200
     spawn scp -c blowfish $USER@$HOST:$REMOTEDB $LOCALDB
     expect {
     password: { send \"$PWD\r\"; exp_continue }    
     }
"

# unpack db
expect -c "
    spawn gunzip $FILE
    expect {
    EOF { exp_continue }
    }
"

mv $DATA'_pgsqldump.sql' $FILE
gunzip $FILE

# db operations
dbname="$DB"
username="$DB"

psql -d $dbname -U postgres << EOF
DROP SCHEMA lw CASCADE;
EOF

psql -d $dbname -U postgres << EOF
CREATE SCHEMA lw;
EOF

psql -d $dbname -U postgres < /home/$DATA'_pgsqldump.sql'
