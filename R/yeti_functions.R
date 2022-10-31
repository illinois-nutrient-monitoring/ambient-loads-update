library(RSQLite)
library(EGRET)
library(dataRetrieval)
#XXX ADD CODE TO REMOVE EMPTY VALUES WHICH OCCUR WHEN PULLING DATA FROM MY DATABASE
#handle error in case ata does not exist for site"03336645"
readNWISSample <- function(con, tablename, siteNumber,parameterCd,startDate="",endDate="", verbose = TRUE,interactive=NULL){

  if(!is.null(interactive)) {
    warning("The argument 'interactive' is deprecated. Please use 'verbose' instead")
    verbose <- interactive
  }
  #Changed query because values in db shouldn't be NULL as this breaks something in EGRET
  query <- sprintf("SELECT site_no, sample_dt, p%s, r%s FROM %s WHERE site_no='%s' AND p%1$s IS NOT '' ORDER BY sample_dt",parameterCd, parameterCd, tablename, siteNumber)
  #query <- sprintf("SELECT site_no, sample_dt, p%s, r%s FROM %s WHERE site_no='%s' AND p%1$s IS NOT NULL ORDER BY sample_dt",parameterCd, parameterCd, tablename, siteNumber)
  result = tryCatch({
    rawSample <- dbGetQuery(con, query)
    #result <- dbSendQuery(con, query)
    #rawSample <- fetch(result, n=-Inf)
    dataColumns <- grep("p\\d{5}",names(rawSample))
    remarkColumns <- grep("r\\d{5}",names(rawSample))
    totalColumns <-c(grep("sample_dt",names(rawSample)), remarkColumns, dataColumns)
    #totalColumns <- totalColumns[order(totalColumns)]
    compressedData <- compressData(rawSample[,totalColumns], verbose=verbose)
    Sample <- populateSampleColumns(compressedData)
    return(Sample)
  }, error = function(e) {
    Sample <- data.frame(Date=as.Date(character()),
                         ConcLow=numeric(),
                         ConcHigh=numeric(),
                         Uncen=numeric(),
                         ConcAve=numeric(),
                         Julian=numeric(),
                         Month=numeric(),
                         Day=numeric(),
                         DecYear=numeric(),
                         MonthSeq=numeric(),
                         SinDY=numeric(),
                         CosDY=numeric(),
                         stringsAsFactors=FALSE)
    return(Sample)


  })
  return(result)
}

# compressedData must match this format
#dateTime ConcLow ConcHigh Uncen
#1   1978-01-18    6.80     6.80     1
#2   1978-02-14    5.40     5.40     1
#3   1978-04-11    0.00     0.10     0
w_readNWISDaily <- function(siteID, parameter, start_date, end_date) {
    if (siteID == '05550000'){
        daily <- readNWISDaily_05550000(start_date, end_date)
    } else if (siteID =='05563800') {
        print('Generate Pekin Elist')
        daily <- readNWISDaily_05563800(start_date, end_date)
    } else if (siteID =='05599490') {
        daily <- readNWISDaily_BM(start_date, end_date)
    } else if (siteID =='404208089335201') {
        filename <- '../data/404208089335201.csv'
        daily = readNWISDaily_file(filename, parameterCd='00060', start_date=start_date, end_date=end_date)
    } else if (siteID =='411925089063901') {
        filename <- '../data/411925089063901.csv'
        daily = readNWISDaily_file(filename, parameterCd='00060', start_date=start_date, end_date=end_date)
    } else {
        daily = readNWISDaily(siteID, parameter, start_date, end_date)

    }
    return(daily)
}

format_rdb <- function(siteNumber, parameterCd, startDate, endDate) {
  url <- dataRetrieval::constructNWISURL(siteNumber,parameterCd,startDate,endDate,"dv",statCd="00003", format = "tsv")
  data_rdb <- dataRetrieval::importRDB1(url, asDateTime=FALSE)

  localDaily <- data.frame(Date=as.Date(character()),
                           Q=numeric(),
                           Julian=numeric(),
                           Month=numeric(),
                           Day=numeric(),
                           DecYear=numeric(),
                           MonthSeq=numeric(),
                           Qualifier=character(),
                           i=integer(),
                           LogQ=numeric(),
                           Q7=numeric(),
                           Q30=numeric(),
                           stringsAsFactors=FALSE)

  if(nrow(data_rdb) > 0){
    if(length(names(data_rdb)) >= 5){
      names(data_rdb) <- c('agency', 'site', 'dateTime', 'value', 'code')
      data_rdb$dateTime <- as.Date(data_rdb$dateTime)
      data_rdb$value <- as.numeric(data_rdb$value)
    } else {
      if("comment" %in% names(attributes(data_rdb))){
        message(attr(data_rdb, "comment"))
      }
    }

  }

  return (data_rdb)
}

readNWISDaily_05563800 <- function(start_date, end_date) {
	#WIP
	#readNWISdv
	illinois_river <- format_rdb('05568500', '00060', start_date, end_date)
	mackinaw_river <- format_rdb('05568000', '00060', start_date, end_date)

	temp <- merge(mackinaw_river, illinois_river, by='dateTime', all=TRUE)
	q <- temp$value.y - temp$value.x #subtract Mackinaw contribution from Illinois
	# rescale by drainage area
	q <- q *  14585/(15818-1073)
	q <- q[!is.na(q)]
	# write back to Mackinaw dataframe
	mackinaw_river$value <- q
	mackinaw_river$site <- '05563800' #Illinois River at Peking
	#merge and difference
	# format to READNWISdaily
	#qConvert <- ifelse("00060" == parameterCd, 35.314667, 1)
        qConvert <- 35.314667
	Daily <- populateDaily(mackinaw_river, qConvert)

	return(Daily)
}


# get data for big muddy
readNWISDaily_BM <- function(start_date, end_date) {
  #get big Muddy data
  interval<- c(start_date,end_date)
  switch <- c("2007-09-30","2007-10-01")
  siteID <- "05599500"
  siteID2 <- "05599490"
  Daily1 <- readNWISDaily(siteID,"00060", interval[1], switch[1])
  Daily2 <- readNWISDaily(siteID2,"00060", switch[2], interval[2])

  Daily <- rbind(Daily1, Daily2)


  Daily[Daily$Q<0,'Q'] <- 0.0729461706834582
  Daily$LogQ <- log(Daily$Q)

  return(Daily)
}


readNWISDaily_05550000 <- function(start_date, end_date) {
  interval<- c(start_date,end_date)
  switch <- c("2009-09-30","2009-10-01")
  siteID <- "05550000"
  siteID2 <- "05550001"
  Daily1 <- readNWISDaily(siteID,"00060", interval[1], switch[1])
  Daily2 <- readNWISDaily(siteID2,"00060", switch[2], interval[2])

  Daily <- rbind(Daily1, Daily2)


  Daily[Daily$Q<0,'Q'] <- 0.0729461706834582
  Daily$LogQ <- log(Daily$Q)

  return(Daily)
}


readNWISDaily_file <- function (filename,parameterCd="00060",
                           start_date=NULL,end_date=NULL,verbose = TRUE,convert=TRUE){

  data_rdb <- read.csv(filename)
  data_rdb$datetime <- as.Date(data_rdb$datetime, format="%Y-%m-%d")
  start_date <- as.Date(start_date); end_date <- as.Date(end_date)
  data_rdb <- data_rdb[data_rdb$datetime >= start_date & data_rdb$datetime <= end_date, ]
  localDaily <- data.frame(Date=as.Date(character()),
                           Q=numeric(),
                           Julian=numeric(),
                           Month=numeric(),
                           Day=numeric(),
                           DecYear=numeric(),
                           MonthSeq=numeric(),
                           Qualifier=character(),
                           i=integer(),
                           LogQ=numeric(),
                           Q7=numeric(),
                           Q30=numeric(),
                           stringsAsFactors=FALSE)

  if(nrow(data_rdb) > 0){
    if(length(names(data_rdb)) >= 5){
      names(data_rdb) <- c('agency', 'site', 'dateTime', 'value', 'code')
      data_rdb$dateTime <- as.Date(data_rdb$dateTime)
      data_rdb$value <- as.numeric(data_rdb$value)
      #####################################
      qConvert <- ifelse("00060" == parameterCd, 35.314667, 1)
      qConvert<- ifelse(convert,qConvert,1)

      localDaily <- populateDaily(data_rdb,qConvert,verbose = verbose)
    } else {
      if("comment" %in% names(attributes(data_rdb))){
        message(attr(data_rdb, "comment"))
      }
    }

  }

  return (localDaily)
}
