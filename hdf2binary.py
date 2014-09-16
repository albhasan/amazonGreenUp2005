import os
import sys
import fnmatch
import subprocess as subp
import datetime

#from datetime import date

#********************************************************
# UTIL
#********************************************************
def buildDoy(yearFrom, yearTo, period):
	'''Returns an int array containing the year-day-of-the-year set corresponding to the given year interval'''
	res = []
	
	for year in range(yearFrom, yearTo + 1):
		byear = year * 1000
		for i in range(0, 365/period + 1):
			res.append(byear + 1 + i * period)
	return res
	
def isLeapYear(year):
	'''Returns TRUE if the given year (int) is leap and FALSE otherwise'''
	leapyear = False
	if year % 4 != 0:
		leapyear = False
	elif year % 100 != 0:
		leapyear = True
	elif year % 400 == 0:
		leapyear = True
	else:
		leapyear = False
	return leapyear
	
def doy2date(yyyydoy):
	'''Returns an int array year-month-day (e.g [2001, 1, 1]) out of the given year-day-of-the-year (e.g 2001001)'''
	if len(str(yyyydoy)) == 7:
		year = int(str(yyyydoy)[:4])
		doy = int(str(yyyydoy)[4:])
		if doy > 0 and doy < 367:
			firstdayRegular = [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366]
			firstdayLeap = [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336, 367]
			if isLeapYear(year):
				firstday = firstdayLeap
			else:
				firstday = firstdayRegular
			for i in range(len(firstday) - 1):
				start = firstday[i]
				end = firstday[i + 1]
				if doy >= start and doy < end:
					month = i + 1
					break
			day = doy - firstday[month - 1] + 1
		res = [year, month, day]
	return res

def getHV(tile):
	'''Returns the h and v components (i.e ['08', '10']) from the given tile id. Use map to get int instead of strings. results = map(int, results)'''
	h = tile[1:3]
	v = tile[4:6]
	return [h, v]
	
def checkHdfName(file, head, yyyydoyFrom, yyyydoyTo, hFrom, hTo, vFrom, vTo, col, ext):
	'''Returns TRUE if the given file name (e.g MOD09Q1.A2013361.h13v10.005.2014006133008.hdf) fits in the given parameters'''
	res = False
	fnparts = file.split(".")
	if len(fnparts) == 6:
		yyydoy = int(fnparts[1][1:])
		if yyydoy >= yyyydoyFrom and yyydoy <= yyyydoyTo:
			hv = map(int, getHV(fnparts[2]))
			h = hv[0]
			v = hv[1]
			if h >= hFrom and h <= hTo and v >= vFrom and v <= vTo:
				if fnparts[0] == head:
					if fnparts[3] == col:
						if fnparts[5] == ext:
							res = True
	return res
	
def checkHdfName(file, head, Adoy, tile, col, ext):
	'''Checks filename for the right number of parts, extension, date (YYYDOY), tile, name start and collection'''
	res = False
	fnparts = file.split(".")
	if len(fnparts) == 6:
		if fnparts[1] == Adoy:
			if fnparts[2] == tile:
				if fnparts[0] == head:
					if fnparts[3] == col:
						if fnparts[5] == ext:
							res = True
	return res

def checkHdfName(file, splitStr, nParts, ext):
	'''Returns TRUE if the given filename has the right number of parts and extension. It returns FALSE otherwise'''
	res = False
	p = file.split(splitStr)
	if len(p) == nParts:
		if p[len(p) - 1] == ext:
			res = True
	return res

def isStringinList(aString, strList):
	'''Returns TRUE if the given string is part of the given list and FALSE otherwise'''
	res = False
	for s in strList:
		if aString == s:
			res = True
			break
	return res

def buildAdoyList(doyList):
	'''Returns the list adding an "A" to each element'''
	res = []
	for doy in doyList:
		res.append('A' + str(doy))
	return res;

def buildTileLits(hRange, vRange):
	'''Return a list of MODIS tile names built from the given ranges'''
	res = []
	for h in hRange:
		for v in vRange:
			htmp = str(h)
			vtmp = str(v)
			if len(htmp) < 2:
				htmp = '0' + htmp
			if len(vtmp) < 2:
				vtmp = '0' + vtmp
			tmp = 'h' + htmp + 'v' + vtmp
			res.append(tmp)
	return res
	
def buildBinaryFilePath(basebfilepath, hRange, vRange, date):
	'''Returns a name for a binary file made of a set of tiles'''
	tmpfn = 0
	for i in hRange:
		for j in vRange:
			tmpfn = tmpfn + i + j
	binaryFilename = 'load_' + str(tmpfn) + str(date) + '.sdbbin'
	res = basebfilepath + binaryFilename
	return res

def buildBinaryFilePath1(basebfilepath, h, v, date):
	'''Builds the name of a single binary file'''
	hn = str(h)
	vn = str(v)
	if len(hn) == 1:
		hn = 'h0' + hn
	elif len(hn) == 2:
		hn = 'h' + hn
	if len(vn) == 1:
		vn = 'v0' + vn
	elif len(vn) == 2:
		vn = 'v' + vn
	binaryFilename = 'load_' + hn + vn + '_' + str(date) + '.sdbbin'
	res = basebfilepath + binaryFilename
	return res

def buildTileName(h, v):
	'''Returns a tile name from the given parameters'''
	si = ''
	sj = ''
	if len(str(h)) == 1:
		si = 'h0' + str(h)
	else:
		si = 'h' + str(h)
	if len(str(v)) == 1:
		sj = 'v0' + str(v)
	else:
		sj = 'v' + str(v)
	res = si + sj
	return res

def callAddHdfCommand(scriptFolder, hdf2binFolder, loadFolder, hdfPaths, binaryFilepath, lineMin, lineMax, sampMin, sampMax, period):
	'''Calls the script that builds the binary files from HDFs'''
	arg0 = "python " + scriptFolder + "addHdfs2bin.py --log INFO "
	arg1 = ';'.join(hdfPaths)
	arg2 = " " + binaryFilepath
	arg3 = " --lineMin " + str(lineMin)
	arg4 = " --lineMax " + str(lineMax)
	arg5 = " --sampMin " + str(sampMin)
	arg6 = " --sampMax " + str(sampMax)
	arg7 = " --period " + str(period)
	cmd = arg0 + arg3 + arg4 + arg5 + arg6 + arg7 + ' "' + arg1 + '"' + arg2
	print cmd
	subp.check_call(str(cmd), shell=True)
	#Copy to the keep folder
	if os.path.isdir(hdf2binFolder):
		print "Copying binary file to KEEP folder.."
		tmpPts = binaryFilepath.split("/")
		fn = tmpPts[len(tmpPts) - 1]
		cmd1 = "cp " + binaryFilepath + " " + hdf2binFolder + '/' + fn
		subp.check_call(str(cmd1), shell=True)
	#Move file to the loadFolder folder
	print "Moving binary file to LOAD folder.."
	cmd2 = "mv " + binaryFilepath + " " + loadFolder + os.path.basename(binaryFilepath)
	subp.check_call(str(cmd2), shell=True)	


def loadhdfGISOBAMA(modisPath, basebfilepath, dates, hRange, vRange, hdf2binFolder, loadFolder, scriptFolder, lineMin, lineMax, sampMin, sampMax, period):
	'''Builds the file paths and calls the load script'''
	for date in dates:
		hdfPaths = []
		#Builds the basepath where to find the HDFs
		d = doy2date(date)
		yyyy = d[0]
		mm = d[1]
		dd = d[2]
		if len(str(d[1])) == 1:
			mm = '0'  +str(d[1])
		if len(str(d[2])) == 1:
			dd = '0' + str(d[2])
		basePath = modisPath + str(yyyy) + '.'  + str(mm) + '.'  + str(dd) + '/'
		if os.path.isdir(basePath):
			#Builds the name of the binary file
			binaryFilepath = buildBinaryFilePath(basebfilepath, hRange, vRange, date)
			#Get the path to the HDFs
			for i in hRange:
				for j in vRange:
					tile = '*' + buildTileName(i, j) + '*'
					for file in os.listdir(basePath):
						if fnmatch.fnmatch(file, tile):
							if fnmatch.fnmatch(file, '*' + str(date) + '*'):
								hdfPaths.append(basePath + file)
							#else:
							#	print "No match file-date"
						#else:
						#	print "No match file-tile"
			#Command
			callAddHdfCommand(scriptFolder, hdf2binFolder, loadFolder, hdfPaths, binaryFilepath, lineMin, lineMax, sampMin, sampMax, period)
		#else:
		#	print "ERROR: " + basePath + " is not a directory"

			
#********************************************************
#WORKER
#********************************************************
t0 = datetime.datetime.now()

####################################################
# CONFIG
# Example array
# CREATE ARRAY MOD09Q1_SALESKA <red:int16, nir:int16, quality:uint16> [col_id=48000:72000,1014,5,row_id=38400:62400,1014,5,time_id=0:9200,1,0];
####################################################

# MODIS tile interval
hRange = range(0,36)
vRange = range(0,18)
# Number of days between images
period = 8
# Paths
basebfilepath = '/home/scidb/'
hdf2binFolder = '/home/scidb/fakepath/'
loadFolder = '/home/scidb/toLoad/'
scriptFolder = '/home/scidb/modis2scidb/'
modisPath = '/home/scidb/MODIS_ARC/MODIS/MOD09Q1.005/' 
# Pixel interval
lineMin = 0
lineMax = 4799
sampMin = 0
sampMax = 4799
# Dates
dates = buildDoy(2000, 2013, period)[3:]#date.today().year - 1
#Use HSD folder structure of R MODIS PACKAGE. All HDFs of the same date to a binary file
loadhdfGISOBAMA(modisPath, basebfilepath, dates, hRange, vRange, hdf2binFolder, loadFolder, scriptFolder, lineMin, lineMax, sampMin, sampMax, period)
