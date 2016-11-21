init_map <- function() {
    
    library(ggmap) 
    library(dplyr)
    library(rgeos)
    library(rgdal)
    library(maptools)
    library(mapproj)
    
    italy_map <- readRDS("ITA_adm2.rds")
    bb_italy <- bbox(italy_map)
    center_location <<- (bb_italy - rowMeans(bb_italy)) * 1.05 + rowMeans(bb_italy)
    
    vote_results <<- transform(vote_results, big_area = as.character(big_area))
    geo_results <<- fortify(italy_map, region = "NAME_1")
    geo_results <<- left_join(geo_results, vote_results,
                           by = c("id" = "big_area"))
}

plot_poltype_map <- function(index = "text") {
    
    init_map()
    
    # Political map
    blank_theme <- theme_minimal() +
        theme(
            axis.title.x = element_blank(),
            axis.title.y = element_blank(),
            axis.text.x = element_blank(),
            axis.text.y = element_blank(),
            panel.border = element_blank(),
            panel.grid=element_blank(),
            axis.ticks = element_blank(),
            plot.title=element_text(size = 14, face = "bold")
        )
    
    filen <- paste("c:/Users/SIMONENB/Desktop/gif/map/", as.character(index), ".png", sep = "")

    poltype_map <- ggmap(get_map(location = b, source = "stamen", maptype = "toner", crop = TRUE), darken = c(1, "white")) +
        ggtitle(paste("Heatmap - ", as.character(index), sep = ""))
    poltype_map + blank_theme + 
        geom_polygon(data = geo_results,
                     aes(x = long, y = lat, group = group, fill = tendency),
                     alpha = 1, color = "#525252") +
        theme(legend.title = element_blank()) +
        scale_fill_gradient(low = "#F74802", high = "#F7DE02",
                            breaks = c(min(geo_results$tendency[!is.na(geo_results$tendency)]), max(geo_results$tendency[!is.na(geo_results$tendency)])),
                            labels = c("No", "Yes"))
    
    ggsave(filen, width = 13.2, height = 9.2, units = "cm", dpi = 100)
}


