## remove genes and then plot heatmap of pearson correlations;

# Setup -------------------------------------------------------------------

library(dplyr)
library(tidyverse)
library(gplots)


defaultArgs <- list (
  #pct = 5
)

args <- R.utils::commandArgs(trailingOnly = TRUE,
                             asValues = TRUE ,
                             defaults = defaultArgs)

col<- colorRampPalette(c("blue", "white", "red"))(500)

dat <- read.csv("heatmap.in.csv",
                row.names=1,
                header = TRUE,
                sep=",")

## 2 weeks cases and deaths; top 50 in l1
heatmap.2(as.matrix(dat)[1:50,c(79:92,171:184)],
          dendrogram = "none",Rowv = FALSE, Colv = FALSE,
          trace="none",col=col
          )
title(main = plotDescription[i])

## 2 weeks cases and deaths; bottom of the list;
heatmap.2(as.matrix(dat)[1000:2758,c(79:92,171:184)],
          dendrogram = "none",Rowv = FALSE, Colv = FALSE,
          trace="none",col=col
          )
heatmap.2(as.matrix(dat)[1:10,c(79:92,171:184)],
          dendrogram = "none",Rowv = FALSE, Colv = FALSE,
          trace="none",col=col
          )

heatmap.2(as.matrix(dat)[1:10,],
          dendrogram = "none",Rowv = FALSE, Colv = FALSE,
          trace="none",col=col
)



q()
