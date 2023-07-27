eListPath <- '/lustre/projects/water/cmwsc/thodson/nrec/elists/'
outPath <- '/lustre/projects/water/cmwsc/thodson/nrec/elists_converted/'
files <- list.files(path=eListPath, pattern='*.Rdata')
concFields <- c('ConcLow', 'ConcHigh', 'ConcAve')

lapply( files, function(x) {
    load(paste(eListPath, x, sep=''))
    outfile <- paste(outPath, x, sep='')
    units <- eList$INFO$param.units

    if ( grepl('ug/l', units) ) {
        eList$Sample[,concFields] <- eList$Sample[,concFields] * 0.001
        # save output
        save(eList, file=outfile)

        
    } else if (grepl('mg/l', units)) {
        save(eList, file= outfile)    

    } else {
        print(eList$INFO$param.nm)
    }
})
