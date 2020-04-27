## 

# Setup -------------------------------------------------------------------

library(dplyr)
library(tidyverse)
library(gplots)


defaultArgs <- list (
  plotFile = "countDifferences.pdf",
  csvFile = 'l1Distance.csv'
)

args <- R.utils::commandArgs(trailingOnly = TRUE,
                             asValues = TRUE ,
                             defaults = defaultArgs)

pdf(args$plotFile)
colRWB<- function(n=11) {colorRampPalette(c("blue", "white", "red"))(n)}
########## functions
drawHeatMap <- function(x,rowRange = 1:nrow(x),
                        colRange = -grep("l1Distance",colnames(x)),
                        col=colRWB(),rowLabel=NULL,
                        rowv = FALSE,
                        plotTitle = ""
                        ) {

  heatmap.2(as.matrix(x[rowRange,colRange]),
            dendrogram = "none",
            Rowv = rowv,
            Colv = FALSE,
            cexRow = .4,
            labRow = rowLabel,
            key.xlab = "diff between counts",
            trace="none",
            denscol = "black", density.info = "density",
            col=col
            )
  title(main= plotTitle)
} ##drawHeatmap

## get column indices for ranges of dates;
lastNDays <- function(columnNames = colnames(dat), n=14) {
  maxCases  <- max(grep("^C",columnNames))
  maxDeaths <- max(grep("^D",columnNames))
  return(c((maxCases-n+1):maxCases,(maxDeaths-n+1):maxDeaths))
} ## lastNDays

firstNDays <- function(columnNames = colnames(dat), n=14) {
  minCases  <- min(grep("^C",columnNames))
  minDeaths <- min(grep("^D",columnNames))
  return(c(minCases:(minCases+n-1),minDeaths:(minDeaths+n-1)))
} ## firstNDays

#############
dat <- read.csv(args$csvFile,
                row.names=1,
                header = TRUE,
                sep=",")

### all data
drawHeatMap(dat, rowLabel = "", plotTitle = "NYT-USAFacts"
            )

## 2 weeks cases and deaths; top 50 in l1
drawHeatMap(dat,rowRange = 1:25,
            colRange = lastNDays(n=14),
            plotTitle = "25 Counties(fips) with largest l1 distance: last 2 weeks"
            )

### first 2 months
drawHeatMap(dat,rowRange = 500:nrow(dat), colRange = firstNDays(n=60),rowLabel = "",
            plotTitle = "NYT-USAFacts: first 2 months w/o top 500"
)

## smallest differences
drawHeatMap(dat,rowRange = (nrow(dat)-500+1):nrow(dat),rowLabel = "",
            plotTitle = "NYT-USAFacts: 500 counties with smallest l1 distance"
)

drawHeatMap(dat,rowRange = (nrow(dat)-25+1):nrow(dat),
            plotTitle = "NYT-USAFacts: 25 counties with smallest l1 distance"
)

dev.off()

q()
