library(RSQLite)
library(EGRET)
library(data.table)
library(lubridate)



setwd("~/projects/ambient-loads-update/R")
#setwd("c:/Users/thodson/Desktop/Projects/illinois-nutrient-monitoring/ambient-loads-update/R")
# source('readNwISSample.R')
source('yeti_functions.R')
source('stretchInterval.r')
source('func_calc_annual_loads.R')
data_csv <- '/lustre/projects/water/cmwsc/thodson/ambient-loads-update/data_release/illinois_ambient_annual_loads_wrtdsk.csv'
out_csv <- '/lustre/projects/water/cmwsc/thodson/ambient-loads-update/data_release/illinois_ambient_annual_flow.csv'
#df <- read.csv('c:/Users/thodson/Desktop/Projects/illinois-nutrient-monitoring/ambient-loads-update/illinois_ambient_annual_loads_wrtdsk.csv',
df <- read.csv(data_csv,
               colClasses= c("site_no"="character"))

sites <- unique(df$site_no)

output <- data.frame()

for (site in sites){
  print(site)
  d <- df[df$site_no == site,]
  min_year <- min(d$year)
  max_year <- max(d$year)
  
  start_date <- paste0(min_year - 1,'-10-1')
  end_date <- paste0(max_year ,'-9-30')
  
  Daily = w_readNWISDaily(site, "00060", start_date, end_date)
  annual_flow = aggregate(Daily[,c("Q")], list(Daily$waterYear), mean, na.rm = TRUE)
  annual_flow = setNames(annual_flow, c("year","mean flow [cms]"))
  annual_flow$site_no = site
  output <- rbind(output, annual_flow)
  
}

write.csv(output, 
          out_csv,
          row.names=FALSE)
