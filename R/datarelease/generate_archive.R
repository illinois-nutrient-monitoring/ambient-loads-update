eListPath <- '/lustre/projects/water/cmwsc/thodson/nrec/elists/'
outPath <- '/lustre/projects/water/cmwsc/thodson/nrec/datarelease/'
files <- list.files(path=eListPath, pattern='*.Rdata')


lapply( files, function(x) {
    load( paste(eListPath, x, sep='') )
    param <- eList$INFO$paramNumber
    site <- eList$INFO$staAbbrev
    flowFile <- paste('Flow/',param,'_',site, '_Daily.csv', sep='')
    sampleFile <- paste('Sample/',param,'_',site, '_Sample.csv', sep='')
    infoFile <- paste('INFO/',param,'_',site, '_INFO.csv', sep='')

    write.csv(eList$Sample, file = paste(outPath, sampleFile, sep=''),
              row.names=FALSE)
    #write.csv(eList$Daily, file = paste(outPath, flowFile, sep=''),
    #          row.names=FALSE)
    #write.csv(eList$INFO, file = paste(outPath, infoFile, sep=''),
    #          row.names=FALSE)
           
})
