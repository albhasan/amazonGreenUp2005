#!/bin/bash
echo "************************************************************************"
echo "SCIDB CONFIGURATION"
echo "************************************************************************"
export LC_ALL="en_US.UTF-8"
export SCIDB_VER=14.3
export PATH=$PATH:/opt/scidb/$SCIDB_VER/bin:/opt/scidb/$SCIDB_VER/share/scidb
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/scidb/$SCIDB_VER/lib:/opt/scidb/$SCIDB_VER/3rdparty/boost/lib
/etc/init.d/shimsvc start
echo "************************************************************************"
echo "Updating the container-user id to match host-user id..."
echo "************************************************************************"
export NEW_SCIDB_UID=1004
export NEW_SCIDB_GID=1004
OLD_SCIDB_UID=$(id -u scidb)
OLD_SCIDB_GID=$(id -g scidb)
usermod -u $NEW_SCIDB_UID -U scidb
groupmod -g $NEW_SCIDB_GID scidb	
find / -uid $OLD_SCIDB_UID -exec chown -h $NEW_SCIDB_UID {} +
find / -gid $OLD_SCIDB_GID -exec chgrp -h $NEW_SCIDB_GID {} +
echo "************************************************************************"
echo "Moving PostGRESQL files..."
echo "************************************************************************"
/etc/init.d/postgresql stop
cp -aR /var/lib/postgresql/8.4/main /home/scidb/catalog/main
rm -rf /var/lib/postgresql/8.4/main
ln -s /home/scidb/catalog/main /var/lib/postgresql/8.4/main
/etc/init.d/postgresql start
echo "************************************************************************"
echo "Setting up poasswordless SSH..."
echo "************************************************************************"
sudo su scidb
cd ~
yes | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
sshpass -f pass.txt ssh-copy-id "scidb@localhost -p 49901"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "scidb@0.0.0.0 -p 49901"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "scidb@127.0.0.1 -p 49901"
rm /home/scidb/pass.txt
echo "************************************************************************"
echo "Starting SciDB..."
echo "************************************************************************"
exit
/etc/init.d/postgresql restart
cd /tmp && sudo -u postgres /opt/scidb/14.3/bin/scidb.py init_syscat scidb_docker_2a
sudo su scidb
cd ~
export SCIDB_VER=14.3
export PATH=$PATH:/opt/scidb/$SCIDB_VER/bin:/opt/scidb/$SCIDB_VER/share/scidb
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/scidb/$SCIDB_VER/lib:/opt/scidb/$SCIDB_VER/3rdparty/boost/lib
/home/scidb/./startScidb.sh
sed -i 's/yes/#yes/g' /home/scidb/startScidb.sh
echo "************************************************************************"
echo "Testing SciDB using IQuery..."
echo "************************************************************************"
iquery -naq "store(build(<num:double>[x=0:4,1,0, y=0:6,1,0], random()),TEST_ARRAY)"
iquery -aq "list('arrays')"
iquery -aq "scan(TEST_ARRAY)"

echo "Finished installing SciDB!" 