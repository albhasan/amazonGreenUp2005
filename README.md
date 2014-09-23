amazonGreenUp2005
=================

Reproduction of the computations on the article "Amazon Forest Green-Up During 2005 Drought"


<h3>Pre-requisites:</h3>
<ul>
<li>Docker.io</li>
<li>SSH</li>
<li>Internet access</li>
</ul>



<h3>Files:</h3>
<ul>
	<li><code>LICENSE</code> - License file.</li>
	<li><code>README.md</code> - This file.</li>
	
	<li>Docker-related files
	<ul>
		<li><code>setup.sh</code> - (host) Script for generating a docker image.</li>
		<li><code>Dockerfile</code> - (host) Docker file for building a Docker Image.</li>
	</ul>
	</li>
	<li>SciDB-related files:
	<ul>
		<li><code>conf</code> - SHIM configuration file. SHIM is SciDB's web service</li>
		<li><code>config.ini</code> - SciDB's configuration file. Here you can control things such as the number of instances (see table below).</li>
		<li><code>iquery.conf</code> - IQuery configuration file. IQuery is SciDB's native client able to process AQL and AFL queries.</li>
		<li><code>startScidb.sh</code> - Script for starting SciDB.</li>
		<li><code>stopScidb.sh</code> - Script for stopping SciDB.</li>
		<li><code>.pam_environment</code> - User's environmental variable file. Stores variables required for IQuery.</li>
		<li><code>containerSetup.sh</code> - Commands for setting up SciDB inside a container. It also creates some test data.</li>
		<li><code>anomalyComputation.afl</code> - Array Functional Language instructions to calculate EVI2 anomalies.</li>		
	</ul>
	</li>
	<li>Other files
	<ul>
		<li><code>install_pyhdf.sh</code> - Install an interface for enabling python to handle HDFs.</li>
		<li><code>installParallel.sh</code> - Script for installing parallel.Parallel allows to execute scripts at the same time.</li>
		<li><code>installPackages.R</code> - R script for installing R packages.</li>
		<li><code>downloadData.R</code> - R script for downloading MODIS data from NASA website.</li>
		<li><code>downloadData.sh</code> - Script for downloading MODIS in parallel. It is a wrapper of <code>downloadData.R</code></li>
		<li><code>hdf2bin.sh</code> - Script for exporting HDFs to binary files. It is a wrapper of the python scripts available at <a href="http://github.com/albhasan/modis2scidb" target="_blank">modis2scidb</a>.</li>
	</ul>
	</li>
</ul>


<h3>Instructions:</h3>
<ol>
<li>Clone this project <code>git clone https://github.com/albhasan/amazonGreenUp2005.git</code></li>
<li>Setup SciDB on Docker and other required stuff:
	<ul>
		<li>Build a docker image <code>./setup.sh</code>. This script will build the Docker image <em>scidb_img</em> and it will start the Docker container <em>scidb1</em>.</li>
		<li>Login the SciDB Docker container <em>scidb1</em> by using <code>ssh -p 49901 root@localhost</code>. The default password is <em>xxxx.xxxx.xxxx</em></li>
		<li>Install parallel: <code>/home/root/./installParallel.sh</code></li>
		<li>Install pyhdf: <code>yes | /home/root/./install_pyhdf.sh</code></li>
		<li>Install the required R Packages: <code>Rscript /home/root/installPackages.R packages=RCurl,snow,ptw,bitops,mapdata,XML,rgeos,rgdal,MODIS,scidb verbose=0 quiet=0</code></li>		
		<li>Run the commands in <em>/home/root/containerSetup.sh</em>. <b>NOTE</b>: You need to copy & paste the commands to a terminal.</li>
	</ul>
</li>
<li>Download MODIS' HDFs to the container:
	<ul>
<li>Run the script <code>./downloadData.sh MOD09Q1 005 2000 2006 07.01 09.30 10:13 8:10 1</code>. This will download the required information from NASA servers and it will take hours or even days!</li>
	</ul>
</li>
<li>Load HDFs to SciDB:
	<ul>
	<li>As the <em>scidb</em> user clone the project <em>modis2scidb</em> using <code>git clone http://github.com/albhasan/modis2scidb.git</code></li>
	<li>Create the destination array <code>iquery -q "CREATE ARRAY MOD09Q1_SALESKA &lt;red:int16, nir:int16, quality:uint16&gt; [col_id=48000:72000,1014,5,row_id=38400:62400,1014,5,time_id=0:9200,1,0];"</code></li>
	<li>Run the folder monitor <code>python /home/scidb/modis2scidb/checkFolder.py --log INFO /home/scidb/toLoad/ /home/scidb/modis2scidb/ MOD09Q1_SALESKA &</code></li>
	<li>Run the HDF export script <code>./hdf2bin.sh /home/scidb/MODIS_ARC/MODIS/MOD09Q1.005/ 2000 2006 10 13 8 10 R-MODIS /home/scidb/ /home/scidb/toLoad/ INFO</code></li>
	</ul>
</li>
<li>Compute the anomalies: <code>iquery -f anomalyComputation.afl</code></li>
</ol>


<h3>Notes:</h3>
<ul>
	<li><b>SciDB setup</b>. The default setting is <em>scidb_docker_2a</em> (see table below). You can add your own configuration to the file <code>config.ini</code> and update the files <code>config.ini</code>, <code>startScidb.sh</code>, and <code>stopScidb.sh</code>. For example, to switch to the "scidb_docker_8" setup:
		<ul>
			<li>Review the contents of <code>config.ini</code> under <em>[scidb_docker_8]</em>.</li>
			<li>Change the line <code>cd /tmp && sudo -u postgres /opt/scidb/14.3/bin/scidb.py init_syscat scidb_docker_2a</code> for <code>cd /tmp && sudo -u postgres /opt/scidb/14.3/bin/scidb.py init_syscat scidb_docker_8</code></li>
			<li>Replace the ocurrences of <code>scidb_docker_2a</code> for <code>scidb_docker_8</code> on the files <code>startScidb.sh</code> and <code>stopScidb.sh</code></li>
		</ul>
	</li>
</ul>

<h5>SciDB setup options available in <code>config.ini</code>:</h5>
<table>
  <tr>
    <th>Name</th>
    <th>Instances per server<br></th>
    <th>Max concurrent connections<br></th>
    <th>CPU cores per server<br></th>
    <th>GB per server<br></th>
  </tr>
  <tr>
    <td>scidb_docker_1</td>
    <td>1<br></td>
    <td>2</td>
    <td>2</td>
    <td>2</td>
  </tr>
  <tr>
    <td>scidb_docker_2</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>4</td>
  </tr>
  <tr>
    <td>scidb_docker_2a</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>8</td>
  </tr>
  <tr>
    <td>scidb_docker_2b</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>16</td>
  </tr>
  <tr>
    <td>scidb_docker_4</td>
    <td>4</td>
    <td>4</td>
    <td>4</td>
    <td>16</td>
  </tr>
  <tr>
    <td>scidb_docker_8</td>
    <td>8</td>
    <td>16</td>
    <td>24</td>
    <td>160</td>
  </tr>
</table>
