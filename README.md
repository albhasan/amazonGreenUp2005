amazonGreenUp2005
=================

Reproduction of the computations on the article "Amazon Forest Green-Up During 2005 Drought"



Files:
<ul>
<li><code>LICENSE</code> - License file.</li>
<li><code>README.md</code> - This file.</li>

<li><code>conf</code> - SHIM configuration file.</li>
<li><code>config.ini</code> - SciDB's configuration file.</li>
<li><code>iquery.conf</code> - IQUERY configuration file.</li>
<li><code>startScidb.sh</code> - Container script for starting SciDB.</li>
<li><code>stopScidb.sh</code> - Container script for stopping SciDB.</li>
<li><code>.pam_environment</code> - User's environmental variable file.</li>

<li><code>containerSetup.sh</code> - Commands for setting up SciDB inside a container. It also creates some test data.</li>
<li><code>updatePortsPass.sh</code> - Host script for changing other scripts's configuration (ports, passwords, SciDB configuration)</li>
<li><code>Dockerfile</code> - Docker file for building a Docker Image.</li>
<li><code>setup.sh</code> - Host script for removing old containers and images from host machine.</li>
</ul>


<h3>Instructions:</h3>
<ol>
<li>Clone this project <code>git clone https://github.com/albhasan/amazonGreenUp2005.git</code></li>
<li>Setup SciDB on Docker</li>
	<ul>
	<li>Build a docker image <code>./setup.sh</code>. This script will build the Docker image <em>scidb_img</em> and it will start the Docker container <em>scidb1</em>.</li>
	<li>Login the SciDB Docker container <em>scidb1</em> by using <code>ssh -p 49901 root@localhost</code>. The default password is <em>xxxx.xxxx.xxxx</em><li>
	<li>Run the commands in <em>/home/root/containerSetup.sh</em>. NOTE: You need to copy & paste the commands to a terminal.</li>
	<ul>
<li>Download MODIS' HDFs to the container</li>
	<ul>
	<li>Change from root to the <em>scidb</em> user <code>su scidb</code></li>
	<li>Run the R script <code>Rscript /home/scidb/downloadData.R</code>. This will download the required information from NASA servers and can take hours or even days!</li>
	</ul>
<li>Load HDFs to SciDB</li>
	<ul>
	<li>As the <em>scidb</em> user clone the project <em>modis2scidb</em> using <code>git clone https://github.com/albhasan/modis2scidb.git</code></li>
	<li>Install support for <em>pyhdf</em> <code>modis2scidb/./install_pyhdf.sh</code></li>
	<li>Create the destination array <code>iquery -q "CREATE ARRAY MOD09Q1_SALESKA <red:int16, nir:int16, quality:uint16> [col_id=48000:72000,1014,5,row_id=38400:62400,1014,5,time_id=0:9200,1,0];"</code></li>
	<li>
	
	RUN THE SCRIPTS
	
	</li>
	<ul>
<li>Run the process on SciDB</li>
</ol>