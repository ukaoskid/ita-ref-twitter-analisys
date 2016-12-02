tweets_data <- function() {
    
    # Calculate Tweets vs Retweets
    tweets_no <- sqldf("select count(*) from tweets_global where isRetweet = 0")
    retweets_no <- sqldf("select count(*) from tweets_global where isRetweet = 1")
    
    tweets_perc <<- round(tweets_no / (tweets_no + retweets_no), 2) * 100
    retweets_perc <<- round(retweets_no / (tweets_no + retweets_no), 2) * 100
    
    # Calculate possibile user propagation
    global_users <<- mutate(global_users, possible_propagation = 0)
    
    for (i in 13571:nrow(global_users)) {
        
        print(i)
        temp_user = getUser(global_users$screenName[i])
        global_users$possible_propagation[i] <- temp_user$followersCount
    }
    
    global_users <<- global_users
    
    possible_no_prop <- sqldf("select sum(possible_propagation) from global_users where will_vote = 'NO'")
    possible_yes_prop <- sqldf("select sum(possible_propagation) from global_users where will_vote = 'YES'")
}

calculate_cumulative_trend <- function(filter = "std") {
    
    query <- "select screenName from tweets_global "
    query_filter <- ""
    if (filter != "std") {
        print("cumulative filtering by date")
        query_filter <- paste("where ext_filter <= '", filter, "'", sep = "")
        query <- paste(query, query_filter, " group by screenName", sep = "")
    }
    
    # Grouping Twitter users
    global_users <<- sqldf(query)
    
    sub_vote_query <- sqldf(paste("select screenName, count(case when will_vote = 'YES' then 1 end) as v_yes,
                                count(case when will_vote = 'NO' then 1 end) as v_no from tweets_global ",
                                  query_filter, " group by screenName", sep = ""))
    
    # Identifying unclear users
    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes == v_no, "UD", ifelse(v_yes > v_no, "YES", "NO")))
    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes > 0 & v_no > 0, ifelse(abs(v_yes - v_no) < 10, "UD", will_vote), will_vote))
    
    sub_marea_query <- sqldf(paste("select screenName, big_area, geo_district, count(big_area) as metro_counter from tweets_global ",
                                   query_filter, " group by screenName, big_area, geo_district", sep = ""))
    
    sub_marea_query <- sqldf(paste("select screenName, big_area, geo_district, sum(metro_counter) as metro_counter from sub_marea_query
                        group by screenName, big_area, geo_district", sep = ""))
    
    sub_marea_query <- sqldf("select screenName,
	                    (select big_area from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as big_area,
                        (select geo_district from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as geo_district,
                        (select metro_counter from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as metro_counter
                        from sub_marea_query tg group by screenName")
    
    
    global_users <<- left_join(global_users, sub_vote_query,
                               by = c("screenName" = "screenName"))
    global_users <<- left_join(global_users, sub_marea_query,
                               by = c("screenName" = "screenName"))
}

calculate_daily_trend <- function(filter = "std") {
    
    query <- "select screenName from tweets_global "
    query_filter <- ""
    if (filter != "std") {
        print("daily filtering by date")
        query_filter <- paste("where ext_filter = '", filter, "'", sep = "")
        query <- paste(query, query_filter, " group by screenName", sep = "")
    }
    
    # Grouping Twitter users
    global_users_daily <<- sqldf(query)
    
    sub_vote_query <- sqldf(paste("select screenName, count(case when will_vote = 'YES' then 1 end) as v_yes,
                                  count(case when will_vote = 'NO' then 1 end) as v_no from tweets_global ",
                                  query_filter, " group by screenName", sep = ""))
    
    # Identifying unclear users
    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes == v_no, "UD", ifelse(v_yes > v_no, "YES", "NO")))
    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes > 0 & v_no > 0, ifelse(abs(v_yes - v_no) < 10, "UD", will_vote), will_vote))
    
    sub_marea_query <- sqldf(paste("select screenName, big_area, geo_district, count(big_area) as metro_counter from tweets_global ",
                                   query_filter, " group by screenName, big_area, geo_district", sep = ""))
    
    sub_marea_query <- sqldf(paste("select screenName, big_area, geo_district, sum(metro_counter) as metro_counter from sub_marea_query
                                   group by screenName, big_area, geo_district", sep = ""))
    
    sub_marea_query <- sqldf("select screenName,
                             (select big_area from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as big_area,
                             (select geo_district from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as geo_district,
                             (select metro_counter from sub_marea_query where screenName = tg.screenName order by metro_counter desc limit 1) as metro_counter
                             from sub_marea_query tg group by screenName")
    
    
    global_users_daily <<- left_join(global_users_daily, sub_vote_query,
                               by = c("screenName" = "screenName"))
    global_users_daily <<- left_join(global_users_daily, sub_marea_query,
                               by = c("screenName" = "screenName"))
}

calculate_tendency <- function(vote_dataset) {
    
    vote_dataset <<- mutate(vote_results, perc_y = 0, perc_n = 0, perc_ud = 0, tendency = 0, winner = "")
    
    for (i in 1:nrow(vote_dataset)) {
        
        wyes <- round(vote_dataset$v_yes[i] / (vote_dataset$v_yes[i] + vote_dataset$v_no[i] + vote_dataset$v_ud[i]), 2)
        wno <- round(vote_dataset$v_no[i] / (vote_dataset$v_yes[i] + vote_dataset$v_no[i] + vote_dataset$v_ud[i]), 2)
        wud <- round(vote_dataset$v_ud[i] / (vote_dataset$v_yes[i] + vote_dataset$v_no[i] + vote_dataset$v_ud[i]), 2)
        
        vote_dataset$perc_y[i] <- wyes
        vote_dataset$perc_n[i] <- wno
        vote_dataset$perc_ud[i] <- wud
        
        if (wyes > wno) {
            
            vote_dataset$tendency[i] <- wyes - 0.50
            vote_dataset$winner[i] <- "Y"
        } else if (wno > wyes) {
            
            vote_dataset$tendency[i] <- (wno - 0.50) * -1
            vote_dataset$winner[i] <- "N"
        } else if (wyes == wno) {
            
            vote_dataset$tendency[i] <- 0
            vote_dataset$winner[i] <- "U"          
        }
    }
    
    return(vote_dataset)
}

calculate_geo_tendency <- function(geo_dataset) {
    
    geo_dataset <- mutate(geo_dataset, perc_y = 0, perc_n = 0)
    
    geo_dataset_chart <- data.frame()
    for (i in 1:nrow(geo_dataset)) {
        
        wyes <- round(geo_dataset$tot_yes[i] / (geo_dataset$tot_yes[i] + geo_dataset$tot_no[i] + geo_dataset$tot_ud[i]), 2)
        wno <- round(geo_dataset$tot_no[i] / (geo_dataset$tot_yes[i] + geo_dataset$tot_no[i] + geo_dataset$tot_ud[i]), 2)
        wud <- round(geo_dataset$tot_ud[i] / (geo_dataset$tot_yes[i] + geo_dataset$tot_no[i] + geo_dataset$tot_ud[i]), 2)
        
        geo_dataset$perc_y[i] <- wyes
        geo_dataset$perc_n[i] <- wno
        geo_dataset$perc_ud[i] <- wud
        
        temp_wyes <- data.frame(geo_area = geo_dataset$geo_area[i], full_perc = wyes, sign = "Y")
        temp_wno <- data.frame(geo_area = geo_dataset$geo_area[i], full_perc = wno, sign = "N")
        temp_wud <- data.frame(geo_area = geo_dataset$geo_area[i], full_perc = wud, sign = "U")
        
        geo_dataset_chart <- rbind(geo_dataset_chart, temp_wyes)
        geo_dataset_chart <- rbind(geo_dataset_chart, temp_wno)
        geo_dataset_chart <- rbind(geo_dataset_chart, temp_wud)
    }
    
    return_list <- list()
    return_list$dataset <- geo_dataset
    return_list$chart <- geo_dataset_chart
    
    return(return_list)
}

process_datasets <- function(filter = "std") {
    
    library(dplyr)
    library(sqldf)
    
    calculate_cumulative_trend(filter)
    calculate_daily_trend(filter)
    
    # Aggregating users cumulative results for voting
    vote_results <<- sqldf("select big_area, geo_district,
                          count(case when will_vote = 'YES' then 1 end) as v_yes,
                          count(case when will_vote = 'NO' then 1 end) as v_no,
                          count(case when will_vote = 'UD' then 1 end) as v_ud
                          from global_users
                          group by big_area, geo_district")

    
    # Calculating percentage of tendency in Metropolitan Cities
    vote_results <<- calculate_tendency(vote_results)
    
    # Aggregating users daily results for voting
    vote_results_daily <<- sqldf("select big_area, geo_district,
                                 count(case when will_vote = 'YES' then 1 end) as v_yes,
                                 count(case when will_vote = 'NO' then 1 end) as v_no,
                                 count(case when will_vote = 'UD' then 1 end) as v_ud
                                 from global_users_daily
                                 group by big_area, geo_district")
    
    # Calculating percentage of tendency in Metropolitan Cities
    vote_results_daily <<- calculate_tendency(vote_results_daily)
    
    # Calculating results for Big Areas
    big_area_results <<- sqldf("select big_area as geo_area, sum(v_yes) as tot_yes, sum(v_no) as tot_no, sum(v_ud) as tot_ud
                              from vote_results group by big_area")
    big_area_calculation <- calculate_geo_tendency(big_area_results)
    
    big_area_results <<- big_area_calculation$dataset
    big_area_chart <<- big_area_calculation$chart
    
    # Calculating results for Geo district
    geo_distric_results <<- sqldf("select geo_district as geo_area, sum(v_yes) as tot_yes, sum(v_no) as tot_no, sum(v_ud) as tot_ud
                              from vote_results group by geo_district")
    geo_distric_calculation <- calculate_geo_tendency(geo_distric_results)
    
    geo_distric_results <<- geo_distric_calculation$dataset
    geo_district_chart <<- geo_distric_calculation$chart
}

rolling_total <- function(date = "") {
    
    # Final national pie chart
    total_yes <- sqldf("select sum(v_yes) as tot_yes from vote_results")
    total_no <- sqldf("select sum(v_no) as tot_no from vote_results")
    total_ud <- sqldf("select sum(v_ud) as tot_ud from vote_results")
    total_yes_d <- sqldf("select sum(v_yes) as tot_yes_d from vote_results_daily")
    total_no_d <- sqldf("select sum(v_no) as tot_no_d from vote_results_daily")
    total_ud_d <- sqldf("select sum(v_ud) as tot_ud_d from vote_results_daily")
    
    total_yes_df <- data.frame("Date" = date, "Sign" = "YES", "value" = round((total_yes$tot_yes / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_yes_df_d <- data.frame("Date" = date, "Sign" = "YES_D", "value" = round((total_yes_d$tot_yes_d / (total_yes_d$tot_yes_d + total_no_d$tot_no_d + total_ud_d$tot_ud_d)) * 100, 2))
    
    total_no_df <- data.frame("Date" = date, "Sign" = "NO", "value" = round((total_no$tot_no / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_no_df_d <- data.frame("Date" = date, "Sign" = "NO_D", "value" = round((total_no_d$tot_no_d / (total_yes_d$tot_yes_d + total_no_d$tot_no_d + total_ud_d$tot_ud_d)) * 100, 2))
    
    total_ud_df <- data.frame("Date" = date, "Sign" = "UD", "value" = round((total_ud$tot_ud / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_ud_df_d <- data.frame("Date" = date, "Sign" = "UD_D", "value" = round((total_ud_d$tot_ud_d / (total_yes_d$tot_yes_d + total_no_d$tot_no_d + total_ud_d$tot_ud_d)) * 100, 2))
        
    temp_rolling_df <- rbind(total_yes_df, total_yes_df_d, total_no_df, total_no_df_d, total_ud_df, total_ud_df_d)
    rolling_values <<- rbind(rolling_values, temp_rolling_df)
}

plot_rolling_total <- function(index = "rchart") {

    library(sqldf)
    library(ggplot2)
    
    filen <- paste("~/imgs/rolling_chart/", as.character(index), ".png", sep = "")
    
    rolling_total_chart <- ggplot(data = rolling_values, aes(x = Date, y = value, group = Sign, colour = Sign)) +
        geom_line() +
        geom_point(size = 1, shape = 21, fill = "white") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
    
    ggsave(filen, width = 16.2, height = 9.2, units = "cm", dpi = 200)
}

plot_charts <- function(index = "chart") {
    
    library(ggplot2)
    
    blank_theme_hist <- theme_minimal() +
        theme(
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            panel.border = element_blank(),
            panel.grid = element_blank(),
            axis.ticks = element_blank(),
            plot.title = element_text(size = 14, face = "bold")
        )
    
    filen <- paste("~/imgs/big_area_hist/", as.character(index), ".png", sep = "")
    
    big_area_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = geo_area, fill = sign), data = big_area_chart, stat = "identity") +
        ggtitle(paste("Big Area - ", as.character(index), sep = ""))
    big_area_stacked <- big_area_stacked + blank_theme_hist +
        geom_text(data = big_area_chart,aes(x = geo_area, y = full_perc * 100, label = "")) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        scale_fill_manual(values = c("#F8766D", "#00BCF4", "#EBEBEB"))
    
    ggsave(filen, width = 16.2, height = 9.2, units = "cm", dpi = 200)
    
    filen <- paste("~/imgs/geo_hist/", as.character(index), ".png", sep = "")
    
    geo_district_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = geo_area, fill = sign), data = geo_district_chart, stat = "identity") +
        ggtitle(paste("Geo District - ", as.character(index), sep = ""))
    geo_district_stacked <- geo_district_stacked + blank_theme_hist +
        geom_text(data = geo_district_chart, aes(x = geo_area, y = full_perc * 100, label = "")) +
        scale_fill_manual(values = c("#F8766D", "#00BCF4", "#EBEBEB"))
    
    ggsave(filen, width = 16.2, height = 9.2, units = "cm", dpi = 200)
    
    # Final national pie chart
    total_yes <- sqldf("select sum(v_yes) as tot_yes from vote_results")
    total_no <- sqldf("select sum(v_no) as tot_no from vote_results")
    total_ud <- sqldf("select sum(v_ud) as tot_ud from vote_results")
    
    total_yes_df <- data.frame("Sign" = "YES", "value" = round((total_yes$tot_yes / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_no_df <- data.frame("Sign" = "NO", "value" = round((total_no$tot_no / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_ud_df <- data.frame("Sign" = "UD", "value" = round((total_ud$tot_ud / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    
    pie_values <- rbind(total_yes_df, total_no_df, total_ud_df)
    
    filen <- paste("~/imgs/national_pie/", as.character(index), ".png", sep = "")
    
    pie_plot<- ggplot(pie_values, aes(x="", y = value, fill = Sign)) +
        geom_bar(width = 1, stat = "identity")
    pie_final <- pie_plot + coord_polar("y", start = 0) + blank_theme +
        theme(axis.text.x = element_blank()) +
        geom_text(data = pie_values, aes(x = "", y = value, label = "")) +
        scale_fill_manual(values = c("#F8766D", "#00BCF4", "#EBEBEB"))
    pie_final
    
    ggsave(filen, width = 16.2, height = 9.2, units = "cm", dpi = 200)
}