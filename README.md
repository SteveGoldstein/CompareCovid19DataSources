# CompareCovid19DataSources


Retrieves "processed" files from Yu-Group (Berkeley) github repo and then
compares files, producing:

 1.  log with differences noted
 2.  csv file with pairwise differences for each observation 
          (cases or deaths for a given day)
 3.  heatmaps of various slices of pairwise difference matrix 
 4.  csv file with processed data in a common format. This file might be
     useful for visually inspecting the counts for counties with large
     discrepancies. 

Usage:  bin/compareCSV.pl -outdir <dir>
             -fetch or -nofetch:   hook to avoid multiple wgets (for testing)
             -excludeIdentical (default) or -noex:  
                  suppress printing identical entries
