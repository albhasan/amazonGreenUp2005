#!/bin/bash
export LC_ALL="en_US.UTF-8"
echo "#########################################################"
echo "SET UP OF AMAZON GREEN UP-SCIDB 14 ON A DOCKER CONTAINER"
# ./containerSetup.sh scidb_docker_8.ini
echo "#########################################################"


if [ "$#" -ne 1 ]; then
    echo "Illegal number of parameters"
	exit 1
fi
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
wget https://github.com/Paradigm4/deployment/archive/master.zip
unzip master.zip
cd /root/deployment-master/cluster_install
yes | ./cluster_install -s /home/scidb/$SCIDB_CONF_FILE
#********************************************************
echo "***** Installing additional packages..."
#********************************************************
Rscript /home/scidb/installPackages.R packages=scidb verbose=0 quiet=0
yes | /root/./installParallel.sh
yes | /root/./installBoost_1570.sh 
yes | /root/./installGribModis2SciDB.sh
ldconfig
wget -P /opt/scidb/14.8/lib/scidb/plugins https://dl.dropboxusercontent.com/u/25989010/scidbResources/libsavebmp.so
wget -P /opt/scidb/14.8/lib/scidb/plugins https://dl.dropboxusercontent.com/u/25989010/scidbResources/libgeosdb.so
#********************************************************
echo "***** Installing SHIM..."
#********************************************************
cd ~
wget http://paradigm4.github.io/shim/shim_14.8_amd64.deb
yes | gdebi -q shim_14.8_amd64.deb
rm /var/lib/shim/conf
mv /root/conf /var/lib/shim/conf
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
#parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/{2} ::: {1998..2006} ::: {182..246}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/182 ::: {1998..2006}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/183 ::: {1998..2006}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/213 ::: {1998..2006}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/214 ::: {1998..2006}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/244 ::: {1998..2006}
parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=4 --tries=50 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/245 ::: {1998..2006}
parallel -j 8 --no-notice wget -r -np --retry-connrefused --wait=1 --accept 'MOD09Q1.A200[0-6][1-2][0-9][0-9].h1[0-3]v[0-1][089]*' http://e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/{1}.0{2}.{0..3}{0..9}/ ::: {2000..2006} ::: {7..9}
#parallel -j 2 --no-notice wget -r -np --retry-connrefused --wait=2 --tries=30 ftp://disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/{1}/{2} ::: {1998..1998} ::: {182..246}
#parallel -j 8 --no-notice wget -r -np --retry-connrefused --wait=1 --accept 'MOD09Q1.A20001[0-9][0-9].h10v08*' http://e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/{1}.0{2}.0{0..9}/ ::: {2000..2001} ::: {7..8}

#TODO: Validate the number of downloaded files

#********************************************************
echo "***** ***** Downloading required scripts..."
#********************************************************
git clone http://github.com/albhasan/modis2scidb.git
git clone http://github.com/albhasan/scidb_geoTrans.git
iquery -aq "load_module('/home/scidb/scidb_geoTrans/geoTransformation.txt')"
#********************************************************
echo "***** ***** Creating load arrays..."
#********************************************************
iquery -q "CREATE ARRAY MOD09Q1_SALESKA <red:int16, nir:int16, quality:uint16> [col_id=48000:67199,1014,5,row_id=38400:52799,1014,5,time_id=0:9200,1,0];"
iquery -q "CREATE ARRAY TRMM_3B43_SALESKA <precipitation:float, relativeError:float, gaugeRelativeWeighting:int8> [col_id=0:399,512,0,row_id=0:1439,512,0,time_id=0:9200,1,0];"
#********************************************************
echo "***** ***** Loading data to arrays..."
#********************************************************
python /home/scidb/modis2scidb/checkFolder.py --log DEBUG /home/scidb/toLoad/modis/ /home/scidb/modis2scidb/ MOD09Q1_SALESKA MOD09Q1 &
python /home/scidb/modis2scidb/checkFolder.py --log DEBUG /home/scidb/toLoad/trmm/ /home/scidb/modis2scidb/ TRMM_3B43_SALESKA TRMM_3B43 &

#----------------------------------------------------------------------------------------------------------------------
# WORKAROUND - Change the TRMM file names for enabling the use of modis2scidb tool
find /home/scidb/disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43 -type f -name '*.HDF'| while read FN; do
  DFN=$(dirname "$FN")
  BFN=$(basename "$FN")
  NFN=TRMM${BFN}
  SIZE=${#BFN}
  if [ $SIZE = 19 ]; then
    NFNN=${NFN::-5}h00v00.000.7.hdf
  fi
  if [ $SIZE = 20 ]; then
    NFNN=${NFN::-6}h00v00.000.7.hdf
  fi
  mv "$FN" "$DFN/$NFNN"
done
#----------------------------------------------------------------------------------------------------------------------

find /home/scidb/disc2.nascom.nasa.gov/ftp/data/s4pa/TRMM_L3/TRMM_3B43/ -type f -name '*.hdf' -print | parallel -j +0 --no-notice --xapply python /home/scidb/modis2scidb/hdf2sdbbin.py --log DEBUG {} /home/scidb/toLoad/trmm/ TRMM3B43
find /home/scidb/e4ftl01.cr.usgs.gov/MOLT/MOD09Q1.005/ -type f -name '*.hdf' -print | parallel -j +0 --no-notice --xapply python /home/scidb/modis2scidb/hdf2sdbbin.py --log DEBUG {} /home/scidb/toLoad/modis/ MOD09Q1
#********************************************************
echo "***** ***** Waiting for finishing uploading files to SciDB..."
#********************************************************
COUNTER=$(find /home/scidb/toLoad/ -type f -name '*.sdbbin' -print | wc -l)
while [  $COUNTER -gt 0 ]; do
	echo "Waiting for finishing uploading files to SciDB. Files to go... $COUNTER"
	sleep 60
	let COUNTER=$(find /home/scidb/toLoad/ -type f -name '*.sdbbin' -print | wc -l)
done
#********************************************************
echo "***** ***** Removing array versions..."
#********************************************************
MOD09Q1_SALESKA_NVERSION=$(iquery -aq "versions(MOD09Q1_SALESKA);" | wc -l)
let MOD09Q1_SALESKA_NVERSION=$(($MOD09Q1_SALESKA_NVERSION - 2))
IQUERYCMD="iquery -aq \"remove_versions(MOD09Q1_SALESKA, $MOD09Q1_SALESKA_NVERSION);\""
eval $IQUERYCMD
TRMM_SALESKA_NVERSION=$(iquery -aq "versions(TRMM_3B43_SALESKA);" | wc -l)
let TRMM_SALESKA_NVERSION=$(($TRMM_SALESKA_NVERSION - 2))
IQUERYCMD="iquery -aq \"remove_versions(TRMM_3B43_SALESKA, $TRMM_SALESKA_NVERSION);\""
eval $IQUERYCMD
#********************************************************
echo "***** ***** Re-arrange TRMM..."
# TRMM data is not aligned
#********************************************************
#TODO: Is there a better way to do a Reverse-transpose-slice? - http://www.scidb.org/forum/viewtopic.php?f=11&t=1495
iquery -naq "store(redimension(attribute_rename(project(apply(unpack(TRMM_3B43_SALESKA, tmpId), ncol_id, int64(abs(row_id - 1439)), nrow_id, col_id + 0, ntime_id, time_id + 0), ncol_id, nrow_id, ntime_id, precipitation, relativeError, gaugeRelativeWeighting), ncol_id, col_id, nrow_id, row_id, ntime_id, time_id), <precipitation:float,relativeError:float,gaugeRelativeWeighting:int8> [col_id=0:1439,512,0,row_id=0:399,512,0,time_id=0:9200,1,0]), TRMM_3B43_SALESKA_FLIP);"
iquery -naq "remove(TRMM_3B43_SALESKA);"
iquery -naq "rename(TRMM_3B43_SALESKA_FLIP, TRMM_3B43_SALESKA);"
#********************************************************
echo "***** ***** Calculating EVI2-Rain anomalies..."
#********************************************************
iquery -f anomalyComputation.afl
rm /home/scidb/pass.txt
#********************************************************
echo "***** ***** Exporting EVI2 anomalies as an image..."
#********************************************************
convert /home/scidb/evi2anom.bmp /home/scidb/evi2anom.jpg
rm /home/scidb/evi2anom.bmp
convert /home/scidb/evi2anom.jpg -rotate 90 /home/scidb/evi2anom_rotated.jpg
rm /home/scidb/evi2anom.jpg
mv /home/scidb/evi2anom_rotated.jpg /home/scidb/evi2anom.jpg
EOF
#----------------
#********************************************************
echo "***** Amazon Green-up - SciDB setup finished "
#********************************************************




