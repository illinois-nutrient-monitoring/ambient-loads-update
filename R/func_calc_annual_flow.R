library(lubridate)
library(stats)

meanflow_by_year <-function(q, dates, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(dates)
    } else {
        years <- calc_wy(dates)
    }

    year_list <- unique(years)A

    fl
 
}


