library("RJSONIO")
library("RCurl")
library("magrittr")
library("jsonlite")
library("emil")
library("wru")
library("dplyr")
source("scripts/functions.R")

# Year with event ID
# 2015 - 855
# 2013 - 39
# 2012 - 67
# 2011 - 886
# 2010 - 279
# 2009 - 883
# 2008 - 882
# 2007 - 881
# 2006 - 880
# 2005 - 879

yearID <- data.frame(c(2015,2013:2005), c(855, 39, 67, 886, 279, 883, 882, 881, 880, 879))
colnames(yearID) <- c("year", "eventID")

allRaceData <- data.frame()

for (p in 2:10) {
  
  year <- yearID$year[[p]]
  eventID <- yearID$eventID[[p]]
  
  raceData <- RJSONIO::fromJSON(getURL(paste0("http://results.xacte.com/json/search?eventId=", eventID, "&sEcho=1&iColumns=13&sColumns=&iDisplayStart=0&iDisplayLength=30000&mDataProp_0=&mDataProp_1=bib&mDataProp_2=firstname&mDataProp_3=lastname&mDataProp_4=sex&mDataProp_5=age&mDataProp_6=city&mDataProp_7=state&mDataProp_8=country&mDataProp_9=&mDataProp_10=&mDataProp_11=&mDataProp_12=&sSearch=&bRegex=false&sSearch_0=&bRegex_0=false&bSearchable_0=false&sSearch_1=&bRegex_1=false&bSearchable_1=true&sSearch_2=&bRegex_2=false&bSearchable_2=true&sSearch_3=&bRegex_3=false&bSearchable_3=true&sSearch_4=&bRegex_4=false&bSearchable_4=true&sSearch_5=&bRegex_5=false&bSearchable_5=true&sSearch_6=&bRegex_6=false&bSearchable_6=true&sSearch_7=&bRegex_7=false&bSearchable_7=true&sSearch_8=&bRegex_8=false&bSearchable_8=true&sSearch_9=&bRegex_9=false&bSearchable_9=true&sSearch_10=&bRegex_10=false&bSearchable_10=true&sSearch_11=&bRegex_11=false&bSearchable_11=false&sSearch_12=&bRegex_12=false&bSearchable_12=false&iSortCol_0=0&sSortDir_0=asc&iSortingCols=1&bSortable_0=false&bSortable_1=true&bSortable_2=true&bSortable_3=true&bSortable_4=true&bSortable_5=true&bSortable_6=true&bSortable_7=true&bSortable_8=true&bSortable_9=false&bSortable_10=false&bSortable_11=false&bSortable_12=false&_=1449041119791")))
  eventLength <- raceData$iTotalRecords
  
  for (i in 1:eventLength) {
    
      age <- raceData$aaData[[i]]$age 
      firstName <- raceData$aaData[[i]]$firstname
      lastName <- raceData$aaData[[i]]$lastname
      sex <- raceData$aaData[[i]]$sex
      city <- raceData$aaData[[i]]$city
      state <- raceData$aaData[[i]]$state
      country <- raceData$aaData[[i]]$country
      bib <- raceData$aaData[[i]]$bib
      disquil <- raceData$aaData[[i]]$dq
      clockTime <- raceData$aaData[[i]]$clocktime
      chipTime <- raceData$aaData[[i]]$chiptime
      
      tempList <- list(year, age, firstName, lastName, city, sex, state, country, bib, disquil, clockTime, chipTime)
      
      dataFrameRace <- tempList %>% nullToNA() %>% blankToNA() %>% data.frame()
      colnames(dataFrameRace) <- c("year", "age", "firstName", "lastName", "city", "sex", "state", "country", "bib", "disquil", "clockTime", "chipTime")
    
      allRaceData <- rbind(allRaceData, dataFrameRace)
      print(paste(year, "-", i))
  }
}
  
# Feature Mining - WRU

modRaceData <- allRaceData

#count of the city + state
cityTable <- paste0(allRaceData$city, ", ", allRaceData$state) %>% tolower() %>% table() %>% data.frame() %>% arrange(-Freq)
colnames(cityTable) <- c("city", "count")
cityTable$city <- as.character(cityTable$city)

modRaceData$cityState <- paste0(allRaceData$city, ", ", allRaceData$state) %>% tolower()

nu <- 200000

latLon <- lapply(head(modRaceData$cityState, n = nu), cityToGPS) %>% do.call(rbind.data.frame, .)

#using surname is determine ethnicity
cenusKey <- "698c05cc91b66fc3d38a063f0fbefd5449909bf3"

surName <- allRaceData$lastName %>%  tolower() %>% table() %>% data.frame() %>% arrange(-Freq)
colnames(surName) <- c("surname", "count")
surName$surname <- as.character(surName$surname)
surName <- surName %>% arrange(-count)

str(surName)

surNamePred <- race.pred(voters = head(surName, n = 50000), census = "tract", 
               census.key = cenusKey, demo = TRUE, surname.only=TRUE, name.clean = TRUE) %>% arrange(-count)

surNamePred[,3] <- surNamePred[,3]*100
surNamePred[,4] <- surNamePred[,4]*100
surNamePred[,5] <- surNamePred[,5]*100
surNamePred[,6] <- surNamePred[,6]*100
surNamePred[,7] <- surNamePred[,7]*100
