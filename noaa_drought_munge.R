#############################
# Ryan Quan
# NOAA Drought Data
# 
# 2014-09-15
#
# The following code gets
# data from NOAA
#############################
library(dplyr)
library(rJava)
library(stringr)
library(GEOquery)


setwd("/Users/Quan/GitHub/drought/")

dir.create("data")
baseURL <- "ftp://ftp.ncdc.noaa.gov/pub/data/noaa/2014/"

#############################
# DOWNLOADING THE DATA
#############################
if(!file.exists("ish_history.csv")){
    download.file("ftp://ftp.ncdc.noaa.gov/pub/data/noaa/ish-history.csv",
                  "ish_history.csv")
}
df <- read.csv("ish-history.csv", stringsAsFactors = FALSE)

# change column names to lowercase
names(df) <- tolower(names(df))

# constructing the url path
df_ca <- df %>%
    # get only stations in US and CA
    filter(ctry == "US" & state == "CA") %>%
    filter(str_detect(end, "2014[0-9]*")) %>%
    mutate(file = sprintf("%s-%s-2014.gz", usaf, wban),
           url = sprintf("%s%s-%s-2014.gz", baseURL, usaf, wban)) %>%
    select(file, url)

file <- df_ca$file
url <- df_ca$url

# get data from NOAA website
setwd("data")
dwnld_errors <- vector()
for(i in 1:length(file)){
    if(!file.exists(file)){
        # ERROR HANDLING
        tryCatch({
            download.file(url[i], file[i])
            # line unable to read in data to dwnld_errors
        }, error = function(e){dwnld_errors <- append(dwnld_errors, file[i])})
    } 
}

#############################
# DATA PROCESSING
#############################

# get list of files in directory
zip_file <- list.files(pattern = ".gz")
# unzip the .gz file
sapply(zip_file, gunzip)


#-------JAVA CODE HERE ---------#
