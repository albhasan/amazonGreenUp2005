###########################################################
# DOWNLOADS HDF DATA
#Rscript downloadData.R product=MOD09Q1 collection=005 begin=2000.02.01 end=2000.04.01 tileH=11:11 tileV=9:9 wait=1
###########################################################
#Get arguments
argsep <- "="
keys <- vector(mode = "character", length = 0)
values <- vector(mode = "character", length = 0)
#commandArgs <- c("uno=1", "dos=2")
for (arg in commandArgs()){
  if(agrep(argsep, arg) == TRUE){
    pair <- unlist(strsplit(arg, argsep))
    keys <- append(keys, pair[1], after = length(pair))
    values <- append(values, pair[2], after = length(pair))
  }
}

#cat("\n-----------------\n")
#matrix(data = cbind(keys, values), ncol = 2, byrow = FALSE)
#cat("\n-----------------\n")

product <- values[which(keys == "product")]
begin <- values[which(keys == "begin")]
end <- values[which(keys == "end")]
tileH <- values[which(keys == "tileH")]
tileV <- values[which(keys == "tileV")]
collection <- values[which(keys == "collection")]
wait <- values[which(keys == "wait")]

if(agrep(":", tileH) == TRUE){
  pair <- unlist(strsplit(tileH, ":"))
  tileH <- seq(from = as.numeric(pair[1]), to = as.numeric(pair[2]), by = 1)
}else{
  tileH <- as.numeric(tileH)
}
if(agrep(":", tileV) == TRUE){
  pair <- unlist(strsplit(tileV, ":"))
  tileV <- seq(from = as.numeric(pair[1]), to = as.numeric(pair[2]), by = 1)
}else{
  tileV <- as.numeric(tileV)
}

# Downloads data
library(MODIS)
#MODISoptions(localArcPath, outDirPath, pixelSize, outProj, resamplingType, dataFormat, gdalPath, MODISserverOrder, dlmethod, stubbornness, systemwide = FALSE, quiet = FALSE, save=TRUE, checkPackages=TRUE)
res <- getHdf(product = product, begin = begin, end = end, tileH = tileH, tileV = tileV, collection = collection, wait = wait, quiet = FALSE, checkIntegrity = TRUE)  
