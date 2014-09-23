#!/bin/bash
echo "************************************************************************"
echo "EXPORT HDFs TO BINARY"
#./hdf2bin.sh /home/scidb/MODIS_ARC/MODIS/MOD09Q1.005/ 2000 2006 10 13 8 10 R-MODIS /home/scidb/ /home/scidb/toLoad/ INFO
echo "************************************************************************"
export LC_ALL="en_US.UTF-8"
MODISPATH=$1
FROMYEAR=$2
TOYEAR=$3
TILEHFROM=$4
TILEHTO=$5
TILEVFROM=$6
TILEVTO=$7
FILESCHEMA=$8
BASEFILEPATH=$9
LOADFOLDER=${10}
LOG=${11}

eval "parallel --no-notice --xapply python /home/scidb/modis2scidb/run.py -yf {1} -yt {2} --log INFO $MODISPATH $FILESCHEMA $BASEFILEPATH $LOADFOLDER $TILEHFROM $TILEHTO $TILEVFROM $TILEVTO ::: {$FROMYEAR..$TOYEAR} ::: {$FROMYEAR..$TOYEAR}"
echo "Finished exporting MODIS to binary!" 

