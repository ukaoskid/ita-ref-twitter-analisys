# Twitter data collection for Italian Referendum Vote Day
# This study has to be intended for a experimental purpose
#
# Prerequisites:
#
# - Taking tweets by geolocation filtering.
# - Geolocation granularity level: Local discrict (Province)
# - Positive and negative meaning hastags cannot coexsists in the same tweet
# - User are grouped simulating one vote
#
# Output data for YES and NO:
# - Italian heatmap
# - Daily mean trend
# - Tweet/Retweet ratio
#
# The study will underline also unconfident users with this social network:
# - % of uncomplete profiles
# - % of incorrect/deceiptive profiles

library(twitteR)
library(RCurl)
library(stringr)
library(dplyr)
library(lubridate)
library(sqldf)
library(ggmap)
library(ggplot2)
source("twitter_map.R")
source("twitter_ds.R")

api_key <- "T7AvLRoNhQmur8hwDp87PDlIW"
api_secret <- "gogtlL294hRd1NpsPAfFWXnLntI2MDgA5iAPR2IFSEtam4it9w"
token <- "4284853821-CDiJKgDtSmIkomdSec23fEwiWJtZaF818F7bhEi"
token_secret <- "TdYlBlHUDmWXWYwYiRk1G6bLitaWesXP15H1NM0ScCx2P"

ext_dates <- c("2016-11-30")
unt_dates <- c("2016-12-01")

tags_NO <- "#IoVotoNO OR #BastaUnNO OR #IoDicoNO OR #VotaNO"
tags_YES <- "#IoVotoSI OR #BastaUnSI OR #IoDicoSI OR #VotaSI OR #IoVotoSì OR #BastaUnSì OR #IoDicoSì OR #VotaSì"
grep_filter_NO <- "/#bastaunsi|#iovotosi|#iodicosi|#votasi|#bastaunsì|#iovotosì|#iodicosì|#votasì/ig"
grep_filter_YES <- "/#bastaunno|#iovotono|#iodicono|#votano/ig"
geo_areas <- read.csv("italian-geopolitic-subdivision.csv", sep = ";")
geo_areas <- mutate(geo_areas, GADMCode = as.character(GADMCode))

# Create Twitter Connection
setup_twitter_oauth(api_key, api_secret, token, token_secret)

if (!exists("tweets_global")) {
    tweets_global <<- data.frame()
}

for (i in 1:length(ext_dates)) {
    
    print(ext_dates[i])
    
    for (j in 1:nrow(geo_areas)) {
        
        geo_query <- paste(geo_areas$Latitude[j], ",", geo_areas$Longitude[j], ",", geo_areas$Radius[j], "km", sep = "")
        
        tweets_NO <- searchTwitter(tags_NO, geocode = geo_query, n = 5000, since = ext_dates[i], until = unt_dates[i], lang = "it")
        tweets_YES <- searchTwitter(tags_YES, geocode = geo_query, n = 5000, since = ext_dates[i], until = unt_dates[i], lang = "it")
       
        if (length(tweets_NO) > 0) {
            
            tweets_NO_df <- twListToDF(tweets_NO)
            
            # Cleaning NO tweets
            tweets_NO_df <- subset(tweets_NO_df, !grepl(grep_filter_NO, tweets_NO_df[["text"]]))
            tweets_NO_df <- mutate(tweets_NO_df, extraction_date = ymd(ext_dates[i]))
            tweets_NO_df <- mutate(tweets_NO_df, will_vote = "NO", metro_area = geo_areas$GADMCode[j],
                                   big_area = geo_areas$BigArea[j], geo_district = geo_areas$GeoDistrict[j],
                                   lat = geo_areas$Latitude[j], lon = geo_areas$Longitude[j], ext_filter = "")
            
            # Merging datasets
            tweets_global <- rbind(tweets_global, tweets_NO_df)
        }
        
        if (length(tweets_YES) > 0) {  
            
            tweets_YES_df <- twListToDF(tweets_YES)
            
            # Cleaning YES tweets
            tweets_YES_df <- subset(tweets_YES_df, !grepl(grep_filter_YES, tweets_YES_df[["text"]]))
            tweets_YES_df <- mutate(tweets_YES_df, extraction_date = ymd(ext_dates[i]))
            tweets_YES_df <- mutate(tweets_YES_df, will_vote = "YES", metro_area = geo_areas$GADMCode[j],
                                    big_area = geo_areas$BigArea[j], geo_district = geo_areas$GeoDistrict[j],
                                    lat = geo_areas$Latitude[j], lon = geo_areas$Longitude[j], ext_filter = "")
            
            tweets_global <- rbind(tweets_global, tweets_YES_df)
        }

        rm(tweets_NO)
        rm(tweets_YES)
        rm(tweets_NO_df)
        rm(tweets_YES_df)
    }
}

tweets_global <- mutate(tweets_global, ext_filter = as.character(extraction_date))

ledate <- c("2016-11-03", "2016-11-04", "2016-11-05", "2016-11-06","2016-11-07", "2016-11-08", "2016-11-09", "2016-11-10", "2016-11-11", "2016-11-12",
            "2016-11-13", "2016-11-14", "2016-11-15", "2016-11-16", "2016-11-17", "2016-11-18", "2016-11-19", "2016-11-20", "2016-11-21",
            "2016-11-22", "2016-11-23", "2016-11-24", "2016-11-25", "2016-11-26", "2016-11-27", "2016-11-28", "2016-11-29", "2016-11-30")
if (exists("rolling_values")) {
    rm(rolling_values)
    rolling_values <<- data.frame()
}

for (k in 1:length(ledate)) {
    
    print(ledate[k])
    process_datasets(ledate[k])
    rolling_total(ledate[k])
    plot_rolling_total(ledate[k])
    plot_poltype_map(ledate[k])
    plot_charts(ledate[k])
}


# Process datasets
process_datasets()

# Plot charts
plot_charts()

# Map
plot_poltype_map(1)
