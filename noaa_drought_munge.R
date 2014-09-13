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

setwd(dir_base)
dir.create("data")
dir.create("ishJava")

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
setwd(dir_data)
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
# FILE PROCESSING
#############################

# get list of files in directory
zip_file <- list.files(pattern = ".gz")
# unzip the .gz file
sapply(zip_file, gunzip)

file <- list.files(pattern = "[^.gz]")
file <- list.files(pattern = "[^.class]")


# runs java from command line to convert to
# abbreviated ISH format
setwd(dir_data)

for(i in file){
    input <- sprintf("%s", i)
    output <- sprintf("%s.out", i)
    if(!file.exists(output)){
        system(sprintf("java -classpath . ishJava %s %s.out", input, output))   
    }
}

#############################
# READING DATA
#############################

# get all files with extension
file_list <- as.list(list.files(pattern = ".out"))

# preallocate list and load data
data_list <- vector("list", length = length(file_list))
data_list <- lapply(file_list, read.table, sep = "\t")




