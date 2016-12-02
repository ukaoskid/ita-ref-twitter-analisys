# Italian December, 4th 2016 Constitutional Referendum Twitter analisys

Twitter data collection for Italian Referendum Vote Day on December, 4th 2016.
This study has to be intended for an experimental purpose

## How to run?
### Requirements
R is needed to run this application. If you don't have R installed you should download it from
- https://www.r-project.org/
- Once R is installed just download this repository in your R working directory. If you don't know where is located just open R and type the command `getwd()`

Twitter App is needed. You should create it because you need APIs codes and Tokens in order to invoke Twitter API layer.
Inside `twitter_ref.R` you have to replace these varaibles
- `api_key`
- `api_secret`
- `token`
- `token_secret`

You can create a Twitter APP following this link
- https://apps.twitter.com/

### Running
- Open R console
- Verify you have these libaries
	1. `twitteR`
	2. `RCurl`
	3. `stringr`
	4. `dplyr`
	5. `lubridate`
	6. `sqldf`
	7. `ggmap`
	8. `ggplot2`
- Load the main R file `source("twitter_ref.R")`
- Adjust the extraction dates and enjoy
