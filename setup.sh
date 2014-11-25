#!/bin/bash
echo "************************************************************************"
echo "BUILD AMAZON DOCKER IMAGE"
echo "************************************************************************"
echo "Removing old container and image..."
docker stop scidb_amazon1
docker rm scidb_amazon1
docker rmi scidb_amazon_img
echo "Building a new image..."
docker build --rm=true --tag="scidb_amazon_img" .
#docker build --tag="scidb_amazon_img" .
echo "Launching a new container..."
docker run -d --name="scidb_amazon1" -p 49911:49911 -p 49912:49912 --expose=49913 --expose=49914 scidb_amazon_img

#docker run -d --name="scidb_amazon1" -p 49911:49911 -p 49912:49912 --expose=49913 --expose=49914 -v /var/bliss/scidb/test/data:/home/scidb/data scidb_amazon_img
#docker run -d --name="scidb_amazon1" -p 49911:49911 -p 49912:49912 --expose=49913 --expose=49914 -v /var/bliss/scidb/test/data:/home/scidb/data -v /var/bliss/scidb/test/catalog:/home/scidb/catalog scidb_amazon_img
#docker run -d --name="scidb_amazon1" -p 49911:49911 -p 49912:49912 --expose=49913 --expose=49914 -v /var/bliss/scidb/test/data:/home/scidb/data -v /var/bliss/scidb/test/catalog:/home/scidb/catalog -v /var/bliss/modis:/home/scidb/modis scidb_amazon_img
#ssh -p 49911 root@localhost

echo "Finished building Amazon docker image"
