###########################################################
# DOWNLOADS HDF DATA
###########################################################
#Set up
prod <- "MOD09Q1"
col <- "005"
fromDate <- "2000.01.01"
toDate <- "2000.03.01"
tH <- 10:10
tV <-8:8
waitTime = 1
pkgs <- c("RCurl", "snow", "ptw", "bitops", "mapdata", "XML", "rgeos", "rgdal", "MODIS")
repos <- c("http://cran.us.r-project.org", 
          "http://cran.r-mirror.de/", 
          "http://www.laqee.unal.edu.co/CRAN/", 
          "http://ftp.iitm.ac.in/cran/",
          "http://cran.mirror.ac.za/",
          "http://cran.ms.unimelb.edu.au/", 
          "http://R-Forge.R-project.org")
###########################################################

install.packages(pkgs = pkgs, repos = repos)

library(MODIS)
#MODISoptions(localArcPath, outDirPath, pixelSize, outProj, resamplingType, dataFormat, gdalPath, MODISserverOrder, dlmethod, stubbornness, systemwide = FALSE, quiet = FALSE, save=TRUE, checkPackages=TRUE)
res <- getHdf(product = prod, begin = fromDate, end = toDate, tileH = tH, tileV = tV, collection = col, wait = waitTime)  
