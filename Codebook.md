# Codebook
## Italian Constitutional Referendum Twitter analisys
*Political reform pointing to Senate power reduction, number of Senators reduction, Regional competencies resize, Public administration resize.* 

### Introduction
Twitter data collection for Italian Referendum Vote Day
This study has to be intended for a experimental purpose

#### Prerequisites

- Taking tweets by geolocation filtering and hashtag filtering
    1. Negative opinion `#IoVotoNO, #BastaUnNO, #IoDicoNO, #VotaNO`
    2. Positive opinion `#IoVotoSI, #BastaUnSI, #IoDicoSI, #VotaSI, #IoVotoSì, #BastaUnSì, #IoDicoSì, #VotaSì`
- Geolocation granularity minimum level is Metropolitan City
- Positive and negative meaning hastags cannot coexsists in the same tweet
- User are grouped simulating one vote

#### Output data for YES and NO
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

#### Subdivision Masterdata
Geopolitic subdivision is took from ISTAT (Italian National Institute of Statistics)
- http://www.istat.it
- Population data is referring the last Census survey (2014)

Dataset reading indexes for `italian-geopolitic-subdivision.csv`

| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
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

### Available datasets after data processing
Brief description and explanation of the available datasets:
- `tweets_global` (all the extracted tweets)
- `global_users` (all the users grouped by Geo parameters and willing vote)
- `vote_results` (aggregate by Geo parameters)
- `big_area_results` (aggregate by Big Area)
- `geo_district_results` (aggregate by Geo Disctric)

#### Extracted Tweets dataset `tweets_global`
| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| text | String | | Tweet text |
| favorited | Boolean | | If this Tweet is a favorited one |
| favoriteCount | Number | | Tweet preference count |
| replyToSN | String | | Tweet in reply of a user (aka SN "ScreenName") |
| created | Date | | Tweet creation date |
| replyToSID | Number | | Tweet in reply of a SID (aka User or SN "ScreenName") |
| id | Number | | User ID
| replyToUID | Number | | Tweet in reply of a UID (aka SID, User or SN "ScreenName") |
| statusSource | String | | Tweet device source |
| screenName | String | | User name |
| retweetCount | Number | | Tweet retweet count |
| isRetweet | Boolean | | Is this Tweet a retweet |
| retweeted | Boolean | | Is this Tweet retwetted |
| longitude | Number | | Tweet longitude |
| latitude | Number | | Tweet latitude |
| extraction_date | Date | | Tweet extraction date | 
| will_vote | String | | What user is supposed to vote |
| metro_area | String | | Tweet Metropolitan City |
| big_area | String | | Tweet Big Area |
| geo_district | String | | Tweet Geo District |
| lat | Number | | Metropolitan City latitude |
| lon | Number | | Metropolitan City longitude |
| ext_filter | String | | Extraction date for filtering |

#### Global Users dataset `global_users`
| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| screenName | String | | Aggregated Username |
| metro_area | String | | Aggregated Metropolitan City |
| big_area | String | | Aggregated Big Area |
| geo_district | String | | Aggregated Geo District |
| will_vote | String | | Aggregate vote supposition |
| lat | Number | | Metropolitan City latitude |
| lon | Number | | Metropolitan City longitude |

#### Metropolitan Area dataset `vote_results`

| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| metro_area | String | | The Metropolitan City code |
| big_area | String | | The Region containing the Metropolitan City |
| geo_district | String | | Geographic area containing the Big Area |
| v_yes | Number | | Number of sampled YES votes |
| v_no | Number | | Number of sampled NO votes |
| perc_y | Number | % | % of YES votes on the total votes |
| perc_n | Number | % | % of NO votes on the total votes |
| tendency | Number | | Value between -0.5 and +0.5 representing the shift from NO to YES votes to be showed on the heatmap |
| winner | String | | Y or N values indicating what is the winning tendency |

#### Big Area dataset `big_area_results`
| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| big_area | String | | Big Area name |
| tot_yes | Number | | Total sampled YES supposed votes |
| tot_no | Number | | Total sampled NO supposed votes |
| perc_y | Number | % | % of YES votes on the total votes  |
| perc_n | Number | % | % of NO votes on the total votes  |

#### Geo District dataset `geo_district_dataset`
| Column | Type | Unit of measure | Description |
|--------|------|-----------------|-------------|
| geo_district | String | | Geo District name |
| tot_yes | Number | | Total sampled YES supposed votes |
| tot_no | Number | | Total sampled NO supposed votes |
| perc_y | Number | % | % of YES votes on the total votes  |
| perc_n | Number | % | % of NO votes on the total votes  |

#### Extraction and Data Process Flow
<img src="https://dl.dropboxusercontent.com/u/52092659/ref/final/data_flow_diagram.png" alt="Extraction and Data Process Flow">

### Vote results
#### Preface
The data observation time-frame started from November, 3rd 2016 and ended on November, 23th 2016. To make this analisys clear and transparent we have to put some notes on top of the charts, in order to read data in the proper way:

- Italian internet users are the `65.6%` of the population (source is WorldBank.org: http://data.worldbank.org/indicator/IT.NET.USER.P2?locations=IT);
- Only the `5.7%` (dataset da aggiungere) of the Italian internet users are really active on Twitter. Given that, we can continue to say that "this is, however, a good sample to consider", but we cannot say that it is representative of the whole nation;
- The analisys in topic has an experimental purpose and it is only representing the orientation of the Italian Twitter users;
-  The analisys is not making any kind of propaganda. These are scientific data.

#### Points involved in Referendum
Unfortunately for not-Italian people, the reform's original text is in Italian, but a Wikipedia page is present and summarizes the purpose also in English:

- [Govern official reform text (only Italian)](https://dl.dropboxusercontent.com/u/52092659/ref/DLAC2613-D.pdf)
- [Wikipedia Italian consitutional Referendum 2016 (English)](https://en.wikipedia.org/wiki/Italian_constitutional_referendum,_2016)

#### Charts and Outputs
#####Trending Heatmap

<img src="https://dl.dropboxusercontent.com/u/52092659/ref/heatmap.gif" alt="Italian constitutional Referendum 2016 Trending Heatmap" width="450"/>

##### Big Area
###### Histogram
<img src="https://dl.dropboxusercontent.com/u/52092659/ref/big_area_hist.gif" alt="Italian constitutional Referendum 2016 Big Area Trending Histogram" width="450"/>

###### Final output
| Big Area | Yes | No | % Yes | % No |
|----------|-----|----|-------|------|
| Abruzzo | 44 | 7 | 86 | 14 |
| Basilicata | 11 | 51 | 18 | 82 |
| Calabria | 18 | 32 | 36 | 64 |
| Campania | 55 | 172 | 24 | 76 |
| Emilia-Romagna | 96 | 138 | 41 | 59 |
| Friuli-Venezia Giulia | 31 | 66 | 32 | 68 |
| Lazio | 10 | 37 | 21 | 79 |
| Liguria | 2 | 21 | 09 | 91 |
| Lombardia | 1137 | 1843 | 38 | 62 |
| Marche | 26 | 5 | 84 | 16 |
| Molise | 8 | 12 | 40 | 60 |
| Piemonte | 56 | 72 | 44 | 56 |
| Puglia | 29 | 112 | 21 | 79 |
| Sardegna | 24 | 96 | 20 | 80 |
| Sicilia | 50 | 95 | 34 | 66 |
| Toscana | 29 | 128 | 18 | 82 |
| Trentino-Alto Adige | 33 | 102 | 24 | 76 |
| Umbria | 6 | 31 | 16 | 84 |
| Valle d'Aosta | 0 | 3 | 0 | 100 |
| Veneto | 62 | 132 | 32 | 68 |

##### Geo District
###### Histogram
<img src="https://dl.dropboxusercontent.com/u/52092659/ref/geo_hist.gif" alt="Italian constitutional Referendum 2016 Geo District Trending Histogram" width="450"/>

###### Final output
| Geo District | Yes | No | % Yes | % No |
|--------------|-----|----|-------|------|
| North-East | 222 | 438 | 34 | 66
| North-West | 1195 | 1939 | 38 | 62
| Center | 71 | 201 | 26 | 74
| South | 165 | 386 | 30 | 70
| Islands | 74 | 191 | 28 | 72

##### Overall
###### Pie chart
<img src="https://dl.dropboxusercontent.com/u/52092659/ref/national_pie.gif" alt="Italian constitutional Referendum 2016 Overall Trending Pie chart" width="450"/>

> **Yes: 33.3%**
> 
> **No: 66.7%**
