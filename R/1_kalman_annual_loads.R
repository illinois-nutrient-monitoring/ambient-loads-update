# generates all eLists for Ambient trend analysis
library(RSQLite)
library(EGRET)
library(EGRETci)
library(data.table)
library(lubridate)

setwd("~/projects/ambient-loads-update/R")
# source('readNwISSample.R')
source('yeti_functions.R')
source('stretchInterval.r')
source('testEGRET.R')
source('runPairsBoot.R')
source('testEGRET.R')
source('func_calc_annual_loads.R')

#gfn_boot_table <- "wrtds_gfn_boot"
#wrtds_boot_table <- "wrtds_boot"
#gfn_table <- "wrtds_gfn"
load_boot_table <- "wrtds_k_load"
started_at <- Sys.time()

#parse command line inputs: dbname, project_path, index, startYear, endYear
args = commandArgs(trailingOnly = TRUE)
if (length(args)!=4) {
  stop("Specify site_db, Project root, index, start_boot", call.=FALSE)

} else if (length(args)==4) {
  dbname <- args[1]
  project_path <- args[2]
  index <- as.numeric(args[3])
  #startYear <- as.numeric(args[4])
  #endYear <- as.numeric(args[5])
  start_boot <- as.numeric(args[4])
}

seed <- 12345
elistPath <- paste(project_path, 'elists', sep='/')
dbPath <- paste(project_path, 'loads', sep='/')

drv <- RSQLite::SQLite()
con <- dbConnect(drv, dbname)

query <- "SELECT DISTINCT site_no FROM wrtds;"
response <- dbGetQuery(con, query)
sites <- unlist(response, use.names=FALSE)
junk <- dbDisconnect(con)


params <- c("00600","99220","00530","00630","00625","00610","00665","00666","00667", "00946", "80154","00535", "01045", "01046")
#params <- c("01045")

#usedStartYear <- startYear #used to alter start of specific runs


minNumObs <- 60
censorLimit <- 0.5
nBoot <- 10
nKalman <- 20

#N = length(sites) * length(params)

runAnalysis <- function(i) {

  # get site ID ----------
  siteID = sites[i %% length(sites) + 1] 
  # XXX run specific sites
  #if (!siteID %in% c('05563800')) {stop()}
  #if (!siteID %in% c('411925089063901','404208089335201','05558300')) {stop()}
  #if (!siteID %in% c('05586100','03339000')) {stop()}

  # get parameter -----------
  param = params[ceiling(i/length(sites))]
  print(siteID)
  print(param)
  print(seed)
  print(start_boot)

  outdb <- paste0(dbPath, '/',siteID,'_',param,'_annual_load.sqlite')
  #

  #XXX Begin here
  elistFile <- sprintf("%s_%s_eList.Rdata", siteID, param)

  load(file=paste(elistPath, elistFile, sep='/')) #load eList

  # Determine start and end years based on available data --------
  # next if no data from period

  # Run tests ----------
  #if (testHasDuplicates(eList$Sample)){stop('Sample had duplicates')}
  if (testTooCensored(eList$Sample, censorLimit=censorLimit)){next}
  if (testZeroFlow(eList$Daily)){next}
  if (testTooFewObs(eList$Sample, minNumObs=minNumObs)){print('too few obs');next}
  #if (testTooShort(start, end)){next}

  # Check for previous saved state XXX
  if (file.exists(outdb)) {
      con <- dbConnect(drv, outdb)
      query <- sprintf("SELECT max(boot) FROM %s;", load_boot_table)
      response <- dbGetQuery(con, query)
      junk <- dbDisconnect(con)
      max_boot <- unlist(response, use.names=FALSE)
      stopifnot(max_boot < start_boot + nKalman * nBoot) #could improve
      #stopifnot(max_boot == start_boot) #could improve

  } else {
      #max_boot = 0
      start_boot <- 0
  }

  # Run model ----------
  # generate eList from modelEstimation prior to calling wBT
  # XXX sometimes this only converges with eList called afteward ??? (i=11?)
  eList <- modelEstimation(eList, minNumObs = minNumObs - 1, minNumUncen = censorLimit -1)

  dailyBoot <- EGRETci::genDailyBoot(eList, nBoot = nBoot, nKalman = nKalman, setSeed = seed + start_boot)
  output <- calc_annual_loads(dailyBoot, eList$Daily$Date, wy=TRUE)
  # save all results, but log missing days and sample counts
  sample_df <- samples_by_year(eList$Sample$Date, wy=TRUE)
  flowdays_df <- flowdays_by_year(eList$Daily$Date, wy=TRUE)
  output <- merge(output, sample_df)
  output <- merge(output, flowdays_df)
  #output <- drop_partial_years(output, eList$Daily$Date)
  #output <- drop_years_wo_samples(output, eList$Sample$Date, min_samples=4)
  output$boot <- output$boot + start_boot

  output$site_no <- siteID

  #Put bootstrap results in database ----
  var.names<-tolower(colnames(output))
  colnames(output)<-var.names

  con <- dbConnect(drv, outdb)
  dbWriteTable(con, load_boot_table, value=output, append=TRUE, row.names=FALSE) #XXX is this writing to shared dB?
  junk <- dbDisconnect(con)
  print('Wrote out data')

}

runAnalysis(index)
#possibleErrorX <- tryCatch( runAnalysis(index),
#                            error = function(err) {
#                              sink(paste(dbPath,"!failed_elists.log", sep='/'))
#                              cat(paste('all_loads',index, sep=','))
#                              sink()
#                            }
#) #END tryCatch
