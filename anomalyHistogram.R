library(scidb)
scidbconnect(host="localhost", port=49912L, username = "scidb", password = "xxxx.xxxx.xxxx")
histdata <- iquery("scan(MODIS_TRMM_AMZ_EVIANOM_HISTOGRAM)", `return` = TRUE, afl = TRUE, iterative = FALSE, n = 10000)

#Frequency histogram
plot(x = unlist(histdata[,2]), y = unlist(histdata[,3]), type = "l", col = "blue", lwd = 2.5, xlab = "Standard deviation", ylab = "Frequency", main = "EVI2 anomaly distribution in drought areas")

