# libraries
library(curl)
library(magrittr)
library(readr)
library(stringr)

# functions
check_dir <- function(directory){
    if(!grepl("/{1}$", directory)){
        stop("directory needs to end with a forward slash")
    }
    if(!file.exists(directory)) {
    dir.create(directory)
    }
}
get_filenames <- function(ftp_site) {
    h <- new_handle() %>%
        handle_setopt(ftp_use_epsv = FALSE, crlf = TRUE)
    con <- curl(ftp_site, handle = h) 
    f <- readLines(con) %>%
        strsplit("\\s+") %>%
        do.call(rbind, .) %>% 
        as.data.frame %>%
        .[, 5:9]
    close(con)
    names(f) <- c("size", "month", "day", "year", "filename")
    return(f)
}

# reads SAS input statements file to create fwf input specs
read_sas_specs <- function(textdoc, ...){
    z <- readLines(textdoc, ...) %>% # allows for encoding or other arguments to readLines
        .[grepl("^\\s*@", .)]  # pick lines starting with @
    colstart <- str_extract(z, "@\\s*\\d+\\s+") %>% 
        gsub("@", "", .) %>% 
        as.numeric
    varname <- str_extract(z, "[A-Z]+\\d*\\S*") %>% # caps + maybe a number + maybe any non-whitespace char
        tolower
    char <- str_detect(z, "\\$(CHAR|char)?\\d+")
    num <- str_detect(z, "\\s+\\d+\\.\\d+\\s+") # spaces followed by number followed by . followed by number followed by spaces
    width <- str_extract(z, "\\d+\\.\\d*") %>% # number followed by . maybe followed by number
        gsub("\\.\\d*", "", .) %>% 
        as.numeric
    desc <- str_extract(z, "/\\*.+\\*/") %>% # characters contained between /* and */
        gsub("/\\*\\s*", "", .) %>% 
        gsub("\\s*\\*/", "", .)
    colstop <- colstart + width - 1
    specs <- data.frame(colstart, colstop, varname, char, num, width, desc) # file of database specs
    return(specs)
}

# download file and specs, and read the fwf, and save it as an rds file
# requires a file list with 2 columns, one for the filenames of the data files, and one for the filenames for the documnetation files (sas input)
# uses readr read_fwf to load data and uses on character per column for setting column classes
get_save_files <- function(file_list, dest_dir, ...){
    check_dir(dest_dir) # checks directory and makes it if it doesn't exist
    temp_data <- tempfile() # create tempfiles
    temp_docs <- tempfile()
    td <- tempdir() # save temp directory for use
    for(r in seq_along(file_list[[1]])){
        curl_download(paste0(ftp_data, file_list[["datafiles"]][[r]]), temp_data)
        y <- unzip(temp_data, exdir = td)
        curl_download(paste0(ftp_docs, file_list[["docfiles"]][[r]]), temp_docs)
        specs <- read_sas_specs(temp_docs, ...)
        if(any(is.na(specs$width))){
            cat("Skipped ", file_list[["datafiles"]][[r]], " due to SAS filespec error\n")
            next
        }
        coltype <- ifelse(specs$char, "c", 
                        ifelse(specs$num, "d", "i")) %>% paste0(., collapse = "") # one character per column for classes
        input_specs <- fwf_positions(specs$colstart, specs$colstop, specs$varname) # could set na here but there are 3 na values in NAMCS (-9, -8, and -7)
        d <- read_fwf(y, input_specs, col_types = coltype, progress = FALSE)
        f <- paste0(dest_dir, file_list[["datafiles"]][[r]] %>%  tolower %>% gsub("(exe)$", "rds", .))
        saveRDS(d, f)
        cat("Saved ", f, "\n")
    }
}

# set up directories
namcs_dir <- "./data/" # local directory on computer where data will be saved
ftp_data <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/NAMCS/" # data ftp site
ftp_docs <- "ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/dataset_documentation/namcs/sas/" # documentation ftp site

# --------------------------------------------------------------------------------------------------
# extract relevant files for downloading from all files in ftp directory
# saved working verison of file_list just in case, called "download_specs.rds" so this section can be skipped
# to skip use: file_list <- readRDS("./data/download_specs.rds")

# download directory information
fdata <- get_filenames(ftp_data) # get data file names
fdocs <- get_filenames(ftp_docs) # get sas input specs

# note that in "file_list" years have to be organized by row.  Order is not guaranteed by this code. It because they are sorted alphabetically.
# missing "." in sas input statement for 1993 and 1994; skipped above using "if-next"
datafiles <- grep("\\.(exe|EXE)$", fdata$filename, value = TRUE) # limit to those that are for data
docfiles <- grep("^nam\\d\\dinp\\.txt", fdocs$filename, ignore.case = TRUE, value = TRUE) # limit to those that are for data.  
file_list <- data.frame(datafiles, docfiles) 

# --------------------------------------------------------------------------------------------------
# run download and save to local disk
# note that "UTF-8" seems to work the best.  Unsure of exact formatting.  "US-ASCII" and "ASCII" did not work. Neither did default.
get_save_files(file_list, namcs_dir, encoding = "UTF-8")



