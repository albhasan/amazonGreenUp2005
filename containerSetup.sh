#!/bin/bash
export LC_ALL="en_US.UTF-8"
echo "#########################################################"
echo "SET UP OF AMAZON GREEN UP-SCIDB 14 ON A DOCKER CONTAINER"
# ./containerSetup.sh scidb_docker_2a.ini
echo "#########################################################"

SCIDB_CONF_FILE=$1  # scidb_docker_2a.ini

#********************************************************
echo "***** Update container-user ID to match host-user ID..."
#********************************************************
export NEW_SCIDB_UID=1004
export NEW_SCIDB_GID=1004
OLD_SCIDB_UID=$(id -u scidb)
OLD_SCIDB_GID=$(id -g scidb)
usermod -u $NEW_SCIDB_UID -U scidb
groupmod -g $NEW_SCIDB_GID scidb
find / -uid $OLD_SCIDB_UID -exec chown -h $NEW_SCIDB_UID {} +
find / -gid $OLD_SCIDB_GID -exec chgrp -h $NEW_SCIDB_GID {} +
#********************************************************
echo "***** Moving PostGres files..."
#********************************************************
/etc/init.d/postgresql stop
cp -aR /var/lib/postgresql/8.4/main /home/scidb/catalog/main
rm -rf /var/lib/postgresql/8.4/main
ln -s /home/scidb/catalog/main /var/lib/postgresql/8.4/main
/etc/init.d/postgresql start
#********************************************************
echo "***** Installing additional packages..."
#********************************************************
Rscript /home/scidb/installPackages.R packages=RCurl,snow,ptw,bitops,mapdata,XML,rgeos,rgdal,raster,scidb verbose=0 quiet=0


wget http://download.r-forge.r-project.org/src/contrib/MODIS_0.10-18.tar.gz
R CMD INSTALL MODIS_0.10-18.tar.gz


yes | /home/root/./installParallel.sh
yes | /home/root/./install_pyhdf.sh
#********************************************************
echo "***** Setting up passwordless SSH..."
#********************************************************
yes | ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
sshpass -f /home/scidb/pass.txt ssh-copy-id "root@localhost -p 49911"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "root@0.0.0.0 -p 49911"
yes | ssh-copy-id -i ~/.ssh/id_rsa.pub  "root@127.0.0.1 -p 49911"
#********************************************************
echo "***** Installing SciDB..."
#********************************************************
cd ~ 
wget https://github.com/Paradigm4/deployment/archive/14.8.zip
unzip 14.8.zip
cd /root/deployment-14.8/cluster_install
yes | ./cluster_install -s /home/scidb/$SCIDB_CONF_FILE
#********************************************************
echo "***** Installing SHIM..."
#********************************************************
cd ~ 
wget http://paradigm4.github.io/shim/shim_14.8_amd64.deb
yes | gdebi -q shim_14.8_amd64.deb
rm /var/lib/shim/conf
mv /home/root/conf /var/lib/shim/conf
rm shim_14.8_amd64.deb
/etc/init.d/shimsvc stop
/etc/init.d/shimsvc start
#----------------
#sudo su scidb
su scidb <<'EOF'
cd ~ 
#****************************************************************************************
sed -i 's/1239/49914/g' ~/.bashrc
#****************************************************************************************
source ~/.bashrc
#********************************************************
echo "***** ***** Starting SciDB..."
#********************************************************
yes | scidb.py initall scidb_docker
/home/scidb/./startScidb.sh
#********************************************************
echo "***** ***** Testing SciDB installation using IQuery..."
#********************************************************
iquery -naq "store(build(<num:double>[x=0:4,1,0, y=0:6,1,0], random()),TEST_ARRAY)"
iquery -aq "list('arrays')"
iquery -aq "scan(TEST_ARRAY)"
#********************************************************
echo "***** ***** Downloading MODIS data..."
#********************************************************
cd ~


./downloadData.sh MOD09Q1 005 2000 2006 07.01 09.30 10:13 8:10 1
#./downloadData.sh MOD09Q1 005 2000 2000 07.01 07.30 10:10 8:8 1


git clone http://github.com/albhasan/modis2scidb.git
iquery -q "CREATE ARRAY MOD09Q1_SALESKA <red:int16, nir:int16, quality:uint16> [col_id=48000:67199,1014,5,row_id=38400:52799,1014,5,time_id=0:9200,1,0];"
python /home/scidb/modis2scidb/checkFolder.py --log INFO /home/scidb/toLoad/ /home/scidb/modis2scidb/ MOD09Q1_SALESKA &
/home/scidb/./hdf2bin.sh /home/scidb/MODIS_ARC/MODIS/MOD09Q1.005/ 2000 2006 10 13 8 10 R-MODIS /home/scidb/ /home/scidb/toLoad/ INFO
#********************************************************
echo "***** ***** Waiting for finishing uploading files to SciDB..."
#********************************************************
COUNTER=$(ls -1 /home/scidb/toLoad/ | wc -l)
while [  $COUNTER -gt 0 ]; do
	echo "Waiting for finishing uploading files to SciDB. Files to go... $COUNTER"
	sleep 60
	let COUNTER=$(ls -1 /home/scidb/toLoad/ | wc -l)
done
#********************************************************
echo "***** ***** Removing array versions..."
#********************************************************
iquery -f "remove_versions(MOD09Q1_SALESKA, 84);"
#********************************************************
echo "***** ***** Calculating EVI2 anomalies..."
#********************************************************
iquery -f anomalyComputation.afl
rm /home/scidb/pass.txt
EOF
#----------------
#********************************************************
echo "***** Amazon Green-up - SciDB setup finished sucessfully!"
#********************************************************
