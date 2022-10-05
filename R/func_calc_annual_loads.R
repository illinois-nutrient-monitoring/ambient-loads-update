# compute annual loads given eList
require(lubridate)
require(plyr)

# Calculate annual loads from dailyBoot data
# Any missing data should make the annual load for that year NA (sum includes
# NA equals NA)

calc_annual_loads <- function(dailyBoot, dates, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(dates)
    } else {
        years <- calc_wy(dates)
    }

    year_list <- unique(years)
    n_years = length(year_list)
    n_boot <- ncol(dailyBoot)
    year_column <- rep(year_list, n_boot)
    boot_column <- rep(seq(n_boot), each=n_years)
    df <- data.frame(year=year_column, boot=boot_column, load=NA)

    for (i in seq(n_boot)) {
        start <- (i-1) * n_years + 1
        end <- i * n_years
    df$load[start: end] <- as.numeric( tapply(dailyBoot[,i], years, FUN=sum) )
    }
    return(df)
}

calc_wy <- function(dates) {
    years <- lubridate::year(dates)
    months <- lubridate::month(dates)

    water_year = years
    water_year[months >= 10] = years[months >= 10] + 1
    return(water_year)
}

flowdays_by_year <- function(dates, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(dates)
    } else {
        years <- calc_wy(dates)
    }
    obs <- count(years)
    names(obs) <- c('year', 'flow_days')
    return(obs)
}


samples_by_year <- function(dates, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(dates)
    } else {
        years <- calc_wy(dates)
    }
    obs <- count(years)
    names(obs) <- c('year', 'n_samples')
    return(obs)
}

#null any partial years in the dailyBoot
drop_partial_years <- function(annual_loads, dates, allowed_missing = 10, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(dates)
    } else {
        years <- calc_wy(dates)
    }
    #years <- lubridate::year(dates)
    obs <- count(years)
    full_years <- obs$x[obs$freq >= 365 - allowed_missing]
    annual_loads <- annual_loads[ annual_loads$year %in% full_years, ]
    return(annual_loads)
}

# blank years with fewer than min samples
drop_years_wo_samples <- function(annual_loads, sample_dates, min_samples=4, wy=FALSE) {
    if (!wy){
        years <- lubridate::year(sample_dates)
    } else {
        years <- calc_wy(sample_dates)
    }
    #years <- lubridate::year(sample_dates)
    obs <- count(years)
    full_years <- obs$x[obs$freq >= min_samples]
    annual_loads <- annual_loads[ annual_loads$year %in% full_years, ]
    return(annual_loads)
}
