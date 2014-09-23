#!/bin/bash
echo "************************************************************************"
echo "DOWNLOAD MODIS DATA"
#./downloadData.sh MOD09Q1 005 2000 2006 07.01 09.30 11:11 9:9 1
echo "************************************************************************"
export LC_ALL="en_US.UTF-8"
PRODUCT=$1
COLLECTION=$2
FROMYEAR=$3
TOYEAR=$4
FROMMONTHDAY=$5
TOMONTHDAY=$6
TILEH=$7
TILEV=$8
WAIT=$9

eval "parallel --no-notice --xapply Rscript /home/scidb/downloadData.R product=$PRODUCT collection=$COLLECTION begin={1}.$FROMMONTHDAY end={2}.$TOMONTHDAY tileH=$TILEH tileV=$TILEV wait=$WAIT ::: {$FROMYEAR..$TOYEAR} ::: {$FROMYEAR..$TOYEAR}"
echo "Finished downloading MODIS data!"
