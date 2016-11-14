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
source("twitter_map.R")

api_key <- "api_key"
api_secret <- "api_secret"
token <- "token"
token_secret <- "token_secret"

ext_dates <- c("2016-11-13")
unt_dates <- c("2016-11-14")

tags_NO <- "#IoVotoNO OR #BastaUnNO OR #IoDicoNO OR #VotaNO"
tags_YES <- "#IoVotoSI OR #BastaUnSI OR #IoDicoSI OR #VotaSI OR #IoVotoSì OR #BastaUnSì OR #IoDicoSì OR #VotaSì"
grep_filter_NO <- "/#bastaunsi|#iovotosi|#iodicosi|#votasi|#bastaunsì|#iovotosì|#iodicosì|#votasì/ig"
grep_filter_YES <- "/#bastaunno|#iovotono|#iodicono|#votano/ig"
geo_areas <- read.csv("Italy_MetropolitanAreas.csv", sep = ";")

# Create Twitter Connection
setup_twitter_oauth(api_key, api_secret, token, token_secret)

if (!exists("tweets_global")) {
    tweets_global <- data.frame()
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
            tweets_NO_df <- mutate(tweets_NO_df, will_vote = "NO", metro_area = geo_areas$Code[j],
                                   big_area = geo_areas$BigArea[j], geo_district = geo_areas$GeoDistrict[j],
                                   lat = geo_areas$Latitude[j], lon = geo_areas$Longitude[j])
            
            # Merging datasets
            tweets_global <- rbind(tweets_global, tweets_NO_df)
        }
        
        if (length(tweets_YES) > 0) {  
            
            tweets_YES_df <- twListToDF(tweets_YES)
            
            # Cleaning YES tweets
            tweets_YES_df <- subset(tweets_YES_df, !grepl(grep_filter_YES, tweets_YES_df[["text"]]))
            tweets_YES_df <- mutate(tweets_YES_df, extraction_date = ymd(ext_dates[i]))
            tweets_YES_df <- mutate(tweets_YES_df, will_vote = "YES", metro_area = geo_areas$Code[j],
                                    big_area = geo_areas$BigArea[j], geo_district = geo_areas$GeoDistrict[j],
                                    lat = geo_areas$Latitude[j], lon = geo_areas$Longitude[j])
            
            tweets_global <- rbind(tweets_global, tweets_YES_df)
        }

        rm(tweets_NO)
        rm(tweets_YES)
        rm(tweets_NO_df)
        rm(tweets_YES_df)
    }
}

# Grouping Twitter users
global_users <- sqldf("select screenName, metro_area, big_area, geo_district, will_vote, lat, lon
                      from tweets_global
                      group by screenName, metro_area, big_area, geo_district, will_vote, lat, lon")
global_users <- mutate(global_users, user_location = "")

# Aggregating users results for voting
vote_results <- sqldf("select metro_area, big_area, geo_district,
                        count(case when will_vote = 'YES' then 1 end) as v_yes,
                        count(case when will_vote = 'NO' then 1 end) as v_no
                        from global_users
                        group by metro_area, big_area, geo_district")
vote_results <- mutate(vote_results, ratio = 0, tendency = 0, winner = "")

# Calculating percentage of tendency
for (i in 1:nrow(vote_results)) {
    
    wyes <- round(vote_results$v_yes[i] / (vote_results$v_yes[i] + vote_results$v_no[i]), 2)
    wno <- round(vote_results$v_no[i] / (vote_results$v_yes[i] + vote_results$v_no[i]), 2)
    
    if (wyes > wno) {
        
        vote_results$tendency[i] <- wyes - 0.50
        vote_results$ratio[i] <- wyes
        vote_results$winner[i] <- "Y"
    } else if (wno > wyes) {
        
        vote_results$tendency[i] <- (wno - 0.50) * -1
        vote_results$ratio[i] <- wno
        vote_results$winner[i] <- "N"
    }
}

big_area_results <- sqldf("select big_area, sum(v_yes) as tot_yes, sum(v_no) as tot_no,
                          sum(v_yes) / (sum(v_yes) + sum(v_no)) as ratio_y
                          from vote_results group by big_area")

# Map
plot_poltype_map()
