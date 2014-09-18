###########################################################
# INSTALL PACKAGES
###########################################################
pkgs <- c("RCurl", "snow", "ptw", "bitops", "mapdata", "XML", "rgeos", "rgdal", "MODIS")
repos <- c("http://cran.us.r-project.org", 
          "http://cran.r-mirror.de/", 
          "http://www.laqee.unal.edu.co/CRAN/", 
          "http://ftp.iitm.ac.in/cran/",
          "http://cran.mirror.ac.za/",
          "http://cran.ms.unimelb.edu.au/", 
          "http://R-Forge.R-project.org")
install.packages(pkgs = pkgs, repos = repos, verbose = FALSE, quiet = TRUE)
