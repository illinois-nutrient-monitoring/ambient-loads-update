#EGRET tests

# test for minimum number of samples
testTooFewObs<- function(Sample, minNumObs=60, dropDuplicates=TRUE) {
  return(nrow(Sample) < (minNumObs))
}


testTooCensored <- function(Sample, censorLimit=0.5) {
# Hirsch and DeCicco 2015 recommend a 50% censorship threshold for WRTDS
  return(mean(Sample$Uncen) < censorLimit)
}


# test for data continuity

# test for sufficient storm sampling 


testZeroFlow <- function(Daily, limit=0.2) {
  # Hirsch and Decicco recommmend <0.2% of input data have zero or negative flow for WRTDS
  return( sum(Daily$Q <= 0) > limit)
}


testHasDuplicates <- function(Sample) {
  # Use EGRET's removeDuplicates to resolve:
  # Sample <- removeDuplicates(Sample) 
  return(sum(duplicated(Sample$Date)) != 0)
}

testTooShort <- function(startYear, endYear, minDuration=5){
  return( (endYear - startYear) < minDuration)
}

#XXX add buf (#days) to startDate
testStartCoverage <- function(dates, startYear, buf=0){
  dates <- as.Date(dates)
  startDate <- as.Date(paste(startYear-1,10,1, sep='-')) + buf # days
  return(any(dates <= startDate))
  
}

testEndCoverage <- function(dates, endYear, buf=0){
  dates <- as.Date(dates)
  endDate <- as.Date(paste(endYear,9,30, sep='-')) - buf
  return(any(dates >= endDate))
  
}


# composite tests