#!/bin/bash
export LC_ALL="en_US.UTF-8"
echo "#########################################################"
echo "SET UP OF AMAZON GREEN UP-SCIDB 14 ON A DOCKER CONTAINER"
# ./containerSetup.sh scidb_docker_8.ini
echo "#########################################################"

SCIDB_CONF_FILE=$1  # scidb_docker_8.ini


apt-get -qq update && apt-get install --fix-missing -y --force-yes \
	apt-utils \
	build-essential \
	cmake \
	libgdal-dev \
	gdal-bin \
	g++ \
	python-dev \
	autotools-dev \
	gfortran \
	libicu-dev \
	libbz2-dev \
	libzip-dev


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
Rscript /home/scidb/installPackages.R packages=scidb verbose=0 quiet=0
yes | /root/./installParallel.sh
yes | /root/./installBoost_1570.sh 
yes | /root/./installGribModis2SciDB.sh
ldconfig
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
export LC_ALL="en_US.UTF-8"
cd ~ 
sed -i 's/1239/49914/g' ~/.bashrc
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
wget -r -np --retry-connrefused --wait=0.5 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1998..2006}
wget -r -np --retry-connrefused --wait=0.5 --accept 'MOD09Q1.A200[0-6][1-2][0-9][0-9].h1[0-3]v[0-1][089]*' http://e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/{2000..2006}.0{7..9}.{0..3}{0..9}/ 
git clone http://github.com/albhasan/modis2scidb.git
#********************************************************
echo "***** ***** Creating load arrays..."
#********************************************************
iquery -q "CREATE ARRAY MOD09Q1_SALESKA <red:int16, nir:int16, quality:uint16> [col_id=48000:67199,1014,5,row_id=38400:52799,1014,5,time_id=0:9200,1,0];"
iquery -q "CREATE ARRAY TRMM_3B43_SALESKA <precipitation:float, relativeError:float, gaugeRelativeWeighting:int8> [col_id=0:399,512,0,row_id=0:1439,512,0,time_id=0:9200,1,0];"
#********************************************************
echo "***** ***** Loading data to arrays..."
#********************************************************
python /home/scidb/modis2scidb/checkFolder.py --log INFO /home/scidb/toLoad/modis/ /home/scidb/modis2scidb/ MOD09Q1_SALESKA MOD09Q1 &
python /home/scidb/modis2scidb/checkFolder.py --log INFO /home/scidb/toLoad/trmm/ /home/scidb/modis2scidb/ TRMM_3B43_SALESKA TRMM_3B43 &



#----------------------------------------------------------------------------------------------------------------------
#DID GRibeiro fix the bug?
# GAMBIADA - remove dots from paths
#cd /home/scidb/e4ftl01crusgsgov/MOLT/MOD09Q1005
#mv /home/scidb/e4ftl01.cr.usgs.gov /home/scidb/e4ftl01crusgsgov
#mv /home/scidb/e4ftl01crusgsgov/MOLT/MOD09Q1.005 /home/scidb/e4ftl01crusgsgov/MOLT/MOD09Q1005
#for dir in /home/scidb/e4ftl01crusgsgov/MOLT/MOD09Q1005/*/
#do
#    dir=${dir%*/}
#    mv ${dir} ${dir//./}
#done
#mv /home/scidb/disc2.nascom.nasa.gov /home/scidb/disc2nascomnasagov
#----------------------------------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------------------------------
# WORKAROUND - Change the TRMM file names for enabling the use of modis2scidb tool
find /home/scidb/disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43 -type f -name '*.HDF'| while read FN; do
  DFN=$(dirname "$FN")
  BFN=$(basename "$FN")
  NFN=TRMM${BFN}
  NFNN=${NFN::-5}h00v00.000.7.hdf
  mv "$FN" "$DFN/$NFN"
done
#----------------------------------------------------------------------------------------------------------------------


python /home/scidb/modis2scidb/hdf2sdbbin.py --log INFO e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/ /home/scidb/toLoad/modis/ MOD09Q1
python /home/scidb/modis2scidb/hdf2sdbbin.py --log INFO /home/scidb/disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/ /home/scidb/toLoad/trmm/ TRMM3B43






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
#TODO: PROCESS RAIN, includes traspose, resampling coordinte transformation---------------------------------------------
iquery -f anomalyComputation.afl
rm /home/scidb/pass.txt
EOF
#----------------
#********************************************************
echo "***** Amazon Green-up - SciDB setup finished "
#********************************************************
	

