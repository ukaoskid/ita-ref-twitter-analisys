# Codebook
## Italian Constitutional Referendum Twitter analisys
*Political reform pointing to Senate power reduction, number of Senators reduction, Regional competencies resize, Public administration resize.* 

### Introduction
Twitter data collection for Italian Referendum Vote Day
This study has to be intended for a experimental purpose

##### Prerequisites

- Taking tweets by geolocation filtering and hashtag filtering
    1. Negative opinion `#IoVotoNO, #BastaUnNO, #IoDicoNO, #VotaNO`
    2. Positive opinion `#IoVotoSI, #BastaUnSI, #IoDicoSI, #VotaSI, #IoVotoSì, #BastaUnSì, #IoDicoSì, #VotaSì`
- Geolocation granularity minimum level is Metropolitan City
- Positive and negative meaning hastags cannot coexsists in the same tweet
- User are grouped simulating one vote

##### Output data for YES and NO
- Daily heatmap and total heatmap
- Daily mean trend
- % of active users on topic
- % of passive users on topic

The study will underline also unconfident users with this social network
- % of uncomplete profiles
- % of incorrect/deceiptive profiles

### Geopolitic subdivision
Statistic is distributed with a level of granularity following this order of dimensions
1. Metropolitan City
2. Big Area
3. Geographic district
4. Nation

##### Subdivision Masterdata
Geopolitic subdivision is took from ISTAT (Italian National Institute of Statistics)
- http://www.istat.it
- Population data is referring the last Census survey (2014)

Dataset reading indexes for `italian-geopolitic-subdivision.csv`

| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| ISTAT | Number | | ISTAT identifing code |
| NationalCode | Character | | Metropolitan City national standard encoding |
| GADMCode | String | | GADM Metropolitan City identifing code |
| MetropolitanCity | Character | | Metropolitan City name |
| BigArea | Character | | National Region |
| GeoDistrict | Character | | National geographic subdivision |
| Population | Number | | Metropolitan City population |
| Area | Number | Km2 | Metropolitan City area |
| Radius | Number | Km | Metropolitan City extention radius [SQRT(Area/3.14)] |
| DistrictsNo | Number | | Number of districts inside Metropolitan City |
| Latitude | Number | | Metropolitan City center Latitude |
| Longitude | Number | | Metropolitan City center Longitude |

`GeoDistrict` Legenda of possible/available values
| Value | Description |
|-------|-------------|
| NW | North-West |
| NE | North-East |
| C | Center |
| S | South |
| IS | Islands |