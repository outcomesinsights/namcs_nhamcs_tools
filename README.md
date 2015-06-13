# namcs_nhamcs_tools
tools to download and load namcs and nhamcs data

## Notes  
This works only for [NAMCS](http://www.cdc.gov/nchs/ahcd/about_ahcd.htm#NAMCS) right now.  Will add [NHAMCS](http://www.cdc.gov/nchs/ahcd/about_ahcd.htm#NHAMCS), but much of the code should be the same. 

There is a problem with the 1993 and 1994 SAS input specs, so they won't load.  This could be fixed manually but I am trying to do this all automatically.  Will have to contact NCHS and ask them to fix their files.  

I plan to put the data up here eventually too.  Most files are pretty small when compressed as [.rds](https://stat.ethz.ch/R-manual/R-devel/library/base/html/readRDS.html) files.  

The function to read the SAS input statement should work on other files.  I tested it on SEER data and it works there.  [SAScii](http://cran.r-project.org/web/packages/SAScii/index.html) is probably a more broadly applicable package but I wanted to play around with reading in SAS files myself.  

This uses the *[curl](http://cran.r-project.org/web/packages/curl/index.html)* package and not the *[Rcurl](http://cran.r-project.org/web/packages/RCurl/index.html)* package because I wanted to explore it.  Also, *[download.file](https://stat.ethz.ch/R-manual/R-devel/library/utils/html/download.file.html)* and other base R functions would work equally well.

I am using the readr package to read in fixed width files.  It is the best way to do fixed width files.  The [LaF](http://cran.r-project.org/web/packages/LaF/index.html) package also works for fixed width files.  Generally, I prefer *[fread](http://www.inside-r.org/packages/cran/data.table/docs/fread)* in the [data.table](http://cran.r-project.org/web/packages/data.table/index.html) package because it is usually faster to read in large files.  
