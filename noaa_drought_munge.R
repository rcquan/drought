setwd("/Users/Quan/GitHub/drought/")
library(dplyr)

df <- read.csv("ish-history.csv", stringsAsFactors = FALSE)
names(df) <- tolower(names(df))

df_ca <- df %>%
    filter(ctry == "US" & state == "CA") %>%
    mutate(filename = sprintf("%s-%s-2014.gz", usaf, wban)) %>%
    group_by(state) %>%
    summarise(count = n())