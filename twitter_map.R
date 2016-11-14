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
    
    vote_results <- transform(vote_results, metro_area = as.character(metro_area))
    geo_results <<- fortify(italy_map, region = "HASC_2")
    geo_results <<- left_join(geo_results, vote_results,
                           by = c("id" = "metro_area"))
}

plot_geotype_map <- function() {
    
    init_map()
    
    # Geographic map
    geotype_map <- ggmap(get_map(location = center_location))
    geotype_map +
        poltype_map +
        geom_polygon(data = geo_results,
                     aes(x = long, y = lat, group = group, fill = tendency),
                     alpha = 1, color = "#525252") +
        theme(legend.title=element_blank()) +
        scale_fill_gradient(low = "#004A00", high = "#91D091", breaks = c(-0.5, 0, 0.5), labels = c("No", "Undecided", "Yes"))
}

plot_poltype_map <- function() {
    
    init_map()
    
    # Political map
    poltype_map <- ggmap(get_map(location = b, source = "stamen", maptype = "toner", crop = TRUE), darken = c(1, "white")) +
        ggtitle("Italian Tweets for Referendum")
    poltype_map +
        geom_polygon(data = geo_results,
                     aes(x = long, y = lat, group = group, fill = tendency),
                     alpha = 1, color = "#525252") +
        theme(legend.title=element_blank()) +
        scale_fill_gradient(low = "#F74802", high = "#F7DE02", breaks = c(-0.5, 0, 0.5), labels = c("No", "Undecided", "Yes"))
}


