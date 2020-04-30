### Heatmaps displaying differences between NYTimes and USAfacts counts;
## usage:  Rscript --vanilla bin/heatmapOfDiffs.R 
##               -plotFile <plot.pdf>  -csvFile <l1Dist.csv>

## Setup -------------------------------------------------------------------

library(dplyr)
library(tidyverse)
library(gplots)


defaultArgs <- list (
  plotFile = '2020-04-29/heatmaps.pdf',
  csvFile = '2020-04-29/l1Distance.csv'
)

args <- R.utils::commandArgs(trailingOnly = TRUE,
                             asValues = TRUE ,
                             defaults = defaultArgs)

pdf(args$plotFile)

dat <- read.csv(args$csvFile,
                row.names=1,
                header = TRUE,
                sep=",")

########## functions -----------------------------------------------
colRWB<- function(n=11) {colorRampPalette(c("blue", "white", "red"))(n)}

drawHeatMap <- function(x,rowRange = 1:nrow(x),
                        colRange = -grep("l1Distance",colnames(x)),
                        col=colRWB(),rowLabel=NULL,
                        rowv = FALSE,
                        sepcolor = "lightgrey",
                        plotTitle = ""
                        ) {
    minDeathCol <- min(grep("^D",colnames(x[,colRange])))
    heatmap.2(as.matrix(x[rowRange,colRange]),
            dendrogram = "none",
            Rowv = rowv,
            Colv = FALSE,
            cexRow = .4,
            labRow = rowLabel,
            key.xlab = "diff between counts",
            trace="none",
            denscol = "black", density.info = "density",
            colsep = minDeathCol,
            sepcolor = sepcolor, sepwidth=c(0.01,0.01),
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

#########################################
## plots --------------------------------------------
### all data
drawHeatMap(dat, rowLabel = "", plotTitle = "NYT-USAFacts"
            )

## 2 weeks cases and deaths; top 25 in l1
drawHeatMap(dat,rowRange = 1:25,
            colRange = lastNDays(n=14),
            plotTitle = paste("25 Counties(fips) with largest l1 distance",
            "last 2 weeks", sep = "\n")
            )

### first 2 months
drawHeatMap(dat,rowRange = 1:100, colRange = firstNDays(n=60),
            rowLabel = "", rowv = FALSE,
            plotTitle = "NYT-USAFacts: first 2 months top 100"
)

drawHeatMap(dat,rowRange = 101:500, colRange = firstNDays(n=60),
            rowLabel = "", rowv = TRUE,
            plotTitle = "NYT-USAFacts: first 2 months l1 ranks 101-500"
)

drawHeatMap(dat,rowRange = 501:nrow(dat), colRange = firstNDays(n=60),
            rowLabel = "", rowv = TRUE,
            col=colRWB(7),
            plotTitle = "NYT-USAFacts: first 2 months w/o top 500"
)

## smallest differences
smallL1_dat <- dat %>% 
  filter(l1Distance < 4)
drawHeatMap(smallL1_dat,rowLabel = "",
            rowv = TRUE,
            col=colRWB(7),
            plotTitle = "NYT-USAFacts: counties with l1 distance < 4"
)

wiscDat <- dat %>% 
  rownames_to_column(var="fips") %>% 
  filter(grepl('^55',fips)) %>% 
  column_to_rownames(var="fips")


dev.off()
q()
