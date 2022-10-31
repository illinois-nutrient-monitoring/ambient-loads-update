# generates all eLists for Ambient trend analysis
library(RSQLite)
library(EGRET)
library(data.table)
library(lubridate)

setwd("~/projects/ambient-loads-update/R")
# source('readNwISSample.R')
source('yeti_functions.R')
source('stretchInterval.r')
source('func_calc_annual_loads.R')

started_at <- Sys.time()

#parse command line inputs: start, stop, start_i, end_i
args = commandArgs(trailingOnly = TRUE)
if (length(args)!=3) {
  stop("Specify db, savePath, index", call.=FALSE)
  
} else if (length(args)==3) {
    dbname <- args[1]
    savePath <- args[2]
    index <- as.numeric(args[3])
}


drv <- RSQLite::SQLite()
con <- dbConnect(drv, dbname)

query <- "SELECT DISTINCT site_no FROM wrtds;"
response <- dbGetQuery(con, query)
sites <- unlist(response, use.names=FALSE)
print(dbname)

params <- c("00600","99220","00530", "00535","00630","00625","00610","00665","00666","00667", "00946", "80154", "01045")

#startYear <- 1970
endYear <- "2021"

#usedStartYear <- startYear #used to alter start of specific runs

#projectEndDate <- "2020-09-30"


#N = length(sites) * length(params)

runAnalysis <- function(i) {
  
  # get site ID ----------
  siteID = sites[i %% length(sites) + 1]
  # SET FOR TESTING  
  #XXX run specific sites
  #if (!siteID %in% c('411925089063901','404208089335201','05558300')) {stop()}
  # get parameter -----------
  param = params[ceiling(i/length(sites))]
  
  #startDate <-""
  #endDate <- projectEndDate
  
  print(siteID)
  # Get sample data ----------------
  con = dbConnect(drv, dbname)
  Sample <- readNWISSample(con, 'wrtds', siteID, param,"","")
  Sample <- removeDuplicates(Sample)
  print('read sample')
  #junk <- dbDisconnect(con)
  
  # Get flow data --------------
  #interval <- stretchInterval(min(Sample$Date), max(Sample$Date))
  start_date <- calc_wy(min(Sample$Date))
  start_date <- paste0(start_date,'-10-1')
  #end_date <- calc_wy(max(Sample$Date))
  #if (end_date > 2021) {
  #    end_date = 2021 #XXX clip flow data to 2020 because 2021 may not be approved
  #}

  end_date <- paste0(endYear,'-9-30')
  print(end_date)
  print(start_date) 
  #if (siteID == '05599490'){
  #  Daily =  readNWISDaily_BM(start_date, end_date) #XXX check this before reusing code
  #} else {
  #  Daily <- readNWISDaily(siteID,"00060", start_date, end_date)
  #} 
  Daily = w_readNWISDaily(siteID, "00060", start_date, end_date)
  print('read daily') 
  
  # Adjust data interval ---------------------
  if (nrow(Daily) == 0) {print('no discharge data during interval'); next} # if no discharge skip
  #Daily <- compressFrame(Daily, 'Date') #XXX compress frame to *roughly* align with water year
  coverage <- Sample$Date >= min(Daily$Date) & Sample$Date <= max(Daily$Date)
  # Throw out samples outside discharge coverage
  Sample <- Sample[coverage,]
  
  
  # Create eList ---------------
  INFO <- readNWISInfo(siteID, param, interactive=FALSE)
  # set parameters used to save workspaces
  INFO$staAbbrev <- siteID 
  INFO$constitAbbrev <- param
  eList <- mergeReport(INFO, Daily, Sample, verbose=FALSE)
  # throw out samples without flow data
  Sample <- eList$Sample[!is.na(eList$Sample$Q),]
  eList <- mergeReport(INFO, Daily, Sample, verbose=FALSE)
  
  saveFile <- sprintf("%s_%s_eList.Rdata", siteID, param) 
  save(eList, file=paste(savePath, saveFile, sep='/'))
  
  
}
runAnalysis(index)
#possibleErrorX <- tryCatch( runAnalysis(index), 
#                            error = function(err) {
#                              sink(paste(savePath,"!failed_elists.log", sep='/'))
#                              cat(paste('make_eList',index, sep=','))
#                              sink()
#                            }
#                          ) #END tryCatch
