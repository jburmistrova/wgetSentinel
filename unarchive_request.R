# Title: download_20.R
# Author: jburmistrova
# Modified: 08-25-2020 
# Purpose: request to unarchive archived S2 files from Copernicus
#
# **Requires** 
# 1) A previously created csv document hat includes UUIDs
# 2) A username and password with Copernicus, sign-up found here: https://scihub.copernicus.eu/dhus/#/self-registration
####################################################################################
#
## require packages
suppressWarnings(
library(tidyverse)
)
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             INPUT VARIABLES       #### 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# The following variables should be defined by the user each time.
#### INPUT CSV AND OUTPUT PATHS TXT FILE ####
input_output <- "input_output.txt"

#### USER DEFINED USERNAME AND PASSWORD AS A TXT FILE ####
username_password <- "copernicus_username_password.txt"

#### MAX FILES, NOTE MUST BE >0 and <20 ####
max_files <- 20

#### SCRIPT SLEEP TIME IN SECONDS, RECOMMENDED 12 HOURS ####
sleep_hours <- 12
sleep_seconds <- pause_hours * 60 * 60 

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             INPUT VARIABLES        ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
####             START SCRIPT                      ####
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#read in txt file that has username and password
un_pw <- read.delim(username_password, header = T, sep = " ")
username <- un_pw[1,2]
password <- un_pw[2,2]

#read in txt file that has input CSV/output paths
in_out <- read.delim(input_output, header = T, sep = " ")
inFile <- in_out[1,2]
outPathWgetTXT <- in_out[2,2]
outPathScriptTXT <- in_out[3,2]
outPathSAFE <- in_out[4,2]

my_csv <- read.csv(inFile)
my_archived <- length(which(my_csv$status %in% c("archived", "403 Forbidden", "<NA>")))

#a counter to keep track of while loop
my_counter <- 1

#repeat the code here
while (my_archived != 0) {
  
  if (my_counter > 1) { 
    print(paste0("Sleeping for ", sleep_hours," hours, or ", sleep_seconds," seconds."))
    Sys.sleep(pause_seconds)
  }
  
  #if max_files is greater than 20, the script stops immediately and tells the user
  #to change max_files to a value <20
  if(any(max_files < 1 | max_files > 20) ) stop('max_files is not between 1 and 20; maxumum files you can request to unarchive is 20 according to ESA copernicus')
  
  #read the csv file and find all archived files
  my_uuid <- read.csv(inFile)%>%
    filter(status %in% c("archived", "403 Forbidden", "NA"))

  if (length(my_uuid$uuid) < max_files) {
    max_files <- length(my_uuid$uuid)
    paste0("max_files is less than 20 and is now: ", max_files)
  }

  paste0("max_files is ", max_files)

  #slice cuts the CSV file to the max_files
  #REMEMBER, you can only request 20 files from ESA Copernicus hub
  my_uuid <- my_uuid %>%
    slice(1:max_files) %>%
    mutate(uuid = as.character(uuid))

  #this gives the user a sanity check, makes sure the code is wget'ing is a UUID
  paste0("You have requested the following UUID's:")
  print(my_uuid$uuid)
  
  #start by requesting the tiles/uuids, and repeat for the max_files 
  for (u in 1:max_files) {
    
    filenameScript <- paste0(outPathScriptTXT,"/unarchive_output_",my_uuid$title[u],".txt")
    filenameWget <- paste0(outPathWgetTXT,"/unarchive_output_",my_uuid$title[u],".txt")
  
    #using system(), you are running wget as if running in linux
    system(paste0("wget --content-disposition --continue --user=",username," --password=",password," -o ",filenameWget," -N \"https://scihub.copernicus.eu/apihub/odata/v1/Products(\'",my_uuid$uuid[u],"\')/\\$value\""))
  
  
    new_status <- read_lines(outPathWgetTXT,skip = 0, skip_empty_rows = FALSE, n_max = -1L)%>%
      na.omit(str_extract("(?:[:digit:]{3}[:space:])+[[:alpha:]$]+"))[3]
  
    new_timestamp_attempt <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
    #update the uuid's status to new_status
    my_uuid$status[u] <- new_status
    my_uuid$timestamp_attempt[u] <- new_timestamp_attempt
  
    #add the requested tiles, with new_status to entire CSV file
    my_csv <- read.csv(inFile)%>%
      slice(-c(my_uuid$X[u])) #remove all the rows that are now pending
    my_csv <- rbind(my_csv, my_uuid[u,])%>%
      arrange(X)
  
    #save the csv with updated status
    #note it OVERWRITES the old CSV
    write_csv(my_csv, inFile)
  
  }
  
  sink(paste0(outPathScriptTXT,"/archive_script_output_",format(Sys.time(), "%Y%m%d_%H%M"),".txt"), type = "output")
  #create a summary of the CSV for the user
  my_archived <- length(which(my_csv$status == c("archived", "403 Forbidden", NA)))
  my_requested <- length(which(my_csv$status == "202 Accepted"))
  my_notfound <- length(which(my_csv$status == "500 Not Found"))
  my_downloaded <- length(which(my_csv$status == "200 OK"))

  paste0("Summary of CSV")
  paste0("The last time this script finished running was: ", format(Sys.time(), "%Y%m%d_%H%M"))
  paste0("UUIDs requested: ", my_requested)
  paste0("UUIDs  downloaded: ", my_downloaded)
  paste0("UUIDs still archived: ", my_archived) 
  paste0("UUIDs not found: ", my_notfound)
  paste0("You have finished attempting to unarchived the Sentinel tiles.") 
  paste0("Remember to try to download them tomorrow.")
  paste0("It might take a few days for the files to become officially unarchived, so keep checking")
  
  paste0("Please keep the script running until all files are requested.")
  
  my_counter <- my_counter + 1
  paste0("This script has run ", my_counter, " times.")
  
  sink()
  
  paste0("This script has run ", my_counter, " times.")
}
  