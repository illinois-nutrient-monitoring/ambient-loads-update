library(RPostgreSQL)
library(EGRET)
library(dataRetrieval)
#XXX ADD CODE TO REMOVE EMPTY VALUES WHICH OCCUR WHEN PULLING DATA FROM MY DATABASE
#handle error in case ata does not exist for site"03336645"
readNWISSample <- function(con, siteNumber,parameterCd,startDate="",endDate="",verbose = TRUE,interactive=NULL){
  
  if(!is.null(interactive)) {
    warning("The argument 'interactive' is deprecated. Please use 'verbose' instead")
    verbose <- interactive
  }
  #XXX testing order by statement
  query <- sprintf("SELECT site_no, sample_dt, p%s, r%s FROM ambient.wrtds WHERE site_no='%s' AND p%1$s IS NOT NULL ORDER BY sample_dt",parameterCd, parameterCd, siteNumber)
  result = tryCatch({
    result <- dbSendQuery(con, query)
    rawSample <- fetch(result, n=-Inf)
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
