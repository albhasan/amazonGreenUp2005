#!/bin/bash
echo "************************************************************************"
echo "BUILD AMAZON DOCKER IMAGE"
echo "************************************************************************"
echo "Removing old container and image..."
docker stop scidb1
docker rm scidb1
docker rmi scidb_img
echo "Building a new image..."
#docker build --rm=true --tag="scidb_img" .
docker build --tag="scidb_img" .
echo "Launching a new container..."
docker run -d --name="scidb1" -p 49901:49901 -p 49904:49904 --expose=49902 --expose=49910 scidb_img

#docker run -d --name="scidb1" -p 49901:49901 -p 49904:49904 --expose=49902 --expose=49910 -v /var/bliss/scidb/test/data:/home/scidb/data scidb_img
#docker run -d --name="scidb1" -p 49901:49901 -p 49904:49904 --expose=49902 --expose=49910 -v /var/bliss/scidb/test/data:/home/scidb/data -v /var/bliss/scidb/test/catalog:/home/scidb/catalog scidb_img 
#docker run -d --name="scidb1" -p 49901:49901 -p 49904:49904 --expose=49902 --expose=49910 -v /var/bliss/scidb/test/data:/home/scidb/data -v /var/bliss/scidb/test/catalog:/home/scidb/catalog -v /var/bliss/modis:/home/scidb/modis scidb_img 
#ssh -p 49901 root@localhost

echo "Finished building Amazon docker image"