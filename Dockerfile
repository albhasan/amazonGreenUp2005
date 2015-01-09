# AMAZON GREEN UP ON SciDB 14.8
#
# VERSION 1.0
#
#
#
#
#
#
#PORT MAPPING
#SERVICE		DEFAULT		MAPPED
#ssh 			22			49911
#shim			8083s		49912
#Postgresql	 	5432		49913
#SciDB			1239		49914


FROM ubuntu:12.04
MAINTAINER Alber Sanchez


RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu precise/" >> /etc/apt/sources.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
# install
RUN apt-get -qq update && apt-get install --fix-missing -y --force-yes \
	openssh-server \
	sudo \
	wget \
	gdebi \
	nano \  
	postgresql-8.4 \ 
	sshpass \ 
	git-core \ 
	apt-transport-https \
	imagemagick \ 
	r-base \
	r-base-dev \
	r-cran-spatial


# Set environment
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
RUN env


# Configure users
RUN useradd --home /home/scidb --create-home --uid 1005 --group sudo --shell /bin/bash scidb
RUN echo 'root:xxxx.xxxx.xxxx' | chpasswd
RUN echo 'postgres:xxxx.xxxx.xxxx' | chpasswd
RUN echo 'scidb:xxxx.xxxx.xxxx' | chpasswd
RUN echo 'xxxx.xxxx.xxxx'  >> /home/scidb/pass.txt


RUN mkdir /var/run/sshd
RUN mkdir /home/scidb/data
RUN mkdir /home/scidb/catalog
RUN mkdir /home/scidb/toLoad
RUN mkdir /home/scidb/toLoad/modis
RUN mkdir /home/scidb/toLoad/trmm


# Configure SSH
RUN sed -i 's/22/49911/g' /etc/ssh/sshd_config
RUN echo 'StrictHostKeyChecking no' >> /etc/ssh/ssh_config


# Configure Postgres 
RUN echo 'host  all all 255.255.0.0/16   md5' >> /etc/postgresql/8.4/main/pg_hba.conf
RUN sed -i 's/5432/49913/g' /etc/postgresql/8.4/main/postgresql.conf


# Add files
ADD containerSetup.sh 		/root/containerSetup.sh
ADD conf	 		/root/conf
#ADD install_pyhdf.sh           /root/install_pyhdf.sh
ADD installParallel.sh		/root/installParallel.sh
ADD installBoost_1570.sh	/root/installBoost_1570.sh
ADD installGribModis2SciDB.sh	/root/installGribModis2SciDB.sh
ADD hdf2bin.sh                  /home/scidb/hdf2bin.sh
ADD iquery.conf 		/home/scidb/.config/scidb/iquery.conf
ADD startScidb.sh 		/home/scidb/startScidb.sh
ADD stopScidb.sh 		/home/scidb/stopScidb.sh
ADD installPackages.R 		/home/scidb/installPackages.R
ADD hdf2bin.sh 			/home/scidb/hdf2bin.sh
ADD anomalyComputation.afl 	/home/scidb/anomalyComputation.afl
ADD scidb_docker_1.ini          /home/scidb/scidb_docker_1.ini
ADD scidb_docker_2a.ini         /home/scidb/scidb_docker_2a.ini
ADD scidb_docker_2b.ini         /home/scidb/scidb_docker_2b.ini
ADD scidb_docker_2.ini          /home/scidb/scidb_docker_2.ini
ADD scidb_docker_4.ini          /home/scidb/scidb_docker_4.ini
ADD scidb_docker_8.ini          /home/scidb/scidb_docker_8.ini
ADD scidb_docker_16.ini          /home/scidb/scidb_docker_16.ini
ADD scidb_docker_32.ini          /home/scidb/scidb_docker_32.ini



RUN chown -R root:root \ 
	/root/*.sh \ 
	/root/conf


RUN chown -R scidb:scidb /home/scidb/*


RUN chmod +x \ 
	/root/*.sh \ 
	/home/scidb/*.sh 


# Restarting services
RUN stop ssh
RUN start ssh
RUN /etc/init.d/postgresql restart


	
EXPOSE 49911
EXPOSE 49912


CMD    ["/usr/sbin/sshd", "-D"]
