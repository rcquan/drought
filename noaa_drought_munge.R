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


dir_base <- "/Users/Quan/Github/drought"
dir_data <- sprintf("%s/data", dir_base)
dir_java <- sprintf("%s/ishJava", dir_base)
baseURL <- "ftp://ftp.ncdc.noaa.gov/pub/data/noaa/2014/"

setwd(dir_base)
dir.create("data")

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
setwd(dir_data)
for(i in 1:length(file)){
    if(!file.exists(file[i])){
        # ERROR HANDLING
        tryCatch(
            {
                message(paste("Downloading", file[i]))
                download.file(url[i], file[i])
            }, 
            # would like to add broken urls to vector ****
            error = function(e){
                message(paste("URL does not seem to exist:", file[i]))
            }
        )
    } 
}

#############################
# FILE PROCESSING
#############################

# get list of files in directory
zip_file <- list.files(pattern = ".gz")
# unzip the .gz file, output to .txt
sapply(zip_file, gunzip)

# runs java from command line to convert to
# abbreviated ISH format
setwd(dir_data)

file <- list.files(pattern = "[^.gz]") 

for(i in file){
    input <- sprintf("%s", i)
    output <- sprintf("%s.out", i)
    if(!file.exists(output)){
        system(sprintf("java -classpath . ishJava %s %s", input, output))   
    }
}

#############################
# READING DATA
#############################

# get all files with extension
file_list <- as.list(list.files(pattern = ".out"))
# preallocate list and load data
data_list <- vector("list", length = length(file_list))

read_list <- function (X) {
    # reads table into list, returns null upon error
    return(tryCatch(read.table(X), error=function(e) NULL))
}

data_list <- lapply(file_list, read_list)

