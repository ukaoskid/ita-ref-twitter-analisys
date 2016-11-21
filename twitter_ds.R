process_datasets <- function(filter = "std") {
    
    library(dplyr)
    library(sqldf)
    
    query <- "select screenName from tweets_global group by screenName"
    if (filter != "std") {
        query <- paste("select screenName from tweets_global where ext_filter <= '", filter, "' group by screenName", sep = "")
    }
    # Grouping Twitter users
    global_users <<- sqldf(query)
    
    sub_vote_query <- sqldf(paste("select screenName, count(case when will_vote = 'YES' then 1 end) as v_yes,
                                count(case when will_vote = 'NO' then 1 end) as v_no from tweets_global group by screenName", sep = ""))

    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes == v_no, "UD", ifelse(v_yes > v_no, "YES", "NO")))
    sub_vote_query <- mutate(sub_vote_query, will_vote = ifelse(v_yes > 0 & v_no > 0, ifelse(abs(v_yes - v_no) < 10, "UD", will_vote), will_vote))
    
    sub_marea_query <- sqldf(paste("select screenName, big_area, geo_district, count(big_area) as metro_counter from tweets_global
                        group by screenName, big_area, geo_district", sep = ""))
    
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
    
    # Aggregating users results for voting
    vote_results <<- sqldf("select big_area, geo_district,
                          count(case when will_vote = 'YES' then 1 end) as v_yes,
                          count(case when will_vote = 'NO' then 1 end) as v_no,
                          count(case when will_vote = 'UD' then 1 end) as v_ud
                          from global_users
                          group by big_area, geo_district")
    vote_results <<- mutate(vote_results, perc_y = 0, perc_n = 0, perc_ud = 0, tendency = 0, winner = "")
    
    # Calculating percentage of tendency in Metropolitan Cities
    for (i in 1:nrow(vote_results)) {
        
        wyes <- round(vote_results$v_yes[i] / (vote_results$v_yes[i] + vote_results$v_no[i] + vote_results$v_ud[i]), 2)
        wno <- round(vote_results$v_no[i] / (vote_results$v_yes[i] + vote_results$v_no[i] + vote_results$v_ud[i]), 2)
        wud <- round(vote_results$v_ud[i] / (vote_results$v_yes[i] + vote_results$v_no[i] + vote_results$v_ud[i]), 2)
        
        vote_results$perc_y[i] <- wyes
        vote_results$perc_n[i] <- wno
        vote_results$perc_ud[i] <- wud
        
        if (wyes > wno) {
            
            vote_results$tendency[i] <- wyes - 0.50
            vote_results$winner[i] <- "Y"
        } else if (wno > wyes) {
            
            vote_results$tendency[i] <- (wno - 0.50) * -1
            vote_results$winner[i] <- "N"
        } else if (wyes == wno) {
            
            vote_results$tendency[i] <- 0
            vote_results$winner[i] <- "U"          
        }
    }
    
    vote_results <<- vote_results
    
    # Calculating results for Big Areas
    big_area_results <<- sqldf("select big_area, sum(v_yes) as tot_yes, sum(v_no) as tot_no, sum(v_ud) as tot_ud
                              from vote_results group by big_area")
    big_area_results <<- mutate(big_area_results, perc_y = 0, perc_n = 0)
    
    big_area_chart <<- data.frame()
    for (i in 1:nrow(big_area_results)) {
        
        wyes <- round(big_area_results$tot_yes[i] / (big_area_results$tot_yes[i] + big_area_results$tot_no[i] + big_area_results$tot_ud[i]), 2)
        wno <- round(big_area_results$tot_no[i] / (big_area_results$tot_yes[i] + big_area_results$tot_no[i] + big_area_results$tot_ud[i]), 2)
        wud <- round(big_area_results$tot_ud[i] / (big_area_results$tot_yes[i] + big_area_results$tot_no[i] + big_area_results$tot_ud[i]), 2)
        
        big_area_results$perc_y[i] <- wyes
        big_area_results$perc_n[i] <- wno
        big_area_results$perc_ud[i] <- wud
        
        temp_wyes <- data.frame(big_area = big_area_results$big_area[i], full_perc = wyes, sign = "Y")
        temp_wno <- data.frame(big_area = big_area_results$big_area[i], full_perc = wno, sign = "N")
        temp_wud <- data.frame(big_area = big_area_results$big_area[i], full_perc = wud, sign = "U")
        
        big_area_chart <<- rbind(big_area_chart, temp_wyes)
        big_area_chart <<- rbind(big_area_chart, temp_wno)
        big_area_chart <<- rbind(big_area_chart, temp_wud)
    }
    
    # Calculating results for Geo district
    geo_distric_results <<- sqldf("select geo_district, sum(v_yes) as tot_yes, sum(v_no) as tot_no, sum(v_ud) as tot_ud
                              from vote_results group by geo_district")
    geo_distric_results <<- mutate(geo_distric_results, perc_y = 0, perc_n = 0)
    
    geo_district_chart <<- data.frame()
    for (i in 1:nrow(geo_distric_results)) {
        
        wyes <- round(geo_distric_results$tot_yes[i] / (geo_distric_results$tot_yes[i] + geo_distric_results$tot_no[i] + geo_distric_results$tot_ud[i]), 2)
        wno <- round(geo_distric_results$tot_no[i] / (geo_distric_results$tot_yes[i] + geo_distric_results$tot_no[i] + geo_distric_results$tot_ud[i]), 2)
        wud <- round(geo_distric_results$tot_ud[i] / (geo_distric_results$tot_yes[i] + geo_distric_results$tot_no[i] + geo_distric_results$tot_ud[i]), 2)
        
        geo_distric_results$perc_y[i] <- wyes
        geo_distric_results$perc_n[i] <- wno
        geo_distric_results$perc_ud[i] <- wud
        
        temp_wyes <- data.frame(big_area = geo_distric_results$geo_district[i], full_perc = wyes, sign = "Y")
        temp_wno <- data.frame(big_area = geo_distric_results$geo_district[i], full_perc = wno, sign = "N")
        temp_wud <- data.frame(big_area = geo_distric_results$geo_district[i], full_perc = wud, sign = "U")
        
        geo_district_chart <<- rbind(geo_district_chart, temp_wyes)
        geo_district_chart <<- rbind(geo_district_chart, temp_wno)
        geo_district_chart <<- rbind(geo_district_chart, temp_wud)
    }    
}

rolling_total <- function(date = "") {
    
    # Final national pie chart
    total_yes <- sqldf("select sum(v_yes) as tot_yes from vote_results")
    total_no <- sqldf("select sum(v_no) as tot_no from vote_results")
    total_ud <- sqldf("select sum(v_ud) as tot_ud from vote_results")
    
    total_yes_df <- data.frame("Date" = date, "Sign" = "YES", "value" = round((total_yes$tot_yes / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_no_df <- data.frame("Date" = date, "Sign" = "NO", "value" = round((total_no$tot_no / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_ud_df <- data.frame("Date" = date, "Sign" = "UD", "value" = round((total_ud$tot_ud / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    
    temp_rolling_df <- rbind(total_yes_df, total_no_df, total_ud_df)
    rolling_values <<- rbind(rolling_values,temp_rolling_df)
}

plot_rolling_total <- function(index = "rchart") {

    library(sqldf)
    library(ggplot2)
    
    filen <- paste("c:/Users/SIMONENB/Desktop/gif/rolling_chart/", as.character(index), ".png", sep = "")
    
    rolling_total_chart <- ggplot(data=rolling_values, aes(x=Date, y=value, group = Sign, colour = Sign)) +
        geom_line() +
        geom_point( size=4, shape=21, fill="white") +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
    
    ggsave(filen, width = 13.2, height = 9.2, units = "cm", dpi = 100)
}

plot_charts <- function(index = "chart") {
    
    library(ggplot2)
    
    blank_theme_hist <- theme_minimal() +
        theme(
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            panel.border = element_blank(),
            panel.grid=element_blank(),
            axis.ticks = element_blank(),
            plot.title=element_text(size = 14, face = "bold")
        )
    
    filen <- paste("c:/Users/SIMONENB/Desktop/gif/big_area_hist/", as.character(index), ".png", sep = "")
    
    big_area_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = big_area, fill = sign), data = big_area_chart, stat="identity") +
        ggtitle(paste("Big Area - ", as.character(index), sep = ""))
    big_area_stacked <- big_area_stacked + blank_theme_hist +
        geom_text(data = big_area_chart,aes(x = big_area, y = full_perc * 100, label = "")) +
        theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
        scale_fill_manual(values = c("#F8766D", "#00BCF4", "#EBEBEB"))
    
    ggsave(filen, width = 13.2, height = 9.2, units = "cm", dpi = 100)
    
    filen <- paste("c:/Users/SIMONENB/Desktop/gif/geo_hist/", as.character(index), ".png", sep = "")
    
    geo_district_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = big_area, fill = sign), data = geo_district_chart, stat="identity") +
        ggtitle(paste("Geo District - ", as.character(index), sep = ""))
    geo_district_stacked <- geo_district_stacked + blank_theme_hist +
        geom_text(data = geo_district_chart, aes(x = big_area, y = full_perc * 100, label = "")) +
        scale_fill_manual(values = c("#F8766D", "#00BCF4", "#EBEBEB"))
    
    ggsave(filen, width = 13.2, height = 9.2, units = "cm", dpi = 100)
    
    # Final national pie chart
    total_yes <- sqldf("select sum(v_yes) as tot_yes from vote_results")
    total_no <- sqldf("select sum(v_no) as tot_no from vote_results")
    total_ud <- sqldf("select sum(v_ud) as tot_ud from vote_results")
    
    total_yes_df <- data.frame("Sign" = "YES", "value" = round((total_yes$tot_yes / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_no_df <- data.frame("Sign" = "NO", "value" = round((total_no$tot_no / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    total_ud_df <- data.frame("Sign" = "UD", "value" = round((total_ud$tot_ud / (total_yes$tot_yes + total_no$tot_no + total_ud$tot_ud)) * 100, 2))
    
    pie_values <- rbind(total_yes_df, total_no_df, total_ud_df)
    
    filen <- paste("c:/Users/SIMONENB/Desktop/gif/national_pie/", as.character(index), ".png", sep = "")
    
    pie_plot<- ggplot(pie_values, aes(x="", y = value, fill = Sign)) +
        geom_bar(width = 1, stat = "identity")
    pie_final <- pie_plot + coord_polar("y", start=0) + blank_theme +
        theme(axis.text.x = element_blank()) +
        geom_text(data = pie_values, aes(x = "", y = value, label = "")) +
        scale_fill_manual(values=c("#F8766D", "#00BCF4", "#EBEBEB"))
    pie_final
    
    ggsave(filen, width = 13.2, height = 9.2, units = "cm", dpi = 100)
}