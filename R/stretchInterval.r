library(lubridate)

stretchInterval <- function(startDate, endDate) {
  startDate <- as.Date(startDate)
  endDate <- as.Date(endDate)
  
  if (month(startDate) >=10) {
    startDate <- paste(year(startDate),'-10-1', sep='')
  } else {
    startDate <- paste(year(startDate)-1,'-10-1', sep='')
  }
  
  if (month(endDate) > 10) {
    endDate <- paste(year(endDate)+1,'-9-30', sep='')
  } else {
    endDate <- paste(year(endDate),'-9-30', sep='')
  }
  
  return(c(startDate, endDate))
  
}

compressInterval <- function(startDate, endDate) {
  
  if (month(startDate) > 10) { 
    #XXX Might need to make this stricter by adding day >= 2
    startDate <- paste(year(startDate)+1,'-10-1', sep='')
  } else {
    startDate <- paste(year(startDate),'-10-1', sep='')
  }
  
  if (month(endDate) > 9) {
    endDate <- paste(year(endDate),'-9-30', sep='')
  } else {
    endDate <- paste(year(endDate)-1,'-9-30', sep='')
  }
  

  
  return(c(startDate, endDate))
}

compressFrame <- function(df, date_field) {
  #XXX see note on compressInterval
  startDate <- min(df[,date_field])
  endDate <- max(df[,date_field])
  
  interval <-compressInterval(startDate, endDate)
  
  
  
  if (as.Date(interval[1]) > as.Date(interval[2])) {
    start <- 1
    end <- nrow(df)
  } else {
    # else if end date falls after start date
    start = which(df[,date_field] == interval[1])
    end = which(df[,date_field] == interval[2])
  }
  
  return(df[start:end,])
}



nearsetStartYear <- function(eList, startYear) {
  
}

nearestEndYear <- function(eList, endYear) {
  

}
