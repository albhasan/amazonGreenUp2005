library(scidb)
library(sp)
library(maps)
library(maptools)
library(rgdal)


######################################################
# Auxiliary functions
######################################################
calcTileWidth <- function(){
  #Calculates the width of a MODIS tile
  #https://code.env.duke.edu/projects/mget/wiki/SinusoidalMODIS
  modisHtiles <- 36
  #modisVtiles <- 18
  corner.ul.x <- -20015109.354
  #corner.ul.y <- 10007554.677
  corner.lr.x <- 20015109.354
  #corner.lr.y <- -10007554.677
  tile.width <- (corner.lr.x - corner.ul.x) / modisHtiles
  #tile.height <- (corner.lr.y - corner.ul.y) / modisVtiles
  #tile.height <- tile.width # Tiles seem to be squared
  return(tile.width)
}
calcPixelSize <- function(resolution, tileWidth){
  #Calculates the length of a MODIS pixel. Resolution is the number of pixel in one dimension (e.g 4800)
  #https://code.env.duke.edu/projects/mget/wiki/SinusoidalMODIS
  #earth.radius <- 6371007.181 # MODIS synusoidal parameter - SPHERICAL EARTH!
  #tile.rows <- resolution#4800
  #tile.cols <- tile.rows
  #---------------------
  cell.size <- tileWidth / resolution
}
getxyMatrix <- function(colrowid.Matrix, pixelSize){
  #Returns the coords (MODIS synusoidal) of the center of the given pixel
  #SR-ORG:6974
  x <- vector(mode = "numeric", length = length(nrow(colrowid.Matrix)))
  y <- vector(mode = "numeric", length = length(nrow(colrowid.Matrix)))
  corner.ul.x <- -20015109.354
  corner.ul.y <- 10007554.677
  x <- corner.ul.x + (pixelSize/2) + (colrowid.Matrix[,1] * pixelSize)
  y <- corner.ul.y - (pixelSize/2) - (colrowid.Matrix[,2] * pixelSize)
  cbind(x,y)
}
######################################################
# Worker
######################################################

# Connect to SciDB
scidbconnect(host = "localhost", port = 49912, username = "scidb", password = "xxxx.xxxx.xxxx")

#Pixel size estimation
resolution <- 4800 # Number of pixels on the x and y direction (per image or HDF)
tileWidth <- calcTileWidth()

# Display array's properties
str(scidb("MODIS_AMZ_EVI2_ANOM"))

# Retrive brazilian borders
modsin.crs <- CRS("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs ")
amazonCountriesNames <- c("Brazil", "Colombia", "Venezuela", "Ecuador", "Peru", "Bolivia", "Guyana", "Suriname", "French Guiana")
amazonCountries.map <- map("world", amazonCountriesNames, fill = TRUE, col="transparent", plot = FALSE)
IDs <- sapply(strsplit(amazonCountries.map$names, ":"), function(x) x[1])
amazonCountries.sp <- map2SpatialPolygons(amazonCountries.map, IDs=IDs,proj4string=CRS("+proj=longlat +datum=WGS84"))
amazonCountriesNames.df <- data.frame(sapply(1:length(amazonCountries.sp), function(n){slot(slot(amazonCountries.sp[n], "polygons")[[1]], "ID")}, simplify = TRUE))
amazonCountries.spdf <- SpatialPolygonsDataFrame(amazonCountries.sp, amazonCountriesNames.df, match.ID = FALSE)
amazonPolDov.spdf <- spTransform(amazonCountries.spdf, modsin.crs)

######################################################
# Plot a grid mean
######################################################

regridfactor <- 256 # 16
pixelSize <- calcPixelSize(resolution, tileWidth) * regridfactor

#Whole array indexes
col_id.from <- 48000 / regridfactor
row_id.from <- 38400 / regridfactor

#Retrieve data
query <- paste("regrid(MODIS_AMZ_EVI2_ANOM,", regridfactor, ",", regridfactor, ", avg(evi_anomaly) as evi_anomaly_avg)")
evi2.anom <- iquery(query = query, `return` = TRUE, afl = TRUE, iterative = FALSE, n = Inf)
#cp <- evi2.anom
#evi2.anom <- cp


# Restore indexes' values
evi2.anom["col_id"] <- col_id.from +  evi2.anom["col_id"] - (col_id.from * regridfactor)
evi2.anom["row_id"] <- row_id.from +  evi2.anom["row_id"] - (row_id.from * regridfactor)

# Calculate coords
xy <- getxyMatrix(cbind(colrowid.Matrix = evi2.anom["col_id"], evi2.anom["row_id"]), pixelSize = pixelSize)
evi2.anom <- cbind(evi2.anom, xy)

# Build an SpatialPointsDataFrame
evi2.sp <- SpatialPoints(coords = evi2.anom[, c("x", "y")])
bbox(evi2.sp)





#areOver <- over(evi2.sp, SpatialPolygons(slot(amazonPolDov.spdf, "polygons")))
#areOver[is.na(areOver)] <- FALSE
#areOver[!is.na(areOver)] <- TRUE
#plot(evi2.sp[areOver])





evi2.spdf = SpatialPointsDataFrame(evi2.sp, evi2.anom["evi_anomaly_avg"])
modsin.crs <- CRS("+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs ")
proj4string(evi2.spdf) <- modsin.crs

# Plot 
sd <- sd(unlist(slot(evi2.spdf, "data")))
breaks <- c(-2, -1.5, -1, 1, 1.5, 2) * sd
bcolors <- c("#481316", "#E51D24", "#F47E56", "#F7F7B6", "#58B734", "#259B43", "#184621")
lo <- list(sp.polygons, amazonPolDov.spdf, first = FALSE)
spplot(evi2.spdf, col.regions = bcolors, at = breaks, pretty = TRUE, sp.layout = lo, cuts = 7)
#spplot(evi2.spdf[areOver], col.regions = bcolors, at = breaks, pretty = TRUE, sp.layout = lo, cuts = 7)

######################################################
# Plot a subarray on the border Brazil-Colombia
######################################################
pixelSize <- calcPixelSize(resolution, tileWidth)
#Subarray indexes
col_id.from <- 52800
row_id.from <- 43200
col_id.to <- col_id.from + 100
row_id.to <- row_id.from + 100

# Retrieve data
col <- c(48000, 67199)
row <- c(38400, 52799)
(col[2] - col[1] + 1)/4
(row[2] - row[1] + 1)/4
query <- paste("subarray(project(MODIS_AMZ_EVI2_ANOM, evi_anomaly),", paste(col_id.from, row_id.from, col_id.to, row_id.to, sep = ","), ");")
evi2.anom <- iquery(query = query, `return` = TRUE, afl = TRUE, iterative = FALSE, n = Inf)

# Restore indexes' values
evi2.anom["col_id"] <- evi2.anom["col_id"] + col_id.from
evi2.anom["row_id"] <- evi2.anom["row_id"] + row_id.from

# Calculate coords
xy <- getxyMatrix(cbind(evi2.anom["col_id"], evi2.anom["row_id"]), pixelSize)
evi2.anom <- cbind(evi2.anom, xy)

# Build an SpatialPointsDataFrame
evi2.sp <- SpatialPoints(coords = evi2.anom[, c("x", "y")])
bbox(evi2.sp)
evi2.spdf = SpatialPointsDataFrame(evi2.sp, evi2.anom["evi_anomaly"])
proj4string(evi2.spdf) <- modsin.crs

# Plot 
sd <- sd(unlist(slot(evi2.spdf, "data")))
breaks <- c(-2, -1.5, -1, 1, 1.5, 2) * sd
bcolors <- c("#481316", "#E51D24", "#F47E56", "#F7F7B6", "#58B734", "#259B43", "#184621")
lo <- list(sp.polygons, amazonPolDov.spdf, first = FALSE)
spplot(evi2.spdf, col.regions = bcolors, at = breaks, pretty = TRUE, sp.layout = lo, cuts = 7)





