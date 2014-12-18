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
		<li><code>scidb_docker_XX.ini</code> - SciDB's configuration files. Here you can control things such as the number of instances (see table below).</li>
		<li><code>iquery.conf</code> - IQuery configuration file. IQuery is SciDB's native client able to process AQL and AFL queries.</li>
		<li><code>startScidb.sh</code> - Script for starting SciDB.</li>
		<li><code>stopScidb.sh</code> - Script for stopping SciDB.</li>
		<li><code>containerSetup.sh</code> - Commands for setting up SciDB inside a container. It also creates some test data.</li>
		<li><code>anomalyComputation.afl</code> - Array Functional Language instructions to calculate EVI2 anomalies.</li>		
	</ul>
        </li>
        <li>R scripts
	<ul>
                <li><code>anomalyHistogram.R</code> - Script for retrieving and ploting the resulting EVI2 anomaly histogram.</li>
                <li><code>exploreResults.R</code> - Script with general functions for retrieving and ploting the resulting EVI2 anomalies.</li>
                <li><code>installPackages.R</code> - R script for installing R packages.</li>
        </ul>
        </li>
	<li>Other files
	<ul>
		<li><code>installBoost_1570.shh</code> - Install Boost libraries.</li>
		<li><code>installGribModis2SciDB.sh</code> - Install a tool for exporting HDFs to SciDB's binary.</li>
                <li><code>installParallel.sh</code> - Script for installing parallel.Parallel allows to execute scripts at the same time.</li>
		<li><code>install_pyhdf.sh</code> - DEPRECATED - Install an interface for enabling python to handle HDFs.</li>
		<li><code>downloadData.R</code> - DEPRECATED - R script for downloading MODIS data from NASA website.</li>
		<li><code>downloadData.sh</code> - DEPRECATED - Script for downloading MODIS in parallel. It is a wrapper of <code>downloadData.R</code></li>
		<li><code>hdf2bin.sh</code> - DEPRECATED - Script for exporting HDFs to binary files. It is a wrapper of the python scripts available at <a href="http://github.com/albhasan/modis2scidb" target="_blank">modis2scidb</a>.</li>
	</ul>
	</li>
</ul>


<h3>Instructions:</h3>
<ol>
	<li>Clone this project <code>git clone https://github.com/albhasan/amazonGreenUp2005.git</code></li>
	<li>Setup SciDB on Docker and other required stuff:
		<ul>
			<li>Build a docker image <code>./setup.sh</code>. This script will build the Docker image <em>scidb_amazon_img</em> and it will start the Docker container <em>scidb_amazon1</em>.</li>
			<li>Login the SciDB Docker container <em>scidb_amazon1</em> by using <code>ssh -p 49901 root@localhost</code>. The default password is <em>xxxx.xxxx.xxxx</em></li>
		</ul>
	</li>
	<li>Run the container script using one of the SciDB configuration file names as a parameter, for example: <code>/home/root/./containerSetup.sh scidb_docker_2a.ini</code>.</li>
	<li>The array with the results is <code>MODIS_AMZ_EVI2_ANOM</code></li>
	<li>You can use <code>exploreResults.R</code> to get the computation results in R, either form the container or the host.</li>
</ol>


<h5>SciDB setup configurations files:</h5>
<table>
  <tr>
    <th>Name</th>
    <th>Instances per server<br></th>
    <th>Max concurrent connections<br></th>
    <th>CPU cores per server<br></th>
    <th>GB per server<br></th>
  </tr>
  <tr>
    <td>scidb_docker_1.ini</td>
    <td>1<br></td>
    <td>2</td>
    <td>2</td>
    <td>2</td>
  </tr>
  <tr>
    <td>scidb_docker_2.ini</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>4</td>
  </tr>
  <tr>
    <td>scidb_docker_2a.ini</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>8</td>
  </tr>
  <tr>
    <td>scidb_docker_2b.ini</td>
    <td>2</td>
    <td>2</td>
    <td>4</td>
    <td>16</td>
  </tr>
  <tr>
    <td>scidb_docker_4.ini</td>
    <td>4</td>
    <td>4</td>
    <td>4</td>
    <td>16</td>
  </tr>
  <tr>
    <td>scidb_docker_8.ini</td>
    <td>8</td>
    <td>16</td>
    <td>24</td>
    <td>160</td>
  </tr>
</table>
