process_datasets <- function() {
    
    library(dplyr)
    library(sqldf)

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
    vote_results <- mutate(vote_results, perc_y = 0, perc_n = 0, tendency = 0, winner = "")
    
    # Calculating percentage of tendency in Metropolitan Cities
    for (i in 1:nrow(vote_results)) {
        
        wyes <- round(vote_results$v_yes[i] / (vote_results$v_yes[i] + vote_results$v_no[i]), 2)
        wno <- round(vote_results$v_no[i] / (vote_results$v_yes[i] + vote_results$v_no[i]), 2)
        vote_results$perc_y[i] <- wyes
        vote_results$perc_n[i] <- wno
        
        if (wyes > wno) {
            
            vote_results$tendency[i] <- wyes - 0.50
            vote_results$winner[i] <- "Y"
        } else if (wno > wyes) {
            
            vote_results$tendency[i] <- (wno - 0.50) * -1
            vote_results$winner[i] <- "N"
        }
    }
    
    # Calculating results for Big Areas
    big_area_results <- sqldf("select big_area, sum(v_yes) as tot_yes, sum(v_no) as tot_no
                              from vote_results group by big_area")
    big_area_results <- mutate(big_area_results, perc_y = 0, perc_n = 0)
    
    big_area_chart <- data.frame()
    for (i in 1:nrow(big_area_results)) {
        
        wyes <- round(big_area_results$tot_yes[i] / (big_area_results$tot_yes[i] + big_area_results$tot_no[i]), 2)
        wno <- round(big_area_results$tot_no[i] / (big_area_results$tot_yes[i] + big_area_results$tot_no[i]), 2)
        big_area_results$perc_y[i] <- wyes
        big_area_results$perc_n[i] <- wno
        
        temp_wyes <- data.frame(big_area = big_area_results$big_area[i], full_perc = wyes, sign = "Y")
        temp_wno <- data.frame(big_area = big_area_results$big_area[i], full_perc = wno, sign = "N")
        
        big_area_chart <- rbind(big_area_chart, temp_wyes)
        big_area_chart <- rbind(big_area_chart, temp_wno)
    }
    
    # Calculating results for Geo district
    geo_distric_results <- sqldf("select geo_district, sum(v_yes) as tot_yes, sum(v_no) as tot_no
                              from vote_results group by geo_district")
    geo_distric_results <- mutate(geo_distric_results, perc_y = 0, perc_n = 0)
    
    geo_district_chart <- data.frame()
    for (i in 1:nrow(geo_distric_results)) {
        
        wyes <- round(geo_distric_results$tot_yes[i] / (geo_distric_results$tot_yes[i] + geo_distric_results$tot_no[i]), 2)
        wno <- round(geo_distric_results$tot_no[i] / (geo_distric_results$tot_yes[i] + geo_distric_results$tot_no[i]), 2)
        geo_distric_results$perc_y[i] <- wyes
        geo_distric_results$perc_n[i] <- wno
        
        temp_wyes <- data.frame(big_area = geo_distric_results$geo_district[i], full_perc = wyes, sign = "Y")
        temp_wno <- data.frame(big_area = geo_distric_results$geo_district[i], full_perc = wno, sign = "N")
        
        geo_district_chart <- rbind(geo_district_chart, temp_wyes)
        geo_district_chart <- rbind(geo_district_chart, temp_wno)
    }    
    
    
    # Final national pie chart
    total_yes <- sqldf("select sum(v_yes) as tot_yes from vote_results")
    total_no <- sqldf("select sum(v_no) as tot_no from vote_results")
    
    pie_values <- c(
        (total_yes$tot_yes / (total_yes$tot_yes + total_no$tot_no)) * 100, 
        (total_no$tot_no / (total_yes$tot_yes + total_no$tot_no)) * 100)
    
    pie_labels <- c("YES", "NO")
    pie_colors <- c("blue","pink")
    
    pie_val_round <- round(pie_values, 1)
    pie_lab_values <- paste(pie_val_round, "%", sep = "")
    
    pie(pie_values, labels = pie_lab_values, col = pie_colors, main = "National Twitter preference")
    legend("topright", c("YES","NO"), cex = 0.8, fill = pie_colors)
}

plot_charts <- function() {
    
    library(ggplot2)
    
    big_area_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = big_area, fill = sign), data = big_area_chart, stat="identity")
    big_area_stacked <- big_area_stacked + geom_text(data=big_area_chart, aes(x = big_area, y = full_perc * 100, 
                                                    label = paste0(full_perc * 100,"%")), size=4)
    
    geo_district_stacked <<- ggplot() + geom_bar(aes(y = full_perc * 100, x = big_area, fill = sign), data = geo_district_chart, stat="identity")
    geo_district_stacked <- geo_district_stacked + geom_text(data=geo_district_chart, aes(x = big_area, y = full_perc * 100, 
                                                                              label = paste0(full_perc * 100,"%")), size=4)
}